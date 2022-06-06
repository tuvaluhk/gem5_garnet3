#!/bin/bash
# Author: jseefive
# Create Date: 2021/4/24
# Discription: Scripts to plot network stats of mesh_3D synthetic traffic simulation.
# Usage: running ./my_scripts/graduation_proj/plot_network_stats.sh under the gem5 directory.

# traffic pattern list
#traffic_pattern=(' ' 'uniform_random' 'tornado' 'bit_complement' 'bit_reverse' 'bit_rotation' 'neighbor' 'shuffle' 'transpose')
#topology=(' ' 'NoI_ButterDonut_X' 'NoI_FoldedTorus_X' 'NoI_DoubleButterfly_X' 'NoI_FoldedTorus_X' 'NoI_KiteSmall' 'NoI_Mesh')
#echo "${traffic_pattern[i]}"
algorithm=(' ' 'Q-learning' 'Sarsa' 'Expected Sarsa')
pre_process(){

# create injection rate file
# three topology 

for i in `seq 1 50`
do
	# injection rate
	# inj_rate=$(echo "$inj_rate+$interval"|bc)
	echo "$i" >> episode.txt
done

for line in `cat  Q.txt`
do
	reward=$(echo "scale=4; $line - 152000" | bc)
	echo $reward >> Q_minus.txt
done

for line in `cat  sarsa.txt`
do
	reward=$(echo "scale=4; $line - 140600" | bc)
	echo $reward >> sarsa_minus.txt
done

for line in `cat  esarsa.txt`
do
	reward=$(echo "scale=4; $line - 135200" | bc)
	echo $reward >> esarsa_minus.txt
done


paste episode.txt Q_minus.txt > Q_plot.txt	
paste episode.txt sarsa_minus.txt > sarsa_plot.txt	
paste episode.txt esarsa_minus.txt > esarsa_plot.txt	


}

plot_throughput(){

#plot \"Q_plot.txt\" smooth unique with linespoint linestyle 0 linecolor 1 linewidth 1.5 pointtype 1 title \"QL\", \
#    \"sarsa_plot.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 title \"Sarsa\", \
#   \"esarsa_plot.txt\" smooth unique with linespoints linecolor 4 linewidth 1.5 pointtype 4 title \"Expected Sarsa\", \
# plot and save the throughput graph
#   \"m5out/NoI_ButterDonut_X/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 2 linewidth 1.5 pointtype 2 pointsize 2 title \"tornado\", \
#     \"m5out/NoI_KiteSmall/stats/throughput_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"bit complement\", \

echo "
set term pngcairo font \",18\"
set xlabel \"Episode\"
set ylabel \"Reward\"
set title font ',25'
set xlabel font ',22'
set ylabel font ',22'
set tics font ',18'
set key font ',16'
set grid
set key box
set key bottom right
set terminal pngcairo size 1280, 720
set output \"Mem.png\"

plot \"Q_plot.txt\" smooth unique with linespoint linestyle 0 linecolor 1 linewidth 2 title \"QL\", \
     \"sarsa_plot.txt\" smooth unique with linespoint linestyle 1 linecolor 2 linewidth 1.5 title \"Sarsa\", \
     \"esarsa_plot.txt\" smooth unique with linespoint linestyle 2 linecolor 3 linewidth 1.5 title \"Expected Sarsa\", \

" | gnuplot
}


#pre_process
plot_throughput
exit 0
