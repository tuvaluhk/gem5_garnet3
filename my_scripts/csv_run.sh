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
-d my_outdir/NoI/DB_csv \
configs/my/garnet_synth_traffic.py \
--num-cpus=64 \
--num-dirs=16 \
--sys-clock=1.8GHz \
--ruby-clock=1.8GHz \
--network=garnet2.0 \
--topology=NoI_DoubleButterfly_csv \
--mesh-rows=8 \
--num-chiplets=4 \
--sim-cycles=20000 \
--vcs-per-vnet=4 \
--injectionrate=0.5 \
--synthetic=uniform_random
$1


cp -f node.csv ./latex
cp -f edge.csv ./latex
cd ./latex
pdflatex plot.tex
