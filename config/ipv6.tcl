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

#****h* imunes/ipv6.tcl
# NAME
#   ipv6.tcl -- file for handeling IPv6
#****
global ipv6 change_subnet6

set ipv6 fc00::/64
set change_subnet6 0

#****f* ipv6.tcl/IPv6AddrApply
# NAME
#   IPv6AddrApply -- IPv6 address apply
# SYNOPSIS
#   IPv6AddrApply $w
# FUNCTION
#   Sets new IPv6 address from widget.
# INPUTS
#   * w -- widget
#****
proc IPv6AddrApply { w } {
	global ipv6
	global changed
	global control

	set newipv6 [$w.ipv6frame.e1 get]

	if { [checkIPv6Net $newipv6] == 0 } {
		focusAndFlash .entry1.ipv6frame.e1
		return
	}
	destroy $w

	if { $newipv6 != $ipv6 } {
		set changed 1
		set control 1
	}
	set ipv6 $newipv6
}

#****f* ipv6.tcl/findFreeIPv6Net
# NAME
#   findFreeIPv6Net -- find free IPv6 network
# SYNOPSIS
#   set ipnet [findFreeIPv6Net $mask]
# FUNCTION
#   Finds a free IPv6 network. Network is concidered to be free
#   if there are no simulated nodes attached to it.
# INPUTS
#   * mask -- this parameter is left unused for now
# RESULT
#   * ipnet -- returns the free IPv6 network address in the form "a $i".
#****
proc findFreeIPv6Net { mask { ipv6_used_list "" } } {
	global ipv6

	if { $ipv6_used_list == {} } {
		set defip6net [ip::contract [ip::prefix $ipv6]]
		set testnet [ip::contract "[string trimright $defip6net :]::"]

		return $testnet
	} else {
		set defip6net [ip::contract [ip::prefix $ipv6]]
		set subnets [lsort -unique [lmap ip $ipv6_used_list {ip::contract [ip::prefix $ip]}]]
		for { set i 0 } { $i <= 65535 } { incr i } {
			set testnet [ip::contract "[string trimright $defip6net :]:[format %x $i]::"]
			if { $testnet ni $subnets } {
				return $testnet
			}
		}
	}
}

#****f* ipv6.tcl/autoIPv6addr
# NAME
#   autoIPv6addr -- automaticaly assign an IPv6 address
# SYNOPSIS
#   autoIPv6addr $node_id $iface_id
# FUNCTION
#   automaticaly assignes an IPv6 address to the interface $iface_id of
#   of the node $node_id.
# INPUTS
#   * node_id -- the node containing the interface to witch a new
#     IPv6 address should be assigned
#   * iface_id -- the interface to witch a new, automatically generated, IPv6
#     address will be assigned
#****
proc autoIPv6addr { node_id iface_id { use_autorenumbered "" } } {
	if { ! [getActiveOption "IPv6autoAssign"] } {
		return
	}

	global change_subnet6 control autorenumbered_ifcs6
	#change_subnet6 - to change the subnet (1) or not (0)
	#autorenumbered_ifcs6 - list of all interfaces that changed an address

	set node_type [getNodeType $node_id]
	if { [$node_type.netlayer] != "NETWORK" } {
		#
		# Shouldn't get called at all for link-layer nodes
		#
		return
	}

	setToRunning "ipv6_used_list" [removeFromList [getFromRunning "ipv6_used_list"] [getIfcIPv6addrs $node_id $iface_id] "keep_doubles"]

	setIfcIPv6addrs $node_id $iface_id ""

	lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
	set peers_ip6addrs {}
	set has_extnat 0
	set has_router 0
	set best_choice_ip ""
	if { $peer_id != "" } {
		if { [[getNodeType $peer_id].netlayer] == "LINK" } {
			foreach l2node [listLANNodes $peer_id {}] {
				foreach l2node_iface_id [ifcList $l2node] {
					lassign [logicalPeerByIfc $l2node $l2node_iface_id] new_peer_id new_peer_iface_id
					set new_peer_ip6addrs [getIfcIPv6addrs $new_peer_id $new_peer_iface_id]
					if { $new_peer_ip6addrs == "" } {
						continue
					}

					if { $use_autorenumbered == "" || "$new_peer_id $new_peer_iface_id" in $autorenumbered_ifcs6 } {
						if { ! $has_extnat } {
							set new_peer_type [getNodeType $new_peer_id]
							if { $new_peer_type == "ext" && [getNodeNATIface $new_peer_id] != "UNASSIGNED" } {
								set has_extnat 1
								set best_choice_ip [lindex $new_peer_ip6addrs 0]
							} elseif { ! $has_router && $new_peer_type in "router nat64" } {
								set has_router 1
								set best_choice_ip [lindex $new_peer_ip6addrs 0]
							} elseif { ! $has_extnat && ! $has_router } {
								set best_choice_ip [lindex $new_peer_ip6addrs 0]
							}
						}

						lappend peers_ip6addrs {*}$new_peer_ip6addrs
					}
				}
			}
		} else {
			set peers_ip6addrs [getIfcIPv6addrs $peer_id $peer_iface_id]
			set best_choice_ip [lindex $peers_ip6addrs 0]
		}
	}

	if { $peers_ip6addrs != "" && $change_subnet6 == 0 && $best_choice_ip != "" } {
		set targetbyte [expr 0x[$node_type.IPAddrRange]]
		set addr [nextFreeIP6Addr $best_choice_ip $targetbyte $peers_ip6addrs]
	} else {
		set addr [getNextIPv6addr $node_type [getFromRunning "ipv6_used_list"]]
	}

	setIfcIPv6addrs $node_id $iface_id $addr
	lappendToRunning "ipv6_used_list" $addr
}

