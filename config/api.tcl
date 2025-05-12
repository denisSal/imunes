proc API_redeployCfg {} {
	undeployCfg
	deployCfg
}

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
}

proc API_restartNodes { nodes } {
	if { $nodes == {} } {
		return
	}

	foreach node_id $nodes {
		trigger_nodeRecreate $node_id
	}
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
}
