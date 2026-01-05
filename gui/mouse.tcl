#****f* editor.tcl/animateCursor
# NAME
#   animateCursor -- animate current cursor
# SYNOPSIS
#   animateCursor
# FUNCTION
#   Animates the cursor to show the status of the running script.
#****
proc animateCursor {} {
	global cursorState
	global clock_seconds

	if { [clock seconds] == $clock_seconds } {
		update

		return
	}

	set clock_seconds [clock seconds]
	if { $cursorState } {
		.panwin.f1.c config -cursor watch
		set cursorState 0
	} else {
		.panwin.f1.c config -cursor pirate
		set cursorState 1
	}

	update
}

#****f* editor.tcl/removeLinkGUI
# NAME
#   removeLinkGUI -- remove link from GUI
# SYNOPSIS
#   renoveGUILink $link_id $atomic
# FUNCTION
#   Removes link from GUI. It removes standard links as well as
#   split links and links connecting nodes on different canvases.
# INPUTS
#   * link_id -- the link id
#   * atomic -- defines if the remove was atomic action or a part
#     of a composed, non-atomic action (relevant for updating log
#     for undo).
#****
proc removeLinkGUI { link_id atomic { keep_ifaces 0 } } {
	global changed

	if { $link_id == "" } {
		return
	}

	if { $atomic == "atomic" } {
		if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
			setToExecuteVars "terminate_cfg" [cfgGet]
		}
	}

	set new_link_id [mergeLink $link_id]
	if { $new_link_id != "" } {
		set link_id $new_link_id
	}

	# this data needs to be fetched before we removeLink
	lassign [getLinkPeers $link_id] node1_id node2_id

	set node1_type [getNodeType $node1_id]
	set node2_type [getNodeType $node2_id]
	# TODO: check this when wlan node turn comes
	if { "wlan" in "$node1_type $node2_type" } {
		removeLink [lindex [linkFromPseudoLink $link_id] 0]

		return
	}

	removeLink [lindex [linkFromPseudoLink $link_id] 0] $keep_ifaces
	cfgUnset "gui" "links" $link_id

	if { $atomic == "atomic" } {
		.panwin.f1.c delete $link_id

		if { [getFromRunning "stop_sched"] } {
			redeployCfg
		}

		set changed 1
		if { $new_link_id != "" || $keep_ifaces || "rj45" in "$node1_type $node2_type" } {
			redrawAll
		}

		updateUndoLog
		.panwin.f1.c config -cursor left_ptr
	}
}

#****f* editor.tcl/removeNodeGUI
# NAME
#   removeNodeGUI -- remove node from GUI
# SYNOPSIS
#   removeNodeGUI $node_id
# FUNCTION
#   Removes node from GUI. When removing a node from GUI the links
#   connected to that node are also removed.
# INPUTS
#   * node_id -- node id
#****
proc removeNodeGUI { node_id { keep_other_ifaces 0 } } {
	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	if { [isPseudoNode $node_id] } {
		removeLinkGUI [getPseudoNodeLink $node_id] non-atomic $keep_other_ifaces
	} else {
		foreach iface_id [ifcList $node_id] {
			set pseudo_id [getPseudoNodeFromNodeIface $node_id $iface_id]
			if { $pseudo_id != "" } {
				removeLinkGUI [getPseudoNodeLink $pseudo_id] non-atomic $keep_other_ifaces

				continue
			}

			set link_id [getIfcLink $node_id $iface_id]
			if { $link_id != "" } {
				removeLinkGUI $link_id non-atomic $keep_other_ifaces
			}
		}
	}

	if { [getNodeCustomIcon $node_id] != "" } {
		removeImageReference [getNodeCustomIcon $node_id] $node_id
	}

	removeNode $node_id $keep_other_ifaces
	cfgUnset "gui" "nodes" $node_id

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	.panwin.f1.c delete $node_id
}

#****f* editor.tcl/splitLinkGUI
# NAME
#   splitLinkGUI -- splits a link
# SYNOPSIS
#   splitLinkGUI $link_id
# FUNCTION
#   Splits the link and draws new links and new pseudo nodes
#   on the canvas.
# INPUTS
#   * link_id -- link id
#****
proc splitLinkGUI { link_id } {
	global changed

	set zoom [getActiveOption "zoom"]
	set curcanvas [getFromRunning_gui "curcanvas"]

	lassign [getLinkPeers $link_id] orig_node1_id orig_node2_id
	lassign [splitLink $link_id] new_node1_id new_node2_id

	lassign [getNodeCoords $orig_node1_id] x1 y1
	lassign [getNodeCoords $orig_node2_id] x2 y2

	setNodeCoords $new_node1_id \
		"[expr {($x1 + 0.4 * ($x2 - $x1)) / $zoom}] \
		[expr {($y1 + 0.4 * ($y2 - $y1)) / $zoom}]"
	setNodeCoords $new_node2_id \
		"[expr {($x1 + 0.6 * ($x2 - $x1)) / $zoom}] \
		[expr {($y1 + 0.6 * ($y2 - $y1)) / $zoom}]"
	setNodeLabelCoords $new_node1_id [getNodeCoords $new_node1_id]
	setNodeLabelCoords $new_node2_id [getNodeCoords $new_node2_id]

	setNodeCanvas $new_node1_id $curcanvas
	setNodeCanvas $new_node2_id $curcanvas

	set changed 1
	updateUndoLog
	redrawAll
}

#****f* editor.tcl/selectNode
# NAME
#   selectNode -- select node
# SYNOPSIS
#   selectNode $c $obj
# FUNCTION
#   Crates the selecting box around the specified canvas
#   object.
# INPUTS
#   * c -- tk canvas
#   * obj -- tk canvas object tag id
#****
proc selectNode { c obj } {
	if { $obj == "none" } {
		$c delete -withtags "selectmark"
		return
	}

	set node_id [lindex [$c gettags $obj] 1]
	if { $node_id == "" } {
		return
	}

	$c addtag selected withtag "node && $node_id"
	if { [isPseudoNode $node_id] } {
		set bbox [$c bbox "nodelabel && $node_id"]
	} elseif { [getAnnotationType $node_id] == "rectangle" } {
		$c addtag selected withtag "rectangle && $node_id"
		set bbox [$c bbox "rectangle && $node_id"]
	} elseif { [getAnnotationType $node_id] == "text" } {
		$c addtag selected withtag "text && $node_id"
		set bbox [$c bbox "text && $node_id"]
	} elseif { [getAnnotationType $node_id] == "oval" } {
		$c addtag selected withtag "oval && $node_id"
		set bbox [$c bbox "oval && $node_id"]
	} elseif { [getAnnotationType $node_id] == "freeform" } {
		$c addtag selected withtag "freeform && $node_id"
		set bbox [$c bbox "freeform && $node_id"]
	} else {
		set bbox [$c bbox "node && $node_id"]
	}

	if { $bbox == "" } {
		return
	}

	lassign $bbox bx1 by1 bx2 by2
	set bx1 [expr {$bx1 - 2}]
	set by1 [expr {$by1 - 2}]
	set bx2 [expr {$bx2 + 1}]
	set by2 [expr {$by2 + 1}]
	$c delete -withtags "selectmark && $node_id"
	$c create line $bx1 $by1 $bx2 $by1 $bx2 $by2 $bx1 $by2 $bx1 $by1 \
		-dash {6 4} -fill black -width 1 -tags "selectmark $node_id"
}

#****f* editor.tcl/selectAllObjects
# NAME
#   selectAllObjects -- select all objects on the canvas
# SYNOPSIS
#   selectAllObjects
# FUNCTION
#   Select all object on the canvas.
#****
proc selectAllObjects {} {
	set all_objects [.panwin.f1.c find withtag \
		"node || text || oval || rectangle || freeform"]
	foreach obj $all_objects {
		selectNode .panwin.f1.c $obj
	}
}

#****f* editor.tcl/selectNodes
# NAME
#   selectNodes -- select nodes
# SYNOPSIS
#   selectNodes $nodelist
# FUNCTION
#   Select all nodes in a list.
# INPUTS
#   * nodelist -- list of nodes to select.
#****
proc selectNodes { nodelist } {
	foreach node_id $nodelist {
		selectNode .panwin.f1.c [.panwin.f1.c find withtag \
			"(node || text || oval || rectangle || freeform) && $node_id"]
	}
}

