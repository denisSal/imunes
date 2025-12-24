#
# Copyright 2005-2013 University of Zagreb.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

# $Id: rj45.tcl 130 2015-02-24 09:52:19Z valter $


#****h* imunes/rj45.tcl
# NAME
#  rj45.tcl -- defines rj45 specific procedures
# FUNCTION
#  This module is used to define all the rj45 specific procedures.
# NOTES
#  Procedures in this module start with the keyword rj45 and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE rj45
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#### required for every node
proc $MODULE.netlayer {} {
	return [genericL2.netlayer]
}
#### /required for every node

#****f* rj45.tcl/rj45.confNewNode
# NAME
#   rj45.confNewNode -- configure new node
# SYNOPSIS
#   rj45.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id [getNewNodeNameType rj45 $nodeNamingBase(rj45)]
}

#****f* rj45.tcl/rj45.ifacePrefix
# NAME
#   rj45.ifacePrefix -- interface name prefix
# SYNOPSIS
#   rj45.ifacePrefix
# FUNCTION
#   Returns rj45 interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
	return "x"
}

proc $MODULE.getPrivateNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid
	}

	if { $isOSfreebsd } {
		return $eid
	}
}

proc $MODULE.getPublicNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		# nothing
		return
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc $MODULE.getHookData { node_id iface_id } {
	global isOSlinux isOSfreebsd

	set public_elem [getIfcName $node_id $iface_id]
	set vlan [getIfcVlanTag $node_id $iface_id]

	if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
		set public_elem ${public_elem}_$vlan
	}

	if { $isOSlinux } {
		set hook_name ""
	}

	if { $isOSfreebsd } {
		set hook_name "lower"
	}

	return [list $public_elem $hook_name]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* rj45.tcl/rj45.prepareSystem
# NAME
#   rj45.prepareSystem -- prepare system
# SYNOPSIS
#   rj45.prepareSystem
# FUNCTION
#   Loads ng_ether into the kernel.
#****
proc $MODULE.prepareSystem {} {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return
	}

	if { $isOSfreebsd } {
		catch { rexec kldload ng_ether }

		return
	}
}

proc $MODULE.checkNodePrerequisites { eid node_id } {
	return true
}

