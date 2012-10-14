PYTHON=python
TARGET=cyvix.so
VMWARE_LIB=libvixAllProducts.so
.PHONY=install

EXTRA_STEP=
ifeq ($(shell uname), Darwin)
  EXTRA_STEP=osx_fixup_lib
  VMWARE_LIB=libvixAllProducts.dylib
  VMWARE_FUSION_LIB_PATH=/Applications/VMware\ Fusion.app/Contents/Public/
endif

all: build_ext $(EXTRA_STEP)

build_ext:
	$(PYTHON) setup.py build_ext --inplace

osx_fixup_lib:
	install_name_tool -change $(VMWARE_LIB) @rpath/$(VMWARE_LIB) $(TARGET)
	install_name_tool -add_rpath $(VMWARE_FUSION_LIB_PATH) $(TARGET)
