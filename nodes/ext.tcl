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

# $Id: ext.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/ext.tcl
# NAME
#  ext.tcl -- defines ext specific procedures
# FUNCTION
#  This module is used to define all the ext specific procedures.
# NOTES
#  Procedures in this module start with the keyword ext and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE ext
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#### required for every node
proc $MODULE.netlayer {} {
	return [genericL3.netlayer]
}
#### /required for every node

#****f* ext.tcl/ext.virtlayer
# NAME
#   ext.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [ext.virtlayer]
# FUNCTION
#   Returns the layer on which the ext is instantiated i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
	return NATIVE
}

#****f* ext.tcl/ext.confNewNode
# NAME
#   ext.confNewNode -- configure new node
# SYNOPSIS
#   ext.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id [getNewNodeNameType ext $nodeNamingBase(ext)]
	setNodeNATIface $node_id "UNASSIGNED"
}

#****f* ext.tcl/ext.confNewIfc
# NAME
#   ext.confNewIfc -- configure new interface
# SYNOPSIS
#   ext.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
	global mac_byte4 mac_byte5

	autoIPv4addr $node_id $iface_id
	autoIPv6addr $node_id $iface_id

	set bkp_mac_byte4 $mac_byte4
	set bkp_mac_byte5 $mac_byte5
	randomizeMACbytes
	autoMACaddr $node_id $iface_id
	set mac_byte4 $bkp_mac_byte4
	set mac_byte5 $bkp_mac_byte5
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

#****f* ext.tcl/ext.ifacePrefix
# NAME
#   ext.ifacePrefix -- interface name
# SYNOPSIS
#   ext.ifacePrefix
# FUNCTION
#   Returns ext interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
	return "ext"
}

#****f* ext.tcl/ext.maxIfaces
# NAME
#   ext.maxIfaces -- maximum number of links
# SYNOPSIS
#   ext.maxIfaces
# FUNCTION
#   Returns ext node maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxIfaces {} {
	return 1
}

proc $MODULE.getPrivateNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		global devfs_number

		return "imunes_$devfs_number"
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc $MODULE.getPublicNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid
	}

	if { $isOSfreebsd } {
		return $eid
	}
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* ext.tcl/ext.prepareSystem
# NAME
#   ext.prepareSystem -- prepare system
# SYNOPSIS
#   ext.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
	global isOSfreebsd

	if { $isOSfreebsd } {
		catch { rexec kldload ipfilter }
	}

	catch { rexec sysctl net.inet.ip.forwarding=1 }
}

proc $MODULE.checkNodePrerequisites { eid node_id } {
	setStateErrorMsgNode $node_id ""

	foreach iface_id [allIfcList $node_id] {
		addStateNodeIface $node_id $iface_id "creating"
		set ext_ifc_exists [invokeNodeProc $node_id "nodePhysIfacesCreate_check" $eid $node_id $iface_id]
		removeStateNodeIface $node_id $iface_id "creating running"
		if { $ext_ifc_exists } {
			addStateNode $node_id "error"
			setStateErrorMsgNode $node_id "Interface '$eid-$node_id' already exists in global namespace!"

			return false
		}

		setStateNodeIface $node_id $iface_id ""
	}

	removeStateNode $node_id "error"

	return true
}

proc $MODULE.checkIfacesPrerequisites { eid node_id ifaces } {
	# TODO
	removeStateNode $node_id "pifaces_creating lifaces_creating"

	return true
}

#****f* ext.tcl/ext.nodeCreate
# NAME
#   ext.nodeCreate -- instantiate
# SYNOPSIS
#   ext.nodeCreate $eid $node_id
# FUNCTION
#   Creates an ext node.
#   Does nothing, as it is not created per se.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
	if { ! [isErrorNode $node_id] } {
		setStateNode $node_id "running"
	}
}

#****f* ext.tcl/ext.nodeNamespaceSetup
# NAME
#   ext.nodeNamespaceSetup -- ext node nodeNamespaceSetup
# SYNOPSIS
#   ext.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

#****f* ext.tcl/ext.nodeInitConfigure
# NAME
#   ext.nodeInitConfigure -- ext node nodeInitConfigure
# SYNOPSIS
#   ext.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	addStateNode $node_id "pifaces_creating"

	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
	set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]
	foreach iface_id $ifaces {
		addStateNodeIface $node_id $iface_id "creating"

		if { $isOSlinux } {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -

			# Create a veth pair - private hook in global NS and public hook
			# in the experiment NS
			createNsVethPair $node_id $private_ns $public_iface $public_ns
		}

		if { $isOSfreebsd } {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] ng_peer -

			set outifc "$eid-$node_id"

			# save newly created ngnodeX into a shell variable ifid and
			# rename the ng node to $ng_peer (unique to this experiment)
			set cmds "ifid=\$(printf \"mkpeer . eiface $ng_peer ether \n"
			set cmds "$cmds show .:$ng_peer\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
			set cmds "$cmds; jexec $eid ngctl name \$ifid: $ng_peer"
			set cmds "$cmds; jexec $eid ifconfig \$ifid name $outifc"

			pipesExec $cmds "hold"
			pipesExec "ifconfig $outifc -vnet $eid" "hold"

			set ether [getIfcMACaddr $node_id $iface_id]
			if { $ether == "" } {
				autoMACaddr $node_id $iface_id
			}

			set ether [getIfcMACaddr $node_id $iface_id]
			pipesExec "ifconfig $outifc link $ether" "hold"
		}
	}

	pipesExec ""

}

