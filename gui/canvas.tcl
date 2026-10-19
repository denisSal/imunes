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

# $Id: canvas.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/canvas.tcl
# NAME
#  canvas.tcl -- file used for manipultaion with canvases in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring
#  canvases in IMUNES. On each canvas a part of the simulation is presented
#  If there is no additional canvas defined, simulation is presented on the
#  defalut canvas.
#
#****

#****f* canvas.tcl/removeCanvas
# NAME
#   removeCanvas -- remove canvas
# SYNOPSIS
#   removeCanvas $canvas_id
# FUNCTION
#   Removes the canvas from simulation. This function does not change the
#   configuration of the nodes, i.e. nodes attached to the removed canvas
#   remain attached to the same non existing canvas.
# INPUTS
#   * canvas_id -- canvas id
#****
proc removeCanvas { canvas_id } {
	setToRunning_gui "canvas_list" [removeFromList [getFromRunning_gui "canvas_list"] $canvas_id]
	cfgUnset "gui" "canvases" $canvas_id
}

#****f* canvas.tcl/newCanvas
# NAME
#   newCanvas -- create new canvas
# SYNOPSIS
#   set canvas_id [newCanvas $name]
# FUNCTION
#   Creates new canvas. Returns the canvas_id of the new canvas.
#   If the canvas_name parameter is empty, the name of the new canvas
#   is set to CanvasN, where N represents the canvas_id of the new canvas.
# INPUTS
#   * name -- canvas name
# RESULT
#   * canvas_id -- canvas id
#****
proc newCanvas { name } {
	global sizex sizey

	set canvas_id [newObjectId [getFromRunning_gui "canvas_list"] "c"]
	lappendToRunning_gui "canvas_list" $canvas_id

	if { $name != "" } {
		setCanvasName $canvas_id $name
	} else {
		setCanvasName $canvas_id "Canvas[string range $canvas_id 1 end]"
	}

	lassign [getCanvasSize $canvas_id] sizex sizey

	return $canvas_id
}

#****f* canvas.tcl/setCanvasSize
# NAME
#   setCanvasSize -- set canvas size
# SYNOPSIS
#   setCanvasSize $canvas_id $x $y
# FUNCTION
#   Sets the specified canvas size.
# INPUTS
#   * canvas_id -- canvas id
#   * x -- width
#   * y -- height
#****
proc setCanvasSize { canvas_id x y } {
	cfgSet "gui" "canvases" $canvas_id "size" "$x $y"
}

#****f* canvas.tcl/getCanvasSize
# NAME
#   getCanvasSize -- get canvas size
# SYNOPSIS
#   getCanvasSize $canvas_id
# FUNCTION
#   Returns the specified canvas size.
# INPUTS
#   * canvas_id -- canvas id
# RESULT
#   * size -- canvas size in the form of {x y}
#****
proc getCanvasSize { canvas_id } {
	return [cfgGetWithDefault {900 620} "gui" "canvases" $canvas_id "size"]
}

#****f* canvas.tcl/getCanvasName
# NAME
#   getCanvasName -- get canvas name
# SYNOPSIS
#   set canvas_name [getCanvasName $canvas_id]
# FUNCTION
#   Returns the name of the canvas.
# INPUTS
#   * canvas_id -- canvas id
# RESULT
#   * canvas_name -- canvas name
#****
proc getCanvasName { canvas_id } {
	return [cfgGet "gui" "canvases" $canvas_id "name"]
}

#****f* canvas.tcl/setCanvasName
# NAME
#   setCanvasName -- set canvas name
# SYNOPSIS
#   setCanvasName $canvas_id $name
# FUNCTION
#   Sets the name of the canvas.
# INPUTS
#   * canvas_id -- canvas id
#   * name -- canvas name
#****
proc setCanvasName { canvas_id name } {
	return [cfgSet "gui" "canvases" $canvas_id "name" $name]
}

