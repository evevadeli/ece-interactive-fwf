# namelist.nemo-ORCA1L46.cfg.sh writes the NEMO namelist for ORCA1L46 in
# coupled mode to standard output. This namelist will overwrite the reference
# namelist (namelist.nemo.ref.sh). Hence, only parameters specific to the
# ORCA1L46/coupled configuration should be specified here.

cat << EOF
!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!! NEMO/OPA  Configuration namelist : used to overwrite defaults values defined in SHARED/namelist_ref
!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

!!======================================================================
!!                   ***  Run management namelists  ***
!!======================================================================
!!   namrun       parameters of the run
!!======================================================================
!
!-----------------------------------------------------------------------
&namrun        !   parameters of the run
!-----------------------------------------------------------------------
   nn_leapy      =  1            !  Leap year calendar (1) or not (0)
/
!
!!======================================================================
!!                      ***  Domain namelists  ***
!!======================================================================
!!   namcfg       parameters of the configuration
!!   namzgr       vertical coordinate
!!   namzgr_sco   s-coordinate or hybrid z-s-coordinate
!!   namdom       space and time domain (bathymetry, mesh, timestep)
!!   namtsd       data: temperature & salinity
!!======================================================================
!
!-----------------------------------------------------------------------
&namcfg        !   parameters of the configuration
!-----------------------------------------------------------------------
   cp_cfg      =   "orca"              !  name of the configuration
   jp_cfg      =       1               !  resolution of the configuration
   jpidta      =     362               !  1st lateral dimension ( >= jpi )
   jpjdta      =     292               !  2nd    "         "    ( >= jpj )
   jpkdta      =      75               !lolo  number of levels      ( >= jpk )
   jpiglo      =     362               !  1st dimension of global domain --> i =jpidta
   jpjglo      =     292               !  2nd    -                  -    --> j  =jpjdta
   jperio      =       6               !  lateral cond. type (between 0 and 6)
                                       !  = 0 closed                 ;   = 1 cyclic East-West
                                       !  = 2 equatorial symmetric   ;   = 3 North fold T-point pivot
                                       !  = 4 cyclic East-West AND North fold T-point pivot
                                       !  = 5 North fold F-point pivot
                                       !  = 6 cyclic East-West AND North fold F-point pivot
/
!-----------------------------------------------------------------------
&namzgr        !   vertical coordinate
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzgr_sco    !   s-coordinate or hybrid z-s-coordinate
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdom        !   space and time domain (bathymetry, mesh, timestep)
!-----------------------------------------------------------------------
   rn_hmin     =    20.    !  min depth of the ocean (>0) or min number of ocean level (<0)
   rn_rdt      = ${nem_time_step_sec} !  time step for the dynamics (and tracer if nn_acc=0)
   ppglam0     =  999999.0             !  longitude of first raw and column T-point (jphgr_msh = 1)
   ppgphi0     =  999999.0             ! latitude  of first raw and column T-point (jphgr_msh = 1)
   ppe1_deg    =  999999.0             !  zonal      grid-spacing (degrees)
   ppe2_deg    =  999999.0             !  meridional grid-spacing (degrees)
   ppe1_m      =  999999.0             !  zonal      grid-spacing (degrees)
   ppe2_m      =  999999.0             !  meridional grid-spacing (degrees)
   ppsur       =   -3958.951371276829  !  ORCA r4, r2 and r05 coefficients
   ppa0        =     103.9530096000000 ! (default coefficients)
   ppa1        =       2.415951269000000   !
   ppkth       =      15.35101370000000    !
   ppacr       =       7.0             !
   ppdzmin     =  999999.0             !  Minimum vertical spacing
   pphmax      =  999999.0             !  Maximum depth
   ldbletanh   =   .TRUE.              !  Use/do not use double tanf function for vertical coordinates
   ppa2        =     100.7609285000000 !  Double tanh function parameters
   ppkth2      =      48.02989372000000    !
   ppacr2      =      13.00000000000   !
