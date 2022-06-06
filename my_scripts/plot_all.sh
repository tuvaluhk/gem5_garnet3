#!/bin/bash
# Author: jseefive
# Create Date: 2021/4/24
# Discription: Scripts to plot network stats of mesh_3D synthetic traffic simulation.
# Usage: running ./my_scripts/graduation_proj/plot_network_stats.sh under the gem5 directory.

# traffic pattern list
traffic_pattern=(' ' 'uniform_random' 'tornado' 'bit_complement' 'bit_reverse' 'bit_rotation' 'neighbor' 'shuffle' 'transpose')
topology=(' ' 'NoI_ButterDonut_X' 'NoI_FoldedTorus_X' 'NoI_DoubleButterfly_X' 'NoI_FoldedTorus_X' 'NoI_KiteSmall' 'NoI_Mesh')
#echo "${traffic_pattern[i]}"

pre_process(){

# create injection rate file
# three topology 
for h in `seq 1 3`
do
	inj_rate=0
	interval=0.02
	for i in `seq 1 20`
	do
		# injection rate
		inj_rate=$(echo "$inj_rate+$interval"|bc)
		echo "$inj_rate" >> m5out/${topology[h]}/stats/injection_rate.txt
	done
done

for h in `seq 1 3`
do
	mkdir m5out/${topology[h]}/stats/throughput_plot
	mkdir m5out/${topology[h]}/stats/hops_plot
	mkdir m5out/${topology[h]}/stats/latency_plot
done

for h in `seq 1 3`
do
	# pre-process
	# calculate throughput
	for j in `seq 1 1`
	# traffic pattern from 1 'uniform_random' to 8 'transpose'
	do
		for k in `seq 3 3`
		do
			for line in `cat  m5out/${topology[h]}/stats/${traffic_pattern[j]}/flits_received_exp_$k.txt`
			do
				throughput=$(echo "scale=4; $line / 2560" | bc)
				echo $throughput >> m5out/${topology[h]}/stats/${traffic_pattern[j]}/throughput_exp_$k.txt
			done
			
			for line in `cat  m5out/${topology[h]}/stats/${traffic_pattern[j]}/latency_exp_$k.txt`
			do
				latency=$(echo "scale=4; $line / 5" | bc)
				echo $latency >> m5out/${topology[h]}/stats/${traffic_pattern[j]}/cycles_exp_$k.txt
			done
		done
	done
done

for h in `seq 1 3`
do	
	# merge data file
	for j in `seq 1 1`
	# traffic pattern from 1 'uniform_random' to 8 'transpose'
	do
		for k in `seq 3 3`
		do
			paste m5out/${topology[h]}/stats/injection_rate.txt m5out/${topology[h]}/stats/${traffic_pattern[j]}/throughput_exp_$k.txt > m5out/${topology[h]}/stats/throughput_plot/${traffic_pattern[j]}.txt	
			paste m5out/${topology[h]}/stats/injection_rate.txt m5out/${topology[h]}/stats/${traffic_pattern[j]}/hops_exp_$k.txt > m5out/${topology[h]}/stats/hops_plot/${traffic_pattern[j]}.txt
			paste m5out/${topology[h]}/stats/injection_rate.txt m5out/${topology[h]}/stats/${traffic_pattern[j]}/cycles_exp_$k.txt > m5out/${topology[h]}/stats/latency_plot/${traffic_pattern[j]}.txt
		done
	done
done


}

