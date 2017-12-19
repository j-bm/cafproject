program initial_conditions_nu
  use parameters
  implicit none

  !Fermi-Dirac CDF
  integer, parameter :: ncdf = 10000
  real, dimension(2,ncdf) :: cdf

  !Units
  real, parameter :: vp2s = 1.0/(300.*sqrt(omega_m)*box/a_i_nu/2./nc)
  real, parameter :: fdf = 25.8341 !kT/m for T=1K, m=1eV
  real, parameter :: fd = vp2s*fdf*maxval(Tnu/Mnu)/a_i_nu !kBcTnu/mass with temp in K and mass in eV
  real, parameter :: sigma_v = 3.59714*fd !fd velocity dispersion (45/3 * Zeta(5)/Zeta(3))**0.5

  !Seed
  integer(4) seedsize
  integer(4), allocatable :: iseed(:)
  real, allocatable :: rseed_all(:,:)

  !Useful variables and small arrays
  integer :: i,j,k,p,n,pii,pjj,pkk,b,b1,b2

  !Particle information
  integer, parameter :: npt = np_nc_nu*nc
  integer(izipx), dimension(3,npt**3) ::  xp
  integer(izipv), dimension(3,npt**3) :: vp
  integer(izipi), dimension(npt**3) :: ip
  real, dimension(3) :: xq,vq,rng

  integer(4), dimension(nt,nt,nt) :: rhoc
  real(4), dimension(3,nt,nt,nt) :: vfield

  !Setup
  call geometry
  if (head) then
     write(*,*) ''
     write(*,*) 'Homogeneous Initial Conditions for Massive Neutrinos'
     write(*,*) ''
     write(*,*) 'vp2s/(km/s)=',vp2s
     write(*,*) 'fd/(km/s)=',fd/vp2s
  end if

  !Read seed
  if (head) write(*,*) 'Reading seeds'
  call random_seed(size=seedsize)
  seedsize=max(seedsize,12)
  allocate(iseed(seedsize))
  allocate(rseed_all(seedsize,nn**3))
  open(11,file=output_dir()//'seed'//output_suffix(),status='old',access='stream')
  read(11) iseed
  close(11)
  call random_seed(put=iseed)

!!$  !Read cdf table
!!$  if (head) write(*,*) 'Reading cdf'
!!$  open(11,file='./CDFTable.txt')
!!$  read(11,*) cdf
!!$  close(11)
!!$  cdf(1,:) = cdf(1,:)*fd

  if (head) write(*,*) 'Generating cdf'
  call compute_cdf
  if (head) then
     write(*,*) 'Writing CDF to file'
     write(*,*) 'FD factor used: ',fd
     open(11,file='./cdf.txt')
     do i=1,ncdf
        write(11,*) cdf(1,i)/fd,cdf(2,i)
     end do
     close(11)
  end if

  !Create particles
  if (head) write(*,*) 'Computing particle positions and velocities'
  open(unit=10,file=ic_name('xp_nu'),status='replace',access='stream')
  open(unit=11,file=ic_name('vp_nu'),status='replace',access='stream')
  open(unit=12,file=ic_name('np_nu'),status='replace',access='stream')
  open(unit=13,file=ic_name('vc_nu'),status='replace',access='stream')
  open(unit=14,file=ic_name('id_nu'),status='replace',access='stream')
  vfield=0
  rhoc=np_nc_nu**3
  do k=1,nnt
     do j=1,nnt
        do i=1,nnt

           !Compute Lagrangian positions and Thermal velocities
           do pkk=1,npt
              do pjj=1,npt
                 do pii=1,npt

                    p=pii+npt*(pjj-1)+npt**2*(pkk-1)

                    !Positions stored in xq
                    xq=(/pii,pjj,pkk/)-0.5
                    xp(:,p)=floor( xq/x_resolution,kind=izipx )

                    !Random velocities
                    call random_number(rng)

                    !Bisection interpolate CDF
                    !Type out fns here to save time in case compiler does not inline
                    b1=1
                    b2=ncdf
                    do while(b2-b1>1)
                      b=(b1+b2)/2
                      if ( rng(1).gt.cdf(2,b) ) then
                         b1=b
                      else
                         b2=b
                      end if
                    end do
                    n=merge(b1,b2,b1<b2)
                    rng(1)=(cdf(1,n)*(cdf(2,n+1)-rng(1))+cdf(1,n+1)*(rng(1)-cdf(2,n)))/(cdf(2,n+1)-cdf(2,n))

                    !!Store fraction of max velocity
                    !!Fermi-Dirac CDF Approximated by Gaussian
                    ip(p)=nint(approxCDF(rng(1))*int(2,8)**(8*izipi)-int(2,8)**(8*izipi-1),kind=izipi)

                    !!Amplitude and Angle
                    rng(1)=rng(1)!*fd !!Holds velocity amplitude
                    rng(2)=2.*rng(2)-1. !cosTheta in (-1,1)
                    rng(3)=rng(3)*2.*pi !Phi in 0 to 2*pi
                    !!Direction
                    vq(1)=rng(1)*sqrt(1.-rng(2)**2.)*cos(rng(3))
                    vq(2)=rng(1)*sqrt(1.-rng(2)**2.)*sin(rng(3))
                    vq(3)=rng(1)*rng(2)

                    vp(:,p)=nint(real(nvbin-1)*atan(sqrt(pi/2)/(sigma_v*vrel_boost)*vq)/pi,kind=izipv)

                 end do
              end do
           end do

           write(10) xp
           write(11) vp
           write(12) rhoc
           write(13) ip
           write(14) vfield

        end do
     end do
  end do

  close(10)
  close(11)
  close(12)
  close(13)
  close(14)

  if (head) write(*,*) 'Finished neutrino ic'

contains

  function approxCDF(v) result(c)
    implicit none
    real, intent(in) :: v
    real :: c
    real, parameter :: s=3.5
    c=1.-exp(-(v/s)**2.)
  end function approxCDF

  function invertCDF(c) result(v)
    implicit none
    real, intent(in) :: c
    real :: v
    real, parameter :: s=3.5
    v=s*sqrt(log(1./(1.-c)))
  end function invertCDF

  subroutine compute_cdf
    implicit none
    real(8), dimension(2,ncdf) :: cdf0
    real, dimension(2,ncdf) :: cdfn
    integer, parameter :: ni = 1000 !How many points to integrate per cdf
    real, dimension(ni) :: x,y
    real, parameter :: maxu = 15.0
    real, parameter :: cdfinf = 1.80309
    integer :: i,j,n
    real :: l,u,fnu,fdnu

    cdf0 = 0.
    do i=2,ncdf

       !Limits of integration
       l=maxu*(1.0*i-1.)/ncdf
       u=maxu*(1.0*i)/ncdf
       cdf0(1,i)=u

       !Integral
       do j=1,ni
          x(j)=l+(j-1)*(u-l)/(ni-1)
          y(j)=f0(x(j))
       end do
       cdf0(2,i)=cdf0(2,i-1)+integrate(x,y)

    end do

    write(*,*) 'cdf: u->inf = ',cdf0(2,ncdf),cdfinf
    cdf0(2,:) = cdf0(2,:)/cdf0(2,ncdf)

    !Now sum up for each neutrino
    cdf=0
    cdf(1,:)=fd*cdf0(1,:)
    cdfn(2,:)=cdf0(2,:)
    do n=1,Nnu
       fnu=Mnu(n)*(Tnu(n)/Tcnb)**3/Meff ! fraction of energy in this neutrino
       fdnu=vp2s*fdf*Tnu(n)/Mnu(n)/a_i_nu
       cdfn(1,:)=cdf0(1,:)*fdnu
       do i=1,ncdf
          j=nearest_loc(cdf(1,i),cdfn(1,:))
          cdf(2,i) = cdf(2,i)+fnu*interp(cdf(1,i),cdfn(1,j),cdfn(1,j+1),cdfn(2,j),cdfn(2,j+1))
       end do
    end do

    return

  end subroutine compute_cdf

  function f0(u) result(f)
    implicit none
    real, intent(in) :: u
    real :: f
    f= u**2./(exp(u)+1.)
  end function f0

  function integrate(x,y) result(s)
    implicit none
    real, dimension(:), intent(in) :: x,y
    real :: s
    integer :: i
    s=0
    do i=2,size(x)
       s=s+0.5*(x(i)-x(i-1))*(y(i)+y(i-1))
    end do
  end function integrate

  function nearest_loc(u,c) result(nl)
    implicit none
    real, intent(in) :: u
    real, dimension(:) :: c
    integer :: b1,b2,b,nl
    b1=1
    b2=size(c)
    do while(b2-b1>1)
       b=(b1+b2)/2
       if ( u.gt.c(b) ) then
          b1=b
       else
          b2=b
       end if
    end do
    nl=merge(b1,b2,b1<b2)
  end function nearest_loc

  function interp(x,x1,x2,y1,y2) result(y)
    implicit none
    real, intent(in) :: x,x1,x2,y1,y2
    real :: y
    y = (y1*(x2-x)+y2*(x-x1))/(x2-x1)
  end function interp

end program initial_conditions_nu
