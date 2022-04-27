#!/bin/sh
sudo mount /dev/sdb1 /mnt && sudo cp build/ICE40_Computer.uf2 /mnt && sudo umount /mnt