#****f* canvas.tcl/getCanvasBkg
# NAME
#   getCanvasBkg -- get canvas background image file name
# SYNOPSIS
#   set canvasBkgImage [getCanvasBkg $canvas_id]
# FUNCTION
#   Returns the name of the canvas background image file.
# INPUTS
#   * canvas_id -- canvas id
# RESULT
#   * canvasBkgImage -- image variable name
#****
proc getCanvasBkg { canvas_id } {
	return [cfgGet "gui" "canvases" $canvas_id "bkg_image"]
}

#****f* canvas.tcl/setCanvasBkg
# NAME
#   setCanvasBkg -- set canvas background
# SYNOPSIS
#   setCanvasBkg $canvas_id $name
# FUNCTION
#   Sets the background image for the canvas.
# INPUTS
#   * canvas_id -- canvas id
#   * name -- image variable name
#****
proc setCanvasBkg { canvas_id name } {
	return [cfgSet "gui" "canvases" $canvas_id "bkg_image" $name]
}

#****f* canvas.tcl/removeCanvasBkg
# NAME
#   removeCanvasBkg -- remove canvas background
# SYNOPSIS
#   removeCanvasBkg $canvas_id
# FUNCTION
#   Removes the background image for the current canvas.
# INPUTS
#   * canvas_id -- canvas id
#****
proc removeCanvasBkg { canvas_id } {
	cfgUnset "gui" "canvases" $canvas_id "bkg_image"
}

proc getCanvasAnnotationOrder { canvas_id } {
	return [cfgGet "gui" "canvases" $canvas_id "annotation_order"]
}

proc setCanvasAnnotationOrder { canvas_id new_order } {
	return [cfgSet "gui" "canvases" $canvas_id "annotation_order" $new_order]
}

#****f* canvas.tcl/setImageReference
# NAME
#   setImageReference -- set image reference
# SYNOPSIS
#   setImageReference $img $target
# FUNCTION
#   Sets the reference of the $target object to the
#   the image $img.
# INPUTS
#   * img -- image that is being used
#   * target -- the object that uses the image
#****
proc setImageReference { img target } {
	set ref_list [getImageReferences $img]
	lappend ref_list $target

	cfgSet "gui" "images" $img "referencedBy" [lsort -unique $ref_list]
}

#****f* canvas.tcl/getImageReferences
# NAME
#   getImageReferences -- get image reference
# SYNOPSIS
#   getImageReferences $img
# FUNCTION
#   Gets all the references to the image $img.
# INPUTS
#   * img -- image that can be referenced
# RESULT
#   * entry -- list of references to the image
#****
proc getImageReferences { img } {
	return [cfgGet "gui" "images" $img "referencedBy"]
}

#****f* canvas.tcl/removeImageReference
# NAME
#   removeImageReference -- remove image reference
# SYNOPSIS
#   removeImageReference $img $target
# FUNCTION
#   Removes the reference of the $target object to the image $img.
# INPUTS
#   * img -- image that is referenced
#   * target -- the object that references the image
#****
proc removeImageReference { img target } {
	cfgSet "gui" "images" $img "referencedBy" [removeFromList [getImageReferences $img] $target]
}

#****f* canvas.tcl/setImageType
# NAME
#   setImageType -- set image type
# SYNOPSIS
#   setImageType $img $type
# FUNCTION
#   Sets the image type of the image $img to the type $type.
# INPUTS
#   * img -- image
#   * type -- type of the image
#****
proc setImageType { img type } {
	cfgSet "gui" "images" $img "type" $type
}

#****f* canvas.tcl/getImageType
# NAME
#   getImageType -- get the type of an image
# SYNOPSIS
#   getImageType $img
# FUNCTION
#   Gets the image type of the image $img.
# INPUTS
#   * img -- image
# RESULT
#   * imageType -- the type of the image
#****
proc getImageType { img } {
	return [cfgGet "gui" "images" $img "type"]
}

