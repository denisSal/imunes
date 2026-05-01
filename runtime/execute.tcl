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

#****f* exec.tcl/genExperimentId
# NAME
#   genExperimentId -- generate experiment ID
# SYNOPSIS
#   set eid [genExperimentId]
# FUNCTION
#   Generates a new random experiment ID that will be used when the experiment
#   is started.
# RESULT
#   * eid -- a new generated experiment ID
#****
proc genExperimentId {} {
	global isOSlinux

	if { $isOSlinux } {
		return i[string range [format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]] end-2 end]
	} else {
		return i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
	}
}

#****f* exec.tcl/checkExternalInterfaces
# NAME
#   checkExternalInterfaces -- check external interfaces in the topology
# SYNOPSIS
#   checkExternalInterfaces
# FUNCTION
#   Check whether external interfaces are available in the running system.
# RESULT
#   * returns 0 if everything is ok, otherwise it returns 1.
#****
proc checkExternalInterfaces {} {
	global execMode isOSlinux gui

	set eid [getFromRunning "eid"]

	set nodes_ifcpairs {}
	foreach node_id [getFromRunning "node_list"] {
		if { $node_id in [getFromRunning "no_auto_execute_nodes"] } {
			continue
		}

		set ifaces [ifcList $node_id]
		if { ! [invokeNodeProc $node_id "checkIfacesPrerequisites" $eid $node_id $ifaces] } {
			foreach iface_id $ifaces {
				set msg [getStateErrorMsgNodeIface $node_id $iface_id]
				if { $msg == "" } {
					continue
				}

				if { "wireless" in [getStateNodeIface $node_id $iface_id] } {
					set severity "WARNING"
				} else {
					set severity "ERROR"
				}

				set msg "[getNodeName $node_id] - $iface_id\n$msg"
				if { ! $gui || $execMode == "batch" } {
					sputs stderr "IMUNES $severity: $msg"
				} else {
					after idle { .dialog1.msg configure -wraplength 4i }
					tk_dialog .dialog1 "IMUNES $severity" $msg \
						info 0 Dismiss
				}

				if { $severity == "ERROR" } {
					return 1
				}
			}
		}
	}

	return 0

	set extifcs [getHostIfcList]

	foreach node_ifcpair $nodes_ifcpairs {
		lassign $node_ifcpair node_id ifcpair
		lassign $ifcpair iface_id physical_ifc

		if { $physical_ifc == "UNASSIGNED" } {
			continue
		}

		# check if the interface exists
		set i [lsearch $extifcs $physical_ifc]
		if { $i < 0 } {
			set msg "Error: external interface $physical_ifc non-existant."
			if { ! $gui || $execMode == "batch" } {
				sputs stderr $msg
			} else {
				after idle { .dialog1.msg configure -wraplength 4i }
				tk_dialog .dialog1 "IMUNES error" $msg \
					info 0 Dismiss
			}

			return 1
		}

		if { [getIfcVlanDev $node_id $iface_id] != "" && [getIfcVlanTag $node_id $iface_id] != "" } {
			if { [getHostIfcVlanExists $node_id $physical_ifc] } {
				return 1
			}
		} elseif { $isOSlinux } {
			set dirname "/sys/class/net/$physical_ifc/wireless"
			catch { rexec ls -d $dirname } output
			if { "$dirname" == "$output"} {
				if { [getLinkDirect [getIfcLink $node_id $iface_id]] } {
					set severity "warning"
					set msg "Interface '$physical_ifc' is a wireless interface,\
						so its peer cannot change its MAC address!"
				} else {
					set severity "error"
					set msg "Cannot bridge wireless interface '$physical_ifc',\
						use 'Direct link' to connect to this interface!"
				}

				if { ! $gui || $execMode == "batch" } {
					sputs stderr $msg
				} else {
					after idle { .dialog1.msg configure -wraplength 4i }
					tk_dialog .dialog1 "IMUNES $severity" "$msg" \
						info 0 Dismiss
				}

				if { $severity == "error" } {
					return 1
				}
			}
		}
	}

	return 0
}

#****f* exec.tcl/execCmdsNode
# NAME
#   execCmdsNode -- execute a set of commands on virtual node
# SYNOPSIS
#   execCmdsNode $node_id $cmds
# FUNCTION
#   Executes commands on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmds -- list of commands to execute
# RESULT
#   * returns the execution output
#****
proc execCmdsNode { node_id cmds } {
	set output ""
	foreach cmd $cmds {
		set result [execCmdNode $node_id $cmd]
		append output "\n" $result
	}
	return $output
}

#****f* exec.tcl/execCmdsNodeBkg
# NAME
#   execCmdsNodeBkg -- execute a set of commands on virtual node
# SYNOPSIS
#   execCmdsNodeBkg $node_id $cmds
# FUNCTION
#   Executes commands on a virtual node (in the background).
# INPUTS
#   * node_id -- virtual node id
#   * cmds -- list of commands to execute
#****
proc execCmdsNodeBkg { node_id cmds { output "" } } {
	set cmds_str ""
	foreach cmd $cmds {
		if { $output != "" } {
			set cmd "$cmd >> $output"
		}

		set cmds_str "$cmds_str $cmd ;"
	}

	execCmdNodeBkg $node_id $cmds_str
}

#****f* exec.tcl/createExperimentFiles
# NAME
#   createExperimentFiles -- create experiment files
# SYNOPSIS
#   createExperimentFiles $eid
# FUNCTION
#   Creates all needed files to run the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc createExperimentFiles { eid } {
	global currentFileBatch execMode runtimeDir gui

	set current_file [getFromRunning "current_file"]
	set basedir "$runtimeDir/$eid"

	writeDataToFile $basedir/timestamp [clock format [clock seconds]]

	dumpLinksToFile $basedir/links

	if { $execMode == "interactive" } {
		if { $current_file != "" } {
			writeDataToFile $basedir/name [file tail $current_file]
		}
	} else {
		if { $currentFileBatch != "" } {
			writeDataToFile $basedir/name [file tail $currentFileBatch]
		}
	}

	saveRunningConfiguration $eid
	if { $gui && $execMode == "interactive" } {
		createExperimentScreenshot $eid
	}
}

proc createRunningVarsFile { eid } {
	global runtimeDir

	upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
	upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
	upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

	# TODO: maybe remove some elements?
	writeDataToFile $runtimeDir/$eid/runningVars \
		[list "dict_run" "$dict_run" "dict_run_gui" "$dict_run_gui" "execute_vars" "$execute_vars"]
}

