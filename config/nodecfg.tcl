#
# Copyright 2004-2013 University of Zagreb.
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

# $Id: nodecfg.tcl 149 2015-03-27 15:50:14Z valter $


#****h* imunes/nodecfg.tcl
# NAME
#  nodecfg.tcl -- file used for manipultaion with nodes in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring
#  nodes in IMUNES. The definition of nodes is presented in NOTES
#  section.
#
# NOTES
#  The IMUNES configuration file contains declarations of IMUNES objects.
#  Each object declaration contains exactly the following three fields:
#
#     object_class object_id class_specific_config_string
#
#  Currently only two object classes are supported: node and link. In the
#  future we plan to implement a canvas object, which should allow placing
#  other objects into multiple visual maps.
#
#  "node" objects are further divided by their type, which can be one of
#  the following:
#  * router
#  * host
#  * pc
#  * lanswitch
#  * hub
#  * rj45
#  * pseudo
#
#  The following node types are to be implemented in the future:
#  * frswitch
#  * text
#  * image
#
#
# Routines for manipulation of per-node network configuration files
# IMUNES keeps per-node network configuration in an IOS / Zebra / Quagga
# style format.
#
# Network configuration is embedded in each node's config section via the
# "network-config" statement. The following functions can be used to
# manipulate the per-node network config:
#
# netconfFetchSection { node_id sectionhead }
#	Returns a section of a config file starting with the $sectionhead
#	line, and ending with the first occurence of the "!" sign.
#
# netconfClearSection { node_id sectionhead }
#	Removes the appropriate section from the config.
#
# netconfInsertSection { node_id section }
#	Inserts a section in the config file. Sections beginning with the
#	"interface" keyword are inserted at the head of the config, and
#	all other sequences are simply appended to the config tail.
#
# getIfcOperState { node_id iface_id }
#	Returns "up" or "down".
#
# setIfcOperState { node_id iface_id state }
#	Sets the new interface state. Implicit default is "up".
#
# getIfcNatState { node_id iface_id }
#	Returns "on" or "off".
#
# setIfcNatState { node_id iface_id state }
#	Sets the new interface NAT state. Implicit default is "off".
#
# getIfcQDisc { node_id iface_id }
#	Returns "FIFO", "WFQ" or "DRR".
#
# setIfcQDisc { node_id iface_id qdisc }
#	Sets the new queuing discipline. Implicit default is FIFO.
#
# getIfcQDrop { node_id iface_id }
#	Returns "drop-tail" or "drop-head".
#
# setIfcQDrop { node_id iface_id qdrop }
#	Sets the new queuing discipline. Implicit default is "drop-tail".
#
# getIfcQLen { node_id iface_id }
#	Returns the queue length limit in packets.
#
# setIfcQLen { node_id iface_id len }
#	Sets the new queue length limit.
#
# getIfcMTU { node_id iface_id }
#	Returns the configured MTU, or an empty string if default MTU is used.
#
# setIfcMTU { node_id iface_id mtu }
#	Sets the new MTU. Zero MTU value denotes the default MTU.
#
# getIfcIPv4addrs { node_id iface_id }
#	Returns a list of all IPv4 addresses assigned to an interface.
#
# setIfcIPv4addrs { node_id iface_id addrs }
#	Sets a new IPv4 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getIfcIPv6addrs { node_id iface_id }
#	Returns a list of all IPv6 addresses assigned to an interface.
#
# setIfcIPv6addrs { node_id iface_id addrs }
#	Sets a new IPv6 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getDefaultGateways { node_id subnet_gws nodes_l2data }
#	Returns a list of all default IPv4/IPv6 routes as {destination
#	gateway} pairs and updates existing subnet gateways and members.
#
# getStatIPv4routes { node_id }
#	Returns a list of all static IPv4 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv4routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getStatIPv6routes { node_id }
#	Returns a list of all static IPv6 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv6routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getNodeName { node_id }
#	Returns node's logical name.
#
# setNodeName { node_id name }
#	Sets a new node's logical name.
#
# getNodeType { node_id }
#	Returns node's type.
#
# getNodeModel { node_id }
#	Returns node's optional model identifier.
#
# setNodeModel { node_id model }
#	Sets the node's optional model identifier.
#
# getNodeCanvas { node_id }
#	Returns node's canvas affinity.
#
# setNodeCanvas { node_id canvas_id }
#	Sets the node's canvas affinity.
#
# getNodeCoords { node_id }
#	Return icon coords.
#
# setNodeCoords { node_id coords }
#	Sets the coordinates.
#
# getNodeSnapshot { node_id }
#	Return node's snapshot name.
#
# setNodeSnapshot { node_id coords }
#	Sets node's snapshot name.
#
# getSTPEnabled { node_id }
#	Returns true if STP is enabled.
#
# setSTPEnabled { node_id state }
#	Sets STP state.
#
# getNodeLabelCoords { node_id }
#	Return node label coordinates.
#
# setNodeLabelCoords { node_id coords }
#	Sets the label coordinates.
#
# getNodeCPUConf { node_id }
#	Returns node's CPU scheduling parameters { minp maxp weight }.
#
# setNodeCPUConf { node_id param_list }
#	Sets the node's CPU scheduling parameters.
#
# ifcList { node_id }
#	Returns a list of all interfaces present in a node.
#
# getIfcPeer { node_id iface_id }
#	Returns id of the node on the other side of the interface
#
# logicalPeerByIfc { node_id iface_id }
#	Returns id of the logical node on the other side of the interface.
#
# ifcByPeer { local_node_id peer_id }
#	Returns the name of the interface connected to the specified peer
#       if the peer is on the same canvas, otherwise returns an empty string.
#
# hasIPv4Addr { node_id }
# hasIPv6Addr { node_id }
#	Returns true if at least one interface has an IPv{4|6} address
#	configured, otherwise returns false.
#
# removeNode { node_id }
#	Removes the specified node as well as all the links that bind
#       that node to any other node.
#
# newIface { type node_id }
#	Returns the first available name for a new interface of the
#       specified type.
#
# All of the above functions are independent to any Tk objects. This means
# they can be used for implementing tasks external to GUI, so inside the
# GUI any updating of related Tk objects (such as text labels etc.) will
# have to be implemented by additional Tk code.
#
# Additionally, an alternative configuration can be specified in
# "custom-config" section.
#
# getCustomEnabled { node_id }
#
# setCustomEnabled { node_id state }
#
# getCustomConfigSelected { node_id }
#
# setCustomConfigSelected { node_id cfg_id }
#
# getCustomConfig { node_id id }
#
# setCustomConfig { node_id id cmd config }
#
# removeCustomConfig { node_id id }
#
# getCustomConfigCommand { node_id id }
#
# getCustomConfigIDs { node_id }
#
#****

proc getNodeDir { node_id } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_dir [getNodeCustomImage $node_id]
    if { $node_dir == "" } {
	set node_dir [getVrootDir]/$eid/$node_id
    }

    return $node_dir
}

#****f* nodecfg.tcl/getCustomEnabled
# NAME
#   getCustomEnabled -- get custom configuration enabled state
# SYNOPSIS
#   set enabled [getCustomEnabled $node_id]
# FUNCTION
#   For input node this procedure returns true if custom configuration is
#   enabled for the specified node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- returns true if custom configuration is enabled
#****
proc getCustomEnabled { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    if { [lindex [lsearch -inline [set $node_id] "custom-enabled *"] 1] == true } {
	return true
    } else {
	return false
    }
}

#****f* nodecfg.tcl/setCustomEnabled
# NAME
#   setCustomEnabled -- set custom configuration enabled state
# SYNOPSIS
#   setCustomEnabled $node_id $state
# FUNCTION
#   For input node this procedure enables or disables custom configuration.
# INPUTS
#   * node_id -- node id
#   * state -- true if enabling custom configuration, false if disabling
#****
proc setCustomEnabled { node_id state } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "custom-enabled *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i]
    }

    if { $state == true } {
	lappend $node_id [list custom-enabled $state]
    }
}

#****f* nodecfg.tcl/getCustomConfigSelected
# NAME
#   getCustomConfigSelected -- get default custom configuration
# SYNOPSIS
#   getCustomConfigSelected $node_id
# FUNCTION
#   For input node this procedure returns ID of a default configuration
# INPUTS
#   * node_id -- node id
# RESULT
#   * cfg_id -- returns default custom configuration ID
#****
proc getCustomConfigSelected { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "custom-selected *"] 1]
}

#****f* nodecfg.tcl/setCustomConfigSelected
# NAME
#   setCustomConfigSelected -- set default custom configuration
# SYNOPSIS
#   setCustomConfigSelected $node_id
# FUNCTION
#   For input node this procedure sets ID of a default configuration
# INPUTS
#   * node_id -- node id
#   * cfg_id -- custom-config id
#****
proc setCustomConfigSelected { node_id cfg_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "custom-selected *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i]
    }

    lappend $node_id [list custom-selected $cfg_id]
}

#****f* nodecfg.tcl/getCustomConfig
# NAME
#   getCustomConfig -- get custom configuration
# SYNOPSIS
#   getCustomConfig $node_id $cfg_id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- configuration id
# RESULT
#   * customConfig -- returns custom configuration
#****
proc getCustomConfig { node_id cfg_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set customCfgsList {}
    set customCfgsList [lsearch -inline [set $node_id] "custom-configs *"]
    set customCfg [lsearch -inline [lindex $customCfgsList 1] "custom-config-id $cfg_id *"]
    set customConfig [lsearch [lindex $customCfg 2] "config*"]
    set customConfig [lindex [lindex $customCfg 2] $customConfig+1]

    return $customConfig
}

#****f* nodecfg.tcl/setCustomConfig
# NAME
#   setCustomConfig -- set custom configuration
# SYNOPSIS
#   setCustomConfig $node_id $cfg_id $cmd $config
# FUNCTION
#   For input node this procedure sets custom configuration section in input
#   node.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- custom-config id
#   * cmd -- custom command
#   * config -- custom configuration section
#****
proc setCustomConfig { node_id cfg_id cmd config } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    if { $cfg_id in [getCustomConfigIDs $node_id] } {
	removeCustomConfig $node_id $cfg_id
    }

    set customCfg [list custom-config-id $cfg_id]
    set customCfg2 [list custom-command $cmd config]
    set cfg ""
    foreach zline [split $config {
}] {
	lappend cfg $zline
    }
    lappend customCfg2 $cfg

    lappend customCfg $customCfg2

    if { [lsearch [set $node_id] "custom-configs *"] != -1 } {
	set customCfgsList [lsearch -inline [set $node_id] "custom-configs *"]
	set customCfgs [lindex $customCfgsList 1]
	lappend customCfgs $customCfg
	set customCfgsList [lreplace $customCfgsList 1 1 $customCfgs]
	set idx1 [lsearch [set $node_id] "custom-configs *"]
	set $node_id [lreplace [set $node_id] $idx1 $idx1 $customCfgsList]
    } else {
	set customCfgsList [list custom-configs]
	lappend customCfgsList [list $customCfg]
	set $node_id [linsert [set $node_id] end $customCfgsList]
    }
}

#****f* nodecfg.tcl/removeCustomConfig
# NAME
#   removeCustomConfig -- remove custom configuration
# SYNOPSIS
#   removeCustomConfig $node_id $cfg_id
# FUNCTION
#   For input node and configuration ID this procedure removes custom
#   configuration from node.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- configuration id
#****
proc removeCustomConfig { node_id cfg_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set customCfgsList [lsearch -inline [set $node_id] "custom-configs *"]
    set idx [lsearch [lindex $customCfgsList 1] "custom-config-id $cfg_id *"]

    set customCfgs [lreplace [lindex $customCfgsList 1] $idx $idx]
    set customCfgsList [lreplace $customCfgsList 1 1 $customCfgs]
    set idx1 [lsearch [set $node_id] "custom-configs *"]

    set $node_id [lreplace [set $node_id] $idx1 $idx1 $customCfgsList]
}

