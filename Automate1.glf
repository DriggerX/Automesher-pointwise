# Fidelity Pointwise V18.6 Journal file - Fri Jun 28 16:50:18 2024
# Load Pointwise Glyph package and Tk
package require PWI_Glyph
pw::Script loadTk

# AIRFOIL GUI INFORMATION
# -----------------------------------------------
set naca 0012
set sharp 0
wm title . "Airfoil Generator"
grid [ttk::frame .c -padding "5 5 5 5"] -column 0 -row 0 -sticky nwes
grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1
grid [ttk::labelframe .c.lf -padding "5 5 5 5" -text "NACA 4-Series Airfoil Generator"]
grid [ttk::label .c.lf.nacal -text "NACA"] -column 1 -row 1 -sticky e
grid [ttk::entry .c.lf.nacae -width 5 -textvariable naca] -column 2 -row 1 -sticky e
grid [ttk::frame .c.lf.te] -column 3 -row 1 -sticky e
grid [ttk::radiobutton .c.lf.te.sharprb -text "Sharp" -value 1 -variable sharp] -column 1 -row 1 -sticky w
grid [ttk::radiobutton .c.lf.te.bluntrb -text "Blunt" -value 0 -variable sharp] -column 1 -row 2 -sticky w
grid [ttk::button .c.lf.gob -text "CREATE" -command airfoilGen] -column 4 -row 1 -sticky e
foreach w [winfo children .c.lf] {grid configure $w -padx 10 -pady 10}
focus .c.lf.nacae
::tk::PlaceWindow . widget
bind . <Return> {airfoilGen}

