! read qspace fields and compute the divergence
! compute B mode
! compute the c.c. w.r.t. delta_L
program correlation_qspace
  use pencil_fft
  use powerspectrum
  implicit none
  save

  logical,parameter :: correlate_phi=.false.
  integer i
  real cube3(3,ng,ng,ng),cube(ng,ng,ng),delta_L(ng,ng,ng)
  real xi(10,nbin)[*]

  call geometry

  print*, 'checkpoint at:'
  open(16,file='../main/redshifts.txt',status='old')
  do i=1,nmax_redshift
    read(16,end=71,fmt='(f8.4)') z_checkpoint(i)
    print*, z_checkpoint(i)
  enddo
  71 n_checkpoint=i-1
  close(16)
  print*,''

  call create_penfft_plan
  print*, 'ng=',ng

  do cur_checkpoint= 1,n_checkpoint

    print*,output_name('dsp')

    open(10,file=output_dir()//'delta_L'//output_suffix(),status='old',access='stream')
      read(10) delta_L
    close(10)


    ! displacement
    cube3=0;cube=0
    open(10,file=output_name('dsp'),status='old',access='stream')
      read(10) cube3(1,:,:,:)
      read(10) cube3(2,:,:,:)
      read(10) cube3(3,:,:,:)
    close(10)
    call get_divergence(cube3,cube)
    open(10,file=output_name('dspE'),status='replace',access='stream')
      write(10) cube
    close(10)
    call cross_power(xi,cube,delta_L)
    if (head) then
      open(10,file=output_name('cicpower_dspE'),status='replace',access='stream')
      write(10) xi
      close(10)
      print*,'wrote',output_name('cicpower_dspE')
    endif
    sync all

    delta_L=cube     ! cross correlate with dsp


    ! velocity
    cube3=0;cube=0
    open(10,file=output_name('vel'),status='old',access='stream')
      read(10) cube3(1,:,:,:)
      read(10) cube3(2,:,:,:)
      read(10) cube3(3,:,:,:)
    close(10)
    call get_divergence(cube3,cube)
    open(10,file=output_name('velE'),status='replace',access='stream')
      write(10) cube
    close(10)
    call cross_power(xi,cube,delta_L)
    if (head) then
      open(10,file=output_name('cicpower_velE'),status='replace',access='stream')
      write(10) xi
      close(10)
      print*,'wrote',output_name('cicpower_velE')
    endif
    sync all


    ! acceleration
    cube3=0;cube=0
    open(10,file=output_name('acc'),status='old',access='stream')
      read(10) cube3(1,:,:,:)
      read(10) cube3(2,:,:,:)
      read(10) cube3(3,:,:,:)
    close(10)
    call get_divergence(cube3,cube)
    open(10,file=output_name('accE'),status='replace',access='stream')
      write(10) cube
    close(10)

    call cross_power(xi,cube,delta_L)
    if (head) then
      open(10,file=output_name('cicpower_accE'),status='replace',access='stream')
      write(10) xi
      close(10)
      print*,'wrote',output_name('cicpower_accE')
    endif
    sync all

    if (correlate_phi) then ! cross correlate potential with 1LPT potential
      print*, output_dir()//'49.000phi1'//output_suffix()
      open(10,file=output_dir()//'49.000phi1'//output_suffix(),status='old',access='stream')
        read(10) delta_L
      close(10)
      print*, output_name('phiq')
      open(10,file=output_name('phiq'),status='old',access='stream')
        read(10) cube
      close(10)
      call cross_power(xi,cube,delta_L)
      if (head) then
        open(10,file=output_name('cicpower_phiq'),status='replace',access='stream')
        write(10) xi
        close(10)
      endif
      open(10,file=output_name('phi1'),status='old',access='stream')
        read(10) cube
      close(10)
      call cross_power(xi,cube,delta_L)
      if (head) then
        open(10,file=output_name('cicpower_phi'),status='replace',access='stream')
        write(10) xi
        close(10)
      endif
    endif

  enddo
  call destroy_penfft_plan

contains

  subroutine get_divergence(vecfield,div)

    integer i_dim,dim_1,dim_2,dim_3
    integer i,j,k,kg,jg,ig
    real kx(3),kr
    real vecfield(3,ng,ng,ng),div(ng,ng,ng)
    complex cdiv(ng*nn/2+1,ng,npen)
    complex pdim, ekx(3)

    r3=0
    cdiv=0
    do i_dim=1,3
      r3=vecfield(i_dim,:,:,:)
      call pencil_fft_forward
      do k=1,npen
      do j=1,ng
      do i=1,ng*nn/2+1
        kg=(nn*(icz-1)+icy-1)*npen+k
        jg=(icx-1)*ng+j
        ig=i
        kx=mod((/ig,jg,kg/)+ng/2-1,ng)-ng/2
        kr=sqrt(kx(1)**2+kx(2)**2+kx(3)**2)
        ekx=exp(2*pi*(0,1)*kx/ng)
        dim_1=i_dim
        dim_2=mod(dim_1,3)+1
        dim_3=mod(dim_2,3)+1
        pdim=(ekx(dim_1)-1)*(ekx(dim_2)+1)*(ekx(dim_3)+1)/4
        cdiv(i,j,k)=cdiv(i,j,k)+cxyz(i,j,k)*pdim
      enddo
      enddo
      enddo
    enddo ! i_dim
    if (head) then
      cdiv(1,1,1)=0
    endif
    sync all
    cxyz=cdiv
    call pencil_fft_backward
    div=-r3

  endsubroutine

end