#****f* editor.tcl/selectedNodes
# NAME
#   selectedNodes -- get selected nodes
# SYNOPSIS
#   selectedNodes
# FUNCTION
#   Gets selected nodes and returns them as a list.
# RESULT
#   * selected -- object list of selected nodes.
#****
proc selectedNodes {} {
	set selected {}
	foreach obj [.panwin.f1.c find withtag "node && selected"] {
		lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
	}

	return $selected
}

#****f* editor.tcl/selectedAnnotations
# NAME
#   selectedAnnotations -- get selected annotations
# SYNOPSIS
#   selectedAnnotations
# FUNCTION
#   Gets selected annotations and returns them as a list.
# RESULT
#   * selected -- object list of selected annotations.
#****
proc selectedAnnotations {} {
	set selected {}
	foreach obj [.panwin.f1.c find withtag "oval && selected"] {
		lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
	}

	foreach obj [.panwin.f1.c find withtag "rectangle && selected"] {
		lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
	}

	foreach obj [.panwin.f1.c find withtag "text && selected"] {
		lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
	}

	foreach obj [.panwin.f1.c find withtag "freeform && selected"] {
		lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
	}

	return $selected
}

#****f* editor.tcl/selectedRealNodes
# NAME
#   selectedRealNodes -- get selected real nodes
# SYNOPSIS
#   selectedRealNodes
# FUNCTION
#   Gets selected real nodes and returns them as a list.
# RESULT
#   * selected -- object list of selected real nodes.
#****
proc selectedRealNodes {} {
	set selected {}
	foreach obj [.panwin.f1.c find withtag "node && selected"] {
		set node_id [lindex [.panwin.f1.c gettags $obj] 1]
		if { [isPseudoNode $node_id] } {
			continue
		}
		lappend selected $node_id
	}

	return $selected
}

#****f* editor.tcl/selectAdjacent
# NAME
#   selectAdjacent -- select adjacent nodes
# SYNOPSIS
#   selectAdjacent
# FUNCTION
#   Finds all adjacent nodes and selects them.
#****
proc selectAdjacent {} {
	set selected [selectedNodes]
	set adjacent {}
	foreach node_id $selected {
		foreach iface_id [ifcList $node_id] {
			set peer_id [getIfcPeer $node_id $iface_id]
			if { $peer_id == "" } {
				continue
			}

			set mirror_node [getNodeMirror $peer_id]
			if { $mirror_node != "" } {
				set peer_id [getIfcPeer $mirror_node "ifc0"]
			}

			if { $peer_id ni $adjacent } {
				lappend adjacent $peer_id
			}
		}
	}

	if { $adjacent != "" } {
		selectNodes $adjacent
	}
}

#****f* editor.tcl/button3link
# NAME
#   button3link
# SYNOPSIS
#   button3link $c $x $y
# FUNCTION
#   This procedure is called when a right mouse button is
#   clicked on the canvas. If there is a link on the place of
#   mouse click this procedure creates and configures a popup
#   menu. The options in the menu are:
#   * Configure -- configure the link
#   * Delete -- delete the link
#   * Split -- split the link
#   * Merge -- this option is active only if the link is previously
#   been split, by this action the link is merged.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate for popup menu
#   * y -- y coordinate for popup menu
#****
proc button3link { c x y } {
	global isOSlinux

	set oper_mode [getFromRunning "oper_mode"]

	set link_id [lindex [$c gettags "link && current"] 1]
	if { $link_id == "" } {
		set link_id [lindex [$c gettags "linklabel && current"] 1]
		if { $link_id == "" } {
			return
		}
	}

	lassign [linkFromPseudoLink $link_id] real_link_id - -

	if { $real_link_id != "" } {
		global linkDirect_$real_link_id
		set linkDirect_$real_link_id [getLinkDirect $real_link_id]
	}

	.button3menu delete 0 end

	#
	# Configure link
	#
	.button3menu add command -label "Configure" \
		-command "linkConfigGUI $c $link_id"

	#
	# Clear link configuration
	#
	.button3menu add command -label "Clear all settings" \
		-command "linkResetConfig [lindex [linkFromPseudoLink $link_id] 0] ; redrawAll"

	global linkJitterConfiguration
	if  { $linkJitterConfiguration } {
		#
		# Edit link jitter
		#
		.button3menu add command -label "Edit link jitter" \
			-command "linkJitterConfigGUI $c $link_id"
		#
		# Reset link jitter
		#
		.button3menu add command -label "Clear link jitter" \
			-command "linkJitterReset $link_id"
	}

	#
	# Toggle direct link
	#
	if { [isPseudoLink $link_id] } {
		lassign [linkFromPseudoLink $link_id] - peer1_id peer1_iface_id
		lassign [logicalPeerByIfc $peer1_id $peer1_iface_id] peer2_id peer2_iface_id
	} else {
		lassign [getLinkPeers $link_id] peer1_id peer2_id
		lassign [getLinkPeersIfaces $link_id] peer1_iface_id peer2_iface_id
	}

	if {
		! $isOSlinux ||
		$oper_mode == "edit" ||
		! [getFromRunning "auto_execution"] ||
		([isRunningNode $peer1_id] &&
		[isRunningNode $peer2_id])
	} {
		.button3menu add checkbutton -label "Direct link" \
			-underline 5 -variable linkDirect_$real_link_id \
			-command "toggleDirectLink $c $link_id"
	} else {
		.button3menu add checkbutton -label "Direct link" \
			-underline 5 -variable linkDirect_$real_link_id \
			-state disabled
	}

	#
	# Delete link
	#
	if { $oper_mode == "edit" || [getFromRunning "stop_sched"] } {
		.button3menu add command -label "Delete" \
			-command "removeLinkGUI $link_id atomic"
	} else {
		.button3menu add command -label "Delete" \
			-state disabled
	}

	#
	# Delete link (keep ifaces)
	#
	if {
		$oper_mode == "edit" ||
		[getFromRunning "stop_sched"]
	} {
		.button3menu add command -label "Delete (keep interfaces)" \
			-command "removeLinkGUI $link_id atomic 1"
	} else {
		.button3menu add command -label "Delete (keep interfaces)" \
			-state disabled
	}

	#
	# Split link
	#
	if { ! [isPseudoLink $link_id] } {
		.button3menu add command -label "Split" \
			-command "splitLinkGUI $link_id"
	} else {
		.button3menu add command -label "Split" -state disabled
	}

	#
	# Merge two pseudo nodes / links
	#
	set peers [getLinkPeers $real_link_id]
	if {
		[isPseudoLink $link_id] &&
		[getNodeCanvas [lindex [getLinkPeers_gui [getLinkMirror $link_id]] 0]] ==
		[getFromRunning_gui "curcanvas"] &&
		[lindex $peers 0] != [lindex $peers 1]
	} {
		.button3menu add command -label "Merge" \
			-command "mergeNodeGUI [lindex [getLinkPeers_gui $link_id] 0]"
	} else {
		.button3menu add command -label "Merge" -state disabled
	}

	set x [winfo pointerx .]
	set y [winfo pointery .]
	tk_popup .button3menu $x $y
}

