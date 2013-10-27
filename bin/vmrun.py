from plumbum import cli

import cyvix


class VmRun(cli.Application):

    VERSION = "version 1.12.1 python"

    def main(self, *args):
        if args:
            print "Error: Unrecognized command: %s" % (args)
            return 255
        if not self.nested_command:
            print "No command given"
            return 1   # error exit code


@VmRun.subcommand("start")
class VmRunStart(cli.Application):

    def main(self, *args):
        h = cyvix.VMwareWorkstationHost()
        h.connect()

        vm = cyvix.VirtualMachine(args[0], h)
        vm.open()
        vm.powerOn(gui=True)


@VmRun.subcommand("stop")
class VmRunStop(cli.Application):

    def main(self, *args):
        h = cyvix.VMwareWorkstationHost()
        h.connect()

        vm = cyvix.VirtualMachine(args[0], h)
        vm.open()
        vm.powerOff()


if __name__ == "__main__":
    VmRun.run()