#****f* canvas.tcl/setImageData
# NAME
#   setImageData -- set image data
# SYNOPSIS
#   setImageData $img $path
# FUNCTION
#   Sets image data for variable img.
# INPUTS
#   * img -- image variable
#   * path -- path to image file
#****
proc setImageData { img path } {
	set f [open $path]
	fconfigure $f -translation binary

	set data [read -nonewline $f]
	set enc_data [base64::encode -maxlen 0 $data]
	#set enc_data [string map {"\n" "\n          "} $enc_data]

	cfgSet "gui" "images" $img "data" $enc_data
}

#****f* canvas.tcl/getImageData
# NAME
#   getImageData -- get image data
# SYNOPSIS
#   getImageData $img
# FUNCTION
#   Returns image data for img.
# INPUTS
#   * img -- image variable
# RESULT
#   * data -- image data
#****
proc getImageData { img } {
	set entry [cfgGet "gui" "images" $img "data"]
	set enc [string trim $entry \{\}]
	set enc [string trim $enc " "]
	set data [base64::decode $enc]

	return $data
}

#****f* canvas.tcl/setImageZoomData
# NAME
#   setImageZoomData -- set image zoom data
# SYNOPSIS
#   setImageZoomData $img $path $zoom
# FUNCTION
#   Sets image zoom data.
# INPUTS
#   * img -- image variable
#   * path -- path to image file
#   * zoom -- zoom percentage
#****
proc setImageZoomData { img path zoom } {
	set f [open $path]
	fconfigure $f -translation binary

	set data [read -nonewline $f]
	set enc_data [base64::encode -maxlen 0 $data]
	#set enc_data [string map {"\n" "\n          "} $enc_data]

	cfgSet "gui" "images" $img "zoom_$zoom" $enc_data
}

#****f* canvas.tcl/getImageZoomData
# NAME
#   getImageZoomData -- get image zoom data
# SYNOPSIS
#   getImageZoomData $img $zoom
# FUNCTION
#   Returns image zoom data.
# INPUTS
#   * img -- image variable
#   * zoom -- zoom percentage
# RESULT
#   * data -- image zoom data
#****
proc getImageZoomData { img zoom } {
	set entry [cfgGet "gui" "images" $img "zoom_$zoom"]
	set enc [string trim $entry \{\}]
	set enc [string trim $enc " "]
	set data [base64::decode $enc]

	return $data
}

#****f* canvas.tcl/setImageFile
# NAME
#   setImageFile -- set image file
# SYNOPSIS
#   setImageFile $img $file
# FUNCTION
#   Sets image filename.
# INPUTS
#   * img -- image variable
#   * file -- image filename
#****
proc setImageFile { img file } {
	cfgSet "gui" "images" $img "file" $file
}

#****f* canvas.tcl/getImageFile
# NAME
#   getImageFile -- get image file
# SYNOPSIS
#   getImageFile $img
# FUNCTION
#   Returns image filename.
# INPUTS
#   * img -- image variable
# RESULT
#   * file -- image filename
#****
proc getImageFile { img } {
	return [cfgGet "gui" "images" $img "file"]
}

#****f* canvas.tcl/loadImage
# NAME
#   loadImage -- load the image into running memory
# SYNOPSIS
#   loadImage $path $ref $type
# FUNCTION
#   Load the image from the position $path into memory
#   so that it can be used in the actual project.
# INPUTS
#   * path -- path to the image
#   * ref -- object that loads the image and references it
#   * type -- type of image (custom icon or canvas background)
#   * file -- image filename
# RESULT
#   * imageName -- name of the variable which now contains the image
#****
proc loadImage { path ref type file } {
	set image_list [getFromRunning_gui "image_list"]

	if { [file exists $path] != 1 } {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" \
			"Couldn\'t find image file." \
			info 0 Dismiss
		return 2
	}

	set imgname [newObjectId $image_list "image"]
	lappendToRunning_gui "image_list" $imgname

	setImageData $imgname $path
	setImageFile $imgname [relpath $file]

	if { $ref != "" } {
		setImageReference $imgname $ref
	}

	setImageType $imgname $type

	return $imgname
}

#****f* canvas.tcl/random
# NAME
#   random -- random
# SYNOPSIS
#   random $range $start
# FUNCTION
#   Returns a random number between start and start+range.
# INPUTS
#   * range -- range of numbers
#   * start -- first number
# RESULT
#   * rnd -- random number
#****
proc random { range start } {
	return [expr {int(rand()*$range+$start)}]
}

