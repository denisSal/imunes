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

# $Id: vm.tcl 130 2015-02-24 09:52:19Z valter $


#****h* imunes/vm.tcl
# NAME
#  vm.tcl -- defines vm specific procedures
# FUNCTION
#  This module is used to define all the vm specific procedures.
# NOTES
#  Procedures in this module start with the keyword vm and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE vm
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* vm.tcl/vm.confNewNode
# NAME
#   vm.confNewNode -- configure new node
# SYNOPSIS
#   vm.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id [getNewNodeNameType vm $nodeNamingBase(vm)]
}

#****f* vm.tcl/vm.confNewIfc
# NAME
#   vm.confNewIfc -- configure new interface
# SYNOPSIS
#   vm.confNewIfc $node_id $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node_id ifc } {
	autoMACaddr $node_id $ifc
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

#****f* vm.tcl/vm.ifacePrefix
# NAME
#   vm.ifacePrefix -- interface name prefix
# SYNOPSIS
#   vm.ifacePrefix
# FUNCTION
#   Returns vm interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
	return "x"
}

#****f* vm.tcl/vm.netlayer
# NAME
#   vm.netlayer -- layer
# SYNOPSIS
#   set layer [vm.netlayer]
# FUNCTION
#   Returns the layer on which the vm operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
	return LINK
}

#****f* vm.tcl/vm.virtlayer
# NAME
#   vm.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [vm.virtlayer]
# FUNCTION
#   Returns the layer on which the vm node is instantiated,
#   i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
	return NATIVE
}

#****f* vm.tcl/vm.nghook
# NAME
#   vm.nghook
# SYNOPSIS
#   vm.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the netgraph hook name. In this
#   case netgraph node name correspondes to the name of the physical interface.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * nghook -- the list containing netgraph node name and
#     the netraph hook name (in this case: lower).
#****
proc $MODULE.nghook { eid node_id iface_id } {
	set iface_name [getIfcName $node_id $iface_id]
	set vlan [getIfcVlanTag $node_id $iface_id]
	if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
		set iface_name ${iface_name}_$vlan
	}

	return [list $iface_name lower]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* vm.tcl/vm.prepareSystem
# NAME
#   vm.prepareSystem -- prepare system
# SYNOPSIS
#   vm.prepareSystem
# FUNCTION
#   Loads ng_ether into the kernel.
#****
proc $MODULE.prepareSystem {} {
}

#****f* vm.tcl/vm.nodeCreate
# NAME
#   vm.nodeCreate -- instantiate
# SYNOPSIS
#   vm.nodeCreate $eid $node_id
# FUNCTION
#   Procedure vm.nodeCreate puts real interface into promiscuous mode.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
	set result [startVM $eid $node_id]

	if { $result == "success" } {
		setToRunning "${node_id}_running" true
	} else {
		setToRunning "${node_id}_running" false
		powerOffVM $eid $node_id
	}
}

#****f* vm.tcl/vm.nodeNamespaceSetup
# NAME
#   vm.nodeNamespaceSetup -- vm node nodeNamespaceSetup
# SYNOPSIS
#   vm.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

#****f* vm.tcl/vm.nodeInitConfigure
# NAME
#   vm.nodeInitConfigure -- vm node nodeInitConfigure
# SYNOPSIS
#   vm.nodeInitConfigure $eid $node_id
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
	# first deal with VLAN interfaces to avoid 'non-existant'
	# interface error
	set vlan_ifaces {}
	set nonvlan_ifaces {}
	foreach iface_id $ifaces {
		if { [getIfcVlanDev $node_id $iface_id] != "" } {
			lappend vlan_ifaces $iface_id
		} else {
			lappend nonvlan_ifaces $iface_id
		}
	}

	foreach iface_id [concat $vlan_ifaces $nonvlan_ifaces] {
		captureExtIfc $eid $node_id $iface_id

		setToRunning "${node_id}|${iface_id}_running" "creating"
	}
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* vm.tcl/vm.nodeIfacesConfigure
# NAME
#   vm.nodeIfacesConfigure -- configure vm node interfaces
# SYNOPSIS
#   vm.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a vm. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
}

#****f* vm.tcl/vm.nodeConfigure
# NAME
#   vm.nodeConfigure -- configure vm node
# SYNOPSIS
#   vm.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new vm. Simulates the booting proces of a node, starts all the
#   services, etc.
#   This procedure can be called if it is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeConfigure { eid node_id } {
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* vm.tcl/vm.nodeIfacesUnconfigure
# NAME
#   vm.nodeIfacesUnconfigure -- unconfigure vm node interfaces
# SYNOPSIS
#   vm.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a vm to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
	if { $ifaces == "*" } {
		set ifaces [ifcList $node_id]
	}

	foreach iface_id $ifaces {
		releaseExtIfc $eid $node_id $iface_id

		setToRunning "${node_id}|${iface_id}_running" "false"
	}
}

proc $MODULE.nodeUnconfigure { eid node_id } {
}

#****f* vm.tcl/vm.nodeShutdown
# NAME
#   vm.nodeShutdown -- layer 3 node nodeShutdown
# SYNOPSIS
#   vm.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a vm node.
#   Simulates the shutdown proces of a node, kills all the services and
#   processes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
	powerOffVM $eid $node_id
}

#****f* vm.tcl/vm.nodeDestroy
# NAME
#   vm.nodeDestroy -- destroy
# SYNOPSIS
#   vm.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys an vm emulation interface.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
}

proc $MODULE.nodeDestroyFS { eid node_id } {
}
