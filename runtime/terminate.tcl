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
# This work was supported in part by the Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

#****f* terminate.tcl/undeployCfg
# NAME
#   undeployCfg -- shutdown and destroy all nodes in experiment
# SYNOPSIS
#   undeployCfg
# FUNCTION
#   Undeploys a current working configuration. It terminates and unconfigures
#   all the nodes and links given in the "executeVars" set of variables:
#   terminate_nodes, destroy_nodes_ifaces, terminate_links,
#   unconfigure_links, unconfigure_nodes_ifaces, unconfigure_nodes
#****

proc checkTerminate {} {
}

proc undeployCfg { { eid "" } { terminate 0 } } {
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
	upvar 0 ::loop::state loop_state

	set loop_state "terminating"

	global progressbarCount execMode gui
	global isOSfreebsd
	global dict_loop

	set bkp_cfg ""
	set terminate_cfg [getFromExecuteVars "terminate_cfg"]
	if { ! $terminate } {
		if { ! [getFromRunning "cfg_deployed"] } {
			set loop_state "null"

			return
		}

		if { ! [getFromRunning "auto_execution"] } {
			if { $eid == "" } {
				set eid [getFromRunning "eid"]
			}

			createExperimentFiles $eid
			createRunningVarsFile $eid

			set loop_state "null"

			return
		}
	} else {
		if { $terminate_cfg != "" && $terminate_cfg != [cfgGet] } {
			setToExecuteVars "terminate_nodes" [dict keys [_cfgGet $terminate_cfg "nodes"]]
			setToExecuteVars "terminate_links" [dict keys [_cfgGet $terminate_cfg "links"]]
		}
	}

	set vars "terminate_nodes destroy_nodes_ifaces terminate_links \
		unconfigure_links unconfigure_nodes_ifaces unconfigure_nodes"
	foreach var $vars {
		set $var ""
	}

	prepareTerminateVars

	if { "$terminate_nodes$destroy_nodes_ifaces$terminate_links$unconfigure_links$unconfigure_nodes_ifaces$unconfigure_nodes" == "" } {
		if { $terminate_cfg != "" && $terminate_cfg != [cfgGet] } {
			if { $eid == "" } {
				set eid [getFromRunning "eid"]
			}

			createExperimentFiles $eid
			createRunningVarsFile $eid
		}
		setToExecuteVars "terminate_cfg" ""

		set loop_state "null"

		return
	}

	if { $terminate_cfg != "" && $terminate_cfg != [cfgGet] } {
		set bkp_cfg [cfgGet]
		set dict_cfg $terminate_cfg
	}

	set links_count [llength $terminate_links]

	set t_start [clock milliseconds]

	try {
		checkTerminate
	} on error err {
		statline "ERROR in 'checkTerminate': '$err'"
		if { $gui && $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				"$err \nCleanup the experiment and report the bug!" info 0 Dismiss
		}

		set loop_state "null"

		return
	}

	statline "Preparing for termination..."
	# TODO: fix this mess
	set native_nodes {}
	set virtualized_nodes {}
	set all_nodes {}
	foreach node_id $terminate_nodes {
		set node_type [getNodeType $node_id]
		if { $node_type == "" } {
			set terminate_nodes [removeFromList $terminate_nodes $node_id]
			set node_list [getFromRunning "node_list"]
			if { $node_id in $node_list } {
				setToRunning "node_list" [removeFromList $node_list $node_id]
			}

			continue
		}

		if { [invokeTypeProc $node_type "virtlayer"] == "NATIVE" } {
			if { $node_type == "ext" && [getNodeNATIface $node_id] != "UNASSIGNED" } {
				lappend virtualized_nodes $node_id
			} else {
				lappend native_nodes $node_id
			}
		} else {
			lappend virtualized_nodes $node_id
		}
	}
	set native_nodes_count [llength $native_nodes]
	set virtualized_nodes_count [llength $virtualized_nodes]
	set all_nodes [concat $native_nodes $virtualized_nodes]
	set all_nodes_count [llength $all_nodes]

	if { $destroy_nodes_ifaces == "*" } {
		set destroy_nodes_ifaces [dict create]
		foreach node_id $all_nodes {
			dict set destroy_nodes_ifaces $node_id "*"
		}
		set destroy_nodes_ifaces_count $all_nodes_count
	} else {
		set destroy_nodes_ifaces_count [llength [dict keys $destroy_nodes_ifaces]]
	}

	if { $isOSfreebsd } {
		dict for {node_id ifaces} $destroy_nodes_ifaces {
			if {
				$node_id in $terminate_nodes &&
				[invokeNodeProc $node_id "virtlayer"] == "VIRTUALIZED"
			} {
				dict unset destroy_nodes_ifaces $node_id
				incr destroy_nodes_ifaces_count -1
			}
		}
	}

	if { $unconfigure_nodes_ifaces == "*" } {
		set unconfigure_nodes_ifaces ""
		foreach node_id $all_nodes {
			dict set unconfigure_nodes_ifaces $node_id "*"
		}
		set unconfigure_nodes_ifaces_count $all_nodes_count
	} else {
		set unconfigure_nodes_ifaces_count [llength [dict keys $unconfigure_nodes_ifaces]]
	}

	if { $unconfigure_nodes == "*" } {
		set unconfigure_nodes $all_nodes
	}
	set unconfigure_nodes_count [llength $unconfigure_nodes]

	if { $unconfigure_links == "*" } {
		set unconfigure_links $terminate_links
	}

	# skip unconfiguring links that are going to be destroyed
	set unconfigure_links [removeFromList $unconfigure_links $terminate_links]

	set unconfigure_links_count [llength $unconfigure_links]

	set maxProgressbasCount [expr {1 + 2*$all_nodes_count + 2*$links_count + 1*$unconfigure_links_count + 4*$native_nodes_count + 5*$virtualized_nodes_count + 4*$unconfigure_nodes_ifaces_count + 4*$destroy_nodes_ifaces_count + 2*$unconfigure_nodes_count}]
	set progressbarCount $maxProgressbasCount

	if { $eid == "" } {
		set eid [getFromRunning "eid"]
	}

	set w ""
	if { $gui && $execMode != "batch" } {
		set w .startup
		catch { destroy $w }

		toplevel $w -takefocus 1
		wm transient $w .
		wm title $w "Terminating experiment $eid..."
		message $w.msg -justify left -aspect 1200 \
			-text "Deleting virtual nodes and links."
		pack $w.msg
		update

		ttk::progressbar $w.p -orient horizontal -length 250 \
			-mode determinate -maximum $maxProgressbasCount -value $progressbarCount
		pack $w.p
		update

		grab $w
	}

	set all_dict [dict create]
	dict set all_dict "t_start" $t_start
	dict set all_dict "terminate" $terminate
	dict set all_dict "bkp_cfg" $bkp_cfg
	dict set all_dict "virtualized_nodes" $virtualized_nodes
	dict set all_dict "virtualized_nodes_count" $virtualized_nodes_count
	dict set all_dict "all_nodes" $all_nodes
	dict set all_dict "all_nodes_count" $all_nodes_count
	dict set all_dict "native_nodes" $native_nodes
	dict set all_dict "native_nodes_count" $native_nodes_count
	dict set all_dict "unconfigure_nodes" $unconfigure_nodes
	dict set all_dict "unconfigure_nodes_count" $unconfigure_nodes_count
	dict set all_dict "destroy_nodes_ifaces" $destroy_nodes_ifaces
	dict set all_dict "destroy_nodes_ifaces_count" $destroy_nodes_ifaces_count
	dict set all_dict "unconfigure_nodes_ifaces" $unconfigure_nodes_ifaces
	dict set all_dict "unconfigure_nodes_ifaces_count" $unconfigure_nodes_ifaces_count
	dict set all_dict "terminate_links" $terminate_links
	dict set all_dict "links_count" $links_count
	dict set all_dict "unconfigure_links" $unconfigure_links
	dict set all_dict "unconfigure_links_count" $unconfigure_links_count

	# step1  -> terminate_nodesUnconfigure
	# step2  -> terminate_nodesShutdown
	# step3  -> terminate_linksUnconfigure
	# step4  -> terminate_linksDestroy
	# step5  -> terminate_nodesLogIfacesUnconfigure
	# step6  -> terminate_nodesLogIfacesDestroy
	# step7  -> terminate_nodesPhysIfacesDestroy
	# step8  -> terminate_nodesDestroyNative
	# step9  -> terminate_nodesDestroyNativeFS
	# step10 -> terminate_nodesDestroyVirtualized
	# step11 -> terminate_nodesDestroyVirtualizedFS
	# if terminate
	# step12 -> terminate_removeExperimentContainer
	# step13 -> terminate_removeExperimentFiles
	# step14 -> terminate_deleteRuntimeFiles

	terminate_nodesUnconfigure $all_dict $eid $w
}

