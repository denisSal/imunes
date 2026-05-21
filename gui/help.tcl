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

global help_strings
array set help_strings {
    "Custom image" "If enabled, IMUNES will use the given Docker image (virtual root - vroot) instead of the default one when running the node.\n\nThe default vroot is imunes/template Docker image."
    "Custom vroot" "If enabled, IMUNES will use the given jail path (virtual root - vroot) instead of the default one when running the node.\n\nThe default vroot is /var/imunes/vroot directory."
    "External Docker interface" "(Linux only)\n\nIf enabled, IMUNES will create a Docker interface inside a node (dext0) connected to the imunes-bridge Docker network.\n\nThis interface is primarily used to enable internet connection on a node in a quick and easy way - the default route is automatically added on its creation. Users should configure /etc/resolv.conf by themselves as DNS resolver is not set automatically."
    "Services" "For each enabled service, the node will start its daemon on node startup."
    "Routes" "Custom static routes - add defined routes on node startup. Set one route per line in the format\na.b.c.d/prefix x.y.z.w\n-> for example: 0.0.0.0/0 10.0.0.1\n\nAutomatic default routes - if enabled, IMUNES will dynamically generate default routes for this node and automatically add them on node startup. You can see the default routes that will be generated in the 'Automatic default routes' tab."
    "Custom config" "If enabled, custom configuration(s) will be run instead of default behaviour. There are currently two custom configuration options: interfaces config and node config."
    "Custom interfaces config" "If enabled, custom interfaces configuration will be run instead of default behaviour from the 'Interfaces' tab. More information is available inside the custom config editor."
    "Custom node config" "If enabled, custom node configuration will be run instead of default commands. More information is available inside the custom config editor."
    "Force node" "When applying the configuration, the node (or its interfaces) will be forcefully recreated/reconfigured with the currently configured values."
	"Configure External interface" "'Steal' an interface from the host OS.\nDepending on the type of link it connects to, the interface is handled differently.\n\nFreeBSD\n - 'normal' link: the interface is moved to the experiment jail and connected with the nodes interface over a bridge\n - 'direct' link: the interface is moved to the experiment jail and connected with the nodes interface without a bridge\n\nLinux\n - 'normal' link: the interface is moved to the experiment namespace and connected with the nodes interface over a bridge\n - 'direct' link: a new macvlan (or ipvlan if wireless) interface is created, and moved to the nodes namespace"
    "Advanced virt options" "Additional options for Docker/Jail/others when creating the current node (such as mounts, CPUs, memory, etc.)"
    "CPUs count" "The maximum CPU resources a node can use."
    "Custom flags" "Insert any custom Docker/jail flags."
	"Open in external editor" "Open the selected custom configuration in external editor (configured in 'external_editor_command' custom variable).\n\nIgnored if custom configuration is DISABLED."
	"Editor Preferences" "'Active options'\nPreview of currently active options combining Custom, Topology and Default options. The Default options are loaded first, overwritten by the Topology options and Custom options. If 'custom_override' is enabled for the option, the Custom option will always overwrite the topology option.\n\n'Custom options'\nOptions loaded from .rc files ('/etc/imunes/config', '\$HOME/.imunes.rc' if it exists, otherwise '\$XDG_CONFIG_HOME/imunes/config', './.imunes.rc', '/etc/imunes/override' - in that order). Apply button will save the configured options to the last loaded existing .rc file - not including /etc/imunes/override.\n\n'Topology options'\nOptions loaded from, and saved to the .imn file - some options cannot be saved."

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
	{"INSERT:(.*?)"	"" "\{\{include:generated-docs/\\1.md\}\}"}
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
