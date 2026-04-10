set MODULE qemu

namespace eval ${MODULE}::gui {
	namespace import ::genericL3::gui::*
	namespace export *

	proc toolbarIconDescr {} {
		return "Add new qemu VM"
	}

	proc _confNewIfc { node_cfg iface_id } {
		global node_existing_mac

		set macaddr [getNextMACaddr $node_existing_mac]
		lappend node_existing_mac $macaddr
		set node_cfg [_setIfcMACaddr $node_cfg $iface_id $macaddr]

		return $node_cfg
	}

	proc icon { size } {
		global ROOTDIR LIBDIR

		switch $size {
			normal {
				return $ROOTDIR/$LIBDIR/custom_nodes/icons/normal/qemu.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/custom_nodes/icons/small/qemu.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/custom_nodes/icons/tiny/qemu.gif
			}
		}
	}

	proc configGUI { node_id } {
		global wi
		#
		#guielements - the list of modules contained in the configuration window
		#		(each element represents the name of the procedure which creates
		#		that module)
		#
		#treecolumns - the list of columns in the interfaces tree (each element
		#		consists of the column id and the column name)
		#
		global guielements treecolumns
		global node_cfg node_cfg_gui node_existing_mac

		set guielements {}
		set treecolumns {}
		set node_cfg [cfgGet "nodes" $node_id]
		set node_cfg_gui [cfgGet "gui" "nodes" $node_id]
		set node_existing_mac [getFromRunning "mac_used_list"]

		configGUI_createConfigPopupWin
		wm title $wi "[_getNodeType $node_cfg] ($node_id) configuration"

		configGUI_nodeName $wi $node_id "Node name:"

		configGUI_VMConfig $wi $node_id

		configGUI_nodeRestart $wi $node_id
		configGUI_buttonsACNode $wi $node_id
	}

	proc doubleClick { node_id control } {
		if { [isRunningNode $node_id] && ! $control } {
			exec vncviewer "[getExperimentRuntimeDir]/$node_id-vnc.socket" &
		} else {
			nodeConfigGUI $node_id
		}
	}

}
