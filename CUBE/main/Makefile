OPTIONS=
#OPTIONS+=-DPID
#OPTIONS+=-Wall

MODFILE:=$(wildcard *.f90)
OBJFILE:=$(addprefix ,$(notdir $(MODFILE:.f90=.o)))

all: cafcube.x # acc.x


#cafcube.x: $(OBJFILE)
cafcube.x: cafcube.o parameters.o variables.o initialize.o cubefft.o pencil_fft.o kernel_f.o kernel_c.o timestep.o particle_initialization.o buffer_density.o buffer_x.o buffer_v.o pm.o update_particle.o checkpoint.o projection.o finalize.o
	@echo ""
	@echo "Link files:"
#	$(FC) $(XFLAG) $(OPTIONS) $(OBJFILE) -o $@ $(FFTFLAG)
	$(FC) $(XFLAG) $(OPTIONS) $^ -o $@ $(FFTFLAG)


acc.x: acc_field.o parameters.o variables.o initialize.o cubefft.o pencil_fft.o particle_initialization.o buffer_density.o buffer_x.o pm_acceleration.o finalize.o kernel_c.o kernel_f.o
	@echo ""
	@echo "Link files:"
	$(FC) $(XFLAG) $(OPTIONS) $^ -o $@ $(FFTFLAG)





## For addtional subroutines, add its dependency on variables.o, and dependency of cafcube.o on it.

variables.o: parameters.o
pencil_fft.o: parameters.o

buffer_x.o: variables.o
buffer_v.o: variables.o
buffer_density.o: variables.o
checkpoint.o: variables.o
cubefft.o: variables.o
kernel_f.o: variables.o
kernel_c.o: variables.o
particle_initialization.o: variables.o
timestep.o: variables.o
update_particle.o: variables.o
projection.o: variables.o

initialize.o: variables.o cubefft.o pencil_fft.o redshifts.txt
finalize.o: variables.o cubefft.o pencil_fft.o
cafcube.o: variables.o cubefft.o pencil_fft.o
pm.o: variables.o cubefft.o pencil_fft.o
acceleration_field.o: variables.o cubefft.o pencil_fft.o

cafcube.o: parameters.o variables.o initialize.o cubefft.o pencil_fft.o kernel_f.o kernel_c.o timestep.o particle_initialization.o buffer_density.o buffer_x.o buffer_v.o pm.o update_particle.o checkpoint.o projection.o finalize.o # acceleration_field.o

acc_field.o: parameters.o variables.o initialize.o cubefft.o pencil_fft.o particle_initialization.o buffer_density.o buffer_x.o pm_acceleration.o finalize.o kernel_c.o kernel_f.o

%.o: %.f90 Makefile
	$(FC) $(OFLAG) $(OPTIONS) $< -o $@ $(FFTFLAG)

clean:
	rm -f *.mod *.o *.out *.x *~
