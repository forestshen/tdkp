
set gridfile "n1_0_025_triangle_msh.asc.gz"

# setup
set config [get_configuration_object];
set logmsg [get_logger_object];


# be extremly chatty
$logmsg set_level $LOG_INFO_DEVEL2;

# set configuration options
source "../../configuration.tcl"


# set up material database
set material_database [MaterialDatabase];

# create i/o parser
set parser [InputParser]

# read geometry/grid file
set geometry [$parser read_geometry [AsciiGridReader -args $gridfile]]
$geometry set_materials $material_database


set problem [IntrinsicStrain -args $geometry $material_database]

# add geometry and material


$problem set_reference_lattice_constant 5.6503

$problem solve 1

set field [$problem get_strain_field]


$parser write_ascii_double $geometry $field "element_strain.dat"


quit

