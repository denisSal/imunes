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
# and Technology through the research contracts #IP-2003-143 and #IP-2004-154.
#

# $Id: help.tcl 109 2014-09-29 08:13:54Z denis $

#****h* imunes/help.tcl
# NAME
#  help.tcl -- file used for help infromation
# FUNCTION
#  This file is considered to contain all the help information.
#  Currently it contains only copyright information.
#****

set copyright {

Copyright 2004- University of Zagreb.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

IMUNES manual (pdf and html):
  https://imunes.net/dl/imunes_user_guide.pdf
  https://imunes.net/dl/guide/
}

global all_help_strings meta

set array_names {}

set menubarfile_help_strings {
	"New topology" "Creates a new, empty IMUNES topology in Edit mode."
	"Open topology" "Open an existing IMUNES topology in Edit mode."
	"Recent files" "Show a list of recently opened files. It is possible to set a maximum number of these files to keep in a list using `recents_number` option."
	"Pin to `Recent files`" "Pin the selected topology to the `Recent files` list."
	"Remove from 'Recent files'" "Remove the currently opened file from the `Recent files` list."
	"Save topology" "Save the current topology to its existing file."
	"Save topology as" "Save the current topology to a new file."
	"Close topology" "Close the currently opened topology. Unsaved changes may prompt for confirmation."
	"Print topology" "Print the currently displayed topology using the system print service."
	"Print topology to file" "Export the current topology to a printable file format."
	"Quit IMUNES" "Exit IMUNES. You may be prompted to save unsaved changes."
}
lappend array_names "menubarfile"

set menubaredit_help_strings {
	"Undo last change" "Revert the most recent topology modification."
	"Redo last change" "Reapply the last reverted topology modification."
	"Cut nodes + links" "Remove selected nodes and links from the canvas and place them into the clipboard."
	"Copy nodes + links" "Copy selected nodes and links into the clipboard."
	"Paste nodes + links" "Insert nodes and links from the clipboard to the topology."
	"Select all objects" "Select all nodes and annotations on the current canvas."
	"Select adjacent nodes" "Select all nodes directly connected to the currently selected nodes."
	"Editor preferences" "Configure IMUNES default/current global options."
}
lappend array_names "menubaredit"

set menubarcanvas_help_strings {
	"New canvas" "Create a new canvas. Large topologies can be split across multiple canvases."
	"Rename canvas" "Change the name of the currently opened canvas."
	"Delete canvas" "Delete the current canvas and all elements placed on it."
	"Resize canvas" "Change the dimensions of the current canvas."
	"Canvas background image" "Configure the background image displayed on the current canvas."
	"Previous canvas" "Switch to the previous canvas."
	"Next canvas" "Switch to the next canvas."
	"First canvas" "Switch to the first canvas."
	"Last canvas" "Switch to the last canvas."
}
lappend array_names "menubarcanvas"

set menubarview_help_strings {
	"Node icon size" "Change the size of node icons displayed on the canvas (`Normal` or `Small`)."
	"Show Interface Names" "Display interface names on links next to node interfaces."
	"Show IPv4 Addresses" "Display configured IPv4 addresses on links next to interfaces."
	"Show IPv6 Addresses" "Display configured IPv6 addresses on links next to interfaces."
	"Show VLAN Interfaces" "Display VLAN interfaces, their identifiers, and their IPv4/IPv6 addresses."
	"Show Node Labels" "Display node names/labels on the canvas."
	"Show Link Labels" "Display link options configured on each link."
	"Show All" "Enable all topology information overlays."
	"Show None" "Hide all topology information overlays."
	"Show Topology Tree" "Display the topology tree panel for easier navigation."
	"Customize Node Types" "Select which node types are visible in the node toolbar."
	"Show Unsupported Nodes" "Display node types not supported on the current platform."
	"Show Custom Nodes" "Display user-defined custom node types."
	"Show Background Image" "Display the configured canvas background image."
	"Show Annotations" "Display text and graphical annotations."
	"Show Grid" "Display the canvas alignment grid."
	"Zoom In" "Increase canvas zoom level."
	"Zoom Out" "Decrease canvas zoom level."
	"Themes" "Select the visual theme used by the IMUNES interface."
}
lappend array_names "menubarview"

