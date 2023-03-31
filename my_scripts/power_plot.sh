#!/bin/bash

plot_power(){

# plot and save the latency graph
#     \"m5out/NoI_ButterDonut_X/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 2 linewidth 1.5 pointtype 2 pointsize 2 title \"tornado\", \
#     \"m5out/NoI_KiteSmall/stats/latency_plot/uniform_random.txt\" smooth unique with linespoints linecolor 3 linewidth 1.5 pointtype 3 pointsize 2 title \"bit complement\", \    
   
echo "
set term pngcairo font \",18\"
set yrange [0:1.2]
set ylabel \"Normalized to Mesh\"
set title font ',25'
set xlabel font ',22'
set ylabel font ',22'
set tics font ',18'
set key font ',16'
set grid
set key box
set style fill pattern 3 border -1
set style histogram clustered gap 1 title offset character 0, 0, 0
set datafile missing '-'
set style data histograms
set xtics ("area" 0, "power" 1, "length" 2)
set key top left width 0 box 3
set boxwidth 0.9 absolute
set terminal pngcairo size 1280, 720
set output \"m5out/power/power.png\"


plot \"plot.txt\"  using 2:xtic(1) ti col title "CMesh" ,\"plot.txt\" using 3:xtic(1) ti col title
" | gnuplot
}

plot_power
exit 0
