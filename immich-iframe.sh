#!/bin/bash

# ------------ CONFIGURATION ------------
IDLE_THRESHOLD_MS=600000     # 10 minutes
CHECK_INTERVAL=5             # Check every 5 seconds
IMMICH_CMD="immichiframe"    # Just the command, rely on PATH

# ------------ HELPER FUNCTION: Check fullscreen video ------------
is_fullscreen_video_playing() {
    active_win=$(xdotool getactivewindow 2>/dev/null)

    if [ -n "$active_win" ]; then
        fullscreen=$(xprop -id "$active_win" _NET_WM_STATE 2>/dev/null | grep _NET_WM_STATE_FULLSCREEN)
        class=$(xprop -id "$active_win" WM_CLASS 2>/dev/null)

        if [[ -n "$fullscreen" ]] && echo "$class" | grep -Ei 'vlc|mpv|firefox|chromium|brave|kodi|totem|mplayer' >/dev/null; then
            return 0
        fi
    fi

    return 1
}

# ------------ MAIN LOOP ------------
launched=false

while true; do
    idle_time=$(xprintidle 2>/dev/null || echo 0)

    # Ensure idle_time is numeric
    if ! [[ "$idle_time" =~ ^[0-9]+$ ]]; then
        idle_time=0
    fi

    if [ "$idle_time" -gt "$IDLE_THRESHOLD_MS" ] && ! is_fullscreen_video_playing; then
        if [ "$launched" = false ]; then
            echo "[INFO] 10 minutes idle detected. Launching ImmichIframe..."
            env PATH="$PATH" $IMMICH_CMD &
            launched=true
        fi
    fi

    sleep $CHECK_INTERVAL
done
