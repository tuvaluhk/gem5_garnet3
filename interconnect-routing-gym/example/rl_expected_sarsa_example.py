### Modification
# Author: Tung Thanh Le 
# ttungl@gmail.com
###

from collections import defaultdict, deque
from icn_gym import *

import numpy as np
import random
import csv
import os

import matplotlib as mpl
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt


## Global Parameters 
path = "/home/tuvalu/Documents/HeteroGarnet-early/interconnect-routing-gym/"
# topologies = ["Mesh_XY", "Mesh_XY", "Mesh_westfirst"]

# topologies = ["Mesh_XY", "Mesh_XY", "Mesh_XY"]
routing_algorithm = ["0", "0", "0"]
actions = ["NoI_ButterDonut_X", "NoI_DoubleButterfly_X", "NoI_FoldedTorus_X"]
algorithm = "Expected_sarsa"

a_size = len(actions) # space size of action
Q = defaultdict(lambda: np.zeros(a_size)) # Q-Table
dicts = defaultdict(list)
action_index = random.randint(0, 100)%3
action = actions[action_index]
routing_algorithm = routing_algorithm[action_index] ## TL added 082620

iter_step = 12 # injection from 0.05 to 0.6
total_episodes = 50 # Game Playing times

epsilon = 1.0       # exploration rate
eps_min = 0.01
eps_decay = 0.999

### historical data
rew_history = []

####################
## Expected sarsa ##
####################
for i_episode in range(total_episodes):
	state = 0.02 # = Injection_rate reset
	policy_s = epsilon_greedy_probs(Q[state], i_episode)
	action_index = np.random.choice(np.arange(a_size), p = abs(policy_s))
	action = actions[action_index]
	#topology = topologies[action_index] ## TL added 082620

	rewardsum = 0
	for i in np.arange(0.02, 0.32, 0.02):
		print("Expected Sarsa, i_episode {}; injection_rate {}".format(i_episode, state))
		# next_state = (i+1)*1.0/10.0 # get next state
		next_state = (state*1.0 + 0.02) # get next state
		action = actions[action_index]
		#topology = topologies[action_index] ## TL added 082620

		dicts = icn_routing_gym(i_episode, state, action, routing_algorithm) ## TL added 082620

		#reward = reward_f(dicts) # get reward latency from original action 
		reward = reward_uf(dicts) # get reward throughput from original action

		rewardsum += reward # Sum of Reward for this episode
		if epsilon > eps_min: epsilon *= eps_decay

		# get epsilon-greedy action probabilities
		policy_s = epsilon_greedy_probs(Q[next_state], i_episode)
		# pick next action A'
		next_action_index = np.random.choice(np.arange(a_size), p=policy_s)
		# update TD estimate of Q
		Q[state][action_index] = update_Q(Q[state][action_index], np.dot(Q[next_state], policy_s), \
												reward, .01, epsilon)
		
		# update state and action
		action_index = next_action_index
		action = actions[action_index] # get next action
		state = next_state

	rew_history.append(rewardsum) # Recording rewards

print('Q-Table:', Q)

print('Reward:', rew_history)

############
## tables ##
############

# csv_columns = ['average_flit_latency','average_packet_queueing_latency','average_flit_network_latency','average_flit_queueing_latency','packets_injected', 'average_packet_network_latency', 'average_hops',  'flits_injected', 'packets_received',  'flits_received', 'average_packet_latency']
csvfile = path + 'Inter_Connect_Networks/Tables/ESARSA_xy_'+str(iter_step)+'_'+str(total_episodes)+'.csv'

## TL added 082820
# ## read back csvfile
# with open(csvfile) as csv_file:
# 	reader = csv.reader(csv_file)
# 	mydict = dict(reader)

## write dicts
with open(csvfile, 'w') as csv_file:  
	writer = csv.writer(csv_file)
	for key, value in dicts.items():
		writer.writerow([key]+value)


####################
## reward history ##
####################
# csv_rew_hist = path + "Inter_Connect_Networks/Rewards_Hist/Reward_history_rl_sarsa_{}_{}.csv".format(iter_step, total_episodes)

# with open(csv_rew_hist, 'w') as csv_file:  
# 	writer = csv.writer(csv_file)
# 	for value in rew_history:
# 		writer.writerow(value)

np.savetxt(path + "Inter_Connect_Networks/Rewards_Hist/Reward_history_rl_expected_sarsa_xy.csv", rew_history, delimiter=",")

### Plotting 
# print("Learning Performance")
mpl.rcdefaults()
mpl.rcParams.update({'font.size': 16})

fig, ax = plt.subplots(figsize=(10,4))
#plt.grid(True, linestyle='--')
plt.title('RLE-NOC Learning')
# plt.plot(range(len(time_history)), time_history, label='Steps', marker="^", linestyle=":")#, color='red')
plt.plot(range(len(rew_history)), rew_history, label='Reward', marker="", linestyle="-")#, color='k')
plt.xlabel('Episodes')
plt.ylabel('Reward')
plt.savefig(path + 'Inter_Connect_Networks/Figures/ESARSA_xy_'+str(iter_step)+'_'+str(total_episodes)+'_RLNOC.png', bbox_inches='tight')