/
!-----------------------------------------------------------------------
&namsplit      !   time splitting parameters  ("key_dynspg_ts") !lolo compiled with!
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namcrs        !   Grid coarsening for dynamics output and/or
               !   passive tracer coarsened online simulations
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtsd    !   data : Temperature  & Salinity
!-----------------------------------------------------------------------
!          !  file name    ! frequency (hours) ! variable  ! time interp. !  clim  ! 'yearly'/ ! weights  ! rotation ! land/sea mask !
!          !               ! (if <0  months)   !  name     ! (logical)    !  (T/F) ! 'monthly' ! filename ! pairing  ! filename      !
   sn_tem  = 'conservative_temperature_WOA13_decav_Reg1L75_clim', -1 ,'votemper' , .true. , .true. , 'yearly' , 'weights_WOA13d1_2_orca1_bilinear.nc' , '' , ''
   sn_sal  = 'absolute_salinity_WOA13_decav_Reg1L75_clim'       , -1 ,'vosaline' , .true. , .true. , 'yearly' , 'weights_WOA13d1_2_orca1_bilinear.nc' , '' , ''
   ln_tsd_tradmp = ${ln_tsd_tradmp}  !  damping of ocean T & S toward T &S input data (T) or not (F)
/
!-----------------------------------------------------------------------
&namsbc        !   Surface Boundary Condition (surface module)
!-----------------------------------------------------------------------
   nn_fsbc     = $(( lim_time_step_sec / nem_time_step_sec )) !  frequency of surface boundary condition computation
                           !     (also = the frequency of sea-ice model call)
   ln_blk_core = .false.   !  CORE bulk formulation                     (T => fill namsbc_core)
   ln_cpl      = .true.    !  Coupled formulation                       (T => fill namsbc_cpl )
   nn_ice_embd = 1         !  =0 levitating ice (no mass exchange, concentration/dilution effect)
                           !  =1 levitating ice with mass and salt exchange but no presure effect
                           !  =2 embedded sea-ice (full salt and mass exchanges and pressure)
   ln_dm2dc    = .false.   !lolo only for ocean standalone! only for ocean standalone!  daily mean to diurnal cycle on short wave   ln_dm2dc    = .false.   !  daily mean to diurnal cycle on short wave
   ln_rnf      = .true.    !  runoffs                                   (T   => fill namsbc_rnf)
   nn_isf      = 0         !  ice shelf melting/freezing                (/=0 => fill namsbc_isf)
                           !  0 = no isf                 1 = presence of ISF
                           !  2 = bg03 parametrisation   3 = rnf file for isf
                           !  4 = ISF fwf specified
                           !  option 1 and 4 need ln_isfcav = .true. (domzgr)
   ln_ssr      = .false. !  Sea Surface Restoring on T and/or S       (T => fill namsbc_ssr)
   nn_fwb      = 0         !  FreshWater Budget: =0 unchecked
                           !     =1 global mean of e-p-r set to zero at each time step
                           !     =2 annual global mean of e-p-r set to zero
   nn_limflx   =  2        !  LIM3 Multi-category heat flux formulation (use -1 if LIM3 is not used)
                           !  =-1  Use per-category fluxes, bypass redistributor, forced mode only, not yet implemented coupled
                           !  = 0  Average per-category fluxes (forced and coupled mode)
                           !  = 1  Average and redistribute per-category fluxes, forced mode only, not yet implemented coupled
                           !  = 2  Redistribute a single flux over categories (coupled mode only)
   ln_fwf = ${fwf_option}  ! read in additional freshwater forcing fields
