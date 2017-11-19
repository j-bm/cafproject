!#define zipconvert
module variables
use parameters
implicit none
save

! parameters
integer,parameter :: npnode=nf**3
real,parameter :: density_buffer=1.1
integer,parameter :: npmax=npnode*(nte*1./nt)**3*density_buffer
integer,parameter ::  nseedmax=200
real,parameter :: vbuf=0.9
real,parameter :: dt_max=1
real,parameter :: dt_scale=1
integer(8),parameter :: unit8=1
integer,parameter :: NULL=0
real,parameter :: pi=3.141592654
real,parameter :: GG=1.0/6.0/pi

! checkpoint variables
integer,parameter :: nmax_redshift=100
integer cur_checkpoint[*], n_checkpoint[*]
real z_checkpoint(nmax_redshift)[*]
logical checkpoint_step[*], final_step[*]

! variables
integer its[*]
real dt[*],dt_old[*],dt_mid[*]
real dt_fine(nn**3),dt_pp(nn**3),dt_coarse(nn**3),dt_vmax(nn**3)
real a[*],da[*],a_mid[*],tau[*],t[*] ! time step
real f2_max_fine(nnt,nnt,nnt)[*],f2_max_pp(nnt,nnt,nnt)[*],f2_max_coarse[*]

integer iseed(nseedmax), iseedsize
integer itx,ity,itz,ix,iy,iz,i_dim
integer i,j,k,l,ip,ipp,pp
!integer nplocal[*], nptile(nnt,nnt,nnt)
!integer(8) nptotal, npcheck

!real mass_p

! FFT plans
integer(8) plan_fft_fine,plan_ifft_fine
integer(8) planx,plany,planz,iplanx,iplany,iplanz

real v_i2r(3)[*],v_i2r_new(3)[*]
real vmax(3)[*],vmax_new(3)[*]
! n^3
!#ifdef zipconvert
!  integer(1) xic_new(3,npmax)
!  integer(2) vic_new(3,npmax)
!#endif
!integer(izipx) x(3,npmax)[*], x_new(3,npmax/nnt**3)
!integer(izipv) v(3,npmax)[*], v_new(3,npmax/nnt**3)
!#ifdef PID
!  integer(2) pid(4,npmax)[*], pid_new(4,npmax/nnt**3)
!#endif
!integer(1) rhoc_i1(nt,nt,nt,nnt,nnt,nnt)
!integer(4) rhoc_i4(nc**2)

!real rho_f(nfe+2,nfe,nfe,ncore)
!real crho_f(nfe+2,nfe,nfe,ncore)
!real kern_f(3,nfe/2+1,nfe,nfe)
!real force_f(3,nfb:nfe-nfb+1,nfb:nfe-nfb+1,nfb:nfe-nfb+1,ncore)
!integer rhoce1d(nce**3), rhoequiv(nce,nce,nce) ! rhoce is a coarray
!equivalence(rhoequiv,rhoce1d)

! rho in physical tiles and 6 buffers of tiles
! n^3
!integer rhotile(nt,nt,nt,nnt,nnt,nnt)[*]
!integer rhoc(1-ncb:nt+ncb,1-ncb:nt+ncb,1-ncb:nt+ncb,nnt,nnt,nnt)[*]
!integer cum(1-ncb:nt+ncb,1-ncb:nt+ncb,1-ncb:nt+ncb,nnt,nnt,nnt)[*]

! coarse fft arrays
real r3(nc,nc,nc)[*]
real rxlong(nc*nn+2,nc,npen)[*]
complex cx(nc*nn/2+1,nc,npen)[*]
real crho_c(nc*nn+2,nc,npen)
complex cy(npen,nn,nn,nc/2+1,npen)[*]
complex cz(npen,nn,nn,nc/2+1,npen)[*]
complex cyxz(npen*nn,npen*nn/2+1,npen)
complex cyyxz(npen,nn,npen*nn/2+1,npen)
equivalence(cyxz,cyyxz)


! coarse kernel arrays
!real ck(3,nc,nc,nc)
!real kern_c(3,nc*nn/2,nc,npen+2)
!real kern_c(3,nc*nn/2+1,nc,npen)
!real tmp_kern_c(3,nc*nn,nc,npen+2)
!real tmp_kern_c(3,nc*nn+2,nc,npen)

!real force_c(3,0:nc+1,0:nc+1,0:nc+1)[*]


! n^2
!integer,dimension(ncb,nt,nt,nnt,nnt,nnt) :: rhotilex1[*],rhotilex2[*]
!integer,dimension(1-ncb:nt+ncb,ncb,nt,nnt,nnt,nnt) :: rhotiley1[*],rhotiley2[*]
!integer,dimension(1-ncb:nt+ncb,1-ncb:nt+ncb,ncb,nnt,nnt,nnt) :: rhotilez1,rhotilez2

character (10) :: img_s, z_s
character (200) :: fn0,fn1,fn2,fn3,fn4

!equivalence(rhoce,rhoce1d)

endmodule
