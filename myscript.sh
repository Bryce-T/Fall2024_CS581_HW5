#!/bin/bash
source /apps/profiles/modules_asax.sh.dyn
module load cuda/11.7.0
nvcc homework5.cu -o homework5
./homework5 10000 5000 scratch/$USER/
./homework5 10000 5000 scratch/$USER/
./homework5 10000 5000 scratch/$USER/