proc $MODULE.checkIfacesPrerequisites { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	foreach iface_id $ifaces {
		removeStateNodeIface $node_id $iface_id "error"
		setStateErrorMsgNodeIface $node_id $iface_id ""

		if { [getIfcName $node_id $iface_id] == "UNASSIGNED" } {
			set ifaces [removeFromList $ifaces $iface_id]
		}
	}

	if { $ifaces == {} } {
		return true
	}

	set stolen {}
	set vlan_pairs [dict create]
	set direct {}
	foreach other_node_id [removeFromList [getFromRunning "node_list"] $node_id] {
		if {
			([getFromRunning "cfg_deployed"] &&
			! [isRunningNode $other_node_id]) ||
			$other_node_id in [getFromRunning "no_auto_execute_nodes"]
		} {
			continue
		}

		foreach other_iface_id [ifcList $other_node_id] {
			if {
				([getFromRunning "cfg_deployed"] &&
				(! [isRunningNodeIface $other_node_id $other_iface_id] ||
				"creating" ni [getStateNodeIface $other_node_id $other_iface_id])) ||
				$other_node_id in [getFromRunning "no_auto_execute_nodes"]
			} {
				continue
			}

			if { [getIfcType $other_node_id $other_iface_id] == "stolen" } {
				set other_iface_name [getIfcName $other_node_id $other_iface_id]
				set other_vlan [getIfcVlanTag $other_node_id $other_iface_id]
				set other_dev [getIfcVlanDev $other_node_id $other_iface_id]
				if { $other_vlan != "" && $other_dev != "" } {
					dict lappend vlan_pairs $other_dev $other_vlan
					set other_iface_name "${other_iface_name}_$other_vlan"
				}

				set other_link_id [getIfcLink $other_node_id $other_iface_id]
				if { $other_link_id != "" && [getLinkDirect $other_link_id] } {
					if { $other_iface_name ni $direct } {
						lappend direct $other_iface_name
					}

					continue
				}

				if { $other_iface_name ni $stolen } {
					lappend stolen $other_iface_name
				}

				continue
			}
		}
	}

	# check own ifaces
	set error_ifaces {}
	foreach iface_id $ifaces {
		setStateErrorMsgNodeIface $node_id $iface_id ""

		set add_to_vlan 0
		set vlan [getIfcVlanTag $node_id $iface_id]
		set dev_name [getIfcVlanDev $node_id $iface_id]
		if { $vlan != "" && $dev_name != "" } {
			set iface_name "${dev_name}_$vlan"
			set add_to_vlan 1
		} else {
			set iface_name [getIfcName $node_id $iface_id]
		}

		set link_id [getIfcLink $node_id $iface_id]
		set link_is_direct [getLinkDirect $link_id]
		set add_to_direct 0
		if { $link_id != "" && $link_is_direct } {
			if { $iface_name in $stolen } {
				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - already stolen in the experiment."
				}

				if { $iface_id ni $error_ifaces } {
					lappend error_ifaces $iface_id
				}
			}

			if { $dev_name != "" } {
				if { $dev_name in $stolen } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already stolen in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $iface_name in $stolen } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already used as a trunk in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}
			}

			if { $iface_name ni $direct } {
				set add_to_direct 1
			}
		}

		set add_to_stolen 0
		if { $link_is_direct == 0 } {
			if { $iface_name in $direct } {
				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Cannot steal '$iface_name' for $iface_id - already used as a direct interface in the experiment."
				}

				if { $iface_id ni $error_ifaces } {
					lappend error_ifaces $iface_id
				}
			}

			if { $iface_name in $stolen } {
				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - already stolen in the experiment."
				}

				if { $iface_id ni $error_ifaces } {
					lappend error_ifaces $iface_id
				}
			}

			if { $iface_name in [dict keys $vlan_pairs] } {
				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Cannot steal '$iface_name' for $iface_id - already used as a trunk in the experiment."
				}

				if { $iface_id ni $error_ifaces } {
					lappend error_ifaces $iface_id
				}
			}

			if { $dev_name != "" } {
				if { $dev_name in $direct } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already used in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $dev_name in $stolen } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already stolen in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $dev_name in [dict keys $vlan_pairs] && $vlan in [dictGet $vlan_pairs $dev_name] } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - VLAN $vlan already used in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}
			}

			if { $iface_name ni $stolen } {
				set add_to_stolen 1
			}
		}

		if { $add_to_vlan } {
			dict lappend vlan_pairs $dev_name $vlan
		}

		if { $add_to_direct } {
			lappend direct $iface_name
		}

		if { $add_to_stolen } {
			lappend stolen $iface_name
		}
	}

	set ifaces [removeFromList $ifaces $error_ifaces]

	set host_ifaces [getHostIfcList]

	set node_name [getNodeName $node_id]
	foreach iface_id $ifaces {
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id != "" && [getLinkDirect $link_id] } {
			continue
		}

		set vlan [getIfcVlanTag $node_id $iface_id]
		set dev_name [getIfcVlanDev $node_id $iface_id]
		if { $vlan == "" || $dev_name == "" } {
			set iface_name [getIfcName $node_id $iface_id]
			if { $iface_name ni $host_ifaces } {
				lappend error_ifaces $iface_id

				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - no interface on host!"
				}
			}

			continue
		}

		# check if VLAN ID is already taken
		# this can be only done by trying to create it, as it's possible that the same
		# VLAN interface already exists in some other namespace
		try {
			if { $isOSlinux } {
				rexec ip link add link $dev_name name ${dev_name}_$vlan type vlan id $vlan
			}

			if { $isOSfreebsd } {
				rexec ifconfig $dev_name.$vlan create
			}
		} on ok {} {
			if { $isOSlinux } {
				rexec ip link del ${dev_name}_$vlan
			}

			if { $isOSfreebsd } {
				rexec ifconfig $dev_name.$vlan destroy
			}
		} on error err {
			lappend error_ifaces $iface_id

			addStateNodeIface $node_id $iface_id "error"
			if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
				setStateErrorMsgNodeIface $node_id $iface_id "VLAN error on '$node_name', interface '$dev_name': $err"
			}
		}
	}

	foreach iface_id [removeFromList $ifaces $error_ifaces] {
		try {
			rexec test -d /sys/class/net/$iface_name/wireless
		} on error {} {
			# not wireless, so MAC address can be changed
			removeStateNodeIface $node_id $iface_id "wireless"
		} on ok {} {
			# we cannot use macvlan on wireless interfaces, so MAC address cannot be changed
			addStateNodeIface $node_id $iface_id "wireless"
			if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
				setStateErrorMsgNodeIface $node_id $iface_id "Wireless interface '$iface_name' for $iface_id detected, cannot change MAC address."
			}
		}
	}

	if { $error_ifaces != {} } {
		return false
	}

	return true
}

