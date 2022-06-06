#!/bin/sh

topologies='Mesh_XY NoI_Mesh NoI_CMesh'
injection_rates='0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08'

echo -n "injetion_rate(ps) "
for topology in $topologies
do
	echo -n "$topology "
done
echo

for injection_rate in $injection_rates
do
	echo -n "$injection_rate "
	for topology in $topologies
	do
		dir=results/$topology-ir$injection_rate
		file=$dir/m5out/stats.txt

		average_hops=`grep 'system.ruby.network.average_hops' $file | awk '{print $2}'`
		average_packet_latency=`grep 'system.ruby.network.average_packet_latency' $file | awk '{print $2}'`

		echo -n "$average_hops "
#		echo 'average_packet_latency(ticks, ps):' $average_packet_latency

#		echo -n "$average_packet_latency "
	done
	echo
done
