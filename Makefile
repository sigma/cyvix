PYTHON=python
TARGET=cyvix.so
VMWARE_LIB=libvixAllProducts.so
.PHONY=install

ifeq ($(shell uname), Darwin)
  VMWARE_LIB=libvixAllProducts.dylib
  VMWARE_FUSION_LIB_PATH=/Applications/VMware\ Fusion.app/Contents/Public/
endif

all: $(TARGET)

$(TARGET): $(wildcard *.pxd) $(wildcard *.pyx)
	$(PYTHON) setup.py build_ext --inplace
ifeq ($(shell uname), Darwin)
	install_name_tool -change $(VMWARE_LIB) @rpath/$(VMWARE_LIB) $(TARGET)
	install_name_tool -add_rpath $(VMWARE_FUSION_LIB_PATH) $(TARGET)
endif

clean:
	rm -f $(TARGET) $(subst .pyx,.c,$(wildcard *.pyx)) $(subst .pyx,.h,$(wildcard *.pyx))
	rm -rf build/