proc airfoilGen {} {

# AIRFOIL INPUTS
# -----------------------------------------------
# m = maximum camber 
# p = maximum camber location 
# t = maximum thickness
set m [expr {[string index $::naca 0]/100.0}]  
set p [expr {[string index $::naca 1]/10.0}] 
set a [string index $::naca 2]
set b [string index $::naca 3]
set c "$a$b"
scan $c %d c
set t [expr {$c/100.0}]
set s $::sharp

# GENERATE AIRFOIL COORDINATES
# -----------------------------------------------
# Initialize Arrays
set x {}
set xu {}
set xl {}
set yu {}
set yl {}
set yc {0}
set yt {}

# Airfoil step size
set ds 0.001

# Check if airfoil is symmetric or cambered
if {$m == 0 && $p == 0 || $m == 0 || $p == 0} {set symm 1} else {set symm 0}

# Get x coordinates
for {set i 0} {$i < [expr {1+$ds}]} {set i [expr {$i+$ds}]} {lappend x $i}

# Calculate mean camber line and thickness distribution
foreach xx $x {

	# Mean camber line definition for symmetric geometry
	if {$symm == 1} {lappend yc 0}

	# Mean camber line definition for cambered geometry
	if {$symm == 0 && $xx <= $p} {
		lappend yc [expr {($m/($p**2))*(2*$p*$xx-$xx**2)}]
	} elseif {$symm == 0 && $xx > $p} {
		lappend yc [expr {($m/((1-$p)**2)*(1-2*$p+2*$p*$xx-$xx**2))}]
	}

	# Thickness distribution
    if {$s} {
	    lappend yt [expr {($t/0.20)*(0.29690*sqrt($xx)-0.12600*$xx- \
	                      0.35160*$xx**2+0.28430*$xx**3-0.1036*$xx**4)}]
    } else {
	    lappend yt [expr {($t/0.20)*(0.29690*sqrt($xx)-0.12600*$xx- \
	                      0.35160*$xx**2+0.28430*$xx**3-0.1015*$xx**4)}]
    }

	# Theta
	set dy [expr {[lindex $yc end] - [lindex $yc end-1]}]
	set th [expr {atan($dy/$ds)}]

	# Upper x and y coordinates
	lappend xu [expr {$xx-[lindex $yt end]*sin($th)}]
	lappend yu [expr {[lindex $yc end]+[lindex $yt end]*cos($th)}]

	# Lower x and y coordinates
	lappend xl [expr {$xx+[lindex $yt end]*sin($th)}]
	lappend yl [expr {[lindex $yc end]-[lindex $yt end]*cos($th)}]

}

# GENERATE AIRFOIL GEOMETRY
# -----------------------------------------------
# Create upper airfoil surface
set airUpper [pw::Application begin Create]
set airUpperPts [pw::SegmentSpline create]

for {set i 0} {$i < [llength $x]} {incr i} {
	$airUpperPts addPoint [list [lindex $xu $i] [lindex $yu $i] 0]
}

set airUpperCurve [pw::Curve create]
$airUpperCurve addSegment $airUpperPts
$airUpper end

# Create lower airfoil surface
set airLower [pw::Application begin Create]
set airLowerPts [pw::SegmentSpline create]

for {set i 0} {$i < [llength $x]} {incr i} {
	$airLowerPts addPoint [list [lindex $xl $i] [lindex $yl $i] 0]
}

set airLowerCurve [pw::Curve create]
$airLowerCurve addSegment $airLowerPts
$airLower end

if {!$s} {
    # Create flat trailing edge
    set airTrail [pw::Application begin Create]
    set airTrailPts [pw::SegmentSpline create]
    $airTrailPts addPoint [list [lindex $xu end] [lindex $yu end] 0]
    $airTrailPts addPoint [list [lindex $xl end] [lindex $yl end] 0]
    set airTrailCurve [pw::Curve create]
    $airTrailCurve addSegment $airTrailPts
    $airTrail end
}


# Zoom to airfoil geometry
pw::Display resetView


package require PWI_Glyph 6.22.1

pw::Application setUndoMaximumLevels 5

set _DB(1) [pw::DatabaseEntity getByName curve-1]
set _DB(2) [pw::DatabaseEntity getByName curve-3]
set _DB(3) [pw::DatabaseEntity getByName curve-2]
set _TMP(PW_1) [pw::Connector createOnDatabase -parametricConnectors Aligned -merge 0 -reject _TMP(unused) [list $_DB(1) $_DB(2) $_DB(3)]]
unset _TMP(unused)
unset _TMP(PW_1)
pw::Application markUndoLevel {Connectors On DB Entities}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  set _CN(1) [pw::GridEntity getByName con-1]
  set _CN(2) [pw::GridEntity getByName con-3]
  $_TMP(PW_1) addPoint [$_CN(1) getPosition -arc 1]
  $_TMP(PW_1) addPoint [pwu::Vector3 add [pw::Application getXYZ [$_CN(1) getPosition -arc 1]] {10 0 0}]
  set _CN(3) [pw::Connector create]
  $_CN(3) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(3) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  set _CN(4) [pw::GridEntity getByName con-2]
  $_TMP(PW_1) delete
  unset _TMP(PW_1)
$_TMP(mode_1) abort
unset _TMP(mode_1)
set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(4) getPosition -arc 1]
  $_TMP(PW_1) addPoint [pwu::Vector3 add [pw::Application getXYZ [$_CN(4) getPosition -arc 1]] {10 0 0}]
  set _CN(5) [pw::Connector create]
  $_CN(5) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(5) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(1) getPosition -arc 1]
  $_TMP(PW_1) addPoint {1 10 0}
  set _CN(6) [pw::Connector create]
  $_CN(6) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(6) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(4) getPosition -arc 1]
  $_TMP(PW_1) addPoint {1 -10 0}
  set _CN(7) [pw::Connector create]
  $_CN(7) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(7) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(6) getPosition -arc 1]
  $_TMP(PW_1) addPoint [pwu::Vector3 add [$_CN(6) getPosition -arc 1] {10 0 0}]
  set _CN(8) [pw::Connector create]
  $_CN(8) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(8) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(7) getPosition -arc 1]
  $_TMP(PW_1) addPoint [pwu::Vector3 add [$_CN(7) getPosition -arc 1] {10 0 0}]
  set _CN(9) [pw::Connector create]
  $_CN(9) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(9) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(5) getPosition -arc 1]
  $_TMP(PW_1) addPoint {11 -10 0}
  set _CN(10) [pw::Connector create]
  $_CN(10) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(10) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(3) getPosition -arc 1]
  $_TMP(PW_1) addPoint {11 10 0}
  set _CN(11) [pw::Connector create]
  $_CN(11) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(11) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) addPoint [$_CN(3) getPosition -arc 1]
  $_TMP(PW_1) addPoint [$_CN(5) getPosition -arc 1]
  set _CN(12) [pw::Connector create]
  $_CN(12) addSegment $_TMP(PW_1)
  unset _TMP(PW_1)
  $_CN(12) calculateDimension
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create 2 Point Connector}

set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentSpline create]
  $_TMP(PW_1) delete
  unset _TMP(PW_1)
