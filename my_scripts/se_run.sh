##################################
# Example Script for Running BFS benchmark
# for 10K instructions on 16c CHIPS system
#
# Written By: Tushar Krishna (tushar@ece.gatech.edu)
# Last Updated: Feb 5, 2019
##################################

## How to run
#./my_scripts/run_demo.sh "<additional_options>"

# Examples to try:
#./my_scripts/run_demo.sh "--interposer-link-width=32"
#./my_scripts/run_demo.sh "--interposer-link-width=8"
#./my_scripts/run_demo.sh "--interposer-link-width=32 --clip-logic-ifc-delay=12"


### RISCV SE
cpu_type=TimingSimpleCPU

# Cache Parameters
# L1
l1_size='16kB'
l1_assoc=4

# Total L2 = 2MB
# L2 per tile:
l2_size='128kB'
l2_assoc=8


./build/NULL/gem5.debug \
--debug-flags=RubyNetwork \
--debug-file=se.txt \
-d my_outdir/se/Mesh \
configs/example/se.py \
--num-cpus=64 \
--num-dirs=64 \
--ruby \
--network=garnet2.0 \
--routing-algorithm=1 \
--topology=Mesh_XY \
--mesh-rows=8 \
--sim-cycles=20000 \
-c my_benchmarks/ligra/bin/riscv/BFS -o '-n 16 my_benchmarks/ligra/input/rMatGraph_J_5_100' \
--maxinsts=100 \
$1


# Print Stats
echo
echo "Run: Stats:"
grep "sim_ticks" my_outdir/NoC/Mesh/stats.txt
grep "average_packet_latency" my_outdir/NoC/Mesh/stats.txt
grep "average_hops" my_outdir/NoC/Mesh/stats.txt
grep "packets_injected::total" my_outdir/NoC/Mesh/stats.txt
grep "packets_received::total" my_outdir/NoC/Mesh/stats.txt
