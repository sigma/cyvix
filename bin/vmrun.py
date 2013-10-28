from plumbum import cli

import cyvix


class Application(cli.Application):

    @staticmethod
    def _checkArgIs(args, idx, value):
        return idx < len(args) and args[idx] == value


class VmRun(Application):

    VERSION = "version 1.12.1 python"

    host_type = cli.SwitchAttr(["-T"], help="host type",
                               default="ws")

    def main(self, *args):
        host_types = {'ws': cyvix.VMwareWorkstationHost}

        self._host = host_types[self.host_type]()
        self._host.connect()

        if args:
            print "Error: Unrecognized command: %s" % (args)
            return 255
        if not self.nested_command:
            print "No command given"
            return 1   # error exit code


class VmRunSubCmd(Application):

    def _getVM(self, name):
        return cyvix.VirtualMachine(name, self.parent._host)


@VmRun.subcommand("start")
class VmRunStart(VmRunSubCmd):

    def main(self, *args):
        gui = self._checkArgIs(args, 1, 'gui')
        vm = self._getVM(args[0])
        vm.open()
        vm.powerOn(gui=gui)


@VmRun.subcommand("stop")
class VmRunStop(VmRunSubCmd):

    def main(self, *args):
        guest = self._checkArgIs(args, 1, 'soft')
        vm = self._getVM(args[0])
        vm.open()
        vm.powerOff(guest=guest)


@VmRun.subcommand("reset")
class VmRunReset(VmRunSubCmd):

    def main(self, *args):
        guest = self._checkArgIs(args, 1, 'soft')
        vm = cyvix.VirtualMachine(args[0], self.parent._host)
        vm.open()
        vm.reset(guest=guest)


if __name__ == "__main__":
    VmRun.run()