#****f* nodecfg.tcl/getCustomConfigCommand
# NAME
#   getCustomConfigCommand -- get custom configuration boot command
# SYNOPSIS
#   getCustomConfigCommand $node_id $cfg_id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration boot command.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- configuration id
# RESULT
#   * customCmd -- returns custom configuration boot command
#****
proc getCustomConfigCommand { node_id cfg_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set customCfgsList {}
    set customCfgsList [lsearch -inline [set $node_id] "custom-configs *"]
    set customCfg [lsearch -inline [lindex $customCfgsList 1] "custom-config-id $cfg_id *"]
    set customCmd [lsearch [lindex $customCfg 2] "custom-command*"]
    set customCmd [lindex [lindex $customCfg 2] $customCmd+1]

    return $customCmd
}

#****f* nodecfg.tcl/getCustomConfigIDs
# NAME
#   getCustomConfigIDs -- get custom configuration IDs
# SYNOPSIS
#   getCustomConfigIDs $node_id
# FUNCTION
#   For input node this procedure returns all custom configuration IDs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * IDs -- returns custom configuration IDs
#****
proc getCustomConfigIDs { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set customCfgsList [lsearch -inline [set $node_id] "custom-configs *"]
    set customCfg [lsearch -all -inline [lindex $customCfgsList 1] "custom-config-id *"]

    set IDs {}
    foreach x $customCfg {
	lappend IDs [lindex $x 1]
    }

    return $IDs
}

#****f* nodecfg.tcl/netconfFetchSection
# NAME
#   netconfFetchSection -- fetch the network configuration section
# SYNOPSIS
#   set section [netconfFetchSection $node_id $sectionhead]
# FUNCTION
#   Returns a section of a network part of a configuration file starting with
#   the $sectionhead line, and ending with the first occurrence of the "!"
#   sign.
# INPUTS
#   * node_id -- node id
#   * sectionhead -- represents the first line of the section in
#     network-config part of the configuration file
# RESULT
#   * section -- returns a part of the configuration file between sectionhead
#     and "!"
#****
proc netconfFetchSection { node_id sectionhead } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set cfgmode global
    set section {}
    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]
    foreach line $netconf {
	if { $cfgmode == "section" } {
	    if { "$line" == "!" } {
		return $section
	    }
	    lappend section "$line"

	    continue
	}

	if { "$line" == "$sectionhead" } {
	    set cfgmode section
	}
    }
}

#****f* nodecfg.tcl/netconfClearSection
# NAME
#   netconfClearSection -- clear the section from a network-config part
# SYNOPSIS
#   netconfClearSection $node_id $sectionhead
# FUNCTION
#   Removes the appropriate section from the network part of the
#   configuration.
# INPUTS
#   * node_id -- node id
#   * sectionhead -- represents the first line of the section that is to be
#     removed from network-config part of the configuration.
#****
proc netconfClearSection { node_id sectionhead } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "network-config *"]
    set netconf [lindex [lindex [set $node_id] $i] 1]
    set lnum_beg -1
    set lnum_end 0
    foreach line $netconf {
	if { $lnum_beg == -1 && "$line" == "$sectionhead" } {
	    set lnum_beg $lnum_end
	}

	if { $lnum_beg > -1 && "$line" == "!" } {
	    set netconf [lreplace $netconf $lnum_beg $lnum_end]
	    set $node_id [lreplace [set $node_id] $i $i \
		[list network-config $netconf]]
	    return
	}

	incr lnum_end
    }
}

#****f* nodecfg.tcl/netconfInsertSection
# NAME
#   netconfInsertSection -- Insert the section to a network-config
#   part of configuration
# SYNOPSIS
#   netconfInsertSection $node_id $section
# FUNCTION
#   Inserts a section in the configuration. Sections beginning with the
#   "interface" keyword are inserted at the head of the configuration, and all
#   other sequences are simply appended to the configuration tail.
# INPUTS
#   * node_id -- the node id of the node whose config section is inserted
#   * section -- represents the section that is being inserted. If there was a
#     section in network configuration with the same section head, it is lost.
#****
proc netconfInsertSection { node_id section } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set sectionhead [lindex $section 0]
    netconfClearSection $node_id $sectionhead

    set i [lsearch [set $node_id] "network-config *"]
    set netconf [lindex [lindex [set $node_id] $i] 1]

    set lnum_beg end
    if { "[lindex $sectionhead 0]" == "interface" } {
	set lnum [lsearch $netconf "hostname *"]
	if { $lnum >= 0 } {
	    set lnum_beg [expr $lnum + 2]
	}
    } elseif { "[lindex $sectionhead 0]" == "hostname" } {
	set lnum_beg 0
    }

    if { "[lindex $section end]" != "!" } {
	lappend section "!"
    }

    foreach line $section {
	set netconf [linsert $netconf $lnum_beg $line]
	if { $lnum_beg != "end" } {
	    incr lnum_beg
	}
    }

    set $node_id [lreplace [set $node_id] $i $i [list network-config $netconf]]
}

#****f* nodecfg.tcl/getIfcName
# NAME
#   getIfcName -- get interface name
# SYNOPSIS
#   set name [getIfcName $node_id $iface_id]
# FUNCTION
#   Returns the name of the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- the interface id
# RESULT
#   * name -- the name of the interface
#****
proc getIfcName { node_id iface_id } {
    return $iface_id
}

#****f* nodecfg.tcl/setIfcName
# NAME
#   setIfcName -- set interface name
# SYNOPSIS
#   setIfcName $node_id $iface_id $name
# FUNCTION
#   Sets the name of the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * name -- new name of the interface
#****
proc setIfcName { node_id iface_id name } {
}

#****f* nodecfg.tcl/getIfcOperState
# NAME
#   getIfcOperState -- get interface operating state
# SYNOPSIS
#   set state [getIfcOperState $node_id $iface_id]
# FUNCTION
#   Returns the operating state of the specified interface. It can be "up" or
#   "down".
# INPUTS
#   * node_id -- node id
#   * iface_id -- the interface that is up or down
# RESULT
#   * state -- the operating state of the interface, can be either "up" or
#     "down".
#****
proc getIfcOperState { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "shutdown" } {
	    return "down"
	}
    }

    return "up"
}

#****f* nodecfg.tcl/setIfcOperState
# NAME
#   setIfcOperState -- set interface operating state
# SYNOPSIS
#   setIfcOperState $node_id $iface_id
# FUNCTION
#   Sets the operating state of the specified interface. It can be set to "up"
#   or "down".
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface
#   * state -- new operating state of the interface, can be either "up" or
#     "down"
#****
proc setIfcOperState { node_id iface_id state } {
    set ifcfg [list "interface $iface_id"]
    if { $state == "down" } {
	lappend ifcfg " shutdown"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "shutdown" && \
	    [lrange $line 0 1] != "no shutdown" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcNatState
# NAME
#   getIfcNatState -- get interface NAT state
# SYNOPSIS
#   set state [getIfcNatState $node_id $iface_id]
# FUNCTION
#   Returns the NAT state of the specified interface. It can be "on" or "off".
# INPUTS
#   * node_id -- node id
#   * iface_id -- the interface that is used for NAT
# RESULT
#   * state -- the NAT state of the interface, can be either "on" or "off"
#****
proc getIfcNatState { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] in "!nat nat" } {
	    return "on"
	}
    }

    return "off"
}

#****f* nodecfg.tcl/setIfcNatState
# NAME
#   setIfcNatState -- set interface NAT state
# SYNOPSIS
#   setIfcNatState $node_id $iface_id
# FUNCTION
#   Sets the NAT state of the specified interface. It can be set to "on" or "off"
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface
#   * state -- new NAT state of the interface, can be either "on" or "off"
#****
proc setIfcNatState { node_id iface_id state } {
    set ifcfg [list "interface $iface_id"]
    if { $state == "on" } {
	lappend ifcfg " !nat"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] ni "!nat nat" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcDirect
# NAME
#   getIfcDirect -- get interface queuing discipline
# SYNOPSIS
#   set direction [getIfcDirect $node_id $iface_id]
# FUNCTION
#   Returns the direction of the specified interface. It can be set to
#   "internal" or "external".
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * iface_id -- interface id
# RESULT
#   * direction -- the direction of the interface, can be either "internal" or
#     "external".
#****
proc getIfcDirect { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "external" } {
	    return external
	}
    }

    return internal
}

#****f* nodecfg.tcl/setIfcDirect
# NAME
#   setIfcDirect -- set interface direction
# SYNOPSIS
#   setIfcDirect $node_id $iface_id $direct
# FUNCTION
#   Sets the direction of the specified interface. It can be set to "internal"
#   or "external".
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * direct -- new direction of the interface, can be either "internal" or
#     "external"
#****
proc setIfcDirect { node_id iface_id direct } {
    set ifcfg [list "interface $iface_id"]
    if { $direct == "external" } {
	lappend ifcfg " external"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "external" && \
	    [lindex $line 0] != "internal" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcQDisc
# NAME
#   getIfcQDisc -- get interface queuing discipline
# SYNOPSIS
#   set qdisc [getIfcQDisc $node_id $iface_id]
# FUNCTION
#   Returns one of the supported queuing discipline ("FIFO", "WFQ" or "DRR")
#   that is active for the specified interface.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * iface_id -- interface id
# RESULT
#   * qdisc -- returns queuing discipline of the interface, can be "FIFO",
#     "WFQ" or "DRR".
#****
proc getIfcQDisc { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "fair-queue" } {
	    return WFQ
	}

	if { [lindex $line 0] == "drr-queue" } {
	    return DRR
	}
    }

    return FIFO
}

#****f* nodecfg.tcl/setIfcQDisc
# NAME
#   setIfcQDisc -- set interface queueing discipline
# SYNOPSIS
#   setIfcQDisc $node_id $iface_id $qdisc
# FUNCTION
#   Sets the new queuing discipline for the interface. Implicit default is
#   FIFO.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queuing
#     discipline is set.
#   * iface_id -- interface id
#   * qdisc -- queuing discipline of the interface, can be "FIFO", "WFQ" or
#     "DRR".
#****
proc setIfcQDisc { node_id iface_id qdisc } {
    set ifcfg [list "interface $iface_id"]
    if { $qdisc == "WFQ" } {
	lappend ifcfg " fair-queue"
    }

    if { $qdisc == "DRR" } {
	lappend ifcfg " drr-queue"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "fair-queue" && \
	    [lindex $line 0] != "drr-queue" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcQDrop
# NAME
#   getIfcQDrop -- get interface queue dropping policy
# SYNOPSIS
#   set qdrop [getIfcQDrop $node_id $iface_id]
# FUNCTION
#   Returns one of the supported queue dropping policies ("drop-tail" or
#   "drop-head") that is active for the specified interface.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     dropping policy is checked.
#   * iface_id -- interface id
# RESULT
#   * qdrop -- returns queue dropping policy of the interface, can be
#     "drop-tail" or "drop-head".
#****
proc getIfcQDrop { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "drop-head" } {
	    return drop-head
	}
    }

    return drop-tail
}

