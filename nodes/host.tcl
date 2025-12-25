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

# $Id: host.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/host.tcl
# NAME
#  host.tcl -- defines host specific procedures
# FUNCTION
#  This module is used to define all the host specific procedures.
# NOTES
#  Procedures in this module start with the keyword host and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE host
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#### required for every node
proc $MODULE.netlayer {} {
	return [genericL3.netlayer]
}
#### /required for every node

#****f* host.tcl/host.confNewNode
# NAME
#   host.confNewNode -- configure new node
# SYNOPSIS
#   host.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id [getNewNodeNameType host $nodeNamingBase(host)]
	setNodeAutoDefaultRoutesStatus $node_id "enabled"

	set logiface_id [newLogIface $node_id "lo"]
	setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
	setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

#****f* host.tcl/host.generateConfig
# NAME
#   host.generateConfig -- configuration generator
# SYNOPSIS
#   set config [host.generateConfig $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure host.bootcmd.
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added. portmap
#   and inetd are also started.
# INPUTS
#   * node_id -- node id
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
	set cfg [genericL3.generateConfig $node_id]

	if {
		[getNodeCustomEnabled $node_id] != true ||
		[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] in "\"\" DISABLED"
	} {
		lappend cfg ""
		lappend cfg "rpcbind"
		lappend cfg "inetd"
	}

	return $cfg
}

proc $MODULE.generateUnconfig { node_id } {
	set cfg [genericL3.generateUnconfig $node_id]

	if {
		[getNodeCustomEnabled $node_id] != true ||
		[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] in "\"\" DISABLED"
	} {
		lappend cfg ""
		lappend cfg "killall rpcbind"
		lappend cfg "killall inetd"
	}

	return $cfg
}

#****f* host.tcl/host.IPAddrRange
# NAME
#   host.IPAddrRange -- IP address range
# SYNOPSIS
#   host.IPAddrRange
# FUNCTION
#   Returns host IP address range
# RESULT
#   * range -- host IP address range
#****
proc $MODULE.IPAddrRange {} {
	return 10
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################
