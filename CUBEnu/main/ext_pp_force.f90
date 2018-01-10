module extended_pp_force
  use variables
  !use neutrinos
  implicit none
  save

  integer(8),parameter :: np_pp_max=np_image/nnt**3*(1+2./nt)**3*tile_buffer
  integer hoc(1-ncell:nft+ncell,1-ncell:nft+ncell,1-ncell:nft+ncell)
  integer ll(np_pp_max)
  integer(8) npairs,itest1
  real(8) xvec1(3),xvec2(3),xvec21(3),rmag,force_pp(3),rcut,pcut,f_tot(3)
  integer(4) ivec1(3),nlast,nlast1,nlast2,np,ii,jj,kk,np1,np2,l1,l2
  integer igx,igy,igz,lp,ip1,ip2
contains

subroutine ext_pp_force
  use variables
  !use neutrinos
  implicit none
  save


  if (head) then
    print*, ''
    print*, 'ext_pp_force'
    print*, '  ext_pp_force over',nnt**3,'tiles'
    print*, '  np_pp_max=',np_pp_max
  endif
  itest1=0
  f2_max_pp(1:nnt,1:nnt,1:nnt)=0
  print*, '  nplocal =',sum(rhoc(1:nt,1:nt,1:nt,:,:,:))
  do itz=1,nnt
  do ity=1,nnt
  do itx=1,nnt
    !print*, '  cum_nu',itx,ity,itz,cum_nu(-5,-5,-5,1,1,1)
    ! [1] make linked list
    if (np_pp_max<sum(rhoc(0:nt+1,0:nt+1,0:nt+1,itx,ity,itz))) then
      print*, 'np_pp_max too small'
      print*, np_pp_max, sum(rhoc(0:nt+1,0:nt+1,0:nt+1,itx,ity,itz))
      stop
    endif

    hoc(:,:,:)=0
    ll=0
    do igz=0,nt+1
    do igy=0,nt+1
    do igx=0,nt+1
      nlast=cum(igx-1,igy,igz,itx,ity,itz)
      np=rhoc(igx,igy,igz,itx,ity,itz)
      do lp=1,np ! loop over cdm particles
        ip1=nlast+lp
        xvec1=ncell*((/igx,igy,igz/)-1)+ncell*(int(xp(:,ip1)+ishift,izipx)+rshift)*x_resolution
        ivec1=floor(xvec1)+1
        ll(ip1)=hoc(ivec1(1),ivec1(2),ivec1(3))
        hoc(ivec1(1),ivec1(2),ivec1(3))=ip1
      enddo
    enddo
    enddo
    enddo

    do igz=1,nft
    do igy=1,nft
    do igx=1,nft
      ip1=hoc(igx,igy,igz)
      do while (ip1/=0)
        itest1=itest1+1
#ifdef NODEBUG
        xvec1=ncell*(((/i,j,k/)-1)/4)+ncell*(int(xp(:,ip1)+ishift,izipx)+rshift)*x_resolution
        vreal=tan(pi*real(vp(:,ip1))/real(nvbin-1))/(sqrt(pi/2)/(sigma_vi*vrel_boost))
        !ivec1=floor(xvec1)+1
        !ivec1=(/i,j,k/)
        ! loop over nearby cells and particles
        npairs=0
        f_tot=0
        !print*, i,j,k
        !print*, xp(:,ip1)
        !print*, xvec1

        ! CHOICE 1 (use linked list)
        do kk=k-pp_range,k+pp_range
        do jj=j-pp_range,j+pp_range
        do ii=i-pp_range,i+pp_range
          ip2=hoc(ii,jj,kk)
          do while (ip2/=0) ! loop over particle 2

        ! CHOICE 2 (use coarse grid)
        !do kk=k-1,k+1
        !do jj=j-1,j+1
        !do ii=i-1,i+1
        !  nlast2=cum(ii-1,jj,kk,itx,ity,itz)
        !  np2=rhoc(ii,jj,kk,itx,ity,itz)
        !  do l2=1,np2
        !    ip2=nlast2+l2

            !npairs=npairs+1
            xvec2=ncell*floor(((/ii,jj,kk/)-1)/4.)+ncell*(int(xp(:,ip2)+ishift,izipx)+rshift)*x_resolution
            xvec21=xvec2-xvec1
            rmag=sqrt(sum(xvec21**2))
            rmag=merge(1d0,rmag,rmag==0)
            rcut=rmag/nf_cutoff
            pcut=1-(7./4*rcut**3)+(3./4*rcut**5)
            force_pp=mass_p*(xvec21/rmag**3)*pcut
            force_pp=merge(force_pp,force_pp*0,rmag>rsoft)
            f_tot=f_tot+force_pp
            !print*, ii,jj,kk
            !print*, xp(:,ip2)
            !print*, xvec2
            !stop
            ip2=ll(ip2)

          enddo !! do while (ip2/=0)
        enddo !! kk
        enddo !! jj
        enddo !! ii
        vreal=vreal+f_tot*a_mid*dt/6/pi
        vp(:,ip1)=nint(real(nvbin-1)*atan(sqrt(pi/2)/(sigma_vi*vrel_boost)*vreal)/pi,kind=izipv)
        f2_max_pp(itx,ity,itz)=max(f2_max_pp(itx,ity,itz),sum(f_tot**2))
#endif
        ip1=ll(ip1)
        !print*,npairs
      enddo !! do while (ip1/=0)
    enddo !! i
    enddo !! j
    enddo !! k
  enddo
  enddo
  enddo !! itz
  !print*, '  cum_nu',cum_nu(-5,-5,-5,1,1,1)


  print*,'  updated',itest1,'particles'
  if (itest1/=nplocal) then
    print*, 'itest1/=nplocal'
    print*, itest1,nplocal
    stop
  endif

  print*, '  max of f_pp', sqrt(maxval(f2_max_pp))
  dt_pp=sqrt(0.05*rsoft) / max(sqrt(maxval(f2_max_pp))*a_mid*GG,1e-3)
  ! for reference:
  !dt_fine=sqrt( 1.0 / (sqrt(maxval(f2_max_fine))*a_mid*GG) )
  !dt_coarse=sqrt( real(ncell) / (sqrt(f2_max_coarse)*a_mid*GG) )
  sync all

endsubroutine






endmodule