proc $MODULE.nodePhysIfacesCreate_check { eid node_id ifaces } {
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

	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

	if { $isOSlinux } {
		# get list of interface names
		set cmds "ip -br l | sed \"s/\[@\[:space:]].*//\""
		set cmds "ip netns exec $private_ns sh -c '$cmds'"
	}

	if { $isOSfreebsd } {
		# get list of interface names
		set cmds "ifconfig -l"
		set cmds "sh -c '$cmds'"
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
			if {
				[isRunningNodeIface $node_id $iface_id] ||
				("creating" in [getStateNodeIface $node_id $iface_id] &&
				"$eid-$node_id" in $ifaces_all)
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
			return true
		}

		return false
	} on error {} {
		return false
	}

	return false
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* ext.tcl/ext.nodeIfacesConfigure
# NAME
#   ext.nodeIfacesConfigure -- configure ext node interfaces
# SYNOPSIS
#   ext.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a ext. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	set cmds ""
	set outifc "$eid-$node_id"

	foreach iface_id $ifaces {
		set ether [getIfcMACaddr $node_id $iface_id]
		if { $ether == "" } {
			set ether [autoMACaddr $node_id $iface_id]
		}

		set addrs4 [getIfcIPv4addrs $node_id $iface_id]
		setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $addrs4

		set addrs6 [getIfcIPv6addrs $node_id $iface_id]
		setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $addrs6

		if { $isOSlinux } {
			append cmds "ip l set $outifc address $ether; "

			foreach ipv4 $addrs4 {
				append cmds "ip a add $ipv4 dev $outifc; "
			}

			foreach ipv6 $addrs6 {
				append cmds "ip a add $ipv6 dev $outifc; "
			}

			append cmds "ip l set $outifc up; "
		}

		if { $isOSfreebsd } {
			append cmds "ifconfig $outifc link $ether; "

			foreach ipv4 $addrs {
				append cmds "ifconfig $outifc $ipv4; "
			}

			foreach ipv6 $addrs6 {
				append cmds "ifconfig $outifc inet6 $ipv6; "
			}

			append cmds "ifconfig $outifc up; "
		}
	}

	if { $cmds == "" } {
		return
	}

	addStateNode $node_id "ifaces_configuring"

	pipesExec "$cmds" "hold"
}

proc $MODULE.nodeIfacesConfigure_check { eid node_id ifaces } {
	# TODO
	return true
}

proc $MODULE.attachToLink { node_id iface_id link_id direct } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		if { $direct } {
			return
		}

		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -
		setNsIfcMaster [getFromRunning "eid"] $public_iface $link_id "up"

		return
	}

	if { $isOSfreebsd } {
		# nothing to do, createLinkBetween does everything
		return
	}
}

proc $MODULE.detachFromLink { node_id iface_id link_id { direct "" } } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		if { $direct } {
			# link already destroyed, except in some cases

			return
		}

		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -
		pipesExec "ip -n [getFromRunning "eid"] link set $public_iface down"

		return
	}

	if { $isOSfreebsd } {
		# nothing to do, destroyLinkBetween does everything
		return
	}
}

#****f* ext.tcl/ext.nodeConfigure
# NAME
#   ext.nodeConfigure -- start
# SYNOPSIS
#   ext.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new ext. The node can be started if it is instantiated.
#   Simulates the booting proces of a ext, by calling l3node.nodeConfigure procedure.
#   Sets up the NAT for the given interface if assigned.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeConfigure { eid node_id } {
	global isOSlinux isOSfreebsd

	set ifaces [ifcList $node_id]
	if { $ifaces == {} } {
		return
	}

	set host_out_iface [getNodeNATIface $node_id]
	if { $host_out_iface == "UNASSIGNED" } {
		return
	}

	foreach iface_id $ifaces {
		set out_ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
		if { $out_ip == "" } {
			return
		}

		set prefixLen [lindex [split $out_ip "/"] 1]
		set subnet "[ip::prefix $out_ip]/$prefixLen"

		set cmds ""
		if { $isOSlinux } {
			append cmds "iptables -t nat -A POSTROUTING -o $host_out_iface -j MASQUERADE -s $subnet; "
			append cmds "iptables -A FORWARD -i $eid-$node_id -o $host_out_iface -j ACCEPT; "
			append cmds "iptables -A FORWARD -o $eid-$node_id -j ACCEPT; "
		}

		if { $isOSfreebsd } {
			append cmds "echo 'map $host_out_iface $subnet -> 0/32' | ipnat -f -; "
		}

		pipesExec "$cmds" "hold"
	}

	addStateNode $node_id "node_configuring"

	pipesExec ""
}