$_TMP(mode_1) abort
unset _TMP(mode_1)
set _TMP(mode_1) [pw::Application begin Create]
  set _TMP(PW_1) [pw::SegmentCircle create]
  $_TMP(PW_1) addPoint [$_CN(6) getPosition -arc 1]
  $_TMP(PW_1) addPoint [$_CN(7) getPosition -arc 1]
  $_TMP(PW_1) setAngle 180 {0 0 1}
  set _CN(13) [pw::Connector create]
  $_CN(13) addSegment $_TMP(PW_1)
  $_CN(13) calculateDimension
  unset _TMP(PW_1)
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Create Connector}

set _TMP(split_params) [list]
lappend _TMP(split_params) [$_CN(13) getParameter -arc [expr {0.01 * 50}]]
set _TMP(PW_1) [$_CN(13) split $_TMP(split_params)]
unset _TMP(PW_1)
unset _TMP(split_params)
pw::Application markUndoLevel Split

set _CN(14) [pw::GridEntity getByName con-13-split-2]
set _CN(15) [pw::GridEntity getByName con-13-split-1]
set _TMP(PW_1) [pw::Collection create]
$_TMP(PW_1) set [list $_CN(14) $_CN(15) $_CN(1) $_CN(4)]
$_TMP(PW_1) do setDimension 200
$_TMP(PW_1) delete
unset _TMP(PW_1)
pw::CutPlane refresh
pw::Application markUndoLevel Dimension

set _TMP(PW_1) [pw::Collection create]
$_TMP(PW_1) set [list $_CN(6) $_CN(5) $_CN(3) $_CN(8) $_CN(11) $_CN(9) $_CN(10) $_CN(7)]
$_TMP(PW_1) do setDimension 100
$_TMP(PW_1) delete
unset _TMP(PW_1)
pw::CutPlane refresh
pw::Application markUndoLevel Dimension

set _TMP(PW_1) [pw::Collection create]
$_TMP(PW_1) set [list $_CN(12) $_CN(2)]
$_TMP(PW_1) do setDimension 40
$_TMP(PW_1) delete
unset _TMP(PW_1)
pw::CutPlane refresh
pw::Application markUndoLevel Dimension

set _TMP(PW_1) [pw::DomainStructured createFromConnectors -reject _TMP(unusedCons)  [list $_CN(14) $_CN(15) $_CN(6) $_CN(5) $_CN(3) $_CN(8) $_CN(11) $_CN(9) $_CN(12) $_CN(10) $_CN(2) $_CN(1) $_CN(7) $_CN(4)]]
unset _TMP(unusedCons)
unset _TMP(PW_1)
pw::Application markUndoLevel {Assemble Domains}

set _TMP(mode_1) [pw::Application begin Modify [list $_CN(7) $_CN(6) $_CN(12) $_CN(10) $_CN(11) $_CN(2)]]
  set _TMP(PW_1) [$_CN(2) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(2) getDistribution 1]
  $_TMP(PW_1) setEndSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(6) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(7) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(10) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(11) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(12) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(12) getDistribution 1]
  $_TMP(PW_1) setEndSpacing 9.9999999999999995e-07
  unset _TMP(PW_1)
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Change Spacings}

set _TMP(mode_1) [pw::Application begin Modify [list $_CN(8) $_CN(4) $_CN(3) $_CN(15) $_CN(1) $_CN(5) $_CN(9) $_CN(14)]]
  set _TMP(PW_1) [$_CN(1) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(1) getDistribution 1]
  $_TMP(PW_1) setEndSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(4) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(4) getDistribution 1]
  $_TMP(PW_1) setEndSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(3) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(5) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(8) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(9) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(15) getDistribution 1]
  $_TMP(PW_1) setBeginSpacing 0.00050000000000000001
  unset _TMP(PW_1)
  set _TMP(PW_1) [$_CN(14) getDistribution 1]
  $_TMP(PW_1) setEndSpacing 0.00050000000000000001
  unset _TMP(PW_1)
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel {Change Spacings}

