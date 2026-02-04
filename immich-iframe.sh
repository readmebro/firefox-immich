#!/bin/bash

# ------------ CONFIGURATION ------------
IDLE_THRESHOLD_MS=300000     # 5 minutes
CHECK_INTERVAL=5             # Check every 5 seconds
URL="https://example.com"
FIREFOX_CMD="firefox"

# ------------ STATE ------------
firefox_pid=""

# ------------ CLEANUP FUNCTION ------------
cleanup() {
    echo "[INFO] Exiting. Cleaning up…"
    if [ -n "$firefox_pid" ] && kill -0 "$firefox_pid" 2>/dev/null; then
        kill "$firefox_pid"
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM

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
while true; do
    idle_time=$(xprintidle 2>/dev/null || echo 0)

    # Ensure idle_time is numeric
    if ! [[ "$idle_time" =~ ^[0-9]+$ ]]; then
        idle_time=0
    fi

    if [ "$idle_time" -gt "$IDLE_THRESHOLD_MS" ] && ! is_fullscreen_video_playing; then
        if [ -z "$firefox_pid" ] || ! kill -0 "$firefox_pid" 2>/dev/null; then
            echo "[INFO] Idle detected. Launching Firefox..."
            $FIREFOX_CMD --kiosk "$URL" &
            firefox_pid=$!
        fi
    else
        if [ -n "$firefox_pid" ] && kill -0 "$firefox_pid" 2>/dev/null; then
            echo "[INFO] User active or video playing. Closing Firefox instance..."
            kill "$firefox_pid"
            firefox_pid=""
        fi
    fi

    sleep $CHECK_INTERVAL
done
