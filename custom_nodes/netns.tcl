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

set MODULE netns
registerModule $MODULE "linux"

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# genericL3.* procedures from nodes/generic_l3.tcl
	namespace import ::genericL3::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "netns"
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	proc checkNodePrerequisites { eid node_id } {
		setStateErrorMsgNode $node_id ""

		set private_ns_exists [invokeNodeProc $node_id "nodeNamespaceSetup_check" $eid $node_id]
		if { $private_ns_exists } {
			addStateNode $node_id "error"
			setStateErrorMsgNode $node_id "Namespace for node '$node_id' in experiment '$eid' already exists!"

			return false
		}

		foreach iface_id [allIfcList $node_id] {
			setStateNodeIface $node_id $iface_id ""
		}

		removeStateNode $node_id "error"

		return true
	}

	proc nodeCreate { eid node_id } {
		addStateNode $node_id "node_creating"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		# prepare filesystem for node
		pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
	}

	proc nodeCreate_check { eid node_id } {
		global nodecreate_timeout

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "ls -d $VROOT_RUNTIME"

		if { $nodecreate_timeout >= 0 } {
			set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
		}

		set created [isOk $cmds]
		if { $created } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $created
	}

	proc nodeNamespaceSetup { eid node_id } {
		return [invokeTypeProc "genericL2" "nodeNamespaceSetup" $eid $node_id]
	}

	proc nodeNamespaceSetup_check { eid node_id } {
		set created [invokeTypeProc "genericL2" "nodeNamespaceSetup_check" $eid $node_id]
		if { $created } {
			if { "ns_creating" in [getStateNode $node_id] } {
				addStateNode $node_id "running"
			}
		} else {
			addStateNode $node_id "error"
		}

		return $created
	}

	proc nodeInitConfigure { eid node_id } {
		return [invokeTypeProc "genericL2" "nodeInitConfigure" $eid $node_id]
	}

	proc nodeInitConfigure_check { eid node_id } {
		return [invokeTypeProc "genericL2" "nodeInitConfigure_check" $eid $node_id]
	}

	proc nodeIfacesConfigure { eid node_id ifaces } {
		global ifacesconf_timeout

		addStateNode $node_id "ifaces_configuring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		foreach iface_id $ifaces {
			if { [isRunningNodeIface $node_id $iface_id] } {
				continue
			}
			set ifaces [removeFromList $ifaces $iface_id]

			if { ! [isErrorNodeIface $node_id $iface_id] } {
				continue
			}

			addStateNodeIface $node_id $iface_id "error"
			if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
				setStateErrorMsgNodeIface $node_id $iface_id "Interface $iface_id '[getIfcName $node_id $iface_id]' not created, skip configuration."
			}
		}

		set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			set bootcmd [getNodeCustomConfigCommand $node_id "IFACES_CONFIG" $custom_selected]
			set bootcfg [getNodeCustomConfig $node_id "IFACES_CONFIG" $custom_selected]
			set confFile "$VROOT_RUNTIME/custom_ifaces.conf"
		} else {
			set bootcfg [join [invokeNodeProc $node_id "generateConfigIfaces" $node_id $ifaces] "\n"]
			set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
			set confFile "$VROOT_RUNTIME/boot_ifaces.conf"
		}

		set startup_fname "$VROOT_RUNTIME/IFACES_CONFIG.pid"
		writeDataToFile $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
		writeDataToFile $confFile $cfg

		set cmds "rm -f $VROOT_RUNTIME/out_ifaces.log $VROOT_RUNTIME/err_ifaces.log ;"
		set cmds "$cmds $bootcmd $confFile > $VROOT_RUNTIME/out_ifaces.log 2> $VROOT_RUNTIME/err_ifaces.log ;"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "ip netns exec $private_ns sh -c '$cmds' &" "hold"
	}

	proc nodeIfacesConfigure_check { eid node_id ifaces } {
		global ifacesconf_timeout

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set startup_fname "$VROOT_RUNTIME/IFACES_CONFIG.pid"
		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"

		set cmds "ip netns exec $private_ns sh -c '$cmds'"

		if { $ifacesconf_timeout >= 0 } {
			set cmds "timeout [expr $ifacesconf_timeout/5.0] $cmds"
		}

		set ifaces_configured [isOk $cmds]
		if { $ifaces_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $ifaces_configured
	}

	proc nodeConfigure { eid node_id } {
		global nodeconf_timeout

		addStateNode $node_id "node_configuring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			set bootcmd [getNodeCustomConfigCommand $node_id "NODE_CONFIG" $custom_selected]
			set bootcfg [getNodeCustomConfig $node_id "NODE_CONFIG" $custom_selected]
			set bootcfg "$bootcfg\n[join [invokeNodeProc $node_id "generateConfig" $node_id] "\n"]"
			set confFile "$VROOT_RUNTIME/custom.conf"
		} else {
			set bootcfg [join [invokeNodeProc $node_id "generateConfig" $node_id] "\n"]
			set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
			set confFile "$VROOT_RUNTIME/boot.conf"
		}

		set startup_fname "$VROOT_RUNTIME/NODE_CONFIG.pid"
		writeDataToFile $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
		writeDataToFile $confFile $cfg

		set cmds "rm -f $VROOT_RUNTIME/out.log $VROOT_RUNTIME/err.log ;"
		set cmds "$cmds $bootcmd $confFile > $VROOT_RUNTIME/out.log 2> $VROOT_RUNTIME/err.log ;"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "ip netns exec $private_ns sh -c '$cmds' &" "hold"
	}

	proc nodeConfigure_check { eid node_id } {
		global nodeconf_timeout

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set startup_fname "$VROOT_RUNTIME/NODE_CONFIG.pid"
		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
		set cmds "ip netns exec $private_ns sh -c '$cmds'"

		if { $nodeconf_timeout >= 0 } {
			set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
		}

		set node_configured [isOk $cmds]
		if { $node_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_configured
	}

	proc isNodeError { eid node_id } {
		global nodeconf_timeout

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		set cmds "test ! -f /err.log || sed \"/^+ /d\" /err.log"
		set cmds "ip netns exec $private_ns sh -c '$cmds'"

		if { $nodeconf_timeout >= 0 } {
			set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
		}

		try {
			rexec $cmds
		} on error {} {
			return "timeout"
		} on ok errlog {
			if { $errlog == "" } {
				return false
			}

			return true
		}
	}

	proc isNodeErrorIfaces { eid node_id } {
		global ifacesconf_timeout

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		set cmds "test ! -f /err_ifaces.log || sed \"/^+ /d\" /err_ifaces.log"
		set cmds "ip netns exec $private_ns sh -c '$cmds'"

		if { $ifacesconf_timeout >= 0 } {
			set cmds "timeout [expr $ifacesconf_timeout/5.0] $cmds"
		}

		try {
			rexec $cmds
		} on error {} {
			return "timeout"
		} on ok errlog {
			if { $errlog == "" } {
				return false
			}

			return true
		}
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
		addStateNode $node_id "node_unconfiguring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			return
		}

		set bootcfg [join [invokeNodeProc $node_id "generateUnconfig" $node_id] "\n"]
		set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
		set confFile "$VROOT_RUNTIME/unboot.conf"

		set startup_fname "$VROOT_RUNTIME/NODE_UNCONFIG.pid"
		writeDataToFile $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
		writeDataToFile $confFile $cfg

		set cmds "rm -f $VROOT_RUNTIME/out_ifaces.log $VROOT_RUNTIME/err_ifaces.log ;"
		set cmds "$cmds $bootcmd /$confFile > $VROOT_RUNTIME/out_ifaces.log 2> $VROOT_RUNTIME/err_ifaces.log ;"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "ip netns exec $private_ns sh -c '$cmds' &" "hold"
	}

	proc nodeUnconfigure_check { eid node_id } {
		global nodeconf_timeout

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set startup_fname "$VROOT_RUNTIME/NODE_UNCONFIG.pid"
		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
		set cmds "ip netns exec $private_ns sh -c '$cmds'"

		if { $nodeconf_timeout >= 0 } {
			set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
		}

		set node_unconfigured [isOk $cmds]
		if { $node_unconfigured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_unconfigured
	}

	proc nodeShutdown { eid node_id } {
		addStateNode $node_id "node_shutting"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
		killExtProcess "socat.*$eid/$node_id.*"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		# kill all processes in netns
		pipesExec "kill -9 \$(ip netns pids $private_ns); ip netns exec $private_ns sh -c 'touch $VROOT_RUNTIME/shut' &" "hold"
	}

	proc nodeShutdown_check { eid node_id } {
		global nodeconf_timeout

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "rm $VROOT_RUNTIME/shut >/dev/null"
		set cmds "ip netns exec $private_ns $cmds"

		if { $nodeconf_timeout >= 0 } {
			set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
		}

		set shut [isOk $cmds]
		if { $shut } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $shut
	}

	proc nodeIfacesUnconfigure { eid node_id ifaces } {
		set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			return
		}

		# skip interfaces in error state
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return
		}

		addStateNode $node_id "ifaces_unconfiguring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set bootcfg [join [invokeNodeProc $node_id "generateUnconfigIfaces" $node_id $ifaces] "\n"]
		set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
		set confFile "$VROOT_RUNTIME/unboot_ifaces.conf"

		set startup_fname "$VROOT_RUNTIME/IFACES_UNCONFIG.pid"
		writeDataToFile $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
		writeDataToFile $confFile $cfg

		set cmds "rm -f $VROOT_RUNTIME/out_ifaces.log $VROOT_RUNTIME/err_ifaces.log ;"
		set cmds "$cmds $bootcmd $confFile > $VROOT_RUNTIME/out_ifaces.log 2> $VROOT_RUNTIME/err_ifaces.log ;"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "ip netns exec $private_ns sh -c '$cmds' &" "hold"
	}

	proc nodeIfacesUnconfigure_check { eid node_id ifaces } {
		global ifacesconf_timeout

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set startup_fname "$VROOT_RUNTIME/IFACES_UNCONFIG.pid"
		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
		set cmds "ip netns exec $private_ns sh -c '$cmds'"

		if { $ifacesconf_timeout >= 0 } {
			set cmds "timeout [expr $ifacesconf_timeout/5.0] $cmds"
		}

		set ifaces_unconfigured [isOk $cmds]
		if { $ifaces_unconfigured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $ifaces_unconfigured
	}

	proc nodeDestroy { eid node_id } {
		return
	}

	proc nodeDestroy_check { eid node_id } {
		return true
	}

	proc nodeDestroyFS { eid node_id } {
		addStateNode $node_id "node_destroying_fs"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "ip netns del $private_ns" "hold"

		pipesExec "rm -fr $VROOT_RUNTIME" "hold"
	}

	proc nodeDestroyFS_check { eid node_id } {
		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id

		set destroyed_ns true
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		if { [isOk ip netns exec $private_ns true] } {
			set destroyed_ns false
		}

		set destroyed_fs true
		if { $destroyed_ns } {
			if { [isOk ls -d $VROOT_RUNTIME] } {
				set destroyed_fs false
			}
		}

		if { $destroyed_fs } {
			removeStateNode $node_id "error running"
		} else {
			addStateNode $node_id "error"
		}

		return $destroyed_fs
	}
}
