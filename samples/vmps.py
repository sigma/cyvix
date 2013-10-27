import getpass

import cyvix

h = cyvix.VMwareWorkstationHost()
h.connect()
vms = h.findRunningVMs()

for vm in vms:
    print "VM:", vm.path
    user = raw_input("Username: ")
    pswd = getpass.getpass()

    vm.login(user, pswd)
    for p in vm.listProcesses():
        print p.pid, p.cmdline
