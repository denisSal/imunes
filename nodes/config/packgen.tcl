# updateNode cases

addCase_updateNode "packgen" {
	set packgen_diff [dictDiff $old_value $new_value]
	dict for {packets_key packets_change} $packgen_diff {
		if { $packets_change == "copy" } {
			continue
		}

		dputs "======== $packets_change: '$packets_key'"

		set packets_old_value [_cfgGet $old_value $packets_key]
		set packets_new_value [_cfgGet $new_value $packets_key]
		if { $packets_change in "changed" } {
			dputs "======== OLD: '$packets_old_value'"
		}
		if { $packets_change in "new changed" } {
			dputs "======== NEW: '$packets_new_value'"
		}

		if { $packets_key == "packetrate" } {
			dputs "setPackgenPacketRate $node_id $packets_new_value"
			setPackgenPacketRate $node_id $packets_new_value
			continue
		}

		set packets_diff [dictDiff $packets_old_value $packets_new_value]
		foreach {packet_key packet_change} $packets_diff {
			if { $packet_change == "copy" } {
				continue
			}

			dputs "============ $packet_change: '$packet_key'"

			set packet_old_value [_cfgGet $packets_old_value $packet_key]
			set packet_new_value [_cfgGet $packets_new_value $packet_key]
			if { $packet_change in "changed" } {
				dputs "============ OLD: '$packet_old_value'"
			}
			if { $packet_change in "new changed" } {
				dputs "============ NEW: '$packet_new_value'"
			}

			switch -exact $packet_change {
				"removed" {
					removePackgenPacket $node_id $packet_key
				}

				"new" {
					addPackgenPacket $node_id $packet_key $packet_new_value
				}

				"changed" {
					removePackgenPacket $node_id $packet_key
					addPackgenPacket $node_id $packet_key $packet_new_value
				}
			}
		}
	}
}

# node-specific procedures

proc getPackgenPacketRate { node_id } {
	return [cfgGetWithDefault 100 "nodes" $node_id "packgen" "packetrate"]
}

proc setPackgenPacketRate { node_id rate } {
	cfgSet "nodes" $node_id "packgen" "packetrate" $rate

	trigger_nodeReconfig $node_id
}

proc getPackgenPacket { node_id id } {
	return [cfgGet "nodes" $node_id "packgen" "packets" $id]
}

proc addPackgenPacket { node_id id new_value } {
	cfgSetEmpty "nodes" $node_id "packgen" "packets" $id $new_value

	trigger_nodeReconfig $node_id
}

proc removePackgenPacket { node_id id } {
	cfgUnset "nodes" $node_id "packgen" "packets" $id

	trigger_nodeReconfig $node_id
}

proc getPackgenPacketData { node_id id } {
	return [cfgGet "nodes" $node_id "packgen" "packets" $id]
}

proc packgenPackets { node_id } {
	return [cfgGet "nodes" $node_id "packgen" "packets"]
}

proc checkPacketNum { str } {
	return [regexp {^([1-9])([0-9])*$} $str]
}

proc checkPacketData { str } {
	set str [string map { " " "." ":" "." } $str]
	if { $str != "" } {
		return [regexp {^([0-9a-f][0-9a-f])*$} $str]
	}

	return 1
}
