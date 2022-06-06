#!/bin/bash
# Author: jseefive
# Create Date: 2021/4/22
# Discription: Scripts for mesh_3D synthetic traffic simulation,
#              synthetic traffic pattern including:
#              'uniform_random', 'tornado', 'bit_complement', 'bit_reverse',
#              'bit_rotation', 'neighbor', 'shuffle' and 'transpose'.
# Usage: running ./my_scripts/graduation_proj/mesh_3D_simulation.sh under the gem5 directory.


### simulation

# traffic pattern list
traffic_pattern=(' ' 'uniform_random' 'uniform_random' 'bit_complement' 'bit_reverse' 'bit_rotation' 'neighbor' 'shuffle' 'transpose')
topology=(' ' 'NoI_CMesh' 'NoI_FoldedTorus_X' 'NoI_ButterDonut_X' 'NoI_DoubleButterfly_X' 'NoI_Mesh' 'NoI_KiteSmall')
for k in `seq 2 2`
# repeat experiment from 1 to 5
do
	for i in `seq 2 2`
	# traffic pattern from 1 'uniform_random' to 8 'transpose'
	do
		for j in `seq 1 15`
		# injection rate from 1 '0.02' to 40 '0.80'
		do
			# injection rate
			#inj_rate=$(echo "$inj_rate+$interval"|bc)
			#injectionrate=(' ' 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74  0.76 0.78 0.8)	
			injectionrate=(' ' 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74  0.76 0.78 0.8)		
			

			# testcode
			#echo "$inj_rate"
			#echo "${traffic_pattern[i]}/inj_$j/exp_$k"
			
			# command to run
			./build/NULL/gem5.debug  \
			--outdir=m5out/${topology[i]}/${traffic_pattern[k]}/exp_$k/${injectionrate[$j]}  \
			configs/my/garnet_synth_traffic1.py  \
			--network=garnet2.0 \
			--num-cpus=64 \
			--num-dirs=16 \
			--topology=${topology[i]} \
			--mesh-rows=8  \
			--num-chiplets=4 \
			--vcs-per-vnet=4 \
			--precision=5 \
			--sim-cycles=20000 \
			--inj-vnet=0 \
			--injectionrate=${injectionrate[$j]} \
			--synthetic=${traffic_pattern[$k]}

		done
	done
done
