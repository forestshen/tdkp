#####################################################
# kpXxX calculation for the quantum well
#####################################################

set gridfile 		well384.grd
set kpmethod 		kp4x4
set numsol   		16
set num_k_values 	32

# k space definition
set kmax [expr {(2.0 * $constants_pi / 0.5) * 0.15}]
set kmin 0

# transversal direction [010]
set kt_dir $ey 
# quantization dir      [100]
set kq_dir $ex

# setup 
set config [get_configuration_object];
set logmsg [get_logger_object];

# be extremly chatty
$logmsg set_level $LOG_INFO_DEVEL2;

# set configuration options
$config set "output_eigensolver_statistics" 		         0
$config set "assembly_build_nonsymmetric_matrices" 	         1
$config set "assembly_check_matrix_for_symmetry"   	         0
$config set "assembly_check_matrix_for_symmetry_tolerance" 1.0e-10
$config set "assembly_track_nonhermitian_nodes"                  0
$config set "assembly_save_matrices_to_file"		         0
$config set "output_kpmatrix_dump_to_file"                       0


# set up material database
set material_database [MaterialDatabase];

# create i/o parser
set parser [InputParser]

# read geometry/grid file
set geometry [$parser read_geometry_from_file $gridfile]

# create problem
switch $kpmethod {
    effmass {
	set problem [EffectiveMass1D2D]
        $problem set_geometry $geometry
    }
    kp4x4 {
 	set problem [KP4x41D2D]
        $problem set_geometry $geometry
        $problem set_axes $kt_dir $kq_dir
        for {set i 0} {$i < $num_k_values} {incr i} {
          $problem set_energy_guess $i -0.05
        }
    }
    kp6x6 {
	set problem [KP6x61D2D]
	$problem set_geometry $geometry
        $problem set_axes $kt_dir $kq_dir        
        for {set i 0} {$i < $num_k_values} {incr i} {
          $problem set_energy_guess $i -0.05
        }
    }
    kp8x8h {
	set problem [KP8x81D2D]	
	$problem set_geometry $geometry
	$problem set_solution_type $holes
        $problem set_axes $kt_dir $kq_dir
        $problem set_energy_barrier 0.2
    }
    kp8x8e {
	set problem [KP8x81D2D]
	$problem set_geometry $geometry
	$problem set_solution_type $electrons     
        $problem set_axes $kt_dir $kq_dir
        $problem set_energy_barrier 0.2
	set offset [expr {$constants_hbar * $constants_hbar * $kmax * $kmax / (2 * $constants_m0 *0.067 * ($num_k_values - 1))}]
        $problem set_target_energy_offset $offset
        $problem set_energy_guess 0 0.85
    }
    default {
	puts " **error** unknown solution method ${kpmethod}"
	exit
    }
}

# add geometry and material
$problem set_material_db $material_database

# solve problem and display some information
if { $kpmethod == "effmass" } {
  $problem solve $numsol
} else {
  $problem solve $numsol $kmin $kmax $num_k_values
}

# get bandstructure object
set bandstructure [$problem get_bandstructure 0];
BandstructureDomaincomplex -this $bandstructure

# write xy plot file
set xydatafile "bandstructure_${kpmethod}_010.dat"
$parser write_ascii_cplx      $bandstructure $xydatafile
$parser write_ascii_cplx2real  $bandstructure "real_${xydatafile}"

set kt_dir [Vector3D -args 0.0 1.0 1.0]
$problem set_axes $kt_dir $kq_dir

# solve problem and display some information
if { $kpmethod == "effmass" } {
  $problem solve $numsol
} else {
  $problem solve $numsol $kmin $kmax $num_k_values
}

# get bandstructure object
set bandstructure [$problem get_bandstructure 1];
BandstructureDomaincomplex -this $bandstructure

# write xy plot file
set xydatafile "bandstructure_${kpmethod}_011.dat"
$parser write_ascii_cplx      $bandstructure $xydatafile
$parser write_ascii_cplx2real  $bandstructure "real_${xydatafile}"

