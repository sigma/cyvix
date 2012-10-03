cimport vix

cdef class Host:

    cdef vix.VixHandle handle
    cdef vix.VixServiceProvider provider

    def __init__(self, host, port, provider=vix.VIX_SERVICEPROVIDER_DEFAULT):
        self.provider = provider
        self.host = host
        self.port = port

    cdef connect(self, username, passwd):
        self.handle = vix.VixHost_Connect(-1, self.provider, self.host,
                                           self.port, username, passwd,
                                           0, 0, NULL, NULL)

    cdef disconnect(self):
        if self.handle is not None:
            vix.VixHost_Disconnect(self.handle)
            self.handle = None

    def __dealloc__(self):
        if self.handle is not None:
            self.disconnect()