#****f* exec.tcl/createExperimentScreenshot
# NAME
#   createExperimentScreenshot -- create experiment screenshot
# SYNOPSIS
#   createExperimentScreenshot $eid
# FUNCTION
#   Creates a screenshot for the specified experiment and saves it as an image #   in png format.
# INPUTS
#   * eid -- experiment id
#****
proc createExperimentScreenshot { eid } {
	global runtimeDir main_canvas_elem

	set fileName "$runtimeDir/$eid/screenshot.png"
	set error [catch { eval image create photo screenshot -format window \
		-data $main_canvas_elem } err]
	if { $error == 0 } {
		screenshot write $fileName -format png

		catch { exec magick $fileName -resize 300x210\! $fileName\2 }
		catch { exec mv $fileName\2 $fileName }
	}
}

#****f* exec.tcl/createExperimentFilesFromBatch
# NAME
#   createExperimentFilesFromBatch -- create experiment files from batch
# SYNOPSIS
#   createExperimentFilesFromBatch
# FUNCTION
#   Creates all needed files to run the experiments in batch mode.
#****
proc createExperimentFilesFromBatch {} {
	createExperimentFiles [getFromRunning "eid"]
}

#****f* freebsd.tcl/l3node.nghook
# NAME
#   l3node.nghook -- layer 3 node netgraph hook
# SYNOPSIS
#   l3node.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the netgraph node name and the hook name for a given experiment
#   id, node id, and interface id.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc l3node.nghook { eid node_id iface_id } {
	switch -exact [string trim $iface_id 0123456789] {
		wlan -
		ext -
		eth {
			return [list $node_id-$iface_id ether]
		}
	}
}

#****f* exec.tcl/nodeIpsecInit
# NAME
#   nodeIpsecInit -- IPsec initialization
# SYNOPSIS
#   nodeIpsecInit $node_id
# FUNCTION
#   Creates ipsec.conf and ipsec.secrets files from IPsec configuration of given node
#   and copies certificates to desired folders (if there are any certificates)
# INPUTS
#   * node_id -- node id
#****
global ipsecConf ipsecSecrets
set ipsecConf ""
set ipsecSecrets ""
proc nodeIpsecInit { node_id } {
	global ipsecConf ipsecSecrets isOSfreebsd

	if { ! [isRunningNode $node_id] || [getNodeIPsec $node_id] == "" } {
		return
	}

	set ipsecSecrets "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n\n"

	setNodeIPsecSetting $node_id "%default" "keyexchange" "ikev2"
	set ipsecConf "# /etc/ipsec.conf - strongSwan IPsec configuration file\n"
	set ipsecConf "${ipsecConf}config setup\n"

	foreach {config_name config} [getNodeIPsecItem $node_id "ipsec_configs"] {
		set ipsecConf "${ipsecConf}conn $config_name\n"
		set hasKey 0
		set hasRight 0
		foreach {setting value} $config {
			if { $setting == "peersname" } {
				continue
			}

			if { $setting == "sharedkey" } {
				set hasKey 1
				set psk_key $value
				continue
			}

			if { $setting == "right" } {
				set hasRight 1
				set right $value
			}

			set ipsecConf "$ipsecConf	$setting=$value\n"
		}

		if { $hasKey && $hasRight } {
			set ipsecSecrets "${ipsecSecrets}$right : PSK $psk_key\n"
		}
	}

	delNodeIPsecConnection $node_id "%default"

	set ca_cert [getNodeIPsecItem $node_id "ca_cert"]
	set local_cert [getNodeIPsecItem $node_id "local_cert"]
	set ipsecret_file [getNodeIPsecItem $node_id "local_key_file"]
	ipsecFilesToNode $node_id $ca_cert $local_cert $ipsecret_file

	set ipsec_log_level [getNodeIPsecItem $node_id "ipsec_logging"]
	if { $ipsec_log_level != "" } {
		execCmdNode $node_id "touch /tmp/charon.log"

		set charon "charon {\n"
		append charon "\tfilelog {\n"
		append charon "\t\tcharon {\n"
		append charon "\t\t\tpath = /tmp/charon.log\n"
		append charon "\t\t\tappend = yes\n"
		append charon "\t\t\tflush_line = yes\n"
		append charon "\t\t\tdefault = $ipsec_log_level\n"
		append charon "\t\t}\n"
		append charon "\t}\n"
		append charon "}"

		set prefix ""
		if { $isOSfreebsd } {
			set prefix "/usr/local"
		}

		writeDataToNodeFile $node_id "$prefix/etc/strongswan.d/charon-logging.conf" $charon
	}
}

#****f* exec.tcl/generateHostsFile
# NAME
#   generateHostsFile -- generate hosts file
# SYNOPSIS
#   generateHostsFile $node_id
# FUNCTION
#   Generates /etc/hosts file on the given node containing all the nodes in the
#   topology.
# INPUTS
#   * node_id -- node id
#****
proc generateHostsFile { node_id } {
	if { [getActiveOption "auto_etc_hosts"] != 1 || [invokeNodeProc $node_id "virtlayer"] != "VIRTUALIZED" } {
		return
	}

	set etc_hosts [getFromRunning "etc_hosts"]
	if { $etc_hosts == "" } {
		foreach other_node_id [getFromRunning "node_list"] {
			if { [invokeNodeProc $other_node_id "virtlayer"] != "VIRTUALIZED" } {
				continue
			}

			set ctr 0
			set ctr6 0
			foreach iface_id [ifcList $other_node_id] {
				if { $iface_id == "" } {
					continue
				}

				set node_name [getNodeName $other_node_id]
				foreach ipv4 [getIfcIPv4addrs $other_node_id $iface_id] {
					set ipv4 [lindex [split $ipv4 "/"] 0]
					if { $ctr == 0 } {
						set etc_hosts "$etc_hosts$ipv4	${node_name}\n"
					} else {
						set etc_hosts "$etc_hosts$ipv4	${node_name}_${ctr}\n"
					}
					incr ctr
				}

				foreach ipv6 [getIfcIPv6addrs $other_node_id $iface_id] {
					set ipv6 [lindex [split $ipv6 "/"] 0]
					if { $ctr6 == 0 } {
						set etc_hosts "$etc_hosts$ipv6	${node_name}.6\n"
					} else {
						set etc_hosts "$etc_hosts$ipv6	${node_name}_${ctr6}.6\n"
					}
					incr ctr6
				}
			}
		}

		setToRunning "etc_hosts" $etc_hosts
	}

	writeDataToNodeFile $node_id /etc/hosts $etc_hosts
}

