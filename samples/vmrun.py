import cyvix

h = cyvix.VMwareWorkstationHost()
h.connect()
vms = h.findRunningVMs()

print "Total running VMs:", len(vms)
for vm in vms:
    print vm.path