#****f* editor.tcl/printCanvas
# NAME
#   printCanvas -- print canvas
# SYNOPSIS
#   printCanvas $w
# FUNCTION
#   This procedure is called when the print button in
#   print dialog box is pressed.
# INPUTS
#   * w -- print dialog widget
#****
proc printCanvas { w } {
	global sizex sizey main_canvas_elem

	set prncmd [$w.printframe.e1 get]
	destroy $w
	set p [open "|$prncmd" WRONLY]
	puts $p [$main_canvas_elem postscript -height $sizey -width $sizex -x 0 -y 0 -rotate yes -pageheight 297m -pagewidth 210m]
	close $p
}

#****f* editor.tcl/printCanvasToFile
# NAME
#   printCanvasToFile -- print canvas to file
# SYNOPSIS
#   printCanvasToFile $w $entry
# FUNCTION
#   This procedure is called when the print to file
#   button in print to file dialog box is pressed.
# INPUTS
#   * w -- print to file dialog widget
#   * entry -- file name
#****
proc printCanvasToFile { w entry } {
	global printFileType main_canvas_elem

	set entry_string [$entry get]
	if { $entry_string == "" } {
		return
	}

	try {
		set file_id [open $entry_string "w+"]
		close $file_id
	} on error msg {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" \
			$msg \
			info 0 Dismiss

		return
	}

	set start_canvas [getFromRunning_gui "curcanvas"]
	set modified_bkp [getFromRunning "modified"]
	set font_bkp [dict create]
	foreach annotation_id [getFromRunning_gui "annotation_list"] {
		if { [getAnnotationType $annotation_id] != "text" } {
			continue
		}

		set font [getAnnotationFont $annotation_id]
		dict set font_bkp $annotation_id $font

		set font [font actual $font]
		if { [dict get $font "-slant"] == "italic" } {
			set factor 0.7
		} else {
			set factor 0.75
		}

		dict set font "-size" [expr int([dict get [font actual $font] "-size"] / $factor)]
		setAnnotationFont $annotation_id $font
	}

	set msg ""
	try {
		set file_id [file tempfile psname]

		foreach canvas_id [getFromRunning_gui "canvas_list"] {
			setToRunning_gui "curcanvas" $canvas_id
			switchCanvas none

			set sizex [expr {[lindex [getCanvasSize $canvas_id] 0]}]
			set sizey [expr {[lindex [getCanvasSize $canvas_id] 1]}]

			puts $file_id [$main_canvas_elem postscript -height $sizey -width $sizex -x 0 -y 0 -rotate yes -pageheight 390m -pagewidth 276m]
		}
		close $file_id

		if { $printFileType == "pdf" } {
			foreach bad_font "UbuntuMono NotoSans" {
				catch { exec sed -i -e "s/$bad_font\\(\[^-]\\)/$bad_font-Regular\\1/" $psname }
			}

			exec ps2pdf -dPDFSETTINGS=/screen $psname $entry_string
			exec rm $psname
		} else {
			exec mv $psname $entry_string
		}

		file delete $psname
	} on error msg {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" \
			$msg \
			info 0 Dismiss
	}

	dict for {annotation_id font} $font_bkp {
		setAnnotationFont $annotation_id $font
	}
	setToRunning "modified" $modified_bkp

	setToRunning_gui "curcanvas" $start_canvas
	switchCanvas none

	if { $msg == "" } {
		destroy $w
	}
}

