# Copyright (c) 2020 Advanced Micro Devices, Inc.
# All rights reserved.
#
# For use for simulation and test purposes only
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Authors: Srikant Bharadwaj
from m5.params import *
from m5.objects import *
from topologies.BaseTopology import SimpleTopology
# Creates a generic Mesh assuming an equal number of cache
# and directory controllers.
# XY routing is enforced (using link weights)
# to guarantee deadlock freedom.
class Mesh_VF(SimpleTopology):
    description='Mesh_VF'
    def __init__(self, controllers):
        self.nodes = controllers
    # Makes a generic mesh
    # assuming an equal number of cache and directory cntrls
    def makeTopology(self, options, network, IntLink, ExtLink, Router):
        nodes = self.nodes
        num_routers = options.num_cpus
        num_rows = options.mesh_rows
        # default values for link latency and router latency.
        # Can be over-ridden on a per link/router basis
        link_latency = options.link_latency # used by simple and garnet
        router_latency = options.router_latency # only used by garnet
        # We create a Mesh network with some units operating at
        # a slower clock domain and other units operating at a
        # faster clock domain
        slow_freq = options.cpu_clock
        fast_freq = options.mem_clock
        # There must be an evenly divisible number of cntrls to routers
        # Also, obviously the number or rows must be <= the number of routers
        cntrls_per_router, remainder = divmod(len(nodes), num_routers)
        assert(num_rows > 0 and num_rows <= num_routers)
        num_columns = int(num_routers / num_rows)
        assert(num_columns * num_rows == num_routers)
        # Create the routers in the mesh
        routers = [Router(router_id=i, latency = router_latency) \
            for i in range(num_routers)]
        network.routers = routers
        # link counter to set unique link ids
        link_count = 0
        # Add all but the remainder nodes to the list of nodes to be uniformly
        # distributed across the network.
        network_nodes = []
        remainder_nodes = []
        for node_index in range(len(nodes)):
            if node_index < (len(nodes) - remainder):
                network_nodes.append(nodes[node_index])
            else:
                remainder_nodes.append(nodes[node_index])
        # Connect each node to the appropriate router
        ext_links = []
        for (i, n) in enumerate(network_nodes):
            print("\n\n"+n.type)
            cntrl_level, router_id = divmod(i, num_routers)
            assert(cntrl_level < cntrls_per_router)
            intCDC = False
            router_freq = slow_freq
            if (router_id == 5) or (router_id == 6) or \
               (router_id == 9) or (router_id == 10):
                router_freq = fast_freq
                intCDC = True
            router_clk = SrcClockDomain(clock = router_freq,
                            voltage_domain = VoltageDomain(
                            voltage = options.sys_voltage))
            routers[router_id].clk_domain = router_clk
            ext_links.append(ExtLink(link_id=link_count, ext_node=n,
                                    int_node=routers[router_id],
                                    int_cdc = intCDC,
                                    latency = link_latency))
            link_count += 1
        # Connect the remainding nodes to router 0.  These should only be
        # DMA nodes.
        for (i, node) in enumerate(remainder_nodes):
            assert(node.type == 'DMA_Controller')
            assert(i < remainder)
            ext_links.append(ExtLink(link_id=link_count, ext_node=node,
                                    int_node=routers[0],
                                    latency = link_latency))
            link_count += 1
        network.ext_links = ext_links
        # Create the mesh links.
        int_links = []
        # East output to West input links (weight = 1)
        for row in range(num_rows):
            for col in range(num_columns):
                if (col + 1 < num_columns):
                    srcCDC = False
                    dstCDC = False
                    link_freq = slow_freq
                    if (row == 1) or (row == 2):
                        if (col == 0):
                            dstCDC = True
                        elif (col == 1):
                            dstCDC = True
                            srcCDC = True
                        elif (col == 2):
                            srcCDC = True
                    east_out = col + (row * num_columns)
                    west_in = (col + 1) + (row * num_columns)
                    link_clk = SrcClockDomain(clock = link_freq,
                            voltage_domain = VoltageDomain(
                            voltage = options.sys_voltage))
                    int_links.append(IntLink(link_id=link_count,
                                             src_node=routers[east_out],
                                             dst_node=routers[west_in],
                                             src_outport="East",
                                             dst_inport="West",
                                             src_cdc = srcCDC,
                                             dst_cdc = dstCDC,
                                             clk_domain = link_clk,
                                             latency = link_latency,
                                             weight=1))
                    link_count += 1
        # West output to East input links (weight = 1)
        for row in range(num_rows):
            for col in range(num_columns):
                if (col + 1 < num_columns):
                    srcCDC = False
                    dstCDC = False
                    link_freq = slow_freq
                    if (row == 1) or (row == 2):
                        if (col == 2):
                            dstCDC = True
                        elif (col == 1):
                            dstCDC = True
                            srcCDC = True
                        elif (col == 0):
                            srcCDC = True
                    east_in = col + (row * num_columns)
                    west_out = (col + 1) + (row * num_columns)
                    link_clk = SrcClockDomain(clock = link_freq,
                            voltage_domain = VoltageDomain(
                            voltage = options.sys_voltage))
                    int_links.append(IntLink(link_id=link_count,
                                             src_node=routers[west_out],
                                             dst_node=routers[east_in],
                                             src_outport="West",
                                             dst_inport="East",
                                             src_cdc = srcCDC,
                                             dst_cdc = dstCDC,
                                             clk_domain = link_clk,
                                             latency = link_latency,
                                             weight=1))
                    link_count += 1
        # North output to South input links (weight = 2)
        for col in range(num_columns):
            for row in range(num_rows):
                if (row + 1 < num_rows):
                    srcCDC = False
                    dstCDC = False
                    link_freq = slow_freq
                    if (col == 1) or (col == 2):
                        if (row == 0):
                            dstCDC = True
                        elif (row == 1):
                            link_freq = fast_freq
                        elif (row == 2):
                            srcCDC = True
                    north_out = col + (row * num_columns)
                    south_in = col + ((row + 1) * num_columns)
                    link_clk = SrcClockDomain(clock = link_freq,
                            voltage_domain = VoltageDomain(
                            voltage = options.sys_voltage))
                    int_links.append(IntLink(link_id=link_count,
                                             src_node=routers[north_out],
                                             dst_node=routers[south_in],
                                             src_outport="North",
                                             dst_inport="South",
                                             src_cdc = srcCDC,
                                             dst_cdc = dstCDC,
                                             clk_domain = link_clk,
                                             latency = link_latency,
                                             weight=2))
                    link_count += 1
        # South output to North input links (weight = 2)
        for col in range(num_columns):
            for row in range(num_rows):
                if (row + 1 < num_rows):
                    srcCDC = False
                    dstCDC = False
                    link_freq = slow_freq
                    if (col == 1) or (col == 2):
                        if (row == 2):
                            dstCDC = True
                        elif (row == 1):
                            link_freq = fast_freq
                        elif (row == 0):
                            srcCDC = True
                    north_in = col + (row * num_columns)
                    south_out = col + ((row + 1) * num_columns)
                    link_clk = SrcClockDomain(clock = link_freq,
                            voltage_domain = VoltageDomain(
                            voltage = options.sys_voltage))
                    int_links.append(IntLink(link_id=link_count,
                                             src_node=routers[south_out],
                                             dst_node=routers[north_in],
                                             src_outport="South",
                                             dst_inport="North",
                                             src_cdc = srcCDC,
                                             dst_cdc = dstCDC,
                                             clk_domain = link_clk,
                                             latency = link_latency,
                                             weight=2))
                    link_count += 1
        network.int_links = int_links
