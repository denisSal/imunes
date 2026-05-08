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

proc isLinkUnconfigured { eid link_id } {
	# TODO: check link unconfiguration
	removeStateLink $link_id "error unconfiguring"

	return true
}

global terminate_steps
set terminate_steps [dict create]

dict set terminate_steps "terminate_nodesUnconfigure" {
	"current_step"		{terminate_nodesUnconfigure}
	"elem_type"			{nodes}
	"elem_name"			{unconfigure_nodes}
	"elem_count_name"	{unconfigure_nodes_count}
	"start_msg"			{Unconfiguring nodes...}
	"skip_condition"	{ ! [isRunningNode $elem] }
	"success_msg"		{Unconfiguring}
	"run_proc"			{invokeNodeProc $elem "nodeUnconfigure" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem]}
	"end_msg"			{Waiting for unconfiguration of $elems_count node(s)...}
	"timeout_type"		{nodeconf_timeout}
	"condition_name"	{node_unconfiguring}
	"check_proc"		{invokeNodeProc $elem "nodeUnconfigure_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] unconfiguration %msg}
	"next_step"			{terminate_nodesShutdown}
}

dict set terminate_steps "terminate_nodesShutdown" {
	"current_step"		{terminate_nodesShutdown}
	"elem_type"			{nodes}
	"elem_name"			{all_nodes}
	"elem_count_name"	{all_nodes_count}
	"start_msg"			{Stopping nodes...}
	"skip_condition"	{ ! [isRunningNode $elem] }
	"success_msg"		{Shutting down}
	"run_proc"			{invokeNodeProc $elem "nodeShutdown" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem]}
	"end_msg"			{Waiting for processes on $elems_count node(s) to shutdown...}
	"timeout_type"		{nodeconf_timeout}
	"condition_name"	{node_shutting}
	"check_proc"		{invokeNodeProc $elem "nodeShutdown_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] shutdown %msg}
	"next_step"			{terminate_linksUnconfigure}
}

