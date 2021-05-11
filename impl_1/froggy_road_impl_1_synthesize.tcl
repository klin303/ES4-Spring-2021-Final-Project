if {[catch {

# define run engine funtion
source [file join {C:/Program Files/lscc/radiant/2.2} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "//vs-home/klin04/es4/froggy_road"
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- froggy_road_impl_1_cpe.ldc
run_engine_newmsg cpe -f "froggy_road_impl_1.cprj" "pll_1.cprj" -a "iCE40UP" -o froggy_road_impl_1_cpe.ldc
# synthesize top design
file delete -force -- froggy_road_impl_1.vm froggy_road_impl_1.ldc
run_engine_newmsg synthesis -f "froggy_road_impl_1_lattice.synproj"
run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o froggy_road_impl_1_syn.udb froggy_road_impl_1.vm] "//vs-home/klin04/es4/froggy_road/impl_1/froggy_road_impl_1.ldc"

} out]} {
   runtime_log $out
   exit 1
}
