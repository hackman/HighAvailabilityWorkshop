# Define the primitive for the LSB HAproxy resource
    primitive haproxy lsb:haproxy op monitor interval=2s target-role=Started

# Define a clone resource to make it run on all nodes in the cluster
    clone haproxy-clone haproxy meta clone-max=3 clone-node-max=1 globally-unique=false ordered=false interleave=false target-role=Started is-managed=true


