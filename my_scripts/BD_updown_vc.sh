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

injectionrate=(' ' 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74  0.76 0.78 0.8)	


python -W ignore configs/topologies/NoI_ButterDonut_X.py 

./build/NULL/gem5.debug \
-d my_outdir/NoI/updown_vc \
configs/my/garnet_synth_traffic.py \
--num-cpus=64 \
--num-dirs=16 \
--network=garnet2.0 \
--topology=NoI_ButterDonut_X \
--routing-algorithm=2 \
--escape-vc=1 \
--conf-file=configs/topologies/udrouting/BD_NoI.txt \
--mesh-rows=8 \
--num-chiplets=4 \
--sim-cycles=20000 \
--inj-vnet=0 \
--injectionrate=0.2 \
--synthetic=uniform_random
$1
$2
exit
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