dict set terminate_steps "terminate_linksUnconfigure" {
	"current_step"		{terminate_linksUnconfigure}
	"elem_type"			{links}
	"elem_name"			{unconfigure_links}
	"elem_count_name"	{unconfigure_links_count}
	"start_msg"			{Unconfiguring links...}
	"skip_condition"	{ ! [isRunningLink $elem] || ! [isRunningNodeIface $node1_id $iface1_id] || ! [isRunningNodeIface $node2_id $iface2_id] }
	"success_msg"		{Unconfiguring}
	"run_proc"			{unconfigureLinkBetween $eid $node1_id $node2_id $iface1_id $iface2_id $elem}
	"msg_template"		{%msg link $elem}
	"end_msg"			{Waiting for $elems_count link(s) to be unconfigured...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{unconfiguring}
	"check_proc"		{isLinkUnconfigured $eid $elem}
	"done_msg_template"	{Link $elem unconfiguration %msg}
	"next_step"			{terminate_linksDestroy}
}

dict set terminate_steps "terminate_linksDestroy" {
	"current_step"		{terminate_linksDestroy}
	"elem_type"			{links}
	"elem_name"			{terminate_links}
	"elem_count_name"	{links_count}
	"start_msg"			{Destroying links...}
	"skip_condition"	{ ! [isRunningLink $elem] }
	"success_msg"		{Destroying}
	"run_proc"			{destroyLinkBetween $eid $node1_id $node2_id $iface1_id $iface2_id $elem}
	"msg_template"		{%msg link $elem}
	"end_msg"			{Waiting for $elems_count link(s) to be destroyed...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{destroying}
	"check_proc"		{isLinkDestroyed $eid $elem}
	"done_msg_template"	{Link $elem destruction %msg}
	"next_step"			{terminate_nodesLogIfacesUnconfigure}
}

dict set terminate_steps "terminate_nodesLogIfacesUnconfigure" {
	"current_step"		{terminate_nodesLogIfacesUnconfigure}
	"elem_type"			{lifaces}
	"elem_name"			{unconfigure_nodes_ifaces}
	"elem_count_name"	{unconfigure_nodes_ifaces_count}
	"start_msg"			{Unconfiguring logical interfaces on nodes...}
	"skip_condition"	{ ! [isRunningNode $node_id] }
	"success_msg"		{Unconfiguring}
	"run_proc"			{invokeNodeProc $node_id "nodeIfacesUnconfigure" $eid $node_id "$ifaces"}
	"msg_template"		{%msg logical interfaces on node [getNodeName $node_id]}
	"end_msg"			{Waiting for logical interfaces on $elems_count node(s) to be unconfigured...}
	"timeout_type"		{ifacesconf_timeout}
	"condition_name"	{ifaces_unconfiguring}
	"check_proc"		{invokeNodeProc $elem "nodeIfacesUnconfigure_check" $eid $elem $ifaces}
	"done_msg_template"	{Node [getNodeName $elem] logical ifaces unconfiguration %msg}
	"next_step"			{terminate_nodesLogIfacesDestroy}
}

dict set terminate_steps "terminate_nodesLogIfacesDestroy" {
	"current_step"		{terminate_nodesLogIfacesDestroy}
	"elem_type"			{lifaces}
	"elem_name"			{destroy_nodes_ifaces}
	"elem_count_name"	{destroy_nodes_ifaces_count}
	"start_msg"			{Destroying logical interfaces on nodes...}
	"skip_condition"	{ ! [isRunningNode $node_id] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $node_id "nodeLogIfacesDestroy" $eid $node_id "$ifaces"}
	"msg_template"		{%msg logical interfaces on node [getNodeName $node_id]}
	"end_msg"			{Waiting for logical interfaces on $elems_count node(s) to be destroyed...}
	"timeout_type"		{ifacesconf_timeout}
	"condition_name"	{lifaces_destroying}
	"check_proc"		{invokeNodeProc $elem "nodeIfacesDestroy_check" $eid $elem $ifaces}
	"done_msg_template"	{Node [getNodeName $elem] logical ifaces destruction %msg}
	"next_step"			{terminate_nodesPhysIfacesUnconfigure}
}

dict set terminate_steps "terminate_nodesPhysIfacesUnconfigure" {
	"current_step"		{terminate_nodesPhysIfacesUnconfigure}
	"elem_type"			{pifaces}
	"elem_name"			{unconfigure_nodes_ifaces}
	"elem_count_name"	{unconfigure_nodes_ifaces_count}
	"start_msg"			{Unconfiguring physical interfaces on nodes...}
	"skip_condition"	{ ! [isRunningNode $node_id] }
	"success_msg"		{Unconfiguring}
	"run_proc"			{invokeNodeProc $node_id "nodeIfacesUnconfigure" $eid $node_id "$ifaces"}
	"msg_template"		{%msg physical interfaces on node [getNodeName $node_id]}
	"end_msg"			{Waiting for physical interfaces on $elems_count node(s) to be unconfigured...}
	"timeout_type"		{ifacesconf_timeout}
	"condition_name"	{ifaces_unconfiguring}
	"check_proc"		{invokeNodeProc $elem "nodeIfacesUnconfigure_check" $eid $elem $ifaces}
	"done_msg_template"	{Node [getNodeName $elem] physical ifaces unconfiguration %msg}
	"next_step"			{terminate_nodesPhysIfacesDestroy}
}

dict set terminate_steps "terminate_nodesPhysIfacesDestroy" {
	"current_step"		{terminate_nodesPhysIfacesDestroy}
	"elem_type"			{pifaces}
	"elem_name"			{destroy_nodes_ifaces}
	"elem_count_name"	{destroy_nodes_ifaces_count}
	"start_msg"			{Destroying physical interfaces on nodes...}
	"skip_condition"	{ ! [isRunningNode $node_id] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $node_id "nodePhysIfacesDestroy" $eid $node_id "$ifaces"}
	"msg_template"		{%msg physical interfaces on node [getNodeName $node_id]}
	"end_msg"			{Waiting for physical interfaces on $elems_count node(s) to be destroyed...}
	"timeout_type"		{ifacesconf_timeout}
	"condition_name"	{pifaces_destroying}
	"check_proc"		{invokeNodeProc $elem "nodeIfacesDestroy_check" $eid $elem $ifaces}
	"done_msg_template"	{Node [getNodeName $elem] physical ifaces destruction %msg}
	"next_step"			{terminate_nodesDestroyNative}
}

dict set terminate_steps "terminate_nodesDestroyNative" {
	"current_step"		{terminate_nodesDestroyNative}
	"elem_type"			{nodes}
	"elem_name"			{native_nodes}
	"elem_count_name"	{native_nodes_count}
	"start_msg"			{Destroying NATIVE nodes...}
	"skip_condition"	{ ! [isRunningNode $elem] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $elem "nodeDestroy" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem]}
	"end_msg"			{Waiting for $elems_count NATIVE node(s) to be destroyed...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{node_destroying}
	"check_proc"		{invokeNodeProc $elem "nodeDestroy_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] destruction %msg}
	"next_step"			{terminate_nodesDestroyNativeFS}
}

dict set terminate_steps "terminate_nodesDestroyNativeFS" {
	"current_step"		{terminate_nodesDestroyNativeFS}
	"elem_type"			{nodes}
	"elem_name"			{native_nodes}
	"elem_count_name"	{native_nodes_count}
	"start_msg"			{Destroying NATIVE nodes (FS)...}
	"skip_condition"	{ ! [isRunningNode $elem] || [isErrorNode $elem] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $elem "nodeDestroyFS" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem] (FS)}
	"end_msg"			{Waiting for $elems_count NATIVE node(s) to be destroyed (FS)...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{node_destroying_fs}
	"check_proc"		{invokeNodeProc $elem "nodeDestroyFS_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] FS destruction %msg}
	"next_step"			{terminate_nodesDestroyVirtualized}
}

# TODO: hanging TCPs?
dict set terminate_steps "terminate_nodesDestroyVirtualized" {
	"current_step"		{terminate_nodesDestroyVirtualized}
	"elem_type"			{nodes}
	"elem_name"			{virtualized_nodes}
	"elem_count_name"	{virtualized_nodes_count}
	"start_msg"			{Destroying VIRTUALIZED nodes...}
	"skip_condition"	{ ! [isRunningNode $elem] || [isErrorNode $elem] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $elem "nodeDestroy" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem]}
	"end_msg"			{Waiting for $elems_count VIRTUALIZED node(s) to be destroyed...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{node_destroying}
	"check_proc"		{invokeNodeProc $elem "nodeDestroy_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] destruction %msg}
	"next_step"			{terminate_nodesDestroyVirtualizedFS}
}

dict set terminate_steps "terminate_nodesDestroyVirtualizedFS" {
	"current_step"		{terminate_nodesDestroyVirtualizedFS}
	"elem_type"			{nodes}
	"elem_name"			{virtualized_nodes}
	"elem_count_name"	{virtualized_nodes_count}
	"start_msg"			{Destroying VIRTUALIZED nodes (FS)...}
	"skip_condition"	{ ! [isRunningNode $elem] || [isErrorNode $elem] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $elem "nodeDestroyFS" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem] (FS)}
	"end_msg"			{Waiting for $elems_count VIRTUALIZED node(s) to be destroyed (FS)...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{node_destroying_fs}
	"check_proc"		{invokeNodeProc $elem "nodeDestroyFS_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] FS destruction %msg}
	"next_step"			{terminate_isFinished}
}

proc terminate_isFinished { all_dict eid w } {
	if { [dictGet $all_dict "terminate"] } {
		terminate_removeExperimentContainer $all_dict $eid $w
	} else {
		terminate_finishTermination $all_dict $eid $w
	}
}

dict set terminate_steps "terminate_removeExperimentContainer" {
	"current_step"		{terminate_removeExperimentContainer}
	"elem_type"			{nodes}
	"elem_name"			{virtualized_nodes}
	"elem_count_name"	{virtualized_nodes_count}
	"start_msg"			{Destroying VIRTUALIZED nodes (FS)...}
	"skip_condition"	{ ! [isRunningNode $elem] || [isErrorNode $elem] }
	"success_msg"		{Destroying}
	"run_proc"			{invokeNodeProc $elem "nodeDestroyFS" $eid $elem}
	"msg_template"		{%msg node [getNodeName $elem] (FS)}
	"end_msg"			{Waiting for $elems_count VIRTUALIZED node(s) to be destroyed (FS)...}
	"timeout_type"		{nodecreate_timeout}
	"condition_name"	{node_destroying_fs}
	"check_proc"		{invokeNodeProc $elem "nodeDestroyFS_check" $eid $elem}
	"done_msg_template"	{Node [getNodeName $elem] FS destruction %msg}
	"next_step"			{terminate_isFinished}
}

proc terminateDo { all_dict step_dict w } {
	dict for {var_name value} $step_dict {
		set $var_name $value
	}

	# we run services BEFORE these steps
	switch -exact $current_step {
		"terminate_nodesUnconfigure" {
			statline "Stopping services for NODESTOP hook..."
			if { [dictGet $all_dict "all_nodes_count"] > 0 } {
				services stop "NODESTOP" "bkg" [dictGet $all_dict "all_nodes"]
			}
		}

		"terminate_linksUnconfigure" {
			statline "Stopping services for LINKDEST hook..."
			if { [dictGet $all_dict "all_nodes_count"] > 0 } {
				services stop "LINKDEST" "bkg" [dictGet $all_dict "all_nodes"]
			}
		}

		"terminate_nodesDestroyVirtualized" {
			statline "Stopping services for NODESTOP hook..."
			if { [dictGet $all_dict "virtualized_nodes_count"] > 0 } {
				services stop "NODESTOP" "bkg" [dictGet $all_dict "virtualized_nodes"]
			}
		}
	}

	statline $start_msg

	set elems [dictGet $all_dict $elem_name]
	set elems_count [dictGet $all_dict $elem_count_name]

	if { $elems_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		if { $elem_type in "nodes links" } {
			foreach elem $elems {
				displayBatchProgress $batchStep $elems_count

				if { $elem_type == "links" } {
					lassign [getLinkPeers $elem] node1_id node2_id
					lassign [getLinkPeersIfaces $elem] iface1_id iface2_id
				}

				if { [expr [subst $skip_condition]] } {
					set msg "Skipping"
				} else {
					set msg $success_msg
					try {
						{*}[subst $run_proc]
					} on error err {
						return -code error "Error in '[subst $run_proc]': $err"
					}

					pipesExec ""
				}

				incr batchStep

				regsub {%msg} $msg_template {$msg} full_msg
				updateProgressBar $w -1 "[subst $full_msg]"
			}
		} elseif { $elem_type in "ifaces pifaces lifaces" } {
			dict for {node_id ifaces} $elems {
				displayBatchProgress $batchStep $elems_count

				if { [expr [subst $skip_condition]] } {
					set msg "Skipping"
				} else {
					if { $ifaces == "*" } {
						if { $elem_type == "pifaces" } {
							set ifaces [ifcList $node_id]
						} elseif { $elem_type == "lifaces" } {
							set ifaces [logIfcList $node_id]
						} else {
							set ifaces [allIfcList $node_id]
						}
					} else {
						if { $elem_type == "pifaces" } {
							set ifaces [removeFromList $ifaces [logIfcList $node_id]]
						} elseif { $elem_type == "lifaces" } {
							set ifaces [removeFromList $ifaces [ifcList $node_id]]
						}
					}

					set ifaces_direct {}

					# remove non-matching interfaces
					if { $elem_name != "unconfigure_nodes_ifaces" } {
						if { $elem_type in "pifaces" } {
							foreach iface_id $ifaces {
								if {
									! [isRunningNodeIface $node_id $iface_id] ||
									"pifaces_destroying" in [getStateNodeIface $node_id $iface_id] ||
									([getIfcType $node_id $iface_id] == "stolen" &&
									[getFromRunning "${node_id}|${iface_id}_active_name"] == "")
								} {
									set ifaces [removeFromList $ifaces $iface_id]

									continue
								}

								set this_link_id [getIfcLink $node_id $iface_id]
								if { $this_link_id != "" && [getFromRunning "${this_link_id}_destroy_type"] } {
									set ifaces [removeFromList $ifaces $iface_id]
									lappend ifaces_direct $iface_id
								}
							}
						} elseif { $elem_type in "lifaces" } {
							foreach iface_id $ifaces {
								if {
									! [isRunningNodeIface $node_id $iface_id] ||
									"lifaces_destroying" in [getStateNodeIface $node_id $iface_id]
								} {
									set ifaces [removeFromList $ifaces $iface_id]
								}
							}
						}
					}

					if { $ifaces != {} } {
						try {
							{*}[subst $run_proc]
						} on error err {
							return -code error "Error in '[subst $run_proc]': $err"
						}
					}

					# direct interfaces are called along with physical ones
					if { $ifaces_direct != {} } {
						set direct_run_proc {invokeNodeProc $node_id "nodePhysIfacesDirectDestroy" $eid $node_id "$ifaces_direct"}
						try {
							{*}[subst $direct_run_proc]
						} on error err {
							return -code error "Error in '[subst $direct_run_proc]': $err"
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

				regsub {%msg} $msg_template {$msg} full_msg
				updateProgressBar $w -1 "[subst $full_msg]"
			}
		}
		pipesClose

		displayBatchProgress $batchStep $elems_count "clean_statline"

		statline [subst $end_msg]
	}

	set wait_dict $step_dict
	dict set wait_dict "elems" $elems
	dict set wait_dict "elems_count" $elems_count
	if { $elem_type in "ifaces pifaces lifaces" } {
		dict set wait_dict "elems_left" [dict keys $elems]
	} else {
		dict set wait_dict "elems_left" $elems
	}
	dict set wait_dict "nodes_ifaces" $elems
	dict set wait_dict "t_start" [clock milliseconds]
	dict set wait_dict "timeout" [getTimeout $timeout_type]
	dict set wait_dict "old_left_count" -1

	terminateWait $all_dict $w $wait_dict
}

proc terminateWait { all_dict w wait_dict } {
	global terminate_steps err_skip_nodesifaces
	global gui

	dict for {var_name value} $wait_dict {
		set $var_name $value
	}

	set elems_left_count [llength $elems_left]
	set batchStep [expr { $elems_count - $elems_left_count }]

	set try_again 0
	if { $elems_left_count > 0 } {
		displayBatchProgress $batchStep $elems_count

		# check all elements and return remaining elements
		set elems_left [terminateCheck [getFromRunning "eid"] $w $wait_dict]
		dict set wait_dict "elems_left" $elems_left

		set elems_left_count [llength $elems_left]
		set batchStep [expr { $elems_count - $elems_left_count }]

		if { $old_left_count != $elems_left_count } {
			# there is some progress, check if there are elems left
			if { $elems_left_count > 0 } {
				# some elems are completed, reset the timer and start again
				dict set wait_dict "old_left_count" $elems_left_count
				dict set wait_dict "t_start" [clock milliseconds]

				set try_again 1
			}
		} elseif { $timeout < 0 } {
			# no progress, legacy mode -> try until completion
			set try_again 1
		} else {
			# no progress, check timeout
			if { $elems_left_count > 0 && [expr { ([clock milliseconds] - $t_start) / 1000.0 }] > $timeout } {
				# timeout, finish this step
				set elems [removeFromList $elems $elems_left]
				dict set wait_dict "elems" $elems
				set elems_left $elems
			} elseif { $elems != {} } {
				# no timeout, there are still unfinished elems, try again
				set try_again 1
			}
		}
	}

	if { $try_again } {
		after 100 [list terminateWait $all_dict $w $wait_dict]

		return "again"
	}

	if { $elems_count > 0 } {
		displayBatchProgress $batchStep $elems_count "clean_statline"
	}

	if { $gui } {
		redrawAll
	}

	if { $next_step == "terminate_isFinished" } {
		$next_step $all_dict [getFromRunning "eid"] $w
	} else {
		terminateDo $all_dict [dictGet $terminate_steps $next_step] $w
	}

	return "done"
}

proc terminateCheck { eid w step_dict } {
	dict for {var_name value} $step_dict {
		set $var_name $value
	}

	set elems_left_count [llength $elems_left]
	set batchStep [expr { $elems_count - $elems_left_count }]

	if { $elem_type in "nodes ifaces pifaces lifaces" } {
		set get_proc "getStateNode"
		set remove_proc "removeStateNode"
	} elseif { $elem_type == "links" } {
		set get_proc "getStateLink"
		set remove_proc "removeStateLink"
	}

	foreach elem $elems_left {
		if { $condition_name in [$get_proc $elem] } {
			if { $elem_type in "ifaces pifaces lifaces" } {
				set ifaces [dict get $nodes_ifaces $elem]
				if { $ifaces == "*" } {
					if { $elem_type == "pifaces" } {
						set ifaces [ifcList $elem]
					} elseif { $elem_type == "lifaces" } {
						set ifaces [logIfcList $elem]
					} else {
						set ifaces [allIfcList $elem]
					}
				} else {
					if { $elem_type == "pifaces" } {
						set ifaces [removeFromList $ifaces [logIfcList $elem]]
					} elseif { $elem_type == "lifaces" } {
						set ifaces [removeFromList $ifaces [ifcList $elem]]
					}
				}
			}

			if { ! [eval {*}$check_proc] } {
				if { $timeout < 0 } {
					after [expr -$timeout]
				}
				continue
			}

			if { $elem_type == "links" } {
				addStateLink $elem "running"
				set mirror_link_id [getLinkMirror $elem]
				if { $mirror_link_id != "" } {
					addStateLink $mirror_link_id "running"
				}
			}

			$remove_proc $elem $condition_name
			set msg "done"
		} else {
			set msg "skipped"
		}

		displayBatchProgress [incr batchStep] $elems_count

		regsub {%msg} $done_msg_template {$msg} full_msg
		updateProgressBar $w -1 "[subst $full_msg]"

		set elems_left [removeFromList $elems_left $elem]
	}

	return $elems_left
}

proc checkTerminate {} {
}

proc undeployCfg { { eid "" } { terminate 0 } } {
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
	upvar 0 ::loop::state loop_state

	global terminate_steps

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

	terminateDo $all_dict [dictGet $terminate_steps "terminate_nodesUnconfigure"] $w

	# step1  -> terminate_nodesUnconfigure
	# step2  -> terminate_nodesShutdown
	# step3  -> terminate_linksUnconfigure
	# step4  -> terminate_linksDestroy
	# step5  -> terminate_nodesLogIfacesUnconfigure
	# step6  -> terminate_nodesLogIfacesDestroy
	# step7  -> terminate_nodesPhysIfacesUnconfigure
	# step8  -> terminate_nodesPhysIfacesDestroy
	# step9  -> terminate_nodesDestroyNative
	# step10  -> terminate_nodesDestroyNativeFS
	# step11 -> terminate_nodesDestroyVirtualized
	# step12 -> terminate_nodesDestroyVirtualizedFS
	# if terminate
	# step13 -> terminate_removeExperimentContainer
	# step14 -> terminate_removeExperimentFiles
	# step15 -> terminate_deleteRuntimeFiles

	#terminate_nodesUnconfigure $all_dict $eid $w
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
