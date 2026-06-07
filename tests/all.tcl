package require tcltest
namespace import ::tcltest::*

set all "bpstelm"
set err "bel"

set verbose $err

configure -testdir [file dirname [info script]] -verbose $verbose {*}$::argv
runAllTests
