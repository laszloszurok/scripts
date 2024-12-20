#!/bin/sh

# packages needed: v4l2loopback-dkms, scrcpy, ffmpeg

# connect android to pc and enable usb debugging

# check if phone is connected
if [ -z "$(adb devices | tail +2)" ]; then
    echo "no android device is detected"
    exit 1
fi

# name of microphone plugged in this machine (run: 'pactl list sources short' to get the name)
microphone="alsa_input.usb-MU900_MU900_20190805V001-00.analog-stereo"

# values whith which the virtual camera should be created (/dev/video*)
virt_cam_num="99"
virt_cam_label="android-cam"

# create a virtual video camera
if [ ! -c "/dev/video$virt_cam_num" ]; then
    sudo modprobe v4l2loopback devices=1 video_nr="$virt_cam_num" card_label="$virt_cam_label"
fi

# forward android camera stream to our virtual camera
scrcpy \
    --video-source=camera \
    --camera-size=1280x720 \
    --no-audio \
    --v4l2-sink="/dev/video$virt_cam_num" &

sleep 5

echo "press enter to start recording"
read -r _

mkdir -p ~/videos

# start recording with the virtual camera and the microphone
ffmpeg \
    -f pulse -ac 2 -i "$microphone" \
    -f v4l2 -i "/dev/video$virt_cam_num" \
    -vcodec libx265 \
    "$HOME/videos/video-$(date +%Y-%m-%d-%H:%M).mkv"

# At higher resolutions encoding requires more resources.
# The output might be very laggy if the computer is not beefy enough.
#
# Workaround:
# Record raw, then manually reencode.
# (The raw file will be huge, and reencoding will take some time.)
#
# ffmpeg -f pulse -ac 2 -i "$microphone" -f v4l2 -i "/dev/video$virt_cam_num" -c copy video-raw.mkv
# ffmpeg -i video-raw.mkv -vcodec libx265 encoded.mkv