proc $MODULE.nodeConfigure_check { eid node_id } {
	# TODO
	return true
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeUnconfigure { eid node_id } {
	global isOSlinux isOSfreebsd

	set ifaces [ifcList $node_id]
	if { $ifaces == {} } {
		return
	}

	set host_out_iface [getNodeNATIface $node_id]
	if { $host_out_iface == "UNASSIGNED" } {
		return
	}

	foreach iface_id $ifaces {
		set out_ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
		if { $out_ip == "" } {
			return
		}

		set prefixLen [lindex [split $out_ip "/"] 1]
		set subnet "[ip::prefix $out_ip]/$prefixLen"

		set cmds ""
		if { $isOSlinux } {
			append cmds "iptables -t nat -D POSTROUTING -o $host_out_iface -j MASQUERADE -s $subnet; "
			append cmds "iptables -D FORWARD -i $eid-$node_id -o $host_out_iface -j ACCEPT; "
			append cmds "iptables -D FORWARD -o $eid-$node_id -j ACCEPT; "
		}

		if { $isOSfreebsd } {
			append cmds "echo 'map $host_out_iface $subnet -> 0/32' | ipnat -f - -pr; "
		}

		pipesExec "$cmds" "hold"
	}

	addStateNode $node_id "node_unconfiguring"

	pipesExec ""
}

proc $MODULE.nodeUnconfigure_check { eid node_id } {
	# TODO
	return true
}

#****f* ext.tcl/ext.nodeShutdown
# NAME
#   ext.nodeShutdown -- shutdown
# SYNOPSIS
#   ext.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns an ext node.
#   It kills all external packet sniffers and sets the interface down.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
	global isOSlinux isOSfreebsd
	global ttyrcmd

	set iface_id [lindex [ifcList $node_id] 0]
	if { $iface_id == "" } {
		return
	}

	killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
	killExtProcess "xterm -name imunes-terminal -T Capturing $eid-$node_id -e $ttyrcmd tcpdump -ni $eid-$node_id"

	if { $isOSlinux } {
		pipesExec "ip link set $eid-$node_id down" "hold"
	}

	if { $isOSfreebsd } {
		pipesExec "ifconfig $eid-$node_id down" "hold"
	}

	addStateNode $node_id "node_shutting"

	pipesExec ""
}

proc $MODULE.nodeShutdown_check { eid node_id } {
	# TODO
	return true
}

#****f* ext.tcl/ext.nodeIfacesUnconfigure
# NAME
#   ext.nodeIfacesUnconfigure -- unconfigure ext node interfaces
# SYNOPSIS
#   ext.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on an ext to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	set cmds ""
	set iface_id [lindex $ifaces 0]
	if { $iface_id == "" } {
		return
	}

	set outifc "$eid-$node_id"

	set addrs4 [getFromRunning "${node_id}|${iface_id}_old_ipv4_addrs"]
	set addrs6 [getFromRunning "${node_id}|${iface_id}_old_ipv6_addrs"]

	if { $isOSlinux } {
		foreach ipv4 $addrs4 {
			append cmds "ip a del $ipv4 dev $outifc; "
		}

		foreach ipv6 $addrs6 {
			append cmds "ip a del $ipv6 dev $outifc; "
		}
	}

	if { $isOSfreebsd } {
		foreach ipv4 $addrs4 {
			append cmds "ifconfig $outifc inet $ipv4 -alias; "
		}

		foreach ipv6 $addrs6 {
			append cmds "ifconfig $outifc inet $ipv6 -alias; "
		}
	}

	if { $cmds == "" } {
		return
	}

	addStateNode $node_id "ifaces_unconfiguring"

	pipesExec "$cmds" "hold"
}

proc $MODULE.nodeIfacesUnconfigure_check { eid node_id ifaces } {
	# TODO
	return true
}

proc $MODULE.nodePhysIfacesDestroy { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	foreach iface_id $ifaces {
		if { $isOSlinux } {
			pipesExec "ip -n $eid link del $node_id-$iface_id" "hold"
		}

		if { $isOSfreebsd } {
			pipesExec "ifconfig $node_id-$iface_id destroy" "hold"
		}
	}

	pipesExec ""
}

proc $MODULE.nodeIfacesDestroy_check { eid node_id ifaces } {
	# TODO
	return true
}

#****f* ext.tcl/ext.nodeDestroy
# NAME
#   ext.nodeDestroy -- destroy
# SYNOPSIS
#   ext.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys an ext node.
#   Does nothing, as it is not created.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
	removeStateNode $node_id "running"
}

proc $MODULE.nodeDestroyFS { eid node_id } {
}
