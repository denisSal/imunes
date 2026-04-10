addCase_updateNode "vm_parameters" {
	setNodeVMConfig $node_id $new_value
}

proc configGUI_VMConfig { wi node_id } {
	global guielements
	global vm_hdd_create
	lappend guielements configGUI_VMConfig
	global w w.hdd.path
	global cfg

	global node_cfg

	set cfg [_getNodeVMConfig $node_cfg]
	if { $cfg == {} } {
		set cfg [dict create]
		dict set cfg "hdd_path" ""
		dict set cfg "create_hdd" "false"
		dict set cfg "create_hdd_size" "20G"
		dict set cfg "iso_path" ""
		dict set cfg "memory_size" "2048M"
		dict set cfg "cpu_count" "2"
	}

	set vm_hdd_create [dict get $cfg "create_hdd"]
	set w $wi.vmConfig

	ttk::frame $w -borderwidth 2 -relief groove

	ttk::frame $w.hdd -borderwidth 2 -relief groove
	ttk::label $w.hdd.labelHDD -text "Hard disk:" -width 11
	ttk::entry $w.hdd.path -width 34
	$w.hdd.path insert 0 [dict get $cfg hdd_path]

	ttk::frame $w.hdd.create -relief groove
	ttk::checkbutton $w.hdd.create.label -text "Create virtual hard disk" -variable vm_hdd_create
	ttk::entry $w.hdd.create.size -width 15
	ttk::label $w.hdd.create.labelSize -text "Size:" -width 11
	$w.hdd.create.size insert 0 [dict get $cfg create_hdd_size]

	# TODO: naci koji sve tipovi podataka dolaze u obzir

	global hdd_file_types
	global iso_file_types
	set hdd_file_types {
		{ "QEMU image format" {.qcow2} }
		{ "All files" {*} }
	}

	set iso_file_types {
		{ "ISO format" {.iso} }
		{ "All files" {*} }
	}

	ttk::button $w.hdd.button -text "Choose file..." -command {
		set vm_hdd_path [tk_getOpenFile -filetypes $hdd_file_types]
		sputs $vm_hdd_path
		$w.hdd.path delete 0 end
		$w.hdd.path insert 0 $vm_hdd_path
		set w.hdd.path $vm_hdd_path
		dict set cfg "hdd_path" $vm_hdd_path
	}

	ttk::label $w.labelISO -text "ISO:" -width 11
	ttk::frame $w.iso
	ttk::entry $w.iso.path -width 34
	$w.iso.path insert 0 [dict get $cfg iso_path]
	ttk::button $w.iso.button -text "Choose file..." -command {
		set iso_path [tk_getOpenFile -filetypes $iso_file_types]
		sputs $iso_path
		$w.iso.path delete 0 end
		$w.iso.path insert 0 $iso_path
		set w.iso.path $iso_path
		dict set cfg "iso_path" $iso_path
	}
	#$w.iso.path insert 0 [dict get $cfg iso_path]

	ttk::label $w.labelMemory -text "Memory:" -width 11
	ttk::frame $w.memory
	ttk::entry $w.memory.size -width 34
	$w.memory.size insert 0 [dict get $cfg memory_size]

	ttk::label $w.labelCPUs -text "CPUs:" -width 11
	ttk::frame $w.cpu
	ttk::entry $w.cpu.count -width 34
	$w.cpu.count insert 0 [dict get $cfg cpu_count]

	set row -1
	pack $w -expand 1 -padx 1 -pady 1

	grid $w.hdd                  -in $w              -columnspan 2 -row [incr row] -pady 4 -padx 4
	grid $w.hdd.labelHDD         -in $w.hdd          -column 0 -row 0 -pady 4 -padx 4
	grid $w.hdd.path             -in $w.hdd          -column 1 -row 0
	grid $w.hdd.button           -in $w.hdd          -column 2 -row 0 -pady 4 -padx 4
	grid $w.hdd.create           -in $w.hdd          -columnspan 3 -row 1 -pady 4 -padx 4
	grid $w.hdd.create.label     -in $w.hdd.create   -columnspan 3 -row 0  -pady 1
	grid $w.hdd.create.labelSize -in $w.hdd.create   -column 0 -row 1 -pady 4 -padx 4
	grid $w.hdd.create.size      -in $w.hdd.create   -column 1 -row 1 -pady 4 -padx 4
	grid $w.labelISO             -in $w              -column 0 -row [incr row] -pady 4 -padx 4
	grid $w.iso                  -in $w              -column 1 -row $row -pady 4 -padx 4
	grid $w.iso.path             -in $w.iso          -column 1 -row 0
	grid $w.iso.button           -in $w.iso          -column 2 -row 0 -pady 4 -padx 4
	grid $w.labelMemory          -in $w              -column 0 -row [incr row] -pady 4 -padx 4
	grid $w.memory               -in $w              -column 1 -row $row -pady 4 -padx 4
	grid $w.memory.size          -in $w.memory       -column 0 -row 0
	grid $w.labelCPUs            -in $w              -column 0 -row [incr row] -pady 4 -padx 4
	grid $w.cpu                  -in $w              -column 1 -row $row -pady 4 -padx 4
	grid $w.cpu.count            -in $w.cpu          -column 0 -row 0
}

proc configGUI_VMConfigApply { wi node_id } {
	global node_cfg changed vm_hdd_create

	set w $wi.vmConfig

	set cfg [dict create]
	dict set cfg hdd_path [$w.hdd.path get]
	dict set cfg create_hdd $vm_hdd_create
	dict set cfg create_hdd_size [$w.hdd.create.size get]
	dict set cfg iso_path [$w.iso.path get]
	dict set cfg memory_size [$w.memory.size get]
	dict set cfg cpu_count [$w.cpu.count get]

	set node_cfg [_setNodeVMConfig $node_cfg $cfg]
	sputs $node_cfg
	set changed 1
}

proc _getNodeVMConfig { node_cfg } {
	return [_cfgGet $node_cfg "vm_parameters"]
}

proc _setNodeVMConfig { node_cfg vm_parameters } {
	return [_cfgSet $node_cfg "vm_parameters" $vm_parameters]
}

proc getNodeVMConfig { node_id } {
       return [cfgGet "nodes" $node_id "vm_parameters"]
}

proc setNodeVMConfig { node_id vm_parameters } {
       cfgSet "nodes" $node_id "vm_parameters" $vm_parameters
}
