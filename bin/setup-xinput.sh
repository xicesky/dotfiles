#!/bin/bash

#DEVICE="Microsoft Microsoft 3-Button Mouse with IntelliEye(TM)"
DEVICE="Logitech USB-PS/2 Optical Mouse"
PROP_PROFILE="Device Accel Profile"
PROP_DECEL="Device Accel Constant Deceleration"

echo "Global setting: xset m 100 0"
xset m 100 0

echo "Need to set accel profile for all pointers to 7!"
echo "xinput set-prop \"$DEVICE\" \"$PROP_PROFILE\" 7"
xinput set-prop "$DEVICE" "$PROP_PROFILE" 7

echo "Then you can control the sensitivity with the constant deceleration, 100 = 100%, less is faster:"
echo "xinput set-prop \"$DEVICE\" \"$PROP_DECEL\" 90"
xinput set-prop "$DEVICE" "$PROP_DECEL" 90

echo "Also disabling key repeat for the \"<\" key (neo2 mod4)"
xset -r 51 && xset -r 94 # fix mod repeat

