proc parseImnCtl { args } {
	dputs "parseImnCtl =========================="
	dputs "ARGS: '$args'"
	set rest [lassign $args type action]

	dputs "TYPE: '$type'"
	dputs "ACTION: '$action'"
	dputs "REST: '$rest'"
	dputs "/parseImnCtl =========================="
	dputs ""

	if { $type == "" } {
		set type "help"
	}

	if { $action == "" } {
		set action "help"
	}

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
			set msg "Unknown element type '$type'. Possible types:\n"
			append msg "\t{node link iface}\n"

			return -code error $msg
		}
	}
}

proc parseImnCtlNode { action args } {
	set edit_actions "new remove"
	set attribute_actions "get set delete"
	set update_actions "update modify delete"
	set execute_actions "start stop restart"
	set config_actions "config unconfig reconfig"

	set actions [concat $edit_actions $attribute_actions $update_actions $execute_actions $config_actions]
	if { $action ni $actions } {
		set msg "Unknown node action '$action'. Possible actions:\n"
		append msg "Non-running experiment\n"
		append msg "\t{$edit_actions} - create/remove nodes\n"
		append msg "\t{$attribute_actions} - get/set specific attributes\n"
		append msg "\t{$update_actions} - change node configuration\n"
		append msg "Running experiment\n"
		append msg "\t{$execute_actions} - interact with nodes\n"
		append msg "\t{$config_actions} - interact with node configuration\n"

		return -code error $msg
	}

	if { $action in $edit_actions } {
		#TODO
		set rest [lassign $args node_type]

		dputs "parseImnCtlNode =========================="
		dputs "ACTION: '$action'"
		dputs "NODE_TYPE: '$node_type'"
		dputs "REST: '$rest'"
		dputs "/parseImnCtlNode =========================="
		dputs ""

		global all_modules_list

		if { $node_type == "" } {
			set node_type "help"
		}

		if { $node_type ni $all_modules_list } {
			set msg "Unknown node type '$node_type'. Possible types:\n"
			append msg "\t{$all_modules_list}\n"

			return -code error $msg
		}

		return
	}

	if { $action in $attribute_actions } {
		set new_value [lassign $args node_id_name attribute_unparsed]

		dputs "parseImnCtlNode =========================="
		dputs "ACTION: '$action'"
		dputs "NODE_ID_NAME: '$node_id_name'"
		dputs "ATTRIBUTE: '$attribute_unparsed'"
		dputs "NEWVALUE: '$new_value'"
		dputs "/parseImnCtlNode =========================="
		dputs ""

		set node_id [getNodeIdFromHostname $node_id_name]
		if { $node_id == "" } {
			set msg "Node not given. Possible nodes:\n"
			append msg "\t[getFromRunning "node_list"]"

			return -code error $msg
		}

		if { $attribute_unparsed == "" } {
			set attribute_unparsed "help"
		}

		set attribute_to_search [string tolower $attribute_unparsed]
		set attribute_index -1
		set all_attributes {}
		foreach is_gui "{} _gui" {
			foreach proc_type "set get" {
				global node_${proc_type}_attributes${is_gui}

				set attribute_index [lsearch \
					[string tolower [set node_${proc_type}_attributes${is_gui}]] \
					$attribute_to_search]

				if { $attribute_index != -1 } {
					set attribute [lindex [set node_${proc_type}_attributes${is_gui}] $attribute_index]
					break
				}
			}

			if { $attribute_index != -1 } {
				break
			}
		}

		if { $attribute_index == -1 } {
			set msg "Attribute not given. Possible attributes:\n"
			foreach is_gui "{} _gui" {
				foreach proc_type "set get" {
					append msg "\t node_${proc_type}_attributes${is_gui}: "
					append msg "{[set node_${proc_type}_attributes${is_gui}]}\n"
				}
			}

			return -code error $msg
		}

		set rest [lassign $attribute attribute]

		switch -exact -- $action {
			"delete" -
			"set" {
				if { $action == "delete" } {
					set new_value ""
				}

				setNode$attribute $node_id {*}$rest {*}$new_value
				saveCfgJson [getFromRunning "current_file"]
			}

			"get" {
				puts [getNode$attribute $node_id {*}$rest]
				return [getNode$attribute $node_id {*}$rest]
			}
		}

		return
	}

	if { $action in $update_actions } {
		set json [lassign $args node_id]
		#dputs "JSON: '$json'"
		set json_dict [json::json2dict $json]
		#dputs "JSON_DICT: '$json_dict'"

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

	if { $action in [concat $execute_actions $config_actions] } {
		set node_ids_names $args
		dputs "parseImnCtlNode =========================="
		dputs "ACTION: '$action'"
		dputs "NODES: '$node_ids_names'"
		dputs "/parseImnCtlNode =========================="
		dputs ""

		if { $node_ids_names == {} } {
			set msg "Missing list of nodes, for example:\n"
			append msg "\timunes --ctl -e eid node stop 'pc2 router1'"

			return -code error $msg
		}

		set rest [lassign $node_ids_names node_ids_names]
		if { $rest != "" } {
			set msg "Please use a list of nodes, using the apostrophe:\n"
			append msg "\timunes --ctl -e eid node stop 'pc2 router1'"

			return -code error $msg
		}

		set nodes {}
		foreach node_id_name $node_ids_names {
			if { $node_id_name in $nodes } {
				continue
			}

			set node_id [getNodeIdFromHostname $node_id_name]
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
		set msg "Unknown iface action '$action'. Possible actions:\n"
		append msg "\t{$config_actions} - interact with interface configuration\n"

		return -code error $msg
	}

	if { $action in $config_actions } {
		set nodes_ifaces $args

		dputs "parseImnCtlIface =========================="
		dputs "NODES_IFACES: '$nodes_ifaces'"
		dputs "/parseImnCtlIface =========================="
		dputs ""

		if { $nodes_ifaces == {} } {
			set msg "Missing lists of nodes and interfaces, for example:\n"
			append msg "\timunes --ctl -e eid iface config 'pc2 eth0 eth2' 'pc3 *'"

			return -code error $msg
		}

		set nodes {}
		set nodes_ifaces_parsed {}
		foreach node_ifaces $nodes_ifaces {
			set iface_names [lassign $node_ifaces node_id_name]
			if { $iface_names == {} } {
				set msg "Missing interfaces in the list, for example:\n"
				append msg "\timunes --ctl -e eid iface config 'pc2 eth0 eth2' 'pc3 *'"

				return -code error $msg
			}

			set node_id [getNodeIdFromHostname $node_id_name]
			if { $node_id == "" } {
				continue
			}

			if { $node_id ni $nodes } {
				lappend nodes $node_id
			}

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
	}

	return
}
