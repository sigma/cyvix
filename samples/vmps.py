from __future__ import (absolute_import, division, print_function,
                        unicode_literals)

import getpass

import cyvix
from six.moves import input

h = cyvix.VMwareWorkstationHost()
h.connect()
vms = h.findRunningVMs()

for vm in vms:
    print("VM:", vm.path)
    user = input("Username: ")
    pswd = getpass.getpass()

    vm.login(user, pswd)
    for p in vm.listProcesses():
        print(p.pid, p.cmdline)
