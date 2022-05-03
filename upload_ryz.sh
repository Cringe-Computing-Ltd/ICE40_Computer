#!/bin/sh
sudo mount /dev/sdd1 /mnt && sudo cp build/raccoon.uf2 /mnt && sudo umount /mnt
