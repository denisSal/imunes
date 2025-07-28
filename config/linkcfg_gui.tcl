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

# $Id: linkcfg.tcl 129 2015-02-13 11:14:44Z valter $

proc getLinkPeers_gui { link_id } {
	return [cfgGet "gui" "links" $link_id "peers"]
}

proc setLinkPeers_gui { link_id peers } {
	cfgSet "gui" "links" $link_id "peers" $peers
}

#****f* linkcfg.tcl/getLinkColor
# NAME
#   getLinkColor -- get link color
# SYNOPSIS
#   getLinkColor $link_id
# FUNCTION
#   Returns the color of the link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * color -- link color
#****
proc getLinkColor { link_id } {
	global default_link_color

	return [cfgGetWithDefault $default_link_color "gui" "links" $link_id "color"]
}

#****f* linkcfg.tcl/setLinkColor
# NAME
#   setLinkColor -- set link color
# SYNOPSIS
#   setLinkColor $link_id $color
# FUNCTION
#   Sets the color of the link.
# INPUTS
#   * link_id -- link id
#   * color -- link color
#****
proc setLinkColor { link_id color } {
	if { $color == "Red" } {
		set color ""
	}

	cfgSet "gui" "links" $link_id "color" $color
}

#****f* linkcfg.tcl/getLinkWidth
# NAME
#   getLinkWidth -- get link width
# SYNOPSIS
#   getLinkWidth $link_id
# FUNCTION
#   Returns the link width on canvas.
# INPUTS
#   * link_id -- link id
#****
proc getLinkWidth { link_id } {
	global default_link_width

	return [cfgGetWithDefault $default_link_width "gui" "links" $link_id "width"]
}

#****f* linkcfg.tcl/setLinkWidth
# NAME
#   setLinkWidth -- set link width
# SYNOPSIS
#   setLinkWidth $link_id $width
# FUNCTION
#   Sets the link width on canvas.
# INPUTS
#   * link_id -- link id
#   * width -- link width
#****
proc setLinkWidth { link_id width } {
	global default_link_width

	if { $width == $default_link_width } {
		set width ""
	}

	cfgSet "gui" "links" $link_id "width" $width
}

#****f* linkcfg.tcl/getLinkMirror
# NAME
#   getLinkMirror -- get link's mirror link
# SYNOPSIS
#   set mirror_link_id [getLinkMirror $link_id]
# FUNCTION
#   Returns the value of the link's mirror link. Mirror link is the other part
#   of the link connecting node to a pseudo node. Two mirror links present
#   only one physical link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * mirror_link_id -- mirror link id
#****
proc getLinkMirror { link_id } {
	return [cfgGet "gui" "links" $link_id "mirror"]
}

#****f* linkcfg.tcl/setLinkMirror
# NAME
#   setLinkMirror -- set link's mirror link
# SYNOPSIS
#   setLinkMirror $link_id $mirror
# FUNCTION
#   Sets the value of the link's mirror link. Mirror link is the other part of
#   the link connecting node to a pseudo node. Two mirror links present only
#   one physical link.
# INPUTS
#   * link_id -- link id
#   * mirror -- mirror link's id
#****
proc setLinkMirror { link_id mirror } {
	cfgSet "gui" "links" $link_id "mirror" $mirror
}

proc getPseudoLinksFromLink { link_id } {
	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
	set pseudo1_link_id "${link_id}.${node1_id}.${iface1_id}"
	set pseudo2_link_id "${link_id}.${node2_id}.${iface2_id}"
	
	if { [cfgGet "gui" "links" $pseudo1_link_id] != "" } {
		if { [cfgGet "gui" "links" $pseudo2_link_id] != "" } {
			return "$pseudo1_link_id $pseudo2_link_id"
		}
	}

	return ""
}

proc linkFromPseudoLink { pseudo_id } {
	return [split $pseudo_id "."]
}

#****f* linkcfg.tcl/splitLink
# NAME
#   splitLink -- split the link
# SYNOPSIS
#   set nodes [splitLink $orig_link_id]
# FUNCTION
#   Splits the link in two parts. Each part of the split link is one pseudo
#   link.
# INPUTS
#   * orig_link_id -- link id
# RESULT
#   * nodes -- list of node ids of new nodes.
#****
proc splitLink { orig_link_id } {
	set orig_nodes [getLinkPeers $orig_link_id]
	set orig_ifaces [getLinkPeersIfaces $orig_link_id]
	lassign $orig_nodes orig_node1_id orig_node2_id
	lassign $orig_ifaces orig_iface1_id orig_iface2_id

	set links "${orig_link_id}.${orig_node1_id}.${orig_iface1_id} ${orig_link_id}.${orig_node2_id}.${orig_iface2_id}"

	# create pseudo nodes
	set pseudo_nodes "${orig_node1_id}.${orig_iface1_id}"
	lappend pseudo_nodes "${orig_node2_id}.${orig_iface2_id}"

	foreach orig_node_id $orig_nodes orig_iface_id $orig_ifaces pseudo_node_id $pseudo_nodes link_id $links {
		set other_orig_node_id [removeFromList $orig_nodes $orig_node_id "keep_doubles"]
		set other_orig_iface_id [removeFromList $orig_ifaces $orig_iface_id "keep_doubles"]
		set other_link_id [removeFromList $links $link_id "keep_doubles"]

		# setup new pseudo node properties
		setNodeMirror $pseudo_node_id [removeFromList $pseudo_nodes $pseudo_node_id "keep_doubles"]
		setPseudoNodeLink $pseudo_node_id $link_id
		setNodeLabel $pseudo_node_id "[getNodeName $other_orig_node_id]:[getIfcName $other_orig_node_id $other_orig_iface_id]"

		# pseudo node default values
		setNodeCoords $pseudo_node_id [getNodeCoords $other_orig_node_id]
		setNodeLabelCoords $pseudo_node_id [getNodeCoords $pseudo_node_id]
		setNodeCanvas $pseudo_node_id [getNodeCanvas $orig_node_id]

		# setup new pseudo link properties
		setLinkPeers_gui $link_id "$pseudo_node_id $orig_node_id"
		setLinkMirror $link_id $other_link_id
		setLinkColor $link_id [getLinkColor $orig_link_id]
	}

	return $pseudo_nodes
}

#****f* linkcfg.tcl/mergeLink
# NAME
#   mergeLink -- merge the link
# SYNOPSIS
#   set new_link_id [mergeLink $link_id]
# FUNCTION
#   Rebuilts a link from two pseudo links.
# INPUTS
#   * link_id -- pseudo link id
# RESULT
#   * link_id -- rebuilt link id
#****
proc mergeLink { link_id } {
	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id == "" } {
		return
	}

	lassign [getLinkPeers_gui $link_id] pseudo_node1_id orig_node1_id
	lassign [getLinkPeers_gui $mirror_link_id] pseudo_node2_id orig_node2_id

	cfgUnset "gui" "nodes" $pseudo_node1_id
	cfgUnset "gui" "nodes" $pseudo_node2_id

	cfgUnset "gui" "links" $link_id
	cfgUnset "gui" "links" $mirror_link_id

	lassign [linkFromPseudoLink $link_id] link_id - -

	return $link_id
}
