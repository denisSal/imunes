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

# $Id: vm.tcl 63 2025-05-18 17:55:50Z itomasic $


#****h* imunes/vm.tcl
# NAME
#  vm.tcl -- defines vm specific procedures
# FUNCTION
#  This module is used to define all the vm specific procedures.
# NOTES
#  Procedures in this module start with the keyword vm and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE vm

#****f* vm.tcl/vm.toolbarIconDescr
# NAME
#   vm.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   vm.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
	return "Add new VM"
}

proc $MODULE._confNewIfc { node_cfg iface_id } {
	global node_existing_mac node_existing_ipv4 node_existing_ipv6

	set ipv4addr [getNextIPv4addr [_getNodeType $node_cfg] $node_existing_ipv4]
	lappend node_existing_ipv4 $ipv4addr
	set node_cfg [_setIfcIPv4addrs $node_cfg $iface_id $ipv4addr]

	set ipv6addr [getNextIPv6addr [_getNodeType $node_cfg] $node_existing_ipv6]
	lappend node_existing_ipv6 $ipv6addr
	set node_cfg [_setIfcIPv6addrs $node_cfg $iface_id $ipv6addr]

	set macaddr [getNextMACaddr $node_existing_mac]
	lappend node_existing_mac $macaddr
	set node_cfg [_setIfcMACaddr $node_cfg $iface_id $macaddr]

	return $node_cfg
}

#****f* vm.tcl/vm.icon
# NAME
#   vm.icon -- icon
# SYNOPSIS
#   vm.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
proc $MODULE.icon { size } {
	global ROOTDIR LIBDIR

	switch $size {
		normal {
			return $ROOTDIR/$LIBDIR/icons/normal/vm.gif
		}
		small {
			return $ROOTDIR/$LIBDIR/icons/small/vm.gif
		}
		toolbar {
			return $ROOTDIR/$LIBDIR/icons/tiny/vm.gif
		}
	}
}

#****f* vm.tcl/vm.notebookDimensions
# NAME
#   vm.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   vm.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
	set h 210
	set w 507

	if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "Configuration" } {
		set h 350
		set w 507
	}

	if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "Interfaces" } {
		set h 370
		set w 507
	}

	return [list $h $w]
}

#****f* vm.tcl/vm.configGUI
# NAME
#   vm.configGUI -- configuration GUI
# SYNOPSIS
#   vm.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the vm configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
	global wi
	#
	#guielements - the list of modules contained in the configuration window
	#              (each element represents the name of the procedure which creates
	#              that module)
	#
	#treecolumns - the list of columns in the interfaces tree (each element
	#              consists of the column id and the column name)
	#
	global guielements treecolumns
	global node_cfg node_cfg_gui node_existing_mac node_existing_ipv4 node_existing_ipv6

	set guielements {}
	set treecolumns {}
	set node_cfg [cfgGet "nodes" $node_id]
	set node_cfg_gui [cfgGet "gui" "nodes" $node_id]
	set node_existing_mac [getFromRunning "mac_used_list"]
	set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
	set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

	configGUI_createConfigPopupWin $c
	wm title $wi "vm configuration"

	configGUI_nodeName $wi $node_id "Node name:"
	configGUI_VMConfig $wi $node_id
	configGUI_buttonsACNode $wi $node_id
}