#****f* nodecfg.tcl/setIfcQDrop
# NAME
#   setIfcQDrop -- set interface queue dropping policy
# SYNOPSIS
#   setIfcQDrop $node_id $iface_id $qdrop
# FUNCTION
#   Sets the new queuing discipline. Implicit default is "drop-tail".
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     droping policie is set.
#   * iface_id -- interface id
#   * qdrop -- new queue dropping policy of the interface, can be "drop-tail"
#     or "drop-head".
#****
proc setIfcQDrop { node_id iface_id qdrop } {
    set ifcfg [list "interface $iface_id"]
    if { $qdrop == "drop-head" } {
	lappend ifcfg " drop-head"

    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "drop-head" && \
	    [lindex $line 0] != "drop-tail" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcQLen
# NAME
#   getIfcQLen -- get interface queue length
# SYNOPSIS
#   set qlen [getIfcQLen $node_id $iface_id]
# FUNCTION
#   Returns the queue length limit in number of packets.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     length is checked.
#   * iface_id -- interface id
# RESULT
#   * qlen -- queue length limit represented in number of packets.
#****
proc getIfcQLen { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "queue-len" } {
	    return [lindex $line 1]
	}
    }

    return 50
}

#****f* nodecfg.tcl/setIfcQLen
# NAME
#   setIfcQLen -- set interface queue length
# SYNOPSIS
#   setIfcQLen $node_id $iface_id $len
# FUNCTION
#   Sets the queue length limit.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     length is set.
#   * iface_id -- interface id
#   * qlen -- queue length limit represented in number of packets.
#****
proc setIfcQLen { node_id iface_id len } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "queue-len" } {
	    lappend ifcfg $line
	}
    }

    if { $len > 5 && $len != 50 } {
	lappend ifcfg " queue-len $len"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcMTU
# NAME
#   getIfcMTU -- get interface MTU size.
# SYNOPSIS
#   set mtu [getIfcMTU $node_id $iface_id]
# FUNCTION
#   Returns the configured MTU, or a default MTU.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's MTU is
#     checked.
#   * iface_id -- interface id
# RESULT
#   * mtu -- maximum transmission unit of the packet, represented in bytes.
#****
proc getIfcMTU { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "mtu" } {
	    return [lindex $line 1]
	}
    }

    # Return defaults
    switch -exact [string range $iface_id 0 1] {
	lo { return 16384 }
	se { return 2044 }
    }

    return 1500
}

#****f* nodecfg.tcl/setIfcMTU
# NAME
#   setIfcMTU -- set interface MTU size.
# SYNOPSIS
#   setIfcMTU $node_id $iface_id $mtu
# FUNCTION
#   Sets the new MTU. Zero MTU value denotes the default MTU.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's MTU is set.
#   * iface_id -- interface id
#   * mtu -- maximum transmission unit of a packet, represented in bytes.
#****
proc setIfcMTU { node_id iface_id mtu } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "mtu" } {
	    lappend ifcfg $line
	}
    }

    set limit 9018
    if { $mtu >= 256 && $mtu <= $limit } {
	lappend ifcfg " mtu $mtu"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcMACaddr
# NAME
#   getIfcMACaddr -- get interface MAC address.
# SYNOPSIS
#   set addr [getIfcMACaddr $node_id $iface_id]
# FUNCTION
#   Returns the MAC address assigned to the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * addr -- The MAC address assigned to the specified interface.
#****
proc getIfcMACaddr { node_id iface_id } {
    set addr ""
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] == "mac address" } {
	    set addr [lindex $line 2]
	}
    }

    return $addr
}

#****f* nodecfg.tcl/setIfcMACaddr
# NAME
#   setIfcMACaddr -- set interface MAC address.
# SYNOPSIS
#   setIfcMACaddr $node_id $iface_id $addr
# FUNCTION
#   Sets a new MAC address on an interface. The correctness of the MAC address
#   format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's MAC address is set.
#   * iface_id -- interface id
#   * addr -- new MAC address.
#****
proc setIfcMACaddr { node_id iface_id addr } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] != "mac address" } {
	    lappend ifcfg $line
	}
    }

    if { $addr != "" } {
	lappend ifcfg " mac address $addr"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcIPv4addrs
# NAME
#   getIfcIPv4addrs -- get interface IPv4 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv4addrs $node_id $iface_id]
# FUNCTION
#   Returns the list of IPv4 addresses assigned to the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * addrList -- A list of all the IPv4 addresses assigned to the specified
#     interface.
#****
proc getIfcIPv4addrs { node_id iface_id } {
    set addrlist {}
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] == "ip address" } {
	    lappend addrlist [lindex $line 2]
	}
    }

    return $addrlist
}

#****f* nodecfg.tcl/getLogIfcType
# NAME
#   getLogIfcType -- get logical interface type
# SYNOPSIS
#   getLogIfcType $node_id $iface_id
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc getLogIfcType { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "type" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcIPv4addrs
# NAME
#   setIfcIPv4addrs -- set interface IPv4 addresses.
# SYNOPSIS
#   setIfcIPv4addrs $node_id $iface_id $addrs
# FUNCTION
#   Sets new IPv4 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv4 address is set.
#   * iface_id -- interface id
#   * addrs -- new IPv4 addresses.
#****
proc setIfcIPv4addrs { node_id iface_id addrs } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] != "ip address" } {
	    lappend ifcfg $line
	}
    }

    foreach addr $addrs {
	if { $addr != "" } {
	    set addr [string trim $addr]
	    lappend ifcfg " ip address $addr"
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/setLogIfcType
# NAME
#   setLogIfcType -- set logical interface type
# SYNOPSIS
#   setLogIfcType $node_id $iface_id $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * type -- interface type
#****
proc setLogIfcType { node_id iface_id type } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "type" } {
	    lappend ifcfg $line
	}
    }

    if { $type != "" } {
	lappend ifcfg " type $type"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcIPv6addrs
# NAME
#   getIfcIPv6addrs -- get interface IPv6 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv6addrs $node_id $iface_id]
# FUNCTION
#   Returns the list of IPv6 addresses assigned to the specified interface.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv6 addresses are returned.
#   * iface_id -- interface id
# RESULT
#   * addrList -- A list of all the IPv6 addresses assigned to the specified
#     interface.
#****
proc getIfcIPv6addrs { node_id iface_id } {
    set addrlist {}
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] == "ipv6 address" } {
	    lappend addrlist [lindex $line 2]
	}
    }

    return $addrlist
}

#****f* nodecfg.tcl/setIfcIPv6addrs
# NAME
#   setIfcIPv6addrs -- set interface IPv6 addresses.
# SYNOPSIS
#   setIfcIPv6addrs $node_id $iface_id $addrs
# FUNCTION
#   Sets new IPv6 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv6 address is set.
#   * iface_id -- interface id
#   * addrs -- new IPv6 addresses.
#****
proc setIfcIPv6addrs { node_id iface_id addrs } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] != "ipv6 address" } {
	    lappend ifcfg $line
	}
    }

    foreach addr $addrs {
	if { $addr != "" } {
	    set addr [string trim $addr]
	    lappend ifcfg " ipv6 address $addr"
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcLinkLocalIPv6addr
# NAME
#   getIfcLinkLocalIPv6addr -- get interface link-local IPv6 address.
# SYNOPSIS
#   set addr [getIfcLinkLocalIPv6addr $node_id $iface_id]
# FUNCTION
#   Returns link-local IPv6 addresses that is calculated from the interface
#   MAC address. This can be done only for physical interfaces, or interfaces
#   with a MAC address assigned.
# INPUTS
#   * node_id -- the node id of the node whose link-local IPv6 address is returned.
#   * iface_id -- interface id
# RESULT
#   * addr -- The link-local IPv6 address that will be assigned to the
#     specified interface.
#****
proc getIfcLinkLocalIPv6addr { node_id iface_id } {
    if { [isIfcLogical $node_id $iface_id] } {
	return ""
    }

    set mac [getIfcMACaddr $node_id $iface_id]

    set bytes [split $mac :]
    set bytes [linsert $bytes 3 fe]
    set bytes [linsert $bytes 3 ff]

    set first [expr 0x[lindex $bytes 0]]
    set xored [expr $first^2]
    set result [format %02x $xored]

    set bytes [lreplace $bytes 0 0 $result]

    set i 0
    lappend final fe80::
    foreach b $bytes {
	lappend final $b
	if { [expr $i%2] == 1 && $i < 7 } {
	    lappend final :
	}
	incr i
    }
    lappend final /64

    return [ip::normalize [join $final ""]]
}

#****f* nodecfg.tcl/getNodeStolenIfaces
# NAME
#   getNodeStolenIfaces -- set node's stolen interfaces
# SYNOPSIS
#   getNodeStolenIfaces $node_id
# FUNCTION
#   Gets pairs of the node's stolen interfaces
# INPUTS
#   * node_id -- node id
# RESULT
#   * ifaces -- list of {iface_id stolen_iface} pairs
#****
proc getNodeStolenIfaces { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "external-ifcs *"] 1]
}

#****f* nodecfg.tcl/setNodeStolenIfaces
# NAME
#   setNodeStolenIfaces -- set node stolen interfaces
# SYNOPSIS
#   setNodeStolenIfaces $node_id $ifaces
# FUNCTION
#   Sets pairs of the node's stolen interfaces
# INPUTS
#   * node_id -- node id
#   * ifaces -- list of {iface_id stolen_iface} pairs
#****
proc setNodeStolenIfaces { node_id ifaces } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "external-ifcs *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "external-ifcs {$ifaces}"]
    } else {
	set $node_id [linsert [set $node_id] 1 "external-ifcs {$ifaces}"]
    }
}

