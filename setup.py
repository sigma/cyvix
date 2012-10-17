from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import sys

library_dirs = None
extra_link_args = None

if sys.platform == 'darwin':
    library_dirs = ["/Applications/VMware Fusion.app/Contents/Public/"]
    extra_link_args = ["-headerpad_max_install_names"]

ext_modules = [Extension("cyvix", ["cyvix.pyx", "vix.pxd"],
                         libraries=["vixAllProducts", "dl", "pthread"],
                         library_dirs=library_dirs,
                         extra_link_args=extra_link_args)]

setup(
    name = 'ViX API',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules
)
