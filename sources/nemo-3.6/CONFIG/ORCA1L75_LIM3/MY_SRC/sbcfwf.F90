MODULE sbcfwf
   !!======================================================================
   !!                       ***  MODULE  sbcfwf  ***
   !! ocean forcing : add. freshwater forcing  
   !!======================================================================
   !! History :         2022-05 A. Jueling
   !!======================================================================

   USE dom_oce         ! ocean space and time domain
   USE sbc_oce         ! Surface boundary condition: ocean fields
   USE sbc_ice         ! Surface boundary condition: ice fields
   use oce
   USE phycst          ! physical constants
   USE iom             ! I/O module
   USE fldread         ! read input fields
   USE wrk_nemo        ! work arrays
   USE in_out_manager  ! I/O manager
   USE iom             ! I/O module

   IMPLICIT NONE
   PRIVATE

   PUBLIC   sbc_fwf_init, sbc_fwf, sbc_fwf_bm, sbc_fwf_output ! routines called by sbcmod.F90

   INTEGER                                   ::   ierror
   INTEGER                                   ::   ios
   ! Local integer output status for namelist read

   CHARACTER(len=100)                        ::   cn_dir_f     
   ! Root directory for location of fwf files

   INTEGER, PARAMETER                        ::   jpr_cal = 29 ! calving
   INTEGER, PARAMETER                        ::   jprcv   =  1
   ! total number of fields received, originally jprcv = 44 defined in sbccpl.F90

   TYPE ::   DYNARR     
      REAL(wp), POINTER, DIMENSION(:,:,:)    ::   z3   
   END TYPE DYNARR

   TYPE( DYNARR ), SAVE, DIMENSION(jprcv)    ::   frcv 
   ! all fields recieved from the atmosphere

   TYPE(FLD_N)       , PUBLIC                ::   sn_rnf_f   
   !: information about the additionnal forced river runoff file to be read
   TYPE(FLD_N)       , PUBLIC                ::   sn_cal_f 
   !: information about the additionnal forced calving file to be read
   TYPE(FLD_N)       , PUBLIC                ::   sn_zshelf 
   !: information about the basal melt depth file to be read
   TYPE(FLD_N)       , PUBLIC                ::   sn_zdraft
   !: information about the basal melt depth file to be read

   TYPE(FLD), ALLOCATABLE, DIMENSION(:)      ::   sf_rnf_f
   ! structure: additional forced runoff  (file information, fields read)
   TYPE(FLD), ALLOCATABLE, DIMENSION(:)      ::   sf_cal_f
   ! structure: additional forced calving (file information, fields read)
   REAL(wp), ALLOCATABLE, SAVE, DIMENSION(:,:)   ::  sf_zshelf
   ! structure: basal melt depth (file information, fields read)
   REAL(wp), ALLOCATABLE, SAVE, DIMENSION(:,:)   ::  sf_zdraft
   ! structure: basal melt depth (file information, fields read)


CONTAINS

   SUBROUTINE sbc_fwf_init
      !!----------------------------------------------------------------------
      !!                  ***  ROUTINE sbc_fwf_init  ***
      !! (like `sbc_rnf_init` in sbcrnf.F90)
      !!
      !! ** Purpose :   Initialisation of add. runoff+calving if (ln_fwf=T)
      !!
      !! ** Method  : - read the runoff namsbc_fwf namelist
      !!
      !! ** Action  : - read parameters
      !!----------------------------------------------------------------------
 
      integer :: inum
      NAMELIST/namsbc_fwf/  cn_dir_f, sn_rnf_f, sn_cal_f, sn_zshelf, sn_zdraft

      REWIND( numnam_cfg )              ! Namelist namsbc_fwf in configuration namelist: Freshwater Forcing
      READ  ( numnam_cfg, namsbc_fwf, IOSTAT = ios, ERR = 901 )
