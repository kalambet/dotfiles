### Linux start ###
export PATH=${HOME}/dev/github.com/mimblewimble/grin-miner:${PATH:+${PATH}}
export PATH=/usr/local/cuda-10.0/bin:${PATH:+${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-10.0/lib64 \
                         ${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

### Linux end ###
