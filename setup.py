from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import sys

library_dirs = None

if sys.platform == 'darwin':
    library_dirs = ["/Applications/VMware Fusion.app/Contents/Public/"]

ext_modules = [Extension("cyvix", ["cyvix.pyx"],
                         libraries=["vixAllProducts", "dl", "pthread"],
                         library_dirs=library_dirs)]

setup(
    name = 'ViX API',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules
)