proc checkNodePrerequisites { nodes nodes_count w } {
	set timeout [getTimeout "nodecreate_timeout"]

	set eid [getFromRunning "eid"]

	set t_start [clock milliseconds]

	set batchStep 0
	set nodes_left $nodes
	set old_left_count -1
	while { [llength $nodes_left] > 0 } {
		displayBatchProgress $batchStep $nodes_count
		foreach node_id $nodes_left {
			if { ! [isRunningNode $node_id] } {
				# clear state
				removeStateNode $node_id "error node_creating ns_creating pifaces_creating lifaces_creating"
				removeStateNode $node_id "error lifaces_destroying pifaces_destroying node_destroying node_destroying_fs"

				if { ! [invokeNodeProc $node_id "checkNodePrerequisites" $eid $node_id] } {
					set msg "failed"
				} else {
					set msg "successful"
				}
			} else {
				set msg "skipped"
			}

			incr batchStep
			displayBatchProgress $batchStep $nodes_count

			updateProgressBar $w 1 "Prerequisites check for [getNodeName $node_id] $msg"

			set nodes_left [removeFromList $nodes_left $node_id]
		}

		if { $old_left_count != [llength $nodes_left] } {
			set old_left_count [llength $nodes_left]
			set t_start [clock milliseconds]

			continue
		}

		if { $timeout < 0 } {
			continue
		}

		set t_last [clock milliseconds]
		if { [llength $nodes_left] > 0 && [expr {($t_last - $t_start)/1000.0}] > $timeout } {
			break
		}
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count "clean_statline"
	}
}

#****f* exec.tcl/deployCfg
# NAME
#   deployCfg -- deploy working configuration
# SYNOPSIS
#   deployCfg
# FUNCTION
#   Deploys a current working configuration. It creates and configures all the
#   nodes, interfaces and links given in the "executeVars" set of variables:
#   instantiate_nodes, create_nodes_ifaces, instantiate_links, configure_links,
#   configure_nodes_ifaces, configure_nodes
#****
proc deployCfg { { execute 0 } } {
	upvar 0 ::loop::state loop_state

	set loop_state "executing"

	global progressbarCount execMode err_skip_nodesifaces
	global runnable_node_types gui

	if { ! $execute } {
		if { ! [getFromRunning "cfg_deployed"] } {
			set loop_state "null"

			return
		}

		if { ! [getFromRunning "auto_execution"] } {
			createExperimentFiles [getFromRunning "eid"]
			createRunningVarsFile [getFromRunning "eid"]

			set loop_state "null"

			return
		}
	} else {
		setToExecuteVars "terminate_cfg" ""
	}

	prepareInstantiateVars "force"

	if { "$instantiate_nodes$create_nodes_ifaces$instantiate_links$configure_links$configure_nodes_ifaces$configure_nodes" == "" } {
		set loop_state "null"

		return
	}

	set progressbarCount 0
	set err_skip_nodesifaces {}
	set nodes_count [llength $instantiate_nodes]
	set links_count [llength $instantiate_links]

	foreach link_id $instantiate_links {
		setToRunning "${link_id}_destroy_type" [getLinkDirect $link_id]
	}

	set t_start [clock milliseconds]

	set init_popup ""
	if { $gui && $execMode != "batch" } {
		set init_popup .startup
		catch { destroy $init_popup }
		toplevel $init_popup -takefocus 1
		wm transient $init_popup .
		wm title $init_popup "Preparing the system"

		message $init_popup.msg -justify left -aspect 1200 \
			-text "Checking prerequisites..."

		pack $init_popup.msg
		update

		set init_max 5
		ttk::progressbar $init_popup.p -orient horizontal -length 250 \
			-mode determinate -maximum $init_max -value 0
		pack $init_popup.p
		update

		grab $init_popup
	}

	try {
		execute_prepareSystem $init_popup.p $init_popup.msg
	} on error err {
		statline "ERROR in 'execute_prepareSystem $init_popup.p $init_popup.msg': '$err'"
		if { $gui && $execMode != "batch" } {
			catch { destroy $init_popup }

			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				"$err \nTerminate the experiment and report the bug!" info 0 Dismiss
		}

		set loop_state "null"

		return
	}

	if { $gui && $execMode != "batch" } {
		$init_popup.p configure -value $init_max
		update

		catch { destroy $init_popup }
	}

	statline "Preparing for initialization..."

	# TODO: fix this mess
	set native_nodes {}
	set virtualized_nodes {}
	set all_nodes {}
	set no_auto_execute_nodes [getFromRunning "no_auto_execute_nodes"]
	foreach node_id $instantiate_nodes {
		if { [getNodeType $node_id] ni $runnable_node_types || $node_id in $no_auto_execute_nodes } {
			set instantiate_nodes [removeFromList $instantiate_nodes $node_id]
			set configure_nodes [removeFromList $configure_nodes $node_id]
			if { $create_nodes_ifaces != "*" && $node_id in [dict keys $create_nodes_ifaces] } {
				dict unset create_nodes_ifaces $node_id
			}

			if { $configure_nodes_ifaces != "*" && $node_id in [dict keys $configure_nodes_ifaces] } {
				dict unset configure_nodes_ifaces $node_id
			}

			continue
		}

		if { [invokeNodeProc $node_id "virtlayer"] != "VIRTUALIZED" } {
			lappend native_nodes $node_id
		} else {
			lappend virtualized_nodes $node_id
		}
	}

	set native_nodes_count [llength $native_nodes]
	set virtualized_nodes_count [llength $virtualized_nodes]
	set all_nodes [concat $native_nodes $virtualized_nodes]
	set all_nodes_count [llength $all_nodes]

	if { $create_nodes_ifaces == "*" } {
		set create_nodes_ifaces ""
		foreach node_id $all_nodes {
			dict set create_nodes_ifaces $node_id "*"
		}
		set create_nodes_ifaces_count $all_nodes_count
	} else {
		set create_nodes_ifaces_count [llength [dict keys $create_nodes_ifaces]]
	}

	if { $configure_nodes_ifaces == "*" } {
		set configure_nodes_ifaces ""
		foreach node_id $all_nodes {
			dict set configure_nodes_ifaces $node_id "*"
		}
		set configure_nodes_ifaces_count $all_nodes_count
	} else {
		set configure_nodes_ifaces_count [llength [dict keys $configure_nodes_ifaces]]
	}

	if { $configure_nodes == "*" } {
		set configure_nodes $all_nodes
	}
	set configure_nodes_count [llength $configure_nodes]

	if { $configure_links == "*" } {
		set configure_links $instantiate_links
	}
	set configure_links_count [llength $configure_links]

	set maxProgressbasCount [expr {3*$all_nodes_count + 2*$native_nodes_count + 4*$virtualized_nodes_count + 2*$links_count + 1*$configure_links_count + 3*$configure_nodes_count + 4*$create_nodes_ifaces_count + 3*$configure_nodes_ifaces_count}]

	set w ""
	set eid [getFromRunning "eid"]
	if { $gui && $execMode != "batch" } {
		set w .startup
		catch { destroy $w }
		toplevel $w -takefocus 1
		wm transient $w .
		wm title $w "Starting experiment $eid..."

		message $w.msg -justify left -aspect 1200 \
			-text "Starting up virtual nodes and links."

		pack $w.msg
		update

		ttk::progressbar $w.p -orient horizontal -length 250 \
			-mode determinate -maximum $maxProgressbasCount -value $progressbarCount
		pack $w.p
		update

		grab $w
	}

	if { $execute && ! [getFromRunning "auto_execution"] } {
		updateInstantiateVars "force"
		createRunningVarsFile $eid

		statline "Empty topology instantiated in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."

		if { ! $gui || $execMode == "batch" } {
			sputs "Experiment ID = $eid"
		}

		if { $gui } {
			catch { destroy $w }
		}

		set progressbarCount 0

		set loop_state "null"

		return
	}

	statline "Checking node prerequisites..."
	checkNodePrerequisites $all_nodes $all_nodes_count $w

	set all_dict [dict create]
	dict set all_dict "t_start" $t_start
	dict set all_dict "execute" $execute
	dict set all_dict "virtualized_nodes" $virtualized_nodes
	dict set all_dict "virtualized_nodes_count" $virtualized_nodes_count
	dict set all_dict "all_nodes" $all_nodes
	dict set all_dict "all_nodes_count" $all_nodes_count
	dict set all_dict "native_nodes" $native_nodes
	dict set all_dict "native_nodes_count" $native_nodes_count
	dict set all_dict "configure_nodes" $configure_nodes
	dict set all_dict "configure_nodes_count" $configure_nodes_count
	dict set all_dict "create_nodes_ifaces" $create_nodes_ifaces
	dict set all_dict "create_nodes_ifaces_count" $create_nodes_ifaces_count
	dict set all_dict "configure_nodes_ifaces" $configure_nodes_ifaces
	dict set all_dict "configure_nodes_ifaces_count" $configure_nodes_ifaces_count
	dict set all_dict "instantiate_links" $instantiate_links
	dict set all_dict "links_count" $links_count
	dict set all_dict "configure_links" $configure_links
	dict set all_dict "configure_links_count" $configure_links_count

	# -> step1  - execute_nodesCreateVirtualized
	# -> step2  - execute_nodesNamespaceSetup
	# -> step3  - execute_nodesInitConfigure
	# -> step4  - execute_nodesCreateNative
	# -> step5  - execute_nodesPhysIfacesCreate
	# -> step6  - execute_nodesLogIfacesCreate
	# -> step7  - execute_nodesIfacesConfigure
	# -> step8  - execute_linksCreate
	# -> step9  - execute_linksConfigure
	# -> step10 - execute_nodesConfigure
	# -> step11 - execute_finishExecution

	execute_nodesCreateVirtualized $all_dict $w
}

