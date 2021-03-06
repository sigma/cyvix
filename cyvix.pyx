cimport vix

cdef bint VIX_FAILED(vix.VixError err) nogil:
    return not VIX_SUCCEEDED(err)

cdef bint VIX_SUCCEEDED(vix.VixError err) nogil:
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

class Program(object):

    def __init__(self, id, time, code):
        self.id = id
        self.time = time
        self.code = code

cdef class Job:
    cdef vix.VixHandle handle

    def __init__(self, vix.VixHandle jobHandle):
        self.handle = jobHandle

    def __del__(self):
        vix.Vix_ReleaseHandle(self.handle)

    def wait(self):
        cdef vix.VixError err \
            = vix.VixJob_Wait(self.handle, vix.VIX_PROPERTY_NONE)

        VIX_CHECK_ERR_CODE(err)

    def waitHandle(self):
        cdef vix.VixHandle handle
        cdef vix.VixError err \
            = vix.VixJob_Wait(self.handle,
                              vix.VIX_PROPERTY_JOB_RESULT_HANDLE, &handle,
                              vix.VIX_PROPERTY_NONE)
        VIX_CHECK_ERR_CODE(err)
        return handle


    def waitProgram(self):
        cdef int err_code, elapsed_time, proc_id
        cdef vix.VixError err \
            = vix.VixJob_Wait(self.handle,
                              vix.VIX_PROPERTY_JOB_RESULT_PROCESS_ID,
                              &proc_id,
                              vix.VIX_PROPERTY_JOB_RESULT_GUEST_PROGRAM_ELAPSED_TIME,
                              &elapsed_time,
                              vix.VIX_PROPERTY_JOB_RESULT_GUEST_PROGRAM_EXIT_CODE,
                              &err_code,
                              vix.VIX_PROPERTY_NONE)
        VIX_CHECK_ERR_CODE(err)
        return Program(proc_id, elapsed_time, err_code)

cdef class Process:

    cdef public char* processName
    cdef public vix.uint64 pid
    cdef public char* owner
    cdef public char* cmdline
    cdef public vix.Bool isDebugged
    cdef public int startTime

    def __init__(self, processName, pid, owner, cmdline,
                 isDebugged, startTime):
        self.processName = processName
        self.pid = pid
        self.owner = owner
        self.cmdline = cmdline
        self.isDebugged = isDebugged
        self.startTime = startTime

cdef class __Host:

    cdef vix.VixHandle handle
    cdef vix.VixServiceProvider provider
    cdef public char* host
    cdef public int port

    def __init__(self, host, int port, vix.VixServiceProvider provider):
        self.provider = provider
        if host is not None:
            self.host = host
        self.port = port
        self.handle = vix.VIX_INVALID_HANDLE

    def connect(self, username, passwd):
        cdef char* _user = NULL
        cdef char* _pwd = NULL

        if username is not None:
            _user = username
        if passwd is not None:
            _pwd = passwd

        self.handle = Job(vix.VixHost_Connect(vix.VIX_API_VERSION,
                                              self.provider, self.host,
                                              self.port, _user, _pwd,
                                              0, vix.VIX_INVALID_HANDLE,
                                              NULL, NULL)).waitHandle()

    def disconnect(self):
        if self.handle is not vix.VIX_INVALID_HANDLE:
            vix.VixHost_Disconnect(self.handle)
            self.handle = vix.VIX_INVALID_HANDLE

    cpdef _findVMs(self, vix.VixFindItemType typ):
        cdef vix.VixHandle jobHandle
        cdef vix.VixError err
        vms = []
        if self.handle is not vix.VIX_INVALID_HANDLE:
            jobHandle \
                = vix.VixHost_FindItems(self.handle, typ,
                                        vix.VIX_INVALID_HANDLE, -1,
                                        vm_discovery_proc, <void*>vms)
            Job(jobHandle).wait()
        res = [VirtualMachine(vm, self) for vm in vms]
        for v in res:
            v.open()
        return res

    def findRunningVMs(self):
        return self._findVMs(vix.VIX_FIND_RUNNING_VMS)

    def openVM(self, path):
        vm = VirtualMachine(path, self)
        vm.open()
        return vm

    def __del__(self):
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
        return self._findVMs(vix.VIX_FIND_REGISTERED_VMS)

