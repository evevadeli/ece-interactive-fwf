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

   PUBLIC   sbc_fwf_init, sbc_fwf, sbc_fwf_bm        ! routines called by sbcmod.F90

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
   !: information about the additionnal forced river runoff file to be read
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
      !! ** Action  : update `tsb` and`sshb` at each time step
      !!----------------------------------------------------------------------   
      
      INTEGER                              , INTENT(in   ) ::   kt          ! ocean time-step index
      !INTEGER                              , INTENT(in   ) ::   kit000      ! first time step index
      INTEGER  ::  ji, jj, jk                ! dummy loop indices
      !
      !CALL wrk_alloc( jpi, jpj, jpkm )
      !
         DO jk = 1, jpk                     
            DO jj = 1, jpj                    
               DO ji = 1, jpi                 
                  IF( sf_zshelf(ji,jj) .GT. 0.) THEN
                     IF( sf_zdraft(ji,jj) .GT. 0.) THEN
                        IF( gdept_n(ji,jj,jk) .GT. sf_zdraft(ji,jj) ) THEN
                           IF( gdept_n(ji,jj,jk) .LT. sf_zshelf(ji,jj) ) THEN
                              ! Computations assume m3 as input for sf_rnf_f;  distribution from sshb to zshelf
                              !tsb(ji,jj,jk,jp_tem) = tsb(ji,jj,jk,jp_tem) - 333.55/4.184 * &
                              !   & sf_rnf_f(1)%fnow(ji,jj,1)/(e1t(ji,jj)*e2t(ji,jj)*(sf_zshelf(ji,jj)+sshb(ji,jj)))
                           
                              !tsb(ji,jj,jk,jp_sal) = tsb(ji,jj,jk,jp_sal) * (e1t(ji,jj)*e2t(ji,jj) * (sf_zshelf(ji,jj)+sshb(ji,jj))) & 
                              !   &/(e1t(ji,jj)*e2t(ji,jj)*(sf_zshelf(ji,jj)+sshb(ji,jj)) + sf_rnf_f(1)%fnow(ji,jj,1))
                           
                              !sshb(ji,jj)=sshb(ji,jj) + sf_rnf_f(1)%fnow(ji,jj,1)/(e1t(ji,jj)*e2t(ji,jj))

                              ! Computations assuming kg m-2 s-1 as input for sf_rnf_f: distribution from zdraft to zshelf
                              tsb(ji,jj,jk,jp_tem) = tsb(ji,jj,jk,jp_tem) - lfus / 4184.0 * &
                              & sf_rnf_f(1)%fnow(ji,jj,1) * 1.e-3 * 2700 / ( sf_zshelf(ji,jj) - sf_zdraft(ji,jj) )
                        
                              tsb(ji,jj,jk,jp_sal) = tsb(ji,jj,jk,jp_sal) * ( sf_zshelf(ji,jj) - sf_zdraft(ji,jj) ) & 
                              &/( sf_zshelf(ji,jj) - sf_zdraft(ji,jj) + sf_rnf_f(1)%fnow(ji,jj,1) * 1.e-3 * 2700 )
                        
                              sshb(ji,jj) = sshb(ji,jj) + sf_rnf_f(1)%fnow(ji,jj,1) * 1.e-3 * 2700
                           ENDIF
                        ENDIF
                     ENDIF     
                  ENDIF
               END DO
            END DO
         END DO
      !CALL wrk_dealloc( jpi, jpj, jpkm )
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
      !! ** Action  : update `rnf`,`emp_tot`,`emp_oce` and `qns_tot`
      !!              at each time step with addtional freshwater forcing
      !!----------------------------------------------------------------------   
      INTEGER, INTENT(in) ::   kt   ! ocean time step

      REAL(wp), POINTER, DIMENSION(:,:) ::  zemp_cal, zcptn

      ! allocate
      CALL wrk_alloc( jpi,jpj, zemp_cal, zcptn)
      ! rnf, emp_tot, qns_tot  defined in sbc_oce.F90
      ! emp_oce                defined in sbc_ice.F90

      ! forcing:   read additional forcing files
      CALL fld_read ( kt, nn_fsbc, sf_rnf_f )  ! Read forced Runoffs data and provide it at kt
      CALL fld_read ( kt, nn_fsbc, sf_cal_f )  ! Read forced Runoffs calving data and provide it at kt

      ! add freshwater fluxes from runoff (not anymore since we correct with sbc_fwf_bm)
      !rnf(:,:)      = rnf(:,:)      + sf_rnf_f(1)%fnow(:,:,1)
      !WRITE(numout,*) 'forced runoffs.nc sorunoff_f  field added to `rnf` runoff flux'
      
      ! add freshwater fluxes from calving to both ocean and total
      ! the so_calving_f field is defined as positive for fluxes into the ocean,
      ! so the upward calving flux is negative (and compatible with emp)
      zemp_cal(:,:) = zemp_cal(:,:) - sf_cal_f(1)%fnow(:,:,1)
      emp_oce(:,:) = emp_oce(:,:) + zemp_cal(:,:)
      emp_tot(:,:) = emp_tot(:,:) + zemp_cal(:,:)
      ! WRITE(numout,*) 'forced runoffs.nc socalving_f fields added to `emp_tot` and `emp_oce` freshwater fluxes'
      
      ! add heat flux from calving
      ! melting should result in negatve heat fluxi
      qns_tot(:,:) = qns_tot(:,:) + zemp_cal(:,:) * lfus  ! assumes icebergs to be at melting point temperature
      ! WRITE(numout,*) 'forced runoffs.nc socalving_f fields added to `qns_tot` heat flux'

      ! I/O: heat/freshwater fluxes
      ! these were originally in sbccpl.F90, commented them out there now
      zcptn(:,:) = rcp * sst_m(:,:)
      IF( iom_use('hflx_rnf_cea') )  CALL iom_put( 'hflx_rnf_cea', rnf(:,:) * zcptn(:,:)  )  ! l.1680
      IF( iom_use('hflx_cal_cea') )  CALL iom_put( 'hflx_cal_cea', - zemp_cal(:,:) * lfus )  ! l.1623
      IF( iom_use('calving_cea' ) )  CALL iom_put( 'calving_cea' , - zemp_cal(:,:)        )  ! l.1538

      ! deallocate
      CALL wrk_dealloc( jpi,jpj, zemp_cal )

   END SUBROUTINE sbc_fwf

END MODULE sbcfwf
