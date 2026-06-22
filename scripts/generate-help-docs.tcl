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

set section_tags {
	{"NOSECTION"	""	"NOSECTION"}
	{"SECTION"	""	"# "}
	{"SUBSECTION"	""	"## "}
	{"SUBSUBSECTION"	""	"### "}
	{"SUBSUBSUBSECTION"	""	"#### "}
}

set nonsection_tags {
	{"LEVEL1"	""	"  * "}
	{"\\*"	""	"*"}
	{"`"	""	"`"}
	{"( *)(\[0-9\])+( *)"	""	"\\1(\\2)\\3"}
}

set tags {
	{"INDENT1"	""	"    "}
	{"BULLET_EXP"	""	" - "}
	{"LEVEL1"	"  - "	"  * "}
	{"LEVEL2"	"    - "	"    - "}
	{"FAKENEWLINE"	""	"\n"}
	{"NEWLINE"	"\n"	"\n\n"}
}

foreach array_name $array_names {
    upvar 0 ${array_name}_help_strings help_array

    set filename [file join $output_dir "${array_name}.md"]
    set fd [open $filename w]

    dict for {key value} $help_array {
		set level ""
		foreach tag_line $section_tags {
			lassign $tag_line tag - replace

			if { [regsub -all "<<$tag>>" $key "" pure_key] > 0 } {
				set level $replace

				set key_link [string tolower $pure_key]
				regsub -all " " $key_link "-" key_link
				regsub -all "\[(){}\[\\\]\]" $key_link "" key_link
				set key "\[$pure_key\]\(#$key_link\)"

				break
			}
		}

		foreach tag_line $nonsection_tags {
			lassign $tag_line tag - replace
			regsub -all "<<$tag>>" $key $replace key
		}

		if { $level != "NOSECTION" } {
			if { $level != "" } {
				puts $fd "$level$key\n"
			} else {
				foreach tag_line $tags {
					lassign $tag_line tag - replace
					regsub -all "<<$tag>>" $key $replace key
				}

				puts -nonewline $fd "$key"
			}
		}

		foreach tag_line $tags {
			lassign $tag_line tag - replace
			regsub -all "<<$tag>>" $value $replace value
		}

        puts $fd $value
    }

    close $fd

    puts "Generated $filename"
}