#****f* nodecfg.tcl/getDefaultGateways
# NAME
#   getDefaultGateways -- get default IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getDefaultGateways $node_id $subnet_gws $nodes_l2data] \
#     my_gws subnets_and_gws
# FUNCTION
#   Returns a list of all default IPv4/IPv6 gateways for the subnets in which
#   this node belongs as a {node_type|gateway4|gateway6} values. Additionally,
#   it refreshes newly discovered gateways and subnet members to the existing
#   $subnet_gws list and $nodes_l2data dictionary.
# INPUTS
#   * node_id -- node id
#   * subnet_gws -- already known {node_type|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node_id iface_id subnet_idx}
#   triplets in this subnet
# RESULT
#   * my_gws -- list of all possible default gateways for the specified node
#   * subnet_gws -- refreshed {node_type|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node_id iface_id subnet_idx} triplets in
#   this subnet
#****
proc getDefaultGateways { node_id subnet_gws nodes_l2data } {
    set node_ifaces [ifcList $node_id]
    if { [llength $node_ifaces] == 0 } {
	return [list {} {} {}]
    }

    # go through all interfaces and collect data for each subnet
    foreach iface_id $node_ifaces {
	if { [dict exists $nodes_l2data $node_id $iface_id] } {
	    continue
	}

	# add new subnet at the end of the list
	set subnet_idx [llength $subnet_gws]
	lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
	lassign [getSubnetData $peer_id $peer_iface_id \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    # merge all gateways values and return
    set my_gws {}
    foreach subnet_idx [lsort -unique [dict values [dict get $nodes_l2data $node_id]]] {
	set my_gws [concat $my_gws [lindex $subnet_gws $subnet_idx]]
    }

    return [list $my_gws $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getSubnetData
# NAME
#   getSubnetData -- get subnet members and its IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getSubnetData $this_node_id $this_iface_id \
#     $subnet_gws $nodes_l2data $subnet_idx] \
#     subnet_gws nodes_l2data
# FUNCTION
#   Called when checking L2 network for routers/extnats in order to get all
#   default gateways. Returns all possible default IPv4/IPv6 gateways in this
#   LAN appended to the subnet_gws list and updates the members of this subnet
#   as {node_id iface_id subnet_idx} triplets in the nodes_l2data dictionary.
# INPUTS
#   * this_node_id -- node id
#   * this_iface_id -- node interface
#   * subnet_gws -- already known {node_type|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node_id iface_id subnet_idx}
#   triplets in this subnet
# RESULT
#   * subnet_gws -- refreshed {node_type|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node_id iface_id subnet_idx} triplets in
#   this subnet
#****
proc getSubnetData { this_node_id this_iface_id subnet_gws nodes_l2data subnet_idx } {
    set my_gws [lindex $subnet_gws $subnet_idx]

    if { [dict exists $nodes_l2data $this_node_id $this_iface_id] } {
	# this node/iface is already a part of this subnet
	set subnet_idx [dict get $nodes_l2data $this_node_id $this_iface_id]
	return [list $subnet_gws $nodes_l2data]
    }

    dict set nodes_l2data $this_node_id $this_iface_id $subnet_idx

    if { [[getNodeType $this_node_id].netlayer] == "NETWORK" } {
	if { [getNodeType $this_node_id] in "router nat64 extnat" } {
	    # this node is a router/extnat, add our IP addresses to lists
	    # TODO: multiple addresses per iface - split subnet4data and subnet6data
	    set gw4 [lindex [split [getIfcIPv4addrs $this_node_id $this_iface_id] /] 0]
	    set gw6 [lindex [split [getIfcIPv6addrs $this_node_id $this_iface_id] /] 0]
	    lappend my_gws [getNodeType $this_node_id]|$gw4|$gw6
	    lset subnet_gws $subnet_idx $my_gws
	}

	# first, get this node/iface peer's subnet data in case it is an L2 node
	# and we're not yet gone through it
	lassign [logicalPeerByIfc $this_node_id $this_iface_id] peer_id peer_iface_id
	lassign [getSubnetData $peer_id $peer_iface_id \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data

	# this node is done, do nothing else
	if { $subnet_gws == "" } {
	    set subnet_gws "{||}"
	}

	return [list $subnet_gws $nodes_l2data]
    }

    # this node is an L2 node
    # - collect data from all interfaces
    foreach iface_id [ifcList $this_node_id] {
	dict set nodes_l2data $this_node_id $iface_id $subnet_idx

	lassign [logicalPeerByIfc $this_node_id $iface_id] peer_id peer_iface_id
	lassign [getSubnetData $peer_id $peer_iface_id \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    return [list $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getStatIPv4routes
# NAME
#   getStatIPv4routes -- get static IPv4 routes.
# SYNOPSIS
#   set routes [getStatIPv4routes $node_id]
# FUNCTION
#   Returns a list of all static IPv4 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv4routes { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set routes {}
    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]
    foreach entry [lsearch -all -inline $netconf "ip route *"] {
	lappend routes [lrange $entry 2 end]
    }

    return $routes
}

#****f* nodecfg.tcl/setStatIPv4routes
# NAME
#   setStatIPv4routes -- set static IPv4 routes.
# SYNOPSIS
#   setStatIPv4routes $node_id $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- the node id of the node whose static routes are set.
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv4routes { node_id routes } {
    netconfClearSection $node_id "ip route [lindex [getStatIPv4routes $node_id] 0]"

    set section {}
    foreach route $routes {
	lappend section "ip route $route"
    }

    netconfInsertSection $node_id $section
}

#****f* nodecfg.tcl/getDefaultIPv4routes
# NAME
#   getDefaultIPv4routes -- get auto default IPv4 routes.
# SYNOPSIS
#   set routes [getDefaultIPv4routes $node_id]
# FUNCTION
#   Returns a list of all auto default IPv4 routes as a list of
#   {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc getDefaultIPv4routes { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lrange [lsearch -inline [set $node_id] "default_routes4 *"] 1 end]
}

#****f* nodecfg.tcl/setDefaultIPv4routes
# NAME
#   setDefaultIPv4routes -- set auto default IPv4 routes.
# SYNOPSIS
#   setDefaultIPv4routes $node_id $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node_id -- the node id of the node whose default routes are set
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc setDefaultIPv4routes { node_id routes } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "default_routes4 *"]
    if { [llength $routes] != 0 } {
	if { $i >= 0 } {
	    set $node_id [lreplace [set $node_id] $i $i "default_routes4 $routes"]
	} else {
	    set $node_id [linsert [set $node_id] end "default_routes4 $routes"]
	}
    } else {
	if { $i >= 0 } {
	    set $node_id [lreplace [set $node_id] $i $i]
	}
    }
}

#****f* nodecfg.tcl/getDefaultIPv6routes
# NAME
#   getDefaultIPv6routes -- get auto default IPv6 routes.
# SYNOPSIS
#   set routes [getDefaultIPv6routes $node_id]
# FUNCTION
#   Returns a list of all auto default IPv6 routes as a list of
#   {::/0 gateway} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc getDefaultIPv6routes { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lrange [lsearch -inline [set $node_id] "default_routes6 *"] 1 end]
}

#****f* nodecfg.tcl/setDefaultIPv6routes
# NAME
#   setDefaultIPv6routes -- set auto default IPv6 routes.
# SYNOPSIS
#   setDefaultIPv6routes $node_id $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {::/0 gateway} pairs.
# INPUTS
#   * node_id -- the node id of the node whose default routes are set
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc setDefaultIPv6routes { node_id routes } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "default_routes6 *"]
    if { [llength $routes] != 0 } {
	if { $i >= 0 } {
	    set $node_id [lreplace [set $node_id] $i $i "default_routes6 $routes"]
	} else {
	    set $node_id [linsert [set $node_id] end "default_routes6 $routes"]
	}
    } else {
	if { $i >= 0 } {
	    set $node_id [lreplace [set $node_id] $i $i]
	}
    }
}

#****f* nodecfg.tcl/getStatIPv6routes
# NAME
#   getStatIPv6routes -- get static IPv6 routes.
# SYNOPSIS
#   set routes [getStatIPv6routes $node_id]
# FUNCTION
#   Returns a list of all static IPv6 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv6routes { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set routes {}
    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]
    foreach entry [lsearch -all -inline $netconf "ipv6 route *"] {
	lappend routes [lrange $entry 2 end]
    }

    return $routes
}

#****f* nodecfg.tcl/setStatIPv6routes
# NAME
#   setStatIPv6routes -- set static IPv6 routes.
# SYNOPSIS
#   setStatIPv6routes $node_id $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv6routes { node_id routes } {
    netconfClearSection $node_id "ipv6 route [lindex [getStatIPv6routes $node_id] 0]"

    set section {}
    foreach route $routes {
	lappend section "ipv6 route $route"
    }

    netconfInsertSection $node_id $section
}

#****f* nodecfg.tcl/getDefaultRoutesConfig
# NAME
#   getDefaultRoutesConfig -- get node default routes in a configuration format
# SYNOPSIS
#   lassign [getDefaultRoutesConfig $node_id $gws] routes4 routes6
# FUNCTION
#   Called when translating IMUNES default gateways configuration to node
#   pre-running configuration. Returns IPv4 and IPv6 routes lists.
# INPUTS
#   * node_id -- node id
#   * gws -- gateway values in the {node_type|gateway4|gateway6} format
# RESULT
#   * all_routes4 -- {0.0.0.0/0 gw4} pairs of default IPv4 routes
#   * all_routes6 -- {0.0.0.0/0 gw6} pairs of default IPv6 routes
#****
proc getDefaultRoutesConfig { node_id gws } {
    set all_routes4 {}
    set all_routes6 {}

    lassign [getAllIpAddresses $node_id] ipv4_addrs ipv6_addrs
    if { $ipv4_addrs == "" && $ipv6_addrs == "" } {
	return "\"$all_routes4\" \"$all_routes6\""
    }

    # remove all non-extnat routes
    if { [getNodeType $node_id] in "router nat64" } {
	set gws [lsearch -inline -all $gws "extnat*"]
    }

    foreach route $gws {
	lassign [split $route "|"] route_type gateway4 -

	if { $gateway4 == "" } {
	    continue
	}

	set match4 false
	foreach ipv4_addr $ipv4_addrs {
	    set mask [ip::mask $ipv4_addr]
	    if { [ip::prefix $gateway4/$mask] == [ip::prefix $ipv4_addr] } {
		set match4 true
		break
	    }
	}

	if { $match4 && "0.0.0.0/0 $gateway4" ni $all_routes4 } {
	    lappend all_routes4 "0.0.0.0/0 $gateway4"
	}
    }

    foreach route $gws {
	lassign [split $route "|"] route_type - gateway6

	if { $gateway6 == "" } {
	    continue
	}

	set match6 false
	foreach ipv6_addr $ipv6_addrs {
	    set mask [ip::mask $ipv6_addr]
	    if { [ip::contract [ip::prefix $gateway6/$mask]] == [ip::contract [ip::prefix $ipv6_addr]] } {
		set match6 true
		break
	    }
	}

	if { $match6 && "::/0 $gateway6" ni $all_routes6 } {
	    lappend all_routes6 "::/0 $gateway6"
	}
    }

    return "\"$all_routes4\" \"$all_routes6\""
}

#****f* nodecfg.tcl/getNodeName
# NAME
#   getNodeName -- get node name.
# SYNOPSIS
#   set name [getNodeName $node_id]
# FUNCTION
#   Returns node's logical name.
# INPUTS
#   * node_id -- node id
# RESULT
#   * name -- logical name of the node
#****
proc getNodeName { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]

    return [lrange [lsearch -inline $netconf "hostname *"] 1 end]
}

#****f* nodecfg.tcl/setNodeName
# NAME
#   setNodeName -- set node name.
# SYNOPSIS
#   setNodeName $node_id $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node_id -- node id
#   * name -- logical name of the node
#****
proc setNodeName { node_id name } {
    netconfClearSection $node_id "hostname [getNodeName $node_id]"
    netconfInsertSection $node_id [list "hostname $name"]
}

#****f* nodecfg.tcl/getNodeType
# NAME
#   getNodeType -- get node type.
# SYNOPSIS
#   set type [getNodeType $node_id]
# FUNCTION
#   Returns node's type.
# INPUTS
#   * node_id -- node id
# RESULT
#   * type -- type of the node
#****
proc getNodeType { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "type *"] 1]
}

#****f* nodecfg.tcl/setNodeType
# NAME
#   setNodeType -- set node's type.
# SYNOPSIS
#   setNodeType $node_id $type
# FUNCTION
#   Sets node's type.
# INPUTS
#   * node_id -- node id
#   * type -- type of node
#****
proc setNodeType { node_id type } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "type *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "type $type"]
    } else {
	set $node_id [linsert [set $node_id] 1 "type $type"]
    }
}

#****f* nodecfg.tcl/getNodeModel
# NAME
#   getNodeModel -- get node routing model.
# SYNOPSIS
#   set model [getNodeModel $node_id]
# FUNCTION
#   Returns node's optional routing model. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node_id -- node id
# RESULT
#   * model -- routing model of the specified node
#****
proc getNodeModel { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "model *"] 1]
}

#****f* nodecfg.tcl/setNodeModel
# NAME
#   setNodeModel -- set node routing model.
# SYNOPSIS
#   setNodeModel $node_id $model
# FUNCTION
#   Sets an optional routing model to the node. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node_id -- node id
#   * model -- routing model of the specified node
#****
proc setNodeModel { node_id model } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "model *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "model $model"]
    } else {
	set $node_id [linsert [set $node_id] 1 "model $model"]
    }
}

