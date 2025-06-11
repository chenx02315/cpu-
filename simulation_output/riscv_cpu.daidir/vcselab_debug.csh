#!/bin/csh -f

cd /home/jiangchuanc/Desktop/Design_CPU

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/cad/synopsys/vcs-mx/R-2020.12-SP2/linux64/bin/vcselab $* \
    -o \
    simulation_output/riscv_cpu \
    -nobanner \

cd -

