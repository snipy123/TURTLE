#!/bin/bash
#BSUB -n 128
#BSUB -J benchgamess
#BSUB -o benchgamess.out.%J
#BSUB -W 04:00
#BSUB -R "span[ptile=2]"

export LD_LIBRARY_PATH=/opt/gm/lib:${LD_LIBRARY_PATH}

binary=../../../../bin/gamess-uk
inputdir=../../input_files_benchmarks
jobs_list=$inputdir/jobs.list
mycwd=$LS_SUBCWD

for job in `cat $jobs_list | grep -v "#"`
do
cp $inputdir/${job}.in datain
mpirun.lsf_pgi -np 128 $binary  >& $mycwd/${job}.out.128
done

/bin/rm -rf ed3-cyclo ed3-tot12 ed3-morphine ed3-valino ftn058
/bin/rm -rf options.dft datain