#****f* nodecfg.tcl/getNodeSnapshot
# NAME
#   getNodeSnapshot -- get node snapshot image name.
# SYNOPSIS
#   set snapshot [getNodeSnapshot $node_id]
# FUNCTION
#   Returns node's snapshot name.
# INPUTS
#   * node_id -- node id
# RESULT
#   * snapshot -- snapshot name for the specified node
#****
proc getNodeSnapshot { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "snapshot *"] 1]
}

#****f* nodecfg.tcl/setNodeSnapshot
# NAME
#   setNodeSnapshot -- set node snapshot image name.
# SYNOPSIS
#   setNodeSnapshot $node_id $snapshot
# FUNCTION
#   Sets node's snapshot name.
# INPUTS
#   * node_id -- node id
#   * snapshot -- snapshot name for the specified node
#****
proc setNodeSnapshot { node_id snapshot } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "snapshot *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "snapshot $snapshot"]
    } else {
	set $node_id [linsert [set $node_id] 1 "snapshot $snapshot"]
    }
}

#****f* nodecfg.tcl/getStpEnabled
# NAME
#   getStpEnabled -- get STP enabled state
# SYNOPSIS
#   set state [getStpEnabled $node_id]
# FUNCTION
#   For input node this procedure returns true if STP is enabled
#   for the specified node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- returns true if STP is enabled
#****
proc getStpEnabled { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]
    if { [lrange [lsearch -inline $netconf "stp-enabled *"] 1 end] == true } {
	return true
    }

    return false
}

#****f* nodecfg.tcl/setStpEnabled
# NAME
#   setStpEnabled -- set STP enabled state
# SYNOPSIS
#   setStpEnabled $node_id $state
# FUNCTION
#   For input node this procedure enables or disables STP.
# INPUTS
#   * node_id -- node id
#   * state -- true if enabling STP, false if disabling
#****
proc setStpEnabled { node_id state } {
    netconfClearSection $node_id "stp-enabled true"
    if { $state == true } {
	netconfInsertSection $node_id [list "stp-enabled $state"]
    }
}

#****f* nodecfg.tcl/getNodeCoords
# NAME
#   getNodeCoords -- get node icon coordinates.
# SYNOPSIS
#   set coords [getNodeCoords $node_id]
# FUNCTION
#   Returns node's icon coordinates.
# INPUTS
#   * node_id -- node id
# RESULT
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc getNodeCoords { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "iconcoords *"] 1]
}

#****f* nodecfg.tcl/setNodeCoords
# NAME
#   setNodeCoords -- set node's icon coordinates.
# SYNOPSIS
#   setNodeCoords $node_id $coords
# FUNCTION
#   Sets node's icon coordinates.
# INPUTS
#   * node_id -- node id
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc setNodeCoords { node_id coords } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    set i [lsearch [set $node_id] "iconcoords *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "iconcoords {$roundcoords}"]
    } else {
	set $node_id [linsert [set $node_id] end "iconcoords {$roundcoords}"]
    }
}

#****f* nodecfg.tcl/getNodeLabelCoords
# NAME
#   getNodeLabelCoords -- get node's label coordinates.
# SYNOPSIS
#   set coords [getNodeLabelCoords $node_id]
# FUNCTION
#   Returns node's label coordinates.
# INPUTS
#   * node_id -- node id
# RESULT
#   * coords -- coordinates of the node's label in form of {Xcoord Ycoord}
#****
proc getNodeLabelCoords { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "labelcoords *"] 1]
}

#****f* nodecfg.tcl/setNodeLabelCoords
# NAME
#   setNodeLabelCoords -- set node's label coordinates.
# SYNOPSIS
#   setNodeLabelCoords $node_id $coords
# FUNCTION
#   Sets node's label coordinates.
# INPUTS
#   * node_id -- node id
#   * coords -- coordinates of the node's label in form of Xcoord Ycoord
#****
proc setNodeLabelCoords { node_id coords } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    set i [lsearch [set $node_id] "labelcoords *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "labelcoords {$roundcoords}"]
    } else {
	set $node_id [linsert [set $node_id] end "labelcoords {$roundcoords}"]
    }
}

#****f* nodecfg.tcl/getNodeCPUConf
# NAME
#   getNodeCPUConf -- get node's CPU configuration
# SYNOPSIS
#   set conf [getNodeCPUConf $node_id]
# FUNCTION
#   Returns node's CPU scheduling parameters { minp maxp weight }.
# INPUTS
#   * node_id -- node id
# RESULT
#   * conf -- node's CPU scheduling parameters { minp maxp weight }
#****
proc getNodeCPUConf { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [join [lrange [lsearch -inline [set $node_id] "cpu *"] 1 3]]
}

#****f* nodecfg.tcl/setNodeCPUConf
# NAME
#   setNodeCPUConf -- set node's CPU configuration
# SYNOPSIS
#   setNodeCPUConf $node_id $param_list
# FUNCTION
#   Sets the node's CPU scheduling parameters.
# INPUTS
#   * node_id -- node id
#   * param_list -- node's CPU scheduling parameters { minp maxp weight }
#****
proc setNodeCPUConf { node_id param_list } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "cpu *"]
    if { $i >= 0 } {
	if { $param_list != "{}" } {
	    set $node_id [lreplace [set $node_id] $i $i "cpu $param_list"]
	} else {
	    set $node_id [lreplace [set $node_id] $i $i]
	}
    } else {
	if { $param_list != "{}" } {
	    set $node_id [linsert [set $node_id] 1 "cpu $param_list"]
	}
    }
}

proc getAutoDefaultRoutesStatus { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set res [lsearch -inline [set $node_id] "auto_default_routes *"]
    if { $res == "" } {
	return "disabled"
    }

    return [lindex $res 1]
}

proc setAutoDefaultRoutesStatus { node_id state } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "auto_default_routes *"]
    if { $state == "enabled" } {
	if { $i >= 0 } {
	    set $node_id [lreplace [set $node_id] $i $i "auto_default_routes $state"]
	} else {
	    set $node_id [linsert [set $node_id] end "auto_default_routes $state"]
	}
    } else {
	if { $i >= 0 } {
	    set $node_id [lreplace [set $node_id] $i $i]
	}
    }
}

#****f* nodecfg.tcl/ifcList
# NAME
#   ifcList -- get list of all interfaces
# SYNOPSIS
#   set ifcs [ifcList $node_id]
# FUNCTION
#   Returns a list of all interfaces present in a node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of all node's interfaces
#****
proc ifcList { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set interfaces ""
    foreach entry [lsearch -all -inline [set $node_id] "interface-peer *"] {
	lappend interfaces [lindex [lindex $entry 1] 0]
    }

    return $interfaces
}

#****f* nodecfg.tcl/logIfcList
# NAME
#   logIfcList -- logical interfaces list
# SYNOPSIS
#   logIfcList $node_id
# FUNCTION
#   Returns the list of all the node's logical interfaces.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of node's logical interfaces
#****
proc logIfcList { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set interfaces ""
    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]
    foreach line $netconf {
	if { "interface" in $line } {
	    set iface_id [lindex $line 1]
	    if { $iface_id ni [ifcList $node_id] } {
		lappend interfaces $iface_id
	    }
	}
    }

    return $interfaces
}

#****f* nodecfg.tcl/isIfcLogical
# NAME
#   isIfcLogical -- is given interface logical
# SYNOPSIS
#   isIfcLogical $node_id $iface_id
# FUNCTION
#   Returns true or false whether the node's interface is logical or not.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * check -- true if the interface is logical, otherwise false.
#****
proc isIfcLogical { node_id iface_id } {
    if { $iface_id in [logIfcList $node_id] } {
	return true
    }

    return false
}

#****f* nodecfg.tcl/allIfcList
# NAME
#   allIfcList -- all interfaces list
# SYNOPSIS
#   allIfcList $node_id
# FUNCTION
#   Returns the list of all node's interfaces.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of node's interfaces
#****
proc allIfcList { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set interfaces [concat [ifcList $node_id] [logIfcList $node_id]]
    set lo0_pos [lsearch $interfaces lo0]
    if { $lo0_pos != -1 } {
	set interfaces "lo0 [lreplace $interfaces $lo0_pos $lo0_pos]"
    }

    return $interfaces
}

#****f* nodecfg.tcl/getIfcPeer
# NAME
#   getIfcPeer -- get node's peer by interface.
# SYNOPSIS
#   set peer_id [getIfcPeer $node_id $iface_id]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is situated on the other canvas or
#   connected via split link, this function returns a pseudo node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * peer_id -- node id of the node on the other side of the interface
#****
proc getIfcPeer { node_id iface_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set entry [lsearch -inline [set $node_id] "interface-peer {$iface_id *}"]

    return [lindex [lindex $entry 1] 1]
}

#****f* nodecfg.tcl/logicalPeerByIfc
# NAME
#   logicalPeerByIfc -- get node's peer by interface.
# SYNOPSIS
#   set peer_id [logicalPeerByIfc $node_id $iface_id]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is connected via normal link (not split)
#   this function acts the same as the function getIfcPeer, but if the nodes
#   are connected via split links or situated on different canvases this
#   function returns the logical peer node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * peer_id -- node id of the node on the other side of the interface
#****
proc logicalPeerByIfc { node_id iface_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set peer_id [getIfcPeer $node_id $iface_id]
    if { [getNodeType $peer_id] == "pseudo" } {
	set node_id [getNodeMirror $peer_id]
	set peer_id [getIfcPeer $node_id "0"]
	set peer_iface_id [ifcByPeer $peer_id $node_id]
    } else {
	foreach link_id [linksByPeers $node_id $peer_id] {
	    set ifaces [getLinkPeersIfaces $link_id]

	    set peer_idx [lsearch -exact [getLinkPeers $link_id] $node_id]
	    set my_ifc [lindex $ifaces $peer_idx]
	    if { $iface_id == $my_ifc } {
		set peer_iface_id [removeFromList $ifaces $iface_id "keep_doubles"]
		break
	    }
	}
    }

    return "$peer_id $peer_iface_id"
}

#****f* nodecfg.tcl/ifcByPeer
# NAME
#   ifcByPeer -- get node interface by peer.
# SYNOPSIS
#   set iface_id [getIfcPeer $node_id $peer_id]
# FUNCTION
#   Returns the name of the interface connected to the specified peer. If the
#   peer node is on different canvas or connected via split link to the
#   specified node this function returns an empty string.
# INPUTS
#   * node_id -- node id
#   * peer_id -- id of the peer node
# RESULT
#   * iface_id -- interface id
#****
proc ifcByPeer { node_id peer_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set entry [lsearch -inline [set $node_id] "interface-peer {* $peer_id}"]

    return [lindex [lindex $entry 1] 0]
}

#****f* nodecfg.tcl/hasIPv4Addr
# NAME
#   hasIPv4Addr -- has IPv4 address.
# SYNOPSIS
#   set check [hasIPv4Addr $node_id]
# FUNCTION
#   Returns true if at least one interface has an IPv4 address configured,
#   otherwise returns false.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- true if at least one interface has an IPv4 address, otherwise
#     false.
#****
proc hasIPv4Addr { node_id } {
    foreach iface_id [ifcList $node_id] {
	if { [getIfcIPv4addrs $node_id $iface_id] != {} } {
	    return true
	}
    }

    return false
}