proc terminate_nodesUnconfigure { all_dict eid w } {
	global progressbarCount execMode gui

	set unconfigure_nodes [dictGet $all_dict "unconfigure_nodes"]
	set unconfigure_nodes_count [dictGet $all_dict "unconfigure_nodes_count"]

	statline "Stopping services for NODESTOP hook..."
	if { $unconfigure_nodes_count > 0 } {
		services stop "NODESTOP" "" $unconfigure_nodes
	}

	statline "Unconfiguring nodes..."
	if { $unconfigure_nodes_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach node_id $unconfigure_nodes {
			displayBatchProgress $batchStep $unconfigure_nodes_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} {
				set msg "Unconfiguring"
				try {
					invokeNodeProc $node_id "nodeUnconfigure" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeUnconfigure $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				$w.p configure -value $progressbarCount
				statline "$msg node [getNodeName $node_id]"
				update
			}
		}

		displayBatchProgress $batchStep $unconfigure_nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for unconfiguration of $unconfigure_nodes_count node(s)..."

		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodeconf_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_links_left -1
	terminate_nodesUnconfigure_wait $all_dict $eid $unconfigure_nodes $unconfigure_nodes_count $unconfigure_nodes $w \
		$t_start $timeout $batchStep $old_links_left
}

proc terminate_nodesUnconfigure_wait { all_dict eid nodes nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode gui

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "node_unconfiguring" in [getStateNode $node_id] } {
				set node_unconfigured [invokeNodeProc $node_id "nodeUnconfigure_check" $eid $node_id]
				if { ! $node_unconfigured } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "node_unconfiguring"
				set msg "unconfigured"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesUnconfigure_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesShutdown $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesUnconfigure_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesUnconfigure_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesShutdown $all_dict $eid $w

	return "done"
}

proc terminate_nodesShutdown { all_dict eid w } {
	global progressbarCount execMode gui

	set all_nodes [dictGet $all_dict "all_nodes"]
	set all_nodes_count [dictGet $all_dict "all_nodes_count"]

	statline "Stopping nodes..."
	if { $all_nodes_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach node_id $all_nodes {
			displayBatchProgress $batchStep $all_nodes_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} {
				set msg "Shutting down"
				try {
					invokeNodeProc $node_id "nodeShutdown" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeShutdown $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg node [getNodeName $node_id]"
				$w.p configure -value $progressbarCount
				update
			}
		}

		displayBatchProgress $batchStep $all_nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for processes on $all_nodes_count node(s) to shutdown..."

		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodeconf_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_links_left -1
	terminate_nodesShutdown_wait $all_dict $eid $all_nodes $all_nodes_count $all_nodes $w \
		$t_start $timeout $batchStep $old_links_left
}

proc terminate_nodesShutdown_wait { all_dict eid nodes nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode gui

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "node_shutting" in [getStateNode $node_id] } {
				set node_stopped [invokeNodeProc $node_id "nodeShutdown_check" $eid $node_id]
				if { ! $node_stopped } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "node_shutting"
				set msg "stopped"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesShutdown_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_linksUnconfigure $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesShutdown_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesShutdown_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_linksUnconfigure $all_dict $eid $w

	return "done"
}

proc terminate_linksUnconfigure { all_dict eid w } {
	global progressbarCount execMode gui

	set unconfigure_nodes [dictGet $all_dict "unconfigure_nodes"]
	set unconfigure_nodes_count [dictGet $all_dict "unconfigure_nodes_count"]

	statline "Stopping services for LINKDEST hook..."
	if { $unconfigure_nodes_count > 0 } {
		services stop "LINKDEST" "" $unconfigure_nodes
	}

	set unconfigure_links [dictGet $all_dict "unconfigure_links"]
	set unconfigure_links_count [dictGet $all_dict "unconfigure_links_count"]

	statline "Unconfiguring links..."
	if { $unconfigure_links_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach link_id $unconfigure_links {
			displayBatchProgress $batchStep $unconfigure_links_count

			lassign [getLinkPeers $link_id] node1_id node2_id
			lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

			if {
				! [isRunningLink $link_id] ||
				! [isRunningNodeIface $node1_id $iface1_id] ||
				! [isRunningNodeIface $node2_id $iface2_id]
			} {
				set msg "Skipping"
			} else {
				set msg "Unconfiguring"
				try {
					unconfigureLinkBetween $eid $node1_id $node2_id $iface1_id $iface2_id $link_id
				} on error err {
					return -code error "Error in 'unconfigureLinkBetween $eid $node1_id $node2_id $iface1_id $iface2_id $link_id': $err"
				}
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg link $link_id"
				$w.p configure -value $progressbarCount
				update
			}
		}
		pipesExec ""

		displayBatchProgress $batchStep $unconfigure_links_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for $unconfigure_links_count link(s) to be unconfigured..."

		pipesClose
	}

	# TODO: not used
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_links_left -1
	terminate_linksUnconfigure_wait $all_dict $eid $unconfigure_links $unconfigure_links_count $unconfigure_links $w \
		$t_start $timeout $batchStep $old_links_left
}

proc terminate_linksUnconfigure_wait { all_dict eid links links_count links_left w t_start timeout batchStep old_links_left } {
	terminate_linksDestroy $all_dict $eid $w
}

proc terminate_linksDestroy { all_dict eid w } {
	global progressbarCount execMode gui

	set terminate_links [dictGet $all_dict "terminate_links"]
	set links_count [dictGet $all_dict "links_count"]

	statline "Destroying links..."
	if { $links_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach link_id $terminate_links {
			displayBatchProgress $batchStep $links_count

			if { ! [isRunningLink $link_id] } {
				set msg "Skipping"
			} else {
				set msg "Destroying"
				lassign [getLinkPeers $link_id] node1_id node2_id
				lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

				try {
					destroyLinkBetween $eid $node1_id $node2_id $iface1_id $iface2_id $link_id
				} on error err {
					return -code error "Error in 'destroyLinkBetween $eid $node1_id $node2_id $iface1_id $iface2_id $link_id': $err"
				}
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg link $link_id"
				$w.p configure -value $progressbarCount
				update
			}
		}
		pipesExec ""

		if { $links_count > 0 } {
			displayBatchProgress $batchStep $links_count
			if { ! $gui || $execMode == "batch" } {
				statline ""
			}
		}
		statline "Waiting for $links_count link(s) to be destroyed..."

		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_links_left -1
	terminate_linksDestroy_wait $all_dict $eid $terminate_links $links_count $terminate_links $w \
		$t_start $timeout $batchStep $old_links_left
}

proc isLinkDestroyed { eid link_id } {
	global isOSlinux isOSfreebsd

	set timeout [getTimeout "nodecreate_timeout"]

	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
	if {
		([getFromRunning "${link_id}_destroy_type"] ||
		"wlan" in "[getNodeType $node1_id] [getNodeType $node2_id]")
	} {
		# TODO
		removeStateLink $link_id "error destroying running"

		return true
	}

	if { $isOSlinux } {
		set cmds "ip -n $eid link show $link_id"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $eid ngctl show $link_id:"
	}

	if { $timeout >= 0 } {
		set cmds "timeout [expr $timeout/5.0] $cmds"
	}

	set destroyed [isNotOk $cmds]
	if { $destroyed } {
		removeStateLink $link_id "error destroying running"
	} else {
		addStateLink $link_id "error"
	}

	return $destroyed
}

proc terminate_linksDestroy_wait { all_dict eid links links_count links_left w t_start timeout batchStep old_links_left } {
	global progressbarCount execMode gui

	if { [llength $links_left] > 0 } {
		displayBatchProgress $batchStep $links_count
		foreach link_id $links_left {
			if { "destroying" in [getStateLink $link_id] } {
				if { ! [isLinkDestroyed $eid $link_id] } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateLink $link_id "destroying"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "Link $link_id $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $links_count

			set links_left [removeFromList $links_left $link_id]
		}

		if { $old_links_left != [llength $links_left] } {
			if { $links_left != {} } {
				set old_links_left [llength $links_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_linksDestroy_wait $all_dict $eid $links $links_count $links_left $w \
					$t_start $timeout $batchStep $old_links_left]

				return "again"
			} else {
				terminate_nodesLogIfacesUnconfigure $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_linksDestroy_wait $all_dict $eid $links $links_count $links_left $w \
				$t_start $timeout $batchStep $old_links_left]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $links_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set links [removeFromList $links $links_left]
			set links_left $links
		} elseif { $links != {} } {
			after 100 [list terminate_linksDestroy_wait $all_dict $eid $links $links_count $links_left $w \
				$t_start $timeout $batchStep $old_links_left]

			return "not done"
		}
	}

	if { $links_count > 0 } {
		displayBatchProgress $batchStep $links_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesLogIfacesUnconfigure $all_dict $eid $w

	return "done"
}

proc terminate_nodesLogIfacesUnconfigure { all_dict eid w } {
	global progressbarCount execMode gui

	set unconfigure_nodes_ifaces [dictGet $all_dict "unconfigure_nodes_ifaces"]
	set unconfigure_nodes_ifaces_count [dictGet $all_dict "unconfigure_nodes_ifaces_count"]

	statline "Unconfiguring logical interfaces on nodes..."
	if { $unconfigure_nodes_ifaces_count > 0 } {
		set batchStep 0

		pipesCreate
		dict for {node_id ifaces} $unconfigure_nodes_ifaces {
			displayBatchProgress $batchStep $unconfigure_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} {
				if { $ifaces == "*" } {
					set ifaces [logIfcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [ifcList $node_id]]
				}

				if { $ifaces != {} } {
					try {
						invokeNodeProc $node_id "nodeIfacesUnconfigure" $eid $node_id $ifaces
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodeIfacesUnconfigure $eid $node_id $ifaces': $err"
					}

					pipesExec ""

					set msg "Unconfiguring"
				} else {
					set msg "No available"
				}
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				$w.p configure -value $progressbarCount
				statline "$msg logical interfaces on node [getNodeName $node_id]"
				update
			}
		}

		displayBatchProgress $batchStep $unconfigure_nodes_ifaces_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for logical interfaces on $unconfigure_nodes_ifaces_count node(s) to be unconfigured..."
		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	set batchStep 0
	set nodes_left [dict keys $unconfigure_nodes_ifaces]
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesLogIfacesUnconfigure_wait $all_dict $eid $unconfigure_nodes_ifaces $unconfigure_nodes_ifaces_count $nodes_left \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesLogIfacesUnconfigure_wait { all_dict eid nodes_ifaces nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode err_skip_nodesifaces gui

	set nodes [dict keys $nodes_ifaces]

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "ifaces_unconfiguring" in [getStateNode $node_id] } {
				set ifaces [dict get $nodes_ifaces $node_id]
				if { $ifaces == "*" } {
					set ifaces [logIfcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [ifcList $node_id]]
				}

				set node_ifaces_unconfigured [invokeNodeProc $node_id "nodeIfacesUnconfigure_check" $eid $node_id $ifaces]
				if { ! $node_ifaces_unconfigured } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "ifaces_unconfiguring"
				set msg "unconfigured"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name logical ifaces $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesLogIfacesUnconfigure_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesLogIfacesDestroy $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesLogIfacesUnconfigure_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set err_skip_nodesifaces $nodes_left
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesLogIfacesUnconfigure_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesLogIfacesDestroy $all_dict $eid $w

	return "done"
}

proc terminate_nodesLogIfacesDestroy { all_dict eid w } {
	global progressbarCount execMode gui

	set destroy_nodes_ifaces [dictGet $all_dict "destroy_nodes_ifaces"]
	set destroy_nodes_ifaces_count [dictGet $all_dict "destroy_nodes_ifaces_count"]

	statline "Destroying logical interfaces on nodes..."
	if { $destroy_nodes_ifaces_count > 0 } {
		set batchStep 0

		pipesCreate
		dict for {node_id ifaces} $destroy_nodes_ifaces {
			displayBatchProgress $batchStep $destroy_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} {
				if { $ifaces == "*" } {
					set ifaces [logIfcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [ifcList $node_id]]
				}

				foreach iface_id $ifaces {
					set this_link_id [getIfcLink $node_id $iface_id]
					if {
						! [isRunningNodeIface $node_id $iface_id] ||
						"destroying" in [getStateNodeIface $node_id $iface_id]
					} {
						set ifaces [removeFromList $ifaces $iface_id]
					}
				}

				if { $ifaces != {} } {
					try {
						invokeNodeProc $node_id "nodeLogIfacesDestroy" $eid $node_id $ifaces
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodeLogIfacesDestroy $eid $node_id $ifaces': $err"
					}

					pipesExec ""

					set msg "Destroying"
				} else {
					set msg "No available"
				}
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg logical interfaces on node [getNodeName $node_id]"
				$w.p configure -value $progressbarCount
				update
			}
		}

		displayBatchProgress $batchStep $destroy_nodes_ifaces_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for logical interfaces on $destroy_nodes_ifaces_count node(s) to be destroyed..."
		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	set batchStep 0
	set nodes_left [dict keys $destroy_nodes_ifaces]
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesLogIfacesDestroy_wait $all_dict $eid $destroy_nodes_ifaces $destroy_nodes_ifaces_count $nodes_left  \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesLogIfacesDestroy_wait { all_dict eid nodes_ifaces nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode err_skip_nodesifaces gui

	set nodes [dict keys $nodes_ifaces]

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "lifaces_destroying" in [getStateNode $node_id] } {
				set ifaces [dict get $nodes_ifaces $node_id]
				if { $ifaces == "*" } {
					set ifaces [logIfcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [ifcList $node_id]]
				}

				set ifaces_destroyed [invokeNodeProc $node_id "nodeIfacesDestroy_check" $eid $node_id $ifaces]
				if { ! $ifaces_destroyed } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "lifaces_destroying"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name logical ifaces $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesLogIfacesDestroy_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesPhysIfacesUnconfigure $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesLogIfacesDestroy_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set err_skip_nodesifaces $nodes_left
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesLogIfacesDestroy_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesPhysIfacesUnconfigure $all_dict $eid $w

	return "done"
}

proc terminate_nodesPhysIfacesUnconfigure { all_dict eid w } {
	global progressbarCount execMode gui

	set unconfigure_nodes_ifaces [dictGet $all_dict "unconfigure_nodes_ifaces"]
	set unconfigure_nodes_ifaces_count [dictGet $all_dict "unconfigure_nodes_ifaces_count"]

	statline "Unconfiguring physical interfaces on nodes..."
	if { $unconfigure_nodes_ifaces_count > 0 } {
		set batchStep 0

		pipesCreate
		dict for {node_id ifaces} $unconfigure_nodes_ifaces {
			displayBatchProgress $batchStep $unconfigure_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} {
				if { $ifaces == "*" } {
					set ifaces [ifcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [logIfcList $node_id]]
				}

				if { $ifaces != {} } {
					try {
						invokeNodeProc $node_id "nodeIfacesUnconfigure" $eid $node_id $ifaces
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodeIfacesUnconfigure $eid $node_id $ifaces': $err"
					}

					pipesExec ""

					set msg "Unconfiguring"
				} else {
					set msg "No available"
				}
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				$w.p configure -value $progressbarCount
				statline "$msg physical interfaces on node [getNodeName $node_id]"
				update
			}
		}

		displayBatchProgress $batchStep $unconfigure_nodes_ifaces_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for physical interfaces on $unconfigure_nodes_ifaces_count node(s) to be unconfigured..."
		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	set batchStep 0
	set nodes_left [dict keys $unconfigure_nodes_ifaces]
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesPhysIfacesUnconfigure_wait $all_dict $eid $unconfigure_nodes_ifaces $unconfigure_nodes_ifaces_count $nodes_left  \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesPhysIfacesUnconfigure_wait { all_dict eid nodes_ifaces nodes_count nodes_left w t_start timeout batchStep old_left_count} {
	global progressbarCount execMode err_skip_nodesifaces gui

	set nodes [dict keys $nodes_ifaces]

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "ifaces_unconfiguring" in [getStateNode $node_id] } {
				set ifaces [dict get $nodes_ifaces $node_id]
				if { $ifaces == "*" } {
					set ifaces [ifcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [logIfcList $node_id]]
				}

				set node_ifaces_unconfigured [invokeNodeProc $node_id "nodeIfacesUnconfigure_check" $eid $node_id $ifaces]
				if { ! $node_ifaces_unconfigured } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "ifaces_unconfiguring"
				set msg "unconfigured"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name physical ifaces $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesPhysIfacesUnconfigure_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesPhysIfacesDestroy $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesPhysIfacesUnconfigure_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set err_skip_nodesifaces $nodes_left
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesPhysIfacesUnconfigure_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesPhysIfacesDestroy $all_dict $eid $w

	return "done"
}

proc terminate_nodesPhysIfacesDestroy { all_dict eid w } {
	global progressbarCount execMode gui

	set destroy_nodes_ifaces [dictGet $all_dict "destroy_nodes_ifaces"]
	set destroy_nodes_ifaces_count [dictGet $all_dict "destroy_nodes_ifaces_count"]

	statline "Destroying physical interfaces on nodes..."
	if { $destroy_nodes_ifaces_count > 0 } {
		set batchStep 0

		pipesCreate
		dict for {node_id ifaces} $destroy_nodes_ifaces {
			displayBatchProgress $batchStep $destroy_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} {
				if { $ifaces == "*" } {
					set ifaces [ifcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [logIfcList $node_id]]
				}

				set ifaces_direct {}

				# skip 'direct link' and UNASSIGNED stolen interfaces
				foreach iface_id $ifaces {
					if {
						! [isRunningNodeIface $node_id $iface_id] ||
						"destroying" in [getStateNodeIface $node_id $iface_id] ||
						([getIfcType $node_id $iface_id] == "stolen" &&
						[getFromRunning "${node_id}|${iface_id}_active_name"] == "")
					} {
						set ifaces [removeFromList $ifaces $iface_id]

						continue
					}

					set this_link_id [getIfcLink $node_id $iface_id]
					if { $this_link_id != "" && [getFromRunning "${this_link_id}_destroy_type"] } {
						lappend ifaces_direct $iface_id
					}
				}

				set ifaces [removeFromList $ifaces $ifaces_direct]

				if { $ifaces != {} } {
					try {
						invokeNodeProc $node_id "nodePhysIfacesDestroy" $eid $node_id $ifaces
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodePhysIfacesDestroy $eid $node_id $ifaces': $err"
					}
				}

				if { $ifaces_direct != {} } {
					try {
						invokeNodeProc $node_id "nodePhysIfacesDirectDestroy" $eid $node_id $ifaces_direct
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodePhysIfacesDirectDestroy $eid $node_id $ifaces_direct': $err"
					}
				}

				if { $ifaces != {} || $ifaces_direct != {} } {
					pipesExec ""

					set msg "Destroying"
				} else {
					set msg "No available"
				}
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg physical interfaces on node [getNodeName $node_id]"
				$w.p configure -value $progressbarCount
				update
			}
		}

		displayBatchProgress $batchStep $destroy_nodes_ifaces_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for physical interfaces on $destroy_nodes_ifaces_count node(s) to be destroyed..."
		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	set batchStep 0
	set nodes_left [dict keys $destroy_nodes_ifaces]
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesPhysIfacesDestroy_wait $all_dict $eid $destroy_nodes_ifaces $destroy_nodes_ifaces_count $nodes_left \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesPhysIfacesDestroy_wait { all_dict eid nodes_ifaces nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode err_skip_nodesifaces gui

	set nodes [dict keys $nodes_ifaces]

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "pifaces_destroying" in [getStateNode $node_id] } {
				set ifaces [dict get $nodes_ifaces $node_id]
				if { $ifaces == "*" } {
					set ifaces [ifcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [logIfcList $node_id]]
				}

				set ifaces_destroyed [invokeNodeProc $node_id "nodeIfacesDestroy_check" $eid $node_id $ifaces]
				if { ! $ifaces_destroyed } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "pifaces_destroying"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name physical ifaces $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]
				after 100 [list terminate_nodesPhysIfacesDestroy_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesDestroyNative $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesPhysIfacesDestroy_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesPhysIfacesDestroy_wait $all_dict $eid $nodes_ifaces $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesDestroyNative $all_dict $eid $w

	return "done"
}

proc timeoutPatch { eid nodes nodes_count w } {
	global progressbarCount execMode gui

	set batchStep 0
	set nodes_left $nodes
	while { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { ! [isRunningNode $node_id] } {
				set msg "skipped"
			} else {
				checkHangingTCPs $eid $node_id

				set msg "TCP stopped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}
}

proc terminate_nodesDestroyNative { all_dict eid w } {
	global progressbarCount execMode gui

	set native_nodes [dictGet $all_dict "native_nodes"]
	set native_nodes_count [dictGet $all_dict "native_nodes_count"]

	statline "Destroying NATIVE nodes..."
	if { $native_nodes_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach node_id $native_nodes {
			displayBatchProgress $batchStep $native_nodes_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Destroying"
				try {
					invokeNodeProc $node_id "nodeDestroy" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeDestroy $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg node [getNodeName $node_id]"
				$w.p configure -value $progressbarCount
				update
			}
		}

		displayBatchProgress $batchStep $native_nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for $native_nodes_count NATIVE node(s) to be destroyed..."
		pipesClose
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesDestroyNative_wait $all_dict $eid $native_nodes $native_nodes_count $native_nodes \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesDestroyNative_wait { all_dict eid nodes nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode gui

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "node_destroying" in [getStateNode $node_id] } {
				set node_destroyed [invokeNodeProc $node_id "nodeDestroy_check" $eid $node_id]
				if { ! $node_destroyed } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "node_destroying"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesDestroyNative_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesDestroyNativeFS $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesDestroyNative_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesDestroyNative_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesDestroyNativeFS $all_dict $eid $w

	return "done"
}

proc terminate_nodesDestroyNativeFS { all_dict eid w } {
	global progressbarCount execMode gui

	set native_nodes [dictGet $all_dict "native_nodes"]
	set native_nodes_count [dictGet $all_dict "native_nodes_count"]

	# Keep this because we mark nodes as non-running here
	statline "Destroying NATIVE nodes (FS)..."
	if { $native_nodes_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach node_id $native_nodes {
			displayBatchProgress $batchStep $native_nodes_count

			if {
				! [isRunningNode $node_id] ||
				[isErrorNode $node_id]
			} {
				set msg "Skipping"
			} else {
				set msg "Destroying"
				try {
					invokeNodeProc $node_id "nodeDestroyFS" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeDestroyFS $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg node [getNodeName $node_id] (FS)"
				$w.p configure -value $progressbarCount
				update
			}
		}
		pipesClose

		displayBatchProgress $batchStep $native_nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for $native_nodes_count NATIVE node(s) to be destroyed (FS)..."
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesDestroyNativeFS_wait $all_dict $eid $native_nodes $native_nodes_count $native_nodes \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesDestroyNativeFS_wait { all_dict eid nodes nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode gui

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "node_destroying_fs" in [getStateNode $node_id] } {
				set node_destroyed_fs [invokeNodeProc $node_id "nodeDestroyFS_check" $eid $node_id]
				if { ! $node_destroyed_fs } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "node_destroying_fs"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg (FS)"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesDestroyNativeFS_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesDestroyVirtualized $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesDestroyNativeFS_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesDestroyNativeFS_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesDestroyVirtualized $all_dict $eid $w

	return "done"
}

proc terminate_nodesDestroyVirtualized { all_dict eid w } {
	global progressbarCount execMode gui

	set virtualized_nodes [dictGet $all_dict "virtualized_nodes"]
	set virtualized_nodes_count [dictGet $all_dict "virtualized_nodes_count"]

	statline "Checking for hanging TCP connections on VIRTUALIZED node(s)..."
	if { $virtualized_nodes_count > 0 } {
		#pipesCreate
		timeoutPatch $eid $virtualized_nodes $virtualized_nodes_count $w
		statline "Waiting for hanging TCP connections on $virtualized_nodes_count VIRTUALIZED node(s)..."
		#pipesClose
	}

	statline "Stopping services for NODEDEST hook..."
	if { $virtualized_nodes_count > 0 } {
		services stop "NODEDEST" "" $virtualized_nodes
	}

	statline "Destroying VIRTUALIZED nodes..."
	if { $virtualized_nodes_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach node_id $virtualized_nodes {
			displayBatchProgress $batchStep $virtualized_nodes_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Destroying"
				try {
					invokeNodeProc $node_id "nodeDestroy" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeDestroy $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg node [getNodeName $node_id]"
				$w.p configure -value $progressbarCount
				update
			}
		}
		pipesClose

		displayBatchProgress $batchStep $virtualized_nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}

		statline "Waiting for $virtualized_nodes_count VIRTUALIZED node(s) to be destroyed..."
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesDestroyVirtualized_wait $all_dict $eid $virtualized_nodes $virtualized_nodes_count $virtualized_nodes \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesDestroyVirtualized_wait { all_dict eid nodes nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode gui

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "node_destroying" in [getStateNode $node_id] } {
				set node_destroyed [invokeNodeProc $node_id "nodeDestroy_check" $eid $node_id]
				if { ! $node_destroyed } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "node_destroying"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesDestroyVirtualized_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				terminate_nodesDestroyVirtualizedFS $all_dict $eid $w

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesDestroyVirtualized_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesDestroyVirtualized_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	terminate_nodesDestroyVirtualizedFS $all_dict $eid $w

	return "done"
}

proc terminate_nodesDestroyVirtualizedFS { all_dict eid w } {
	global progressbarCount execMode gui

	set virtualized_nodes [dictGet $all_dict "virtualized_nodes"]
	set virtualized_nodes_count [dictGet $all_dict "virtualized_nodes_count"]

	statline "Destroying VIRTUALIZED nodes (FS)..."
	if { $virtualized_nodes_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach node_id $virtualized_nodes {
			displayBatchProgress $batchStep $virtualized_nodes_count

			if {
				! [isRunningNode $node_id] ||
				[isErrorNode $node_id]
			} {
				set msg "Skipping"
			} else {
				set msg "Destroying"
				try {
					invokeNodeProc $node_id "nodeDestroyFS" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeDestroyFS $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep
			incr progressbarCount -1

			if { $gui && $execMode != "batch" } {
				statline "$msg node [getNodeName $node_id] (FS)"
				$w.p configure -value $progressbarCount
				update
			}
		}
		pipesClose
		statline "Waiting for $virtualized_nodes_count VIRTUALIZED node(s) to be destroyed (FS)..."

		displayBatchProgress $batchStep $virtualized_nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	set batchStep 0
	# ignore first run when checking for timeout
	set old_left_count -1
	terminate_nodesDestroyVirtualizedFS_wait $all_dict $eid $virtualized_nodes $virtualized_nodes_count $virtualized_nodes \
		$w $t_start $timeout $batchStep $old_left_count
}

proc terminate_nodesDestroyVirtualizedFS_wait { all_dict eid nodes nodes_count nodes_left w t_start timeout batchStep old_left_count } {
	global progressbarCount execMode gui

	set terminate [dictGet $all_dict "terminate"]

	if { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { "node_destroying_fs" in [getStateNode $node_id] } {
				set node_destroyed_fs [invokeNodeProc $node_id "nodeDestroyFS_check" $eid $node_id]
				if { ! $node_destroyed_fs } {
					if { $timeout < 0 } {
						after [expr -$timeout]
					}
					update
					continue
				}

				removeStateNode $node_id "node_destroying_fs"
				set msg "destroyed"
			} else {
				set msg "skipped"
			}

			incr batchStep
			incr progressbarCount -1

			set name [getNodeName $node_id]
			if { $gui && $execMode != "batch" } {
				statline "Node $name $msg (FS)"
				$w.p configure -value $progressbarCount
				update
			}
			displayBatchProgress $batchStep $nodes_count

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			if { $nodes_left != {} } {
				set old_left_count [llength $nodes_left]
				set t_start [clock milliseconds]

				after 100 [list terminate_nodesDestroyVirtualizedFS_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
					$t_start $timeout $batchStep $old_left_count]

				return "again"
			} else {
				if { $terminate } {
					terminate_removeExperimentContainer $all_dict $eid $w
				} else {
					terminate_finishTermination $all_dict $eid $w
				}

				return "done"
			}
		}

		if { $timeout < 0 } {
			after 100 [list terminate_nodesDestroyVirtualizedFS_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "again"
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			set nodes [removeFromList $nodes $nodes_left]
			set nodes_left $nodes
		} elseif { $nodes != {} } {
			after 100 [list terminate_nodesDestroyVirtualizedFS_wait $all_dict $eid $nodes $nodes_count $nodes_left $w \
				$t_start $timeout $batchStep $old_left_count]

			return "not done"
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count
		if { ! $gui || $execMode == "batch" } {
			statline ""
		}
	}

	if { $terminate } {
		terminate_removeExperimentContainer $all_dict $eid $w
	} else {
		terminate_finishTermination $all_dict $eid $w
	}

	return "done"
}

proc terminate_removeExperimentFiles_wait { all_dict eid w t_start timeout } {
	global gui execMode

	# NOTE: watch out for ZFS
	set dir_name "[getVrootDir]/$eid"

	if { [isOk test -d $dir_name] } {
		set t_last [clock milliseconds]
		if { [expr { ($t_last - $t_start) / 1000.0 }] <= $timeout } {
			after 100 [list terminate_removeExperimentFiles_wait $all_dict $eid $w $t_start $timeout]

			return "again"
		}

		set msg "Timeout encountered while removing experiment vroot files:\n\n"
		append msg "$dir_name\n\n"
		append msg "Delete the directory yourself before running the experiment again"

		if { $gui && $execMode != "batch" } {
			after idle {.dialog1.msg configure -wraplength 6i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}

	terminate_deleteRuntimeFiles $all_dict $eid $w

	return "done"
}

#****f* terminate.tcl/terminate_deleteRuntimeFiles
# NAME
#   terminate_deleteRuntimeFiles -- delete experiment files
# SYNOPSIS
#   terminate_deleteRuntimeFiles $eid
# FUNCTION
#   Deletes experiment files for the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc terminate_deleteRuntimeFiles { all_dict eid w } {
	global runtimeDir

	set dir_name "$runtimeDir/$eid"
	catch { rexec rm -rf $dir_name & }

	set t_start [clock milliseconds]
	set timeout 30
	terminate_deleteRuntimeFiles_wait $all_dict $eid \
		$w $t_start $timeout
}

proc terminate_deleteRuntimeFiles_wait { all_dict eid w t_start timeout } {
	global runtimeDir gui execMode

	set dir_name "$runtimeDir/$eid"

	if { [isOk test -d $dir_name] } {
		set t_last [clock milliseconds]
		if { [expr { ($t_last - $t_start) / 1000.0 }] <= $timeout } {
			after 100 [list terminate_deleteRuntimeFiles_wait $all_dict $eid $w $t_start $timeout]

			return "again"
		}

		set msg "Timeout encountered while deleting experiment runtime files:\n\n"
		append msg "$dir_name\n\n"
		append msg "Delete the directory yourself before running the experiment again"

		if { $gui && $execMode != "batch" } {
			after idle {.dialog1.msg configure -wraplength 6i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}

	# just deleting files without termination
	set terminate [dictGetWithDefault 0 $all_dict "terminate"]
	if { $terminate } {
		terminate_finishTermination $all_dict $eid $w
	}

	return "done"
}

proc terminate_finishTermination { all_dict eid w } {
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

	global gui execMode

	set t_start [dictGet $all_dict "t_start"]
	set terminate [dictGet $all_dict "terminate"]
	set bkp_cfg [dictGet $all_dict "bkp_cfg"]

	finishTerminating 1 "" $w

	if { $bkp_cfg != "" } {
		set dict_cfg $bkp_cfg
	}

	if { ! $terminate } {
		if { [getFromRunning "auto_execution"] } {
			createExperimentFiles $eid
		}
		createRunningVarsFile $eid
	}

	statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."

	if { $bkp_cfg != "" } {
		setToExecuteVars "terminate_cfg" ""
	}

	if { ! $gui || $execMode == "batch" } {
		sputs "Terminated experiment ID = $eid"
	}

	set execMode $execMode
}

proc finishTerminating { status msg w } {
	upvar 0 ::loop::state loop_state

	global progressbarCount execMode gui
	global dict_loop

	set vars "terminate_nodes destroy_nodes_ifaces terminate_links \
		unconfigure_links unconfigure_nodes_ifaces unconfigure_nodes"
	foreach var $vars {
		setToExecuteVars "$var" ""
	}

	catch { pipesClose }
	if { ! $gui || $execMode == "batch" } {
		sputs stderr $msg
	} else {
		catch { destroy $w }
		set progressbarCount 0
		if { ! $status } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				"$msg \nCleanup the experiment and report the bug!" info 0 Dismiss
		}

		redrawAll
	}

	set loop_state "null"
}