plot_throughput(){

# plot and save the throughput graph
#   \"m5out/NoI_ButterDonut_X/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 2 linewidth 1.5 pointtype 2 pointsize 2 title \"tornado\", \
#     \"m5out/NoI_KiteSmall/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"bit complement\", \
echo "
set term pngcairo font \",18\"
set title \"Memory Throughput - Injection Rate\"
set xlabel \"Injection rate(flits/node/cycle)\"
set ylabel \"Throughput(flits/node/cycle)\"
set yrange [0:14]
set title font ',25'
set xlabel font ',22'
set ylabel font ',22'
set tics font ',18'
set key font ',16'
set grid
set key box
set key top left
set terminal pngcairo size 1280, 720
set output \"m5out/NoI_plot/throughput.png\"

plot \"m5out/NoI_ButterDonut_X/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 1 linewidth 1.5 pointtype 1 pointsize 2 title \"NoI_ButterDonut_X\", \
     \"m5out/NoI_DoubleButterfly_X/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"NoI_DoubleButterfly_X\", \
     \"m5out/NoI_FoldedTorus_X/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 4 linewidth 1.5 pointtype 4 pointsize 2 title \"NoI_FoldedTorus_X\", \
     \"m5out/NoI_Mesh/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 2 linewidth 1.5 pointtype 2 pointsize 2 title \"NoI_Mesh\", \
     \"m5out/NoI_CMesh/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 5 linewidth 1.5 pointtype 5 pointsize 2 title \"NoI_CMesh\", \
     \"m5out/NoI_KiteSmall/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 6 linewidth 1.5 pointtype 6 pointsize 2 title \"NoI_KiteSmall\", \
" | gnuplot
}

plot_hops(){

# plot and save the hops graph
#     \"m5out/NoI_ButterDonut_X/stats/hops_plot/uniform_random.txt\" smooth unique with linespoints linecolor 2 linewidth 1.5 pointtype 2 pointsize 2 title \"tornado\", \
#     \"m5out/NoI_KiteSmall/stats/hops_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"bit complement\", \     
echo "
set term pngcairo font \",18\"
set title \"Hops - Injection Rate\"
set yrange [0:12]
set xlabel \"Injection rate(flits/node/cycle)\"
set ylabel \"Hops\"
set title font ',25'
set xlabel font ',22'
set ylabel font ',22'
set tics font ',18'
set key font ',16'
set grid
set key box
set key top left
set terminal pngcairo size 1280, 720
set output \"m5out/NoI_plot/hops.png\"

plot \"m5out/NoI_ButterDonut_X/stats/hops_plot/uniform_random.txt\" smooth unique with linespoints linecolor 1 linewidth 1.5 pointtype 1 pointsize 2 title \"NoI_ButterDonut_X\", \
     \"m5out/NoI_DoubleButterfly_X/stats/hops_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"NoI_DoubleButterfly_X\", \
     \"m5out/NoI_FoldedTorus_X/stats/hops_plot/uniform_random.txt\" smooth unique with linespoints linecolor 4 linewidth 1.5 pointtype 4 pointsize 2 title \"NoI_FoldedTorus_X\", \
" | gnuplot
}

plot_latency(){

# plot and save the latency graph
#     \"m5out/NoI_ButterDonut_X/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 2 linewidth 1.5 pointtype 2 pointsize 2 title \"tornado\", \
#     \"m5out/NoI_KiteSmall/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"bit complement\", \    
   
echo "
set term pngcairo font \",18\"
set title \"Average Packet Latency - Injection Rate\"
set yrange [0:50]
set xlabel \"Injection rate(flits/node/cycle)\"
set ylabel \"Average packet latency(cycle)\"
set title font ',25'
set xlabel font ',22'
set ylabel font ',22'
set tics font ',18'
set key font ',16'
set grid
set key box
set key top left
set terminal pngcairo size 1280, 720
set output \"m5out/NoI_plot/latency.png\"

plot \"m5out/NoI_ButterDonut_X/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 1 linewidth 1.5 pointtype 1 pointsize 2 title \"NoI_ButterDonut_X\", \
     \"m5out/NoI_DoubleButterfly_X/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"NoI_DoubleButterfly_X\", \
     \"m5out/NoI_FoldedTorus_X/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 4 linewidth 1.5 pointtype 4 pointsize 2 title \"NoI_FoldedTorus_X\", \

" | gnuplot
}

#mkdir m5out/NoI_plot
#pre_process
plot_throughput
#plot_hops
#plot_latency
exit 0