#****f* nodecfg.tcl/hasIPv6Addr
# NAME
#   hasIPv6Addr -- has IPv6 address.
# SYNOPSIS
#   set check [hasIPv6Addr $node_id]
# FUNCTION
#   Retruns true if at least one interface has an IPv6 address configured,
#   otherwise returns false.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- true if at least one interface has an IPv6 address, otherwise
#     false.
#****
proc hasIPv6Addr { node_id } {
    foreach iface_id [ifcList $node_id] {
	if { [getIfcIPv6addrs $node_id $iface_id] != {} } {
	    return true
	}
    }
    return false
}

#****f* nodecfg.tcl/removeNode
# NAME
#   removeNode -- removes the node
# SYNOPSIS
#   removeNode $node_id
# FUNCTION
#   Removes the specified node as well as all the links binding that node to
#   the other nodes.
# INPUTS
#   * node_id -- node id
#****
proc removeNode { node_id } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    if { [getCustomIcon $node_id] != "" } {
	removeImageReference [getCustomIcon $node_id] $node_id
    }

    foreach iface_id [ifcList $node_id] {
	foreach link_id [linksByPeers $node_id [getIfcPeer $node_id $iface_id]] {
	    removeLink $link_id
	}
    }

    set node_list [removeFromList $node_list $node_id]

    set node_type [getNodeType $node_id]
    if { $node_type in [array names nodeNamingBase] } {
	recalculateNumType $node_type $nodeNamingBase($node_type)
    }
}

#****f* nodecfg.tcl/getNodeCanvas
# NAME
#   getNodeCanvas -- get node canvas id
# SYNOPSIS
#   set canvas_id [getNodeCanvas $node_id]
# FUNCTION
#   Returns node's canvas affinity.
# INPUTS
#   * node_id -- node id
# RESULT
#   * canvas_id -- canvas id
#****
proc getNodeCanvas { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "canvas *"] 1]
}

#****f* nodecfg.tcl/setNodeCanvas
# NAME
#   setNodeCanvas -- set node canvas
# SYNOPSIS
#   setNodeCanvas $node_id $canvas
# FUNCTION
#   Sets node's canvas affinity.
# INPUTS
#   * node_id -- node id
#   * canvas_id -- canvas id
#****
proc setNodeCanvas { node_id canvas_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "canvas *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "canvas $canvas_id"]
    } else {
	set $node_id [linsert [set $node_id] end "canvas $canvas_id"]
    }
}

#****f* nodecfg.tcl/newIface
# NAME
#   newIface -- new interface
# SYNOPSIS
#   set iface_id [newIface $type $node_id]
# FUNCTION
#   Returns the first available name for a new interface of the specified type.
# INPUTS
#   * type -- interface type
#   * node_id -- node id
# RESULT
#   * iface_id -- the first available name for a interface of the specified type
#****
proc newIface { type node_id } {
    set interfaces [ifcList $node_id]
    for { set id 0 } { [lsearch -exact $interfaces $type$id] >= 0 } { incr id } {}

    return $type$id
}

#****f* nodecfg.tcl/newLogIface
# NAME
#   newLogIface -- new logical interface
# SYNOPSIS
#   newLogIface $type $node_id
# FUNCTION
#   Returns the first available name for a new logical interface of the
#   specified type.
# INPUTS
#   * type -- interface type
#   * node_id -- node id
#****
proc newLogIface { type node_id } {
    set interfaces [logIfcList $node_id]
    for { set id 0 } { [lsearch -exact $interfaces $type$id] >= 0 } { incr id } {}

    return $type$id
}

#****f* nodecfg.tcl/newNode
# NAME
#   newNode -- new node
# SYNOPSIS
#   set node_id [newNode $type]
# FUNCTION
#   Returns the node id of a new node of the specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * node_id -- node id of a new node of the specified type
#****
proc newNode { type } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global viewid
    catch { unset viewid }

    set node_id [newObjectId $node_list "n"]
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    set $node_id {}
    lappend $node_id "type $type"
    lappend node_list $node_id

    if { [info procs $type.confNewNode] == "$type.confNewNode" } {
	$type.confNewNode $node_id
    }

    return $node_id
}

#****f* nodecfg.tcl/getNodeMirror
# NAME
#   getNodeMirror -- get node mirror
# SYNOPSIS
#   set mirror_node_id [getNodeMirror $node_id]
# FUNCTION
#   Returns the node id of a mirror pseudo node of the node. Mirror node is
#   the corresponding pseudo node. The pair of pseudo nodes, node and his
#   mirror node, are introduced to form a split in a link. This split can be
#   used for avoiding crossed links or for displaying a link between the nodes
#   on a different canvas.
# INPUTS
#   * node_id -- node id
# RESULT
#   * mirror_node_id -- node id of a mirror node
#****
proc getNodeMirror { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "mirror *"] 1]
}

#****f* nodecfg.tcl/setNodeMirror
# NAME
#   setNodeMirror -- set node mirror
# SYNOPSIS
#   setNodeMirror $node_id $value
# FUNCTION
#   Sets the node id of a mirror pseudo node of the specified node. Mirror
#   node is the corresponding pseudo node. The pair of pseudo nodes, node and
#   his mirror node, are introduced to form a split in a link. This split can
#   be used for avoiding crossed links or for displaying a link between the
#   nodes on a different canvas.
# INPUTS
#   * node_id -- node id
#   * value -- node id of a mirror node
#****
proc setNodeMirror { node_id value } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "mirror *"]
    if { $value == "" } {
	set $node_id [lreplace [set $node_id] $i $i]
    } else {
	set $node_id [linsert [set $node_id] end "mirror $value"]
    }
}

#****f* nodecfg.tcl/getNodeProtocol
# NAME
#   getNodeProtocol
# SYNOPSIS
#   getNodeProtocol $node_id $protocol
# FUNCTION
#   Checks if node's protocol is enabled.
# INPUTS
#   * node_id -- node id
#   * protocol -- protocol to check
# RESULT
#   * check -- 1 if it is rip, otherwise 0
#****
proc getNodeProtocol { node_id protocol } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    if { $protocol == "bgp" } {
	set protocol "bgp 1000"
    }

    if { [netconfFetchSection $node_id "router $protocol"] != "" } {
	return 1
    } else {
	return 0
    }
}

#****f* nodecfg.tcl/setNodeProtocol
# NAME
#   setNodeProtocol
# SYNOPSIS
#   setNodeProtocol $node_id $protocol $state
# FUNCTION
#   Sets node's protocol state.
# INPUTS
#   * node_id -- node id
#   # protocol -- protocol to enable/disable
#   * state -- 1 if enabling protocol, 0 if disabling
#****
proc setNodeProtocol { node_id protocol state } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    if { $state == 1 } {
	switch -exact $protocol {
	    "rip" {
		set cfg [list "router rip" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ospf" \
		" network 0.0.0.0/0" \
		! ]
	    }
	    "ripng" {
		set cfg [list "router ripng" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ospf6" \
		" network ::/0" \
		! ]
	    }
	    "ospf" {
		set cfg [list "router ospf" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute rip" \
		" network 0.0.0.0/0 area 0.0.0.0" \
		! ]
	    }
	    "ospf6" {
		set router_id [ip::intToString [expr 1 + [string trimleft $node_id "n"]]]

		set area_string "area 0.0.0.0 range ::/0"
		if { [getNodeModel $node_id] == "quagga" } {
		    set area_string "network ::/0 area 0.0.0.0"
		}

		set cfg [list "router ospf6" \
		    " ospf6 router-id $router_id" \
		    " redistribute static" \
		    " redistribute connected" \
		    " redistribute ripng" \
		    " $area_string" \
		    ! ]
	    }
	    "bgp" {
		set loopback_ipv4 [lindex [split [getIfcIPv4addrs $node_id "lo0"] "/"] 0]

		set cfg [list "router bgp 1000" \
		    " bgp router-id $loopback_ipv4" \
		    " no bgp ebgp-requires-policy" \
		    " neighbor DEFAULT peer-group" \
		    " neighbor DEFAULT remote-as 1000" \
		    " neighbor DEFAULT update-source $loopback_ipv4" \
		    " redistribute static" \
		    " redistribute connected" \
		    ! ]
	    }
	}

	netconfInsertSection $node_id $cfg
    } else {
	if { $protocol == "bgp" } {
	    set protocol "bgp 1000"
	}

	netconfClearSection $node_id "router $protocol"
    }
}

#****f* nodecfg.tcl/getRouterProtocolCfg
# NAME
#   getRouterProtocolCfg -- get router protocol configuration
# SYNOPSIS
#   getRouterProtocolCfg $node_id $protocol
# FUNCTION
#   Returns the router protocol configuration.
# INPUTS
#   * node_id -- node id
#   * protocol -- router protocol
#****
proc getRouterProtocolCfg { node_id protocol } {
    if { [getNodeProtocol $node_id $protocol] == 0 } {
	return ""
    }

    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set router_id [ip::intToString [expr 1 + [string trimleft $node_id "n"]]]
	    switch -exact -- $protocol {
		"rip" {
		    lappend cfg "router rip"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute ospf"
		    lappend cfg " network 0.0.0.0/0"
		    lappend cfg "!"
		}
		"ripng" {
		    lappend cfg "router ripng"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute ospf6"
		    lappend cfg " network ::/0"
		    lappend cfg "!"
		}
		"ospf" {
		    lappend cfg "router ospf"
		    lappend cfg " ospf router-id $router_id"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute rip"
		    lappend cfg "!"
		}
		"ospf6" {
		    if { $model == "quagga" } {
			set id_string "router-id $router_id"
			#set area_string "network ::/0 area 0.0.0.0"
		    } else {
			set id_string "ospf6 router-id $router_id"
			#set area_string "area 0.0.0.0 range ::/0"
		    }

		    lappend cfg "router ospf6"
		    lappend cfg " $id_string"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute ripng"

		    if { $model == "quagga" } {
			foreach iface_id [ifcList $node_id] {
			    lappend cfg " interface $iface_id area 0.0.0.0"
			}
		    }

		    lappend cfg "!"
		}
		"bgp" {
		    set loopback_ipv4 [lindex [split [getIfcIPv4addrs $node_id "lo0" ] "/"] 0]
		    lappend cfg "router bgp 1000"
		    lappend cfg " bgp router-id $loopback_ipv4"
		    lappend cfg " no bgp ebgp-requires-policy"
		    lappend cfg " neighbor DEFAULT peer-group"
		    lappend cfg " neighbor DEFAULT remote-as 1000"
		    lappend cfg " neighbor DEFAULT update-source $loopback_ipv4"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg "!"
		}
	    }

	    lappend cfg "__EOF__"
	}
	"static" {
	    # nothing to return
	}
    }

    return $cfg
}

proc getRouterProtocolUnconfig { node_id protocol } {
    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set router_id [ip::intToString [expr 1 + [string trimleft $node_id "n"]]]
	    switch -exact -- $protocol {
		"rip" {
		    lappend cfg "no router rip"
		}
		"ripng" {
		    lappend cfg "no router ripng"
		}
		"ospf" {
		    lappend cfg "no router ospf"
		}
		"ospf6" {
		    lappend cfg "no router ospf6"

		    if { $model == "quagga" } {
			foreach iface [ifcList $node_id] {
			    lappend cfg " no interface $iface area 0.0.0.0"
			}
		    }

		    lappend cfg "!"
		}
		"bgp" {
		    lappend cfg "no router bgp 1000"
		}
	    }

	    lappend cfg "__EOF__"
	}
	"static" {
	    # nothing to return
	}
    }

    return $cfg
}