#****f* rj45.tcl/rj45.nodeCreate
# NAME
#   rj45.nodeCreate -- instantiate
# SYNOPSIS
#   rj45.nodeCreate $eid $node_id
# FUNCTION
#   Procedure rj45.nodeCreate puts real interface into promiscuous mode.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
	addStateNode $node_id "running"
}

proc $MODULE.nodeCreate_check { eid node_id } {
	return true
}

#****f* rj45.tcl/rj45.nodeNamespaceSetup
# NAME
#   rj45.nodeNamespaceSetup -- rj45 node nodeNamespaceSetup
# SYNOPSIS
#   rj45.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

proc $MODULE.nodeNamespaceSetup_check { eid node_id } {
	return true
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global ifacesconf_timeout

	# first deal with VLAN interfaces to avoid 'non-existant'
	# interface error
	set vlan_ifaces {}
	set nonvlan_ifaces {}
	foreach iface_id $ifaces {
		if { [getIfcVlanTag $node_id $iface_id] != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
			lappend vlan_ifaces $iface_id
		} else {
			lappend nonvlan_ifaces $iface_id
		}
	}

	addStateNode $node_id "pif_creating"

	foreach iface_id [concat $vlan_ifaces $nonvlan_ifaces] {
		#captureExtIfc $eid $node_id $iface_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		set iface_name [getIfcName $node_id $iface_id]
		#if { $iface_name == "UNASSIGNED" } {
		#	unsetRunning "${node_id}|${iface_id}_old_iface_vlan"
		#	unsetRunning "${node_id}|${iface_id}_old_iface_dev"
		#	continue
		#}

		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -

		set vlan [getIfcVlanTag $node_id $iface_id]
		set dev_name [getIfcVlanDev $node_id $iface_id]

		if { $isOSlinux } {
			if { $vlan != "" && $dev_name != "" } {
				pipesExec "ip link set $dev_name up" "hold"
				pipesExec "ip link add link $dev_name name $public_iface netns $private_ns type vlan id $vlan" "hold"
			}

			# actually, capture iface to experiment namespace
			pipesExec "ip link set $public_iface netns $private_ns" "hold"
			pipesExec "ip -n $private_ns link set $public_iface up promisc on" "hold"
		}

		if { $isOSfreebsd } {
			if { $vlan != "" && $dev_name != "" } {
				pipesExec "ifconfig $dev_name up" "hold"
				pipesExec "ifconfig $dev_name.$vlan create" "hold"
				pipesExec "ifconfig ${dev_name}.$vlan name $public_iface" "hold"
			}

			pipesExec "ifconfig $public_iface vnet $private_ns" "hold"
			pipesExec "jexec $private_ns ifconfig $public_iface up promisc" "hold"
		}

		setToRunning "${node_id}|${iface_id}_old_iface_name" $public_iface
		setToRunning "${node_id}|${iface_id}_old_iface_vlan" $vlan
		setToRunning "${node_id}|${iface_id}_old_iface_dev" $dev_name

		addStateNodeIface $node_id $iface_id "creating"
	}

	pipesExec ""

	return
}

