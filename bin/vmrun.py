from plumbum import cli

import cyvix


class VmRun(cli.Application):

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


@VmRun.subcommand("start")
class VmRunStart(cli.Application):

    def main(self, *args):
        vm = cyvix.VirtualMachine(args[0], self.parent._host)
        vm.open()
        vm.powerOn(gui=True)


@VmRun.subcommand("stop")
class VmRunStop(cli.Application):

    def main(self, *args):
        vm = cyvix.VirtualMachine(args[0], self.parent._host)
        vm.open()
        vm.powerOff()


@VmRun.subcommand("reset")
class VmRunReset(cli.Application):

    def main(self, *args):
        vm = cyvix.VirtualMachine(args[0], self.parent._host)
        vm.open()
        vm.reset()


if __name__ == "__main__":
    VmRun.run()