set menubartools_help_strings {
	"Auto rearrange all" "Automatically arrange all nodes on the current topology based on its connection/placement compared to other nodes."
	"Auto rearrange selected" "Automatically arrange only the selected nodes."
	"Align to grid" "Move selected elements so they align with the canvas grid."
	"IPv4 auto-assign" "Automatically generate and assign IPv4 addresses to interfaces."
	"IPv6 auto-assign" "Automatically generate and assign IPv6 addresses to interfaces."
	"Auto-generate /etc/hosts" "Generate hosts file entries for all nodes in the topology."
	"Randomize MAC bytes" "Generate new last 3 bytes of MAC addresses for newly created node interfaces."
	"IPv4 address pool" "Configure the IPv4 address ranges used for automatic address assignment."
	"IPv6 address pool" "Configure the IPv6 address ranges used for automatic address assignment."
	"Routing protocol defaults" "Configure default routing settings used when creating new routers."
	"Debugger" "Open the interactive shell widget for running Tcl/Tk commands."
}
lappend array_names "menubartools"

set menubartopogen_help_strings {
	"Topology generator" "Generate predefined or parameterized network topologies automatically."
}
lappend array_names "menubartopogen"

set menubarwidgets_help_strings {
	"IMUNES Widgets" "Show available interactive widgets used for visualization, monitoring and experimentation."
}
lappend array_names "menubarwidgets"

set menubarevents_help_strings {
	"IMUNES Events" "Tools for scheduling topology changes and actions during experiment execution."
	"Events - start scheduling" "Start processing scheduled events."
	"Events - stop scheduling" "Stop processing scheduled events."
	"Event editor" "Create, modify and delete scheduled events."
}
lappend array_names "menubarevents"

set menubarexperiment_help_strings {
	"IMUNES experiment modes" "IMUNES has three modes of operation: `edit`, `exec` and `paused`. TODO"
	"Execute experiment" "Start the experiment and instantiate all configured network elements."
	"Terminate experiment" "Stop the running experiment and remove all instantiated resources."
	"Restart experiment" "Terminate and execute the experiment again."
	"Pausing/Resuming experiment" "Temporarily pause or resume runtime topology updates."
	"Attaching to experiment" "Attach IMUNES to an already running experiment."
	"Refreshing experiment" "Synchronize the GUI with the current state of the running experiment. Used only when multiple UI instances are attached to the same experiment."
}
lappend array_names "menubarexperiment"

set menubarhelp_help_strings {
	"About IMUNES" "Display version information, authorship and licensing details."
}
lappend array_names "menubarhelp"

set selecttool_help_strings {
	"Select tool" "The default tool for selecting and moving elements."
}
lappend array_names "selecttool"

set linktool_help_strings {
	"Link tool" "Tool for creating links between nodes on the canvas. Drag the line from one node to another to create a link."
}
lappend array_names "linktool"

set linklayertools_help_strings {
	"Link layer node tool" "This is a list of link-layer (L2) nodes available for use. It is not possible to execute node types with red background on current architecture."
	"LAN switch node" "A link layer element that forwards incoming packets to connected nodes using the table of destination addresses and its ports."
	"Hub node" "A link layer element that forwards every incoming packet to all of its ports and, thus, to every connected node."
	"External interface node" "A tool that provides the possibility to connect a virtual node with the physical interface (e.g. to give the node the access to the Internet)."
	"RSTP switch node" "A Rapid Spanning Tree Protocol switch that can prevent bridge loops and allow providing backup links if an active link fails. (FreeBSD only)"
	"Filter node" "A link layer element that can filter/divert/forward packets depending on their content. (FreeBSD only)"
	"Packet generator node" "A link layer element to craft custom packets and send them with given packet rate. (FreeBSD only)"
}
lappend array_names "linklayertools"

