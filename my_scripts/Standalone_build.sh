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


scons build/NULL/gem5.debug PROTOCOL=Garnet_standalone
