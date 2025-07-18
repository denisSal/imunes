foreach elem_type "node link iface" {
	foreach proc_type "set get" {
		global ${elem_type}_${proc_type}_attributes
	}
}

foreach elem_type "node link canvas annotation" {
	foreach proc_type "set get" {
		global ${elem_type}_${proc_type}_attributes_gui
	}
}

set node_set_attributes "Name Model CustomImage {Protocol rip} {Protocol ripng} {Protocol ospf} {Protocol ospf6} IPsec DockerAttach VlanFiltering NATIface Services"
set node_get_attributes "Dir Type $node_set_attributes"
set node_set_attributes_gui "Canvas Coords LabelCoords"
set node_get_attributes_gui "$node_set_attributes_gui"

proc API_startNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		if { [getFromRunning "${node_id}_running"] == true } {
			continue
		}

		trigger_nodeCreate $node_id
	}

	undeployCfg
	deployCfg
}

proc API_stopNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		trigger_nodeDestroy $node_id
	}

	undeployCfg
	deployCfg
}

proc API_restartNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		trigger_nodeRecreate $node_id
	}

	undeployCfg
	deployCfg
}

proc API_configNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		trigger_nodeConfig $node_id
	}

	undeployCfg
	deployCfg
}

proc API_unconfigNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		trigger_nodeUnconfig $node_id
	}

	undeployCfg
	deployCfg
}

proc API_reconfigNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		trigger_nodeReconfig $node_id
	}

	undeployCfg
	deployCfg
}

proc API_configIfaces { nodes_ifaces } {
	if { $nodes_ifaces == {} } {
		return
	}

	foreach node_ifaces $nodes_ifaces {
		lassign $node_ifaces node_id ifaces
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		foreach iface_id $ifaces {
			if { [getFromRunning "${node_id}|${iface_id}_running"] != true } {
				continue
			}

			trigger_ifaceConfig $node_id $iface_id
		}
	}

	undeployCfg
	deployCfg
}

proc API_unconfigIfaces { nodes_ifaces } {
	if { $nodes_ifaces == {} } {
		return
	}

	foreach node_ifaces $nodes_ifaces {
		lassign $node_ifaces node_id ifaces
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		foreach iface_id $ifaces {
			if { [getFromRunning "${node_id}|${iface_id}_running"] != true } {
				continue
			}

			trigger_ifaceUnconfig $node_id $iface_id
		}
	}

	undeployCfg
	deployCfg
}

proc API_reconfigIfaces { nodes_ifaces } {
	if { $nodes_ifaces == {} } {
		return
	}

	foreach node_ifaces $nodes_ifaces {
		lassign $node_ifaces node_id ifaces
		if { [getFromRunning "${node_id}_running"] != true } {
			continue
		}

		foreach iface_id $ifaces {
			if { [getFromRunning "${node_id}|${iface_id}_running"] != true } {
				continue
			}

			trigger_ifaceReconfig $node_id $iface_id
		}
	}

	undeployCfg
	deployCfg
}
