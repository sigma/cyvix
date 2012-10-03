from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules = [Extension("cyvix", ["cyvix.pyx"],
                         libraries=["vixAllProducts", "dl", "pthread"])]

setup(
    name = 'ViX API',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules
)
