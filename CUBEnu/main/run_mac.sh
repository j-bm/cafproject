source ../utilities/module_load_mac.sh

#rm -rf ../output/universe1/*

cd ../utilities/
make clean
make

# Main N-body code
cd ../main/
make clean
make

cd ../utilities/
./ic.x
./ic_nu.x
cd ../main/
./cube.x
cd ../utilities/
./cicpower.x


cd ../main/
