# make
# insmod GlobalCharDev.ko
# lsmod |grep GlobalCharDev
GlobalCharDev         262144  0
# cat /proc/devices |grep GlobalChar
243 GlobalChar
# ls /dev/GlobalChar
ls: cannot access '/dev/GlobalChar': No such file or directory
# mknod -m 666 /dev/GlobalChar c 243 0
# ls /dev/GlobalChar
/dev/GlobalChar
# gcc GlobalCharTest.c -o GlobalCharTest
# ./GlobalCharTest
The GlobalChar is 0
Please input a number written to GlobalChar: 666
The GlobalChar is 666
# make clean