#****f* editor.tcl/moveToCanvas
# NAME
#   moveToCanvas -- move to canvas
# SYNOPSIS
#   moveToCanvas $canvas_id
# FUNCTION
#   This procedure moves all the nodes selected in the GUI to
#   the specified canvas.
# INPUTS
#   * canvas_id -- canvas id.
#****
proc moveToCanvas { canvas_id } {
	global changed

	set curcanvas [getFromRunning_gui "curcanvas"]

	set selected_nodes [selectedNodes]
	foreach node_id $selected_nodes {
		setNodeCanvas $node_id $canvas_id
		set changed 1
	}

	set selected_annotations [selectedAnnotations]
	foreach node_id $selected_annotations {
		setAnnotationCanvas $node_id $canvas_id
		set changed 1
	}

	foreach obj [.panwin.f1.c find withtag "linklabel"] {
		set link_id [lindex [.panwin.f1.c gettags $obj] 1]

		lassign [getLinkPeers [lindex [linkFromPseudoLink $link_id] 0]] \
			real_peer1_id real_peer2_id

		# if both (or none) real nodes are moved, don't do anything
		if {
			($real_peer1_id in $selected_nodes &&
			$real_peer2_id in $selected_nodes) ||
			($real_peer1_id ni $selected_nodes &&
			$real_peer2_id ni $selected_nodes)
		} {
			continue
		}

		# if we had a pseudo link before, merge it
		if { [isPseudoLink $link_id] } {
			set link_id [mergeLink $link_id]
		}

		#lassign [getLinkPeers_gui $link_id] peer1_id peer2_id
		set real_peer1_canvas_id [getNodeCanvas $real_peer1_id]
		set real_peer2_canvas_id [getNodeCanvas $real_peer2_id]

		# if nodes are on different canvases, split link
		if { $real_peer1_canvas_id != $real_peer2_canvas_id } {
			lassign [splitLink $link_id] new_node1_id new_node2_id

			setNodeCoords $new_node1_id [getNodeCoords $real_peer2_id]
			setNodeCoords $new_node2_id [getNodeCoords $real_peer1_id]
			setNodeLabelCoords $new_node1_id [getNodeCoords $new_node1_id]
			setNodeLabelCoords $new_node2_id [getNodeCoords $new_node2_id]

			setNodeCanvas $new_node1_id $real_peer1_canvas_id
			setNodeCanvas $new_node2_id $real_peer2_canvas_id
		}
	}

	updateUndoLog
	redrawAll
}

#****f* editor.tcl/mergeNodeGUI
# NAME
#   mergeNodeGUI -- merge GUI node
# SYNOPSIS
#   mergeNodeGUI $node_id
# FUNCTION
#   This procedure removes the specified pseudo node as well
#   as it's mirror copy. Also this procedure removes the
#   pseudo links and reestablish the original link between
#   the non-pseudo nodes.
# INPUTS
#   * node_id -- node id of a pseudo node.
#****
proc mergeNodeGUI { node_id } {
	global changed

	set link_id [mergeLink [getPseudoNodeLink $node_id]]

	set changed 1
	updateUndoLog
	redrawAll

	return $link_id
}

#****f* editor.tcl/button3node
# NAME
#   button3node
# SYNOPSIS
#   button3node $c $x $y
# FUNCTION
#   This procedure is called when a right mouse button is
#   clicked on the canvas. If there is a node on the place of
#   mouse click this procedure creates and configures a popup
#   menu. The options in the menu are:
#   * Configure -- configure the node
#   * Create link to -- create a link to any available node,
#   it can be on the same canvas or on a different canvas.
#   * Move to -- move to some other canvas
#   * Merge -- this option is available only for pseudo nodes
#   that have mirror nodes on the same canvas (Pseudo nodes
#   created by splitting a link).
#   * Delete -- delete the node
#   * Shell window -- specifies the shell window to open in
#   exec mode. This option is available only to nodes on a
#   network layer
#   * Wireshark -- opens a Wireshark program for the specified
#   node and the specified interface. This option is available
#   only for network layer nodes in exec mode.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate for popup menu
#   * y -- y coordinate for popup menu
#****
proc button3node { c x y } {
	set canvas_list [getFromRunning_gui "canvas_list"]
	set curcanvas [getFromRunning_gui "curcanvas"]
	set oper_mode [getFromRunning "oper_mode"]

	set node_id [lindex [$c gettags "(node || nodelabel || node_running) && current"] 1]
	if { $node_id == "" } {
		return
	}

	if { [$c gettags "node && $node_id && selected"] == "" } {
		$c dtag node selected
		$c delete -withtags selectmark
		selectNode $c [$c find withtag "current"]
	}

	set node_type [getNodeType $node_id]

	set root_menu ".button3menu"
	$root_menu delete 0 end

	# pseudo node menu
	if { $node_type == "" && [isPseudoNode $node_id] } {
		menu_mergeNodes $node_id $root_menu
		menu_deleteSelection $node_id $root_menu
		menu_deleteSelectionKeepIfaces $node_id $root_menu

		#
		# Finally post the popup menu on current pointer position
		#
		set x [winfo pointerx .]
		set y [winfo pointery .]
		tk_popup $root_menu $x $y

		return
	}

	foreach menu_proc [invokeTypeProc $node_type "gui::rightClickMenus"] {
		{*}${menu_proc} $node_id $root_menu
	}

	#
	# Finally post the popup menu on current pointer position
	#
	set x [winfo pointerx .]
	set y [winfo pointery .]
	tk_popup $root_menu $x $y
}

#****f* editor.tcl/button1
# NAME
#   button1 -- button1 clicked
# SYNOPSIS
#   button1 $c $x $y $button
# FUNCTION
#   This procedure is called when a left mouse button is
#   clicked on the canvas. This procedure selects a new
#   node or creates a new node, depending on the selected
#   tool.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#   * button -- the keyboard button that is pressed.
#****
proc button1 { c x y button } {
	global newlink curobj changed
	global router pc host lanswitch frswitch rj45 hub
	global oval rectangle text freeform newtext
	global lastX lastY
	global background selectbox
	global resizemode resizeobj

	set zoom [getActiveOption "zoom"]

	set x [$c canvasx $x]
	set y [$c canvasy $y]

	set lastX $x
	set lastY $y

	set active_tool [getActiveTool]
	set curobj [$c find withtag current]
	set curtype [lindex [$c gettags current] 0]
	set wasselected 0
	if {
		($active_tool == "select" && $curtype in "node oval rectangle text freeform") ||
		($curtype == "nodelabel" &&
		[isPseudoNode [lindex [$c gettags $curobj] 1]])
	} {
		set node_id [lindex [$c gettags current] 1]
		set wasselected [expr {$node_id in "[selectedNodes] [selectedAnnotations]"}]

		if { $button == "ctrl" } {
			if { $wasselected } {
				$c dtag $node_id selected
				$c delete -withtags "selectmark && $node_id"
			}
		} elseif { ! $wasselected } {
			foreach node_type "node text oval rectangle freeform" {
				$c dtag $node_type selected
			}
			$c delete -withtags selectmark
		}

		if { $active_tool != "link" && ! $wasselected } {
			selectNode $c $curobj
		}
	} elseif { $active_tool == "select" && $curtype == "selectmark" } {
		set o1 [lindex [$c gettags current] 1]
		if { [getAnnotationType $o1] in "oval rectangle" } {
			set resizeobj $o1
			set bbox1 [$c bbox $o1]
			set x1 [lindex $bbox1 0]
			set y1 [lindex $bbox1 1]
			set x2 [lindex $bbox1 2]
			set y2 [lindex $bbox1 3]
			set l 0 ;# left
			set r 0 ;# right
			set u 0 ;# up
			set d 0 ;# down

			if { $x < [expr $x1+($x2-$x1)/8.0] } { set l 1 }
			if { $x > [expr $x2-($x2-$x1)/8.0] } { set r 1 }
			if { $y < [expr $y1+($y2-$y1)/8.0] } { set u 1 }
			if { $y > [expr $y2-($y2-$y1)/8.0] } { set d 1 }

			if { $l == 1 } {
				if { $u == 1 } {
					set resizemode lu
				} elseif { $d == 1 } {
					set resizemode ld
				} else {
					set resizemode l
				}
			} elseif { $r == 1 } {
				if { $u == 1 } {
					set resizemode ru
				} elseif { $d == 1 } {
					set resizemode rd
				} else {
					set resizemode r
				}
			} elseif { $u == 1 } {
				set resizemode u
			} elseif { $d == 1 } {
				set resizemode d
			} else {
				set resizemode false
			}
		}
	} elseif { $button != "ctrl" || $active_tool != "select" } {
		foreach node_type "node text oval rectangle freeform" {
			$c dtag $node_type selected
		}

		$c delete -withtags selectmark
	}

	#determine whether we can create nodes on the current object
	set object_drawable 0
	foreach type "background grid rectangle oval freeform text" {
		if { $type in [.panwin.f1.c gettags $curobj] } {
			set object_drawable 1
			break
		}
	}

	if { $object_drawable } {
		if { $active_tool ni "select link oval rectangle text freeform" } {
			global newnode

			# adding a new node
			set node_id [newNode $active_tool]
			if { $button == "ctrl" } {
				lappendToRunning "no_auto_execute_nodes" $node_id
			}

			setNodeLabel $node_id [getNodeName $node_id]
			setNodeCanvas $node_id [getFromRunning_gui "curcanvas"]
			setNodeCoords $node_id "[expr {$x / $zoom}] [expr {$y / $zoom}]"

			# To calculate label distance we take into account the normal icon
			# height
			global $active_tool\_iconheight

			set dy [expr [set $active_tool\_iconheight]/2 + 11]
			setNodeLabelCoords $node_id "[expr {$x / $zoom}] \
				[expr {$y / $zoom + $dy}]"

			drawNode $node_id
			foreach node_type "node text oval rectangle freeform" {
				$c dtag $node_type selected
			}
			$c delete -withtags selectmark
			selectNode $c [$c find withtag "node && $node_id"]

			set newnode $node_id
			set changed 1
		} elseif {
			$active_tool == "select" &&
			$curtype ni "node nodelabel"
		} {
			$c config -cursor cross

			set lastX $x
			set lastY $y
			if { $selectbox != "" } {
				# We actually shouldn't get here!
				$c delete $selectbox
				set selectbox ""
			}
		} elseif { $active_tool in "oval rectangle" } {
			$c config -cursor cross
			set lastX $x
			set lastY $y
		} elseif { $active_tool == "text" } {
			$c config -cursor xterm
			set lastX $x
			set lastY $y
			set newtext [$c create text $lastX $lastY \
				-text "" \
				-anchor w \
				-justify left \
				-tags "newtext"]
		}
	} else {
		if { $curtype in "node nodelabel text oval rectangle freeform" } {
			if { $active_tool == "select" && $button == "ctrl" && $wasselected } {
				$c config -cursor cross
			} else {
				$c config -cursor fleur
			}
		}

		if { $active_tool == "link" && $curtype in "node node_running" } {
			$c config -cursor cross
			set lastX [lindex [$c coords $curobj] 0]
			set lastY [lindex [$c coords $curobj] 1]
			set newlink [$c create line $lastX $lastY $x $y \
				-fill [getActiveOption "default_link_color"] -width [getActiveOption "default_link_width"] \
				-tags "link"]
		}
	}

	raiseAll $c
}

