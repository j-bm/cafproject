export FC='gfortran'
#export XFLAG=' -O3 -cpp -fopenmp -fcoarray=single -mcmodel=medium'
#export XFLAG=' -cpp -fopenmp -fcoarray=single -fcheck=all'
export XFLAG='-O3 -cpp -fcoarray=single -fopenmp'
export OFLAG=${XFLAG}' -c'
export FFTFLAG='-I/usr/local/include/ -L/usr/local/lib/ -lfftw3f -lm -ldl'
# -fopenmp cause (maybe memory) probelm: Segmentation fault: 11
# in cumsum6

export OMP_STACKSIZE=6000M
export OMP_NUM_THREADS=4
#export OMP_THREAD_LIMIT=4
ulimit -s 61000
ulimit
