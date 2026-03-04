set MODULE qemu
registerModule $MODULE

namespace eval $MODULE {
	namespace import ::genericL3::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "qemu"
	}

	proc confNewNode { node_id } {
		invokeTypeProc "genericL2" "confNewNode" $node_id
	}

	proc confNewIfc { node_id iface_id } {
		autoMACaddr $node_id $iface_id
	}

	proc generateConfigIfaces { node_id ifaces } {
	}

	proc generateUnconfigIfaces { node_id ifaces } {
	}

	proc generateConfig { node_id } {
	}

	proc generateUnconfig { node_id } {
	}

	proc IPAddrRange {} {
	}

	proc bootcmd { node_id } {
	}

	proc shellcmds {} {
	}

	proc getExecCommand { eid node_id { interactive "" } } {
	}

	proc getPrivateNs { eid node_id } {
		return $eid.$node_id
	}

	proc getPublicNs { eid node_id } {
		return $eid
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		# Linux - interface name of the node (inside node namespace)
		# FreeBSD - interface name of the node (inside node jail)
		set private_elem [getIfcName $node_id $iface_id]

		# Linux - public part of veth pair (inside EID namespace)
		# FreeBSD - name of public netgraph peer (inside EID jail)
		set public_elem "$node_id-$iface_id"

		# Linux - not used
		# FreeBSD - hook for connecting to netgraph node
		set hook_name ""

		return [list $private_elem $public_elem $hook_name]
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	proc checkNodePrerequisites { eid node_id } {
		set vm_cfg [getNodeVMConfig $node_id]
		if { [dictGet $vm_cfg "create_hdd"] != 1 } {
			return true
		}

		set hdd_path [dictGet $vm_cfg "hdd_path"]
		catch { rexec ls $hdd_path } status
		if { ! [catch { rexec ls $hdd_path } status] } {
			addStateNode $node_id "error"
			setStateErrorMsgNode $node_id "ERROR: Cannot create $hdd_path for node $node_id ([getNodeName $node_id]) - file already exists!"

			return false
		}

		foreach iface_id [allIfcList $node_id] {
			setStateNodeIface $node_id $iface_id ""
		}

		removeStateNode $node_id "error"

		return true
	}

	proc checkIfacesPrerequisites { eid node_id ifaces } {
		# TODO: provjeri sve interface s istim imenom i ako postoji neki odbij
		return true
	}

	proc nodeCreate { eid node_id } {
		global runtimeDir

		addStateNode $node_id "node_creating"

		set vm_cfg [getNodeVMConfig $node_id]
		set hdd_path [dictGet $vm_cfg "hdd_path"]
		set iso_path [dictGet $vm_cfg "iso_path"]
		set cpu_count [dictGet $vm_cfg "cpu_count"]

		if { [dictGet $vm_cfg "create_hdd"] == 1 } {
			set size [dictGet $vm_cfg "create_hdd_size"]
			dputs "qemu-img create -f qcow2 $hdd_path $size"
			pipesExec "qemu-img create -f qcow2 $hdd_path $size" "hold"
		}

		set args ""
		set args "$args -m [dictGet $vm_cfg "memory_size"]"
		if { $iso_path != "" } {
			set args "$args -cdrom $iso_path -boot d"
		}
		set args "$args -smp $cpu_count"
		set args "$args -hda $hdd_path"
		set args "$args -cpu host"
		set args "$args --enable-kvm"
		set args "$args -daemonize"

		foreach iface_id [ifcList $node_id] {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -

			set mac [getIfcMACaddr $node_id $iface_id]
			set args "$args -netdev tap,id=$iface_id,ifname=$eid-$public_iface,script=no,downscript=no -device virtio-net,netdev=$iface_id,mac=$mac"
		}

		set exp_runtime_dir [getExperimentRuntimeDir]
		set args "$args -qmp unix:$exp_runtime_dir/$node_id-control.socket,server,nowait"
		set args "$args -vnc unix:$exp_runtime_dir/$node_id-vnc.socket"

		dputs "qemu-system-x86_64 $args"

		pipesExec "qemu-system-x86_64 $args" "hold"
	}

	proc nodeCreate_check { eid node_id } {
		global nodecreate_timeout
		# TODO: check using a qmp message?
		after 100
		addStateNode $node_id "running"
		return 1
	}

	proc nodeNamespaceSetup { eid node_id } {
	}

	proc nodeNamespaceSetup_check { eid node_id } {
	}

	proc nodeInitConfigure { eid node_id } {
	}

	proc nodeInitConfigure_check { eid node_id } {
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_creating"

		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]
		foreach iface_id $ifaces {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -

			if { $isOSlinux } {
				pipesExec "ip link set $eid-$public_iface netns $public_ns name $public_iface" "hold"
			}

			if { $isOSfreebsd } {
				pipesExec "ifconfig $eid-$public_iface vnet $eid" "hold"
				pipesExec "jexec $public_ns ifconfig $eid-$public_iface name $public_iface" "hold"
			}

			addStateNodeIface $node_id $iface_id "creating"
		}
	}

	proc nodePhysIfacesDirectCreate { eid node_id ifaces } {
		return [invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces]
	}

	proc nodeLogIfacesCreate { eid node_id ifaces } {
	}

	proc nodePhysIfacesCreate_check { eid node_id ifaces } {
		#set cmds {printf "{\"execute\":\"qmp_capabilities\"}\n{\"execute\":\"query-pci\"}\n" | socat -t100 - UNIX-CONNECT:}
		#set cmds "\'$cmds[getExperimentRuntimeDir]/$node_id-control.socket\'"

		#try {
		#	if { $nodecreate_timeout >= 0 } {
		#		rexec timeout [expr $nodecreate_timeout/5.0] sh -c $cmds
		#	} else {
		#		rexec sh -c $cmds
		#	}
		#} on ok status {
		#	set dict_status [json::json2dict "{[lindex $status end]}"]

		#	if { [dictGet $dict_status "return" "running"] == "true" } {
		#		return true
		#	}
		#}
		global isOSlinux isOSfreebsd
		global ifacesconf_timeout

		foreach iface_id $ifaces {
			if {
				[isRunningNodeIface $node_id $iface_id] ||
				"creating" ni [getStateNodeIface $node_id $iface_id]
			} {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		if { $isOSlinux } {
			# get list of interface names
			set cmds "ip -br l | sed \"s/\[@\[:space:]].*//\""
			set cmds "ip netns exec $public_ns sh -c '$cmds'"
		}

		if { $isOSfreebsd } {
			# get list of interface names
			set cmds "ifconfig -l"
			if { $public_ns != "" } {
				set cmds "jexec $public_ns sh -c '$cmds'"
			}
		}

		if { $ifacesconf_timeout >= 0 } {
			set cmds "timeout [expr $ifacesconf_timeout/5.0] $cmds"
		}

		try {
			rexec $cmds
		} on ok ifaces_all {
			if { [string trim $ifaces_all "\n "] == "" } {
				return false
			}

			set ifaces_created {}
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
				if {
					[isRunningNodeIface $node_id $iface_id] ||
					("creating" in [getStateNodeIface $node_id $iface_id] &&
					$public_iface in $ifaces_all)
				} {
					lappend ifaces_created $iface_id

					removeStateNodeIface $node_id $iface_id "error creating"
					setStateErrorMsgNodeIface $node_id $iface_id ""
					addStateNodeIface $node_id $iface_id "running"
				} else {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Interface '$iface_id' ($public_iface not created."
					}
				}
			}

			if { [llength $ifaces] == [llength $ifaces_created] } {
				return true
			}

			return false
		} on error {} {
			return false
		}

		return false
	}

	proc nodeIfacesConfigure { eid node_id ifaces } {
	}

	proc nodeIfacesConfigure_check { eid node_id ifaces } {
	}

	proc nodeConfigure { eid node_id } {
	}

	proc nodeConfigure_check { eid node_id } {
	}

	proc isNodeError { eid node_id } {
		# TODO: qmp
		return false
	}

	proc isNodeErrorIfaces { eid node_id } {
		# TODO: qmp
		return false
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
	}

	proc nodeUnconfigure_check { eid node_id } {
	}

	proc nodeShutdown { eid node_id } {
		# TODO: qmp poweroff
	}

	proc nodeShutdown_check { eid node_id } {
		# TODO: check if off
	}

	proc nodeIfacesUnconfigure { eid node_id ifaces } {
	}

	proc nodeIfacesUnconfigure_check { eid node_id ifaces } {
	}

	proc nodeLogIfacesDestroy { eid node_id ifaces } {
	}

	proc nodePhysIfacesDestroy { eid node_id ifaces } {
	}

	proc nodePhysIfacesDirectDestroy { eid node_id ifaces } {
	}

	proc nodeIfacesDestroy_check { eid node_id ifaces } {
	}

	proc nodeDestroy { eid node_id } {
		global runtimeDir

		addStateNode $node_id "node_destroying"

		pipesExec "echo '{\"execute\": \"qmp_capabilities\"} {\"execute\": \"system_powerdown\"}' | sudo socat unix-connect:[getExperimentRuntimeDir]/$node_id-control.socket -" "hold"
	}

	proc nodeDestroy_check { eid node_id } {
		global nodecreate_timeout
		after 100
		# TODO
		#set cmds {printf "{\"execute\":\"qmp_capabilities\"}\n{\"execute\":\"query-status\"}\n" | socat -t100 - UNIX-CONNECT:}
		#set cmds "\'$cmds[getExperimentRuntimeDir]/$node_id-control.socket\'"

		#try {
		#	if { $nodecreate_timeout >= 0 } {
		#		rexec timeout [expr $nodecreate_timeout/5.0] sh -c $cmds
		#	} else {
		#		rexec sh -c $cmds
		#	}
		#} on ok status {
		#	set dict_status [json::json2dict "{[lindex $status end]}"]

		#	if { [dictGet $dict_status "return" "running"] == "true" } {
		#		return false
		#	}
		#} on error {} {
		#}

		return true
	}

	proc nodeDestroyFS { eid node_id } {
		addStateNode $node_id "node_destroying_fs"
		# TODO: remove sockets
	}

	proc nodeDestroyFS_check { eid node_id } {
		removeStateNode $node_id "error running"
		return true
	}
}