/
!-----------------------------------------------------------------------
&namsbc_ana    !   analytical surface boundary condition
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_flx    !   surface boundary condition : flux formulation
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_clio   !   namsbc_clio  CLIO bulk formulae
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_core   !   namsbc_core  CORE bulk formulae
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_cpl    !   coupled ocean/atmosphere model                       ("key_coupled")
!-----------------------------------------------------------------------
!                ! description      !  multiple  !    vector   !      vector          ! vector !
!                !                  ! categories !  reference  !    orientation       ! grids  !
! send
   sn_snd_temp   =   'oce and ice'  ,    'no'    ,     ''      ,         ''           ,   ''
   sn_snd_alb    =   'ice'          ,    'no'    ,     ''      ,         ''           ,   ''
   sn_snd_thick  =   'ice and snow' ,    'no'    ,     ''      ,         ''           ,   ''
   sn_snd_crt    =   'none'         ,    'no'    , 'spherical' , 'eastward-northward' ,  'T'
   sn_snd_co2    =   'none'         ,    'no'    ,     ''      ,         ''           ,   ''
! receive
   sn_rcv_w10m   =   'none'         ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_taumod =   'none'         ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_tau    =   'oce and ice'  ,    'no'    , 'spherical' , 'eastward-northward' ,   'U,V'
   sn_rcv_dqnsdt =   'coupled'      ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_qsr    =   'conservative' ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_qns    =   'conservative' ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_emp    =   'conservative' ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_rnf    =   'coupled'      ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_cal    =   'coupled'      ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_co2    =   'none'         ,    'no'    ,     ''      ,         ''           ,   ''
   sn_rcv_iceflx =   'none'         ,    'no'    ,     ''      ,         ''           ,   ''
!
   nn_cplmodel   =     1     !  Maximum number of models to/from which NEMO is potentialy sending/receiving data
   ln_usecplmask = .false.   !  use a coupling mask file to merge data received from several models
                             !   -> file cplmask.nc with the float variable called cplmask (jpi,jpj,nn_cplmodel)
/
!-----------------------------------------------------------------------
&namtra_qsr    !   penetrative solar radiation
!-----------------------------------------------------------------------
   nn_chldta   =      0    !  RGB : Chl data (=1) or cst value (=0)
/
!-----------------------------------------------------------------------
&namsbc_fwf    !   additional freshwater forcing namelist surface boundary condition
!-----------------------------------------------------------------------
!         !  file name         ! frequency (hours) ! variable   ! time interp. ! clim  ! 'yearly'/ ! weights  ! rotation !
!         !                    !  (if <0  months)  !   name     !   (logical)  ! (T/F) ! 'monthly' ! filename ! pairing  !
   cn_dir_f = './'  !  root directory for the location of the runoff files
   sn_rnf_f = 'freshwater_forcing',              -1, 'sorunoff_f' , .true.     , .false., 'yearly' , ''       , ''       , ''
   sn_cal_f = 'freshwater_forcing',              -1, 'socalving_f', .true.     , .false., 'yearly' , ''       , ''       , ''
   sn_zshelf = 'zshelf',                          0, 'zshelf',      .false.    , .true.,  'yearly' , ''       , ''       , ''
