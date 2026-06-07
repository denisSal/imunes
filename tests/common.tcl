package require tcltest
namespace import ::tcltest::*

set saved_argv $::argv
set ::argv {}

source imunes.tcl

if { [llength [info commands tk_messageBox]] } {
	rename tk_messageBox __real_tk_dialog

	proc tk_messageBox { args } {
		# args = window title message bitmap default button...
		puts "DIALOG SUPPRESSED: $args"

		# simulate clicking the default button (usually 0)
		return 0
	}
}

proc tk_dialog { args } {
	# args = window title message bitmap default button...
	puts "DIALOG SUPPRESSED: $args"

	# simulate clicking the default button (usually 0)
	return 0
}

rename after __real_after

proc after { ms args } {
	if { $ms == "idle" } {
		return
	}

	uplevel 1 [list __real_after $ms {*}$args]
}

set save_argv $::argv
set ::argv $saved_argv