proc routerRoutesCfggen { node_id } {
    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    if { [getCustomEnabled $node_id] != true } {
		set routes4 [nodeCfggenStaticRoutes4 $node_id 1]
		set routes6 [nodeCfggenStaticRoutes6 $node_id 1]

		if { $routes4 != "" || $routes6 != "" } {
		    lappend cfg "vtysh << __EOF__"
		    lappend cfg "conf term"

		    set cfg [concat $cfg $routes4]
		    set cfg [concat $cfg $routes6]

		    lappend cfg "!"
		    lappend cfg "__EOF__"
		}
	    }

	    set routes4 [nodeCfggenAutoRoutes4 $node_id 1]
	    set routes6 [nodeCfggenAutoRoutes6 $node_id 1]

	    if { $routes4 != "" || $routes6 != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		set cfg [concat $cfg $routes4]
		set cfg [concat $cfg $routes6]

		lappend cfg "!"
		lappend cfg "__EOF__"
	    }
	}
	"static" {
	    if { [getCustomEnabled $node_id] != true } {
		set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id]]
		set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id]]

		lappend cfg ""
	    }

	    set cfg [concat $cfg [nodeCfggenAutoRoutes4 $node_id]]
	    set cfg [concat $cfg [nodeCfggenAutoRoutes6 $node_id]]

	    lappend cfg ""
	}
    }

    return $cfg
}

proc routerRoutesUncfggen { node_id } {
    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    if { [getCustomEnabled $node_id] != true } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id 1]]
		set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id 1]]

		lappend cfg "!"
		lappend cfg "__EOF__"
	    }

	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id 1]]
	    set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id 1]]

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    if { [getCustomEnabled $node_id] != true } {
		set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id]]
		set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id]]

		lappend cfg ""
	    }

	    set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id]]
	    set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id]]

	    lappend cfg ""
	}
    }

    return $cfg
}

proc nodeCfggenIfc { node_id iface_id } {
    global isOSlinux

    set cfg {}

    set iface_name [getIfcName $node_id $iface_id]

    set mac_addr [getIfcMACaddr $node_id $iface_id]
    if { $mac_addr != "" } {
	lappend cfg [getMacIfcCmd $iface_name $mac_addr]
    }

    set mtu [getIfcMTU $node_id $iface_id]
    lappend cfg [getMtuIfcCmd $iface_name $mtu]

    if { [getIfcNatState $node_id $iface_id] == "on" } {
	lappend cfg [getNatIfcCmd $iface_name]
    }

    set primary 1
    set addrs [getIfcIPv4addrs $node_id $iface_id]
    foreach addr $addrs {
	if { $addr != "" } {
	    lappend cfg [getIPv4IfcCmd $iface_name $addr $primary]
	    set primary 0
	}
    }

    set primary 1
    set addrs [getIfcIPv6addrs $node_id $iface_id]
    if { $isOSlinux } {
	# Linux is prioritizing IPv6 addresses in reversed order
	set addrs [lreverse $addrs]
    }
    foreach addr $addrs {
	if { $addr != "" } {
	    lappend cfg [getIPv6IfcCmd $iface_name $addr $primary]
	    set primary 0
	}
    }

    set state [getIfcOperState $node_id $iface_id]
    if { $state == "" } {
	set state "up"
    }

    lappend cfg [getStateIfcCmd $iface_name $state]

    return $cfg
}

proc nodeUncfggenIfc { node_id iface_id } {
    set cfg {}

    set iface_name [getIfcName $node_id $iface_id]

    set addrs [getIfcIPv4addrs $node_id $iface_id]
    foreach addr $addrs {
        if { $addr != "" } {
            lappend cfg [getDelIPv4IfcCmd $iface_name $addr]
        }
    }

    set addrs [getIfcIPv6addrs $node_id $iface_id]
    foreach addr $addrs {
        if { $addr != "" } {
            lappend cfg [getDelIPv6IfcCmd $iface_name $addr]
        }
    }

    return $cfg
}

proc routerCfggenIfc { node_id iface_id } {
    set ospf_enabled [getNodeProtocol $node_id "ospf"]
    set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

    set cfg {}

    set model [getNodeModel $node_id]
    set iface_name [getIfcName $node_id $iface_id]
    if { $iface_name == "lo0" } {
	set model "static"
    }

    switch -exact -- $model {
	"quagga" -
	"frr" {
	    set mac_addr [getIfcMACaddr $node_id $iface_id]
	    if { $mac_addr != "" } {
		lappend cfg [getMacIfcCmd $iface_name $mac_addr]
	    }

	    set mtu [getIfcMTU $node_id $iface_id]
	    lappend cfg [getMtuIfcCmd $iface_name $mtu]

	    if { [getIfcNatState $node_id $iface_id] == "on" } {
		lappend cfg [getNatIfcCmd $iface_name]
	    }

	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"
	    lappend cfg "interface $iface_name"

	    set addrs [getIfcIPv4addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " ip address $addr"
		}
	    }

	    if { $ospf_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " ip ospf area 0.0.0.0"
		}
	    }

	    set addrs [getIfcIPv6addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " ipv6 address $addr"
		}
	    }

	    if { $model == "frr" && $ospf6_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " ipv6 ospf6 area 0.0.0.0"
		}
	    }

	    if { [getIfcOperState $node_id $iface_id] == "down" } {
		lappend cfg " shutdown"
	    } else {
		lappend cfg " no shutdown"
	    }

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]
	}
    }

    return $cfg
}

proc routerUncfggenIfc { node_id iface_id } {
    set ospf_enabled [getNodeProtocol $node_id "ospf"]
    set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

    set cfg {}

    set model [getNodeModel $node_id]
    set iface_name [getIfcName $node_id $iface_id]
    if { $iface_name == "lo0" } {
	set model "static"
    }

    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"
	    lappend cfg "interface $iface_name"

	    set addrs [getIfcIPv4addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " no ip address $addr"
		}
	    }

	    if { $ospf_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " no ip ospf area 0.0.0.0"
		}
	    }

	    set addrs [getIfcIPv6addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " no ipv6 address $addr"
		}
	    }

	    if { $model == "frr" && $ospf6_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " no ipv6 ospf6 area 0.0.0.0"
		}
	    }

	    lappend cfg " shutdown"

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]
	}
    }

    return $cfg
}

#****f* nodecfg.tcl/registerModule
# NAME
#   registerModule -- register module
# SYNOPSIS
#   registerModule $module
# FUNCTION
#   Adds a module to all_modules_list.
# INPUTS
#   * module -- module to add
#****
proc registerModule { module } {
    global all_modules_list

    lappend all_modules_list $module
}

#****f* nodecfg.tcl/deregisterModule
# NAME
#   deregisterModule -- deregister module
# SYNOPSIS
#   deregisterModule $module
# FUNCTION
#   Removes a module from all_modules_list.
# INPUTS
#   * module -- module to remove
#****
proc deregisterModule { module } {
    global all_modules_list

    set all_modules_list [removeFromList $all_modules_list $module]
}

#****f* nodecfg.tcl/getIfcVlanDev
# NAME
#   getIfcVlanDev -- get interface vlan-dev
# SYNOPSIS
#   getIfcVlanDev $node_id $iface_id
# FUNCTION
#   Returns node's interface's vlan dev.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * tag -- interfaces's vlan-dev
#****
proc getIfcVlanDev { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "vlan-dev" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcVlanDev
# NAME
#   setIfcVlanDev -- set interface vlan-dev
# SYNOPSIS
#   setIfcVlanDev $node_id $iface_id $dev
# FUNCTION
#   Sets the node's interface's vlan dev.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * dev -- vlan-dev
#****
proc setIfcVlanDev { node_id iface_id dev } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "vlan-dev" } {
	    lappend ifcfg $line
	}
    }

    if { $dev in [ifcList $node_id] } {
	lappend ifcfg " vlan-dev $dev"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcVlanTag
# NAME
#   getIfcVlanTag -- get interface vlan-tag
# SYNOPSIS
#   getIfcVlanTag $node_id $iface_id
# FUNCTION
#   Returns node's interface's vlan tag.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * tag -- interfaces's vlan-tag
#****
proc getIfcVlanTag { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "vlan-tag" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcVlanTag
# NAME
#   setIfcVlanTag -- set interface vlan-tag
# SYNOPSIS
#   setIfcVlanTag $node_id $iface_id $tag
# FUNCTION
#   Sets the node's interface's vlan tag.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * dev -- vlan-tag
#****
proc setIfcVlanTag { node_id iface_id tag } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "vlan-tag" } {
	    lappend ifcfg $line
	}
    }

    if { $tag >= 1 && $tag <= 4094 } {
	lappend ifcfg " vlan-tag $tag"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getEtherVlanEnabled
# NAME
#   getEtherVlanEnabled -- get node rj45 vlan.
# SYNOPSIS
#   set state [getEtherVlanEnabled $node_id]
# FUNCTION
#   Returns whether the rj45 node is vlan enabled.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- vlan enabled
#****
proc getEtherVlanEnabled { node_id } {
    foreach line [netconfFetchSection $node_id "vlan"] {
	if { [lindex $line 0] == "enabled" } {
	    return [lindex $line 1]
	}
    }

    return 0
}

#****f* nodecfg.tcl/setEtherVlanEnabled
# NAME
#   setEtherVlanEnabled -- set node rj45 vlan.
# SYNOPSIS
#   setEtherVlanEnabled $node_id $state
# FUNCTION
#   Sets rj45 node vlan setting.
# INPUTS
#   * node_id -- node id
#   * state -- vlan enabled
#****
proc setEtherVlanEnabled { node_id state } {
    set vlancfg [list "vlan"]
    lappend vlancfg " enabled $state"
    foreach line [netconfFetchSection $node_id "vlan"] {
	if { [lindex $line 0] != "enabled" } {
	    lappend vlancfg $line
	}
    }

    netconfInsertSection $node_id $vlancfg
}

#****f* nodecfg.tcl/getEtherVlanTag
# NAME
#   getEtherVlanTag -- get node rj45 vlan tag.
# SYNOPSIS
#   set tag [getEtherVlanTag $node_id]
# FUNCTION
#   Returns rj45 node vlan tag.
# INPUTS
#   * node_id -- node id
# RESULT
#   * tag -- vlan tag
#****
proc getEtherVlanTag { node_id } {
    foreach line [netconfFetchSection $node_id "vlan"] {
	if { [lindex $line 0] == "tag" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setEtherVlanTag
# NAME
#   setEtherVlanTag -- set node rj45 vlan tag.
# SYNOPSIS
#   setEtherVlanTag $node_id $tag
# FUNCTION
#   Sets rj45 node vlan tag.
# INPUTS
#   * node_id -- node id
#   * tag -- vlan tag
#****
proc setEtherVlanTag { node_id tag } {
    set vlancfg [list "vlan"]
    foreach line [netconfFetchSection $node_id "vlan"] {
	if { [lindex $line 0] != "tag" } {
	    lappend vlancfg $line
	}
    }

    lappend vlancfg " tag $tag"

    netconfInsertSection $node_id $vlancfg
}

#****f* nodecfg.tcl/getNodeServices
# NAME
#   getNodeServices -- get node active services.
# SYNOPSIS
#   set services [getNodeServices $node_id]
# FUNCTION
#   Returns node's selected services.
# INPUTS
#   * node_id -- node id
# RESULT
#   * services -- active services
#****
proc getNodeServices { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "services *"] 1]
}

#****f* nodecfg.tcl/setNodeServices
# NAME
#   setNodeServices -- set node active services.
# SYNOPSIS
#   setNodeServices $node_id $services
# FUNCTION
#   Sets node selected services.
# INPUTS
#   * node_id -- node id
#   * services -- list of services
#****
proc setNodeServices { node_id services } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "services *"]
    if { $i >= 0 } {
        set $node_id [lreplace [set $node_id] $i $i "services {$services}"]
    } else {
        set $node_id [linsert [set $node_id] end "services {$services}"]
    }
}

