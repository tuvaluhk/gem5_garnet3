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
#cpu_type=TimingSimpleCPU

# Cache Parameters
# L1
#l1_size='16kB'
#l1_assoc=4

# Total L2 = 2MB
# L2 per tile:
#l2_size='128kB'
#l2_assoc=8


./build/NULL/gem5.debug \
--debug-flags=RubyNetwork --debug-file=uniform_random0.5.txt \
-d my_outdir/NoI/DoubleButterfly \
configs/my/garnet_synth_traffic.py \
--num-cpus=64 \
--num-dirs=16 \
--sys-clock=3GHz \
--ruby-clock=3GHz \
--network=garnet2.0 \
--topology=NoI_DoubleButterfly \
--mesh-rows=8 \
--num-chiplets=4 \
--sim-cycles=20000 \
--vcs-per-vnet=4 \
--injectionrate=0.5 \
--synthetic=uniform_random
$1


# Print Stats
echo
echo "Run: Stats:"
grep "sim_ticks" my_outdir/NoI/DoubleButterfly/stats.txt
grep "average_packet_latency" my_outdir/NoI/DoubleButterfly/stats.txt
grep "average_hops" my_outdir/NoI/DoubleButterfly/stats.txt
grep "packets_injected::total" my_outdir/NoI/DoubleButterfly/stats.txt
grep "packets_received::total" my_outdir/NoI/DoubleButterfly/stats.txt

touch my_outdir/NoI/DoubleButterfly/run_stats.txt
echo "Run: Stats:" >> my_outdir/NoI/DoubleButterfly/run_stats.txt
grep "sim_ticks" my_outdir/NoI/DoubleButterfly/stats.txt >> my_outdir/NoI/DoubleButterfly/run_stats.txt
grep "average_packet_latency" my_outdir/NoI/DoubleButterfly/stats.txt >> my_outdir/NoI/DoubleButterfly/run_stats.txt
grep "average_hops" my_outdir/NoI/DoubleButterfly/stats.txt >> my_outdir/NoI/DoubleButterfly/run_stats.txt
grep "packets_injected::total" my_outdir/NoI/DoubleButterfly/stats.txt >> my_outdir/NoI/DoubleButterfly/run_stats.txt
grep "packets_received::total" my_outdir/NoI/DoubleButterfly/stats.txt >> my_outdir/NoI/DoubleButterfly/run_stats.txt
