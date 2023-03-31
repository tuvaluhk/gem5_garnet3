#!/bin/bash
### simulation

# traffic pattern list
traffic_pattern=uniform_random
topology=(' ' 'NoI_Mesh' 'NoI_CMesh_ori' 'NoI_DoubleButterfly' 'NoI_FoldedTorus' 'NoI_ButterDonut' 'NoI_CMesh' 'NoI_DoubleButterfly_X' 'NoI_FoldedTorus_X' 'NoI_ButterDonut_X')
injectionrate=0.5
#topology=(' ' 'NoI_CMesh_ori' 'NoI_FoldedTorus' 'NoI_ButterDonut' 'NoI_CMesh')

cycles=(' ' '2000' '5000' '10000' '15000' '20000')

sim(){
for j in `seq 1 1`
	# traffic pattern from 1 'uniform_random' to 8 'transpose'
do
		for i in `seq 1 1`
		# injection rate from 1 '0.02' to 40 '0.80'
		do
			#injectionrate=(' ' 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74  0.76 0.78 0.8)		
			
			# testcode
			#echo "$inj_rate"
			#echo "${traffic_pattern[i]}/inj_$j/exp_$k"
			# command to run
			./build/NULL/gem5.debug  \
			--outdir=my_outdir/power/${cycles[j]}/${topology[i]}_$injectionrate/ \
			configs/my/garnet_synth_traffic1.py  \
			--network=garnet2.0 \
			--num-cpus=64 \
			--num-dirs=16 \
			--topology=${topology[i]} \
			--mesh-rows=8  \
			--num-chiplets=4 \
			--vcs-per-vnet=4 \
			--precision=5 \
			--sim-cycles=${cycles[j]} \
			--inj-vnet=0 \
			--injectionrate=$injectionrate \
			--synthetic=$traffic_pattern
		done
done
}

power(){
for j in `seq 1 1`
do
	for i in `seq 1 1`
	do
			DSENT_OUT=my_outdir/power/${cycles[j]}/${topology[i]}_$injectionrate/dsent_out.txt
	    		echo "Writing DSENT power and area model to: $DSENT_OUT"
	    		python2.7 /home/tuvalu/Documents/HeteroGarnet-early/util/on-chip-network-power-area-2.0.py my_outdir/power/${cycles[j]}/${topology[i]}_$injectionrate &> $DSENT_OUT	
	    		#python2.7 /home/tuvalu/Documents/HeteroGarnet-early/util/on-chip-network-power-area-2.0.py my_outdir/power/${cycles[j]}/${topology[i]}_$injectionrate
	done
done
}

plot(){
for j in `seq 1 1`
do
	echo -n ${cycles[j]} >> my_outdir/power/area.txt
	for i in `seq 1 1`
	do
		echo -n ${topology[i]} >> my_outdir/power/area.txt | grep "tuvaluArea/Total" my_outdir/power/${cycles[j]}/${topology[i]}_$injectionrate/dsent_out.txt | sed 's/tuvaluArea\/Total:/area:/' >> my_outdir/power/area.txt
		echo -n ${cycles[j]} >> my_outdir/power/area.txt | echo -n ${topology[i]} >> my_outdir/power/power.txt | grep "All power:" my_outdir/power/${cycles[j]}/${topology[i]}_$injectionrate/dsent_out.txt | sed 's/All power:/power:/' >> my_outdir/power/power.txt
	done
done
}

power_1(){
for i in `seq 2 9`
	do
			DSENT_OUT=my_outdir/power/${topology[i]}_$injectionrate/dsent_out.txt
	    		echo "Writing DSENT power and area model to: $DSENT_OUT"
	    		python2.7 /home/tuvalu/Documents/HeteroGarnet-early/util/on-chip-network-power-area-2.0.py my_outdir/power/${topology[i]}_$injectionrate &> $DSENT_OUT	
	done
}
plot_1(){
for i in `seq 1 9`
	do
		echo -n ${topology[i]} >> my_outdir/power/area.txt | grep "tuvaluArea/Total" my_outdir/power/${topology[i]}_$injectionrate/dsent_out.txt | sed 's/tuvaluArea\/Total:/area:/' >> my_outdir/power/area.txt
		echo -n ${topology[i]} >> my_outdir/power/length.txt | grep "total links length:" my_outdir/power/${topology[i]}_$injectionrate/dsent_out.txt | sed 's/total links length:/length:/' >> my_outdir/power/length.txt
		echo -n ${topology[i]} >> my_outdir/power/power.txt | grep "All Dynamic power:" my_outdir/power/${topology[i]}_$injectionrate/dsent_out.txt | sed 's/All Dynamic power:/power:/' >> my_outdir/power/power.txt
	done
}
#sim
#power
#power_1
plot_1
exit 0