#****f* editor.tcl/button1-motion
# NAME
#   button1-motion -- button1 moved
# SYNOPSIS
#   button1-motion $c $x $y
# FUNCTION
#   This procedure is called when a left mouse button is
#   pressed and the mouse is moved around the canvas.
#   This procedure creates new select box, moves the
#   selected nodes or draws a new link.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button1-motion { c x y } {
	global newlink changed
	global lastX lastY sizex sizey selectbox background
	global newoval newrect newtext newfree resizemode

	set zoom [getActiveOption "zoom"]

	set x [$c canvasx $x]
	set y [$c canvasy $y]
	set curobj [$c find withtag current]
	set curtype [lindex [$c gettags current] 0]
	set active_tool [getActiveTool]
	if { $active_tool == "link" && $newlink != "" } {
		#creating a new link
		$c coords $newlink $lastX $lastY $x $y
	} elseif {
		$active_tool == "select" &&
		$curtype == "nodelabel" &&
		! [isPseudoNode [lindex [$c gettags $curobj] 1]]
	} {
		$c move $curobj [expr {$x - $lastX}] [expr {$y - $lastY}]

		set changed 1
		set lastX $x
		set lastY $y
	} elseif {
		$active_tool == "select" &&
		$curobj == "" &&
		$curtype == ""
	} {
		return
	} elseif {
		$active_tool == "select" &&
		($curobj == $selectbox ||
		$curtype in "background grid" ||
		($curobj ni [$c find withtag "selected"] &&
		$curtype != "selectmark") &&
		! [isPseudoNode [lindex [$c gettags $curobj] 1]])
	} {
		#forming the selectbox and resizing
		if { $selectbox == "" } {
			set err [catch {
				set selectbox [$c create line \
					$lastX $lastY $x $lastY $x $y $lastX $y $lastX $lastY \
					-dash {10 4} -fill black -width 1 -tags "selectbox"]
			} error]
			if { $err != 0 } {
				return
			}

			$c raise $selectbox "all"
		} else {
			set err [catch {
				$c coords $selectbox \
					$lastX $lastY $x $lastY $x $y $lastX $y $lastX $lastY
			} error]
			if { $err != 0 } {
				return
			}
		}
		# actually we should check if curobj == bkgImage
	} elseif {
		$active_tool == "oval" &&
		($curobj in "$newoval $background" ||
		$curtype in "background oval rectangle grid text freeform")
	} {
		# Draw a new oval
		if { $newoval == "" } {
			set newoval [$c create oval $lastX $lastY $x $y \
				-outline blue \
				-dash {10 4} \
				-width 1 \
				-tags "newoval"]

			$c raise $newoval "background || link || linklabel || interface"
		} else {
			$c coords $newoval \
				$lastX $lastY $x $y
		}
	} elseif {
		$active_tool == "rectangle" &&
		($curobj in "$newrect $background" ||
		$curtype in "background oval rectangle grid text freeform")
	} {
		# Draw a new rectangle
		if { $newrect == "" } {
			set newrect [$c create rectangle $lastX $lastY $x $y \
				-outline blue \
				-dash {10 4} \
				-width 1 \
				-tags "newrect"]

			$c raise $newrect "oval || background || link || linklabel || interface"
		} else {
			$c coords $newrect $lastX $lastY $x $y
		}
	} elseif {
		$active_tool == "freeform" &&
		($curobj in "$newfree $background" ||
		$curtype in "background oval rectangle grid text freeform")
	} {
		# Draw a new freeform
		if { $newfree == "" } {
			set newfree [$c create line $lastX $lastY $x $y \
				-fill blue \
				-width 2 \
				-tags "newfree"]

			$c raise $newfree "oval || rectangle || background || link || linklabel || interface"
		} else {
			xpos $newfree $x $y 2 blue
		}
	} elseif { $active_tool == "select" && $curtype == "selectmark" } {
		# resize annotation
		foreach o [$c find withtag "selected"] {
			set node_id [lindex [$c gettags $o] 1]

			lassign [lmap n [getAnnotationCoords $node_id] {expr {$n * $zoom}}] oldX1 oldY1 oldX2 oldY2
			switch -exact -- $resizemode {
				lu {
					set oldX1 $x
					set oldY1 $y
				}
				ld {
					set oldX1 $x
					set oldY2 $y
				}
				l {
					set oldX1 $x
				}
				ru {
					set oldX2 $x
					set oldY1 $y
				}
				rd {
					set oldX2 $x
					set oldY2 $y
				}
				r {
					set oldX2 $x
				}
				u {
					set oldY1 $y
				}
				d {
					set oldY2 $y
				}
			}

			if { $selectbox == "" } {
				set err [catch {
					set selectbox [$c create line \
						$oldX1 $oldY1 $oldX2 $oldY1 $oldX2 $oldY2 $oldX1 $oldY2 $oldX1 $oldY1 \
						-dash {10 4} -fill black -width 1 -tags "selectbox"]
				} error]
				if { $err != 0 } {
					return
				}

				$c raise $selectbox "all"
			} else {
				set err [catch {
					$c coords $selectbox \
						$oldX1 $oldY1 $oldX2 $oldY1 $oldX2 $oldY2 $oldX1 $oldY2 $oldX1 $oldY1
				} error]
				if { $err != 0 } {
					return
				}
			}
		}
	} else {
		foreach img [$c find withtag "selected"] {
			$c move $img [expr {$x - $lastX}] [expr {$y - $lastY}]

			set node_id [lindex [$c gettags $img] 1]

			foreach elem "selectmark nodedisabled node_running nodelabel link" {
				set obj [$c find withtag "$elem && $node_id"]
				$c move $obj [expr {$x - $lastX}] [expr {$y - $lastY}]

				if { $elem == "link" } {
					$c addtag need_redraw withtag "link && $node_id"
				}
			}
		}

		foreach link_id [$c find withtag "link && need_redraw"] {
			redrawLink [lindex [$c gettags $link_id] 1]
		}

		$c dtag link need_redraw
		set changed 1
		set lastX $x
		set lastY $y
	}
}

