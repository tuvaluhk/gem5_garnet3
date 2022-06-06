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
-d my_outdir/NoI/KiteSmall \
configs/my/garnet_synth_traffic1.py \
--num-cpus=64 \
--num-dirs=16 \
--network=garnet2.0 \
--topology=NoI_KiteSmall \
--mesh-rows=8 \
--num-chiplets=4 \
--sim-cycles=20000 \
--vcs-per-vnet=4 \
--inj-vnet=0 \
--precision=5 \
--injectionrate=0.3 \
--synthetic=uniform_random
$1
exit

# Record Stats
touch my_outdir/NoI/KiteSmall/run_stats.txt
echo
echo "Run: Stats:"  >> my_outdir/NoI/KiteSmall/run_stats.txt
grep "sim_ticks" my_outdir/NoI/KiteSmall/stats.txt >> my_outdir/NoI/KiteSmall/run_stats.txt
grep "average_packet_latency" my_outdir/NoI/KiteSmall/stats.txt >> my_outdir/NoI/KiteSmall/run_stats.txt
grep "average_hops" my_outdir/NoI/KiteSmall/stats.txt >> my_outdir/NoI/KiteSmall/run_stats.txt
grep "packets_injected::total" my_outdir/NoI/KiteSmall/stats.txt >> my_outdir/NoI/KiteSmall/run_stats.txt
grep "packets_received::total" my_outdir/NoI/KiteSmall/stats.txt >> my_outdir/NoI/KiteSmall/run_stats.txt

grep "sim_ticks" my_outdir/NoI/KiteSmall/stats.txt 
grep "average_packet_latency" my_outdir/NoI/KiteSmall/stats.txt 
grep "average_hops" my_outdir/NoI/KiteSmall/stats.txt 
grep "packets_injected::total" my_outdir/NoI/KiteSmall/stats.txt 
grep "packets_received::total" my_outdir/NoI/KiteSmall/stats.txt 
exit
# generate .pdf
cp -f node.csv ./latex
cp -f edge.csv ./latex
exit
cd ./latex
pdflatex plot.tex
