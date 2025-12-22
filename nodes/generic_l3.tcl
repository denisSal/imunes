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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

proc genericL3.netlayer {} {
	return NETWORK
}

proc genericL3.virtlayer {} {
	return VIRTUALIZED
}

proc genericL3.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id $node_id
	setNodeAutoDefaultRoutesStatus $node_id "enabled"

	set logiface_id [newLogIface $node_id "lo"]
	setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
	setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

proc genericL3.confNewIfc { node_id iface_id } {
	autoIPv4addr $node_id $iface_id
	autoIPv6addr $node_id $iface_id
	autoMACaddr $node_id $iface_id
}

proc genericL3.generateConfigIfaces { node_id ifaces } {
	# sort physical ifaces before logical ones (because of vlans)
	set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"

	if { $ifaces == "*" } {
		set ifaces $all_ifaces
	} else {
		set negative_ifaces [removeFromList $all_ifaces $ifaces]
		set ifaces [removeFromList $all_ifaces $negative_ifaces]
	}

	set cfg {}
	foreach iface_id $ifaces {
		set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]

		lappend cfg ""
	}

	return $cfg
}

proc genericL3.generateUnconfigIfaces { node_id ifaces } {
	# sort physical ifaces before logical ones
	set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"

	if { $ifaces == "*" } {
		set ifaces $all_ifaces
	} else {
		set negative_ifaces [removeFromList $all_ifaces $ifaces]
		set ifaces [removeFromList $all_ifaces $negative_ifaces]
	}

	set cfg {}
	foreach iface_id $ifaces {
		set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]

		lappend cfg ""
	}

	return $cfg
}

proc genericL3.generateConfig { node_id } {
	set cfg {}

	if {
		[getNodeCustomEnabled $node_id] != true ||
		[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] in "\"\" DISABLED"
	} {
		set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id]]
		set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id]]

		lappend cfg ""
	}

	set subnet_gws {}
	set nodes_l2data [dict create]
	if { [getNodeAutoDefaultRoutesStatus $node_id] == "enabled" } {
		lassign [getDefaultGateways $node_id $subnet_gws $nodes_l2data] my_gws subnet_gws nodes_l2data
		lassign [getDefaultRoutesConfig $node_id $my_gws] all_routes4 all_routes6

		setDefaultIPv4routes $node_id $all_routes4
		setDefaultIPv6routes $node_id $all_routes6
	} else {
		setDefaultIPv4routes $node_id {}
		setDefaultIPv6routes $node_id {}
	}

	set cfg [concat $cfg [nodeCfggenAutoRoutes4 $node_id]]
	set cfg [concat $cfg [nodeCfggenAutoRoutes6 $node_id]]

	lappend cfg ""

	return $cfg
}

proc genericL3.generateUnconfig { node_id } {
	set cfg {}

	set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id]]
	set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id]]

	lappend cfg ""

	set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id]]
	set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id]]

	lappend cfg ""

	return $cfg
}

proc genericL3.ifacePrefix {} {
	return "eth"
}

proc genericL3.IPAddrRange {} {
	return 20
}

proc genericL3.bootcmd { node_id } {
	return "/bin/sh"
}

proc genericL3.shellcmds {} {
	return "csh bash sh tcsh"
}

proc genericL3.getPrivateNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid-$node_id
	}

	if { $isOSfreebsd } {
		return $eid.$node_id
	}
}

