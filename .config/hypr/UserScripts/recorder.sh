#!/bin/env bash

ICON_PATH="$HOME/.config/hypr/scripts/icons"

pgrep -x "wf-recorder" && pkill -INT -x wf-recorder && notify-send -i $ICON_PATH/recording.png -h string:wf-recorder:record -t 1000 "Finished Recording" && exit 0

notify-send -i $ICON_PATH/recording.png -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>3</b></i></span>"

sleep 1

notify-send -i $ICON_PATH/recording.png -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>2</b></i></span>"

sleep 1

notify-send -i $ICON_PATH/recording.png -h string:wf-recorder:record -t 950 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>1</b></i></span>"

sleep 1

dateTime=$(date +%m-%d-%Y-%H:%M:%S)
wf-recorder --bframes max_b_frames -f $HOME/screenshot/$dateTime.mp4
