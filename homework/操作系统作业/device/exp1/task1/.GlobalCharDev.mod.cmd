savedcmd_GlobalCharDev.mod := printf '%s\n'   GlobalCharDev.o | awk '!x[$$0]++ { print("./"$$0) }' > GlobalCharDev.mod