set netlayertools_help_strings {
	"Network layer node tool" "This is a list of network-layer (L3) nodes available for use. It is not possible to execute node types with red background on current architecture."
	"Router node" "A network layer element that is capable of packet forwarding using the routes obtained by dynamic routing protocols (available through quagga or xorp by default installation or any other standard FreeBSD routing daemon)."
	"Host node" "A network layer element that does not forward packets and has static routes. It starts standard network services, via portmap and inetd."
	"PC node" "A network layer element that also does not forward packets and has static routes. Unlike host, it does not start any network services."
	"NAT64 node" "A router node which is capable to enable translation between IPv4 and IPv6 protocols using a form of network address translation (NAT)."
	"External connection node" "A tool that provides the possibility to connect your host PC with a virtual node by creating an interface on your computer."
	"Netns node" "A Linux network namespace node that allows integration with existing namespaces and processes. (Linux only)"
}
lappend array_names "netlayertools"

set annotationtools_help_strings {
	"Text annotation tool" "Create a text annotation on the canvas. Opens a basic text editor and places the text on the clicked location."
	"Freeform annotation tool" "Create a freeform annotation on the canvas. Follows the mouse cursor and leaves a trail, similarly to a pen."
	"Oval annotation tool" "Create an oval annotation on the canvas. Define upper-left and lower-right 'corners' of the oval to draw on the canvas."
	"Rectangle annotation tool" "Create a rectangle annotation on the canvas. Define upper-left and lower-right corners of the rectangle to draw on the canvas."
}
lappend array_names "annotationtools"

set bottombar_help_strings {
	"Canvas list scrollbar" "Use this to scroll through the list of available canvases."
	"Canvas list" "A list of created canvases. The currently selected canvas is marked using a different color.\n\nUse left click to select the canvas, double click to rename it, or mouse-scroll to switch between different canvases. Double-click on the empty element creates a new canvas with the default name."
	"Canvas scrollbar" "Used to move left/right and up/down on the canvas, if the canvas is not fully visible."
	"Status line" "Used for various informational messages such as: current execution/termination step, node/link details, etc."
	"Zoom level" "Current zoom level. Double-click to insert custom zoom percentage value, or right-click to choose a pre-defined value."
	"Scheduler time" "Current step for event scheduler - time in seconds from the event scheduling start."
	"Auto-rearrange status" "Notifies user that either 'Auto rearrange all' or 'Auto rearrange selected' is enabled."
	"Operational mode" "Shows current mode of operation:\n - 'edit mode' - the experiment is not executed, normal editing\n - 'exec mode' - the experiment is executed\n - 'pause mode' - the experiment is executed, but new elements will not trigger a runtime change"
	"Experiment ID" "Shows the currently running experiment ID (EID) if the experiment is running."
}
lappend array_names "bottombar"

set canvas_help_strings {
	"IMUNES canvas" "The main workspace where topology elements are created, positioned and connected."
	"Canvas grid" "Alignment guide used for placing nodes more precisely."
}
lappend array_names "canvas"

set node_help_strings {
	"IMUNES nodes" "Network devices and virtual systems that make up the topology. Double-click a node to configure it."
}
lappend array_names "node"

set link_help_strings {
	"IMUNES links" "Connections between nodes used to transport packets and model network connectivity."
	"Segment links" "Individual link segments that can be adjusted to modify link appearance on the canvas."
}
lappend array_names "link"

set ifaces_help_strings {
	"IMUNES interfaces" "Network interfaces belonging to nodes and used to connect links."
}
lappend array_names "ifaces"