set _DM(1) [pw::GridEntity getByName dom-2]
set _DM(2) [pw::GridEntity getByName dom-3]
set _DM(3) [pw::GridEntity getByName dom-4]
set _DM(4) [pw::GridEntity getByName dom-1]
set ents [list $_DM(1) $_DM(2) $_DM(3) $_DM(4)]
set _TMP(mode_1) [pw::Application begin Modify $ents]
  $_DM(2) setOrientation IMinimum JMaximum
  $_DM(4) setOrientation JMinimum IMinimum
  $_DM(4) setOrientation IMinimum JMaximum
  $_DM(3) setOrientation JMinimum IMinimum
  $_DM(3) setOrientation IMaximum JMinimum
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application markUndoLevel Orient

set ents [list $_DM(1) $_DM(2) $_DM(3) $_DM(4)]
set _TMP(mode_1) [pw::Application begin Modify $ents]
$_TMP(mode_1) abort
unset _TMP(mode_1)

pw::Application setCAESolver {ANSYS Fluent} 3
pw::Application markUndoLevel {Select Solver}

pw::Application setCAESolver {ANSYS Fluent} 2
pw::Application markUndoLevel {Set Dimension 2D}

set _TMP(PW_1) [pw::BoundaryCondition create]
pw::Application markUndoLevel {Create BC}

unset _TMP(PW_1)
set _TMP(PW_1) [pw::BoundaryCondition getByName bc-2]
$_TMP(PW_1) setName ff
pw::Application markUndoLevel {Name BC}

$_TMP(PW_1) setPhysicalType -usage CAE {Pressure Far Field}
pw::Application markUndoLevel {Change BC Type}

$_TMP(PW_1) apply [list [list $_DM(3) $_CN(15)] [list $_DM(3) $_CN(14)] [list $_DM(2) $_CN(10)] [list $_DM(1) $_CN(11)] [list $_DM(1) $_CN(8)] [list $_DM(4) $_CN(12)] [list $_DM(2) $_CN(9)]]
pw::Application markUndoLevel {Set BC}

set _TMP(PW_2) [pw::BoundaryCondition create]
pw::Application markUndoLevel {Create BC}

unset _TMP(PW_2)
set _TMP(PW_2) [pw::BoundaryCondition getByName bc-3]
$_TMP(PW_2) setName upper
pw::Application markUndoLevel {Name BC}

$_TMP(PW_2) setPhysicalType -usage CAE Wall
pw::Application markUndoLevel {Change BC Type}

set _TMP(PW_3) [pw::BoundaryCondition create]
pw::Application markUndoLevel {Create BC}

unset _TMP(PW_3)
set _TMP(PW_3) [pw::BoundaryCondition getByName bc-4]
$_TMP(PW_3) setName lower
pw::Application markUndoLevel {Name BC}

$_TMP(PW_3) setPhysicalType -usage CAE Wall
pw::Application markUndoLevel {Change BC Type}

set _TMP(PW_4) [pw::BoundaryCondition create]
pw::Application markUndoLevel {Create BC}

unset _TMP(PW_4)
set _TMP(PW_4) [pw::BoundaryCondition getByName bc-5]
$_TMP(PW_4) setName te
pw::Application markUndoLevel {Name BC}

$_TMP(PW_4) setPhysicalType -usage CAE Wall
pw::Application markUndoLevel {Change BC Type}

$_TMP(PW_4) apply [list [list $_DM(4) $_CN(2)]]
pw::Application markUndoLevel {Set BC}

$_TMP(PW_2) apply [list [list $_DM(3) $_CN(1)]]
pw::Application markUndoLevel {Set BC}

$_TMP(PW_3) apply [list [list $_DM(3) $_CN(4)]]
pw::Application markUndoLevel {Set BC}

unset _TMP(PW_1)
unset _TMP(PW_2)
unset _TMP(PW_3)
unset _TMP(PW_4)
set _TMP(PW_1) [pw::VolumeCondition create]
pw::Application markUndoLevel {Create VC}

$_TMP(PW_1) setName fluid
pw::Application markUndoLevel {Name VC}

$_TMP(PW_1) setPhysicalType Fluid
pw::Application markUndoLevel {Change VC Type}


unset _TMP(PW_1)
set _TMP(mode_1) [pw::Application begin CaeExport [pw::Entity sort [list $_DM(4) $_DM(1) $_DM(2) $_DM(3)]]]
  $_TMP(mode_1) initialize -strict -type CAE F:/DRDO_Intern/auto/airfoil_1.cas
  $_TMP(mode_1) verify
  $_TMP(mode_1) write
$_TMP(mode_1) end
unset _TMP(mode_1)
pw::Application save F:/DRDO_Intern/auto_mesh/airfoil_1.pw

exit

}
