export FC='mpif90'
#export XFLAG='-O3 -cpp -fcoarray=single -mcmodel=medium'
export XFLAG='-O3 -cpp -fcoarray=single'
#export XFLAG='-O3 -cpp -fcoarray=single -fopenmp'
export OFLAG=${XFLAG}' -c'
export FFTFLAG='-lfftw3f -lm -ldl'
# -fopenmp cause (maybe memory) probelm: Segmentation fault: 11
# in cumsum6
