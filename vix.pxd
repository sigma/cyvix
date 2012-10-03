cdef extern from "vmware-vix/vix.h":
    ctypedef int VixHandle
    ctypedef int VixServiceProvider
    ctypedef int VixHostOptions
    ctypedef int VixEventType

    cdef enum:
        VIX_SERVICEPROVIDER_DEFAULT
        VIX_SERVICEPROVIDER_VMWARE_SERVER
        VIX_SERVICEPROVIDER_VMWARE_WORKSTATION
        VIX_SERVICEPROVIDER_VMWARE_PLAYER
        VIX_SERVICEPROVIDER_VMWARE_VI_SERVER
        VIX_SERVICEPROVIDER_VMWARE_WORKSTATION_SHARED

    ctypedef void VixEventProc(VixHandle handle,
                               VixEventType eventType,
                               VixHandle moreEventInfo,
                               void *clientData)

    VixHandle VixHost_Connect(int apiVersion,
                              VixServiceProvider hostType,
                              char *hostName,
                              int hostPort,
                              char *userName,
                              char *password,
                              VixHostOptions options,
                              VixHandle propertyListHandle,
                              VixEventProc *callbackProc,
                              void *clientData)

    void VixHost_Disconnect(VixHandle hostHandle)
