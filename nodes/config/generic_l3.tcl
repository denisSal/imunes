# updateNode cases

addCase_updateNode "custom_image" {
	setNodeCustomImage $node_id $new_value
}

addCase_updateNode "docker_attach" {
	setNodeDockerAttach $node_id $new_value
}

addCase_updateNode "croutes4" {
	setNodeStatIPv4routes $node_id $new_value
}

addCase_updateNode "croutes6" {
	setNodeStatIPv6routes $node_id $new_value
}

addCase_updateNode "auto_default_routes" {
	setNodeAutoDefaultRoutesStatus $node_id $new_value
}

addCase_updateNode "services" {
	setNodeServices $node_id $new_value
}

addCase_updateNode "custom_configs" {
	set custom_configs_diff [dictDiff $old_value $new_value]
	dict for {custom_configs_key custom_configs_change} $custom_configs_diff {
		if { $custom_configs_change == "copy" } {
			continue
		}

		dputs "======== $custom_configs_change: '$custom_configs_key'"

		set custom_configs_old_value [_cfgGet $old_value $custom_configs_key]
		set custom_configs_new_value [_cfgGet $new_value $custom_configs_key]
		if { $custom_configs_change in "changed" } {
			dputs "======== OLD: '$custom_configs_old_value'"
		}
		if { $custom_configs_change in "new changed" } {
			dputs "======== NEW: '$custom_configs_new_value'"
		}

		set hook_diff [dictDiff $custom_configs_old_value $custom_configs_new_value]
		dict for {hook_key hook_change} $hook_diff {
			if { $hook_change == "copy" } {
				continue
			}

			dputs "============ $hook_change: '$hook_key'"

			set hook_old_value [_cfgGet $custom_configs_old_value $hook_key]
			set hook_new_value [_cfgGet $custom_configs_new_value $hook_key]
			if { $hook_change in "changed" } {
				dputs "============ OLD: '$hook_old_value'"
			}
			if { $hook_change in "new changed" } {
				dputs "============ NEW: '$hook_new_value'"
			}

			if { $hook_change == "removed" } {
				removeNodeCustomConfig $node_id $custom_configs_key $hook_key
			} else {
				try {
					dict get $hook_new_value "custom_command"
				} on ok cmd {
				} on error {} {
					set cmd [dict get $hook_old_value "custom_command"]
				}

				try {
					dict get $hook_new_value "custom_config"
				} on ok cfg {
				} on error {} {
					set cfg [dict get $hook_old_value "custom_config"]
				}

				setNodeCustomConfig $node_id $custom_configs_key $hook_key $cmd $cfg
			}
		}
	}
}

addCase_updateNode "custom_enabled" {
	setNodeCustomEnabled $node_id $new_value
}

addCase_updateNode "custom_selected" {
	set custom_selected_diff [dictDiff $old_value $new_value]
	dict for {custom_selected_key custom_selected_change} $custom_selected_diff {
		if { $custom_selected_change == "copy" } {
			continue
		}

		dputs "======== $custom_selected_change: '$custom_selected_key'"

		set custom_selected_old_value [_cfgGet $old_value $custom_selected_key]
		set custom_selected_new_value [_cfgGet $new_value $custom_selected_key]
		if { $custom_selected_change in "changed" } {
			dputs "======== OLD: '$custom_selected_old_value'"
		}
		if { $custom_selected_change in "new changed" } {
			dputs "======== NEW: '$custom_selected_new_value'"
		}

		setNodeCustomConfigSelected $node_id $custom_selected_key $custom_selected_new_value
	}
}

# updateIface cases

addCase_updateIface "oper_state" {
	setIfcOperState $node_id $iface_id $iface_prop_new_value
}

addCase_updateIface "nat_state" {
	setIfcNatState $node_id $iface_id $iface_prop_new_value
}

addCase_updateIface "mtu" {
	setIfcMTU $node_id $iface_id $iface_prop_new_value
}

addCase_updateIface "vlan_dev" {
	setIfcVlanDev $node_id $iface_id $iface_prop_new_value
}

addCase_updateIface "mac" {
	if { $iface_prop_new_value == "auto" } {
		autoMACaddr $node_id $iface_id
	} else {
		setIfcMACaddr $node_id $iface_id $iface_prop_new_value
	}
}

addCase_updateIface "ipv4_addrs" {
	if { $iface_prop_new_value == "auto" } {
		autoIPv4addr $node_id $iface_id
	} else {
		setIfcIPv4addrs $node_id $iface_id $iface_prop_new_value
	}
}

addCase_updateIface "ipv6_addrs" {
	if { $iface_prop_new_value == "auto" } {
		autoIPv6addr $node_id $iface_id
	} else {
		setIfcIPv6addrs $node_id $iface_id $iface_prop_new_value
	}
}
