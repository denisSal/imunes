#
# Copyright 2005-2010 University of Zagreb, Croatia.
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

#****h* imunes/stpswitch.tcl
# NAME
#  stpswitch.tcl -- defines stpswitch specific procedures
# FUNCTION
#  This module is used to define all the stpswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword stpswitch and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE stpswitch
registerModule $MODULE "freebsd"

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#### required for every node
proc $MODULE.netlayer {} {
	return [genericL2.netlayer]
}
#### /required for every node

proc $MODULE.virtlayer {} {
	return [genericL3.virtlayer]
}

proc $MODULE.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id [getNewNodeNameType stpswitch $nodeNamingBase(stpswitch)]

	setBridgeProtocol $node_id "rstp"
	setBridgePriority $node_id "32768"
	setBridgeHoldCount $node_id "6"
	setBridgeMaxAge $node_id "20"
	setBridgeFwdDelay $node_id "15"
	setBridgeHelloTime $node_id "2"
	setBridgeMaxAddr $node_id "100"
	setBridgeTimeout $node_id "240"

	set logiface_id [newLogIface $node_id "lo"]
	setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
	setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

proc $MODULE.confNewIfc { node_id iface_id } {
	autoMACaddr $node_id $iface_id

	setBridgeIfcDiscover $node_id $iface_id 1
	setBridgeIfcLearn $node_id $iface_id 1
	setBridgeIfcStp $node_id $iface_id 1
	setBridgeIfcAutoedge $node_id $iface_id 1
	setBridgeIfcAutoptp $node_id $iface_id 1
	setBridgeIfcPriority $node_id $iface_id 128
	setBridgeIfcPathcost $node_id $iface_id 0
	setBridgeIfcMaxaddr $node_id $iface_id 0
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
	set cfg {}

	set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"
	if { $ifaces == "*" } {
		set ifaces $all_ifaces
	} else {
		# sort physical ifaces before logical ones (because of vlans)
		set negative_ifaces [removeFromList $all_ifaces $ifaces]
		set ifaces [removeFromList $all_ifaces $negative_ifaces]
	}

	set bridge_name "stp_br"
	foreach iface_id $ifaces {
		set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]

		lappend cfg ""

		if { [isIfcLogical $node_id $iface_id] } {
			continue
		}

		set iface_name [getIfcName $node_id $iface_id]

		if { [getBridgeIfcSnoop $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name span $iface_name"
			lappend cfg ""
			continue
		}

		lappend cfg "ifconfig $bridge_name addm $iface_name up"

		if { [getBridgeIfcStp $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name stp $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -stp $iface_name"
		}

		if { [getBridgeIfcDiscover $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name discover $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -discover $iface_name"
		}

		if { [getBridgeIfcLearn $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name learn $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -learn $iface_name"
		}

		if { [getBridgeIfcSticky $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name sticky $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -sticky $iface_name"
		}

		if { [getBridgeIfcPrivate $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name private $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -private $iface_name"
		}

		if { [getBridgeIfcEdge $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name edge $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -edge $iface_name"
		}

		if { [getBridgeIfcAutoedge $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name autoedge $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -autoedge $iface_name"
		}

		if { [getBridgeIfcPtp $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name ptp $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -ptp $iface_name"
		}

		if { [getBridgeIfcAutoptp $node_id $iface_id] == "1" } {
			lappend cfg "ifconfig $bridge_name autoptp $iface_name"
		} else {
			lappend cfg "ifconfig $bridge_name -autoptp $iface_name"
		}

		set priority [getBridgeIfcPriority $node_id $iface_id]
		lappend cfg "ifconfig $bridge_name ifpriority $iface_name $priority"

		set pathcost [getBridgeIfcPathcost $node_id $iface_id]
		lappend cfg "ifconfig $bridge_name ifpathcost $iface_name $pathcost"

		set maxaddr [getBridgeIfcMaxaddr $node_id $iface_id]
		lappend cfg "ifconfig $bridge_name ifmaxaddr $iface_name $maxaddr"

		lappend cfg ""
	}

	return $cfg
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
	set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"
	if { $ifaces == "*" } {
		set ifaces $all_ifaces
	} else {
		# sort physical ifaces before logical ones
		set negative_ifaces [removeFromList $all_ifaces $ifaces]
		set ifaces [removeFromList $all_ifaces $negative_ifaces]
	}

	set cfg {}

	set bridge_name "stp_br"
	foreach iface_id $ifaces {
		set iface_name [getIfcName $node_id $iface_id]
		lappend cfg "ifconfig $bridge_name deletem $iface_name"

		set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]

		lappend cfg ""
	}

	return $cfg
}

#****f* stpswitch.tcl/stpswitch.generateConfig
# NAME
#   stpswitch.generateConfig
# SYNOPSIS
#   set config [stpswitch.generateConfig $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure stpswitch.bootcmd
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node_id - id of the node
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
	set cfg {}

	set bridge_name "stp_br"

	set bridgeProtocol [getBridgeProtocol $node_id]
	if { $bridgeProtocol != "" } {
		lappend cfg "ifconfig $bridge_name proto $bridgeProtocol"
	}

	set bridgePriority [getBridgePriority $node_id]
	if { $bridgePriority != "" } {
		lappend cfg "ifconfig $bridge_name priority $bridgePriority"
	}

	set bridgeMaxAge [getBridgeMaxAge $node_id]
	if { $bridgeMaxAge != "" } {
		lappend cfg "ifconfig $bridge_name maxage $bridgeMaxAge"
	}

	set bridgeFwdDelay [getBridgeFwdDelay $node_id]
	if { $bridgeFwdDelay != "" } {
		lappend cfg "ifconfig $bridge_name fwddelay $bridgeFwdDelay"
	}

	set bridgeHoldCnt [getBridgeHoldCount $node_id]
	if { $bridgeHoldCnt != "" } {
		lappend cfg "ifconfig $bridge_name holdcnt $bridgeHoldCnt"
	}

	set bridgeHelloTime [getBridgeHelloTime $node_id]
	if { $bridgeHelloTime != "" && $bridgeProtocol == "stp" } {
		lappend cfg "ifconfig $bridge_name hellotime $bridgeHelloTime"
	}

	set bridgeMaxAddr [getBridgeMaxAddr $node_id]
	if { $bridgeMaxAddr != "" } {
		lappend cfg "ifconfig $bridge_name maxaddr $bridgeMaxAddr"
	}

	set bridgeTimeout [getBridgeTimeout $node_id]
	if { $bridgeTimeout != "" } {
		lappend cfg "ifconfig $bridge_name timeout $bridgeTimeout"
	}

	lappend cfg ""

	return $cfg
}

proc $MODULE.IPAddrRange {} {
}

proc $MODULE.bootcmd { node_id } {
	return "/bin/sh"
}

proc $MODULE.shellcmds {} {
	return "csh bash sh tcsh"
}

proc $MODULE.getPrivateNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid.$node_id
	}

	if { $isOSfreebsd } {
		return $eid.$node_id
	}
}

proc $MODULE.getPublicNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc $MODULE.getHookData { node_id iface_id } {
	global isOSlinux isOSfreebsd

	# Linux - interface name of the node (inside node namespace)
	# FreeBSD - interface name of the node (inside node jail)
	set private_elem [getIfcName $node_id $iface_id]

	# Linux - public part of veth pair (inside EID namespace)
	# FreeBSD - name of public netgraph peer (inside EID jail)
	set public_elem "$node_id-$iface_id"

	# Linux - not used
	# FreeBSD - hook for connecting to netgraph node
	set hook_name "ether"

	return [list $private_elem $public_elem $hook_name]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

proc $MODULE.prepareSystem {} {
	catch { kldload if_bridge bridgestp }
}

proc $MODULE.checkNodePrerequisites { eid node_id } {
	return
}

proc $MODULE.checkIfacesPrerequisites { eid node_id ifaces } {
	return [genericL3.checkIfacesPrerequisites $eid $node_id $ifaces]
}

#****f* stpswitch.tcl/stpswitch.nodeCreate
# NAME
#   stpswitch.nodeCreate
# SYNOPSIS
#   stpswitch.nodeCreate $eid $node_id
# FUNCTION
#   Procedure stpswitch.nodeCreate creates a new virtual node
#   for a given node in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
	genericL3.nodeCreate $eid $node_id

	set bridge_name "stp_br"
	pipesExec "jexec $eid.$node_id ifconfig bridge create name $bridge_name" "hold"
}

proc $MODULE.nodeCreate_check { eid node_id } {
	return [genericL3.nodeCreate_check $eid $node_id]
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

proc $MODULE.nodeNamespaceSetup_check { eid node_id } {
	return true
}

proc $MODULE.nodeInitConfigure { eid node_id } {
	array set sysctl_stpbridge {
		net.link.bridge.pfil_member	0
		net.link.bridge.pfil_bridge	0
		net.link.bridge.pfil_onlyip	0
	}

	foreach {name val} [array get sysctl_ipfwd] {
		lappend cmd "sysctl $name=$val"
	}
	set cmds [join $cmd "; "]

	pipesExec "jexec $eid.$node_id sh -c '$cmds'" "hold"

	genericL3.nodeInitConfigure $eid $node_id
}

proc $MODULE.nodeInitConfigure_check { eid node_id } {
	return [genericL3.nodeInitConfigure_check $eid $node_id]
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
	return [genericL3.nodePhysIfacesCreate $eid $node_id $ifaces]
}

proc $MODULE.nodePhysIfacesDirectCreate { eid node_id ifaces } {
	return [genericL3.nodePhysIfacesDirectCreate $eid $node_id $ifaces]
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

proc $MODULE.nodePhysIfacesCreate_check { eid node_id ifaces } {
	return true
}

proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
	return [genericL3.nodeIfacesConfigure $eid $node_id $ifaces]
}

proc $MODULE.nodeIfacesConfigure_check { eid node_id ifaces } {
	return [genericL3.nodeIfacesConfigure_check $eid $node_id $ifaces]
}

proc $MODULE.attachToLink { node_id iface_id link_id direct } {
	return [genericL3.attachToLink $node_id $iface_id $link_id $direct]
}

proc $MODULE.detachFromLink { node_id iface_id link_id { direct "" } } {
	return [genericL3.detachFromLink $node_id $iface_id $link_id $direct]
}

proc $MODULE.nodeConfigure { eid node_id } {
	return [genericL3.nodeConfigure $eid $node_id]
}

proc $MODULE.nodeConfigure_check { eid node_id } {
	return [genericL3.nodeConfigure_check $eid $node_id]
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeUnconfigure { eid node_id } {
	return [genericL3.nodeUnconfigure $eid $node_id]
}

proc $MODULE.nodeUnconfigure_check { eid node_id } {
	return [genericL3.nodeUnconfigure_check $eid $node_id]
}

proc $MODULE.nodeShutdown { eid node_id } {
	return [genericL3.nodeShutdown $eid $node_id]
}

proc $MODULE.nodeShutdown_check { eid node_id } {
	return [genericL3.nodeShutdown_check $eid $node_id]
}

proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
	return [genericL3.nodeIfacesUnconfigure $eid $node_id $ifaces]
}

proc $MODULE.nodeIfacesUnconfigure_check { eid node_id ifaces } {
	return [genericL3.nodeIfacesUnconfigure_check $eid $node_id $ifaces]
}

proc $MODULE.nodeLogIfacesDestroy { eid node_id ifaces } {
	return [genericL3.nodeLogIfacesDestroy $eid $node_id $ifaces]
}

proc $MODULE.nodePhysIfacesDestroy { eid node_id ifaces } {
	return [genericL3.nodePhysIfacesDestroy $eid $node_id $ifaces]
}

proc $MODULE.nodePhysIfacesDirectDestroy { eid node_id ifaces } {
	return [genericL3.nodePhysIfacesDirectDestroy $eid $node_id $ifaces]
}

proc $MODULE.nodeIfacesDestroy_check { eid node_id ifaces } {
	return [genericL3.nodeIfacesDestroy_check $eid $node_id $ifaces]
}

#****f* stpswitch.tcl/stpswitch.nodeDestroy
# NAME
#   stpswitch.nodeDestroy
# SYNOPSIS
#   stpswitch.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys an stpswitch node.
#   First, it destroys all remaining virtual ifaces (vlans, tuns, etc).
#   Then, it destroys the jail/container with its namespaces and FS.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
	set bridge_name "stp_br"
	pipesExec "jexec $eid.$node_id ifconfig $bridge_name destroy" "hold"

	genericL3.nodeDestroy $eid $node_id
}

proc $MODULE.nodeDestroy_check { eid node_id } {
	return [genericL3.nodeDestroy_check $eid $node_id]
}

proc $MODULE.nodeDestroyFS { eid node_id } {
	return [genericL3.nodeDestroyFS $eid $node_id]
}

proc $MODULE.nodeDestroyFS_check { eid node_id } {
	return [genericL3.nodeDestroyFS_check $eid $node_id]
}
