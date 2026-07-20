#!/usr/bin/env bash

# Dependencies: brightnessctl, wpctl, libnotify (notify-send)

TYPE=$1       # "volume" or "brightness"
DIRECTION=$2  # "up", "down", or "mute"

# Change steps
VOL_STEP="5"
BRIGHT_STEP="5%"

# Unique notification IDs so they overwrite themselves
VOL_ID=1337
BRIGHT_ID=1338

# Premium geometric progress bar
get_bar() {
    local val=$1
    local bar_size=10
    local filled=$(( val / 10 ))
    local empty=$(( bar_size - filled ))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="▰"; done
    for ((i=0; i<empty; i++)); do bar+="▱"; done
    echo "$bar"
}

case "$TYPE" in
    volume)
        if [ "$DIRECTION" = "mute" ]; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        elif [ "$DIRECTION" = "up" ]; then
            wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ ${VOL_STEP}%+
        elif [ "$DIRECTION" = "down" ]; then
            wpctl set-volume @DEFAULT_AUDIO_SINK@ ${VOL_STEP}%-
        fi

        # Extract volume and mute state
        WP_OUT=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
        VOL_FLOAT=$(echo "$WP_OUT" | awk '{print $2}')
        VOLUME=$(echo "$VOL_FLOAT * 100" | bc | cut -d. -f1)

        if echo "$WP_OUT" | grep -q "\[MUTED\]"; then
            notify-send -r $VOL_ID -t 3000 -u low -h string:x-canonical-private-synchronous:osd-vol "Volume" "󰖁  $(get_bar 0)  <span alpha='70%'>Muted</span>"
        else
            notify-send -r $VOL_ID -t 3000 -u low -h string:x-canonical-private-synchronous:osd-vol "Volume" "󰕾  $(get_bar $VOLUME)  <span alpha='70%'>${VOLUME}%</span>"
        fi
        ;;

    brightness)
        if [ "$DIRECTION" = "up" ]; then
            brightnessctl s +${BRIGHT_STEP} > /dev/null
        elif [ "$DIRECTION" = "down" ]; then
            brightnessctl s ${BRIGHT_STEP}- > /dev/null
        fi

        # Get current state
        CURR=$(brightnessctl g)
        MAX=$(brightnessctl m)
        BRIGHTNESS=$(( CURR * 100 / MAX ))

        notify-send -r $BRIGHT_ID -t 3000 -u low -h string:x-canonical-private-synchronous:osd-bright "Brightness" "󰃠  $(get_bar $BRIGHTNESS)  <span alpha='70%'>${BRIGHTNESS}%</span>"
        ;;
esac