proc execute_prepareSystem { progressbar_widget msg_widget } {
	global eid_base isOSlinux
	global execMode gui

	if { [getFromRunning "cfg_deployed"] } {
		return
	}

	set running_eids [getResumableExperiments]
	set eid [getFromRunning "eid"]
	if { $eid == "" || $eid in $running_eids } {
		if { $gui && $execMode != "batch" } {
			if { $isOSlinux } {
				set eid_base [string range $eid_base 0 3]
			}

			set eid ${eid_base}[string range $::curcfg 3 end]
			while { $eid in $running_eids } {
				set eid_base [genExperimentId]
				set eid ${eid_base}[string range $::curcfg 3 end]
				set running_eids [getResumableExperiments]
			}
		} else {
			if { $isOSlinux } {
				set eid_base [string range $eid_base 0 4]
			}

			set eid $eid_base
			while { $eid in $running_eids } {
				sputs -nonewline stderr "Experiment ID $eid already in use, trying "
				set eid [genExperimentId]
				sputs stderr "$eid."
				set running_eids [getResumableExperiments]
			}
		}

		setToRunning "eid" $eid
	}

	if { $gui && $execMode != "batch" } {
		$progressbar_widget step
		$msg_widget configure -text "Loading kernel modules..."
	}
	statline "Loading kernel modules..."
	loadKernelModules

	if { $gui && $execMode != "batch" } {
		$progressbar_widget step
		$msg_widget configure -text "Preparing virtual filesystem..."
	}
	statline "Preparing virtual filesystem..."
	prepareVirtualFS

	if { $gui && $execMode != "batch" } {
		$progressbar_widget step
		$msg_widget configure -text "Preparing devfs..."
	}
	statline "Preparing devfs..."
	prepareDevfs

	if { $gui && $execMode != "batch" } {
		$progressbar_widget step
		$msg_widget configure -text "Creating experiment..."
	}
	statline "Creating experiment..."
	createExperimentContainer
	createExperimentFiles $eid
	createRunningVarsFile $eid
}

proc executeCheck { eid elem_type elems_left elems_count nodes_ifaces timeout w condition_state check_proc msg_template } {
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
		if { $condition_state in [$get_proc $elem] } {
			if { $nodes_ifaces != {} } {
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

			$remove_proc $elem $condition_state
			set msg "done"
		} else {
			set msg "skipped"
		}

		displayBatchProgress [incr batchStep] $elems_count

		regsub {%msg} $msg_template {$msg} full_msg
		updateProgressBar $w 1 "[subst $full_msg]"

		set elems_left [removeFromList $elems_left $elem]
	}

	return $elems_left
}

