./build/NULL/gem5.debug --outdir=m5out/irreMesh_4x4 configs/example/garnet_synth_traffic.py  \
--network=garnet2.0 \
--num-cpus=16 \
--num-dirs=16 \
--topology=irregular_Mesh_XY \
--conf-file=configs/topologies/udrouting/16_nodes-connectivity_matrix_0-links_removed_8.txt \
--routing-algorithm=2 \
--escape-vc=1 \
--mesh-rows=4  \
--sim-cycles=100000 \
--inj-vnet=0 \
--injectionrate=0.6 \
--synthetic=uniform_random