proc genericL3.getPublicNs { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		return $eid
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc genericL3.getHookData { node_id iface_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		# public part of veth pair
		set public_elem "$node_id-$iface_id"
		set hook_name ""
	}

	if { $isOSfreebsd } {
		# name of public netgraph peer
		set public_elem "$node_id-$iface_id"
		set hook_name "ether"
	}

	return [list $public_elem $hook_name]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

proc genericL3.prepareSystem {} {
}

proc genericL3.nodeCreate { eid node_id } {
	global isOSlinux isOSfreebsd

	set VROOTDIR [getVrootDir]
	set VROOT_RUNTIME $VROOTDIR/$eid/$node_id

	if { $isOSlinux } {
		# prepare filesystem for node
		pipesExec "mkdir -p $VROOT_RUNTIME &" "hold"

		# create node container
		global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC

		set os_node_id "$eid.$node_id"

		set network "imunes-bridge"
		#if { [getNodeDockerAttach $node_id] == "true" } {
		#	set network "bridge"
		#}

		set vroot [getNodeCustomImage $node_id]
		if { $vroot == "" } {
			# use default IMUNES docker image
			set vroot $VROOT_MASTER
		}

		if { $ULIMIT_FILE != "" } {
			set ulimit_file_str "--ulimit nofile=$ULIMIT_FILE"
		} else {
			set ulimit_file_str ""
		}

		if { $ULIMIT_PROC != "" } {
			set ulimit_proc_str "--ulimit nproc=$ULIMIT_PROC"
		} else {
			set ulimit_proc_str ""
		}

		set docker_cmd "docker run --detach --init --tty \
			--privileged --cap-add=ALL --net=$network \
			--name $os_node_id --hostname=[getNodeName $node_id] \
			--volume /tmp/.X11-unix:/tmp/.X11-unix \
			--sysctl net.ipv6.conf.all.disable_ipv6=0 \
			$ulimit_file_str $ulimit_proc_str $vroot"

		dputs "Node $node_id -> '$docker_cmd'"

		pipesExec "$docker_cmd" "hold"

		return
	}

	if { $isOSfreebsd } {
		global vroot_unionfs vroot_linprocfs devfs_number

		# Prepare a copy-on-write filesystem root
		if { $vroot_unionfs } {
			# UNIONFS
			set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
			set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

			pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
			pipesExec "mkdir -p $VROOT_OVERLAY" "hold"

			set vroot [lindex [split [getNodeCustomImage $node_id] " "] end]
			if { $vroot == "" } {
				set vroot "$VROOTDIR/vroot"
			}

			pipesExec "mount_nullfs -o ro $vroot $VROOT_RUNTIME" "hold"
			pipesExec "mount_unionfs -o noatime $VROOT_OVERLAY $VROOT_RUNTIME" "hold"
		} else {
			# ZFS
			set VROOT_ZFS vroot/$eid/$node_id
			set VROOT_RUNTIME /$VROOT_ZFS
			set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

			set snapshot [getNodeSnapshot $node_id]
			if { $snapshot == "" } {
				set snapshot "vroot/vroot@clean"
			}

			pipesExec "zfs clone $snapshot $VROOT_ZFS" "hold"
		}

		if { $vroot_linprocfs } {
			pipesExec "mount -t linprocfs linprocfs $VROOT_RUNTIME/compat/linux/proc" "hold"
			#HACK - linux_sun_jdk16 - java hack, won't work if proc isn't accessed
			#before execution, so we need to cd to it.
			pipesExec "cd $VROOT_RUNTIME/compat/linux/proc" "hold"
		}

		# Mount and configure a restricted /dev
		pipesExec "mount -t devfs devfs $VROOT_RUNTIME_DEV" "hold"
		pipesExec "devfs -m $VROOT_RUNTIME_DEV ruleset $devfs_number" "hold"
		pipesExec "devfs -m $VROOT_RUNTIME_DEV rule applyset" "hold"

		# create node jail
		set jail_cmd "jail -c name=$eid.$node_id path=$VROOT_RUNTIME securelevel=1 \
			host.hostname=\"[getNodeName $node_id]\" vnet persist"

		dputs "Node $node_id -> '$jail_cmd'"

		pipesExec "$jail_cmd" "hold"

		return
	}
}

proc genericL3.nodeCreate_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodecreate_timeout

	if { [getFromRunning "${node_id}_running"] == "true" } {
		return true
	}

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		set cmds "docker inspect --format '{{.State.Running}}' $os_node_id"
	}

	if { $isOSfreebsd } {
		set cmds "jls -j $os_node_id"
	}

	if { $nodecreate_timeout >= 0 } {
		set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
	}

	try {
		rexec $cmds
	} on ok status {
		if { $isOSlinux } {
			return [string match "*true*" $status]
		}

		if { $isOSfreebsd } {
			return true
		}
	} on error {} {
		return false
	}

	return false
}