/
!-----------------------------------------------------------------------
&namsbc_rnf    !   runoffs namelist surface boundary condition
!-----------------------------------------------------------------------
!         !  file name         ! frequency (hours) ! variable   ! time interp. ! clim  ! 'yearly'/ ! weights  ! rotation !
!         !                    !  (if <0  months)  !   name     !   (logical)  ! (T/F) ! 'monthly' ! filename ! pairing  !
   sn_rnf     = 'runoff-icb_DaiTrenberth_Depoorter_ORCA1_JD.nc', -1, 'sorunoff', .true.  , .true. , 'yearly' , '' , '' , ''
   sn_i_rnf   = 'runoff-icb_DaiTrenberth_Depoorter_ORCA1_JD.nc', -1, 'Icb_flux', .true.  , .true. , 'yearly' , '' , '' , ''
   sn_cnf     = 'runoff-icb_DaiTrenberth_Depoorter_ORCA1_JD.nc',  0, 'socoeff' , .false. , .true. , 'yearly' , '' , '' , ''
   sn_dep_rnf = 'runoff_depth'                                 ,  0, 'rodepth' , .false. , .true. , 'yearly' , '' , '' , ''
                !
   cn_dir            = './'       !  root directory for the location of the runoff files
   ln_rnf_icb        = .true.     !  read in iceberg flux
   ln_rnf_mouth      = .false.    !  specific treatment at rivers mouths
   rn_hrnf           =  15.e0     !  depth over which enhanced vertical mixing is used
   rn_avt_rnf        =   1.e-3    !  value of the additional vertical mixing coef. [m2/s]
   rn_rfact          =   1.e0     !  multiplicative factor for runoff
   ln_rnf_depth      = .true.     !  read in depth information for runoff 
   ln_rnf_tem        = .false.    !  read in temperature information for runoff
   ln_rnf_sal        = .false.    !  read in salinity information for runoff
   ln_rnf_depth_ini  = .false.    !  compute depth at initialisation from runoff file
   rn_rnf_max        = 0.0065     !  max value of the runoff climatologie over global domain ( ln_rnf_depth_ini = .true )
   rn_dep_max        = 150.       !  depth over which runoffs is spread ( ln_rnf_depth_ini = .true )
   nn_rnf_depth_file = 0          !  create (=1) a runoff depth file or not (=0)
