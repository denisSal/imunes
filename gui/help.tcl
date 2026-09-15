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
	"<<SUBSUBSECTION>>File Menu" \
"The *File* menu<<IHIDE:([@fig:file_menu])>> contains options for configuration files management.<<IHIDE:

<<FIG:![File menu](./assets/file_menu.png){#fig:file_menu width=20%}>>
>>"

	"<<LEVEL1>><<*>>New<<*>><<DHIDE: topology>>" \
"<<BULLET_EXP>>Creates a new, empty IMUNES topology in `edit mode`."

	"<<LEVEL1>><<*>>Open<<*>><<DHIDE: topology>>" \
"<<BULLET_EXP>>Open an existing IMUNES topology in `edit mode`."

	"<<LEVEL1>><<*>>Recent files<<*>>" \
"<<BULLET_EXP>>Show a list of recently opened files. It is possible to set a maximum number of these files to keep in a list using `recents_number` option."

	"<<LEVEL2>><<*>>Pin current to 'Recent files'<<*>>" \
"<<BULLET_EXP>>Pin the selected topology to the `Recent files` list."

	"<<LEVEL2>><<*>>Remove current from 'Recent files'<<*>>" \
"<<BULLET_EXP>>Remove the currently opened file from the `Recent files` list."

	"<<LEVEL1>><<*>>Save<<*>><<DHIDE: topology>>" \
"<<BULLET_EXP>>Save the current topology to its existing file."

	"<<LEVEL1>><<*>>Save<<DHIDE: topology>> As<<*>>" \
"<<BULLET_EXP>>Save the current topology to a new file."

	"<<LEVEL1>><<*>>Close<<*>><<DHIDE: topology>>" \
"<<BULLET_EXP>>Close the currently opened topology. Unsaved changes may prompt for confirmation."

	"<<LEVEL1>><<*>>Print<<*>><<DHIDE: topology>>" \
"<<BULLET_EXP>>Print the currently displayed topology using the system print service."

	"<<LEVEL1>><<*>>Print<<DHIDE: topology>> To File<<*>>" \
"<<BULLET_EXP>>Export the current topology to a printable file format."

	"<<LEVEL1>><<*>>Quit<<*>><<DHIDE: IMUNES>>" \
"<<BULLET_EXP>>Exit IMUNES. You may be prompted to save unsaved changes."
}
lappend array_names "menubarfile"