proc genericL3.nodeNamespaceSetup { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		if { [getNodeDockerAttach $node_id] != "true" } {
			pipesExec "docker network disconnect imunes-bridge $eid.$node_id &" "hold"
		}

		# VIRTUALIZED nodes use docker netns
		set cmds "docker_ns=\$(docker inspect -f '{{.State.Pid}}' $eid.$node_id)"
		set cmds "$cmds; ip netns del \$docker_ns > /dev/null 2>/dev/null"
		set cmds "$cmds; ip netns attach $eid-$node_id \$docker_ns"
		set cmds "$cmds; docker exec -d $eid.$node_id umount /etc/resolv.conf /etc/hosts"

		pipesExec "sh -c \'$cmds\' &" "hold"

		return
	}

	if { $isOSfreebsd } {
		# nothing
		return
	}
}

proc genericL3.nodeNamespaceSetup_check { eid node_id } {
	# same as L2
	return [genericL2.nodeNamespaceSetup_check $eid $node_id]
}

proc genericL3.nodeInitConfigure { eid node_id } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		array set sysctl_icmp {
			net.ipv4.icmp_ratelimit					0
			net.ipv4.icmp_echo_ignore_broadcasts	1
		}

		foreach {name val} [array get sysctl_icmp] {
			lappend cmd "sysctl $name=$val"
		}
		set cmds [join $cmd "; "]

		pipesExec "docker exec -d $eid.$node_id sh -c '$cmds ; touch /tmp/init'" "hold"

		return
	}

	if { $isOSfreebsd } {
		array set sysctl_icmp {
			net.inet.icmp.bmcastecho		1
			net.inet.icmp.icmplim			0
			net.inet.ip.maxfragsperpacket	64000
		}

		foreach {name val} [array get sysctl_icmp] {
			lappend cmd "sysctl $name=$val"
		}
		set cmds [join $cmd "; "]

		pipesExec "jexec $eid.$node_id sh -c '$cmds ; touch /tmp/init'" "hold"

		return
	}
}

proc genericL3.nodeInitConfigure_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodecreate_timeout

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		set cmds "docker exec $os_node_id ls /tmp/init >/dev/null"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $os_node_id rm /tmp/init >/dev/null"
	}

	if { $nodecreate_timeout >= 0 } {
		set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

proc genericL3.nodePhysIfacesCreate { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		# Create "physical" network interfaces
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"

			set iface_name [getIfcName $node_id $iface_id]

			if { [getIfcType $node_id $iface_id] == "stolen" } {
				# private hook is interface name in this case
				captureExtIfcByName $eid $iface_name $node_id
			} else {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -

				# Create a veth pair - private hook in node NS and public hook
				# in the experiment NS
				createNsVethPair $iface_name $private_ns $public_iface $public_ns
			}
		}

		pipesExec ""

		return
	}

	if { $isOSfreebsd } {
		set os_node_id "$eid.$node_id"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		# Create "physical" network interfaces
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"

			set iface_name [getIfcName $node_id $iface_id]

			if { [getIfcType $node_id $iface_id] == "stolen" } {
				# private hook is interface name in this case
				captureExtIfcByName $eid $iface_name $node_id
			} else {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] ng_peer -

				# save newly created ngnodeX into a shell variable ifid and
				# rename the ng node to $ng_peer (unique to this experiment)
				set cmds "ifid=\$(printf \"mkpeer . eiface $ng_peer ether \n"
				set cmds "$cmds show .:$ng_peer\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
				set cmds "$cmds; jexec $eid ngctl name \$ifid: $ng_peer"
				set cmds "$cmds; jexec $eid ifconfig \$ifid name $ng_peer"

				pipesExec $cmds "hold"
				pipesExec "jexec $eid ifconfig $ng_peer vnet $node_id" "hold"
				pipesExec "jexec $os_node_id ifconfig $ng_peer name $iface_name" "hold"

				set ether [getIfcMACaddr $node_id $iface_id]
				if { $ether == "" } {
					set ether [autoMACaddr $node_id $iface_id]
				}

				global ifc_dad_disable
				if { $ifc_dad_disable } {
					pipesExec "jexec $os_node_id sysctl net.inet6.ip6.dad_count=0" "hold"
				}

				pipesExec "jexec $os_node_id ifconfig $iface_name link $ether" "hold"
			}
		}

		pipesExec ""

		return
	}
}