class VMwareWorkstationSharedHost(VMwareVIServerHost):

    PROVIDER = vix.VIX_SERVICEPROVIDER_VMWARE_WORKSTATION_SHARED

cdef class VirtualMachine:

    cdef vix.VixHandle hostHandle
    cdef vix.VixHandle handle
    cpdef public char* path
    cdef public bint loggedin

    def __init__(self, char* path, __Host host):
        self.path = path
        self.hostHandle = host.handle
        self.handle = vix.VIX_INVALID_HANDLE
        self.loggedin = False

    def __del__(self):
        if self.handle != vix.VIX_INVALID_HANDLE:
            vix.Vix_ReleaseHandle(self.handle)
            self.handle = vix.VIX_INVALID_HANDLE

    cpdef open(self):
        if self.handle != vix.VIX_INVALID_HANDLE:
            return

        self.handle = Job(vix.VixHost_OpenVM(self.hostHandle, self.path,
                                             vix.VIX_VMOPEN_NORMAL,
                                             vix.VIX_INVALID_HANDLE,
                                             NULL, NULL)).waitHandle()

    cpdef login(self, char* user, char* pwd, interactive=True):
        self.open()
        options = vix.VIX_LOGIN_IN_GUEST_REQUIRE_INTERACTIVE_ENVIRONMENT \
                  if interactive else <int>0
        Job(vix.VixVM_LoginInGuest(self.handle, user, pwd,
                                   options, NULL, NULL)).wait()
        self.loggedin = True

    cpdef logout(self):
        if not self.loggedin:
            return
        Job(vix.VixVM_LogoutFromGuest(self.handle, NULL, NULL)).wait()
        self.loggedin = False

    cpdef putFile(self, char* orig, char* dest):
        Job(vix.VixVM_CopyFileFromHostToGuest(self.handle, orig, dest, 0,
                                              vix.VIX_INVALID_HANDLE,
                                              NULL, NULL)).wait()

    cpdef getFile(self, char* orig, char* dest):
        Job(vix.VixVM_CopyFileFromGuestToHost(self.handle, orig, dest, 0,
                                              vix.VIX_INVALID_HANDLE,
                                              NULL, NULL)).wait()

    cpdef rmDir(self, char* directory):
        Job(vix.VixVM_DeleteDirectoryInGuest(self.handle, directory, 0,
                                             NULL, NULL)).wait()

    cpdef runProgram(self, char* prog, char* options, bint block=True):
        cdef vix.VixRunProgramOptions opts = vix.VIX_RUNPROGRAM_ACTIVATE_WINDOW
        cdef int err_code, elapsed_time, proc_id
        if not block:
            opts |= vix.VIX_RUNPROGRAM_RETURN_IMMEDIATELY
        return Job(
            vix.VixVM_RunProgramInGuest(self.handle, prog, options,
                                        <vix.VixRunProgramOptions>opts,
                                        vix.VIX_INVALID_HANDLE,
                                        NULL, NULL)).waitProgram()

    cpdef killProcess(self, int pid):
        Job(vix.VixVM_KillProcessInGuest(self.handle, pid, 0,
                                         NULL, NULL)).wait()

    def listProcesses(self):
        cdef vix.VixError err
        cdef char *processName
        cdef vix.uint64 pid
        cdef char *owner
        cdef char *cmdline
        cdef vix.Bool isDebugged
        cdef int startTime

        cdef vix.VixHandle jobHandle \
            = vix.VixVM_ListProcessesInGuest(self.handle, 0, NULL, NULL)
        j = Job(jobHandle)
        j.wait()
        cdef int num = vix.VixJob_GetNumProperties(
            jobHandle,
            vix.VIX_PROPERTY_JOB_RESULT_ITEM_NAME)
        for i in range(num):
            err = vix.VixJob_GetNthProperties(
                jobHandle, i,
                vix.VIX_PROPERTY_JOB_RESULT_ITEM_NAME, &processName,
                vix.VIX_PROPERTY_JOB_RESULT_PROCESS_ID, &pid,
                vix.VIX_PROPERTY_JOB_RESULT_PROCESS_OWNER, &owner,
                vix.VIX_PROPERTY_JOB_RESULT_PROCESS_COMMAND, &cmdline,
                vix.VIX_PROPERTY_JOB_RESULT_PROCESS_BEING_DEBUGGED, &isDebugged,
                vix.VIX_PROPERTY_JOB_RESULT_PROCESS_START_TIME, &startTime,
                vix.VIX_PROPERTY_NONE)
            try:
                VIX_CHECK_ERR_CODE(err)
                yield Process(processName, pid, owner, cmdline,
                              isDebugged, startTime)
            finally:
                vix.Vix_FreeBuffer(processName)
                vix.Vix_FreeBuffer(owner)
                vix.Vix_FreeBuffer(cmdline)

    cpdef clone(self, char* dest, int linked=False):
        cdef vix.VixCloneType clone_type \
            = vix.VIX_CLONETYPE_LINKED if linked else vix.VIX_CLONETYPE_FULL
        cdef vix.VixHandle vmHandle \
            = Job(vix.VixVM_Clone(self.handle, vix.VIX_INVALID_HANDLE,
                                  clone_type, dest,
                                  0, vix.VIX_INVALID_HANDLE,
                                  NULL, NULL)).waitHandle()
        vm = VirtualMachine(dest, self.hostHandle)
        vm.handle = vmHandle
        vm.open()
        return vm

    cpdef revertToSnapshot(self, char* snap_name):
        cdef vix.VixHandle snapHandle
        cdef vix.VixError err \
            = vix.VixVM_GetNamedSnapshot(self.handle, snap_name, &snapHandle)
        VIX_CHECK_ERR_CODE(err)

        Job(vix.VixVM_RevertToSnapshot(self.handle, snapHandle, 0,
                                       vix.VIX_INVALID_HANDLE,
                                       NULL, NULL)).wait()

    cpdef takeSnapshot(self, char* snap_name, char* desc, int memory=False):
        opts = vix.VIX_SNAPSHOT_INCLUDE_MEMORY if memory else 0
        Job(vix.VixVM_CreateSnapshot(self.handle, snap_name, desc,
                                     <vix.VixCreateSnapshotOptions>opts,
                                     vix.VIX_INVALID_HANDLE,
                                     NULL, NULL)).wait()

    cpdef powerOn(self, gui=False):
        cdef vix.VixVMPowerOpOptions options = vix.VIX_VMPOWEROP_NORMAL
        if gui:
            options += vix.VIX_VMPOWEROP_LAUNCH_GUI
        Job(vix.VixVM_PowerOn(self.handle, options,
                              vix.VIX_INVALID_HANDLE,
                              NULL, NULL)).wait()

    cpdef powerOff(self, guest=False):
        cdef vix.VixVMPowerOpOptions options = vix.VIX_VMPOWEROP_NORMAL
        if guest:
            options += vix.VIX_VMPOWEROP_FROM_GUEST
        Job(vix.VixVM_PowerOff(self.handle, options,
                               NULL, NULL)).wait()

    cpdef reset(self, guest=False):
        cdef vix.VixVMPowerOpOptions options = vix.VIX_VMPOWEROP_NORMAL
        if guest:
            options += vix.VIX_VMPOWEROP_FROM_GUEST
        Job(vix.VixVM_Reset(self.handle, options,
                            NULL, NULL)).wait()

    cpdef suspend(self):
        cdef vix.VixVMPowerOpOptions options = vix.VIX_VMPOWEROP_NORMAL
        Job(vix.VixVM_Suspend(self.handle, options,
                              NULL, NULL)).wait()

    cpdef pause(self):
        cdef vix.VixVMPowerOpOptions options = vix.VIX_VMPOWEROP_NORMAL
        Job(vix.VixVM_Pause(self.handle, options,
                            vix.VIX_INVALID_HANDLE,
                            NULL, NULL)).wait()

    cpdef unPause(self):
        cdef vix.VixVMPowerOpOptions options = vix.VIX_VMPOWEROP_NORMAL
        Job(vix.VixVM_Unpause(self.handle, options,
                              vix.VIX_INVALID_HANDLE,
                              NULL, NULL)).wait()