proc executeWait { all_dict elem_type elems elems_count elems_left nodes_ifaces w t_start timeout old_left_count callback_proc condition check_proc msg_template } {
	global err_skip_nodesifaces

	set elems_left_count [llength $elems_left]
	set batchStep [expr { $elems_count - $elems_left_count }]

	set try_again 0
	if { $elems_left_count > 0 } {
		displayBatchProgress $batchStep $elems_count

		set elems_left [executeCheck \
			[getFromRunning "eid"] \
			$elem_type \
			$elems_left \
			$elems_count \
			$nodes_ifaces \
			$timeout \
			$w \
			$condition \
			$check_proc \
			$msg_template \
			]

		set elems_left_count [llength $elems_left]
		set batchStep [expr { $elems_count - $elems_left_count }]

		if { $old_left_count != $elems_left_count } {
			# there is some progress, check if there are elems left
			if { $elems_left_count > 0 } {
				# some elems are completed, reset the timer and start again
				set old_left_count $elems_left_count
				set t_start [clock milliseconds]

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
				set elems_left $elems
			} elseif { $elems != {} } {
				# no timeout, there are still unfinished elems, try again
				set try_again 1
			}
		}
	}

	if { $try_again } {
		# [info level 0] gives the name of the procedure, along with its arguments
		after 100 [list [lindex [info level 0] 0] \
			$all_dict \
			$elem_type \
			$elems \
			$elems_count \
			$elems_left \
			$nodes_ifaces \
			$w \
			$t_start \
			$timeout \
			$old_left_count \
			$callback_proc \
			$condition \
			$check_proc \
			$msg_template \
			]

		return "again"
	}

	if { $elems_count > 0 } {
		displayBatchProgress $batchStep $elems_count "clean_statline"
	}

	$callback_proc $all_dict $w

	return "done"
}

