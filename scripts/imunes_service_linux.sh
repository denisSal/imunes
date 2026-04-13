#!/bin/sh

BINDIR=""

TOPO_DIR=/var/imunes-service
IMUNES_BIN=$BINDIR/imunes

imunes_start() {
	topo="$TOPO_DIR/$1.imn"
	eid_file="$TOPO_DIR/$1.eid"

	eid=$(basename $(mktemp -p $TOPO_DIR iXXXX))
	rm -rf $TOPO_DIR/$eid

	himage -l | grep -q "$eid"
	if [ $? -eq 0 ]; then
		echo "Experiment with eid '$eid' already exists, quitting."
		return 1
	fi

	echo "Starting $topo"
	echo "$eid" > "$eid_file"

	echo "$IMUNES_BIN -dd /var/log/imunes/$eid.exp.log -b -e $eid '$topo'"
	$IMUNES_BIN -dd /var/log/imunes/$eid.exp.log -b -e $eid "$topo" > /dev/null

	echo "Started $1 with EID=$eid"
}

imunes_stop() {
    eid_file="$TOPO_DIR/$1.eid"
    if [ ! -f "$eid_file" ]; then
        echo "No EID file for $1, remove experiment manually."
        return 1
    fi

    eid=$(cat "$eid_file")
    echo "Stopping $1 (EID=$eid)"

    echo "$IMUNES_BIN -dd /var/log/imunes/$eid.exp.log -b -e $eid"
    $IMUNES_BIN -dd /var/log/imunes/$eid.exp.log -b -e $eid > /dev/null
    if [ $? -eq 0 ]; then
        rm -f "$eid_file"
        echo "Stopped $1"
    else
        echo "Failed to stop $1"
        return 1
    fi
}

case $1 in
	start)
		imunes_start $2
		;;
	stop)
		imunes_stop $2
		;;
	*)
		;;
esac
