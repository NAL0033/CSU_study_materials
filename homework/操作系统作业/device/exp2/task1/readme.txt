# make
# insmod ramblock.ko
# ls /dev/ramblock_disk
/dev/ramblock_disk
# ls /tmp
hsperfdata_root  stapbxN8Ko  systemd-private-eec813641dc44bca9fada8ffad83c46d-chronyd.service-g81Myx
stap1As3af       stapFfyzq8  systemd-private-eec813641dc44bca9fada8ffad83c46d-systemd-logind.service-EG43Lj
# mkdosfs /dev/ramblock_disk
mkfs.fat 4.1 (2017-01-24)
# mount /dev/ramblock_disk /tmp
# ls /tmp
# cd /tmp
# echo "Hello, world!" > hello.txt
# ls
hello.txt
# cat hello.txt
Hello, world!
# cd -
# umount /tmp
# ls /tmp
hsperfdata_root  stapbxN8Ko  systemd-private-eec813641dc44bca9fada8ffad83c46d-chronyd.service-g81Myx
stap1As3af       stapFfyzq8  systemd-private-eec813641dc44bca9fada8ffad83c46d-systemd-logind.service-EG43Lj
# mount /dev/ramblock_disk /tmp
# ls /tmp
hello.txt
# cat /tmp/hello.txt
Hello, world!
# umount /tmp
# ls /tmp
hsperfdata_root  stapbxN8Ko  systemd-private-eec813641dc44bca9fada8ffad83c46d-chronyd.service-g81Myx
stap1As3af       stapFfyzq8  systemd-private-eec813641dc44bca9fada8ffad83c46d-systemd-logind.service-EG43Lj
# rmmod ramblock
# make clean

说明：/tmp文件中在“mount /dev/ramblock_disk /tmp”之前和“umount /tmp”之后不见得与上述示例相同。