proc getNextIPv6addr { node_type existing_addrs } {
	if { ! [getActiveOption "IPv6autoAssign"] } {
		return
	}

	set targetbyte [expr 0x[$node_type.IPAddrRange]]

	# TODO: enable changing IPv6 pool mask
	return "[findFreeIPv6Net 64 $existing_addrs][format %x $targetbyte]/64"
}

#****f* ipv6.tcl/nextFreeIP6Addr
# NAME
#   nextFreeIP6Addr -- automaticaly assign an IPv6 address
# SYNOPSIS
#   nextFreeIP6Addr $addr $start $peers
# FUNCTION
#   Automaticaly searches for free IPv6 addresses within a given range
#   defined by $addr, containing $peers
# INPUTS
#   * $addr -- address of a node within the range
#   * $start -- starting host address for a specified node type
#   * $peers -- list of peers in the current network
#****
proc nextFreeIP6Addr { addr start peers } {
	global execMode gui

	set mask 64
	set prefix [ip::prefix $addr]
	set ipnums [split $prefix :]

	set lastpart [expr [lindex $ipnums 7] + $start]
	set ipnums [lreplace $ipnums 7 7 [format %x $lastpart]]
	set ipaddr [ip::contract [join $ipnums :]]/$mask
	while { $ipaddr in $peers } {
		set lastpart [expr $lastpart + 1 ]
		set ipnums [lreplace $ipnums 7 7 [format %x $lastpart]]
		set ipaddr [ip::contract [join $ipnums :]]/$mask
	}

	set x [ip::prefix $addr]
	set y [ip::prefix $ipaddr]

	if { $x != $y } {
		if { $gui && $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES warning" \
				"You have depleted the current pool of addresses ([ip::contract $x]/$mask). Please choose a new pool from Tools->IPV6 address pool or delete nodes to free the address space." \
				info 0 Dismiss
		}
		return ""
	}

	return $ipaddr
}

#****f* ipv6.tcl/checkIPv6Addr
# NAME
#   checkIPv6Addr -- check the IPv6 address
# SYNOPSIS
#   set valid [checkIPv6Addr $str]
# FUNCTION
#   Checks if the provided string is a valid IPv6 address.
# INPUTS
#   * str -- string to be evaluated.
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP address, 1 otherwise
#****
proc checkIPv6Addr { str } {
	try {
		ip::prefix $str
	} on error {} {
		return 0
	}

	return 1
}

#****f* ipv6.tcl/checkIPv6Net
# NAME
#   checkIPv6Net -- check the IPv6 network
# SYNOPSIS
#   set valid [checkIPv6Net $str]
# FUNCTION
#   Checks if the provided string is a valid IPv6 network.
# INPUTS
#   * str -- string to be evaluated. Valid string is in form ipv6addr/m
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP address, 1 otherwise.
#****
proc checkIPv6Net { str } {
	if { $str == "" } {
		return 1
	}
	if { ![checkIPv6Addr [lindex [split $str /] 0]] } {
		return 0
	}
	set net [string trim [lindex [split $str /] 1]]
	if { [string length $net] == 0 } {
		return 0
	}
	return [checkIntRange $net 0 128]
}

#****f* ipv6.tcl/checkIPv6Nets
# NAME
#   checkIPv6Nets -- check the IPv6 networks
# SYNOPSIS
#   set valid [checkIPv6Nets $str]
# FUNCTION
#   Checks if the provided string is a valid IPv6 networks.
# INPUTS
#   * str -- string to be evaluated. Valid IPv6 networks are writen in form
#     a.b.c.d; e.f.g.h
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP network, 1 otherwise
#****
proc checkIPv6Nets { str } {
	foreach net [split $str ";"] {
		set net [string trim $net]
		if { ![checkIPv6Net $net] } {
			return 0
		}
	}
	return 1
}