proc $MODULE.nodePhysIfacesDirectCreate { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global ifacesconf_timeout

	foreach iface_id $ifaces {
		lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
		if { [getIfcName $node_id $iface_id] == "UNASSIGNED" } {
			removeStateNodeIface $peer_id $peer_iface_id "error creating running"

			continue
		}

		set peer_type [getNodeType $peer_id]
		if { $peer_type == "rj45" } {
			continue
		}

		addStateNode $peer_id "pif_creating"
		addStateNode $node_id "pif_creating"

		addStateNodeIface $peer_id $peer_iface_id "creating"
		addStateNodeIface $node_id $iface_id "running"

		set peer_ns [invokeNodeProc $peer_id "getPrivateNs" $eid $peer_id]
		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface ng_hook

		set vlan [getIfcVlanTag $node_id $iface_id]
		set dev_name [getIfcVlanDev $node_id $iface_id]

		set full_virtual_ifc $eid-$peer_id-$peer_iface_id
		if { $isOSlinux } {
			global devfs_number

			set public_ns "imunes_$devfs_number"
			if { $vlan != "" && $dev_name != "" } {
				pipesExec "ip -n $eid show $public_iface || ip -n $public_ns link add link $dev_name name $public_iface netns $eid type vlan id $vlan" "hold"
				set public_ns "$eid"
			}

			# if peer is NATIVE, just set it as master
			if { $peer_type ni "ext" && [invokeNodeProc $peer_id "virtlayer"] == "NATIVE" } {
				#captureExtIfcByName $eid $public_iface $peer_id
				pipesExec "ip link set $public_iface netns $peer_ns" "hold"

				#setNsIfcMaster $peer_ns $public_iface $peer_id "up"
				pipesExec "ip -n $public_ns link set $public_iface master $peer_id up" "hold"

				addStateNodeIface $peer_id $peer_iface_id "running"

				continue
			}

			set cmds "ip -n $public_ns link add link $public_iface name $full_virtual_ifc netns $peer_ns type"
			if { "wireless" ni [getStateNodeIface $node_id $iface_id] } {
				# not wireless, so MAC address can be changed
				set ether [getIfcMACaddr $peer_id $peer_iface_id]

				# you can set macvlan mode to bridge to enable bridging of nodes in the same experiment
				set cmds "$cmds macvlan mode private"
				set cmds "$cmds ; ip -n $peer_ns link set $full_virtual_ifc address $ether"
			} else {
				# we cannot use macvlan on wireless interfaces, so MAC address cannot be changed
				set cmds "$cmds ipvlan mode l2"
			}
			set cmds "$cmds ; ip -n $public_ns link set $public_iface up"

			if { $peer_type in "ext" } {
				set other_iface_name "$eid-$peer_id"
			} else {
				set other_iface_name [getIfcName $peer_id $peer_iface_id]
			}

			# assign the created macvlan/ipvlan to the peer interface
			set cmds "$cmds ; ip -n $peer_ns link set $full_virtual_ifc name $other_iface_name"
			set cmds "$cmds ; ip -n $peer_ns link set $other_iface_name up"

			pipesExec "$cmds" "hold"
		}

		if { $isOSfreebsd } {
		}
	}

	pipesExec ""

	return
}

proc $MODULE.nodePhysIfacesCreate_check { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global ifacesconf_timeout

	foreach iface_id $ifaces {
		set this_link_id [getIfcLink $node_id $iface_id]
		if {
			[isRunningNodeIface $node_id $iface_id] ||
			"creating" ni [getStateNodeIface $node_id $iface_id]
		} {
			set ifaces [removeFromList $ifaces $iface_id]
		}
	}

	if { $ifaces == {} } {
		removeStateNode $node_id "pif_creating lif_creating"

		return true
	}

	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

	if { $isOSlinux } {
		# get list of interface names
		set cmds "ip -br l | sed \"s/\[@\[:space:]].*//\""
		set cmds "ip netns exec $private_ns sh -c '$cmds'"
	}

	if { $isOSfreebsd } {
		# get list of interface names
		set cmds "ifconfig -l"
		set cmds "jexec $private_ns sh -c '$cmds'"
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
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -
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
					setStateErrorMsgNodeIface $node_id $iface_id "Interface '$iface_id' ([getIfcName $node_id $iface_id]) not created."
				}
			}
		}

		if { [llength $ifaces] == [llength $ifaces_created] } {
			removeStateNode $node_id "pif_creating lif_creating"

			return true
		}

		return false
	} on error {} {
		return false
	}

	return false
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodePhysIfacesDestroy { eid node_id ifaces } {
	addStateNode $node_id "ifaces_destroying"

	foreach iface_id $ifaces {
		releaseExtIfc $eid $node_id $iface_id

		removeStateNodeIface $node_id $iface_id "running"
	}
}

proc $MODULE.nodePhysIfacesDirectDestroy { eid node_id ifaces } {
	addStateNode $node_id "ifaces_destroying"
}

proc $MODULE.nodeIfacesDestroy_check { eid node_id ifaces } {
	removeStateNode $node_id "ifaces_destroying"

	foreach iface_id $ifaces {
		removeStateNodeIface $node_id $iface_id "error destroying running"
	}

	return true
}

#****f* rj45.tcl/rj45.nodeDestroy
# NAME
#   rj45.nodeDestroy -- destroy
# SYNOPSIS
#   rj45.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys an rj45 emulation interface.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
	removeStateNode $node_id "error running"
}

proc $MODULE.nodeDestroy_check { eid node_id } {
	return true
}
