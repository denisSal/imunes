#!/usr/bin/env tclsh

#
# Generate Markdown documentation from gui/help.tcl
#

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file dirname $script_dir]

source [file join $repo_root gui help.tcl]

set output_dir [file join $repo_root generated-docs]
file delete -force $output_dir
file mkdir $output_dir

foreach array_name $array_names {
    upvar 0 ${array_name}_help_strings help_array

    set filename [file join $output_dir "${array_name}.md"]
    set fd [open $filename w]

    #puts $fd "# $array_name"
    #puts $fd ""

    dict for {key value} $help_array {
		set key_link [string tolower $key]
		set key_link [string map {" " "-"} $key_link]
		set key_link [string map {"(" "" ")" "" "\}" "" "\{" "" "\[" "\]"} $key_link]
        puts $fd "### \[$key\]\(#$key_link)"
        puts $fd ""

        set help_string $value
		set help_string [string map {"\n\n" "<DOUBLENEWLINE>"} $help_string]
		set help_string [string map {"\n" "\n\n"} $help_string]
		set help_string [string map {"<DOUBLENEWLINE>" "\n\n"} $help_string]

        puts $fd $help_string
        puts $fd ""
    }

    close $fd

    puts "Generated $filename"
}