901   IF( ios /= 0 ) CALL ctl_nam ( ios , 'namsbc_fwf in configuration namelist', lwp )

      ALLOCATE( sf_rnf_f(1), STAT=ierror )         ! Create sf_rnf_f structure (runoff inflow)
      IF(lwp) WRITE(numout,*)
      IF(lwp) WRITE(numout,*) '          forced runoffs runoff read in a file'
      IF( ierror > 0 ) THEN
         CALL ctl_stop( 'sbc_rnf_f: unable to allocate sf_rnf_f structure' )  ; RETURN
      ENDIF
      ALLOCATE( sf_rnf_f(1)%fnow(jpi,jpj,1)   )
      IF( sn_rnf_f%ln_tint ) ALLOCATE( sf_rnf_f(1)%fdta(jpi,jpj,1,2) )
      CALL fld_fill( sf_rnf_f, (/ sn_rnf_f /), cn_dir_f, 'sbc_rnf_init_f', 'read runoffs data', 'namsbc_fwf' )

      ALLOCATE( sf_cal_f(1), STAT=ierror )         ! Create sf_cal_f structure (calving inflow)
      IF(lwp) WRITE(numout,*)
      IF(lwp) WRITE(numout,*) '          forced runoffs calving read in a file'
      IF( ierror > 0 ) THEN
         CALL ctl_stop( 'sbc_cal_f: unable to allocate sf_cal_f structure' )  ; RETURN
      ENDIF
      ALLOCATE( sf_cal_f(1)%fnow(jpi,jpj,1)   )
      IF( sn_cal_f%ln_tint ) ALLOCATE( sf_cal_f(1)%fdta(jpi,jpj,1,2) )
      CALL fld_fill( sf_cal_f, (/ sn_cal_f /), cn_dir_f, 'sbc_cal_init_f', 'read runoffs data', 'namsbc_fwf' )

      ALLOCATE( sf_zshelf(jpi,jpj))
      IF(lwp) WRITE(numout,*)
      IF(lwp) WRITE(numout,*) '          basal melt distribution bottom depth (depth 2) read in a file'
      IF( ierror > 0 ) THEN
         CALL ctl_stop( 'sbc_zshelf: unable to allocate sf_zshelf structure' )  ; RETURN
      ENDIF
      CALL iom_open ( trim(sn_zshelf%clname), inum )                           ! open file
      CALL iom_get  ( inum, jpdom_data, sn_zshelf%clvar,  sf_zshelf)   ! read the zshelf array
      CALL iom_close( inum )                                        ! close file

      ALLOCATE( sf_zdraft(jpi,jpj))
      IF(lwp) WRITE(numout,*)
      IF(lwp) WRITE(numout,*) '          basal melt distribution top depth (depth 1) read in a file'
      IF( ierror > 0 ) THEN
         CALL ctl_stop( 'sbc_zdraft: unable to allocate sf_zdraft structure' )  ; RETURN
      ENDIF
      CALL iom_open ( trim(sn_zdraft%clname), inum )                           ! open file
      CALL iom_get  ( inum, jpdom_data, sn_zdraft%clvar,  sf_zdraft)   ! read the zdraft array
      CALL iom_close( inum )                                        ! close file


   END SUBROUTINE sbc_fwf_init

   SUBROUTINE sbc_fwf_bm( kt )
      !!---------------------------------------------------------------------
      !!                    ***  ROUTINE sbc_fwf_bm ***
      !!
      !! ** Purpose : distribute freshwater and latent heat fluxes from basal melt uniformly
      !!              between zdraft (bottom of ice shelf front) to zshelf (grounding line/seabed depth)
      !!              and account for associated sea surface height changes
      !!
      !! ** Method  : read zshelf, zdraft and sf_rnf_f fields from netcdf
      !!
      !! ** Action  : update `tsn` and`sshn` at each time step
      !!----------------------------------------------------------------------   
      
      INTEGER                              , INTENT(in   ) ::   kt          ! ocean time-step index
      INTEGER  ::  ji, jj, jk                ! dummy loop indices

      REAL(wp), PARAMETER  ::  temp_bm=0.    ! temp of basal melt (in deg C)

      REAL(wp), POINTER, DIMENSION(:,:) ::  zthick, zdelta
      !
      CALL wrk_alloc( jpi, jpj, zthick, zdelta )

      ! Thickness of layer where freshwater is added
      zthick(:,:) = sf_zshelf(:,:) - sf_zdraft(:,:)
      
      ! Computations assuming kg m-2 s-1 as input for sf_rnf_f
      ! Thickness (in m) of freshwater
      zdelta(:,:) = sf_rnf_f(1)%fnow(:,:,1) * 1.e-3 * rdt
      
      !!! add freshwater layer to SSH
      !!!sshn(:,:) = sshn(:,:) + zdelta(:,:)
      ! add freshwater mass from basal melt to E-P
      emp(:,:) = emp(:,:) - sf_rnf_f(1)%fnow(:,:,1)
      ! compensate freshening of top level because
      ! salinity effects are added below at depth (like temp)
      tsn(:,:,1,jp_sal) = tsn(:,:,1,jp_sal) * &
      & e3t_n(:,:,1) / ( e3t_n(:,:,1)-zdelta(:,:) )
      
      ! distribute freshwater impact on temperature and salinity evenly from
      ! zdraft to zshelf
      do jk = 1, jpk
         where ( gdept_n(:,:,jk)>sf_zdraft(:,:) .and. gdept_n(:,:,jk)<sf_zshelf(:,:) )
            ! heat for generating basal melt
             tsn(:,:,jk,jp_tem) = tsn(:,:,jk,jp_tem) - lfus / 4184.0 * &
             & zdelta(:,:) / zthick(:,:)
             ! salinity change from mixing BM from zdraft to zshelf
             ! comment following block if salinity isn't corrected in top layer
             !!!tsn(:,:,jk,jp_sal) = tsn(:,:,jk,jp_sal) * zthick(:,:) &
             !!!&/( zthick(:,:) + zdelta(:,:) )
         endwhere
                        
         ! temperature and salinity change from mixing BM from surface to
         ! zshelf
         where ( gdept_n(:,:,jk)<sf_zshelf(:,:) )
             tsn(:,:,jk,jp_tem) = tsn(:,:,jk,jp_tem) &
             & + (temp_bm-tsn(:,:,jk,jp_tem)) / (sf_zshelf(:,:)/zdelta(:,:)+1.)
             ! comment following block if salinity isn't corrected in top layer
             tsn(:,:,jk,jp_sal) = tsn(:,:,jk,jp_sal) * sf_zshelf(:,:) &
             & / ( sf_zshelf(:,:) + zdelta(:,:) )
         endwhere
      enddo

      ! add basal melt to calving in the output (assuming it's all ice
      ! that cools the ocean when melting)
      calv(:,:) = calv(:,:) + sf_rnf_f(1)%fnow(:,:,1)
      CALL wrk_dealloc( jpi, jpj, zthick, zdelta )
      !
   END SUBROUTINE sbc_fwf_bm

   

   SUBROUTINE sbc_fwf ( kt )
      !!---------------------------------------------------------------------
      !!                    ***  ROUTINE sbc_init ***
      !!
      !! ** Purpose : add freshwater forcing on top of coupled fluxes
      !!
      !! ** Method  : read emp/qns fields from netcdf
      !!
      !! ** Action  : update `rnf`,`emp` and `qns`
      !!              at each time step with addtional freshwater forcing
      !!----------------------------------------------------------------------   
      INTEGER, INTENT(in) ::   kt   ! ocean time step

      REAL(wp), POINTER, DIMENSION(:,:) ::  zemp_cal

      ! allocate
      CALL wrk_alloc( jpi,jpj, zemp_cal)
      ! rnf, emp_tot, qns_tot  defined in sbc_oce.F90
      ! emp_oce                defined in sbc_ice.F90
      ! Note: emp here is emp_oce, qns is qns_oce (Klaus Wyser, SMHI)

      ! forcing:   read additional forcing files
      CALL fld_read ( kt, nn_fsbc, sf_rnf_f )  ! Read forced Runoffs data and provide it at kt
      CALL fld_read ( kt, nn_fsbc, sf_cal_f )  ! Read forced Runoffs calving data and provide it at kt

      ! Do NOT add freshwater fluxes from runoff, since we correct with sbc_fwf_bm
      !rnf(:,:)      = rnf(:,:)      + sf_rnf_f(1)%fnow(:,:,1)
      !WRITE(numout,*) 'forced runoffs.nc sorunoff_f  field added to `rnf` runoff flux'
      
      ! add freshwater fluxes from calving to both ocean and total
      ! the so_calving_f field is defined as positive for fluxes into the ocean,
      ! so the upward calving flux is negative (and compatible with emp)
      zemp_cal(:,:) = - sf_cal_f(1)%fnow(:,:,1)
      emp(:,:) = emp(:,:) + zemp_cal(:,:)

      ! WRITE(numout,*) 'forced runoffs.nc socalving_f fields added to `emp_tot` and `emp_oce` freshwater fluxes'
      
      ! add heat flux from calving
      ! melting should result in negative heat flux
      qns(:,:) = qns(:,:) + zemp_cal(:,:) * lfus  ! assumes icebergs to be at melting point temperature
      ! WRITE(numout,*) 'forced runoffs.nc socalving_f fields added to `qns_tot` heat flux'

      ! add so_calving to calving from sbccpl
      calv(:,:) = calv(:,:) + sf_cal_f(1)%fnow(:,:,1)
      
      ! deallocate
      CALL wrk_dealloc( jpi,jpj, zemp_cal )

   END SUBROUTINE sbc_fwf
   

   SUBROUTINE sbc_fwf_output

      REAL(wp), POINTER, DIMENSION(:,:) ::  zcptn

      ! allocate
      CALL wrk_alloc( jpi,jpj, zcptn )

      ! I/O: heat/freshwater fluxes
      ! these were originally in sbccpl.F90, commented them out there now
      zcptn(:,:) = rcp * sst_m(:,:)
      IF( iom_use('hflx_rnf_cea') )  CALL iom_put( 'hflx_rnf_cea', rnf(:,:) * zcptn(:,:)  )  ! l.1680
      !IF( iom_use('hflx_cal_cea') )  CALL iom_put( 'hflx_cal_cea', - zemp_cal(:,:) * lfus )  ! l.1623
      !IF( iom_use('calving_cea' ) )  CALL iom_put( 'calving_cea' , - zemp_cal(:,:)        )  ! l.1538
      IF( iom_use('hflx_cal_cea') )  CALL iom_put( 'hflx_cal_cea', calv(:,:) * lfus )  ! l.1623
      IF( iom_use('calving_cea' ) )  CALL iom_put( 'calving_cea' , calv(:,:)        )  ! l.1538

      ! deallocate
      CALL wrk_dealloc( jpi,jpj, zcptn )

   END SUBROUTINE sbc_fwf_output



END MODULE sbcfwf
