#!/bin/sh

# touchpad sometimes not recoqnized after boot, this solves it
sudo modprobe -r i2c_hid_acpi && sudo modprobe i2c_hid_acpi
