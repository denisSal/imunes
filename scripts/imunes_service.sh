#!/bin/sh
#
# PROVIDE: imunes
# REQUIRE: NETWORKING FILESYSTEMS jail devfs
# KEYWORD: shutdown
#

if [ "$(id -u)" -ne 0 ]; then
	echo "$0 must be run as root." >&2
	exit 1
fi

. /etc/rc.subr

name="imunes"
rcvar="${name}_enable"

: ${imunes_enable:="NO"}
: ${imunes_list:="*"}

start_cmd="${name}_start"
stop_cmd="${name}_stop"

TOPO_DIR="/var/imunes-service"
LOG_DIR="/var/log/imunes"
IMUNES_BIN="/usr/local/bin/imunes"
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin


imunes_start_topology() {
	topology="$1"
	topo="$TOPO_DIR/$topology.imn"
	eid_file="$TOPO_DIR/$topology.eid"

	if [ ! -f "$topo" ]; then
		echo "Topology '$topo' does not exist."
		return 1
	fi

	if [ -f "$eid_file" ]; then
		eid=$(cat "$eid_file")
		echo "Topology '$topology' already has EID=$eid, skipping."
		return 0
	fi

	eid=$(basename "$(mktemp -p "$TOPO_DIR" iXXXX)")
	rm -f "$TOPO_DIR/$eid"

	if himage -l | grep -q "$eid"; then
		echo "Experiment with EID '$eid' already exists, quitting."
		return 1
	fi

	echo "Starting $topo"

	if "$IMUNES_BIN" -dd "$LOG_DIR/$eid.exp.log" -b -e "$eid" "$topo" > /dev/null; then
		echo "$eid" > "$eid_file"
		echo "Started $topology with EID=$eid"
	else
		echo "Failed to start $topology"
		return 1
	fi
}


imunes_stop_topology() {
	topology="$1"
	eid_file="$TOPO_DIR/$topology.eid"

	if [ ! -f "$eid_file" ]; then
		echo "No EID file for $topology, remove experiment manually."
		return 1
	fi

	eid=$(cat "$eid_file")

	echo "Stopping $topology (EID=$eid)"

	if "$IMUNES_BIN" -dd "$LOG_DIR/$eid.exp.log" -b -e "$eid" > /dev/null; then
		rm -f "$eid_file"
		echo "Stopped $topology"
	else
		echo "Failed to stop $topology"
		return 1
	fi
}


imunes_start() {
	mkdir -p "$TOPO_DIR"
	mkdir -p "$LOG_DIR"

	if [ "$imunes_list" = "*" ]; then
		for topo in "$TOPO_DIR"/*.imn; do
			[ -f "$topo" ] || continue

			topology=$(basename "$topo" .imn)
			imunes_start_topology "$topology"
		done
	else
		for topology in $imunes_list; do
			imunes_start_topology "$topology"
		done
	fi
}


imunes_stop() {
	if [ "$imunes_list" = "*" ]; then
		for eid_file in "$TOPO_DIR"/*.eid; do
			[ -f "$eid_file" ] || continue

			topology=$(basename "$eid_file" .eid)
			imunes_stop_topology "$topology"
		done
	else
		for topology in $imunes_list; do
			imunes_stop_topology "$topology"
		done
	fi
}


load_rc_config "$name"

run_rc_command "$1"
