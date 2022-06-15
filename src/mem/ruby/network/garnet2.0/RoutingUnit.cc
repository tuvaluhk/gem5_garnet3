/*
 * Copyright (c) 2008 Princeton University
 * Copyright (c) 2016 Georgia Institute of Technology
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met: redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer;
 * redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution;
 * neither the name of the copyright holders nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include "mem/ruby/network/garnet2.0/RoutingUnit.hh"

#include "base/cast.hh"
#include "debug/RubyNetwork.hh"
#include "mem/ruby/network/garnet2.0/InputUnit.hh"
#include "mem/ruby/network/garnet2.0/Router.hh"

//// Updown Routing with Escape_VC
// code begin
#include "mem/ruby/network/garnet2.0/OutputUnit.hh"

// code end
#include "mem/ruby/slicc_interface/Message.hh"

RoutingUnit::RoutingUnit(Router *router)
{
    m_router = router;
    m_routing_table.clear();
    m_weight_table.clear();
}

void
RoutingUnit::addRoute(std::vector<NetDest>& routing_table_entry)
{
    if (routing_table_entry.size() > m_routing_table.size()) {
        m_routing_table.resize(routing_table_entry.size());
    }
    for (int v = 0; v < routing_table_entry.size(); v++) {
        m_routing_table[v].push_back(routing_table_entry[v]);
    }
}

void
RoutingUnit::addWeight(int link_weight)
{
    m_weight_table.push_back(link_weight);
}

bool
RoutingUnit::supportsVnet(int vnet, std::vector<int> sVnets)
{
    // If all vnets are supported, return true
    if (sVnets.size() == 1 && sVnets[0] == -1) {
        return true;
    }

    // Find the vnet in the vector, return true
    if (std::find(sVnets.begin(), sVnets.end(), vnet) != sVnets.end()) {
        return true;
    }

    // Not supported vnet
    return false;
}

/*
 * This is the default routing algorithm in garnet.
 * The routing table is populated during topology creation.
 * Routes can be biased via weight assignments in the topology file.
 * Correct weight assignments are critical to provide deadlock avoidance.
 */
int
RoutingUnit::lookupRoutingTable(int vnet, NetDest msg_destination)
{
    // First find all possible output link candidates
    // For ordered vnet, just choose the first
    // (to make sure different packets don't choose different routes)
    // For unordered vnet, randomly choose any of the links
    // To have a strict ordering between links, they should be given
    // different weights in the topology file

    int output_link = -1;
    int min_weight = INFINITE_;
    std::vector<int> output_link_candidates;
    int num_candidates = 0;

    // Identify the minimum weight among the candidate output links
    for (int link = 0; link < m_routing_table[vnet].size(); link++) {
        if (msg_destination.intersectionIsNotEmpty(
            m_routing_table[vnet][link])) {

        if (m_weight_table[link] <= min_weight)
            min_weight = m_weight_table[link];
        }
    }

    // Collect all candidate output links with this minimum weight
    for (int link = 0; link < m_routing_table[vnet].size(); link++) {
        if (msg_destination.intersectionIsNotEmpty(
            m_routing_table[vnet][link])) {

            if (m_weight_table[link] == min_weight) {
                num_candidates++;
                output_link_candidates.push_back(link);
            }
        }
    }

    if (output_link_candidates.size() == 0) {
        fatal("Fatal Error:: No Route exists from this Router.");
        exit(0);
    }

    // Randomly select any candidate output link
    int candidate = 0;
    if (!(m_router->get_net_ptr())->isVNetOrdered(vnet))
        candidate = rand() % num_candidates;

    output_link = output_link_candidates.at(candidate);
    return output_link;
}