/
!-----------------------------------------------------------------------
&namsbc_ssr    !   surface boundary condition : sea surface restoring
!-----------------------------------------------------------------------
!
! 07/2018 - Yohan Ruprich-Robert chages: add mask_ssr reading option and take into account last shaconemo update (06/2018)
!
   !             ! filename          ! freq  ! variable name  ! time     ! clim     ! year or   ! weights   ! rot     ! mask
   !             !                   !       !                ! interp   !          ! monthly   ! filename  ! pair    ! filename
   !----------------------------------------------------------------------------------------------------------------------------------------
   sn_sss      = 'sss_restore_data'  , -1.   , 'so'           , .true.   , .false.  , 'yearly'   , ''        , ''      , ''
   sn_sst      = 'sst_restore_data'  , -1.   , 'thetao'       , .true.   , .false.  , 'yearly'   , ''        , ''      , ''
   sn_msk      = 'mask_restore'      , -12.  , 'mask_ssr'     , .false.  , .true.  , 'yearly'   , ''        , ''      , ''
   !
   cn_dir      = './'    !  root directory for the location of the runoff files  
   nn_sstr     = 1       !  add a retroaction term in the surface heat flux (=1) or not (=0)
   nn_sssr     = 2       !  add a damping term in the surface freshwater flux (=2) or to SSS only (=1) or no damping term (=0)
   nn_icedmp   = 0       !  Cntrl of surface restoration under ice nn_icedmp 
                         !  ( 0   =  no restoration under ice )
                         !  ( 1   =  restoration everywhere  )
                         !  ( > 1 =  reinforced damping (x nn_icedmp) under ice
   nn_msk      = 1       !  add a sub-regional masking to the surface restoring (=1) or not (=0)
                         !  sn_msk can be empty if nn_msk = 0
   rn_dqdt     = -40.    !  magnitude of the retroaction on temperature   [W/m2/K]
   rn_deds     = -27.7   ! -864 magnitude of the damping on salinity   [kg/m2/s/psu]
   ln_sssr_bnd = .false. ! .true. !  flag to bound erp term (associated with nn_sssr=2)
   rn_sssr_bnd = 4.e0    !  ABS(Max/Min) value of the damping erp term [mm/day] (associated with nn_sssr=2)
   ln_sssd_bnd = .false. ! .true. !  flag to bound S-S* term (associated with nn_ssr=2)
   rn_sssd_bnd = 0.01    !  ABS(Max./Min.) value of S-S* term [psu] (associated with nn_ssr=2)
/
!-----------------------------------------------------------------------
&namsbc_alb    !   albedo parameters
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namberg       !   iceberg parameters
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namlbc        !   lateral momentum boundary condition
!-----------------------------------------------------------------------
   rn_shlat    =    0.     !  shlat = 0  !  0 < shlat < 2  !  shlat = 2  !  2 < shlat
                           !  free slip  !   partial slip  !   no slip   ! strong slip
/
!-----------------------------------------------------------------------
&namcla        !   cross land advection
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namobc        !   open boundaries parameters                           ("key_obc")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namagrif      !  AGRIF zoom                                            ("key_agrif")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nam_tide      !   tide parameters (#ifdef key_tide)
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambdy        !  unstructured open boundaries                          ("key_bdy")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambdy_dta      !  open boundaries - external data           ("key_bdy")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambdy_tide     ! tidal forcing at open boundaries
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambfr        !   bottom friction
!-----------------------------------------------------------------------
   nn_bfr      =    2      !  type of bottom friction :   = 0 : free slip,  = 1 : linear friction
                           !                              = 2 : nonlinear friction
/
!-----------------------------------------------------------------------
&nambbc        !   bottom temperature boundary condition
!-----------------------------------------------------------------------
   ln_trabbc   = .true.    !  Apply a geothermal heating at the ocean bottom
   nn_geoflx   =    2      !  geothermal heat flux: = 0 no flux
                           !     = 1 constant flux
                           !     = 2 variable flux (read in geothermal_heating.nc in mW/m2)
   sn_qgh      = 'Goutorbe_ghflux.nc', -12. , 'gh_flux' , .false. , .true. , 'yearly' , 'weights_Goutorbe1_2_orca1_bilinear.nc' , '' , ''
/
!-----------------------------------------------------------------------
&nambbl        !   bottom boundary layer scheme
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nameos        !   ocean physical parameters
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtra_adv    !   advection scheme for tracer
!-----------------------------------------------------------------------
   ln_traadv_tvd    =  .false.  !  TVD scheme
   ln_traadv_ubs    =  .false.  !  UBS scheme
   ln_traadv_tvd_zts=  .true.   !lolo  TVD scheme with sub-timestepping of vertical tracer advection
/
!-----------------------------------------------------------------------
&namtra_adv_mle !  mixed layer eddy parametrisation (Fox-Kemper param)
!-----------------------------------------------------------------------
/
!----------------------------------------------------------------------------------
&namtra_ldf    !   lateral diffusion scheme for tracers
!----------------------------------------------------------------------------------
   ln_traldf_grif   =  .false.   !  griffies skew flux formulation       (require "key_ldfslp")
   ln_traldf_gdia   =  .false.   !  griffies operator strfn diagnostics  (require "key_ldfslp")
   ln_botmix_grif   =  .false.   !  griffies operator with lateral mixing on bottom (require "key_ldfslp")
   rn_aht_0         =  1000.    !  horizontal eddy diffusivity for tracers [m2/s]
   rn_aeiv_0        =  1000.    !  eddy induced velocity coefficient [m2/s]    (require "key_traldf_eiv")
/
!-----------------------------------------------------------------------
&namtra_dmp    !   tracer: T & S newtonian damping
!-----------------------------------------------------------------------
   ln_tradmp   =  ${ln_tradmp}  !  add a damping termn (T) or not (F)
      nn_zdmp     =    2      !  vertical   shape =0    damping throughout the water column
                           !                   =1 no damping in the mixing layer (kz  criteria)
                           !                   =2 no damping in the mixed  layer (rho crieria)
   cn_resto    = 'resto.nc' ! Name of file containing restoration coefficient field (use dmp_tools to create this)
/
!-----------------------------------------------------------------------
&namdyn_adv    !   formulation of the momentum advection
!-----------------------------------------------------------------------
   ln_dynadv_vec = .true.  !  vector form (T) or flux form (F)
   ln_dynadv_cen2= .false. !  flux form - 2nd order centered scheme
   ln_dynadv_ubs = .false. !  flux form - 3rd order UBS      scheme
   ln_dynzad_zts = .true.  !lolo  Use (T) sub timestepping for vertical advection
/
!-----------------------------------------------------------------------
&nam_vvl    !   vertical coordinate options
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_vor    !   option of physics/algorithm (not control by CPP keys)
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_hpg    !   Hydrostatic pressure gradient option
!-----------------------------------------------------------------------
   ln_hpg_zco  = .false.   !  z-coordinate - full steps
   ln_hpg_zps  = .false.   !  z-coordinate - partial steps (interpolation)
   ln_hpg_sco  = .true.    !lolo  s-coordinate (standard jacobian formulation)
   ln_hpg_isf  = .false.   !  s-coordinate (sco ) adapted to isf
   ln_hpg_djc  = .false.   !  s-coordinate (Density Jacobian with Cubic polynomial)
   ln_hpg_prj  = .false.   !  s-coordinate (Pressure Jacobian scheme)
   ln_dynhpg_imp = .false.   !  time stepping: semi-implicit time scheme  (T)
                              !           centered      time scheme  (F)
/
!-----------------------------------------------------------------------
&namdyn_ldf    !   lateral diffusion on momentum
!-----------------------------------------------------------------------
   rn_ahm_0_lap     = 20000.    !  horizontal laplacian eddy viscosity   [m2/s]
/
!-----------------------------------------------------------------------
&namzdf        !   vertical physics
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_ric    !   richardson number dependent vertical diffusion       ("key_zdfric" )
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_tke    !   turbulent eddy kinetic dependent vertical diffusion  ("key_zdftke")
!-----------------------------------------------------------------------
   rn_lc       =   0.20    !  coef. associated to Langmuir cells                                                                                                                           
   nn_etau     =   0       !  penetration of tke below the mixed layer (ML) due to internal & intertial waves                                                                              
                           !        = 0 no penetration                                                                                                                   
                           !        = 1 add a tke source below the ML
                           !        = 2 add a tke source just at the base of the ML
                           !        = 3 as = 1 applied on HF part of the stress    ("key_coupled")

/
!------------------------------------------------------------------------
&namzdf_kpp    !   K-Profile Parameterization dependent vertical mixing  ("key_zdfkpp", and optionally:
!------------------------------------------------------------------------ "key_kppcustom" or "key_kpplktb")
/
!-----------------------------------------------------------------------
&namzdf_gls                !   GLS vertical diffusion                   ("key_zdfgls")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_ddm    !   double diffusive mixing parameterization             ("key_zdfddm")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_tmx    !   tidal mixing parameterization                        ("key_zdftmx")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_tmx_new    !   new tidal mixing parameterization                ("key_zdftmx_new")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsol        !   elliptic solver / island / free surface
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nammpp        !   Massively Parallel Processing                        ("key_mpp_mpi)
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namctl        !   Control prints & Benchmark
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namc1d_uvd    !   data: U & V currents                                 ("key_c1d")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namc1d_dyndmp !   U & V newtonian damping                              ("key_c1d")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsto       ! Stochastic parametrization of EOS
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namnc4        !   netcdf4 chunking and compression settings            ("key_netcdf4")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtrd        !   diagnostics on dynamics and/or tracer trends         ("key_trddyn" and/or "key_trdtra")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namflo       !   float parameters                                      ("key_float")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namptr       !   Poleward Transport Diagnostic
!-----------------------------------------------------------------------
   ln_diaptr  = .true.     !  Poleward heat and salt transport (T) or not (F)
   ln_subbas  = .true.      !  Atlantic/Pacific/Indian basins computation (T) or not
/
!-----------------------------------------------------------------------
&namhsb       !  Heat and salt budgets
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nam_diaharm   !   Harmonic analysis of tidal constituents ('key_diaharm')
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdct        ! transports through sections
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namobs       !  observation usage switch                               ('key_diaobs')
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nam_asminc   !   assimilation increments                               ('key_asminc')
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_wave   ! External fields from wave model
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_nept  !   Neptune effect (simplified: lateral and vertical diffusions removed)
!-----------------------------------------------------------------------
/
EOF