#****f* editor.tcl/renameCanvasPopup
# NAME
#   renameCanvasPopup -- rename canvas popup
# SYNOPSIS
#   renameCanvasPopup
# FUNCTION
#   Tk widget for renaming the canvas.
#****
proc renameCanvasPopup {} {
	set w .entry1
	catch { destroy $w }
	toplevel $w -takefocus 1
	wm transient $w .
	wm resizable $w 0 0

	wm title $w "Canvas rename"
	wm iconname $w "Canvas rename"

	#dodan glavni frame "renameframe"
	ttk::frame $w.renameframe
	pack $w.renameframe -fill both -expand 1

	ttk::label $w.renameframe.msg -wraplength 5i -justify left -text "Canvas name:"
	pack $w.renameframe.msg -side top

	ttk::frame $w.renameframe.buttons
	pack $w.renameframe.buttons -side bottom -fill x -pady 2m
	ttk::button $w.renameframe.buttons.print -text "Apply" -command "renameCanvasApply $w"
	ttk::button $w.renameframe.buttons.cancel -text "Cancel" -command "destroy $w"
	pack $w.renameframe.buttons.print $w.renameframe.buttons.cancel -side left -expand 1

	bind $w <Key-Escape> "destroy $w"
	bind $w <Key-Return> "renameCanvasApply $w"

	ttk::entry $w.renameframe.e1
	$w.renameframe.e1 insert 0 [getCanvasName [getFromRunning_gui "curcanvas"]]
	pack $w.renameframe.e1 -side top -pady 5 -padx 10 -fill x
}

#****f* editor.tcl/resizeCanvasPopup
# NAME
#   resizeCanvasPopup -- resize canvas popup
# SYNOPSIS
#   resizeCanvasPopup
# FUNCTION
#   Creates a popup dialog box for resizing canvas.
#****
proc resizeCanvasPopup {} {
	set w .entry1
	catch { destroy $w }
	toplevel $w -takefocus 1
	wm transient $w .
	wm resizable $w 0 0
	wm title $w "Canvas resize"
	wm iconname $w "Canvas resize"

	set curcanvas [getFromRunning_gui "curcanvas"]

	set minWidth [lindex [getMostDistantNodeCoordinates] 0]
	set minHeight [lindex [getMostDistantNodeCoordinates] 1]

	ttk::frame $w.resizeframe
	pack $w.resizeframe -fill both -expand 1

	ttk::label $w.resizeframe.msg -wraplength 5i -justify left -text "Canvas size:"
	pack $w.resizeframe.msg -side top

	ttk::frame $w.resizeframe.buttons
	pack $w.resizeframe.buttons -side bottom -fill x -pady 2m

	set fit_command [list apply {
		{ w } {
			global mf

			set padx 56
			set pady 56
			$w.resizeframe.size.x set [expr [winfo width $mf.canvas_elem] - $padx]
			$w.resizeframe.size.y set [expr [winfo height $mf.canvas_elem] - $pady]
		}
	} \
		$w
	]
	ttk::button $w.resizeframe.buttons.fit -text "Fit window" -command $fit_command
	ttk::button $w.resizeframe.buttons.print -text "Apply" -command "resizeCanvasApply $w"
	ttk::button $w.resizeframe.buttons.cancel -text "Cancel" -command "destroy $w"
	pack $w.resizeframe.buttons.fit $w.resizeframe.buttons.print $w.resizeframe.buttons.cancel -side left -expand 1 -padx 2
	bind $w <Key-Escape> "destroy $w"
	bind $w <Key-Return> "resizeCanvasApply $w"

	ttk::frame $w.resizeframe.size
	pack $w.resizeframe.size -side top -fill x -pady 2m
	ttk::spinbox $w.resizeframe.size.x -width 4 \
		-validate focus -invalidcommand "focusAndFlash %W"
	$w.resizeframe.size.x insert 0 [lindex [getCanvasSize $curcanvas] 0]
	$w.resizeframe.size.x configure -from $minWidth -to 4096 -increment 2 \
		-validatecommand "checkIntRange %P $minWidth 4096"
	ttk::label $w.resizeframe.size.label -text "*"
	ttk::spinbox $w.resizeframe.size.y -width 4 \
		-validate focus -invalidcommand "focusAndFlash %W"
	$w.resizeframe.size.y insert 0 [lindex [getCanvasSize $curcanvas] 1]
	$w.resizeframe.size.y configure -from $minHeight -to 4096 -increment 2 \
		-validatecommand "checkIntRange %P $minHeight 4096"

	pack $w.resizeframe.size.x $w.resizeframe.size.label $w.resizeframe.size.y -side left -expand 1 -pady 5 -padx 2 -fill y
}

