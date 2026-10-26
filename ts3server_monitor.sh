#!/bin/sh
# Monitor and control the TeamSpeak 3 server through its supplied start script.
# Example cron entry (run as teamspeak, once per minute):
# * * * * * /home/teamspeak/ts3server_monitor.sh check >> /home/teamspeak/ts3server-monitor.log 2>&1
# On its first check, this script creates ~/ts3server-monitor-logrotate.conf.

SERVER_DIR="/home/teamspeak/teamspeak/teamspeak3-server"
START_SCRIPT="$SERVER_DIR/ts3server_startscript.sh"
SERVER_PID_FILE="$SERVER_DIR/ts3server.pid"
STATE_FILE="/home/teamspeak/.ts3server_monitor.pid"
LOG_FILE="/home/teamspeak/ts3server-monitor.log"
LOGROTATE_CONFIG="/home/teamspeak/ts3server-monitor-logrotate.conf"
LOGROTATE_STATE="/home/teamspeak/.ts3server-monitor-logrotate.status"

usage() {
	cat <<EOF
Usage: $0 {check|start|stop|status} [start parameters...]

  check   Check the server and start it if it is not running (default; for cron)
  start   Start the server and save its PID
  stop    Stop the server and clear the saved PID
  status  Show the server status and synchronize the saved PID
EOF
}

read_server_pid() {
	[ -r "$SERVER_PID_FILE" ] || return 1
	SERVER_PID=
	IFS= read -r SERVER_PID < "$SERVER_PID_FILE" || [ -n "$SERVER_PID" ] || return 1
	case "$SERVER_PID" in
		''|*[!0-9]*) return 1 ;;
	esac
	[ "$SERVER_PID" -gt 1 ] 2>/dev/null
}

save_pid() {
	if read_server_pid; then
		printf '%s\n' "$SERVER_PID" > "$STATE_FILE" || {
			echo "Could not save server PID to $STATE_FILE" >&2
			return 1
		}
		return 0
	fi
	echo "The start script reported success, but no valid PID was found in $SERVER_PID_FILE" >&2
	return 1
}

clear_saved_pid() {
	rm -f "$STATE_FILE"
}

run_start() {
	"$START_SCRIPT" start "$@"
	result=$?
	if [ "$result" -ne 0 ]; then
		return "$result"
	fi
	save_pid
}

run_status() {
	"$START_SCRIPT" status "$@"
	result=$?
	if [ "$result" -ne 0 ]; then
		return "$result"
	fi
	save_pid
}

run_check() {
	if "$START_SCRIPT" status >/dev/null 2>&1; then
		if save_pid; then
			return 0
		fi
		return 1
	fi

	echo "TeamSpeak server is not running; attempting to start it"
	run_start "$@"
}

rotate_log() {
	if [ ! -f "$LOGROTATE_CONFIG" ]; then
		umask 077
		cat > "$LOGROTATE_CONFIG" <<EOF
$LOG_FILE {
    size 1M
    rotate 4
    compress
    missingok
    notifempty
    copytruncate
}
EOF
		if [ "$?" -ne 0 ]; then
			echo "Could not create logrotate config: $LOGROTATE_CONFIG" >&2
			return 1
		fi
	fi

	LOGROTATE_BIN=$(command -v logrotate) || {
		echo "logrotate is not installed; cannot rotate $LOG_FILE" >&2
		return 1
	}
	"$LOGROTATE_BIN" -s "$LOGROTATE_STATE" "$LOGROTATE_CONFIG"
}

if [ ! -x "$START_SCRIPT" ]; then
	echo "Start script is missing or not executable: $START_SCRIPT" >&2
	exit 1
fi

action=${1:-check}
if [ "$#" -gt 0 ]; then
	shift
fi

case "$(printf '%s' "$action" | tr '[:upper:]' '[:lower:]')" in
	check|cron|monitor)
	run_check "$@"
	check_result=$?
	rotate_log || exit $?
	exit "$check_result"
	;;
	start)
	run_start "$@"
	exit $?
	;;
	stop)
	"$START_SCRIPT" stop "$@"
	result=$?
	if [ "$result" -eq 0 ]; then
		clear_saved_pid
	fi
	exit "$result"
	;;
	status)
	run_status "$@"
	exit $?
	;;
	-h|--help|help)
	usage
	exit 0
	;;
	*)
	usage >&2
	exit 2
	;;
esac