//// Updown Routing with Escape_VC
// code begin
int
RoutingUnit::lookupRoutingTable_adaptive(int vnet, NetDest msg_destination)
{

    int output_link = -1;
    int min_weight = INFINITE_;
    std::vector<int> output_link_candidates;
    int num_candidates = 0;

    // Identify the minimum weight among the candidate output links
    for (int link = 0; link < m_routing_table.size(); link++) {
        if (msg_destination.intersectionIsNotEmpty(m_routing_table[vnet][link])) {

        if (m_weight_table[link] <= min_weight)
            min_weight = m_weight_table[link];
        }
    }

    // Collect all candidate output links with this minimum weight
    for (int link = 0; link < m_routing_table.size(); link++) {
        if (msg_destination.intersectionIsNotEmpty(m_routing_table[vnet][link])) {

            if (m_weight_table[link] == min_weight) {

                num_candidates++;
                output_link_candidates.push_back(link);
            }
        }
    }

    if (output_link_candidates.size() == 0) {
        fatal("Fatal Error:: lookupRoutingTable_adaptive: No Route exists from this Router.");
        exit(0);
    }


    // Randomly select any candidate output link
    //int candidate = 0;
    //if (!(m_router->get_net_ptr())->isVNetOrdered(vnet))
    //    candidate = rand() % num_candidates;

    // Choose the candidate output link,
    // whose outport has the largest number of free vc (Adaptive)
    int outport_id;		// outport ID
    int accum_;			// credit count
    // (free vc number of outport)
    std::vector<int>outport_credit_index;  // credit count vector

    // 1 loop through the candidate links, get credit count
    for (int i = 0; i < output_link_candidates.size(); i++) {
        outport_id = output_link_candidates[i];
        // get credit count
        accum_ = 0;
        // -------------------------------------------------- //
        accum_ += m_router->getOutputUnit(outport_id) \
                    ->getNumFreeVCs(vnet);
        outport_credit_index.push_back(accum_);
    }

    // 2 get the outport index of max credit count in vector
    int max = -1;
    int candidate = -1;
    for (int i = 0; i < outport_credit_index.size(); i++ ) {
        if (outport_credit_index[i] > max) {
            max = outport_credit_index[i];
            candidate = i;
        }
    }

    output_link = output_link_candidates.at(candidate);
    return output_link;
}
// code end

void
RoutingUnit::addInDirection(PortDirection inport_dirn, int inport_idx)
{
    m_inports_dirn2idx[inport_dirn] = inport_idx;
    m_inports_idx2dirn[inport_idx]  = inport_dirn;
}

/// Updown Routing+ code begin
void
RoutingUnit::addOutDirection(SwitchID dest,\
PortDirection outport_dirn, int outport_idx)
{
    m_outports_dirn2idx[outport_dirn] = outport_idx;
    m_outports_idx2dirn[outport_idx]  = outport_dirn;
    if (outport_dirn != "Local") {
        m_nxt_router_id2idx[dest] = outport_idx;
        }
}
/// code end

// outportCompute() is called by the InputUnit
// It calls the routing table by default.
// A template for adaptive topology-specific routing algorithm
// implementations using port directions rather than a static routing
// table is provided here.

//// Updown Routing with Escape_VC
// code begin
int
RoutingUnit::outportCompute(RouteInfo route, int vc, int inport,
                            PortDirection inport_dirn,
                            bool check_upDn_port)
// code end
{
    int outport = -1;

    if (route.dest_router == m_router->get_id()) {

        // Multiple NIs may be connected to this router,
        // all with output port direction = "Local"
        // Get exact outport id from table
        outport = lookupRoutingTable(route.vnet, route.net_dest);
        return outport;
    }

    // Routing Algorithm set in GarnetNetwork.py
    // Can be over-ridden from command line using --routing-algorithm = 1
    RoutingAlgorithm routing_algorithm =
        (RoutingAlgorithm) m_router->get_net_ptr()->getRoutingAlgorithm();
    if (m_router->get_net_ptr()->escape_vc == 0) {
        //// Updown Routing: Implement of routing switch function
        //// Updown Routing+: Implement of routing switch function
        //// WestFirst: Implement of routing switch function
        // code begin
        switch (routing_algorithm) {
            case TABLE_:  outport =
                lookupRoutingTable(route.vnet, route.net_dest); break;
            case XY_:     outport =
                outportComputeXY(route, inport, inport_dirn); break;
            /// updown routing
            case UPDN_:     outport =
                outportComputeUPDN(route, inport, inport_dirn, check_upDn_port); break;     
            /// end        
            // any custom algorithm
            case CUSTOM_: outport =
                outportComputeCustom(route, inport, inport_dirn); break;
            default: outport =
                lookupRoutingTable(route.vnet, route.net_dest); break;
        }

    }else if ((routing_algorithm == UPDN_) &&
                (m_router->get_net_ptr()->escape_vc == 1)){
        // get vc_base and escapeVC of current vnet
        int vc_base = route.vnet*m_router->get_vc_per_vnet();
        int escapeVC = vc_base + (m_router->get_vc_per_vnet() - 1);
        // if vc is escapeVC, compute outport using UpDown Routing
        if (vc == escapeVC || check_upDn_port) {
            outport = outportComputeUPDN(route, inport, inport_dirn, check_upDn_port);
        } else {
            // else using lookupRoutingTable_adaptive
            outport = lookupRoutingTable_adaptive(route.vnet, route.net_dest);
        }

    } else {
        std::cout << "Invalid value of 'escape_vc'!" << std::endl;
        assert(0);
    }

    assert(outport != -1);
    return outport;
}