set menubaredit_help_strings {
	"<<SUBSUBSECTION>>Edit Menu" \
"The *Edit* menu<<IHIDE:([@fig:edit_menu])>> contains options for handling elements on the canvas.<<IHIDE:

<<FIG:![Edit menu](./assets/edit_menu.png){#fig:edit_menu width=19%}>>
>>"

	"<<LEVEL1>><<*>>Undo<<*>><<DHIDE: last change>>" \
"<<BULLET_EXP>>Revert the most recent topology modification."

	"<<LEVEL1>><<*>>Redo<<*>><<DHIDE: last change>>" \
"<<BULLET_EXP>>Reapply the last reverted topology modification."

	"<<LEVEL1>><<*>>Cut<<*>><<DHIDE: nodes + links>>" \
"<<BULLET_EXP>>Remove selected nodes and links from the canvas and place them into the clipboard."

	"<<LEVEL1>><<*>>Copy<<*>><<DHIDE: nodes + links>>" \
"<<BULLET_EXP>>Copy selected nodes and links into the clipboard."

	"<<LEVEL1>><<*>>Paste<<*>><<DHIDE: nodes + links>>" \
"<<BULLET_EXP>>Insert nodes and links from the clipboard to the topology."

	"<<LEVEL1>><<*>>Select all<<*>><<DHIDE: objects>>" \
"<<BULLET_EXP>>Select all nodes and annotations on the current canvas."

	"<<LEVEL1>><<*>>Select adjacent<<*>><<DHIDE: nodes>>" \
"<<BULLET_EXP>>Select all nodes directly connected to the currently selected nodes."

	"<<LEVEL1>><<*>>Editor preferences<<*>><<DHIDE: menu>>" \
"<<BULLET_EXP>>Configure IMUNES default/custom/current global options."
}
lappend array_names "menubaredit"

set menubarcanvas_help_strings {
	"<<SUBSUBSECTION>>Canvas Menu" \
"The *Canvas* menu contains options for canvas management<<IHIDE: [@fig:canvas_menu]>>.<<IHIDE:

<<FIG:![Canvas menu](./assets/canvas_menu.png){#fig:canvas_menu width=20%}>>
>>"

	"<<LEVEL1>><<*>>New<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Create a new canvas. Large topologies can be split across multiple canvases."

	"<<LEVEL1>><<*>>Rename<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Change the name of the currently opened canvas."

	"<<LEVEL1>><<*>>Delete<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Delete the current canvas and all elements placed on it."

	"<<LEVEL1>><<*>>Resize<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Change the dimensions of the current canvas."

	"<<LEVEL1>><<DHIDE:Canvas >><<*>>Background image<<*>>" \
"<<BULLET_EXP>>Configure the background image displayed on the current canvas."

	"<<LEVEL1>><<*>>Previous<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Switch to the previous canvas."

	"<<LEVEL1>><<*>>Next<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Switch to the next canvas."

	"<<LEVEL1>><<*>>First<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Switch to the first canvas."

	"<<LEVEL1>><<*>>Last<<*>><<DHIDE: canvas>>" \
"<<BULLET_EXP>>Switch to the last canvas."
}
lappend array_names "menubarcanvas"

set menubarview_help_strings {
	"<<SUBSUBSECTION>>View Menu" \
"The *View* menu<<IHIDE: ([@fig:view_menu])>> contains options for showing / hiding links and nodes parameters on the canvas, options for changing icon size, zooming options, etc.<<IHIDE:

<<FIG:![View menu](./assets/view_menu.png){#fig:view_menu width=25%}>>
>>"

	"<<LEVEL1>><<DHIDE:Node >><<*>>Icon size<<*>>" \
"<<BULLET_EXP>>Change the size of node icons displayed on the canvas (`Normal` or `Small`)."

	"<<LEVEL1>><<*>>Show Interface Names<<*>>" \
"<<BULLET_EXP>>Display interface names on links next to node interfaces."

	"<<LEVEL1>><<*>>Show IPv4 Addresses<<*>>" \
"<<BULLET_EXP>>Display configured IPv4 addresses on links next to interfaces."

	"<<LEVEL1>><<*>>Show IPv6 Addresses<<*>>" \
"<<BULLET_EXP>>Display configured IPv6 addresses on links next to interfaces."

	"<<LEVEL1>><<*>>Show VLAN Interfaces<<*>>" \
"<<BULLET_EXP>>Display VLAN interfaces, their identifiers, and their IPv4/IPv6 addresses."

	"<<LEVEL1>><<*>>Show Node Labels<<*>>" \
"<<BULLET_EXP>>Display node names/labels on the canvas."

	"<<LEVEL1>><<*>>Show Link Labels<<*>>" \
"<<BULLET_EXP>>Display link options configured on each link."

	"<<LEVEL1>><<*>>Show All<<*>>" \
"<<BULLET_EXP>>Enable all topology information overlays."

	"<<LEVEL1>><<*>>Show None<<*>>" \
"<<BULLET_EXP>>Hide all topology information overlays."

	"<<LEVEL1>><<*>>Show Topology Tree<<*>>" \
"<<BULLET_EXP>>Display the topology tree panel for easier navigation."

	"<<LEVEL1>><<*>>Customize Node Types<<*>>" \
"<<BULLET_EXP>>Select which node types are visible in the node toolbar."

	"<<LEVEL1>><<*>>Show Unsupported Nodes<<*>>" \
"<<BULLET_EXP>>Display node types not supported on the current platform."

	"<<LEVEL1>><<*>>Show Custom Nodes<<*>>" \
"<<BULLET_EXP>>Display user-defined custom node types."

	"<<LEVEL1>><<*>>Show Background Image<<*>>" \
"<<BULLET_EXP>>Display the configured canvas background image."

	"<<LEVEL1>><<*>>Show Annotations<<*>>" \
"<<BULLET_EXP>>Display text and graphical annotations."

	"<<LEVEL1>><<*>>Show Grid<<*>>" \
"<<BULLET_EXP>>Display the canvas alignment grid."

	"<<LEVEL1>><<*>>Zoom In<<*>>" \
"<<BULLET_EXP>>Increase canvas zoom level."

	"<<LEVEL1>><<*>>Zoom Out<<*>>" \
"<<BULLET_EXP>>Decrease canvas zoom level."

	"<<LEVEL1>><<*>>Themes<<*>>" \
"<<BULLET_EXP>>Select the visual theme used by the IMUNES interface."
}
lappend array_names "menubarview"

set menubartools_help_strings {
	"<<SUBSUBSECTION>>Tools Menu" \
"The *Tools* menu<<IHIDE: ([@fig:tools_menu])>> contains the network topology management tools.<<IHIDE:

<<FIG:![Tools menu](./assets/tools_menu.png){#fig:tools_menu width=30%}>>
>>"

	"<<LEVEL1>><<*>>Auto rearrange all<<*>>" \
"<<BULLET_EXP>>Automatically arrange all nodes on the current topology based on its connection/placement compared to other nodes."

	"<<LEVEL1>><<*>>Auto rearrange selected<<*>>" \
"<<BULLET_EXP>>Automatically arrange only the selected nodes."

	"<<LEVEL1>><<*>>Align to grid<<*>>" \
"<<BULLET_EXP>>Move selected elements so they align with the canvas grid."

	"<<LEVEL1>><<*>>IPv4 auto-assign addresses/routes<<*>>" \
"<<BULLET_EXP>>Automatically generate and assign IPv4 addresses to interfaces."

	"<<LEVEL1>><<*>>IPv6 auto-assign addresses/routes<<*>>" \
"<<BULLET_EXP>>Automatically generate and assign IPv6 addresses to interfaces."

	"<<LEVEL1>><<*>>Auto-generate /etc/hosts file<<*>>" \
"<<BULLET_EXP>>Generate hosts file entries for all nodes in the topology."

	"<<LEVEL1>><<*>>Randomize MAC bytes<<*>>" \
"<<BULLET_EXP>>Generate new last 3 bytes of MAC addresses for newly created node interfaces."

	"<<LEVEL1>><<*>>IPv4 address pool<<*>>" \
"<<BULLET_EXP>>Configure the IPv4 address ranges used for automatic address assignment."

	"<<LEVEL1>><<*>>IPv6 address pool<<*>>" \
"<<BULLET_EXP>>Configure the IPv6 address ranges used for automatic address assignment."

	"<<LEVEL1>><<*>>Routing protocol defaults<<*>>" \
"<<BULLET_EXP>>Configure default routing settings for selected routers, or when creating new routers."

	"<<LEVEL1>><<*>>Debugger<<*>>" \
"<<BULLET_EXP>>Open the interactive shell widget for running Tcl/Tk commands. Only available in `debug` (*-d*) mode."
}
lappend array_names "menubartools"

set menubartopogen_help_strings {
	"<<SUBSUBSECTION>>TopoGen Menu" \
"The *TopoGen* menu<<IHIDE: ([@fig:topogen_menu])>> contains options for simple and fast specification of various network topologies using a selected node type (see Section [Generating a Network Topology]<<IHIDE:(#generating-a-network-topology)>>).<<IHIDE:

<<FIG:![Topogen menu](./assets/topogen_menu.png){#fig:topogen_menu width=12%}>>
>>"

	"<<NOSECTION>>Topology generator" \
"Select any node type and click on one of the options to automatically generate predefined network topologies using any of the following rules:<<FAKENEWLINE>>
<<LEVEL1>>*Chain(n)* - Create *n* nodes and connect them sequentially in a chain.
<<LEVEL1>>*Star(n)* - Create *n* nodes and connect *n-1* of them to a single, central node.
<<LEVEL1>>*Cycle(n)* - Create *n* nodes and connect them sequentially, but connecting the last node with the first one.
<<LEVEL1>>*Wheel(n)* - Create *n* nodes and connect *n-1* of them to a single, central node, and to their neighbors.
<<LEVEL1>>*Cube(n)* - Create *2^n* nodes and connect them each of them with *n* other nodes.
<<LEVEL1>>*Clique(n)* - Create *n* nodes and connect them with each other.
<<LEVEL1>>*Bipartite(n,m)* - Create *n+m* nodes and connect each of *n* nodes with each of *m* nodes.
<<LEVEL1>>*Random(n,m)* - Create *n* nodes and randomly connect *m* links between them."
}
lappend array_names "menubartopogen"

set menubarwidgets_help_strings {
	"<<SUBSUBSECTION>>Widgets Menu" \
"This menu contains a list of 'widgets' for displaying information about the nodes of the currently running topology. To see these information, place the mouse pointer on the virtual node of interest after selecting a widget.<<IHIDE:

<<FIG:![Widgets menu](./assets/widgets_menu.png){#fig:widgets_menu width=20%}>>
>>"

	"<<NOSECTION>>IMUNES Widgets" \
"Selecting a widget and hovering the mouse cursor over a node executes the associated command and displays its output in a GUI popup. These commands are designed for fast responses and therefore time out after 0.1 seconds to prevent them from blocking the GUI.

The pre-existing widgets are:<<FAKENEWLINE>>
<<LEVEL1>>*None* - Disable widgets - do not run any commands on mouse-hover.
<<LEVEL1>>*ifconfig* - `ifconfig` - Show network interfaces parameters.
<<LEVEL1>>*IPv4 Routing table* - `netstat -4 -rn` - Show the IPv4 routing table.
<<LEVEL1>>*IPv6 Routing table* - `netstat -6 -rn` - Show the IPv6 routing table.
<<LEVEL1>>*RIP routes info* - `vtysh -c 'show ip rip'` - Show the RIP routing information.
<<LEVEL1>>*RIPng routes info* - `vtysh -c 'show ip rip'` - Show the RIPng routing information.
<<LEVEL1>>*Process list* - `ps ax` - Show the running processes.
<<LEVEL1>>*IPv4 sockets* - `netstat -4 -an` - Show the IPv4 sockets.
<<LEVEL1>>*IPv6 sockets* - `netstat -6 -an` - Show the IPv6 sockets.
<<LEVEL1>>*View ifaces startup script* - `cat /var/imunes/*/*/{boot,custom}_ifaces.conf` - Show the interfaces startup script
<<LEVEL1>>*View ifaces startup logs* - `cat /var/imunes/*/*/{out,err}_ifaces.log` - Show the interfaces startup logs
<<LEVEL1>>*View startup script* - `cat /var/imunes/*/*/{boot,custom}.conf` - Show the startup script
<<LEVEL1>>*View startup logs* - `cat /var/imunes/*/*/{out,err}.log` - Show the startup logs
<<LEVEL1>>*List files* - `ls` - Show files in the node working directory.
<<LEVEL1>>*Custom...* - Allows the specification of the custom command that will be executed inside a virtual node."
}
lappend array_names "menubarwidgets"

set menubarevents_help_strings {
	"<<SUBSUBSECTION>>Events Menu" \
"The *Events* menu<<IHIDE: ([@fig:events_menu])>> is used to configure event scheduling. The event scheduling is explained in detail in the documentation section [User-configurable Event Scheduling]<<IHIDE:(#user-configurable-event-scheduling)>>.<<IHIDE:

<<FIG:![Events menu](./assets/events_menu.png){#fig:events_menu width=15%}>>
>>"

	"<<LEVEL1>><<*>>Start<<DHIDE: event>> scheduling<<*>>" \
"<<BULLET_EXP>>Start processing scheduled events."

	"<<LEVEL1>><<*>>Stop<<DHIDE: event>> scheduling<<*>>" \
"<<BULLET_EXP>>Stop processing scheduled events."

	"<<LEVEL1>><<*>>Event editor<<*>>" \
"<<BULLET_EXP>>Create, modify and delete scheduled events."
}
lappend array_names "menubarevents"

set menubarexperiment_help_strings {
	"<<SUBSUBSECTION>>Experiment Menu" \
"The *Experiment* menu<<IHIDE: ([@fig:experiment_menu])>> is used to switch IMUNES between different working modes.<<IHIDE:

<<FIG:![Experiment menu](./assets/experiment_menu.png){#fig:experiment_menu width=25%}>>>>

IMUNES operates in three modes: `edit`, `exec`, and `paused`.

In `edit` mode, the topology exists only as a configuration and no system resources are instantiated. Starting an experiment switches IMUNES to `exec` mode, where the topology is instantiated and runs as an independent experiment identified by a unique experiment ID (*eid*). Changes made to the topology while in `exec` mode are immediately reflected in the running experiment.

The `paused` mode temporarily suspends the application of topology changes. Any modifications made while paused are accumulated and applied simultaneously when execution is resumed.

A running experiment exists independently of the IMUNES GUI and can be detached from and reattached to at any time. Terminating an experiment destroys all instantiated resources while preserving the topology configuration.

See more details in the documentation section [IMUNES Architecture]<<IHIDE:(#imunes-architecture)>>.

The *Experiment* submenus can be used to transition between these modes and manage the experiment lifecycle.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Execute<<*>>" \
"<<BULLET_EXP>>Start an experiment and switch to `exec` mode. In the process of starting an experiment, IMUNES creates and configures the virtual network. All events during this process will be shown in the statusbar."

	"<<LEVEL1>><<*>>Terminate<<*>>" \
"<<BULLET_EXP>>Terminate an experiment and switch to `edit` mode. During the termination process, IMUNES will shut down all network elements and it will terminate active services on each node. All events during this process will be shown in the statusbar."

	"<<LEVEL1>><<*>>Restart<<*>>" \
"<<BULLET_EXP>>Terminate and immediately execute the experiment again."

	"<<LEVEL1>><<*>>Pause/Resume execution<<*>>" \
"<<BULLET_EXP>>Temporarily pause or resume runtime topology updates."

	"<<LEVEL1>><<*>>Attach to experiment<<*>>" \
"<<BULLET_EXP>>This option opens a window with the list of attachable experiments on this (or the remote) machine."

	"<<LEVEL1>><<*>>Refresh running experiment<<*>>" \
"<<BULLET_EXP>>Synchronize the GUI with the current state of the running experiment. Useful only when multiple UI instances are attached to the same experiment, since the GUI does not automatically fetch changes from running experiments."
}
lappend array_names "menubarexperiment"

set menubarhelp_help_strings {
	"<<SUBSUBSECTION>>Help Menu" \
"When hovering over certain GUI elements, it is possible to get help for that element with the `F1` button on your keyboard. This will open a popup with explanations for that element.<<IHIDE:

<<FIG:![Help menu](./assets/help_menu.png){#fig:help_menu width=8%}>>>>

The *Help* menu has only one submenu.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>About<<*>>" \
"<<BULLET_EXP>>Display version information, authorship and licensing details."
}
lappend array_names "menubarhelp"

set selecttool_help_strings {
	"<<SUBSUBSECTION>>Select tool" \
"The default tool for selecting and moving elements. Click an element to select it, or click and drag on an empty area of the canvas to draw a rectangle around one or more elements.

Hold `Control` while dragging to add elements to the current selection. To deselect an individual element, hold `Control` and click the selected element.

Also, to exit `autorearrange` mode, use the *Select* tool and click anywhere on the canvas."
}
lappend array_names "selecttool"

set linktool_help_strings {
	"<<SUBSUBSECTION>>Link tool" \
"Tool for creating links between nodes on the canvas. Drag the line from one node to another to create a link. Right clicking on the link gives options (explained in documentation section [Link Options]<<IHIDE:(#link-options)>>) for that link."
}
lappend array_names "linktool"

set linklayertools_help_strings {
	"<<SUBSUBSECTION>>Link layer node tool" \
"This opens a list of link-layer (L2) nodes available for use:<<FAKENEWLINE>>
<<LEVEL1>>LAN switch node
<<LEVEL1>>Hub node
<<LEVEL1>>External interface node
<<LEVEL1>>RSTP switch node (FreeBSD only)
<<LEVEL1>>Filter node (FreeBSD only)
<<LEVEL1>>Packet generator node (FreeBSD only)

**NOTE**: It is not possible to execute node types with red background on the current architecture."

	"<<SUBSUBSUBSECTION>>LAN switch node" \
"A link layer element that forwards incoming packets to connected nodes using the table of destination addresses and its ports."

	"<<SUBSUBSUBSECTION>>Hub node" \
"A link layer element that forwards every incoming packet to all of its ports and, thus, to every connected node."

	"<<SUBSUBSUBSECTION>>External interface node" \
"A tool that provides the possibility to connect a virtual node with the physical interface (e.g. to give the node the access to the Internet)."

	"<<SUBSUBSUBSECTION>>RSTP switch node" \
"A Rapid Spanning Tree Protocol switch that can prevent bridge loops and allow providing backup links if an active link fails. (FreeBSD only)"

	"<<SUBSUBSUBSECTION>>Filter node" \
"A link layer element that can filter/divert/forward packets depending on their content. (FreeBSD only)"

	"<<SUBSUBSUBSECTION>>Packet generator node" \
"A link layer element to craft custom packets and send them with given packet rate. (FreeBSD only)"
}
lappend array_names "linklayertools"

set netlayertools_help_strings {
	"<<SUBSUBSECTION>>Network layer node tool" \
"This opens a list of network-layer (L3) nodes available for use:<<FAKENEWLINE>>
<<LEVEL1>>Router node
<<LEVEL1>>Host node
<<LEVEL1>>PC node
<<LEVEL1>>NAT64 node
<<LEVEL1>>External connection node
<<LEVEL1>>Netns node (Linux only)

**NOTE**: It is not possible to execute node types with red background on current architecture."

	"<<SUBSUBSUBSECTION>>Router node" \
"A network layer element that is capable of packet forwarding using the routes obtained by dynamic routing protocols (available through quagga or xorp by default installation or any other standard FreeBSD routing daemon)."

	"<<SUBSUBSUBSECTION>>Host node" \
"A network layer element that does not forward packets and has static routes. It starts standard network services, via portmap and inetd."

	"<<SUBSUBSUBSECTION>>PC node" \
"A network layer element that also does not forward packets and has static routes. Unlike host, it does not start any network services."

	"<<SUBSUBSUBSECTION>>NAT64 node" \
"A router node which is capable to enable translation between IPv4 and IPv6 protocols using a form of network address translation (NAT)."

	"<<SUBSUBSUBSECTION>>External connection node" \
"A tool that provides the possibility to connect your host PC with a virtual node by creating an interface on your computer."

	"<<SUBSUBSUBSECTION>>Netns node" \
"A Linux network namespace node that allows integration with existing namespaces and processes. (Linux only)"
}
lappend array_names "netlayertools"

set annotationtools_help_strings {
	"<<SUBSUBSECTION>>Annotations" \
"Create different types of graphical annotations on the canvas:<<FAKENEWLINE>>
<<LEVEL1>>Text annotation
<<LEVEL1>>Freeform annotation
<<LEVEL1>>Oval annotation
<<LEVEL1>>Rectangle annotation"

	"<<SUBSUBSUBSECTION>>Text annotation tool" \
"Create a text annotation on the canvas. Opens a basic text editor and places the text on the clicked location."

	"<<SUBSUBSUBSECTION>>Freeform annotation tool" \
"Create a freeform annotation on the canvas. Follows the mouse cursor and leaves a trail, similarly to a pen."

	"<<SUBSUBSUBSECTION>>Oval annotation tool" \
"Create an oval annotation on the canvas. Define upper-left and lower-right 'corners' of the oval to draw on the canvas."

	"<<SUBSUBSUBSECTION>>Rectangle annotation tool" \
"Create a rectangle annotation on the canvas. Define upper-left and lower-right corners of the rectangle to draw on the canvas."
}
lappend array_names "annotationtools"

set bottombar_help_strings {
	"<<LEVEL1>>Canvas list scrollbar<< 1>>" \
"<<BULLET_EXP>>Use this to scroll through the list of available canvases."

	"<<LEVEL1>>Canvas list<< 2>>" \
"<<BULLET_EXP>>A list of created canvases. The currently selected canvas is marked using a different color.\n<<LEVEL2>>Use left click to select the canvas, double click to rename it, or mouse-scroll to switch between different canvases.\n<<LEVEL2>>Double-click on the empty part of this element creates a new canvas with the default name."

	"<<LEVEL1>>Canvas scrollbar<< 3>>" \
"<<BULLET_EXP>>Used to move left/right and up/down on the canvas, if the canvas is not fully visible."

	"<<LEVEL1>>Status line<< 4>>" \
"<<BULLET_EXP>>Used for various informational messages such as: current execution/termination step, node/link details, etc."

	"<<LEVEL1>>Zoom level<< 5>>" \
"<<BULLET_EXP>>Current zoom level. Double-click to insert custom zoom percentage value, or right-click to choose a pre-defined value."

	"<<LEVEL1>>Scheduler time<< 6>>" \
"<<BULLET_EXP>>Current step for event scheduler - time in seconds from the event scheduling start."

	"<<LEVEL1>>Auto-rearrange status<< 7>>" \
"<<BULLET_EXP>>Notifies user that either `Auto rearrange all` or `Auto rearrange selected` is enabled."

	"<<LEVEL1>>Operational mode<< 8>>" \
"<<BULLET_EXP>>Shows current mode of operation:\n<<LEVEL2>>`edit mode` - the experiment is not executed, normal editing\n<<LEVEL2>>`exec mode` - the experiment is executed\n<<LEVEL2>>`pause mode` - the experiment is executed, but new elements will not trigger a runtime change"

	"<<LEVEL1>>Experiment ID<< 9>>" \
"<<BULLET_EXP>>Shows the currently running experiment ID (EID) if the experiment is running."
}
lappend array_names "bottombar"

set canvas_help_strings {
	"<<SUBSUBSECTION>>IMUNES canvas" \
"The main workspace where topology elements are created, positioned and connected."

	"<<SUBSUBSUBSECTION>>Canvas grid" \
"Alignment guide used for placing nodes more precisely."
}
lappend array_names "canvas"

set node_help_strings {
	"<<SUBSUBSECTION>>IMUNES Nodes" \
"Network devices and virtual systems that make up the topology. Double-click a node to configure it."
}
lappend array_names "node"

set ifaces_help_strings {
	"<<SUBSUBSECTION>>IMUNES interfaces" \
"Network interfaces belonging to nodes and used to connect links."
}
lappend array_names "ifaces"

set link_help_strings {
	"<<SUBSUBSECTION>>IMUNES links" \
"Connections between nodes used to transport packets and model network connectivity."

	"<<SUBSUBSUBSECTION>>Segment links" \
"Individual link segments that can be adjusted to modify link appearance on the canvas."
}
lappend array_names "link"

set annotation_help_strings {
	"<<SUBSUBSECTION>>IMUNES text annotations" \
"User-defined text labels displayed on the canvas."

	"<<SUBSUBSUBSECTION>>IMUNES oval annotations" \
"Oval graphical annotations."

	"<<SUBSUBSUBSECTION>>IMUNES rectangle annotations" \
"Rectangular graphical annotations."

	"<<SUBSUBSUBSECTION>>IMUNES freeform annotations" \
"Freehand drawings."
}
lappend array_names "annotation"

set confignode_help_strings {
	"<<SUBSECTION>>Node Options" \
"Right-clicking on the node opens a popup menu with options pertaining to that node."

	"<<LEVEL1>><<DHIDE:Node >>Configure" \
"Opens a *Configuration* window for this node to change functional options such as routing options, IP addresses, custom configuration, advanced options etc. For more information, check documentation section [Node Configuration]<<IHIDE:(#node-configuration)>> and sections for specific options."

	"<<SUBSECTION>>Node Configuration" \
"Double-clicking on the node (<Control> + double clicking if the node is running), or choosing *Configuration* from the right-click menu opens a window with options to configure for that specific node."

	"<<SUBSUBSECTION>>Node name" \
"Name that will be displayed next to the node. If this is a virtualized node, this will be configured as the node hostname."

	"<<SUBSUBSECTION>>Force node" \
"When applying the configuration, the node (or its interfaces) will be forcefully recreated/reconfigured with the currently configured values."

	"<<SUBSUBSECTION>>Custom static routes" \
"Add defined routes on node startup. Set one route per line in the format
a.b.c.d/prefix x.y.z.w

For example: 0.0.0.0/0 10.0.0.1"

	"<<SUBSUBSECTION>>Automatic default routes" \
"If *Enable automatic default routes* is enabled, IMUNES will dynamically generate default routes for this node and automatically add them on node startup.

You can see the default routes that will be generated in the *Automatic default routes* tab."

	"<<SUBSUBSECTION>>Configure External interface" \
"'Steal' an interface from the host OS.

Depending on the type of link it connects to, the interface is handled differently.

FreeBSD:<<FAKENEWLINE>>
<<LEVEL1>>*normal* link: the interface is moved to the experiment jail and bridged with the nodes interface
<<LEVEL1>>*direct* link: the interface is moved to the experiment jail and connected directly with the nodes interface
 
Linux:<<FAKENEWLINE>>
<<LEVEL1>>*normal* link: the interface is moved into the experiment netns and bridged with the nodes interface
<<LEVEL1>>*direct* link: a new macvlan (or ipvlan if wireless) interface is created, and moved to the nodes namespace"

    "<<SUBSUBSECTION>>Custom config" \
"If enabled, custom configuration(s) will be run instead of default behaviour. There are currently two custom configuration options: interfaces config and node config."

    "<<SUBSUBSECTION>>Custom interfaces config" \
"If enabled, custom interfaces configuration will be run instead of default behaviour from the 'Interfaces' tab. More information is available inside the custom config editor."

    "<<SUBSUBSECTION>>Custom node config" \
"If enabled, custom node configuration will be run instead of default commands. More information is available inside the custom config editor."

	"<<SUBSUBSECTION>>Open in external editor" \
"Open the selected custom configuration in external editor (configured in 'external_editor_command' custom variable).

Ignored if custom configuration is DISABLED.

Example values for 'external_editor_command' are:<<FAKENEWLINE>>
<<LEVEL1>>*xterm+vim* -	`{xterm -T \"%TITLE%\" -e \"vim %FILE_PATH%\"}`
<<LEVEL1>>*gedit* -	`{gedit --standalone %FILE_PATH%}`
<<LEVEL1>>*mousepad* -	`{mousepad --disable-server %FILE_PATH%}`
<<LEVEL1>>*kate* -	`{kate --block %FILE_PATH%}`
<<LEVEL1>>*vscode* -	`{code --wait --new-window %FILE_PATH%}`
<<LEVEL1>>*sublime* -	`{subl -n -w %FILE_PATH%}`
<<LEVEL1>>*gvim* -	`{gvim -f %FILE_PATH%}`

The external editor must quit, only then will IMUNES fetch the latest changes."

    "<<SUBSUBSECTION>>Services" \
"For each enabled service, the node will start its daemon on node startup."
}
lappend array_names "confignode"

set configlink_help_strings {
	"<<SUBSECTION>>Link Options" \
"Right-clicking on the link opens a popup menu with options pertaining to that link.<<FAKENEWLINE>>"

	"<<LEVEL1>><<DHIDE:Link >><<*>>Configure<<*>>" \
"<<BULLET_EXP>>Opens a *Configuration* window for this link to change functional and visual options such as bandwidth, delay, color, width, etc. For more information, check documentation section [Link Configuration]<<IHIDE:(#link-configuration)>> and sections for specific options."

	"<<LEVEL1>><<*>>Clear all settings<<*>>" \
"<<BULLET_EXP>>Remove all link emulation settings (bandwidth, delay, BER, loss, duplication) from the link. This change will immediately trigger link reconfiguration."

	"<<LEVEL1>><<*>>Direct link<<*>>" \
"<<BULLET_EXP>>Toggle between `normal` and `direct` link mode of operation: `normal` links use an intermediate bridge/switch and `direct` links connect endpoints directly without any intermediate elements. For `External interface` and `External connection` node types, the behaviour of the `direct` link changes depending on its peer. For more information about `direct` links, check documentation section [IMUNES Architecture]<<IHIDE:(#imunes-architecture)>>."

	"<<LEVEL1>><<*>>Delete<<DHIDE: link>><<*>>" \
"<<BULLET_EXP>>Remove the link, including the interfaces on both endpoints."

	"<<LEVEL1>><<*>>Delete<<DHIDE: link>> (keep interfaces)<<*>>" \
"<<BULLET_EXP>>Remove the link, but keep the interfaces on both endpoints. Due to the nature of `direct` links on Linux, interfaces will be first removed and then recreated."

	"<<LEVEL1>><<*>>Split<<DHIDE: link>><<*>>" \
"<<BULLET_EXP>>Visually splits the link and connects each endpoint to its peer's mirror `pseudo-node`. Each `pseudo-node` can be moved independently. When nodes are on different canvases, the links between them are automatically split. Splitting a segmented link temporarily removes its segmentation - the segmentation is restored when the link is merged. Split links cannot be segmented."

	"<<LEVEL1>><<*>>Merge<<DHIDE: link>><<*>>" \
"<<BULLET_EXP>>Reconnects a previously split link and deletes its `pseudo-nodes`. If the link was segmented before it was split, its previous segmentation is restored."

	"<<LEVEL1>><<*>>Segment<<DHIDE: link>><<*>>" \
"<<BULLET_EXP>>Adds a point to the middle of a link or an existing segment. The point can then be moved with the *Select tool* to change the appearance of the link. To delete a point, right-click it. Segmented links can be split - splitting temporarily removes the segmentation, which is restored when the link is merged."

	"<<SUBSECTION>>Link Configuration" \
"Double-clicking on the link, or choosing *Configuration* from the right-click menu opens a window with options to configure for that specific link."

	"<<SUBSUBSECTION>>Link from" \
"Defines the two endpoints connected by the link."

	"<<SUBSUBSECTION>>Link bandwidth" \
"Maximum link bandwidth in bits per second. Set this to 0 to leave bandwidth unlimited (or rather: limited by your hardware)."

	"<<SUBSUBSECTION>>Link delay" \
"Propagation delay added to packets crossing this link, in microseconds. Set this to 0 for no additional delay."

	"<<SUBSUBSECTION>>Link BER" \
"(FreeBSD only)

Bit error rate expressed as 1/N. Smaller non-zero N values produce errors more frequently. Set this to 0 to disable BER emulation."

	"<<SUBSUBSECTION>>Link packet loss" \
"(Linux only)

Percentage of packets dropped on this link. Set this to 0 for no artificial packet loss."

	"<<SUBSUBSECTION>>Link packet duplication" \
"Percentage of packets duplicated on this link. Set this to 0 to disable packet duplication."

	"<<SUBSUBSECTION>>Link width" \
"Width of the link line on the canvas. This changes only the visual representation of the link."

	"<<SUBSUBSECTION>>Link color" \
"Color of the link line on the canvas. This changes only the visual representation of the link."

	"<<NOSECTION>>Jitter mode" \
"<<DHIDE:Select how configured jitter values are applied. `sequential` uses the values in order; `random` selects values randomly.>>"

	"<<NOSECTION>>Jitter hold" \
"<<DHIDE:Time in milliseconds for which a selected jitter value remains active before the next value is used.>>"

	"<<NOSECTION>>Jitter values" \
"<<DHIDE:ist of jitter values in milliseconds, one value per line. Values are configured separately for each link direction.>>"
}
lappend array_names "configlink"

set advancedopts_help_strings {
	"<<NOSECTION>>Advanced virt options" \
"Additional options for Docker/Jail/others when creating the current node (such as mounts, CPUs, memory, etc)."

	"<<NOSECTION>>Advanced options types" \
"Each node has `generic`, `docker` and `jail` specific options. Generic options are available on all platforms, while `jail` and `docker` options only on FreeBSD and Linux."
	
	"<<SUBSUBSECTION>>Generic options" \
"These are the options that are available for every platform IMUNES runs on (FreeBSD/Linux)."

	"<<SUBSUBSUBSECTION>>Imported files" \
"Import (embed) host files in IMUNES topology file. Files are embedded as JSON arrays of plain text or, optionally, base64-encoded.

**NOTE**: embedding files increases total topology file size, base64-encoding even more so.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Imported file enabled<<*>>" \
"<<BULLET_EXP>>Enable or disable this imported file. Validation errors are ignored while the entry is disabled."

	"<<LEVEL1>><<*>>Imported file internal path<<*>>" \
"<<BULLET_EXP>>Destination of the imported file. Use either:
<<LEVEL2>>`absolute file path`,
<<LEVEL2>>`@node:path` - to link to an imported file from another node (linked entries cannot link to another linked entry)
<<LEVEL2>>`#hook:filename` - to make `filename` executed when hook is reached during deployCfg/undeployCfg.

Valid hooks are:<<FAKENEWLINE>>
<<LEVEL2>>pre-init_config - before the initial node configuration
<<LEVEL2>>post-init_config - after initial node configuration
<<LEVEL2>>pre-pifaces_create - before creating physical interfaces
<<LEVEL2>>post-pifaces_create - after creating physical interfaces
<<LEVEL2>>pre-pifaces_dcreate - before creating physical interfaces (direct links)
<<LEVEL2>>post-pifaces_dcreate - after creating physical interfaces (direct links)
<<LEVEL2>>pre-lifaces_create - before creating logical interfaces
<<LEVEL2>>post-lifaces_create - after creating logical interfaces
<<LEVEL2>>pre-ifaces_config - before configuring all interfaces
<<LEVEL2>>post-ifaces_config - after configuring all interfaces
<<LEVEL2>>pre-node_config - before configuring the node
<<LEVEL2>>post-node_config - after configuring the node
<<LEVEL2>>pre-node_unconfig - before unconfiguring the node
<<LEVEL2>>post-node_unconfig - after unconfiguring the node
<<LEVEL2>>pre-node_shutdown - before shutting down all processes on the node
<<LEVEL2>>post-node_shutdown - after shutting down all processes on the node
<<LEVEL2>>pre-ifaces_unconfig - before unconfiguring all interfaces
<<LEVEL2>>post-ifaces_unconfig - after unconfiguring all interfaces
<<LEVEL2>>pre-lifaces_destroy - before destroying logical interfaces
<<LEVEL2>>post-lifaces_destroy - after destroying logical interfaces
<<LEVEL2>>pre-pifaces_destroy - before destroying physical interfaces
<<LEVEL2>>post-pifaces_destroy - after destroying physical interfaces
<<LEVEL2>>pre-pifaces_ddestroy - before destroying physical interfaces (direct links)
<<LEVEL2>>post-pifaces_ddestroy - after destroying physical interfaces (direct links)
<<LEVEL2>>pre-node_destroy - before destroying the node"

	"<<LEVEL1>><<*>>Imported file mode<<*>>" \
"<<BULLET_EXP>>File permissions specified as a numeric mode, for example 644. An environment variable (a value starting with $) is also accepted."

	"<<LEVEL1>><<*>>Imported file edit<<*>>" \
"<<BULLET_EXP>>Edit the contents of the imported file using the built-in editor."

	"<<LEVEL1>><<*>>Imported file external edit<<*>>" \
"<<BULLET_EXP>>Edit the contents of the imported file using an external editor."

	"<<LEVEL1>><<*>>Imported file import<<*>>" \
"<<BULLET_EXP>>Select a local file and load its contents into this imported file entry."

	"<<LEVEL1>><<*>>Imported file encode<<*>>" \
"<<BULLET_EXP>>Store the file contents base64-encoded in the IMUNES configuration.  Use this for binary files or other content that should not be stored as plain text."

	"<<LEVEL1>><<*>>Imported file delete<<*>>" \
"<<BULLET_EXP>>Delete this imported file entry."

	"<<SUBSUBSUBSECTION>>Imported dirs" \
"Import (embed) host directories in IMUNES topology file. Directories are embedded as base64-encoded tar archives.
<<NEWLINE>>**NOTE**: embedding directories increases total topology file size.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Imported dir enabled<<*>>" \
"<<BULLET_EXP>>Enable or disable this imported directory. Validation errors are ignored while the entry is disabled."

	"<<LEVEL1>><<*>>Imported dir internal path<<*>>" \
"<<BULLET_EXP>>Destination of the imported directory. Use either:
<<LEVEL2>>`absolute directory path`,
<<LEVEL2>>`@node:path` - to link to an imported directory from another node (linked entries cannot link to another linked entry)
<<LEVEL2>>`#hook:dirname` - to save `dirname` in the `hook` folder.

Valid hooks are:<<FAKENEWLINE>>
<<LEVEL2>>pre-init_config - before the initial node configuration
<<LEVEL2>>post-init_config - after initial node configuration
<<LEVEL2>>pre-pifaces_create - before creating physical interfaces
<<LEVEL2>>post-pifaces_create - after creating physical interfaces
<<LEVEL2>>pre-pifaces_dcreate - before creating physical interfaces (direct links)
<<LEVEL2>>post-pifaces_dcreate - after creating physical interfaces (direct links)
<<LEVEL2>>pre-lifaces_create - before creating logical interfaces
<<LEVEL2>>post-lifaces_create - after creating logical interfaces
<<LEVEL2>>pre-ifaces_config - before configuring all interfaces
<<LEVEL2>>post-ifaces_config - after configuring all interfaces
<<LEVEL2>>pre-node_config - before configuring the node
<<LEVEL2>>post-node_config - after configuring the node
<<LEVEL2>>pre-node_unconfig - before unconfiguring the node
<<LEVEL2>>post-node_unconfig - after unconfiguring the node
<<LEVEL2>>pre-node_shutdown - before shutting down all processes on the node
<<LEVEL2>>post-node_shutdown - after shutting down all processes on the node
<<LEVEL2>>pre-ifaces_unconfig - before unconfiguring all interfaces
<<LEVEL2>>post-ifaces_unconfig - after unconfiguring all interfaces
<<LEVEL2>>pre-lifaces_destroy - before destroying logical interfaces
<<LEVEL2>>post-lifaces_destroy - after destroying logical interfaces
<<LEVEL2>>pre-pifaces_destroy - before destroying physical interfaces
<<LEVEL2>>post-pifaces_destroy - after destroying physical interfaces
<<LEVEL2>>pre-pifaces_ddestroy - before destroying physical interfaces (direct links)
<<LEVEL2>>post-pifaces_ddestroy - after destroying physical interfaces (direct links)
<<LEVEL2>>pre-node_destroy - before destroying the node"

	"<<LEVEL1>><<*>>Imported dir import<<*>>" \
"<<BULLET_EXP>>Select a local directory and import its contents. The directory contents are stored as a base64-encoded tar archive in the IMUNES configuration."

	"<<LEVEL1>><<*>>Imported dir delete<<*>>" \
"<<BULLET_EXP>>Delete this imported directory entry."

	"<<SUBSUBSECTION>>Jail options" \
"Node options available specifically for nodes running jails (on FreeBSD)."

	"<<SUBSUBSUBSECTION>>General jail options" \
"General options to attach to `jail -c` command<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Custom vroot<<*>>" \
"<<BULLET_EXP>>If enabled, IMUNES will use the given jail path (virtual root - vroot) instead of the default one when running the node. The default vroot is /var/imunes/vroot directory."

	"<<LEVEL1>><<*>>Custom image<<*>>" \
"<<BULLET_EXP>>If enabled, IMUNES will use the given Docker image (virtual root - vroot) instead of the default one when running the node. The default vroot is imunes/template Docker image."

	"<<SUBSUBSECTION>>Docker options" \
"Node options available specifically for nodes running Docker (on Linux)."

	"<<SUBSUBSUBSECTION>>General Docker options" \
"General options to attach to `docker run` command.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>External Docker interface<<*>>" \
"<<BULLET_EXP>>If enabled, IMUNES will create a Docker interface inside a node (`dext0`) connected to the imunes-bridge Docker network. This interface is primarily used to enable internet connection on a node in a quick and easy way - the default route is automatically added on its creation. Users should configure `/etc/resolv.conf` by themselves as DNS resolver is not set automatically."

	"<<LEVEL1>><<*>>CPUs count<<*>>" \
"<<BULLET_EXP>>The maximum CPU resources a node can use."

	"<<LEVEL1>><<*>>Custom jail flags<<*>>" \
"<<BULLET_EXP>>Insert any custom jail flags."

	"<<LEVEL1>><<*>>Custom Docker flags<<*>>" \
"<<BULLET_EXP>>Insert any custom Docker flags."

	"<<SUBSUBSUBSECTION>>Docker port forwardings" \
"Configure TCP, UDP, SCTP or any port mappings from the host to this Docker node. Each entry defines the protocol and host/container ports used by Docker.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Port forwarding enabled<<*>>" \
"<<BULLET_EXP>>Enable or disable this port forwarding rule. Disabled rules are kept in the configuration but are not applied."

	"<<LEVEL1>><<*>>Port forwarding host IP<<*>>" \
"<<BULLET_EXP>>Optional host IP address on which the forwarded port is exposed. Leave empty to use Docker's default host binding."

	"<<LEVEL1>><<*>>Port forwarding host port<<*>>" \
"<<BULLET_EXP>>Optional port number exposed on the host. Leave empty to let Docker automatically assign an available host port."

	"<<LEVEL1>><<*>>Port forwarding node port<<*>>" \
"<<BULLET_EXP>>Port number inside the Docker node to which incoming connections are forwarded."

	"<<LEVEL1>><<*>>Port forwarding protocol<<*>>" \
"<<BULLET_EXP>>Network protocol used by this port forwarding rule. Use tcp/udp/sctp or leave empty for any."

	"<<LEVEL1>><<*>>Port forwarding delete<<*>>" \
"<<BULLET_EXP>>Delete this port forwarding rule."

	"<<SUBSUBSUBSECTION>><<*>>Docker environment variables<<*>>" \
"Define environment variables passed to the Docker container when the node is created.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Environment variable enable<<*>>" \
"<<BULLET_EXP>>Enable or disable this environment variable. Disabled variables are kept in the configuration but are not applied."

	"<<LEVEL1>><<*>>Environment variable name<<*>>" \
"<<BULLET_EXP>>Name of the environment variable passed to the Docker container."

	"<<LEVEL1>><<*>>Environment variable value<<*>>" \
"<<BULLET_EXP>>Value assigned to the environment variable. The value may be left empty."

	"<<LEVEL1>><<*>>Environment variable deleted<<*>>" \
"<<BULLET_EXP>>Delete this environment variable."

	"<<SUBSUBSUBSECTION>>Docker volumes" \
"Configure host paths or Docker volumes that are mounted inside the node container.<<FAKENEWLINE>>"

	"<<LEVEL1>><<*>>Volume enabled<<*>>" \
"<<BULLET_EXP>>Enable or disable this volume. Disabled volumes are kept in the configuration but are not applied."

	"<<LEVEL1>><<*>>Volume type<<*>>" \
"<<BULLET_EXP>>Bind mount (host file/directoey) or Docker volume."

	"<<LEVEL1>><<*>>Volume source<<*>>" \
"<<BULLET_EXP>>Host path or Docker volume name to mount into the container."

	"<<LEVEL1>><<*>>Volume destination<<*>>" \
"<<BULLET_EXP>>Path inside the Docker container where the volume is mounted."

	"<<LEVEL1>><<*>>Volume read only<<*>>" \
"<<BULLET_EXP>>Mount the volume as read-only. When enabled, the container can read files from the volume but cannot modify them."

	"<<LEVEL1>><<*>>Volume delete<<*>>" \
"<<BULLET_EXP>>Delete this volume mapping."
}
lappend array_names "advancedopts"

set misc_help_strings {
	"<<SUBSECTION>>Editor Preferences" \
"<<LEVEL1>>`Active options` - Preview of currently active options combining Custom, Topology and Default options. The Default options are loaded first, overwritten by the Topology options and Custom options. If `custom_override` is enabled for the option, the Custom option will always overwrite the topology option.

<<LEVEL1>>`Custom options` - Options loaded from .rc files (`/etc/imunes/config`, `\$HOME/.imunes.rc` if it exists, otherwise `\$XDG_CONFIG_HOME/imunes/config`, `./.imunes.rc`, `/etc/imunes/override` - in that order). Apply button will save the configured options to the last loaded existing .rc file - not including /etc/imunes/override.

<<LEVEL1>>`Topology options` - Options loaded from, and saved to the .imn file - some options cannot be saved."
}
lappend array_names "misc"

set section_tags {
	{"NOSECTION"	""	"NOSECTION"}
	{"SECTION"	""	"# "}
	{"SUBSECTION"	""	"## "}
	{"SUBSUBSECTION"	""	"### "}
	{"SUBSUBSUBSECTION"	""	"#### "}
}

set nonsection_tags {
	{"LEVEL1"	""	"  * "}
	{"LEVEL2"	""	"  o "}
	{"\\*"	""	"*"}
	{"`"	""	"`"}
	{"( *)(\[0-9\]+)( *)"	""	"\\1(\\2)\\3"}
	{"DHIDE:(.*?)"	"\\1"	""}
}

set tags {
	{"INDENT1"	""	"    "}
	{"BULLET_EXP"	""	" - "}
	{"LEVEL1"	"  - "	"  * "}
	{"LEVEL2"	"    - "	"    - "}
	{"FAKENEWLINE"	""	"\n"}
	{"NEWLINE"	"\n"	"\n\n"}
	{"FIG:(.*?)"	""	"\\1"}
	{"IHIDE:(.*?)"	""	"\\1"}
	{"DHIDE:(.*?)"	"\\1"	""}
}

foreach array_name $array_names {
    upvar 0 ${array_name}_help_strings var_name
	dict for {section content} $var_name {
		foreach tag_line [concat $section_tags $nonsection_tags] {
			#set tag [lindex $tag_line 0]
			lassign $tag_line tag replace -
			regsub -all "<<$tag>>" $section $replace section
		}

		foreach tag_line $tags {
			lassign $tag_line tag replace -
			regsub -all "<<$tag>>" $content $replace content
		}

		lappend all $section $content
	}
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

	set main_frame $help_popup.main
	ttk::frame $main_frame -padding 4
	grid $main_frame -column 0 -row 0 -sticky nsew
	grid columnconfigure $help_popup 0 -weight 1
	grid rowconfigure $help_popup 0 -weight 1

	set image_obj [image create photo -file $ROOTDIR/$LIBDIR/icons/imunes_icon64.png]
	set image_label $main_frame.image_label
	ttk::label $image_label
	$image_label configure -image $image_obj

	set content_label $main_frame.content_label
	if { [string length $content] < 100 } {
		set wlength 0
	} else {
		set wlength 674
	}
	ttk::label $content_label -wraplength $wlength -text "$content"

	set close_button $main_frame.close_button
	ttk::button $close_button -text "Close" -command "destroy $help_popup"

	grid $image_label -column 0 -row 0 -padx 10 -pady 10 -sticky nw
	grid $content_label -column 1 -row 0 -padx 10 -pady 10 -sticky ns
	grid $close_button -column 0 -row 1 -padx 10 -columnspan 2
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

	#dputs "ADDING '$element' with '$title'"
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