proc genericL3.nodePhysIfacesCreate_check { eid node_id ifaces } {
	# same as L2
	return [genericL2.nodePhysIfacesCreate_check $eid $node_id $ifaces]
}

proc genericL3.nodePhysIfacesCreateDirect { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		set private_ns [getNodeNetns $eid $node_id]

		# Create "physical" network interfaces
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id == "" || ! [getLinkDirect $this_link_id] } {
				continue
			}

			lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
			if { [getFromRunning "${peer_id}_running"] ni "true" } {
				# peer node is not alive, skip
				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"
			if { [getFromRunning "${peer_id}|${peer_iface_id}_running"] in "true creating" } {
				# skip creating our iface since it's already being created by peer
				continue
			}

			setToRunning "${peer_id}|${peer_iface_id}_running" "creating"

			set peer_type [getNodeType $peer_id]
			if { $peer_type == "rj45" } {
				# rj45 nodes will deal with the creation of our iface
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]

			set other_netns [invokeNodeProc $peer_id "getPrivateNs" $eid $peer_id]
			set other_iface_name [getIfcName $peer_id $peer_iface_id]

			# Create a veth pair - private hook in node NS and other hook
			# in the other node NS
			createNsVethPair $iface_name $private_ns $other_iface_name $other_netns

			if { [invokeNodeProc $peer_id "virtlayer"] == "NATIVE" } {
				setNsIfcMaster $other_netns $other_iface_name $peer_id "up"
			}
		}

		pipesExec ""

		return
	}

	if { $isOSfreebsd } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		# Create "physical" network interfaces
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id == "" || ! [getLinkDirect $this_link_id] } {
				continue
			}

			setToRunning "${node_id}|${iface_id}_running" "creating"

			set iface_name [getIfcName $node_id $iface_id]

			if { [getIfcType $node_id $iface_id] == "stolen" } {
				# private hook is interface name in this case
				captureExtIfcByName $eid $iface_name $node_id
			} else {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] ng_peer -

				# save newly created ngnodeX into a shell variable ifid and
				# rename the ng node to $ng_peer (unique to this experiment)
				set cmds "ifid=\$(printf \"mkpeer . eiface $ng_peer ether \n"
				set cmds "$cmds show .:$ng_peer\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
				set cmds "$cmds; jexec $eid ngctl name \$ifid: $ng_peer"
				set cmds "$cmds; jexec $eid ifconfig \$ifid name $ng_peer"

				pipesExec $cmds "hold"
				pipesExec "jexec $eid ifconfig $ng_peer vnet $node_id" "hold"
				pipesExec "jexec $os_node_id ifconfig $ng_peer name $iface_name" "hold"

				set ether [getIfcMACaddr $node_id $iface_id]
				if { $ether == "" } {
					set ether [autoMACaddr $node_id $iface_id]
				}

				global ifc_dad_disable
				if { $ifc_dad_disable } {
					pipesExec "jexec $os_node_id sysctl net.inet6.ip6.dad_count=0" "hold"
				}

				pipesExec "jexec $os_node_id ifconfig $iface_name link $ether" "hold"
			}
		}

		pipesExec ""

		return
	}
}