#****f* editor.tcl/button1-release
# NAME
#   button1-release -- button1 released
# SYNOPSIS
#   button1-release $c $x $y
# FUNCTION
#   This procedure is called when a left mouse button is
#   released.
#   The result of this function depends on the actions
#   during the button1-motion procedure.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button1-release { c x y } {
	global newlink curobj grid
	global changed selectbox
	global lastX lastY sizex sizey
	global autorearrange_enabled
	global resizemode resizeobj
	global newnode

	set zoom [getActiveOption "zoom"]
	set undolevel [getFromRunning "undolevel"]
	set redolevel [getFromRunning "redolevel"]

	set redrawNeeded 0

	set outofbounds 0

	set x [$c canvasx $x]
	set y [$c canvasy $y]
	$c config -cursor left_ptr
	set active_tool [getActiveTool]
	# if the link tool is active and we are creating a new link
	if { $active_tool == "link" && $newlink != "" } {
		$c delete $newlink
		set newlink ""
		set destobj ""

		# find the node that is under the cursor
		foreach obj [$c find overlapping $x $y $x $y] {
			if { [lindex [$c gettags $obj] 0] in "node node_running" } {
				set destobj $obj
				break
			}
		}

		# if there is an object beneath the cursor and an object was
		# selected by the button1 procedure create a link between nodes
		if { $destobj != "" && $curobj != "" && $destobj != $curobj } {
			set lnode1 [lindex [$c gettags $curobj] 1]
			set lnode2 [lindex [$c gettags $destobj] 1]
			newLinkGUI $lnode1 $lnode2
		}
	} elseif { $active_tool in "rectangle oval text freeform" } {
		popupAnnotationDialog $c 0 "false"
	}

	if { $changed == 1 } {
		set regular true

		# selects the node whose label was moved
		if { [lindex [$c gettags $curobj] 0] == "nodelabel" } {
			set node_id [lindex [$c gettags $curobj] 1]
			selectNode $c [$c find withtag "node && $node_id"]
		}

		set selected {}
		foreach img [$c find withtag "selected"] {
			set node_id [lindex [$c gettags $img] 1]
			lappend selected $node_id
			set coords [$c coords $img]
			set x [expr {[lindex $coords 0] / $zoom}]
			set y [expr {[lindex $coords 1] / $zoom}]

			# only nodes are snapped to grid, annotations are not
			if {
				$autorearrange_enabled == 0 &&
				[$c find withtag "node && $node_id"] != ""
			} {
				set dx [expr {(int($x / $grid + 0.5) * $grid - $x) * $zoom}]
				set dy [expr {(int($y / $grid + 0.5) * $grid - $y) * $zoom}]
				$c move $img $dx $dy

				set coords [$c coords $img]
				set x [expr {[lindex $coords 0] / $zoom}]
				set y [expr {[lindex $coords 1] / $zoom}]
				setNodeCoords $node_id "$x $y"

				#moving the nodelabel assigned to the moving node
				$c move "nodelabel && $node_id" $dx $dy
				set coords [$c coords "nodelabel && $node_id"]
				set x [expr {[lindex $coords 0] / $zoom}]
				set y [expr {[lindex $coords 1] / $zoom}]
				setNodeLabelCoords $node_id "$x $y"
				if { $x < 0 || $y < 0 || $x > $sizex || $y > $sizey } {
					set regular false
				}
			} else {
				set dx 0
				set dy 0
			}

			if { [lindex [$c gettags $node_id] 0] == "oval" } {
				lassign [$c coords [lindex [$c gettags $node_id] 1]] x1 y1 x2 y2
				set x1 [expr {$x1 / $zoom}]
				set y1 [expr {$y1 / $zoom}]
				set x2 [expr {$x2 / $zoom}]
				set y2 [expr {$y2 / $zoom}]

				if { $x1 < 0 } {
					set x2 [expr {$x2-$x1}]
					set x1 0
					set outofbounds 1
				}
				if { $y1 < 0 } {
					set y2 [expr {$y2-$y1}]
					set y1 0
					set outofbounds 1
				}
				if { $x2 > $sizex } {
					set x1 [expr {$x1-($x2-$sizex)}]
					set x2 $sizex
					set outofbounds 1
				}
				if { $y2 > $sizey } {
					set y1 [expr {$y1-($y2-$sizey)}]
					set y2 $sizey
					set outofbounds 1
				}

				setAnnotationCoords $node_id "$x1 $y1 $x2 $y2"
			}

			if { [lindex [$c gettags $node_id] 0] == "rectangle" } {
				set coordinates [$c coords [lindex [$c gettags $node_id] 1]]
				set x1 [expr {[lindex $coordinates 0] / $zoom}]
				set y1 [expr {[lindex $coordinates 1] / $zoom}]
				set x2 [expr {[lindex $coordinates 6] / $zoom}]
				set y2 [expr {[lindex $coordinates 13] / $zoom}]

				if { $x1 < 0 } {
					set x2 [expr {$x2-$x1}]
					set x1 0
					set outofbounds 1
				}
				if { $y1 < 0 } {
					set y2 [expr {$y2-$y1}]
					set y1 0
					set outofbounds 1
				}
				if { $x2 > $sizex } {
					set x1 [expr {$x1-($x2-$sizex)}]
					set x2 $sizex
					set outofbounds 1
				}
				if { $y2 > $sizey } {
					set y1 [expr {$y1-($y2-$sizey)}]
					set y2 $sizey
					set outofbounds 1
				}

				setAnnotationCoords $node_id "$x1 $y1 $x2 $y2"
			}

			if { [lindex [$c gettags $node_id] 0] == "freeform" } {
				lassign [$c bbox "selectmark && $node_id"] x1 y1 x2 y2
				set x1 [expr {$x1 / $zoom}]
				set y1 [expr {$y1 / $zoom}]
				set x2 [expr {$x2 / $zoom}]
				set y2 [expr {$y2 / $zoom}]

				set shiftx 0
				set shifty 0

				if { $x1 < 0 } {
					set shiftx -$x1
					set outofbounds 1
				}
				if { $y1 < 0 } {
					set shifty -$y1
					set outofbounds 1
				}
				if { $x2 > $sizex } {
					set shiftx [expr $sizex-$x2]
					set outofbounds 1
				}
				if { $y2 > $sizey } {
					set shifty [expr $sizey-$y2]
					set outofbounds 1
				}

				set coordinates [$c coords [lindex [$c gettags $node_id] 1]]
				set l [expr {[llength $coordinates]-1}]
				set newcoords {}
				set i 0

				while { $i <= $l } {
					set f1 [expr {[lindex $coords $i] * $zoom}]
					set g1 [expr {[lindex $coords $i+1] * $zoom}]
					set xx1 [expr $f1+$shiftx]
					set yy1 [expr $g1+$shifty]

					lappend newcoords $xx1 $yy1
					set i [expr {$i+2}]
				}

				setAnnotationCoords $node_id $newcoords
			}

			if { [lindex [$c gettags $node_id] 0] == "text" } {
				set bbox [$c bbox "selectmark && $node_id"]
				lassign [$c coords [lindex [$c gettags $node_id] 1]] x1 y1
				set x1 [expr {$x1 / $zoom}]
				set y1 [expr {$y1 / $zoom}]

				set width [expr [lindex $bbox 2] - [lindex $bbox 0]]
				set height [expr [lindex $bbox 3] - [lindex $bbox 1]]

				if { [lindex $bbox 0] < 0 } {
					set x1 5
					set outofbounds 1
				}
				if { [lindex $bbox 1] < 0 } {
					set y1 [expr $height/2]
					set outofbounds 1
				}
				if { [lindex $bbox 2] > $sizex } {
					set x1 [expr $sizex-$width+5]
					set outofbounds 1
				}
				if { [lindex $bbox 3] > $sizey } {
					set y1 [expr {$sizey-$height/2}]
					set outofbounds 1
				}

				setAnnotationCoords $node_id "$x1 $y1"
			}

			$c move "selectmark && $node_id" $dx $dy
			$c addtag need_redraw withtag "link && $node_id"
			set changed 1
		} ;# end of: foreach img selected

		if { $outofbounds } {
			redrawAll
			if { $active_tool == "select" } {
				selectNodes $selected
			}
		}

		if { $regular == "true" } {
			if { [getFromRunning "stop_sched"] } {
				redeployCfg
			}

			foreach img [$c find withtag "node && selected"] {
				set node_id [lindex [$c gettags $img] 1]
				drawNode $node_id
				selectNode $c [$c find withtag "node && $node_id"]
			}

			foreach link_id [$c find withtag "link && need_redraw"] {
				redrawLink [lindex [$c gettags $link_id] 1]
				updateLinkLabel [lindex [$c gettags $link_id] 1]
			}
		} else {
			if { $newnode != "" } {
				removeNode $newnode
			}

			.panwin.f1.c config -cursor watch
			.bottom.textbox config -text ""

			jumpToUndoLevel $undolevel
			redrawAll

			if { $active_tool == "select" } {
				selectNodes $selected
			}

			set changed 0
		}

		$c dtag link need_redraw
	} elseif { $active_tool == "select" } {
		# $changed!=1
		if { $selectbox == "" } {
			set x1 $x
			set y1 $y
			set autorearrange_enabled 0
		} else {
			set coords [$c coords $selectbox]
			set x [expr {int([lindex $coords 0] / $zoom)}]
			set y [expr {int([lindex $coords 1] / $zoom)}]
			set x1 [expr {int([lindex $coords 4] / $zoom)}]
			set y1 [expr {int([lindex $coords 5] / $zoom)}]
			$c delete $selectbox
			set selectbox ""
		}

		if { $resizemode == "false" } {
			set enclosed {}

			catch { $c find enclosed $x $y $x1 $y1 } enc_objs
			foreach obj $enc_objs {
				set tags [$c gettags $obj]
				if { [lindex $tags 0] == "node" && [lsearch $tags selected] == -1 } {
					lappend enclosed $obj
				}
				if { [lindex $tags 0] == "oval" && [lsearch $tags selected] == -1 } {
					lappend enclosed $obj
				}
				if { [lindex $tags 0] == "rectangle" && [lsearch $tags selected] == -1 } {
					lappend enclosed $obj
				}
				if { [lindex $tags 0] == "text" && [lsearch $tags selected] == -1 } {
					lappend enclosed $obj
				}
				if { [lindex $tags 0] == "freeform" && [lsearch $tags selected] == -1 } {
					lappend enclosed $obj
				}
			}

			foreach obj $enclosed {
				selectNode $c $obj
			}
		} else {
			setAnnotationCoords $resizeobj "$x $y $x1 $y1"
			set redrawNeeded 1
			set resizemode false
			set changed 1
		}
	}

	set newnode ""

	if { $redrawNeeded } {
		set redrawNeeded 0
		redrawAll
	} else {
		raiseAll $c
	}

	update
	updateUndoLog
	.panwin.f1.c config -cursor left_ptr
}

