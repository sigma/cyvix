cimport vix

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
            = vix.VixHost_Connect(-1, self.provider, self.host,
                                  self.port, _user, _pwd,
                                  0, vix.VIX_INVALID_HANDLE,
                                  NULL, NULL)
        cdef vix.VixError err \
            = vix.VixJob_Wait(jobHandle, vix.VIX_PROPERTY_JOB_RESULT_HANDLE,
                              &hostHandle, vix.VIX_PROPERTY_NONE)

        vix.Vix_ReleaseHandle(jobHandle)
        if err != vix.VIX_OK:
            raise Exception(<long>err) # FIXME: better exception data...
        self.handle = hostHandle

    cpdef disconnect(self):
        if self.handle is not vix.VIX_HANDLETYPE_NONE:
            vix.VixHost_Disconnect(self.handle)
            self.handle = vix.VIX_HANDLETYPE_NONE

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

class VMwareWorkstationSharedHost(VMwareVIServerHost):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_WORKSTATION_SHARED