proc genericL3.nodeLogIfacesCreate { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		set cmds ""
		foreach iface_id $ifaces {
			if { ! [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			switch -exact [getIfcType $node_id $iface_id] {
				vlan {
					set tag [getIfcVlanTag $node_id $iface_id]
					set dev [getIfcVlanDev $node_id $iface_id]
					if { $tag != "" && $dev != "" } {
						append cmds "[getVlanTagIfcCmd $iface_name $dev $tag]\n"
						setToRunning "${node_id}|${iface_id}_running" "creating"
					} else {
						setToRunning "${node_id}|${iface_id}_running" "false"
					}
				}
				lo {
					setToRunning "${node_id}|${iface_id}_running" "creating"
					if { $iface_name != "lo0" } {
						append cmds "ip link add $iface_name type dummy\n"
						append cmds "ip link set $iface_name up\n"
					} else {
						append cmds "ip link set dev lo down 2>/dev/null\n"
						append cmds "ip link set dev lo name lo0 2>/dev/null\n"
						append cmds "ip a flush lo0 2>/dev/null\n"
					}
				}
				default {
					setToRunning "${node_id}|${iface_id}_running" "false"
				}
			}
		}

		pipesExec "docker exec -d $os_node_id sh -c '$cmds'" "hold"

		return
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			if { ! [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			switch -exact [getIfcType $node_id $iface_id] {
				vlan {
					set tag [getIfcVlanTag $node_id $iface_id]
					set dev [getIfcVlanDev $node_id $iface_id]
					if { $tag != "" && $dev != "" } {
						pipesExec "jexec $os_node_id [getVlanTagIfcCmd $iface_name $dev $tag]" "hold"
						setToRunning "${node_id}|${iface_id}_running" "creating"
					} else {
						setToRunning "${node_id}|${iface_id}_running" "false"
					}
				}
				lo {
					setToRunning "${node_id}|${iface_id}_running" "creating"
					if { $iface_name != "lo0" } {
						pipesExec "jexec $os_node_id ifconfig $iface_name create" "hold"
					}
				}
				default {
					setToRunning "${node_id}|${iface_id}_running" "false"
				}
			}
		}

		return
	}
}

proc genericL3.nodeIfacesConfigure { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global ifacesconf_timeout

	set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		set bootcmd [getNodeCustomConfigCommand $node_id "IFACES_CONFIG" $custom_selected]
		set bootcfg [getNodeCustomConfig $node_id "IFACES_CONFIG" $custom_selected]
		set confFile "custom_ifaces.conf"
	} else {
		set bootcfg [join [invokeNodeProc $node_id "generateConfigIfaces" $node_id $ifaces] "\n"]
		set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
		set confFile "boot_ifaces.conf"
	}

	set startup_fname "/IFACES_CONFIG.pid"
	writeDataToNodeFile $node_id $startup_fname ""

	set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg

	set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
	set cmds "$cmds $bootcmd /$confFile > /out_ifaces.log 2> /err_ifaces.log ;"

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		pipesExec "docker exec -d $os_node_id sh -c '$cmds'" "hold"

		return
	}

	if { $isOSfreebsd } {
		if { $ifacesconf_timeout >= 0 } {
			pipesExec "timeout --foreground $ifacesconf_timeout jexec $os_node_id sh -c '$cmds'" "hold"
		} else {
			pipesExec "jexec $os_node_id sh -c '$cmds'" "hold"
		}

		return
	}
}

proc genericL3.nodeIfacesConfigure_check { eid node_id ifaces } {
	global isOSlinux isOSfreebsd
	global ifacesconf_timeout

	set os_node_id "$eid.$node_id"
	set startup_fname "/IFACES_CONFIG.pid"
	set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"

	if { $isOSlinux } {
		set cmds "docker exec -t $os_node_id sh -c '$cmds'"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $os_node_id sh -c '$cmds'"
	}

	if { $ifacesconf_timeout >= 0 } {
		set cmds "timeout [expr $ifacesconf_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

proc genericL3.attachToLink { node_id iface_id link_id direct } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		if { $direct } {
			# link already created, except in some cases

			return
		}

		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] public_iface -
		setNsIfcMaster [getFromRunning "eid"] $public_iface $link_id "up"

		return
	}

	if { $isOSfreebsd } {
		# nothing to do, createLinkBetween does everything
		return
	}
}

