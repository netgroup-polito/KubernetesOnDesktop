obj-m += loadable.o

all: loadable.ko

loadable.ko:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

.PHONY:	clean

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean