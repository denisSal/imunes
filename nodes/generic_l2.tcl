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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

proc genericL2.netlayer {} {
	return LINK
}

proc genericL2.virtlayer {} {
	return NATIVE
}

proc genericL2.confNewNode { node_id } {
	setNodeName $node_id $node_id
}

proc genericL2.confNewIfc { node_id iface_id } {
}

proc genericL2.generateConfigIfaces { node_id ifaces } {
}

proc genericL2.generateUnconfigIfaces { node_id ifaces } {
}

proc genericL2.generateConfig { node_id } {
}

proc genericL2.generateUnconfig { node_id } {
}

proc genericL2.ifacePrefix {} {
	return "e"
}

proc genericL2.IPAddrRange {} {
}

proc genericL2.bootcmd { node_id } {
}

proc genericL2.shellcmds {} {
}

proc genericL2.getPrivateNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid-$node_id
	}

	if { $isOSfreebsd } {
		return $eid
	}
}

proc genericL2.getPublicNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc genericL2.getHookData { node_id iface_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		# public part of veth pair
		set public_elem "$node_id-$iface_id"
		set hook_name ""
	}

	if { $isOSfreebsd } {
		# name of public netgraph peer
		set public_elem $node_id
		set hook_name "link[expr [string range $iface_id 3 end] + 1]"
	}

	return [list $public_elem $hook_name]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

proc genericL2.prepareSystem {} {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		catch { rexec sysctl net.bridge.bridge-nf-call-arptables=0 }
		catch { rexec sysctl net.bridge.bridge-nf-call-iptables=0 }
		catch { rexec sysctl net.bridge.bridge-nf-call-ip6tables=0 }

		return
	}

	if { $isOSfreebsd } {
		catch { rexec kldload ng_hub }

		return
	}
}

proc genericL2.nodeCreate { eid node_id } {
	global isOSlinux isOSfreebsd

	setToRunning "${node_id}_running" "creating"

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		pipesExec "ip -n $private_ns link add name $node_id type bridge ageing_time 0" "hold"
		pipesExec "ip -n $private_ns link set $node_id up" "hold"

		return
	}

	if { $isOSfreebsd } {
		# create an ng node and make it persistent in the same command
		# hub demands hookname 'linkX'
		set ngcmds "mkpeer hub link1 link1\n"
		set ngcmds "$ngcmds msg .link1 setpersistent\n"
		set ngcmds "$ngcmds name .link1 $node_id\n"

		pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"

		return
	}
}

proc genericL2.nodeCreate_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodecreate_timeout

	if { [getFromRunning "${node_id}_running"] == "true" } {
		return true
	}

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "ip netns exec $private_ns ip link show dev $node_id | grep -q \"<.*UP.*>\""
	}

	if { $isOSfreebsd } {
		set cmds "jexec $eid ngctl show $node_id:"
	}

	if { $nodecreate_timeout >= 0 } {
		set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

proc genericL2.nodeNamespaceSetup { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		pipesExec "ip netns add $eid-$node_id" "hold"

		return
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc genericL2.nodeNamespaceSetup_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodecreate_timeout

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "ip netns exec $private_ns true"

		if { $nodecreate_timeout >= 0 } {
			set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
		}

		return [isOk $cmds]
	}

	if { $isOSfreebsd } {
		return true
	}
}

proc genericL2.nodeInitConfigure { eid node_id } {
}

proc genericL2.nodeInitConfigure_check { eid node_id } {
	return true
}

proc genericL2.nodePhysIfacesCreate { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		# Create "physical" network interfaces
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"

			set iface_name [getIfcName $node_id $iface_id]

			if { [getIfcType $node_id $iface_id] == "stolen" } {
				# private hook is interface name in this case
				captureExtIfcByName $eid $iface_name $node_id
			} else {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -

				# Create a veth pair - private hook in node NS and public hook
				# in the experiment NS
				createNsVethPair $iface_name $private_ns $public_iface $public_ns
			}

			# bridge private hook with L2 node (node id is master)
			setNsIfcMaster $private_ns $iface_name $node_id "up"
		}

		pipesExec ""

		return
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			if { [getIfcType $node_id $iface_id] != "stolen" } {
				# skip testing for L2 interfaces as they are not really created on FreeBSD
				setToRunning "${node_id}|${iface_id}_running" "true"

				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"

			set iface_name [getIfcName $node_id $iface_id]
			captureExtIfcByName $eid $iface_name $node_id

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] ngpeer1 nghook1
			set ngpeer2 $iface_name
			set nghook2 "lower"

			pipesExec "jexec $eid ngctl connect $ngpeer1: $ngpeer2: $nghook1 $nghook2" "hold"
		}

		return
	}
}

proc genericL2.nodePhysIfacesCreate_check { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global ifacesconf_timeout

	if { $ifaces == {} } {
		return $ifaces
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
		if { $ifaces_all == "" } {
			return ""
		}

		set ifaces_created {}
		foreach iface_id $ifaces {
			if {
				[getFromRunning "${node_id}|${iface_id}_running"] == "true" ||
				[getIfcName $node_id $iface_id] in $ifaces_all
			} {
				lappend ifaces_created $iface_id
			}
		}

		return $ifaces_created
	} on error {} {
		return ""
	}

	return $ifaces
}

proc genericL2.nodePhysIfacesCreateDirect { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		# Create "physical" network interfaces
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id == "" || ! [getLinkDirect $this_link_id] } {
				continue
			}

			lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
			if { [getFromRunning "${peer_id}_running"] ni "true" } {
				# peer node is not alive, skip creating this iface
				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"
			if { [getFromRunning "${peer_id}|${peer_iface_id}_running"] in "true creating" } {
				# skip creating our iface since it's already being created by peer
				continue
			}

			setToRunning "${peer_id}|${peer_iface_id}_running" "creating"

			set peer_type [getNodeType $peer_id]
			if { $peer_type == "rj45" } {
				# rj45 nodes will deal with the creation of our iface
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]

			set other_netns [invokeNodeProc $peer_id "getPrivateNs" $eid $peer_id]
			set other_iface_name [getIfcName $peer_id $peer_iface_id]

			# Create a veth pair - private hook in node NS and other hook
			# in the other node NS
			createNsVethPair $iface_name $private_ns $other_iface_name $other_netns

			if { [invokeNodeProc $peer_id "virtlayer"] == "NATIVE" } {
				setNsIfcMaster $other_netns $other_iface_name $peer_id "up"
			}

			# bridge private hook with L2 node
			setNsIfcMaster $private_ns $iface_name $node_id "up"
		}

		pipesExec ""

		return
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id == "" || ! [getLinkDirect $this_link_id] } {
				continue
			}

			# skip testing for L2 interfaces as they are not really created on FreeBSD
			setToRunning "${node_id}|${iface_id}_running" "true"
		}

		return
	}
}

proc genericL2.nodeLogIfacesCreate { eid node_id ifaces } {
}

proc genericL2.nodeIfacesConfigure { eid node_id ifaces } {
}

proc genericL2.nodeIfacesConfigure_check { eid node_id ifaces } {
	return true
}

proc genericL2.nodeConfigure { eid node_id } {
}

proc genericL2.nodeConfigure_check { eid node_id } {
	return true
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc genericL2.nodeIfacesUnconfigure { eid node_id ifaces } {
}

proc genericL2.nodeIfacesUnconfigure_check { eid node_id } {
	return true
}

proc genericL2.nodeLogIfacesDestroy { eid node_id ifaces } {
}

proc genericL2.nodePhysIfacesDestroy { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			if { [getIfcType $node_id $iface_id] == "stolen" } {
				set iface_name [getIfcName $node_id $iface_id]
				releaseExtIfcByName $eid $iface_name $node_id
			} else {
				set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -

				pipesExec "ip -n $public_ns link del $public_iface" "hold"
			}

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}
		}

		return
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			if { [getIfcType $node_id $iface_id] != "stolen" } {
				if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
					# skip testing for L2 interfaces as they are not really created on FreeBSD
					setToRunning "${node_id}|${iface_id}_running" "false"
				}

				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			releaseExtIfcByName $eid $iface_name $node_id
			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}
		}

		return
	}
}

proc genericL2.nodePhysIfacesDestroyDirect { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id == "" || ! [getLinkDirect $this_link_id] } {
				continue
			}

			if { [getFromRunning "${node_id}_running"] in "false stopping" } {
				# skip creating our iface since it's already being stopped by peer
				continue
			}

			lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
			if { [getFromRunning "${peer_id}_running"] ni "true" } {
				# peer node is not alive, skip
				setToRunning "${node_id}|${iface_id}_running" "false"
				continue
			}

			if { [getFromRunning "${peer_id}|${peer_iface_id}_running"] in "false stopping" } {
				# skip creating our iface since it's already being stopped by peer
				setToRunning "${node_id}|${iface_id}_running" "false"
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			pipesExec "ip -n $private_ns link del $iface_name" "hold"

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}

			if { [getFromRunning "${peer_id}|${peer_iface_id}_running"] == "true" } {
				setToRunning "${peer_id}|${peer_iface_id}_running" "stopping"
			}
		}

		return
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				# skip testing for L2 interfaces as they are not really created on FreeBSD
				setToRunning "${node_id}|${iface_id}_running" "false"
			}
		}

		return
	}
}

proc genericL2.nodeIfacesDestroy_check { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global skip_nodes ifacesconf_timeout

	if {
		$node_id in $skip_nodes || $ifaces == "" ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return $ifaces
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
		if { $ifaces_all == "" } {
			return $ifaces
		}

		set ifaces_destroyed {}
		foreach iface_id $ifaces {
			if { [getFromRunning "${node_id}|${iface_id}_running"] == "false" } {
				lappend ifaces_destroyed $iface_id

				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			if { $iface_name ni $ifaces_all || $iface_name == "lo0" } {
				lappend ifaces_destroyed $iface_id
			}
		}
	} on error {} {
		return ""
	}

	return $ifaces_destroyed
}

proc genericL2.nodeUnconfigure { eid node_id } {
}

proc genericL2.nodeUnconfigure_check { eid node_id } {
	return true
}

proc genericL2.nodeShutdown { eid node_id } {
}

proc genericL2.nodeShutdown_check { eid node_id } {
	return true
}

proc genericL2.nodeDestroy { eid node_id } {
	global isOSlinux isOSfreebsd

	if { [getFromRunning "${node_id}_running"] == "true" } {
		setToRunning "${node_id}_running" "stopping"
	}

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		# delete our bridge and namespace
		pipesExec "ip -n $private_ns link delete $node_id" "hold"
		pipesExec "ip netns del $private_ns" "hold"

		return
	}

	if { $isOSfreebsd } {
		pipesExec "jexec $eid ngctl msg $node_id: shutdown" "hold"

		return
	}
}

proc genericL2.nodeDestroy_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global skip_nodes nodecreate_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] == "false"
	} {
		return true
	}

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "ip netns exec $private_ns true"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $eid ngctl show $node_id:"
	}

	if { $nodecreate_timeout >= 0 } {
		set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
	}

	return [isNotOk $cmds]
}

proc genericL2.nodeDestroyFS { eid node_id } {
}

proc genericL2.nodeDestroyFS_check { eid node_id } {
	return true
}
