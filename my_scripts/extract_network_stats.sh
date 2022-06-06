#!/bin/bash
# Author: jseefive tuvalu 
# Create Date: 2021/4/23
# Discription: Scripts for extract network stats of mesh_3D synthetic traffic simulation.
# Usage: running ./my_scripts/graduation_proj/extract_network_stats.sh under the gem5 directory.

# traffic pattern list
traffic_pattern=(' ' 'uniform_random' 'uniform_random' 'uniform_random' 'bit_reverse' 'bit_rotation' 'neighbor' 'shuffle' 'transpose')
# injectionrate from 0.02 to 0.8
#injectionrate=(' ' 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74  0.76 0.78 0.8)
injectionrate=(' ' 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74  0.76 0.78 0.8)
topology=(' ' 'NoI_ButterDonut_X' 'NoI_FoldedTorus_X' 'NoI_DoubleButterfly_X' 'NoI_FoldedTorus_X' 'NoI_KiteSmall' 'NoI_Mesh')


for i in `seq 5 5`
# traffic pattern from 1 'uniform_random' to 8 'transpose'
do
	for k in `seq 3 3`
	do
		# create directory
		mkdir -p ./m5out/${topology[i]}/stats/uniform_random
		touch m5out/${topology[i]}/stats/uniform_random/hops_exp_$k.txt
		touch m5out/${topology[i]}/stats/uniform_random/latency_exp_$k.txt
		touch m5out/${topology[i]}/stats/uniform_random/flits_received_exp_$k.txt
		#inj_rate=0
		#interval=0.02

		for j in `seq 1 20`
		# injection rate from 1 '0.02' to 40 '0.80'
		do
		
		
		# injection rate
		#inj_rate=$(echo "$inj_rate+$interval"|bc)

		# repeat experiment from 1 to 5
			# testcode
			#echo "$inj_rate"
			#echo "${traffic_pattern[i]}/exp_$k/${injectionrate[$j]}"

			# extract hops stats
			grep "average_hops" m5out/${topology[i]}/${traffic_pattern[k]}/exp_$k/${injectionrate[$j]}/stats.txt | sed 's/system.ruby.network.average_hops\s*//' >> m5out/${topology[i]}/stats/${traffic_pattern[k]}/hops_exp_$k.txt
			# extract latency stats
			grep "average_flit_latency" m5out/${topology[i]}/${traffic_pattern[k]}/exp_$k/${injectionrate[$j]}/stats.txt | sed 's/system.ruby.network.average_flit_latency\s*//' >> m5out/${topology[i]}/stats/${traffic_pattern[k]}/latency_exp_$k.txt
			# extract flits_received stats
			grep "flits_received::total" m5out/${topology[i]}/${traffic_pattern[k]}/exp_$k/${injectionrate[$j]}/stats.txt | sed 's/system.ruby.network.flits_received::total\s*//' >> m5out/${topology[i]}/stats/${traffic_pattern[k]}/flits_received_exp_$k.txt
		done
	done
done