// XY routing implemented using port directions
// Only for reference purpose in a Mesh
// By default Garnet uses the routing table
int
RoutingUnit::outportComputeXY(RouteInfo route,
                              int inport,
                              PortDirection inport_dirn)
{
    PortDirection outport_dirn = "Unknown";

    int M5_VAR_USED num_rows = m_router->get_net_ptr()->getNumRows();
    int num_cols = m_router->get_net_ptr()->getNumCols();
    assert(num_rows > 0 && num_cols > 0);

    int my_id = m_router->get_id();
    int my_x = my_id % num_cols;
    int my_y = my_id / num_cols;

    int dest_id = route.dest_router;
    int dest_x = dest_id % num_cols;
    int dest_y = dest_id / num_cols;

    int x_hops = abs(dest_x - my_x);
    int y_hops = abs(dest_y - my_y);

    bool x_dirn = (dest_x >= my_x);
    bool y_dirn = (dest_y >= my_y);

    // already checked that in outportCompute() function
    assert(!(x_hops == 0 && y_hops == 0));

    if (x_hops > 0) {
        if (x_dirn) {
            assert(inport_dirn == "Local" || inport_dirn == "West");
            outport_dirn = "East";
        } else {
            assert(inport_dirn == "Local" || inport_dirn == "East");
            outport_dirn = "West";
        }
    } else if (y_hops > 0) {
        if (y_dirn) {
            // "Local" or "South" or "West" or "East"
            assert(inport_dirn != "North");
            outport_dirn = "North";
        } else {
            // "Local" or "North" or "West" or "East"
            assert(inport_dirn != "South");
            outport_dirn = "South";
        }
    } else {
        // x_hops == 0 and y_hops == 0
        // this is not possible
        // already checked that in outportCompute() function
        panic("x_hops == y_hops == 0");
    }

    return m_outports_dirn2idx[outport_dirn];
}

//// Updown Routing: Implement of Updown Routing
// code begin
int
RoutingUnit::outportComputeUPDN(RouteInfo route,
                    int inport,
                    PortDirection inport_dirn,
                    bool check_upDn_port)
{
    //PortDirection outport_dirn = "Unknown";
    int nxt_router_id = 0;

    // get curr_id, dest_id and stc_id
    int curr_id = m_router->get_id();
    int src_id;
    int dest_id = route.dest_router;

    //// Updown Routing with Escape_VC
    // code begin
    // get src_id
    if (check_upDn_port) {
        src_id = curr_id;
    } else {
        if (route.new_src == -1)
            // if no escapeVC
            src_id = route.src_router;
        else
            // if escapeVC
            // new_src set in OutputUnit::select_free_vc
            src_id = route.new_src;
    }
    // code end

    // if current id is the source id
    if (curr_id == src_id) {
        // this means that it's the beginning
        nxt_router_id = m_router->get_net_ptr()->\
            routingTable[src_id][dest_id][0].next_router_id;
    } else {
        // for cycle until match the target index:
        for (int indx= 0; indx < m_router->get_net_ptr()->\
            routingTable[src_id][dest_id].size(); indx++) {
            // choose next port from routingTable
            if (m_router->get_net_ptr()->\
                routingTable[src_id][dest_id][indx].\
                next_router_id == curr_id) {
                nxt_router_id = m_router->get_net_ptr()->\
                    routingTable[src_id][dest_id][indx+1].next_router_id;
                break;
            }
        }
    }

    //assert(outport_dirn != "Unknown");
    //cout << "curr_id: " << curr_id << endl;
    //cout << "dest_id: " << dest_id << endl;
    //cout << "outport_dirn: " << outport_dirn << endl;
    /*cout << "m_outports_dirn2idx[outport_dirn]: " \
    << m_outports_dirn2idx[outport_dirn] << endl;*/
    return m_nxt_router_id2idx[nxt_router_id];
}
// code end

// Template for implementing custom routing algorithm
// using port directions. (Example adaptive)
int
RoutingUnit::outportComputeCustom(RouteInfo route,
                                 int inport,
                                 PortDirection inport_dirn)
{
    panic("%s placeholder executed", __FUNCTION__);
}
