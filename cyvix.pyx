cimport vix

cdef bint VIX_FAILED(vix.VixError err):
    return not VIX_SUCCEEDED(err)

cdef bint VIX_SUCCEEDED(vix.VixError err):
    return err == vix.VIX_OK

cdef VIX_CHECK_ERR_CODE(vix.VixError err):
    if VIX_FAILED(err):
        raise Exception(vix.Vix_GetErrorText(err, NULL))

cdef public void vm_discovery_proc(vix.VixHandle handle,
                                   vix.VixEventType eventType,
                                   vix.VixHandle moreEventInfo,
                                   void *clientData):
    cdef vix.VixError err = vix.VIX_OK
    cdef char *url = NULL

    if vix.VIX_EVENTTYPE_FIND_ITEM != eventType:
        return

    err = vix.Vix_GetProperties(moreEventInfo,
                                vix.VIX_PROPERTY_FOUND_ITEM_LOCATION,
                                &url,
                                vix.VIX_PROPERTY_NONE)
    try:
        VIX_CHECK_ERR_CODE(err)
        (<object>clientData).append(<bytes>url)
    finally:
        vix.Vix_FreeBuffer(url)

cdef class __Host:

    cdef vix.VixHandle handle
    cdef vix.VixServiceProvider provider
    cdef char* host
    cdef int port

    def __init__(self, host, int port, vix.VixServiceProvider provider):
        self.provider = provider
        if host is not None:
            self.host = host
        self.port = port
        self.handle = vix.VIX_HANDLETYPE_NONE

    def connect(self, username, passwd):
        cdef char* _user = NULL
        cdef char* _pwd = NULL

        if username is not None:
            _user = username
        if passwd is not None:
            _pwd = passwd

        cdef vix.VixHandle hostHandle
        cdef vix.VixHandle jobHandle \
            = vix.VixHost_Connect(vix.VIX_API_VERSION, self.provider, self.host,
                                  self.port, _user, _pwd,
                                  0, vix.VIX_INVALID_HANDLE,
                                  NULL, NULL)
        cdef vix.VixError err \
            = vix.VixJob_Wait(jobHandle, vix.VIX_PROPERTY_JOB_RESULT_HANDLE,
                              &hostHandle, vix.VIX_PROPERTY_NONE)

        vix.Vix_ReleaseHandle(jobHandle)
        VIX_CHECK_ERR_CODE(err)
        self.handle = hostHandle

    cpdef disconnect(self):
        if self.handle is not vix.VIX_HANDLETYPE_NONE:
            vix.VixHost_Disconnect(self.handle)
            self.handle = vix.VIX_HANDLETYPE_NONE

    cdef findVMs(self, vix.VixFindItemType typ):
        cdef vix.VixHandle jobHandle
        cdef vix.VixError err
        vms = []
        if self.handle is not vix.VIX_HANDLETYPE_NONE:
            jobHandle \
                = vix.VixHost_FindItems(self.handle, typ,
                                        vix.VIX_INVALID_HANDLE, -1,
                                        vm_discovery_proc, <void*>vms)
            err = vix.VixJob_Wait(jobHandle, vix.VIX_PROPERTY_NONE)
            vix.Vix_ReleaseHandle(jobHandle)
            VIX_CHECK_ERR_CODE(err)
        return [VirtualMachine(vm, self.handle) for vm in vms]

    cpdef findRunningVMs(self):
        return self.findVMs(vix.VIX_FIND_RUNNING_VMS)

    def __dealloc__(self):
        if self.handle is not None:
            self.disconnect()

class Host(__Host):

    PROVIDER = vix.VIX_SERVICEPROVIDER_DEFAULT

    def __init__(self, host, port):
        __Host.__init__(self, host, port, self.PROVIDER)

class VMwareServerHost(Host):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_SERVER

class VMwareWorkstationHost(Host):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_WORKSTATION

    def __init__(self):
        Host.__init__(self, None, 0)

    def connect(self):
        Host.connect(self, None, None)

class VMwarePlayerHost(VMwareWorkstationHost):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_PLAYER

class VMwareVIServerHost(Host):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_VI_SERVER

    def findRegisteredVMs(self):
        return self.findVMs(vix.VIX_FIND_REGISTERED_VMS)

class VMwareWorkstationSharedHost(VMwareVIServerHost):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_WORKSTATION_SHARED

cdef class VirtualMachine:

    cdef vix.VixHandle hostHandle
    cdef vix.VixHandle handle
    cpdef public char* path

    def __init__(self, char* path, vix.VixHandle hostHandle):
        self.path = path
        self.hostHandle = hostHandle
        self.handle = vix.VIX_INVALID_HANDLE

    def __dealloc__(self):
        if self.handle != vix.VIX_INVALID_HANDLE:
            vix.Vix_ReleaseHandle(self.handle)

    cpdef open(self):
        cdef vix.VixHandle handle
        cdef vix.VixHandle jobHandle \
            = vix.VixHost_OpenVM(self.hostHandle, self.path,
                                 vix.VIX_VMOPEN_NORMAL,
                                 vix.VIX_INVALID_HANDLE,
                                 NULL, NULL)
        cdef vix.VixError err \
            = vix.VixJob_Wait(jobHandle,
                              vix.VIX_PROPERTY_JOB_RESULT_HANDLE,
                              &handle,
                              vix.VIX_PROPERTY_NONE)
        VIX_CHECK_ERR_CODE(err)
        self.handle = handle