proc genericL3.detachFromLink { node_id iface_id link_id { direct "" } } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		if { $direct != "" } {
			# link already destroyed, except in some cases

			return
		}

		return
	}

	if { $isOSfreebsd } {
		# nothing to do, destroyLinkBetween does everything
		return
	}
}

proc genericL3.nodeConfigure { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodeconf_timeout

	set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		set bootcmd [getNodeCustomConfigCommand $node_id "NODE_CONFIG" $custom_selected]
		set bootcfg [getNodeCustomConfig $node_id "NODE_CONFIG" $custom_selected]
		set bootcfg "$bootcfg\n[join [invokeNodeProc $node_id "generateConfig" $node_id] "\n"]"
		set confFile "custom.conf"
	} else {
		set bootcfg [join [invokeNodeProc $node_id "generateConfig" $node_id] "\n"]
		set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
		set confFile "boot.conf"
	}

	generateHostsFile $node_id

	set startup_fname "/NODE_CONFIG.pid"
	writeDataToNodeFile $node_id $startup_fname ""

	set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg

	set cmds "rm -f /out.log /err.log ;"
	set cmds "$cmds $bootcmd /$confFile > /out.log 2> /err.log ;"

	if { $isOSlinux } {
		set os_node_id "$eid.$node_id"

		pipesExec "docker exec -d $os_node_id sh -c '$cmds'" "hold"

		return
	}

	if { $isOSfreebsd } {
		set os_node_id "$eid.$node_id"

		if { $nodeconf_timeout >= 0 } {
			pipesExec "timeout --foreground $nodeconf_timeout jexec $os_node_id sh -c '$cmds'" "hold"
		} else {
			pipesExec "jexec $os_node_id sh -c '$cmds'" "hold"
		}

		return
	}
}

proc genericL3.nodeConfigure_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodeconf_timeout

	set os_node_id "$eid.$node_id"
	set startup_fname "/NODE_CONFIG.pid"
	set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
	if { $isOSlinux } {
		set cmds "docker exec -t $os_node_id sh -c '$cmds'"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $os_node_id sh -c '$cmds'"
	}

	if { $nodeconf_timeout >= 0 } {
		set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc genericL3.nodeIfacesUnconfigure { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		return
	}

	set bootcfg [join [invokeNodeProc $node_id "generateUnconfigIfaces" $node_id $ifaces] "\n"]
	set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
	set confFile "unboot_ifaces.conf"

	set startup_fname "/IFACES_UNCONFIG.pid"
	writeDataToNodeFile $node_id $startup_fname ""

	set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg

	set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
	set cmds "$cmds $bootcmd /$confFile > /out_ifaces.log 2> /err_ifaces.log ;"

	if { $isOSlinux } {
		set os_node_id "$eid.$node_id"

		pipesExec "docker exec -d $os_node_id sh -c '$cmds'" "hold"

		return
	}

	if { $isOSfreebsd } {
		set os_node_id "$eid.$node_id"

		pipesExec "jexec $os_node_id sh -c '$cmds'" "hold"

		return
	}
}

proc genericL3.nodeIfacesUnconfigure_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global skip_nodes ifacesconf_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set os_node_id "$eid.$node_id"
	set startup_fname "/IFACES_UNCONFIG.pid"
	set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
	if { $isOSlinux } {
		set cmds "docker exec -t $os_node_id sh -c '$cmds'"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $os_node_id sh -c '$cmds'"
	}

	if { $ifacesconf_timeout >= 0 } {
		set cmds "timeout [expr $ifacesconf_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

proc genericL3.nodeLogIfacesDestroy { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		foreach iface_id $ifaces {
			if { ! [isIfcLogical $node_id $iface_id] } {
				continue
			}

			# skip lo0 as it cannot be deleted
			if { [getIfcName $node_id $iface_id] == "lo0" } {
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]

			pipesExec "ip -n $private_ns link del $iface_name" "hold"

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}
		}

		return
	}

	if { $isOSfreebsd } {
		set os_node_id "$eid.$node_id"
		foreach iface_id $ifaces {
			if { ! [isIfcLogical $node_id $iface_id] } {
				continue
			}

			# skip lo0 as it cannot be deleted
			if { [getIfcName $node_id $iface_id] == "lo0" } {
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			pipesExec "jexec $os_node_id ifconfig $iface_name destroy" "hold"

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}
		}

		return
	}
}