#****f* editor.tcl/renameCanvasApply
# NAME
#   renameCanvasApply -- rename canvas apply
# SYNOPSIS
#   renameCanvasApply $w
# FUNCTION
#   This procedure is called by clicking on apply button in rename
#   canvas popup dialog box. It renames the current canvas.
# INPUTS
#   * w -- tk widget (rename canvas popup dialog box)
#****
proc renameCanvasApply { w } {
	global changed

	set curcanvas [getFromRunning_gui "curcanvas"]

	set newname [$w.renameframe.e1 get]
	destroy $w
	if { $newname == [getCanvasName $curcanvas] } {
		return
	}

	setCanvasName $curcanvas $newname
	switchCanvas none

	set changed 1
	updateUndoLog
}

#****f* editor.tcl/resizeCanvasApply
# NAME
#   resizeCanvasApply -- resize canvas apply
# SYNOPSIS
#   resizeCanvasApply $w
# FUNCTION
#   This procedure is called by clicking on apply button in resize
#   canvas popup dialog box. It resizes the current canvas.
# INPUTS
#   * w -- tk widget (resize canvas popup dialog box)
#****
proc resizeCanvasApply { w } {
	global changed

	set curcanvas [getFromRunning_gui "curcanvas"]

	if { [getCanvasBkg $curcanvas] != "" } {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" \
			"Cannot resize canvas with background image!" \
			info 0 Dismiss

		return
	}

	set x [$w.resizeframe.size.x get]
	set y [$w.resizeframe.size.y get]
	lassign [getMostDistantNodeCoordinates] ix iy

	if { $ix > $x || $iy > $y } {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" \
			"Canvas not big enough for existing nodes!" \
			info 0 Dismiss

		return
	}

	destroy $w
	if { "$x $y" == [getCanvasSize $curcanvas] } {
		return
	}

	setCanvasSize $curcanvas $x $y
	switchCanvas none

	set changed 1
	updateUndoLog
}

proc snapCanvasNodesToGrid {} {
	global main_canvas_elem changed sizex sizey

	set zoom [getActiveOption "zoom"]

	set redraw_needed 0

	foreach img [$main_canvas_elem find withtag "node"] {
		set node_id [lindex [$main_canvas_elem gettags $img] 1]
		lassign [$main_canvas_elem coords $img] view_x view_y
		set orig_x [expr { $view_x / $zoom }]
		set orig_y [expr { $view_y / $zoom }]

		lassign [snapCoordsToGrid $orig_x $orig_y] x y
		if { $x < 0 || $y < 0 || $x > $sizex || $y > $sizey } {
			set regular false
		} elseif { $orig_x != $x || $orig_y != $y } {
			lassign [getNodeCoords $node_id] orig_x orig_y

			set dx [expr { $x - $orig_x }]
			set dy [expr { $y - $orig_y }]

			lassign [getNodeLabelCoords $node_id] orig_lx orig_ly
			set lx [expr { $orig_lx + $dx }]
			set ly [expr { $orig_ly + $dy }]

			if { $lx < 0 || $ly < 0 || $lx > $sizex || $ly > $sizey } {
				set regular false
			} elseif { "$orig_lx $orig_ly" != "$lx $ly" } {
				#moving the nodelabel and selectbox assigned to the moving node

				set view_dx [expr { int($dx / $zoom) }]
				set view_dy [expr { int($dy / $zoom) }]

				setNodeCoords $node_id "$x $y"
				$main_canvas_elem move "selectmark && $node_id" $view_dx $view_dy

				setNodeLabelCoords $node_id "$lx $ly"
				$main_canvas_elem move "nodelabel && $node_id" $view_dx $view_dy

				$main_canvas_elem addtag need_redraw withtag "link && $node_id"
				set changed 1
				set redraw_needed 1
			}
		}
	}

	return $redraw_needed
}
