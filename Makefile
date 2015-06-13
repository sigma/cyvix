PYTHON=python
TARGET=cyvix.so
.PHONY=install

all: $(TARGET)

$(TARGET): $(wildcard *.pxd) $(wildcard *.pyx)
	$(PYTHON) setup.py build_ext --inplace --pyrex-gdb

clean:
	rm -f $(TARGET) $(subst .pyx,.c,$(wildcard *.pyx)) $(subst .pyx,.h,$(wildcard *.pyx))
	rm -rf build/

install: $(TARGET)
	$(PYTHON) setup.py install