proc genericL3.nodePhysIfacesDestroy { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		# same as L2
		return [genericL2.nodePhysIfacesDestroy $eid $node_id $ifaces]
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
				continue
			}

			if { [getIfcType $node_id $iface_id] == "stolen" } {
				set iface_name [getIfcName $node_id $iface_id]
				releaseExtIfcByName $eid $iface_name $node_id
			} else {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] ng_peer -

				pipesExec "jexec $eid ngctl rmnode $ng_peer:" "hold"
			}

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}
		}

		return
	}
}

proc genericL3.nodePhysIfacesDestroyDirect { eid node_id ifaces } {
	global isOSlinux isOSfreebsd

	if { $isOSlinux } {
		# same as L2
		return [genericL2.nodePhysIfacesDestroyDirect $eid $node_id $ifaces]
	}

	if { $isOSfreebsd } {
		foreach iface_id $ifaces {
			if { [isIfcLogical $node_id $iface_id] } {
				continue
			}

			set this_link_id [getIfcLink $node_id $iface_id]
			if { $this_link_id == "" || ! [getLinkDirect $this_link_id] } {
				continue
			}

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] ng_peer -
			pipesExec "jexec $eid ngctl rmnode $ng_peer:" "hold"

			if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
				setToRunning "${node_id}|${iface_id}_running" "stopping"
			}
		}

		return
	}
}

proc genericL3.nodeIfacesDestroy_check { eid node_id ifaces } {
	# same as L2
	return [genericL2.nodeIfacesDestroy_check $eid $node_id $ifaces]
}

proc genericL3.nodeUnconfigure { eid node_id } {
	global isOSlinux isOSfreebsd

	set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		return
	}

	set bootcfg [join [invokeNodeProc $node_id "generateUnconfig" $node_id] "\n"]
	set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
	set confFile "unboot.conf"

	set startup_fname "/IFACES_UNCONFIG.pid"
	writeDataToNodeFile $node_id $startup_fname ""

	set cfg "set -x\necho $$ > $startup_fname\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg

	set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
	set cmds "$cmds $bootcmd /$confFile > /out_ifaces.log 2> /err_ifaces.log ;"

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		pipesExec "docker exec -d $os_node_id sh -c '$cmds'" "hold"

		return
	}

	if { $isOSfreebsd } {
		pipesExec "jexec $os_node_id sh -c '$cmds'" "hold"

		return
	}
}

proc genericL3.nodeUnconfigure_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global skip_nodes nodeconf_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set os_node_id "$eid.$node_id"
	set startup_fname "/IFACES_UNCONFIG.pid"
	set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
	if { $isOSlinux } {
		set cmds "docker exec -t $os_node_id sh -c '$cmds'"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $os_node_id sh -c '$cmds'"
	}

	if { $nodeconf_timeout >= 0 } {
		set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

proc genericL3.nodeShutdown { eid node_id } {
	global isOSlinux isOSfreebsd

	killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
	killExtProcess "socat.*$eid/$node_id.*"

	if { $isOSlinux } {
		set os_node_id "$eid.$node_id"

		# kill all processes except pid 1 and its child(ren)
		pipesExec "docker exec -d $os_node_id sh -c 'killall5 -9 -o 1 -o \$(pgrep -P 1) ; touch /tmp/shut'" "hold"

		return
	}

	if { $isOSfreebsd } {
		set os_node_id "$eid.$node_id"

		pipesExec "jexec $os_node_id kill -9 -1 2> /dev/null" "hold"
		pipesExec "jexec $os_node_id tcpdrop -a 2> /dev/null" "hold"

		pipesExec "jexec $os_node_id touch /tmp/shut" "hold"

		return
	}
}

proc genericL3.nodeShutdown_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global skip_nodes nodeconf_timeout

	if { [getFromRunning "${node_id}_running"] == "false" } {
		return true
	}

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set os_node_id "$eid.$node_id"
	set cmds "rm /tmp/shut >/dev/null"
	if { $isOSlinux } {
		set cmds "docker exec $os_node_id $cmds"
	}

	if { $isOSfreebsd } {
		set cmds "jexec $os_node_id $cmds"
	}

	if { $nodeconf_timeout >= 0 } {
		set cmds "timeout [expr $nodeconf_timeout/5.0] $cmds"
	}

	return [isOk $cmds]
}

