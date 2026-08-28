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
		addStateNode $node_id "node_creating"

		set VROOTDIR [getVrootDir]
		set VROOT_RUNTIME $VROOTDIR/$eid/$node_id

		pipesExec "mkdir -p $VROOT_RUNTIME &" "hold"

		set meta_data "instance-id: imunes-$node_id-[clock seconds]"
		set meta_fname $VROOT_RUNTIME/meta-data
		append meta_data "\nlocal-hostname: [getNodeName $node_id]"
		writeDataToFile $meta_fname $meta_data

		set user_data "#cloud-config"
		set user_fname $VROOT_RUNTIME/user-data
		writeDataToFile $user_fname $user_data

		set network_config "version: 2"
		set netconf_fname $VROOT_RUNTIME/network-config
		append network_config "\nethernets:"
		foreach iface_id [allIfcList $node_id] {
			set iface_name [getIfcName $node_id $iface_id]
			append network_config "\n  $iface_name:"
			append network_config "\n    match:"
			append network_config "\n      macaddress: \"[getIfcMACaddr $node_id $iface_id]\""
			append network_config "\n    set-name: \"$iface_name\""
			set ipv4_addrs [getIfcIPv4addrs $node_id $iface_id]
			set ipv6_addrs [getIfcIPv6addrs $node_id $iface_id]
			if { $ipv4_addrs != {} || $ipv6_addrs != {} } {
				append network_config "\n    addresses:"

				foreach ipv4_addr $ipv4_addrs {
					append network_config "\n      - $ipv4_addr"
				}

				foreach ipv6_addr $ipv6_addrs {
					append network_config "\n      - $ipv6_addr"
				}
			}
		}
		writeDataToFile $netconf_fname $network_config

		set seed_fname $VROOT_RUNTIME/seed.img
		rexec truncate -s 128K $seed_fname
		rexec mformat -i $seed_fname -v cidata ::
		rexec mcopy -i $seed_fname $meta_fname $user_fname $netconf_fname ::

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
		append args " -m [dictGet $vm_cfg "memory_size"]"
		if { $iso_path != "" } {
			append args "$args -cdrom $iso_path -boot d"
		}
		append args " -smp $cpu_count"
		append args " -hda $hdd_path"
		append args " -cpu host"
		append args " --enable-kvm"
		append args " -daemonize"

		foreach iface_id [ifcList $node_id] {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -

			set mac [getIfcMACaddr $node_id $iface_id]
			append args " -netdev tap,id=$iface_id,ifname=$eid-$public_iface,script=no,downscript=no -device virtio-net,netdev=$iface_id,mac=$mac"
		}

		append args " -qmp unix:$VROOT_RUNTIME/control.socket,server,nowait"
		append args " -vnc unix:$VROOT_RUNTIME/vnc.socket"

		# cloud init
		append args " -drive file=$VROOT_RUNTIME/seed.img,format=raw,if=virtio"

		# qemu agent
		append args " -chardev socket,path=$VROOT_RUNTIME/agent.socket,server=on,wait=off,id=qga0"
		append args " -device virtio-serial"
		append args " -device virtserialport,chardev=qga0,name=org.qemu.guest.agent.0"

		# console
		append args " -chardev socket,path=$VROOT_RUNTIME/console.socket,server=on,wait=off,id=console0"
		append args " -device virtio-serial"
		append args " -device virtconsole,chardev=console0"

		dputs "qemu-system-x86_64 $args"

		pipesExec "qemu-system-x86_64 $args" "hold"
	}

	proc nodeCreate_check { eid node_id } {
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

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

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
		addStateNode $node_id "node_destroying"

		set VROOTDIR [getVrootDir]
		set VROOT_RUNTIME $VROOTDIR/$eid/$node_id

		pipesExec "echo '{\"execute\": \"qmp_capabilities\"} {\"execute\": \"system_powerdown\"}' | sudo socat unix-connect:$VROOT_RUNTIME/control.socket -" "hold"
	}

	proc nodeDestroy_check { eid node_id } {
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
