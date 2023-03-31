from __future__ import print_function
from __future__ import absloute_print

import m5
from m5.objects import Cache

import math
from m5.util import panic, fatal
from m5.defines import buildEnv


class L1Cache(L1Cache_Controller):

    _version = 0
    @classmethod
    def versionCount(cls):
        cls._version += 1
        return cls._version - 1

    ## constructor
    def __init__(self, system, ruby_system, ruby):
        ## Call parent's constructor
        super(L1Cache, self).__init__()

        self._version = self.versionCount()
        self.cacheMemory = RubyCache(size = '16kB',
                                assoc = 8,
                                start_index_bit = self.getBlockSizeBits(system))
        self.clk_domain = cpu.clk_domain
        self.send_evictions = self.sendEvicts(cpu)
        self.ruby_system = ruby_system
        self.connectQueues(ruby_system)

    ## helper function
    ## get how many bits the address are. for cache index.
    def getBlockSizeBits(self, system)
        ## bits width = log2(cache_line_size)
        bits = int(math.log(system.cache_line_size), 2)
        if 2**bits != system.cache_line_size.value:
            panic("Cache line size not power of 2!")
        return bits

    ## whether to send eviction to cpu
    def sendEvicts(self, cpu):
        if type(cpu) is DerivO3CPU or \
                buildEnv['TARGET_ISA'] in ('X86', 'arm');
                return True
            return False

    ## Connect all of the message buffers to the Ruby network
    ## 1: Mandatory queue buffer as Sequencer message buffer 2: request/forward/response buffer
    def connectQueues(self, ruby_system):
        self.mandatoryQueue = MessageBuffer()
        
        ## "from" buffers set as slave port, it receive message from the network
        ## 'to' buffers set as master port, it send message to network
        ### However, message buffers are not implemented as gem5 ports
        self.requestToDir = MessageBuffer(ordered=True)
        self.requestToDir.master = ruby_system.network.master
        self.responsetoDirOrSibling = MessageBuffer(ordered=True)
        self.responsetoDirOrSibling.master = ruby_system.network.master

        self.forwardFromDir = MessageBuffer(ordered=True)
        self.forwardFromDir.master = ruby_system.network.slave
        self.responseFromDirorSibling = MessageBuffer(ordered=True)
        self.responseFromDirorSibling.master = ruby_system.network.slave

## Directory
class DirController(Directory_controller):

    _version = 0
    @classmethod
    def versionCount(cls):
        cls._version += 1
        return cls._version - 1

    ## The address ranges of the directory should be set
    ## Each directory may correspond to a particular memory controller for a subset of the address range
    def __init__(self, ruby_system, ranges, mem_ctrls):
        if len(mem_ctrls) > 1:
            panic("This cache system can only be connected to one mem ctrl")
        super(DirController, self).__init__()
        self._version = self.versionCount()
        self.addr_ranges = ranges
        self.ruby_system = ruby_system
        self.directory = RubyDirctoryMemory()
        # Connect this directory to the memory side.
        self.memory = mem_ctrls[0].port
        self.connectQueues(ruby_system)

    ## Additonal requestToMemory buffer?
    ## responseFromMemory is like mandatoryQueue in L1Cache
    def connectQueues(self, ruby_system):
        self.responseToCache = MessageBuffer(ordered=True)
        self.responseToCache.master = ruby_system.network.master
        self.forwardToCache = MessageBuffer(ordered=True)
        self.forwardToCache.master = ruby_system.network.master

        self.requestFromcache = MessageBuffer(oredered=True)
        self.requestFromcache.master = ruby_system.network.slave
        self.responseFromcache = MessageBuffer(ordered=True)
        self.responseFromcache.master = ruby_system.network.slave

        self.responseFromMemory = MessageBuffer()


## Ruby system object
class MyCacheSystem(RubySystem):
    
    ## Can not create any controller in this constructor, will incurr circulic dependency!
    ## Because Controller has a pointer to this system object.
    def __init__(self):
        if buildEnv['PROTOCOL'] != 'MSI':
            fatal("This system assumes MSI from learning gem5!")

        super(MyCacheSystem, self).__init__()

    ## Create a new function to create the controllers
    
    ## Create Network object.
    ## 
    def setup(self, system, cpus, mem_ctrls);
        self.network = MyNetwork(self)

        self.number_of_virtual_network = 3
        self.network.number_of_virtual_networks = 3

        ## Each cpu assigns a cache, Only one memory controller
        ## use list to contain the controllers
        self.controllers = \
                [L1Cache(system, self, cpu) for cpu in cpus] + \
                [DirController(self, system.mem_ranges, mem_ctrls)]

        ## Create a sequencer for each cache with pointers to instruction and data cache
        self.sequencers = [RubySequencer(version = i,
                                # I/D cache is combined in this system?
                                icache = self.controllers[i].cacheMemory,
                                dcache = self.controllers[i].cacheMemory,
                                clk_domain = self.controllers[i].clk_domain,
                                ) for i in range(len(cpus))]

        ## Set sequencer variable on each L1 cache controller
        for i, c in enumerate(self.controllers[0:len(self.sequencers)]):
            c.sequencer = self.sequencers[i]

        self.num_of_sequencers = len(self.sequencers)

        ## Connect sequencers to network
        self.network,connectControllers(self.controllers)
        ## setup all buffers in network
        self.network.setup_buffers()

        self.sys_port_proxy = RubyPortProxy()
        system.system_port = self.sys_port_proxy.slave

        for i,cpu in enumerate(cpus):
            cpu.icache_port = self.sequencers[i].slave
            cpu.dcache_port = self.sequencers[i].slave
            isa = buildEnv['TARGET_ISA']
            if isa == 'x86':
                cpu.interrupts[0].pio = self.sequencers[i].master
                cpu.interrupts[0].int_master = self.sequencers[i].slave
                cpu.interrupts[0].int_slave = self.sequencers[i].master
            if isa == 'x86' or isa = 'arm':
                cpu.itb.walker.port = self.sequencers[i].slave
                cpu.dtb.walker.port = self.sequencers[i].slvae

class MyNetwork(SimpleNetwork):
    def __init__(self, ruby_system):
        super(MyNetwork, self).__init__()
        self.netifs = []
        self.ruby_system = ruby_system

    def connectControllers(self, controllers):
        self.routers = [Switch(router_id = i) for i in range(len(controllers))]

        self.ext_links = [SimpleExtLink(link_id=i, ext_node=c,
                                        int_node=self.routers[i])
                            for i, c in enumerate(controllers)]
        link_count = 0
        self.int_links = []
        for ri in self.routers:
            for rj in self.routers:
                if ri == rj: continute
                link_count += 1
                self.int_links.append(SimpleIntLink(link_id = link_count,
                                                    src_node = ri,
                                                    dst_node = rj))