set annotation_help_strings {
	"IMUNES text annotations" "User-defined text labels displayed on the canvas."
	"IMUNES oval annotations" "Oval graphical annotations."
	"IMUNES rectangle annotations" "Rectangular graphical annotations."
	"IMUNES freeform annotations" "Freehand drawings."
}
lappend array_names "annotation"

set confignode_help_strings {
	"Node name" "Name that will be displayed next to the node. If this is a virtualized node, this will be configured as the node hostname."
	"Force node" "When applying the configuration, the node (or its interfaces) will be forcefully recreated/reconfigured with the currently configured values."
	"Custom static routes" "Add defined routes on node startup. Set one route per line in the format\na.b.c.d/prefix x.y.z.w\n\nFor example: 0.0.0.0/0 10.0.0.1"
	"Automatic default routes" "If 'Enable automatic default routes' is enabled, IMUNES will dynamically generate default routes for this node and automatically add them on node startup.\n\nYou can see the default routes that will be generated in the 'Automatic default routes' tab."
	"Configure External interface" "'Steal' an interface from the host OS.\nDepending on the type of link it connects to, the interface is handled differently.\n\nFreeBSD\n - 'normal' link: the interface is moved to the experiment jail and connected with the nodes interface over a bridge\n - 'direct' link: the interface is moved to the experiment jail and connected with the nodes interface without a bridge\n\nLinux\n - 'normal' link: the interface is moved to the experiment namespace and connected with the nodes interface over a bridge\n - 'direct' link: a new macvlan (or ipvlan if wireless) interface is created, and moved to the nodes namespace"
    "Custom config" "If enabled, custom configuration(s) will be run instead of default behaviour. There are currently two custom configuration options: interfaces config and node config."
    "Custom interfaces config" "If enabled, custom interfaces configuration will be run instead of default behaviour from the 'Interfaces' tab. More information is available inside the custom config editor."
    "Custom node config" "If enabled, custom node configuration will be run instead of default commands. More information is available inside the custom config editor."
	"Open in external editor" "Open the selected custom configuration in external editor (configured in 'external_editor_command' custom variable).\n\nIgnored if custom configuration is DISABLED.\n\nExample values for 'external_editor_command' are:
    xterm+vim:	{xterm -T \"%TITLE%\" -e \"vim %FILE_PATH%\"}
    gedit:		{gedit --standalone %FILE_PATH%}
    mousepad:	{mousepad --disable-server %FILE_PATH%}
    kate		{kate --block %FILE_PATH%}
    vscode		{code --wait --new-window %FILE_PATH%}
    sublime		{subl -n -w %FILE_PATH%}
    gvim		{gvim -f %FILE_PATH%}\n\nThe external editor must quit, only then will IMUNES fetch the latest changes."
    "Services" "For each enabled service, the node will start its daemon on node startup."
}
lappend array_names "confignode"

set configlink_help_strings {
	"Link from" "Defines the two endpoints connected by the link.\n\n`Normal` links use an intermediate bridge/switch segment when required by the platform.\n`Direct` links connect endpoints directly without an intermediate bridge."
	"Link bandwidth" "Maximum link bandwidth in bits per second. Set this to 0 to leave bandwidth unlimited (or rather: limited by your hardware)."
	"Link delay" "Propagation delay added to packets crossing this link, in microseconds. Set this to 0 for no additional delay."
	"Link BER" "(FreeBSD only)\n\nBit error rate expressed as 1/N. Smaller non-zero N values produce errors more frequently. Set this to 0 to disable BER emulation."
	"Link packet loss" "(Lunux only)\n\nPercentage of packets dropped on this link. Set this to 0 for no artificial packet loss."
	"Link packet duplication" "Percentage of packets duplicated on this link. Set this to 0 to disable packet duplication."
	"Link width" "Width of the link line on the canvas. This changes only the visual representation of the link."
	"Link color" "Color of the link line on the canvas. This changes only the visual representation of the link."
	"Jitter mode" "Select how configured jitter values are applied. `sequential` uses the values in order; `random` selects values randomly."
	"Jitter hold" "Time in milliseconds for which a selected jitter value remains active before the next value is used."
	"Jitter values" "List of jitter values in milliseconds, one value per line. Values are configured separately for each link direction."
}
lappend array_names "configlink"

set advancedopts_help_strings {
	"Imported files" "Import (embed) host files in IMUNES topology file."
	"Imported file enabled" "Enable or disable this imported file. Validation errors are ignored while the entry is disabled."
	"Imported file internal path" "Destination of the imported file. Use an absolute file path, @node:path to link to an imported file from another node, or #hook:filename to make the file available to a trigger hook.\n\nLinked entries cannot link to another linked entry.\n\nValid hooks are:\npre-init_config\npost-init_config\npre-pifaces_create\npost-pifaces_create\npre-pifaces_dcreate\npost-pifaces_dcreate\npre-lifaces_create\npost-lifaces_create\npre-ifaces_config\npost-ifaces_config\npre-node_config\npost-node_config\npre-node_unconfig\npost-node_unconfig\npre-node_shutdown\npost-node_shutdown\npre-ifaces_unconfig\npost-ifaces_unconfig\npre-lifaces_destroy\npost-lifaces_destroy\npre-pifaces_destroy\npost-pifaces_destroy\npre-pifaces_ddestroy\npost-pifaces_ddestroy\npre-node_destroy"
	"Imported file mode" "File permissions specified as a numeric mode, for example 644. An environment variable (a value starting with $) is also accepted."
	"Imported file edit" "Edit the contents of the imported file using the built-in editor."
	"Imported file external edit" "Edit the contents of the imported file using an external editor."
	"Imported file import" "Select a local file and load its contents into this imported file entry."
	"Imported file encode" "Store the file contents base64-encoded in the IMUNES configuration. Use this for binary files or other content that should not be stored as plain text."
	"Imported file delete" "Delete this imported file entry."
	"Imported dirs" "Import (embed) host directories in IMUNES topology file."
	"Imported dir enabled" "Enable or disable this imported directory. Validation errors are ignored while the entry is disabled."
	"Imported dir internal path" "Destination of the imported directory. Use an absolute directory path, @node:path to link to an imported directory from another node, or #hook:dirname to make the directory available to a trigger hook.\n\nLinked entries cannot link to another linked entry.\n\nValid hooks are:\npre-init_config\npost-init_config\npre-pifaces_create\npost-pifaces_create\npre-pifaces_dcreate\npost-pifaces_dcreate\npre-lifaces_create\npost-lifaces_create\npre-ifaces_config\npost-ifaces_config\npre-node_config\npost-node_config\npre-node_unconfig\npost-node_unconfig\npre-node_shutdown\npost-node_shutdown\npre-ifaces_unconfig\npost-ifaces_unconfig\npre-lifaces_destroy\npost-lifaces_destroy\npre-pifaces_destroy\npost-pifaces_destroy\npre-pifaces_ddestroy\npost-pifaces_ddestroy\npre-node_destroy"
	"Imported dir import" "Select a local directory and import its contents. The directory contents are stored as a base64-encoded tar archive in the IMUNES configuration."
	"Imported dir delete" "Delete this imported directory entry."
	"General Docker options" "General options to attach to `docker run` command."
	"General jail options" "General options to attach to `jail -c` command"
    "Custom vroot" "If enabled, IMUNES will use the given jail path (virtual root - vroot) instead of the default one when running the node.\n\nThe default vroot is /var/imunes/vroot directory."
	"Custom image" "If enabled, IMUNES will use the given Docker image (virtual root - vroot) instead of the default one when running the node.\n\nThe default vroot is imunes/template Docker image."
    "External Docker interface" "If enabled, IMUNES will create a Docker interface inside a node (dext0) connected to the imunes-bridge Docker network.\n\nThis interface is primarily used to enable internet connection on a node in a quick and easy way - the default route is automatically added on its creation. Users should configure /etc/resolv.conf by themselves as DNS resolver is not set automatically."
    "Advanced virt options" "Additional options for Docker/Jail/others when creating the current node (such as mounts, CPUs, memory, etc.)"
    "CPUs count" "The maximum CPU resources a node can use."
    "Custom jail flags" "Insert any custom jail flags."
    "Custom Docker flags" "Insert any custom Docker flags."
	"Docker port forwardings" "Configure TCP, UDP, SCTP or any port mappings from the host to this Docker node. Each entry defines the protocol and host/container ports used by Docker."
	"Port forwarding enabled" "Enable or disable this port forwarding rule. Disabled rules are kept in the configuration but are not applied."
	"Port forwarding host IP" "Optional host IP address on which the forwarded port is exposed. Leave empty to use Docker's default host binding."
	"Port forwarding host port" "Optional port number exposed on the host. Leave empty to let Docker automatically assign an available host port."
	"Port forwarding node port" "Port number inside the Docker node to which incoming connections are forwarded."
	"Port forwarding protocol" "Network protocol used by this port forwarding rule. Use tcp/udp/sctp or leave empty for any."
	"Port forwarding delete" "Delete this port forwarding rule."
	"Docker environment variables" "Define environment variables passed to the Docker container when the node is created."
	"Environment variable enable" "Enable or disable this environment variable. Disabled variables are kept in the configuration but are not applied."
	"Environment variable name" "Name of the environment variable passed to the Docker container."
	"Environment variable value" "Value assigned to the environment variable. The value may be left empty."
	"Environment variable deleted" "Delete this environment variable."
	"Docker volumes" "Configure host paths or Docker volumes that are mounted inside the node container."
	"Volume enabled" "Enable or disable this volume. Disabled volumes are kept in the configuration but are not applied."
	"Volume type" "Bind mount (host file/directoey) or Docker volume."
	"Volume source" "Host path or Docker volume name to mount into the container."
	"Volume destination" "Path inside the Docker container where the volume is mounted."
	"Volume read only" "Mount the volume as read-only. When enabled, the container can read files from the volume but cannot modify them."
	"Volume delete" "Delete this volume mapping."
}
lappend array_names "advancedopts"

set misc_help_strings {
	"Editor Preferences" "`Active options`\nPreview of currently active options combining Custom, Topology and Default options. The Default options are loaded first, overwritten by the Topology options and Custom options. If `custom_override` is enabled for the option, the Custom option will always overwrite the topology option.\n\n`Custom options`\nOptions loaded from .rc files (`/etc/imunes/config`, `\$HOME/.imunes.rc` if it exists, otherwise `\$XDG_CONFIG_HOME/imunes/config`, `./.imunes.rc`, `/etc/imunes/override` - in that order). Apply button will save the configured options to the last loaded existing .rc file - not including /etc/imunes/override.\n\n`Topology options`\nOptions loaded from, and saved to the .imn file - some options cannot be saved."
}
lappend array_names "misc"

foreach array_name $array_names {
    upvar 0 ${array_name}_help_strings var_name
    lappend all {*}$var_name
}

array set all_help_strings $all

proc helpPopup { title content } {
	global ROOTDIR LIBDIR

	set help_popup .help_popup

	catch { destroy $help_popup }
	toplevel $help_popup

	try {
		grab $help_popup
	} on error {} {
		catch { destroy $help_popup }
		return
	}

	wm title $help_popup "IMUNES Help - $title"
	wm minsize $help_popup 454 0

	set main_frame $help_popup.main
	ttk::frame $main_frame -padding 4
	grid $main_frame -column 0 -row 0 -sticky n
	grid columnconfigure $help_popup 0 -weight 1
	grid rowconfigure $help_popup 0 -weight 1

	set image_obj [image create photo -file $ROOTDIR/$LIBDIR/icons/imunes_icon64.png]
	set image_label $main_frame.image_label
	ttk::label $image_label
	$image_label configure -image $image_obj

	set content_label $main_frame.content_label
	ttk::label $content_label -wraplength 434 -text "$content"

	set close_button $main_frame.close_button
	ttk::button $close_button -text "Close" -command "destroy $help_popup"

	grid $image_label -column 0 -row 0 -pady 1 -padx 10 -pady 10
	grid $content_label -column 1 -row 0 -pady 1 -padx 10 -pady 10
	grid $close_button -column 0 -row 1 -pady 1 -padx 10 -columnspan 2
}

proc createHelp {} {
	global all_help_strings meta
	global debug

	if { ! $debug } {
		return
	}

	set hovered_elem [winfo containing [winfo pointerx .] [winfo pointery .]]
	if { $hovered_elem == "" } {
		return
	}

	set key $hovered_elem

	set x [winfo pointerx .]
	set y [winfo pointery .]

	set local_x [expr { $x - [winfo rootx $hovered_elem] }]
	set local_y [expr { $y - [winfo rooty $hovered_elem] }]

	switch -exact [winfo class $hovered_elem] {
		"Canvas" {
			set elem_type [lindex [$hovered_elem gettags current] 0]
			if { $elem_type != "" } {
				set key "$hovered_elem,$elem_type"
			}
		}
		"Menu" {
			set menu_idx [$hovered_elem index active]
			if { $menu_idx == "none" } {
				return
			}

			try {
				$hovered_elem entrycget $menu_idx -label
			} on ok label_str {
				set key "$hovered_elem,$label_str"
			} on error {} {
				return
			}
		}
		"Treeview" {
			set col [string trimleft [$hovered_elem identify column $local_x $local_y] "#"]

			set columns [$hovered_elem cget -columns]
			if { $col == 0 } {
				set key "$hovered_elem"
			} else {
				set key "$hovered_elem,[lindex $columns $col-1]"
			}
		}
		"TNotebook" {
			set tab_idx [$hovered_elem index "@$local_x,$local_y"]

			if { $tab_idx == "" } {
				return
			}

			set tab_text [$hovered_elem tab $tab_idx -text]

			set key "$hovered_elem,$tab_text"
		}
	}

	set current_title ""
	set current_body ""
	if { [info exists meta($key)] && [info exists all_help_strings($meta($key))] } {
		set current_title $meta($key)
		set current_body $all_help_strings($meta($key))
	}

	dputs "$key --- [winfo class $hovered_elem]"

	set help_editor_elem .help_editor
	catch { destroy $help_editor_elem }
	tk::toplevel $help_editor_elem

	try {
		grab $help_editor_elem
	} on error {} {
		catch { destroy $help_editor_elem }

		return
	}

	wm title $help_editor_elem "$key"
	wm minsize $help_editor_elem 584 445

	set text_frame $help_editor_elem.text_frame
	ttk::frame $text_frame

	ttk::entry $text_frame.title_editor
	$text_frame.title_editor insert 0 "$current_title"

	ttk::scrollbar $text_frame.vsb -orient vertical -command [list $text_frame.body_editor yview]
	ttk::scrollbar $text_frame.hsb -orient horizontal -command [list $text_frame.body_editor xview]
	text $text_frame.body_editor -width 42 -bg white -takefocus 0 -wrap none \
		-yscrollcommand [list $text_frame.vsb set] -xscrollcommand [list $text_frame.hsb set]
	$text_frame.body_editor insert end "$current_body"

	pack $text_frame.title_editor -side top -pady 5 -padx 10 -fill x
	pack $text_frame.vsb -side right -fill y
	pack $text_frame.hsb -side bottom -fill x
	pack $text_frame.body_editor -anchor w -fill both -expand 1
	pack $text_frame -fill both

	set buttons $help_editor_elem.buttons
	ttk::frame $buttons -borderwidth 2

	ttk::button $buttons.apply -text "Apply" \
		-command "printHelpCommands $key $text_frame"
	ttk::button $buttons.close -text "Close" -command "destroy $help_editor_elem"

	grid $buttons.apply -row 0 -column 1 -sticky swe -padx 2
	grid $buttons.close -row 0 -column 2 -sticky swe -padx 2
	pack $buttons -pady 2
}

proc printHelpCommands { target_elem text_elem } {
	set title [string trim [$text_elem.title_editor get]]
	set body [string trim [$text_elem.body_editor get 0.0 end]]

	#dputs "target_elem: $target_elem"
	#dputs "title: $title"
	#dputs "body: $body"

	dputs "================================================="
	dputs "TARGET_ELEM: '$target_elem' ->"
	dputs "	attachHelp \"$target_elem\" \"$title\""

	dputs "gui/help.tcl in *_help_strings array ->"
	dputs "	\"$title\" \"$body\""
	dputs "================================================="
}

proc showHelp {} {
	global all_help_strings meta

	set x [winfo pointerx .]
	set y [winfo pointery .]

	set hovered_elem [winfo containing $x $y]
	if { $hovered_elem == "" } {
		return
	}

	set key $hovered_elem

	set local_x [expr { $x - [winfo rootx $hovered_elem] }]
	set local_y [expr { $y - [winfo rooty $hovered_elem] }]

	switch -exact [winfo class $hovered_elem] {
		"Canvas" {
			set elem_type [lindex [$hovered_elem gettags current] 0]
			if { $elem_type != "" } {
				set key "$hovered_elem,$elem_type"
			}
		}
		"Menu" {
			if { [lindex [split $hovered_elem ","] 0] == ".#menubar" } {
				# main menu
				set menu_idx [$hovered_elem index active]
			} else {
				# vertical menu
				set menu_idx [$hovered_elem index @$local_y]
			}

			if { $menu_idx == "none" } {
				return
			}

			try {
				$hovered_elem entrycget $menu_idx -label
			} on ok label_str {
				set key "$hovered_elem,$label_str"
			} on error {} {
				return
			}
		}
		"Treeview" {
			set col [string trimleft [$hovered_elem identify column $local_x $local_y] "#"]

			set columns [$hovered_elem cget -columns]
			if { $col == 0 } {
				set key "$hovered_elem"
			} else {
				set key "$hovered_elem,[lindex $columns $col-1]"
			}
		}
		"TNotebook" {
			set tab_idx [$hovered_elem index "@$local_x,$local_y"]

			if { $tab_idx == "" } {
				return
			}

			set tab_text [$hovered_elem tab $tab_idx -text]

			set key "$hovered_elem,$tab_text"
		}
	}

	if { [info exists meta($key)] && [info exists all_help_strings($meta($key))] } {
		helpPopup $meta($key) $all_help_strings($meta($key))
	}

	dputs "$key --- [winfo class $hovered_elem]"
}

proc attachHelp { element title } {
	global all_help_strings meta

	dputs "ADDING '$element' with '$title'"
	set meta($element) $title
}

global all_widgets
set all_widgets [dict create]

proc getWidgets { { w . } { indent "" } } {
	global all_widgets

    if { ! [winfo exists $w] } {
        return
    }

	#dputs "${indent}$w	class=[winfo class $w]"
	if { $w ni [dict keys $all_widgets] } {
		puts "ADDED $w"
		dict set all_widgets $w [winfo class $w]
	}

    foreach child [winfo children $w] {
        getWidgets $child "$indent	"
    }
}

proc printTkWidgets { { w . } { indent "" } } {
	global all_widgets

	set fd [open /tmp/widgets "w"]
	dict for {w c} $all_widgets {
		puts $fd "$w	class=$c"
		dputs "$w	class=$c"
	}
	close $fd
}