proc genericL3.nodeDestroy { eid node_id } {
	global isOSlinux isOSfreebsd

	if { [getFromRunning "${node_id}_running"] == "true" } {
		setToRunning "${node_id}_running" "stopping"
	}

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		# remove node virtual interfaces
		pipesExec "docker exec -d $os_node_id sh -c 'for iface in `ls /sys/class/net` ; do ip link del \$iface; done'" "hold"

		# remove node container
		pipesExec "docker kill $os_node_id" "hold"
		pipesExec "docker rm $os_node_id" "hold"

		return
	}

	if { $isOSfreebsd } {
		# remove node virtual interfaces
		pipesExec "jexec $os_node_id sh -c 'for iface in \$(ifconfig -l); do echo \$iface ; ifconfig \$iface destroy ; done'" "hold"

		# remove node jail
		pipesExec "jail -r $os_node_id" "hold"

		return
	}
}

proc genericL3.nodeDestroy_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global nodecreate_timeout

	set os_node_id "$eid.$node_id"
	if { $isOSlinux } {
		set cmds "docker inspect --format '{{.State.Running}}' $os_node_id"
	}

	if { $isOSfreebsd } {
		set cmds "jls -d -j $os_node_id"
	}

	if { $nodecreate_timeout >= 0 } {
		set cmds "timeout [expr $nodecreate_timeout/5.0] $cmds"
	}

	try {
		rexec $cmds
	} on ok {} {
		return false
	} on error status {
		if { $isOSlinux } {
			return [string match -nocase "*Error: No such object: $os_node_id*" $status]
		}

		if { $isOSfreebsd } {
			return true
		}
	}
}

proc genericL3.nodeDestroyFS { eid node_id } {
	global isOSlinux isOSfreebsd

	if { [getFromRunning "${node_id}_running"] == "true" } {
		setToRunning "${node_id}_running" "stopping"
	}

	if { $isOSlinux } {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "ip netns del $private_ns" "hold"

		pipesExec "rm -fr [getVrootDir]/$eid/$node_id" "hold"

		return
	}

	if { $isOSfreebsd } {
		global vroot_unionfs vroot_linprocfs

		set VROOTDIR [getVrootDir]
		set VROOT_RUNTIME $VROOTDIR/$eid/$node_id
		set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
		set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
		pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
		if { $vroot_unionfs } {
			# 1st: unionfs RW overlay
			pipesExec "umount -f $VROOT_RUNTIME" "hold"
			# 2nd: nullfs RO loopback
			pipesExec "umount -f $VROOT_RUNTIME" "hold"
			pipesExec "rm -rf $VROOT_RUNTIME" "hold"
			# 3rd: node unionfs upper
			pipesExec "rm -rf $VROOT_OVERLAY" "hold"
		}

		if { $vroot_linprocfs } {
			pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
		}

		return
	}
}

proc genericL3.nodeDestroyFS_check { eid node_id } {
	global isOSlinux isOSfreebsd
	global skip_nodes

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "stopping delete"
	} {
		return true
	}

	if { $isOSlinux } {
		if { [isOk ip netns exec [getNodeNetns $eid $node_id] true] } {
			return false
		}
	}

	if { [isOk ls -d [getVrootDir]/$eid/$node_id] } {
		return false
	}

	return true
}
