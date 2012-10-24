from distutils.core import setup
from distutils.extension import Extension
from distutils.unixccompiler import UnixCCompiler
from Cython.Distutils import build_ext as _build_ext

import sys
import os

VMWARE_LIB="libvixAllProducts.dylib"
VMWARE_FUSION_LIB_PATH="/Applications/VMware Fusion.app/Contents/Public/"

library_dirs = None
extra_link_args = None

def onOSX():
    return sys.platform == 'darwin'

if onOSX():
    library_dirs = [VMWARE_FUSION_LIB_PATH]
    extra_link_args = ["-headerpad_max_install_names"]

class VMwareExtension(Extension):
    pass

class build_ext(_build_ext):

    def build_extension(self, ext):
        _build_ext.build_extension(self, ext)
        if isinstance(ext, VMwareExtension):
            if onOSX():
                lib_name = ext.name + UnixCCompiler.shared_lib_extension
                os.system('install_name_tool -change "%s" "@rpath/%s" "%s"'
                          % (VMWARE_LIB, VMWARE_LIB, lib_name))
                os.system('install_name_tool -add_rpath "%s" "%s"'
                          % (VMWARE_FUSION_LIB_PATH, lib_name))

ext_modules = [VMwareExtension("cyvix", ["cyvix.pyx", "vix.pxd"],
                               libraries=["vixAllProducts", "dl", "pthread"],
                               library_dirs=library_dirs,
                               extra_link_args=extra_link_args)]

setup(
    name = 'ViX API',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules
)
