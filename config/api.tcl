proc parseImnCtl { args } {
	puts "ARGS: '$args'"
	set rest [lassign $args type action]

	puts "TYPE: '$type'"
	puts "ACTION: '$action'"
	puts "REST: '$rest'"

	switch -exact -- $type {
		"node" {
			parseImnCtlNode $action {*}$rest
		}

		"link" {
			parseImnCtlLink $action {*}$rest
		}

		"iface" {
			parseImnCtlIface $action {*}$rest
		}

		default {
			return -code error "Unknown element type '$type'"
		}
	}
}

proc parseImnCtlNode { action args } {
	set update_actions "update modify delete"
	set execute_actions "start stop restart"
	set config_actions "config unconfig reconfig"
	set edit_actions "name"

	set actions [concat "edit" $update_actions $execute_actions $config_actions]
	if { $action ni $actions } {
		return -code error "Unknown node action '$action'"
	}

	if { $action in $update_actions } {
		set json [lassign $args node_id]
		puts "JSON: '$json'"
		set json_dict [json::json2dict $json]
		puts "JSON_DICT: '$json_dict'"

		switch -exact -- $action {
			"update" {
				# node full update
				updateNode $node_id "*" $json_dict
			}

			"modify" {
				# node delta modify (no delete)
				modifyNode $node_id "*" $json_dict
			}

			"delete" {
				# node delta delete
				deleteInNode $node_id "*" $json_dict
			}

			default {
				return -code error "No node update action '$action'"
			}
		}

		saveCfgJson [getFromRunning "current_file"]

		return
	}

	if { $action == "edit" } {
		set rest [lassign $args node_id command]
		switch -exact -- $command {
			"delete" -
			"set" {
				lassign $rest attribute new_value
				if { $command == "delete" } {
					set new_value ""
				}

				switch -exact -- $attribute {
					"name" {
						# validate name
						setNodeName $node_id $new_value
					}

					default {
						return -code error "No node attribute '$attribute'"
					}
				}

				saveCfgJson [getFromRunning "current_file"]
			}

			"get" {
				lassign $rest attribute
				puts [getNodeName $node_id]
			}

			default {
				return -code error "No command '$command'"
			}
		}

		return
	}

	set node_list [getFromRunning "node_list"]
	set nodes {}
	set node_names $args
	foreach node_name $node_names {
		if { $node_name in $nodes } {
			continue
		}

		if { $node_name in $node_list } {
			lappend nodes $node_name
			continue
		}

		set node_id [getNodeFromHostname $node_name]
		if { $node_id == "" || $node_id in $nodes } {
			continue
		}

		lappend nodes $node_id
	}

	if { $nodes == {} } {
		return -code error "No nodes found!"
	}

	switch -exact -- $action {
		"start" {
			API_startNodes $nodes
		}

		"stop" {
			API_stopNodes $nodes
		}

		"restart" {
			API_restartNodes $nodes
		}

		"config" {
			API_configNodes $nodes
		}

		"unconfig" {
			API_unconfigNodes $nodes
		}

		"reconfig" {
			API_reconfigNodes $nodes
		}
	}

	return
}

proc parseImnCtlLink { action args } {
	set actions ""
	if { $action ni $actions } {
		return -code error "Unknown link action '$action'"
	}

	switch -exact -- $action {
	}

	return
}

proc parseImnCtlIface { action args } {
	set config_actions "config unconfig reconfig"

	set actions [concat $config_actions]
	if { $action ni $actions } {
		return -code error "Unknown iface action '$action'"
	}

	set node_list [getFromRunning "node_list"]
	set nodes {}
	set nodes_ifaces_parsed {}
	set nodes_ifaces $args
	foreach {node_name ifaces} $nodes_ifaces {
		set iface_names [split $ifaces ","]
		if { $node_name in $nodes } {
			continue
		}

		if { $node_name in $node_list } {
			set node_id $node_name
		} else {
			set node_id [getNodeFromHostname $node_name]
			if { $node_id == "" || $node_id in $nodes } {
				continue
			}
		}

		lappend nodes $node_id

		set iface_ids {}
		set iface_list [allIfcList $node_id]
		if { $iface_names == "*" } {
			set iface_ids $iface_list
		} else {
			foreach iface_name $iface_names {
				if { $iface_name in $iface_ids } {
					continue
				}

				if { $iface_name in $iface_list } {
					lappend iface_ids $iface_id
					continue
				}

				set iface_id [ifaceIdFromName $node_id $iface_name]
				if { $iface_id == "" || $iface_id ni $iface_list } {
					continue
				}

				lappend iface_ids $iface_id
			}
		}

		lappend nodes_ifaces_parsed "$node_id {$iface_ids}"
	}

	if { $nodes == {} } {
		return -code error "No nodes found!"
	}

	switch -exact -- $action {
		"config" {
			API_configIfaces $nodes_ifaces_parsed
		}

		"unconfig" {
			API_unconfigIfaces $nodes_ifaces_parsed
		}

		"reconfig" {
			API_reconfigIfaces $nodes_ifaces_parsed
		}
	}

	return
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