#****f* editor.tcl/button3background
# NAME
#   button3background -- button3 background
# SYNOPSIS
#   button3background $c $x $y
# FUNCTION
#   Popup menu for right click on canvas background.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button3background { c x y } {
	global changed

	set canvas_list [getFromRunning_gui "canvas_list"]
	set curcanvas [getFromRunning_gui "curcanvas"]

	.button3menu delete 0 end

	#
	# Show canvas background
	#
	set toggle_bkg_command {
		setGlobalOption "show_background_image" - "toggle"

		redrawAll
		set changed 1
		updateUndoLog
	}
	.button3menu add checkbutton -label "Show background" \
		-underline 5 -variable show_background_image \
		-command $toggle_bkg_command

	.button3menu add separator
	#
	# Change canvas background
	#
	.button3menu add command -label "Change background" \
		-command "changeBkgPopup"

	#
	# Remove canvas background
	#
	set tmp_command [list apply {
		{ curcanvas canvas_bkg } {
			removeCanvasBkg $curcanvas
			if { $canvas_bkg != "" } {
				removeImageReference $canvas_bkg $curcanvas
			}

			redrawAll
			set changed 1
			updateUndoLog
		}
	} \
		$curcanvas \
		[getCanvasBkg $curcanvas]
	]
	.button3menu add command \
		-label "Remove background" \
		-command $tmp_command

	.button3menu.canvases delete 0 end

	set m .button3menu.canvases

	set mode normal
	if { [llength $canvas_list] == 1 } {
		set mode disabled
	}

	.button3menu add cascade \
		-label "Set background from:" \
		-menu $m \
		-underline 0 \
		-state $mode

	foreach c $canvas_list {
		set canv_name [getCanvasName $c]
		set canvas_bkg [getCanvasBkg $c]
		set curcanvas_size [getCanvasSize $curcanvas]
		set othercanvsize [getCanvasSize $c]
		if { $curcanvas != $c && $curcanvas_size == $othercanvsize } {

			set tmp_command [list apply {
				{ curcanvas canvas_bkg } {
					setCanvasBkg $curcanvas $canvas_bkg
					setImageReference $canvas_bkg $curcanvas

					redrawAll
					set changed 1
					updateUndoLog
				}
			} \
				$curcanvas \
				$canvas_bkg
			]
			$m add command \
				-label "$canv_name" \
				-command $tmp_command
		}
	}

	#
	# Finally post the popup menu on current pointer position
	#
	set x [winfo pointerx .]
	set y [winfo pointery .]
	tk_popup .button3menu $x $y
}

#****f* editor.tcl/setDefaultIcon
# NAME
#   setDefaultIcon -- set default icon
# SYNOPSIS
#   setDefaultIcon
# FUNCTION
#   Sets all selected nodes icons to default icons.
#****
proc setDefaultIcon {} {
	global changed
	set nodelist [selectedNodes]

	foreach node_id $nodelist {
		set icon [getNodeCustomIcon $node_id]
		removeNodeCustomIcon $node_id
		removeImageReference $icon $node_id
	}

	redrawAll
	set changed 1
	updateUndoLog
}

#****f* editor.tcl/nodeEnter
# NAME
#   nodeEnter -- node enter
# SYNOPSIS
#   nodeEnter $c
# FUNCTION
#   This procedure prints the node id, node name and
#   node model (if exists), as well as all the interfaces
#   of the node in the status line.
#   Information is presented for the node above which is
#   the mouse pointer.
# INPUTS
#   * c -- tk canvas
#****
proc nodeEnter { c } {
	set node_id [lindex [$c gettags current] 1]
	if { [isPseudoNode $node_id] } {
		lassign [nodeFromPseudoNode $node_id] real_node_id real_iface_id
		.bottom.textbox config -foreground "black" \
			-text "pseudo {$node_id} from {$real_node_id} [getNodeName $real_node_id]:[getIfcName $real_node_id $real_iface_id]"

		return
	}

	set err [catch { getNodeType $node_id } error]
	if { $err != 0 } {
		return
	}

	#Show node error only if in exec mode
	if { [isRunningNode $node_id] } {
		if { [isErrorNode $node_id] && [getStateErrorMsgNode $node_id] != "" } {
			.bottom.textbox configure -text "{$node_id} ERROR: [getStateErrorMsgNode $node_id]" -foreground "red"

			return
		}

		set line ""
		foreach iface_id [ifcList $node_id] {
			if { ! [isErrorNodeIface $node_id $iface_id] } {
				continue
			}

			set iface_error [getStateErrorMsgNodeIface $node_id $iface_id]
			if { $iface_error == "" } {
				continue
			}

			set line "$line$iface_error\n"
		}

		if { $line != "" } {
			# remove last \n
			set line [string range $line 0 end-1]
			.bottom.textbox config -text "{$node_id} IFACES ERRORS: $line" -foreground "red"

			return
		}
	}

	set name [getNodeName $node_id]
	set model [getNodeModel $node_id]
	if { $model != "" } {
		set line "{$node_id} $name ($model):"
	} else {
		set line "{$node_id} $name:"
	}

	if { [getNodeType $node_id] != "rj45" } {
		foreach iface_id [ifcList $node_id] {
			set line "$line [getIfcName $node_id $iface_id]:[join [getIfcIPv4addrs $node_id $iface_id] ", "]"
		}
	}
	.bottom.textbox config -text "$line" -foreground "black"

	showCfg $c $node_id
	showRoute $c $node_id
}

