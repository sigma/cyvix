from __future__ import (absolute_import, division, print_function,
                        unicode_literals)

import cyvix

h = cyvix.VMwareWorkstationHost()
h.connect()
vms = h.findRunningVMs()

print("Total running VMs:", len(vms))
for vm in vms:
    print(vm.path)
