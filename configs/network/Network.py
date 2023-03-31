# Copyright (c) 2016 Georgia Institute of Technology
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer;
# redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution;
# neither the name of the copyright holders nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from __future__ import print_function
from __future__ import absolute_import

import math
import m5
from m5.objects import *
from m5.defines import buildEnv
from m5.util import addToPath, fatal

def define_options(parser):
    # By default, ruby uses the simple timing cpu
    parser.set_defaults(cpu_type="TimingSimpleCPU")

    parser.add_option("--topology", type="string", default="Crossbar",
                      help="check configs/topologies for complete set")
    parser.add_option("--mesh-rows", type="int", default=0,
                      help="the number of rows in the mesh topology")
    parser.add_option("--network", type="choice", default="simple",
                      choices=['simple', 'garnet2.0'],
                      help="'simple'|'garnet2.0'")
    parser.add_option("--router-latency", action="store", type="int",
                      default=1,
                      help="""number of pipeline stages in the garnet router.
                            Has to be >= 1.
                            Can be over-ridden on a per router basis
                            in the topology file.""")
    parser.add_option("--link-latency", action="store", type="int", default=1,
                      help="""latency of each link the simple/garnet networks.
                            Has to be >= 1.
                            Can be over-ridden on a per link basis
                            in the topology file.""")
    parser.add_option("--link-width-bits", action="store", type="int",
                      default=128,
                      help="width in bits for all links inside garnet.")

    # Clock_domain Options
    parser.add_option("--cpu-clock", 
                      default='2GHz',type="string",
                      help = """Top-level clock for blocks running at system
                      speed""")

    parser.add_option("--mem-clock", type="string",
                      default='3GHz',
                      help = """Top-level clock for blocks running at system
                      speed""")

    parser.add_option("--noi-clock", type="string",
                      default='4GHz',
                      help = """Top-level clock for blocks running at system
                      speed""")

    ### SerDes module parser
    parser.add_option("--noi-width", type="int",
                      default=32,
                      help="width in bits for all links inside garnet.")
                          
    ### dsent .cfg parser
    parser.add_option("--buffers-per-data-vc", action="store", type="int", default=4,
                      help="""number of buffers per data virtual channel.""")
    parser.add_option("--buffers-per-ctrl-vc", action="store", type="int", default=1,
                      help="""number of buffers per control virtual channel.""")      
    ### desent end 
                   
    parser.add_option("--vcs-per-vnet", action="store", type="int", default=4,
                      help="""number of virtual channels per virtual network
                            inside garnet network.""")
    ### updown routing
    parser.add_option("--routing-algorithm", action="store", type="int",
                      default=0,
                      help="""routing algorithm in network.
                            0: weight-based table
                            1: XY (for Mesh. see garnet2.0/RoutingUnit.cc)
                            2: Updown (see garnet2.0/RoutingUnit.cc)
                            3: Custom (see garnet2.0/RoutingUnit.cc""")
    ### end
    
    ### Esacape VC
    parser.add_option("--escape-vc", action="store", type="int", default=0,
                      help="""if set 1 will enable up-dn routing present in the
                            configuration file passed as the commandline
                            argument only in escape VC, all other would be
                            random""")
    parser.add_option("--network-fault-model", action="store_true",
                      default=False,
                      help="""enable network fault model:
                            see src/mem/ruby/network/fault_model/""")
    parser.add_option("--garnet-deadlock-threshold", action="store",
                      type="int", default=50000,
                      help="network-level deadlock threshold.")
    ### updownrouting                  
    parser.add_option("--conf-file", type="string",
                      default="NoI_BD.txt", help="check configs/topologies for complete configuration")
    ### end

def create_network(options, ruby):

    # Set the network classes based on the command line options
    if options.network == "garnet2.0":
        NetworkClass = GarnetNetwork
        IntLinkClass = GarnetIntLink
        ExtLinkClass = GarnetExtLink
        RouterClass = GarnetRouter
        InterfaceClass = GarnetNetworkInterface

    else:
        NetworkClass = SimpleNetwork
        IntLinkClass = SimpleIntLink
        ExtLinkClass = SimpleExtLink
        RouterClass = Switch
        InterfaceClass = None

    # Instantiate the network object
    # so that the controllers can connect to it.
    network = NetworkClass(ruby_system = ruby, topology = options.topology,
            routers = [], ext_links = [], int_links = [], netifs = [])

    return (network, IntLinkClass, ExtLinkClass, RouterClass, InterfaceClass)

def init_network(options, network, InterfaceClass):

    if options.network == "garnet2.0":
        network.num_rows = options.mesh_rows
        network.vcs_per_vnet = options.vcs_per_vnet
        network.ni_flit_size = options.link_width_bits / 8
        network.routing_algorithm = options.routing_algorithm
        ### Escape VC
        network.escape_vc = options.escape_vc
        ### end 
        network.garnet_deadlock_threshold = options.garnet_deadlock_threshold
        ### updownrouting  
        network.conf_file = options.conf_file
        ### end          
        
        # Create CDC and connect them to the corresponding links
        for intLink in network.int_links:
            intLink.src_net_bridge = NetworkBridge(
                                     link = intLink.network_link,
                                     vtype = 1,
                                     width = intLink.src_node.width)
            intLink.src_cred_bridge = NetworkBridge(
                                    link = intLink.credit_link,
                                    vtype = 0,
                                    width = intLink.src_node.width)
            intLink.dst_net_bridge = NetworkBridge(
                                   link = intLink.network_link,
                                   vtype = 0,
                                     width = intLink.dst_node.width)
            intLink.dst_cred_bridge = NetworkBridge(
                                    link = intLink.credit_link,
                                    vtype = 1,
                                    width = intLink.dst_node.width)

        for extLink in network.ext_links:
            ext_net_bridges = []
            ext_net_bridges.append(NetworkBridge(link =
                                 extLink.network_links[0], vtype = 1,
                                 width = extLink.width))
            ext_net_bridges.append(NetworkBridge(link =
                                 extLink.network_links[1], vtype = 0,
                                 width = extLink.width))
            extLink.ext_net_bridge = ext_net_bridges

            ext_credit_bridges = []
            ext_credit_bridges.append(NetworkBridge(link =
                                    extLink.credit_links[0], vtype = 0,
                                    width = extLink.width))
            ext_credit_bridges.append(NetworkBridge(link =
                                    extLink.credit_links[1], vtype = 1,
                                    width = extLink.width))
            extLink.ext_cred_bridge = ext_credit_bridges

            int_net_bridges = []
            int_net_bridges.append(NetworkBridge(link =
                                 extLink.network_links[0], vtype = 0,
                                 width = extLink.int_node.width))
            int_net_bridges.append(NetworkBridge(link =
                                 extLink.network_links[1], vtype = 1,
                                 width = extLink.int_node.width))
            extLink.int_net_bridge = int_net_bridges

            int_cred_bridges = []
            int_cred_bridges.append(NetworkBridge(link =
                                  extLink.credit_links[0], vtype = 1,
                                  width = extLink.int_node.width))
            int_cred_bridges.append(NetworkBridge(link =
                                  extLink.credit_links[1], vtype = 0,
                                  width = extLink.int_node.width))
            extLink.int_cred_bridge = int_cred_bridges

    if options.network == "simple":
        network.setup_buffers()

    if InterfaceClass != None:
        netifs = [InterfaceClass(id=i) \
                  for (i,n) in enumerate(network.ext_links)]
        network.netifs = netifs

    if options.network_fault_model:
        assert(options.network == "garnet2.0")
        network.enable_fault_model = True
        network.fault_model = FaultModel()