#****f* editor.tcl/linkEnter
# NAME
#   linkEnter -- link enter
# SYNOPSIS
#   linkEnter $c
# FUNCTION
#   This procedure prints the link id, link bandwidth
#   and link delay in the status line.
#   Information is presented for the link above which is
#   the mouse pointer.
# INPUTS
#   * c -- tk canvas
#****
proc linkEnter { c } {
	set link_id [lindex [$c gettags current] 1]
	if { [lsearch [getFromRunning "link_list"] $link_id] == -1 } {
		return
	}
	set line "$link_id: [getLinkBandwidthString $link_id] [getLinkDelayString $link_id]"
	.bottom.textbox config -text "$line" -foreground "black"
}

#****f* editor.tcl/anyLeave
# NAME
#   anyLeave
# SYNOPSIS
#   anyLeave $c
# FUNCTION
#   This procedure clears the status line.
# INPUTS
#   * c -- tk canvas
#****
proc anyLeave { c } {
	.bottom.textbox config -text "" -foreground "black"

	$c delete -withtag showCfgPopup
	$c delete -withtag route
}

#****f* editor.tcl/deleteSelection
# NAME
#   deleteSelection -- delete selection
# SYNOPSIS
#   deleteSelection
# FUNCTION
#   By calling this procedure all the selected nodes in imunes will
#   be deleted.
#****
proc deleteSelection { { keep_other_ifaces 0 } { no_warning "" } } {
	global changed
	global viewid

	if { $no_warning == "" && [getFromRunning "cfg_deployed"] } {
		set answer [tk_messageBox -message "Are you sure you want to delete selected nodes?\n\nThere is no undo in exec mode." \
			-icon question -type yesno]

		switch -- $answer {
			yes {}
			no {
				return
			}
		}
	}

	if { ! [getFromRunning "stop_sched"] } {
		return
	}

	catch { unset viewid }
	.panwin.f1.c config -cursor watch; update

	foreach node_id [selectedNodes] {
		removeNodeGUI $node_id $keep_other_ifaces

		set changed 1
	}

	foreach annotation_id [selectedAnnotations] {
		deleteAnnotation $annotation_id

		set changed 1
	}

	if { $changed } {
		raiseAll .panwin.f1.c
		updateUndoLog
		redrawAll
	}

	.panwin.f1.c config -cursor left_ptr
	.bottom.textbox config -text ""
}

#****f* editor.tcl/removeIPv4Nodes
# NAME
#   removeIPv4Nodes -- remove ipv4 nodes
# SYNOPSIS
#   removeIPv4Nodes
# FUNCTION
#   Sets all nodes' IPv4 addresses to empty strings.
#****
proc removeIPv4Nodes { nodes all_ifaces } {
	global changed

	if { $nodes == "*" } {
		set nodes [getFromRunning "node_list"]
	}

	set nodes_ifaces [dict create]
	foreach node_id $nodes {
		if { [isPseudoNode $node_id] } {
			set nodes [removeFromList $nodes $node_id]
		}

		if { $all_ifaces == "*" } {
			dict set nodes_ifaces $node_id [ifcList $node_id]
		} else {
			dict set nodes_ifaces $node_id [dictGet $all_ifaces $node_id]
		}
	}

	if { $nodes == "" } {
		return
	}

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	set removed_addrs {}
	foreach node_id $nodes {
		if { [getNodeStatIPv4routes $node_id] != "" } {
			setNodeStatIPv4routes $node_id ""
		}

		set ifaces [dictGet $nodes_ifaces $node_id]
		if { $ifaces == "*" } {
			set ifaces [ifcList $node_id]
		}

		foreach iface_id $ifaces {
			set addrs [getIfcIPv4addrs $node_id $iface_id]
			if { $addrs == "" } {
				continue
			}

			set removed_addrs [concat $removed_addrs $addrs]
			setIfcIPv4addrs $node_id $iface_id ""
		}
	}

	setToRunning "ipv4_used_list" [removeFromList [getFromRunning "ipv4_used_list"] $removed_addrs "keep_doubles"]

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	redrawAll
	set changed 1
	updateUndoLog
}

#****f* editor.tcl/removeIPv6Nodes
# NAME
#   removeIPv6Nodes -- remove ipv6 nodes
# SYNOPSIS
#   removeIPv6Nodes
# FUNCTION
#   Sets all nodes' IPv6 addresses to empty strings.
#****
proc removeIPv6Nodes { nodes all_ifaces } {
	global changed

	if { $nodes == "*" } {
		set nodes [getFromRunning "node_list"]
	}

	set nodes_ifaces [dict create]
	foreach node_id $nodes {
		if { [isPseudoNode $node_id] } {
			set nodes [removeFromList $nodes $node_id]
		}

		if { $all_ifaces == "*" } {
			dict set nodes_ifaces $node_id [ifcList $node_id]
		} else {
			dict set nodes_ifaces $node_id [dictGet $all_ifaces $node_id]
		}
	}

	if { $nodes == "" } {
		return
	}

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	set removed_addrs {}
	foreach node_id $nodes {
		if { [getNodeStatIPv6routes $node_id] != "" } {
			setNodeStatIPv6routes $node_id ""
		}

		set ifaces [dictGet $nodes_ifaces $node_id]
		if { $ifaces == "*" } {
			set ifaces [ifcList $node_id]
		}

		foreach iface_id $ifaces {
			set addrs [getIfcIPv6addrs $node_id $iface_id]
			if { $addrs == "" } {
				continue
			}

			set removed_addrs [concat $removed_addrs $addrs]
			setIfcIPv6addrs $node_id $iface_id ""
		}
	}

	setToRunning "ipv6_used_list" [removeFromList [getFromRunning "ipv6_used_list"] $removed_addrs "keep_doubles"]

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	redrawAll
	set changed 1
	updateUndoLog
}

proc matchSubnet4 { node_id iface_id } {
	global changed

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	set tmp [getActiveOption "IPv4autoAssign"]
	setGlobalOption "IPv4autoAssign" 1
	autoIPv4addr $node_id $iface_id
	setGlobalOption "IPv4autoAssign" $tmp

	if { [getNodeAutoDefaultRoutesStatus $node_id] == "enabled" } {
		trigger_nodeReconfig $node_id
	}

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	redrawAll
	set changed 1
	updateUndoLog

	.panwin.f1.c config -cursor left_ptr
}

proc matchSubnet6 { node_id iface_id } {
	global changed

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	set tmp [getActiveOption "IPv6autoAssign"]
	setGlobalOption "IPv6autoAssign" 1
	autoIPv6addr $node_id $iface_id
	setGlobalOption "IPv6autoAssign" $tmp

	if { [getNodeAutoDefaultRoutesStatus $node_id] == "enabled" } {
		trigger_nodeReconfig $node_id
	}

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	redrawAll
	set changed 1
	updateUndoLog

	.panwin.f1.c config -cursor left_ptr
}