proc execute_nodesCreateVirtualized { all_dict w } {
	set virtualized_nodes [dictGet $all_dict "virtualized_nodes"]
	set virtualized_nodes_count [dictGet $all_dict "virtualized_nodes_count"]

	statline "Instantiating VIRTUALIZED nodes..."
	if { $virtualized_nodes_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		foreach node_id $virtualized_nodes {
			displayBatchProgress $batchStep $virtualized_nodes_count

			if { [isErrorNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Instantiating"
				try {
					invokeNodeProc $node_id "nodeCreate" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeCreate $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep

			updateProgressBar $w 1 "$msg node [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $virtualized_nodes_count "clean_statline"

		statline "Waiting for $virtualized_nodes_count VIRTUALIZED node(s) to start..."
	}

	set elem_type "nodes"
	set elems $virtualized_nodes
	set elems_count $virtualized_nodes_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesNamespaceSetup"
	set condition "node_creating"
	set check_proc [list invokeNodeProc \$elem "nodeCreate_check" \$eid \$elem]
	set msg_template "Node \[getNodeName \$elem] creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesNamespaceSetup { all_dict w } {
	set all_nodes [dictGet $all_dict "all_nodes"]
	set all_nodes_count [dictGet $all_dict "all_nodes_count"]

	if { $all_nodes_count > 0 } {
		statline "Setting up namespaces for all nodes..."

		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		foreach node_id $all_nodes {
			displayBatchProgress $batchStep $all_nodes_count

			if { [isErrorNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Creating"
				try {
					invokeNodeProc $node_id "nodeNamespaceSetup" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeNamespaceSetup $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep

			updateProgressBar $w 1 "$msg namespace for [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $all_nodes_count "clean_statline"

		statline "Waiting on namespaces for $all_nodes_count node(s)..."
	}

	set elem_type "nodes"
	set elems $all_nodes
	set elems_count $all_nodes_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesInitConfigure"
	set condition "ns_creating"
	set check_proc [list invokeNodeProc \$elem "nodeNamespaceSetup_check" \$eid \$elem]
	set msg_template "Namespace for \[getNodeName \$elem] creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesInitConfigure { all_dict w } {
	set virtualized_nodes [dictGet $all_dict "virtualized_nodes"]
	set virtualized_nodes_count [dictGet $all_dict "virtualized_nodes_count"]

	statline "Starting initial configuration on VIRTUALIZED nodes..."
	if { $virtualized_nodes_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		foreach node_id $virtualized_nodes {
			displayBatchProgress $batchStep $virtualized_nodes_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Starting"
				try {
					invokeNodeProc $node_id "nodeInitConfigure" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeInitConfigure $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep

			updateProgressBar $w 1 "$msg initial configuration on [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $virtualized_nodes_count "clean_statline"

		statline "Waiting for initial configuration on $virtualized_nodes_count VIRTUALIZED node(s)..."
	}

	set elem_type "nodes"
	set elems $virtualized_nodes
	set elems_count $virtualized_nodes_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesCreateNative"
	set condition "init_configuring"
	set check_proc [list invokeNodeProc \$elem "nodeInitConfigure_check" \$eid \$elem]
	set msg_template "Initial networking on \[getNodeName \$elem] creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesCreateNative { all_dict w } {
	set native_nodes [dictGet $all_dict "native_nodes"]
	set native_nodes_count [dictGet $all_dict "native_nodes_count"]

	statline "Instantiating NATIVE nodes..."
	if { $native_nodes_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		foreach node_id $native_nodes {
			displayBatchProgress $batchStep $native_nodes_count

			if { [isErrorNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Instantiating"
				try {
					invokeNodeProc $node_id "nodeCreate" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeCreate $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep

			updateProgressBar $w 1 "$msg node [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $native_nodes_count "clean_statline"

		statline "Waiting for $native_nodes_count NATIVE node(s) to start..."
	}

	set elem_type "nodes"
	set elems $native_nodes
	set elems_count $native_nodes_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesPhysIfacesCreate"
	set condition "node_creating"
	set check_proc [list invokeNodeProc \$elem "nodeCreate_check" \$eid \$elem]
	set msg_template "Node \[getNodeName \$elem] creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesCopyFiles { nodes nodes_count w } {
}

proc execute_nodesPhysIfacesCreate { all_dict w } {
	set configure_nodes [dictGet $all_dict "configure_nodes"]
	set configure_nodes_count [dictGet $all_dict "configure_nodes_count"]

	statline "Starting services for NODEINST hook..."
	if { $configure_nodes_count > 0 } {
		services start "NODEINST" "bkg" $configure_nodes
	}

	set create_nodes_ifaces [dictGet $all_dict "create_nodes_ifaces"]
	set create_nodes_ifaces_count [dictGet $all_dict "create_nodes_ifaces_count"]

	statline "Creating physical interfaces on nodes..."
	if { $create_nodes_ifaces_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		dict for {node_id ifaces} $create_nodes_ifaces {
			displayBatchProgress $batchStep $create_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				if { $ifaces == "*" } {
					set ifaces [ifcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [logIfcList $node_id]]
				}

				set ifaces_direct {}

				# skip already-creating and UNASSIGNED stolen interfaces
				foreach iface_id $ifaces {
					if {
						"creating" in [getStateNodeIface $node_id $iface_id] ||
						([getIfcType $node_id $iface_id] == "stolen" &&
						[getIfcName $node_id $iface_id] == "UNASSIGNED")
					} {
						set ifaces [removeFromList $ifaces $iface_id]

						continue
					}

					set this_link_id [getIfcLink $node_id $iface_id]
					if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
						lappend ifaces_direct $iface_id
					}
				}

				if { $ifaces != {} } {
					# mark interfaces to skip
					if { ! [invokeNodeProc $node_id "checkIfacesPrerequisites" $eid $node_id $ifaces] } {
						foreach iface_id $ifaces {
							if { [isErrorNodeIface $node_id $iface_id] } {
								set ifaces [removeFromList $ifaces $iface_id]
								set ifaces_direct [removeFromList $ifaces_direct $iface_id]
							}
						}
					}

					set ifaces [removeFromList $ifaces $ifaces_direct]
				}

				if { $ifaces != {} } {
					try {
						invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodePhysIfacesCreate $eid $node_id $ifaces': $err"
					}
				}

				if { $ifaces_direct != {} } {
					try {
						invokeNodeProc $node_id "nodePhysIfacesDirectCreate" $eid $node_id $ifaces_direct
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodePhysIfacesDirectCreate $eid $node_id $ifaces_direct': $err"
					}
				}

				if { $ifaces != {} || $ifaces_direct != {} } {
					pipesExec ""

					set msg "Creating"
				} else {
					set msg "No available"
				}
			}

			incr batchStep

			updateProgressBar $w 1 "$msg physical ifaces on node [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $create_nodes_ifaces_count "clean_statline"

		statline "Waiting for physical interfaces on $create_nodes_ifaces_count node(s) to be created..."
	}

	set elem_type "pifaces"
	set elems [dict keys $create_nodes_ifaces]
	set elems_count $create_nodes_ifaces_count
	set elems_left $elems
	set nodes_ifaces $create_nodes_ifaces
	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesLogIfacesCreate"
	set condition "pifaces_creating"
	set check_proc [list invokeNodeProc \$elem "nodePhysIfacesCreate_check" \$eid \$elem \$ifaces]
	set msg_template "Node \[getNodeName \$elem] physical ifaces creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesLogIfacesCreate { all_dict w } {
	set create_nodes_ifaces [dictGet $all_dict "create_nodes_ifaces"]
	set create_nodes_ifaces_count [dictGet $all_dict "create_nodes_ifaces_count"]

	statline "Creating logical interfaces on nodes..."
	if { $create_nodes_ifaces_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		dict for {node_id ifaces} $create_nodes_ifaces {
			displayBatchProgress $batchStep $create_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				if { $ifaces == "*" } {
					set ifaces [logIfcList $node_id]
				} else {
					set ifaces [removeFromList $ifaces [ifcList $node_id]]
				}

				foreach iface_id $ifaces {
					if { [isRunningNodeIface $node_id $iface_id] } {
						set ifaces [removeFromList $ifaces $iface_id]
					}
				}

				if { $ifaces != {} } {
					try {
						invokeNodeProc $node_id "nodeLogIfacesCreate" $eid $node_id $ifaces
					} on error err {
						return -code error "Error in '[getNodeType $node_id].nodeLogIfacesCreate $eid $node_id $ifaces': $err"
					}

					pipesExec ""

					set msg "Creating"
				} else {
					set msg "No available"
				}
			}

			incr batchStep

			updateProgressBar $w 1 "$msg logical ifaces on node [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $create_nodes_ifaces_count "clean_statline"

		statline "Waiting for logical interfaces on $create_nodes_ifaces_count node(s) to be created..."
	}

	set elem_type "lifaces"
	set elems [dict keys $create_nodes_ifaces]
	set elems_count $create_nodes_ifaces_count
	set elems_left $elems
	set nodes_ifaces $create_nodes_ifaces
	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesIfacesConfigure"
	set condition "lifaces_creating"
	set check_proc [list invokeNodeProc \$elem "nodePhysIfacesCreate_check" \$eid \$elem \$ifaces]
	set msg_template "Node \[getNodeName \$elem] logical ifaces creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesIfacesConfigure { all_dict w } {
	set configure_nodes_ifaces [dictGet $all_dict "configure_nodes_ifaces"]
	set configure_nodes_ifaces_count [dictGet $all_dict "configure_nodes_ifaces_count"]

	statline "Configuring interfaces on node(s)..."
	if { $configure_nodes_ifaces_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0
		pipesCreate
		dict for {node_id ifaces} $configure_nodes_ifaces {
			displayBatchProgress $batchStep $configure_nodes_ifaces_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				if { $ifaces == "*" } {
					set ifaces [allIfcList $node_id]
				}

				if { $ifaces != {} } {
					# skip 'direct link' and UNASSIGNED stolen interfaces
					foreach iface_id $ifaces {
						set this_link_id [getIfcLink $node_id $iface_id]
						if {
							! [isRunningNodeIface $node_id $iface_id] ||
							[isErrorNodeIface $node_id $iface_id]
						} {
							set ifaces [removeFromList $ifaces $iface_id]
						}
					}

					if { $ifaces != {} } {
						try {
							invokeNodeProc $node_id "nodeIfacesConfigure" $eid $node_id $ifaces
						} on error err {
							return -code error "Error in '[getNodeType $node_id].nodeIfacesConfigure $eid $node_id $ifaces': $err"
						}
					}
				}

				if { $ifaces != {} } {
					pipesExec ""

					set msg "Configuring"
				} else {
					set msg "No available"
				}
			}

			incr batchStep

			updateProgressBar $w 1 "$msg interfaces on node [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $configure_nodes_ifaces_count "clean_statline"
		statline "Waiting for interface configuration on $configure_nodes_ifaces_count node(s)..."
	}

	set elem_type "ifaces"
	set elems [dict keys $configure_nodes_ifaces]
	set elems_count $configure_nodes_ifaces_count
	set elems_left $elems
	set nodes_ifaces $configure_nodes_ifaces
	set t_start [clock milliseconds]
	set timeout [getTimeout "ifacesconf_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_linksCreate"
	set condition "ifaces_configuring"
	set check_proc [list invokeNodeProc \$elem "nodeIfacesConfigure_check" \$eid \$elem \$ifaces]
	set msg_template "Node \[getNodeName \$elem] ifaces configuration %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc isLinkCreated { eid link_id } {
	global isOSlinux isOSfreebsd

	set timeout [getTimeout "nodecreate_timeout"]

	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
	if {
		([getLinkDirect $link_id] ||
		"wlan" in "[getNodeType $node1_id] [getNodeType $node2_id]") &&
		([isRunningNodeIface $node1_id $iface1_id] && [isRunningNodeIface $node2_id $iface2_id])
	} {
		# TODO?
		removeStateLink $link_id "error creating"
		addStateLink $link_id "running"

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

	set created [isOk $cmds]
	if { $created } {
		removeStateLink $link_id "error creating"
		addStateLink $link_id "running"
	} else {
		addStateLink $link_id "error"
	}

	return $created
}

proc execute_linksCreate { all_dict w } {
	set instantiate_links [dictGet $all_dict "instantiate_links"]
	set links_count [dictGet $all_dict "links_count"]

	statline "Creating links..."
	if { $links_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach link_id $instantiate_links {
			lassign [getLinkPeers $link_id] node1_id node2_id
			lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

			displayBatchProgress $batchStep $links_count

			if {
				[isRunningNodeIface $node1_id $iface1_id] &&
				[isRunningNodeIface $node2_id $iface2_id]
			} {
				try {
					createLinkBetween $node1_id $node2_id $iface1_id $iface2_id $link_id
				} on error err {
					return -code error "Error in 'createLinkBetween $node1_id $node2_id $iface1_id $iface2_id $link_id': $err"
				}

				set msg "Creating"
			} else {
				set msg "Skipping"
			}

			incr batchStep

			updateProgressBar $w 1 "$msg link $link_id"
		}
		pipesExec ""
		pipesClose

		displayBatchProgress $batchStep $links_count "clean_statline"

		statline "Waiting for $links_count link(s) to be created..."
	}

	set elem_type "links"
	set elems $instantiate_links
	set elems_count $links_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_linksConfigure"
	set condition "creating"
	set check_proc [list isLinkCreated \$eid \$elem]
	set msg_template "Link \$elem creation %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc isLinkConfigured { eid link_id } {
	# TODO: check link configuration
	return true
}

proc execute_linksConfigure { all_dict w } {
	set configure_links [dictGet $all_dict "configure_links"]
	set configure_links_count [dictGet $all_dict "configure_links_count"]

	statline "Configuring links..."
	if { $configure_links_count > 0 } {
		set batchStep 0

		pipesCreate
		foreach link_id $configure_links {
			lassign [getLinkPeers $link_id] node1_id node2_id
			lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

			displayBatchProgress $batchStep $configure_links_count

			if {
				[isRunningLink $link_id] &&
				! [getLinkDirect $link_id] &&
				[isRunningNodeIface $node1_id $iface1_id] &&
				[isRunningNodeIface $node2_id $iface2_id]
			} {
				try {
					configureLinkBetween $node1_id $node2_id $iface1_id $iface2_id $link_id
				} on error err {
					return -code error "Error in 'configureLinkBetween $node1_id $node2_id $iface1_id $iface2_id $link_id': $err"
				}

				set msg "Configuring"
			} else {
				set msg "Skipping"
			}

			incr batchStep

			updateProgressBar $w 1 "$msg link $link_id"
		}
		pipesExec ""
		pipesClose

		displayBatchProgress $batchStep $configure_links_count "clean_statline"

		statline "Waiting for $configure_links_count link(s) to be configured..."
	}

	set elem_type "links"
	set elems $configure_links
	set elems_count $configure_links_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodecreate_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_nodesConfigure"
	set condition "creating"
	set check_proc [list isLinkConfigured \$eid \$elem]
	set msg_template "Link \$elem configuration %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_nodesConfigure { all_dict w } {
	set configure_nodes [dictGet $all_dict "configure_nodes"]
	set configure_nodes_count [dictGet $all_dict "configure_nodes_count"]

	statline "Starting services for LINKINST hook..."
	if { $configure_nodes_count > 0 } {
		services start "LINKINST" "bkg" $configure_nodes
	}

	statline "Configuring node(s)..."
	if { $configure_nodes_count > 0 } {
		set eid [getFromRunning "eid"]

		set batchStep 0

		pipesCreate
		foreach node_id $configure_nodes {
			displayBatchProgress $batchStep $configure_nodes_count

			if { ! [isRunningNode $node_id] } {
				set msg "Skipping"
			} else {
				set msg "Starting"
				try {
					invokeNodeProc $node_id "nodeConfigure" $eid $node_id
				} on error err {
					return -code error "Error in '[getNodeType $node_id].nodeConfigure $eid $node_id': $err"
				}

				pipesExec ""
			}

			incr batchStep

			updateProgressBar $w 1 "$msg configuration on node [getNodeName $node_id]"
		}
		pipesClose

		displayBatchProgress $batchStep $configure_nodes_count "clean_statline"

		statline "Waiting for configuration on $configure_nodes_count node(s)..."
	}

	set elem_type "nodes"
	set elems $configure_nodes
	set elems_count $configure_nodes_count
	set elems_left $elems
	set nodes_ifaces {}
	set t_start [clock milliseconds]
	set timeout [getTimeout "nodeconf_timeout"]
	# ignore first run when checking for timeout
	set old_left_count -1
	set callback_proc "execute_finishExecution"
	set condition "node_configuring"
	set check_proc [list invokeNodeProc \$elem "nodeConfigure_check" \$eid \$elem]
	set msg_template "Node \[getNodeName \$elem] configuration %msg"
	executeWait \
		$all_dict \
		$elem_type \
		$elems \
		$elems_count \
		$elems_left \
		$nodes_ifaces \
		$w \
		$t_start \
		$timeout \
		$old_left_count \
		$callback_proc \
		$condition \
		$check_proc \
		$msg_template
}

proc execute_finishExecution { all_dict w } {
	global gui execMode

	set eid [getFromRunning "eid"]

	set execute [dictGet $all_dict "execute"]

	set configure_nodes [dictGet $all_dict "configure_nodes"]
	set configure_nodes_count [dictGet $all_dict "configure_nodes_count"]

	statline "Starting services for NODECONF hook..."
	if { $configure_nodes_count > 0 } {
		services start "NODECONF" "bkg" $configure_nodes
	}

	set configure_nodes_ifaces [dictGet $all_dict "configure_nodes_ifaces"]
	set configure_nodes_ifaces_count [dictGet $all_dict "configure_nodes_ifaces_count"]

	set t_stop [clock milliseconds]
	if { $configure_nodes_ifaces_count > 0 } {
		statline "Checking for errors on $configure_nodes_ifaces_count node(s) interfaces..."
		checkForErrorsIfaces [lsort -unique [dict keys $configure_nodes_ifaces]] $configure_nodes_ifaces_count $w
	}

	if { $configure_nodes_count > 0 } {
		statline "Checking for errors on $configure_nodes_count node(s)..."
		checkForErrors [lsort -unique $configure_nodes] $configure_nodes_count $w
	}

	set t_diff [expr [clock milliseconds] - $t_stop]

	finishExecuting 1 "" $w

	if { ! $execute } {
		if { [getFromRunning "auto_execution"] } {
			createExperimentFiles $eid
		}
	}
	createRunningVarsFile $eid

	set t_start [dictGet $all_dict "t_start"]
	set all_nodes_count [dictGet $all_dict "all_nodes_count"]
	set links_count [dictGet $all_dict "links_count"]

	statline "Network topology instantiated in [expr ([clock milliseconds] - $t_diff - $t_start)/1000.0] seconds ($all_nodes_count nodes and $links_count links)."

	if { ! $gui || $execMode == "batch" } {
		sputs "Experiment ID = $eid"
	}

	# NOTE: this needs to be here, to trigger the vwait for batch mode
	set execMode $execMode
}

proc checkForErrors { nodes nodes_count w } {
	global execMode gui

	set eid [getFromRunning "eid"]

	set batchStep 0
	set err_nodes ""
	set skip_nodes {}
	set timeout_nodes {}
	for {set pending_nodes $nodes} {$pending_nodes != ""} {} {
		set node_id [lindex $pending_nodes 0]
		set pending_nodes [removeFromList $pending_nodes $node_id]

		if { ! [isRunningNode $node_id] } {
			lappend skip_nodes $node_id
			set err false
			set msg "skipped error check"
		} elseif { "node_configuring" in [getStateNode $node_id] } {
			lappend timeout_nodes $node_id
			set err false
			set msg "config timeout"
		} else {
			set err [invokeNodeProc $node_id "isNodeError" $eid $node_id]
			if { $err == "timeout" } {
				lappend pending_nodes $node_id
				continue
			} elseif { $err == "" } {
				set err false
			}

			if { $err } {
				set msg "error found"
				append err_nodes "[getNodeName $node_id] ($node_id)\n"
			} else {
				set msg "checked"
			}
		}

		incr batchStep
		displayBatchProgress $batchStep $nodes_count

		updateProgressBar $w 1 "Node [getNodeName $node_id] $msg"
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count "clean_statline"
	}

	if { $skip_nodes != {} } {
		set skip_err_nodes ""
		foreach node_id $skip_nodes {
			set err_msg [getStateErrorMsgNode $node_id]
			if { $err_msg != "" } {
				set err_msg " - $err_msg"
			}
			append skip_err_nodes "[getNodeName $node_id] ($node_id)$err_msg\n"
		}

		set skip_err_nodes [string trimright $skip_err_nodes ", "]
		set msg "Issues encountered while creating nodes:\n"
		append msg "$skip_err_nodes\n"
		append msg "Terminate the experiment and check the output in debug mode "
		append msg "(run IMUNES with -d)."

		if { $gui && $execMode != "batch" } {
			after idle {.dialog1.msg configure -wraplength 6i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}

	if { $timeout_nodes != "" } {
		set skip_err_nodes ""
		foreach node_id $timeout_nodes {
			append skip_err_nodes "[getNodeName $node_id] ($node_id)\n"
		}

		set msg "Timeout detected while configuring nodes:\n"
		append msg "$skip_err_nodes\n"
		append msg "Check their err.log, out.log and boot.conf (or "
		append msg "custom.conf) files in /var/imunes/*/*/."

		if { $gui && $execMode != "batch" } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}

	if { $err_nodes != "" } {
		set msg "Issues encountered while configuring nodes:\n"
		append msg "$err_nodes\n"
		append msg "Check their err.log, out.log and boot.conf (or "
		append msg "custom.conf) files in /var/imunes/*/*/."

		if { $gui && $execMode != "batch" } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}
}

proc checkForErrorsIfaces { nodes nodes_count w } {
	global execMode err_skip_nodesifaces gui

	set eid [getFromRunning "eid"]

	set batchStep 0
	set err_nodes ""
	set timeout_nodes {}
	for {set pending_nodes $nodes} {$pending_nodes != ""} {} {
		set node_id [lindex $pending_nodes 0]
		set pending_nodes [removeFromList $pending_nodes $node_id]

		if {
			! [isRunningNode $node_id] ||
			[allIfcList $node_id] == {}
		} {
			set err false
			set msg "skipped error check"
		} elseif { "ifaces_configuring" in [getStateNode $node_id] } {
			lappend timeout_nodes $node_id
			set err false
			set msg "config timeout"
		} else {
			set err [invokeNodeProc $node_id "isNodeErrorIfaces" $eid $node_id]
			if { $err == "timeout" } {
				lappend pending_nodes $node_id
				continue
			} elseif { $err == "" } {
				set err false
			}

			if { $err } {
				set msg "error found"
				append err_nodes "[getNodeName $node_id] ($node_id)\n"
			} else {
				set msg "checked"
			}
		}

		incr batchStep
		displayBatchProgress $batchStep $nodes_count

		updateProgressBar $w 1 "Interfaces on node [getNodeName $node_id] $msg"
	}

	if { $nodes_count > 0 } {
		displayBatchProgress $batchStep $nodes_count "clean_statline"
	}

	if { $timeout_nodes != "" } {
		set skip_err_nodes ""
		foreach node_id $timeout_nodes {
			append skip_err_nodes "[getNodeName $node_id] ($node_id)\n"
		}

		set msg "Timeout detected while configuring node interfaces:\n"
		append msg "$skip_err_nodes\n"
		append msg "Check their err_ifaces.log, out_ifaces.log and "
		append msg "boot_ifaces.conf (or custom_ifaces.conf) files in /var/imunes/*/*/."

		if { $gui && $execMode != "batch" } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}

	if { $err_nodes != "" } {
		set msg "Issues encountered while configuring interfaces on nodes:\n"
		append msg "$err_nodes\n"
		append msg "Check their err_ifaces.log, out_ifaces.log and "
		append msg "boot_ifaces.conf (or custom_ifaces.conf) files in /var/imunes/*/*/."

		if { $gui && $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES warning" \
				"$msg" \
				info 0 Dismiss
		} else {
			sputs stderr "\nIMUNES warning - $msg\n"
		}
	}
}

proc finishExecuting { status msg w } {
	upvar 0 ::loop::state loop_state

	global progressbarCount execMode gui

	set vars "instantiate_nodes create_nodes_ifaces instantiate_links \
		configure_links configure_nodes_ifaces configure_nodes"
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
				"$msg \nTerminate the experiment and report the bug!" info 0 Dismiss
		}

		redrawAll
	}

	set loop_state "null"
}