#****f* nodecfg.tcl/getNodeCustomImage
# NAME
#   getNodeCustomImage -- get node custom image.
# SYNOPSIS
#   set value [getNodeCustomImage $node_id]
# FUNCTION
#   Returns node custom image setting.
# INPUTS
#   * node_id -- node id
# RESULT
#   * status -- custom image identifier
#****
proc getNodeCustomImage { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "custom-image *"] 1]
}

#****f* nodecfg.tcl/setNodeCustomImage
# NAME
#   setNodeCustomImage -- set node custom image.
# SYNOPSIS
#   setNodeCustomImage $node_id $img
# FUNCTION
#   Sets node custom image.
# INPUTS
#   * node_id -- node id
#   * img -- image identifier
#****
proc setNodeCustomImage { node_id img } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "custom-image *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i]
    }

    if { $img != "" } {
	lappend $node_id [list custom-image $img]
    }
}

#****f* nodecfg.tcl/getNodeDockerAttach
# NAME
#   getNodeDockerAttach -- get node docker ext iface attach.
# SYNOPSIS
#   set value [getNodeDockerAttach $node_id]
# FUNCTION
#   Returns node docker ext iface attach setting.
# INPUTS
#   * node_id -- node id
# RESULT
#   * status -- attach enabled
#****
proc getNodeDockerAttach { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    if { [lindex [lsearch -inline [set $node_id] "docker-attach *"] 1] == true } {
	return true
    } else {
	return false
    }
}

#****f* nodecfg.tcl/setNodeDockerAttach
# NAME
#   setNodeDockerAttach -- set node docker ext iface attach.
# SYNOPSIS
#   setNodeDockerAttach $node_id $state
# FUNCTION
#   Sets node docker ext iface attach status.
# INPUTS
#   * node_id -- node id
#   * state -- attach status
#****
proc setNodeDockerAttach { node_id state } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "docker-attach *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i]
    }

    if { $state == true } {
	lappend $node_id [list docker-attach $state]
    }
}

proc getNodeIface { node_id iface_id } {
}

proc setNodeIface { node_id iface_id new_iface } {
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv4
# NAME
#   nodeCfggenIfcIPv4 -- generate interface IPv4 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv4 $node_id
# FUNCTION
#   Generate configuration for all IPv4 addresses on all node
#   interfaces.
# INPUTS
#   * node_id -- node to generate configuration for
# RESULT
#   * value -- interface IPv4 configuration script
#****
proc nodeCfggenIfcIPv4 { node_id iface_id } {
    set cfg {}
    set primary 1
    foreach addr [getIfcIPv4addrs $node_id $iface_id] {
	lappend cfg [getIPv4IfcCmd [getIfcName $node_id $iface_id] $addr]
	set primary 0
    }

    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv6
# NAME
#   nodeCfggenIfcIPv6 -- generate interface IPv6 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv6 $node_id
# FUNCTION
#   Generate configuration for all IPv6 addresses on all node
#   interfaces.
# INPUTS
#   * node_id -- node to generate configuration for
# RESULT
#   * value -- interface IPv6 configuration script
#****
proc nodeCfggenIfcIPv6 { node_id iface_id } {
    set cfg {}
    set primary 1
    foreach addr [getIfcIPv6addrs $node_id $iface_id] {
	lappend cfg [getIPv6IfcCmd [getIfcName $node_id $iface_id] $addr]
	set primary 0
    }

    return $cfg
}

#****f* nodecfg.tcl/getAllNodesType
# NAME
#   getAllNodesType -- get list of all nodes of a certain type
# SYNOPSIS
#   getAllNodesType $type
# FUNCTION
#   Passes through the list of all nodes and returns a list of nodes of the
#   specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * list -- list of all nodes of the type
#****
proc getAllNodesType { type } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set type_list ""
    foreach node_id $node_list {
	if { [string match "$type*" [getNodeType $node_id]] } {
	    lappend type_list $node_id
	}
    }

    return $type_list
}

#****f* nodecfg.tcl/getNewNodeNameType
# NAME
#   getNewNodeNameType -- get a new node name for a certain type
# SYNOPSIS
#   getNewNodeNameType $type $namebase
# FUNCTION
#   Returns a new node name for the type and namebase, e.g. pc0 for pc.
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
# RESULT
#   * name -- new node name to be assigned
#****
proc getNewNodeNameType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    #if the variable pcnodes isn't set we need to check through all the nodes
    #to assign a non duplicate name
    if { ! [info exists num$type] } {
	recalculateNumType $type $namebase
    }

    incr num$type

    return $namebase[set num$type]
}

#****f* nodecfg.tcl/recalculateNumType
# NAME
#   recalculateNumType -- recalculate number for type
# SYNOPSIS
#   recalculateNumType $type $namebase
# FUNCTION
#   Calculates largest number for the given type
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
#****
proc recalculateNumType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    set num$type 0
    foreach node_id [getAllNodesType $type] {
	set name [getNodeName $node_id]
	if { [string match "$namebase*" $name] } {
	    set rest [string trimleft $name $namebase]
	    if { [string is integer $rest] && $rest > [set num$type] } {
		set num$type $rest
	    }
	}
    }
}

#****f* nodecfg.tcl/transformNodes
# NAME
#   transformNodes -- change nodes' types
# SYNOPSIS
#   transformNodes $nodes $to_type
# FUNCTION
#   Changes nodes' type and configuration. Conversion is possible between router
#   on the one side, and the pc or host on the other side.
# INPUTS
#   * nodes -- node ids
#   * to_type -- new type of node
#****
proc transformNodes { nodes to_type } {
    foreach node_id $nodes {
	if { [[getNodeType $node_id].netlayer] == "NETWORK" } {
	    upvar 0 ::cf::[set ::curcfg]::$node_id nodecfg
	    global changed

	    if { $to_type == "pc" || $to_type == "host" } {
		# replace type
		set typeIndex [lsearch $nodecfg "type *"]
		set nodecfg [lreplace $nodecfg $typeIndex $typeIndex "type $to_type" ]
		# if router, remove model
		set modelIndex [lsearch $nodecfg "model *"]
		set nodecfg [lreplace $nodecfg $modelIndex $modelIndex]

		# delete router stuff in netconf
		foreach model "rip ripng ospf ospf6" {
		    netconfClearSection $node_id "router $model"
		}

		set changed 1
	    } elseif { [getNodeType $node_id] != "router" && $to_type == "router" } {
		# replace type
		set typeIndex [lsearch $nodecfg "type *"]
		set nodecfg [lreplace $nodecfg $typeIndex $typeIndex "type $to_type"]

		# set router model and default protocols
		setNodeModel $node_id "frr"
		setNodeProtocol $node_id "rip" 1
		setNodeProtocol $node_id "ripng" 1
		# clear default static routes
		netconfClearSection $node_id "ip route [lindex [getStatIPv4routes $node_id] 0]"
		netconfClearSection $node_id "ipv6 route [lindex [getStatIPv6routes $node_id] 0]"

		set changed 1
	    }
	}
    }
}

#****f* nodecfg.tcl/getAllIpAddresses
# NAME
#   getAllIpAddresses -- retreives all IP addresses for current node
# SYNOPSIS
#   getAllIpAddresses $node_id
# FUNCTION
#   Retreives all local addresses (IPv4 and IPv6) for current node
# INPUTS
#   node_id - node id
#****
proc getAllIpAddresses { node_id } {
    set ifaces_list [ifcList $node_id]
    foreach logifc [logIfcList $node_id] {
	if { [string match "vlan*" $logifc] } {
	    lappend ifaces_list $logifc
	}
    }

    set ipv4_list ""
    set ipv6_list ""
    foreach iface_id $ifaces_list {
	set ifcIPs [getIfcIPv4addrs $node_id $iface_id]
	if { $ifcIPs != "" } {
	    lappend ipv4_list {*}$ifcIPs
	}

	set ifcIPs [getIfcIPv6addrs $node_id $iface_id]
	if { $ifcIPs != "" } {
	    lappend ipv6_list {*}$ifcIPs
	}
    }

    return "\"$ipv4_list\" \"$ipv6_list\""
}

#****f* nodecfg.tcl/pseudo.netlayer
# NAME
#   pseudo.netlayer -- pseudo layer
# SYNOPSIS
#   set layer [pseudo.netlayer]
# FUNCTION
#   Returns the layer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * layer -- returns an empty string
#****
proc pseudo.netlayer {} {
}

#****f* nodecfg.tcl/pseudo.virtlayer
# NAME
#   pseudo.virtlayer -- pseudo virtlayer
# SYNOPSIS
#   set virtlayer [pseudo.virtlayer]
# FUNCTION
#   Returns the virtlayer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * virtlayer -- returns an empty string
#****
proc pseudo.virtlayer {} {
}

proc nodeCfggenStaticRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    foreach statrte [getStatIPv4routes $node_id] {
	if { $vtysh } {
	    lappend cfg "ip route $statrte"
	} else {
	    lappend cfg [getIPv4RouteCmd $statrte]
	}
    }

    return $cfg
}

proc nodeUncfggenStaticRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    foreach statrte [getStatIPv4routes $node_id] {
	if { $vtysh } {
	    lappend cfg "no ip route $statrte"
	} else {
	    lappend cfg [getRemoveIPv4RouteCmd $statrte]
	}
    }

    return $cfg
}

proc nodeCfggenAutoRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes4 [getDefaultIPv4routes $node_id]
    foreach statrte $default_routes4 {
	if { $vtysh } {
	    lappend cfg "ip route $statrte"
	} else {
	    lappend cfg [getIPv4RouteCmd $statrte]
	}
    }
    setDefaultIPv4routes $node_id {}

    return $cfg
}

proc nodeUncfggenAutoRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes4 [getDefaultIPv4routes $node_id]
    foreach statrte $default_routes4 {
	if { $vtysh } {
	    lappend cfg "no ip route $statrte"
	} else {
	    lappend cfg [getRemoveIPv4RouteCmd $statrte]
	}
    }
    setDefaultIPv4routes $node_id {}

    return $cfg
}

proc nodeCfggenStaticRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    foreach statrte [getStatIPv6routes $node_id] {
	if { $vtysh } {
	    lappend cfg "ipv6 route $statrte"
	} else {
	    lappend cfg [getIPv6RouteCmd $statrte]
	}
    }

    return $cfg
}

proc nodeUncfggenStaticRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    foreach statrte [getStatIPv6routes $node_id] {
	if { $vtysh } {
	    lappend cfg "no ipv6 route $statrte"
	} else {
	    lappend cfg [getRemoveIPv6RouteCmd $statrte]
	}
    }

    return $cfg
}

proc nodeCfggenAutoRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes6 [getDefaultIPv6routes $node_id]
    foreach statrte $default_routes6 {
	if { $vtysh } {
	    lappend cfg "ipv6 route $statrte"
	} else {
	    lappend cfg [getIPv6RouteCmd $statrte]
	}
    }
    setDefaultIPv6routes $node_id {}

    return $cfg
}

proc nodeUncfggenAutoRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes6 [getDefaultIPv6routes $node_id]
    foreach statrte $default_routes6 {
	if { $vtysh } {
	    lappend cfg "no ipv6 route $statrte"
	} else {
	    lappend cfg [getRemoveIPv6RouteCmd $statrte]
	}
    }
    setDefaultIPv6routes $node_id {}

    return $cfg
}