#****f* editor.tcl/changeAddressRange
# NAME
#   changeAddressRange -- change address range
# SYNOPSIS
#   changeAddressRange
# FUNCTION
#   Change address range for selected nodes.
#****
# TODO: merge this with auto default gateway procedures?
proc changeAddressRange {} {
	global changed change_subnet4 control
	global copypaste_nodes copypaste_list

	set control 0
	set autorenumber 1
	set change_subnet4 0

	if { $copypaste_nodes } {
		set selected_nodes $copypaste_list
		set copypaste_nodes 0
	} else {
		set selected_nodes [selectedNodes]
	}

	set link_nodes_selected ""
	set connected_link_layer_nodes ""
	set autorenumber_nodes ""

	# all L2 nodes are saved in link_nodes_selected list
	foreach node_id [lsort -dictionary $selected_nodes] {
		if { [invokeNodeProc $node_id "netlayer"] == "LINK" } {
			lappend link_nodes_selected $node_id
		}
	}

	# all L2 nodes from the same subnet are saved as one element of connected_link_layer_nodes list
	foreach link_node $link_nodes_selected {
		set lan_nodes [lsort -dictionary [listLANNodes $link_node {}]]
		if { [lsearch $connected_link_layer_nodes $lan_nodes] == -1 } {
			lappend connected_link_layer_nodes $lan_nodes
		}
	}

	global autorenumbered_ifcs
	set autorenumbered_ifcs ""

	# assign addresses to nodes connected to L2 nodes
	foreach element $connected_link_layer_nodes {
		set counter 0
		foreach node_id $element {
			set autorenumber_nodes ""
			foreach iface_id [ifcList $node_id] {
				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
				if { $peer_id != "" && [invokeNodeProc $peer_id "netlayer"] != "LINK" && $peer_id in $selected_nodes } {
					lappend autorenumber_nodes "$peer_id $peer_iface_id"
				}
			}

			foreach el $autorenumber_nodes {
				lassign $el node_id iface_id
				if { $counter == 0 } {
					set change_subnet4 1
				}

				autoIPv4addr $node_id $iface_id "use_autorenumbered"
				lappend autorenumbered_ifcs "$node_id $iface_id"
				incr counter
				set changed 1
				set change_subnet4 0
			}
		}
	}

	set autorenumber_nodes ""
	set autorenumber_ifcs ""

	# save nodes not connected to the L2 node in the autorenumber_nodes list
	foreach node_id $selected_nodes {
		if { [isPseudoNode $node_id] } {
			continue
		}

		if { [invokeNodeProc $node_id "netlayer"] != "LINK" } {
			foreach iface_id [ifcList $node_id] {
				lassign [logicalPeerByIfc $node_id $iface_id] peer_id -
				if { $peer_id != "" && [invokeNodeProc $peer_id "netlayer"] != "LINK" && $peer_id in $selected_nodes } {
					lappend autorenumber_ifcs "$node_id $iface_id"
					if { [lsearch $autorenumber_nodes $node_id] == -1 } {
						lappend autorenumber_nodes $node_id
					}
				}
			}
		}
	}

	# delete the existing IP addresses
	set removed_addrs {}
	foreach el $autorenumber_ifcs {
		lassign $el node_id iface_id
		set removed_addrs [concat $removed_addrs [getIfcIPv4addrs $node_id $iface_id]]
		setIfcIPv4addrs $node_id $iface_id ""
	}

	# assign IP addresses to interfaces not connected to L2 nodes
	foreach el $autorenumber_ifcs {
		lassign $el node_id iface_id
		lassign [logicalPeerByIfc $node_id $iface_id] peer_id -
		if { [lsearch $autorenumber_nodes $node_id] < [lsearch $autorenumber_nodes $peer_id] } {
			set change_subnet4 1
		}

		autoIPv4addr $node_id $iface_id "use_autorenumbered"
		set changed 1
		set change_subnet4 0
	}

	set autorenumber 0

	setToRunning "ipv4_used_list" [removeFromList [getFromRunning "ipv4_used_list"] $removed_addrs "keep_doubles"]

	redrawAll
	updateUndoLog
}

#****f* editor.tcl/changeAddressRange6
# NAME
#   changeAddressRange6 -- change address range (ipv6)
# SYNOPSIS
#   changeAddressRange6
# FUNCTION
#   Change IPv6 address range for selected nodes.
#****
# TODO: merge this with auto default gateway procedures?
proc changeAddressRange6 {} {
	global changed change_subnet6 control
	global copypaste_nodes copypaste_list

	set control 0
	set autorenumber 1
	set change_subnet6 0

	if { $copypaste_nodes } {
		set selected_nodes $copypaste_list
		set copypaste_nodes 0
	} else {
		set selected_nodes [selectedNodes]
	}

	set link_nodes_selected ""
	set connected_link_layer_nodes ""
	set autorenumber_nodes ""

	# all L2 nodes are saved in link_nodes_selected list
	foreach node_id [lsort -dictionary $selected_nodes] {
		if { [invokeNodeProc $node_id "netlayer"] == "LINK" } {
			lappend link_nodes_selected $node_id
		}
	}

	# all L2 nodes from the same subnet are saved as one element of connected_link_layer_nodes list
	foreach link_node $link_nodes_selected {
		set lan_nodes [lsort -dictionary [listLANNodes $link_node {}]]
		if { [lsearch $connected_link_layer_nodes $lan_nodes] == -1 } {
			lappend connected_link_layer_nodes $lan_nodes
		}
	}

	global autorenumbered_ifcs6
	set autorenumbered_ifcs6 ""

	# assign addresses to nodes connected to L2 nodes
	foreach element $connected_link_layer_nodes {
		set counter 0
		foreach node_id $element {
			set autorenumber_nodes ""
			foreach iface_id [ifcList $node_id] {
				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
				if { $peer_id != "" && [invokeNodeProc $peer_id "netlayer"] != "LINK" && $peer_id in $selected_nodes } {
					lappend autorenumber_nodes "$peer_id $peer_iface_id"
				}
			}

			foreach el $autorenumber_nodes {
				lassign $el node_id iface_id
				if { $counter == 0 } {
					set change_subnet6 1
				}

				autoIPv6addr $node_id $iface_id "use_autorenumbered"
				lappend autorenumbered_ifcs6 "$node_id $iface_id"

				incr counter
				set changed 1
				set change_subnet6 0
			}
		}
	}

	set autorenumber_nodes ""
	set autorenumber_ifcs ""

	# save nodes not connected to the L2 node in the autorenumber_nodes list
	foreach node_id $selected_nodes {
		if { [isPseudoNode $node_id] } {
			continue
		}

		if { [invokeNodeProc $node_id "netlayer"] != "LINK" } {
			foreach iface_id [ifcList $node_id] {
				lassign [logicalPeerByIfc $node_id $iface_id] peer_id -
				if { $peer_id != "" && [invokeNodeProc $peer_id "netlayer"] != "LINK" && $peer_id in $selected_nodes } {
					lappend autorenumber_ifcs "$node_id $iface_id"
					if { [lsearch $autorenumber_nodes $node_id] == -1 } {
						lappend autorenumber_nodes $node_id
					}
				}
			}
		}
	}

	# delete the existing IP addresses
	set removed_addrs {}
	foreach el $autorenumber_ifcs {
		lassign $el node_id iface_id
		set removed_addrs [concat $removed_addrs [getIfcIPv6addrs $node_id $iface_id]]
		setIfcIPv6addrs $node_id $iface_id ""
	}

	# assign IP addresses to interfaces not connected to L2 nodes
	foreach el $autorenumber_ifcs {
		lassign $el node_id iface_id
		lassign [logicalPeerByIfc $node_id $iface_id] peer_id -
		if { [lsearch $autorenumber_nodes $node_id] < [lsearch $autorenumber_nodes $peer_id] } {
			set change_subnet6 1
		}

		autoIPv6addr $node_id $iface_id "use_autorenumbered"
		set changed 1
		set change_subnet6 0
	}

	set autorenumber 0

	setToRunning "ipv6_used_list" [removeFromList [getFromRunning "ipv6_used_list"] $removed_addrs "keep_doubles"]

	redrawAll
	updateUndoLog
}

#****h* editor.tcl/double1onGrid
# NAME
#  double1onGrid.tcl -- called on Double-1 click on grid (bind command)
# SYNOPSIS
#  double1onGrid $c $x $y
# FUNCTION
#  As grid is layered above annotations this procedure is used to find
#  annotation object closest to cursor.
# INPUTS
#   * c -- tk canvas
#   * x -- double click x coordinate
#   * y -- double click y coordinate
#****
proc double1onGrid { c x y } {
	set tags [$c gettags [$c find closest $x $y]]
	if { [lsearch $tags grid] != -1 || [lsearch $tags background] != -1 } {
		return
	}

	set node_id [lindex $tags 1]
	# Is this really necessary?
	lassign [getAnnotationCoords $node_id] x1 y1 x2 y2
	if { $x < $x1 || $x > $x2 || $y < $y1 || $y > $y2 } {
		# cursor is not ON the closest object
		return
	}

	annotationConfig $c $node_id
}
