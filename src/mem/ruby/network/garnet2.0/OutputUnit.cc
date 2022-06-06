/*
 * Copyright (c) 2020 Inria
 * Copyright (c) 2016 Georgia Institute of Technology
 * Copyright (c) 2008 Princeton University
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


#include "mem/ruby/network/garnet2.0/OutputUnit.hh"

#include "debug/RubyNetwork.hh"
#include "mem/ruby/network/garnet2.0/Credit.hh"
#include "mem/ruby/network/garnet2.0/CreditLink.hh"
#include "mem/ruby/network/garnet2.0/Router.hh"
//// Updown Routing with Escape_VC
// code begin
#include "mem/ruby/network/garnet2.0/InputUnit.hh"

// code end
#include "mem/ruby/network/garnet2.0/flitBuffer.hh"

OutputUnit::OutputUnit(int id, PortDirection direction, Router *router,
  uint32_t consumerVcs)
  : Consumer(router), m_router(router), m_id(id), m_direction(direction),
    m_vc_per_vnet(consumerVcs)
{
    const int m_num_vcs = consumerVcs * m_router->get_num_vnets();
    outVcState.reserve(m_num_vcs);
    for (int i = 0; i < m_num_vcs; i++) {
        outVcState.emplace_back(i, m_router->get_net_ptr(), consumerVcs);
    }
}

void
OutputUnit::decrement_credit(int out_vc)
{
    DPRINTF(RubyNetwork, "Router %d OutputUnit %s decrementing credit:%d for "
            "outvc %d at time: %lld for %s\n", m_router->get_id(),
            m_router->getPortDirectionName(get_direction()),
            outVcState[out_vc].get_credit_count(),
            out_vc, m_router->curCycle(), m_credit_link->name());

    outVcState[out_vc].decrement_credit();
}

void
OutputUnit::increment_credit(int out_vc)
{
    DPRINTF(RubyNetwork, "Router %d OutputUnit %s incrementing credit:%d for "
            "outvc %d at time: %lld from:%s\n", m_router->get_id(),
            m_router->getPortDirectionName(get_direction()),
            outVcState[out_vc].get_credit_count(),
            out_vc, m_router->curCycle(), m_credit_link->name());

    outVcState[out_vc].increment_credit();
}

// Check if the output VC (i.e., input VC at next router)
// has free credits (i..e, buffer slots).
// This is tracked by OutVcState
bool
OutputUnit::has_credit(int out_vc)
{
    assert(outVcState[out_vc].isInState(ACTIVE_, curTick()));
    return outVcState[out_vc].has_credit();
}


//// Updown Routing with Escape_VC
// code begin
int
OutputUnit::getNumFreeVCs(int vnet)
{
    int freeVC = 0;    
    int vc_base = vnet*m_vc_per_vnet;
    for (int vc = vc_base; vc < vc_base + m_vc_per_vnet; vc++) {
        if (is_vc_idle(vc, curTick()))
            freeVC++;
    }
    return freeVC;

}
// code end

// Check if the output port (i.e., input port at next router) has free VCs.
//// Updown Routing with Escape_VC
// code begin
bool
OutputUnit::has_free_vc(int vnet, int invc, flit* t_flit, int inport)
{
    if (m_router->get_net_ptr()->escape_vc == 1) {
        // with escape_vc

        int vc_base = vnet*m_vc_per_vnet;
        // select last vc of this vnet as escape VC
        int escapeVC = vc_base + (m_vc_per_vnet - 1);

        // select free vc !!!
        if (invc == escapeVC) {
            // if invc is escapeVC
            ///////////////////////////////////////////////////////////
            // can't use the assert here as flit might
            // just injected into 'escapeVC' at source!
            if (t_flit->get_injection_vc() != escapeVC)
                assert(t_flit->get_route().new_src != -1);
            ///////////////////////////////////////////////////////////
            // if escapeVC is idle, use escapeVC
            if (is_vc_idle(invc, m_router->curCycle())) {
                return true;
            }
        } else {
            // if invc not escapeVC
            if ((t_flit->get_type() == HEAD_) ||
                (t_flit->get_type() == HEAD_TAIL_)) {
                // only for 'HEAD_' or 'HEAD_TAIL_' flit
                // get upDn_outport
                PortDirection inport_dirn = m_router-> \
                    getInputUnit(inport)->get_direction();
                // -------------------------------------------------- //
                int upDn_outport = m_router->get_routingUnit_ref()-> \
                    outportCompute(t_flit->get_route(), invc, inport,
                                inport_dirn, true);
                if (upDn_outport == m_id) {
                    // if `upDn_outport` is the same as `this_outport`
                    // consider escapeVC, select vc from all vc
                    for (int vc = vc_base; vc < vc_base + m_vc_per_vnet; vc++)
                    {
                        if (is_vc_idle(vc, m_router->curCycle())) {
                            return true;
                        }
                    }
                } else {
                    // select vc from all vc except escapeVC
                    for (int vc = vc_base; vc < escapeVC; vc++) {
                        if (is_vc_idle(vc, m_router->curCycle())) {
                            return true;
                        }
                    }
                }
            }
        }
    } else {
        // without escape_vc: original select_free_vc() function
        int vc_base = vnet*m_vc_per_vnet;
        for (int vc = vc_base; vc < vc_base + m_vc_per_vnet; vc++) {
            if (is_vc_idle(vc, m_router->curCycle())) {
                // has free vc, return true
                return true;
            }
        }
    }

    return false;
}
// code end

// Assign a free output VC to the winner of Switch Allocation
//// Updown Routing with Escape_VC
// code begin
int
OutputUnit::select_free_vc(int vnet, int invc, flit* t_flit, int inport)
{
    if (m_router->get_net_ptr()->escape_vc == 1) {
        // with escape_vc

        int vc_base = vnet*m_vc_per_vnet;
        // select last vc of this vnet as escape VC
        int escapeVC = vc_base + (m_vc_per_vnet - 1);

        // select free vc !!!
        if (invc == escapeVC) {
            // if invc is escapeVC
            ///////////////////////////////////////////////////////////
            // if injection vc not escapeVC, new_src should != -1 ?
            // what is injection_vc ???
            // why new_src != -1 ???
            if (t_flit->get_injection_vc() != escapeVC)
                assert(t_flit->get_route().new_src != -1);
            ///////////////////////////////////////////////////////////
            // if escapeVC is idle, use escapeVC
            if (is_vc_idle(invc, m_router->curCycle())) {
                outVcState[invc].setState(ACTIVE_, m_router->curCycle());
                // -------------------------------------------------- //
                return invc;
            }
        } else {
            // if invc not escapeVC
            if ((t_flit->get_type() == HEAD_) ||
                (t_flit->get_type() == HEAD_TAIL_)) {
                // only for 'HEAD_' or 'HEAD_TAIL_' flit
                // get upDn_outport
                PortDirection inport_dirn = m_router-> \
                    getInputUnit(inport)->get_direction();
                // -------------------------------------------------- //
                int upDn_outport = m_router->get_routingUnit_ref()-> \
                    outportCompute(t_flit->get_route(), invc, inport,
                                inport_dirn, true);
                if (upDn_outport == m_id) {
                    // if `upDn_outport` is the same as `this_outport`
                    // consider escapeVC, select vc from all vc
                    for (int vc = vc_base; vc < vc_base + m_vc_per_vnet; vc++)
                    {
                        if (is_vc_idle(vc, m_router->curCycle())) {
                            outVcState[vc].setState(ACTIVE_,
                                                    m_router->curCycle());
                            // ---------------------------------------- //
                            if (vc == escapeVC) {
                                // if vc is escapeVC,
                                // then set this router as the new src
                                assert(t_flit->get_route().new_src == -1);
                                t_flit->get_route_ref().new_src = \
                                    m_router->get_id();
                            }
                            return vc;
                        }
                    }
                } else {
                    // select vc from all vc except escapeVC
                    for (int vc = vc_base; vc < escapeVC; vc++) {
                        if (is_vc_idle(vc, m_router->curCycle())) {
                            outVcState[vc].setState(ACTIVE_,
                                                    m_router->curCycle());
                            // ---------------------------------------- //
                            return vc;
                        }
                    }
                }
            }
        }
    } else {
        // without escape_vc: original select_free_vc() function
        int vc_base = vnet*m_vc_per_vnet;
        for (int vc = vc_base; vc < vc_base + m_vc_per_vnet; vc++) {
            if (is_vc_idle(vc, m_router->curCycle())) {
                // set outvc state
                outVcState[vc].setState(ACTIVE_, m_router->curCycle());
                // return the first free vc
                return vc;
            }
        }
    }

    return -1;
}
// code end


/*
 * The wakeup function of the OutputUnit reads the credit signal from the
 * downstream router for the output VC (i.e., input VC at downstream router).
 * It increments the credit count in the appropriate output VC state.
 * If the credit carries is_free_signal as true,
 * the output VC is marked IDLE.
 */

void
OutputUnit::wakeup()
{
    if (m_credit_link->isReady(curTick())) {
        Credit *t_credit = (Credit*) m_credit_link->consumeLink();
        increment_credit(t_credit->get_vc());

        if (t_credit->is_free_signal())
            set_vc_state(IDLE_, t_credit->get_vc(), curTick());

        delete t_credit;

        if (m_credit_link->isReady(curTick())) {
            scheduleEvent(Cycles(1));
        }
    }
}

flitBuffer*
OutputUnit::getOutQueue()
{
    return &outBuffer;
}

void
OutputUnit::set_out_link(NetworkLink *link)
{
    m_out_link = link;
}

void
OutputUnit::set_credit_link(CreditLink *credit_link)
{
    m_credit_link = credit_link;
}

void
OutputUnit::insert_flit(flit *t_flit)
{
    outBuffer.insert(t_flit);
    m_out_link->scheduleEventAbsolute(m_router->clockEdge(Cycles(1)));
}

uint32_t
OutputUnit::functionalWrite(Packet *pkt)
{
    return outBuffer.functionalWrite(pkt);
}
