
!***********************************************************************
!   Portions of Models-3/CMAQ software were developed or based on      *
!   information from various groups: Federal Government employees,     *
!   contractors working on a United States Government contract, and    *
!   non-Federal sources (including research institutions).  These      *
!   research institutions have given the Government permission to      *
!   use, prepare derivative works, and distribute copies of their      *
!   work in Models-3/CMAQ to the public and to permit others to do     *
!   so.  EPA therefore grants similar permissions for use of the       *
!   Models-3/CMAQ software, but users are requested to provide copies  *
!   of derivative works to the Government without restrictions as to   *
!   use by others.  Users are responsible for acquiring their own      *
!   copies of commercial software associated with Models-3/CMAQ and    *
!   for complying with vendor requirements.  Software copyrights by    *
!   the MCNC Environmental Modeling Center are used with their         *
!   permissions subject to the above restrictions.                     *
!***********************************************************************

SUBROUTINE setup_wrfem (cdfid, ctmlays)

!-------------------------------------------------------------------------------
! Name:     Set Up the WRF Domain Attributes
! Purpose:  Establishes bounds for WRF post-processing.
! Revised:  ?? Jun 2004  Modified from MCIP2.2 for WRF. (S.-B. Kim)
!           26 May 2005  Changed vertical dimension to reflect full-layer
!                        dimension in WRFv2 header.  Added dynamic calculation
!                        of MET_TAPFRQ.  Converted dimensions to X,Y as opposed
!                        to the (former) convention that aligned with MM5.
!                        Included updates from MCIPv2.3.  Added calculation of
!                        cone factor.  Added logic for moist species, 2-m
!                        temperature, and 10-m winds.  Added definitions for
!                        WRF base state variables.  Added capability to use all
!                        WRF layers for MCIP without defining a priori.
!                        Cleaned up code.  (T. Otte)
!           15 Jul 2005  Added debugging on variable retrievals.  Changed check
!                        on 3D mixing ratios from rain to ice.  Corrected RADM
!                        seasons for Southern Hemisphere.  Corrected variable
!                        name for retrieval of surface physics option. (T. Otte)
!           18 Aug 2005  Changed internal variable SIGN to FAC to avoid
!                        confusion with F90 intrinsic function.  (T. Otte)
!           10 Apr 2006  Corrected checking of I/O API variables for Mercator
!                        projection.  (T. Otte)
!           12 May 2006  Corrected setting of I/O API variables for polar
!                        stereographic projection.  Revised defining and
!                        setting projection variables for module METINFO.
!                        Added restriction on using Eta/Ferrier microphysics
!                        scheme where QCLOUD represents total condensate.
!                        (T. Otte)
!           20 Jun 2006  Changed setting of IDTSEC from REAL to INTEGER
!                        value.  (T. Otte)
!           27 Jul 2007  Removed settings for RADMdry variable ISESN and for
!                        MET_INHYD.  Updated read of P_TOP to account for new
!                        method of storing "real" scalars in WRF I/O API with
!                        WRFv2.2.  Added checks for fractional land use, leaf
!                        area index, Monin-Obukhov length, aerodynamic and
!                        stomatal resistances, vegetation fraction, canopy
!                        wetness, and soil moisture, temperature, and type in
!                        WRF file.  Added read for number of land use
!                        categories...new with WRFV2.2.  Added read for number
!                        of soil layers, MET_RELEASE, MET_FDDA_3DAN and
!                        MET_FDDA_OBS.  Set MET_FDDA_SFAN to 0 for now because
!                        that option is not in WRF ARW as of V2.2.  Changed
!                        MET_RADIATION into MET_LW_RAD and MET_SW_RAD.
!                        (T. Otte)
!           06 May 2008  Changed criteria for setting NUMMETLU when netCDF
!                        dimension "land_cat_stag" does not exist.  Added
!                        checks to determine if 2-m mixing ratio (Q2) and
!                        turbulent kinetic energy (TKE_MYJ) arrays exist, and
!                        set flags appropriately.  Extract nudging coefficients
!                        from header to use in metadata.  Extract whether or
!                        not the urban canopy model was used.  (T. Otte)
!           27 Oct 2009  Cleaned up file opening and logging in WRF I/O API to
!                        prevent condition with too many files open for long
!                        simulations.  Added MODIFIED IGBP MODIS NOAH and 
!                        NLCD/MODIS as land-use classification options.
!                        Changed MET_UCMCALL to MET_URBAN_PHYS, and allowed
!                        for variable to be set to be greater than 1.  Chnaged
!                        code to allow for surface analysis nudging option
!                        and coefficients to be defined per WRFv3.1.  Define
!                        MET_CEN_LAT, MET_CEN_LON, MET_RICTR_DOT, MET_RJCTR_DOT,
!                        and MET_REF_LAT.  Increased MAX_TIMES to 1000.  Compute
!                        MET_XXCTR and MET_YYCTR.  Corrected setting for
!                        DATE_INIT, and fill variable MET_RESTART.  Read number
!                        of land use categories from WRF global attributes for
!                        WRFV3.1 and beyond.  Allow output from WRF
!                        Preprocessing System (WPS) routine, GEOGRID, to provide
!                        fractional land use output if it is unavailable in WRF
!                        output.  Fill MET_P_ALP_D and MET_P_BET_D here
!                        rather than in setgriddefs.F for Mercator.  Added
!                        new logical variables IFLUWRFOUT and IFZNT.  (T. Otte)
!           12 Feb 2010  Removed unused variables COMM and SYSDEP_INFO.
!                        (T. Otte)
!           18 Mar 2010  Added CDFID as an input argument, and no longer open
!                        and close WRF history file here.  Added CDFIDG as an
!                        input argument for subroutine CHKWPSHDR.  (T. Otte)
!-------------------------------------------------------------------------------

  USE metinfo
  USE date_pack
  USE mcipparm
  USE file
  USE parms3, ONLY: badval3
  USE wrf_netcdf
  USE const, ONLY: pi180

  IMPLICIT NONE

  INCLUDE 'netcdf.inc'

  INTEGER,       INTENT(IN)    :: cdfid
  INTEGER                      :: cdfid2
  INTEGER                      :: cdfidg
  REAL,          INTENT(INOUT) :: ctmlays    ( maxlays )
  CHARACTER*19                 :: date_init
  CHARACTER*19                 :: date_start
  INTEGER                      :: dimid
  REAL,          ALLOCATABLE   :: dum2d      ( : , : )
  REAL                         :: dx
  REAL                         :: dy
  REAL                         :: fac
  CHARACTER*256                :: fl
  CHARACTER*256                :: fl2
  CHARACTER*256                :: flg
  CHARACTER*256                :: geofile
  INTEGER                      :: idtsec
  LOGICAL                      :: ifgeo
  LOGICAL                      :: ifisltyp
  LOGICAL                      :: ifra
  LOGICAL                      :: ifrs
  LOGICAL                      :: ifsmois
  LOGICAL                      :: iftslb
  LOGICAL                      :: ifu10m
  LOGICAL                      :: ifv10m
  INTEGER                      :: it
  INTEGER                      :: ival
  INTEGER,       PARAMETER     :: max_times  = 1000
  INTEGER                      :: n_times
  INTEGER                      :: nxm
  INTEGER                      :: nym
  CHARACTER*16,  PARAMETER     :: pname      = 'SETUP_WRFEM'
  INTEGER                      :: rcode
  CHARACTER*80                 :: times      ( max_times )
  CHARACTER*80                 :: times2     ( max_times )
  INTEGER                      :: varid
  CHARACTER*80                 :: wrfversion

!-------------------------------------------------------------------------------
! Extract NX, NY, and NZ.
!-------------------------------------------------------------------------------

  WRITE (6,6000)

  fl = file_mm(1)

  rcode = nf_get_att_int (cdfid, nf_global, 'WEST-EAST_GRID_DIMENSION', met_nx)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'WEST-EAST_GRID_DIMENSION', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'SOUTH-NORTH_GRID_DIMENSION', met_ny)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'SOUTH-NORTH_GRID_DIMENSION', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'BOTTOM-TOP_GRID_DIMENSION', ival)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'BOTTOM-TOP_GRID_DIMENSION', rcode
    GOTO 1001
  ELSE
    met_nz = ival - 1
  ENDIF

  WRITE (6,6100) met_nx, met_ny, met_nz

  met_rictr_dot = FLOAT(met_nx - 1) / 2.0 + 1.0
  met_rjctr_dot = FLOAT(met_ny - 1) / 2.0 + 1.0

!-------------------------------------------------------------------------------
! If layer structure was not defined in user namelist, use WRF layers.
!-------------------------------------------------------------------------------

  IF ( needlayers ) THEN
    nlays = met_nz
    CALL get_var_1d_real_cdf (cdfid, 'ZNW', ctmlays(1:nlays+1), nlays+1,  &
                              1, rcode)
    IF ( rcode /= nf_noerr ) THEN
      WRITE (6,9400) 'ZNW', rcode
      GOTO 1001
    ENDIF
  ENDIF

!-------------------------------------------------------------------------------
! Extract domain attributes.
!-------------------------------------------------------------------------------

  rcode = nf_get_att_text (cdfid, nf_global, 'TITLE', wrfversion)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'TITLE', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'DX', dx)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'DX', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'DY', dy)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'DY', rcode
    GOTO 1001
  ENDIF

  IF (dx == dy) THEN
    met_resoln = dx
  ELSE
    GOTO 8000
  ENDIF

  met_nxcoarse = met_nx 
  met_nycoarse = met_ny
  met_gratio   = 1
  met_x_11     = 1
  met_y_11     = 1

  rcode = nf_get_att_int (cdfid, nf_global, 'MAP_PROJ', met_mapproj)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'MAP_PROJ', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'STAND_LON', met_proj_clon)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'STAND_LON', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'MOAD_CEN_LAT', met_proj_clat)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'MOAD_CEN_LAT', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'CEN_LON', met_cen_lon)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'CEN_LON', rcode
    GOTO 1001
  ENDIF
  met_x_centd = met_cen_lon

  rcode = nf_get_att_real (cdfid, nf_global, 'CEN_LAT', met_cen_lat)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'CEN_LAT', rcode
    GOTO 1001
  ENDIF
  met_y_centd = met_cen_lat

  rcode = nf_get_att_real (cdfid, nf_global, 'TRUELAT1', met_tru1)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'TRUELAT1', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'TRUELAT2', met_tru2)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'TRUELAT2', rcode
    GOTO 1001
  ENDIF

  SELECT CASE ( met_mapproj )
    
    CASE (1)  ! Lambert conformal 
      met_p_alp_d  = MIN(met_tru1, met_tru2)  ! true latitude 1  [degrees]
      met_p_bet_d  = MAX(met_tru1, met_tru2)  ! true latitude 2  [degrees]
      met_p_gam_d  = met_proj_clon            ! central meridian [degrees]
      IF ( met_proj_clat < 0.0 ) THEN
        fac = -1.0  ! Southern Hemisphere
      ELSE
        fac =  1.0  ! Northern Hemisphere
      ENDIF
      IF ( ABS(met_tru1 - met_tru2) > 1.0e-1 ) THEN
        met_cone_fac = ALOG10(COS(met_tru1 * pi180)) -  &
                       ALOG10(COS(met_tru2 * pi180))
        met_cone_fac = met_cone_fac /                                      &
                       ( ALOG10(TAN((45.0 - fac*met_tru1/2.0) * pi180)) -  &
                         ALOG10(TAN((45.0 - fac*met_tru2/2.0) * pi180)) )
      ELSE
        met_cone_fac = fac * SIN(met_tru1*pi180)
      ENDIF

      IF ( wrf_lc_ref_lat > -999.0 ) THEN
        met_ref_lat = wrf_lc_ref_lat
      ELSE
        met_ref_lat = ( met_tru1 + met_tru2 ) * 0.5
      ENDIF

      CALL ll2xy_lam (met_cen_lat, met_cen_lon, met_tru1, met_tru2,  &
                      met_proj_clon, met_ref_lat, met_xxctr, met_yyctr)
    
    CASE (2)  ! polar stereographic
      met_p_alp_d  = SIGN(1.0, met_y_centd)   ! +/-1.0 for North/South Pole
      met_p_bet_d  = met_tru1                 ! true latitude    [degrees]
      met_p_gam_d  = met_proj_clon            ! central meridian [degrees]
      met_cone_fac = 1.0                      ! cone factor
      met_ref_lat  = -999.0                   ! not used

      CALL ll2xy_ps (met_cen_lat, met_cen_lon, met_tru1, met_proj_clon,  &
                     met_xxctr, met_yyctr)
    
    CASE (3)  ! Mercator
      met_p_alp_d  = 0.0                      ! lat of coord origin [deg]
      met_p_bet_d  = 0.0                      ! (not used)
      met_p_gam_d  = met_proj_clon            ! lon of coord origin [deg]
      met_cone_fac = 0.0                      ! cone factor
      met_ref_lat  = -999.0                   ! not used

      CALL ll2xy_merc (met_cen_lat, met_cen_lon, met_proj_clon,  &
                       met_xxctr, met_yyctr)
    
    CASE DEFAULT
      met_p_bet_d  = badval3                  ! missing
      met_p_alp_d  = badval3                  ! missing
      met_p_gam_d  = badval3                  ! missing
      met_cone_fac = badval3                  ! missing
      met_ref_lat  = badval3                  ! missing
  
  END SELECT

!-------------------------------------------------------------------------------
! Extract model run options.
!-------------------------------------------------------------------------------

  rcode = nf_get_att_text (cdfid, nf_global, 'MMINLU', met_lu_src)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'MMINLU', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'ISWATER', met_lu_water)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'ISWATER', rcode
    GOTO 1001
  ENDIF

  rcode = nf_inq_dimid (cdfid, 'soil_layers_stag', dimid)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'ID for soil_layers_stag', rcode
    GOTO 1001
  ENDIF
  rcode = nf_inq_dimlen (cdfid, dimid, met_ns)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'value for soil_layers_stag', rcode
    GOTO 1001
  ENDIF

  ! NUM_LAND_CAT was added in WRFv3.1 to define number of land use categories.
  ! "land_cat_stag" was added in WRFv2.2 to define fractional land use.
  ! Older WRF runs do not include this dimension and they are restricted
  ! to 24-category USGS land cover.

  IF ( wrfversion(18:22) >= "V3.1" ) then
    rcode = nf_get_att_int (cdfid, nf_global, 'NUM_LAND_CAT', nummetlu)
    IF ( rcode /= nf_noerr ) THEN
      WRITE (6,9400) 'NUM_LAND_CAT', rcode
      GOTO 1001
    ENDIF
  ELSE
    rcode = nf_inq_dimid (cdfid, 'land_cat_stag', dimid)
    IF ( rcode /= nf_noerr ) THEN  ! only exists with fractional land use
      SELECT CASE ( met_lu_src(1:3) )
        CASE ( "USG" )  ! USGS -- typically 24, but can be up to 33 in V2.2+
          IF ( ( wrfversion(18:21) == "V2.2" ) .OR.  &
               ( wrfversion(18:19) == "V3"   ) ) THEN
            nummetlu = 33
          ELSE
            nummetlu = 24
          ENDIF
        CASE ( "OLD" )  ! old MM5 13-category system
          nummetlu = 13
        CASE ( "SiB" )  ! SiB 16-category system
          nummetlu = 16
        CASE ( "MOD" )  ! Modified IGBP MODIS NOAH 33-category system
          nummetlu = 33
        CASE ( "NLC" )  ! NLCD/MODIS 50-category combined system
          nummetlu = 50
        CASE DEFAULT
          WRITE (6,9100) met_lu_src(1:3)
          GOTO 1001
      END SELECT
    ELSE
      rcode = nf_inq_dimlen (cdfid, dimid, nummetlu)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9400) 'value for land_cat_stag', rcode
        GOTO 1001
      ENDIF
    ENDIF
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'RA_LW_PHYSICS', met_lw_rad)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'RA_LW_PHYSICS', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'RA_SW_PHYSICS', met_sw_rad)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'RA_SW_PHYSICS', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'CU_PHYSICS', met_cumulus)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'CU_PHYSICS', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'MP_PHYSICS', met_expl_moist)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'MP_PHYSICS', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'BL_PBL_PHYSICS', met_pbl)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'BL_PBL_PHYSICS', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'SF_SFCLAY_PHYSICS', met_sfc_lay)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'SF_SFCLAY_PHYSICS', rcode
    GOTO 1001
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'SF_SURFACE_PHYSICS', met_soil_lsm)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'SF_SURFACE_PHYSICS', rcode
    GOTO 1001
  ENDIF

  ! Determine if an urban model was used.

  IF ( wrfversion(18:21) >= "V3.1" ) THEN

    rcode = nf_get_att_int (cdfid, nf_global, 'SF_URBAN_PHYSICS', met_urban_phys)
    IF ( rcode /= nf_noerr ) THEN
      WRITE (6,9400) 'SF_URBAN_PHYSICS', rcode
      GOTO 1001
    ENDIF

  ELSE IF ( wrfversion(18:21) == "V3.0" ) THEN

    rcode = nf_get_att_int (cdfid, nf_global, 'UCMCALL', met_urban_phys)
    IF ( rcode /= nf_noerr ) THEN
      WRITE (6,9400) 'SF_URBAN_PHYSICS', rcode
      GOTO 1001
    ENDIF

  ELSE 

    ! In v2.2, header variable UCMCALL seems to always be 0 for nested runs,
    ! even when UCM is invoked.  For now, use field TC_URB (canopy temperature)
    ! as a proxy to determine if the UCM was used.  If the field does not exist,
    ! then the UCM was not used.  If the field exists, determine if the data are
    ! "reasonable" (i.e., positive and non-zero); assume that UCM was used if
    ! the field contains "physical" data.

    nxm = met_nx - 1
    nym = met_ny - 1
    it  = 1  ! use first time in file since some files just have one time
    ALLOCATE ( dum2d ( nxm, nym ) )
      CALL get_var_2d_real_cdf (cdfid, 'TC_URB',  dum2d, nxm, nym, it, rcode)
      IF ( ( rcode == nf_noerr ) .AND. ( MAXVAL(dum2d) > 100.0 ) ) THEN  ! UCM
        met_urban_phys = 1
      ELSE
        met_urban_phys = 0
      ENDIF
    DEALLOCATE ( dum2d )

  ENDIF

  met_snow_opt = 1  ! not used for WRF yet

!-------------------------------------------------------------------------------
! Extract WRF start date and time information.
!-------------------------------------------------------------------------------

  rcode = nf_get_att_text (cdfid, nf_global, 'SIMULATION_START_DATE', date_init)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'SIMULATION_START_DATE', rcode
    GOTO 1001
  ENDIF
  met_startdate =  date_init(1:19) // '.0000'
  met_startdate(11:11) = "-"  ! change from "_" to "-" for consistency

  rcode = nf_get_att_text (cdfid, nf_global, 'START_DATE', date_start)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'START_DATE', rcode
    GOTO 1001
  ENDIF

  IF ( date_init == date_start ) THEN
    met_restart = 0
  ELSE
    met_restart = 1
  ENDIF

  CALL get_times_cdf (cdfid, times, n_times, max_times, rcode)
  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'TIMES', rcode
    GOTO 1001
  ENDIF
  IF ( n_times > 1 ) THEN
    CALL geth_idts (times(2)(1:19), times(1)(1:19), idtsec)
  ELSE
    fl2 = file_mm(2)
    IF ( fl2(1:10) == '          ' ) THEN
      WRITE (6,9500)
      idtsec = 60
    ELSE
      rcode = nf_open (fl2, nf_nowrite, cdfid2)
      IF ( rcode == nf_noerr ) THEN
        CALL get_times_cdf (cdfid2, times2, n_times, max_times, rcode)
        IF ( rcode == nf_noerr ) THEN
          CALL geth_idts (times2(1)(1:19), times(1)(1:19), idtsec)
        ELSE
          WRITE (6,9400) 'TIMES2', rcode
          GOTO 1001
        ENDIF
      ELSE
        WRITE (6,9600) TRIM(fl2)
        GOTO 1001
      ENDIF
      rcode = nf_close (cdfid2)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9700) TRIM(fl2)
        GOTO 1001
      ENDIF
    ENDIF
  ENDIF
  met_tapfrq = REAL(idtsec / 60)  ! convert sec --> min

!-------------------------------------------------------------------------------
! Set variables for non-hydrostatic base state.  There is no option for
! hydrostatic run in WRF.  The base state variables are not currently output
! (as of WRFv2.2), so fill in "default" values from WRF namelist.
!
! Note:  In WRFv2.2 NCAR changed the way "real" scalars (e.g., P_TOP) are
!        stored in the WRF I/O API.
!-------------------------------------------------------------------------------

  IF ( (wrfversion(18:21) == "V2.2") .OR. (wrfversion(18:19) >= "V3") ) THEN
    CALL get_var_real2_cdf (cdfid, 'P_TOP', met_ptop, n_times,    rcode)
  ELSE
    CALL get_var_real_cdf  (cdfid, 'P_TOP', met_ptop, 1,       1, rcode)
  ENDIF

  IF ( rcode /= nf_noerr ) THEN
    WRITE (6,9400) 'P_TOP', rcode
    GOTO 1001
  ENDIF

  met_p00   = 100000.0 ! base state sea-level pressure [Pa]
  met_ts0   =    290.0 ! base state sea-level temperature [K]
  met_tlp   =     50.0 ! base state lapse rate d(T)/d(ln P) from 1000 to 300 mb
  met_tiso  = badval3  ! base state stratospheric isothermal T [K]  ! not used

!-------------------------------------------------------------------------------
! Determine WRF release.
!-------------------------------------------------------------------------------

  met_release = '        '

  IF ( wrfversion(18:18) == "V" ) THEN
    met_release(1:2) = wrfversion(18:19)
  ENDIF

  IF ( wrfversion(20:20) == '.' ) THEN
    met_release(3:4) = wrfversion(20:21)
  ENDIF

  IF ( wrfversion(22:22) == '.' ) THEN
    met_release(5:6) = wrfversion(22:23)
  ENDIF

  IF ( wrfversion(24:24) == '.' ) THEN
    met_release(7:8) = wrfversion(24:25)
  ENDIF

!-------------------------------------------------------------------------------
! Determine FDDA options.
!-------------------------------------------------------------------------------

  rcode = nf_get_att_int (cdfid, nf_global, 'GRID_FDDA', met_fdda_3dan)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_3dan = 0  ! not implemented until V2.2
    ELSE
      WRITE (6,9400) 'GRID_FDDA', rcode
      GOTO 1001
    ENDIF
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'GUV', met_fdda_gv3d)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_gv3d = -1.0  ! not in header until V2.2
    ELSE IF ( met_fdda_3dan == 0 ) THEN
      met_fdda_gv3d = -1.0  ! not in header if analysis nudging is off
    ELSE
      WRITE (6,9400) 'GUV', rcode
      GOTO 1001
    ENDIF
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'GT', met_fdda_gt3d)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_gt3d = -1.0  ! not in header until V2.2
    ELSE IF ( met_fdda_3dan == 0 ) THEN
      met_fdda_gt3d = -1.0  ! not in header if analysis nudging is off
    ELSE
      WRITE (6,9400) 'GT', rcode
      GOTO 1001
    ENDIF
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'GQ', met_fdda_gq3d)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_gq3d = -1.0  ! not in header until V2.2
    ELSE IF ( met_fdda_3dan == 0 ) THEN
      met_fdda_gq3d = -1.0  ! not in header if analysis nudging is off
    ELSE
      WRITE (6,9400) 'GQ', rcode
      GOTO 1001
    ENDIF
  ENDIF

  IF ( TRIM(met_release) >= 'V3.1' ) THEN  ! find sfc analysis nudging info

    rcode = nf_get_att_int (cdfid, nf_global, 'GRID_SFDDA', met_fdda_sfan)
    IF ( rcode /= nf_noerr ) THEN
      WRITE (6,9400) 'GRID_SFDDA', rcode
      GOTO 1001
    ENDIF

    IF ( met_fdda_sfan == 1 ) THEN

      rcode = nf_get_att_real (cdfid, nf_global, 'GUV_SFC', met_fdda_gvsfc)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9400) 'GUV_SFC', rcode
        GOTO 1001
      ENDIF

      rcode = nf_get_att_real (cdfid, nf_global, 'GT_SFC', met_fdda_gtsfc)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9400) 'GT_SFC', rcode
        GOTO 1001
      ENDIF

      rcode = nf_get_att_real (cdfid, nf_global, 'GQ_SFC', met_fdda_gqsfc)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9400) 'GQ_SFC', rcode
        GOTO 1001
      ENDIF

    ELSE

      met_fdda_gvsfc = -1.0
      met_fdda_gtsfc = -1.0
      met_fdda_gqsfc = -1.0

    ENDIF

  ELSE
    met_fdda_sfan  =  0  ! sfc analysis nudging not in WRF until V3.1
    met_fdda_gvsfc = -1.0
    met_fdda_gtsfc = -1.0
    met_fdda_gqsfc = -1.0
  ENDIF

  rcode = nf_get_att_int (cdfid, nf_global, 'OBS_NUDGE_OPT', met_fdda_obs)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_obs = 0  ! not implemented until V2.2
    ELSE
      WRITE (6,9400) 'OBS_NUDGE_OPT', rcode
      GOTO 1001
    ENDIF
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'OBS_COEF_WIND', met_fdda_giv)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_giv = -1.0  ! not in header until V2.2
    ELSE IF ( met_fdda_obs == 0 ) THEN
      met_fdda_giv = -1.0  ! not in header if obs nudging is off
    ELSE
      WRITE (6,9400) 'OBS_COEF_WIND', rcode
      GOTO 1001
    ENDIF
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'OBS_COEF_TEMP', met_fdda_git)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_git = -1.0  ! not in header until V2.2
    ELSE IF ( met_fdda_obs == 0 ) THEN
      met_fdda_git = -1.0  ! not in header if obs nudging is off
    ELSE
      WRITE (6,9400) 'OBS_COEF_TEMP', rcode
      GOTO 1001
    ENDIF
  ENDIF

  rcode = nf_get_att_real (cdfid, nf_global, 'OBS_COEF_MOIS', met_fdda_giq)
  IF ( rcode /= nf_noerr ) THEN
    IF ( TRIM(met_release) < 'V2.2' ) THEN
      met_fdda_giq = -1.0  ! not in header until V2.2
    ELSE IF ( met_fdda_obs == 0 ) THEN
      met_fdda_giq = -1.0  ! not in header if obs nudging is off
    ELSE
      WRITE (6,9400) 'OBS_COEF_MOIS', rcode
      GOTO 1001
    ENDIF
  ENDIF

!-------------------------------------------------------------------------------
! Determine whether or not fractional land use is available in the output.
! Set the flag appropriately.
!-------------------------------------------------------------------------------

  rcode = nf_inq_varid (cdfid, 'LANDUSEF', varid)
  IF ( rcode == nf_noerr ) THEN
    iflufrc    = .TRUE.  ! fractional land use is available
    ifluwrfout = .TRUE.  ! fractional land use is located in WRF history file
  ELSE
    ifluwrfout = .FALSE.  ! fractional land use is not available in WRF history
    geofile = TRIM( file_ter )
    INQUIRE ( FILE=geofile, EXIST=ifgeo )
    IF ( .NOT. ifgeo ) THEN
      WRITE (6,9800)
      iflufrc = .FALSE.
    ELSE
      flg = file_ter
      rcode = nf_open (flg, nf_nowrite, cdfidg)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9600) TRIM(flg)
        GOTO 1001
      ENDIF
      CALL chkwpshdr (flg, cdfidg)
      rcode = nf_inq_varid (cdfidg, 'LANDUSEF', varid)
      IF ( rcode == nf_noerr ) THEN
        iflufrc = .TRUE.  ! fractional land use is in the file
      ELSE
        iflufrc = .FALSE. ! fractional land use is not in the file
      ENDIF
      rcode = nf_close (cdfidg)
      IF ( rcode /= nf_noerr ) THEN
        WRITE (6,9700) TRIM(flg)
        GOTO 1001
      ENDIF
    ENDIF
  ENDIF

!-------------------------------------------------------------------------------
! Determine whether or not the 2-m temperature, the 2-m mixing ratio, the
! 10-m wind components, and the turbulent kinetic energy are in the output,
! and set the flags appropriately.
!-------------------------------------------------------------------------------

  rcode = nf_inq_varid (cdfid, 'T2', varid)
  IF ( rcode == nf_noerr ) THEN
    ift2m = .TRUE.  ! 2-m temperature is in the file
  ELSE
    ift2m = .FALSE. ! 2-m temperature is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'Q2', varid)
  IF ( rcode == nf_noerr ) THEN
    ifq2m = .TRUE.  ! 2-m mixing ratio is in the file
  ELSE
    ifq2m = .FALSE. ! 2-m mixing ratio is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'U10', varid)
  IF ( rcode == nf_noerr ) THEN
    ifu10m = .TRUE.  ! 10-m u-component wind is in the file
  ELSE
    ifu10m = .FALSE. ! 10-m u-component wind is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'V10', varid)
  IF ( rcode == nf_noerr ) THEN
    ifv10m = .TRUE.  ! 10-m v-component wind is in the file
  ELSE
    ifv10m = .FALSE. ! 10-m v-component wind is not in the file
  ENDIF

  IF ( ( ifu10m ) .AND. ( ifv10m ) ) THEN
    ifw10m = .TRUE.
  ELSE
    ifw10m = .FALSE.
  ENDIF

  rcode = nf_inq_varid (cdfid, 'TKE_MYJ', varid)
  IF ( rcode == nf_noerr ) THEN
    IF ( met_pbl == 2 ) THEN  ! Mellor-Yamada-Janjic (Eta)
      iftke  = .TRUE.  ! turbulent kinetic energy is in the file
      iftkef = .FALSE. ! TKE is not on full-levels; it is on half-layers
    ELSE
      iftke  = .FALSE. ! turbulent kinetic energy is not in the file
      iftkef = .FALSE.
    ENDIF
  ELSE
    iftke  = .FALSE. ! turbulent kinetic energy is not in the file
    iftkef = .FALSE.
  ENDIF

!-------------------------------------------------------------------------------
! Determine whether or not some surface variables are in the output, and set
! the flags appropriately.
!-------------------------------------------------------------------------------

  rcode = nf_inq_varid (cdfid, 'LAI', varid)
  IF ( rcode == nf_noerr ) THEN
    iflai = .TRUE.  ! leaf area index is in the file
  ELSE
    iflai = .FALSE. ! leaf area index is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'RMOL', varid)
  IF ( rcode == nf_noerr ) THEN
    ifmol = .TRUE.  ! (inverse) Monin-Obukhov length is in the file
  ELSE
    ifmol = .FALSE. ! (inverse) Monin-Obukhov length is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'RA', varid)
  IF ( rcode == nf_noerr ) THEN
    ifra = .TRUE.  ! aerodynamic resistance is in the file
  ELSE
    ifra = .FALSE. ! aerodynamic resistance is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'RS', varid)
  IF ( rcode == nf_noerr ) THEN
    ifrs = .TRUE.  ! stomatal resistance is in the file
  ELSE
    ifrs = .FALSE. ! stomatal resistance is not in the file
  ENDIF

  IF ( ( ifra ) .AND. ( ifrs ) ) THEN
    ifresist = .TRUE.
  ELSE
    ifresist = .FALSE.
  ENDIF

  rcode = nf_inq_varid (cdfid, 'VEGFRA', varid)
  IF ( rcode == nf_noerr ) THEN
    ifveg = .TRUE.  ! vegetation fraction is in the file
  ELSE
    ifveg = .FALSE. ! vegetation fraction is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'CANWAT', varid)
  IF ( rcode == nf_noerr ) THEN
    ifwr = .TRUE.  ! canopy wetness is in the file
  ELSE
    ifwr = .FALSE. ! canopy wetness is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'SMOIS', varid)
  IF ( rcode == nf_noerr ) THEN
    ifsmois = .TRUE.  ! soil moisture is in the file
  ELSE
    ifsmois = .FALSE. ! soil moisture is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'TSLB', varid)
  IF ( rcode == nf_noerr ) THEN
    iftslb = .TRUE.  ! soil temperature is in the file
  ELSE
    iftslb = .FALSE. ! soil temperature is not in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'ISLTYP', varid)
  IF ( rcode == nf_noerr ) THEN
    ifisltyp = .TRUE.  ! soil type is in the file
  ELSE
    ifisltyp = .FALSE. ! soil type is not in the file
  ENDIF

  If ( ( ifsmois ) .AND. ( iftslb ) .AND. ( ifisltyp ) ) THEN
    ifsoil = .TRUE.
  ELSE
    ifsoil = .FALSE.
  ENDIF

  rcode = nf_inq_varid (cdfid, 'ZNT', varid)
  IF ( rcode == nf_noerr ) THEN
    ifznt = .TRUE.  ! roughness length is in the file
  ELSE
    ifznt = .FALSE. ! roughness length is not in the file
  ENDIF

!-------------------------------------------------------------------------------
! Determine the number of 3D cloud moisture species.  Assume that cloud water
! mixing ratio and rain water mixing ratio will occur together.  Also assume
! that cloud ice mixing ratio and cloud snow mixing ratio will occur together,
! but check for availability.  Check for graupel, as well.
! Note:  In WRFv2.1.2 and prior, the Eta/Ferrier microphysics scheme only
! outputs QCLOUD which represents total condensate, not cloud water mixing
! ratio.  CMAQv4.6 and prior cannot handle this field, so MCIP will stop in
! this case.
!-------------------------------------------------------------------------------

  rcode = nf_inq_varid (cdfid, 'QCLOUD', varid)
  IF ( rcode == nf_noerr ) THEN
    nqspecies = 1  ! QCLOUD is in the file
  ELSE
    GOTO 8225  ! need hydrometeor fields for CMAQ
  ENDIF

  rcode = nf_inq_varid (cdfid, 'QRAIN', varid)
  IF ( rcode == nf_noerr ) THEN
    nqspecies = nqspecies + 1  ! QRAIN is in the file
  ELSE
    IF ( met_expl_moist == 5 ) THEN  ! Eta/Ferrier scheme
      GOTO 8250
    ELSE
      GOTO 8275
    ENDIF
  ENDIF

  rcode = nf_inq_varid (cdfid, 'QICE', varid)
  IF ( rcode == nf_noerr ) THEN
    nqspecies = nqspecies + 1  ! QICE is in the file
  ENDIF

  rcode = nf_inq_varid (cdfid, 'QSNOW', varid)
  IF ( rcode == nf_noerr ) THEN
    nqspecies = nqspecies + 1  ! QSNOW is in the file
  ENDIF

  IF ( nqspecies == 3 ) GOTO 8300  ! not set up for QI w/o QS or vice versa

  rcode = nf_inq_varid (cdfid, 'QGRAUP', varid)
  IF ( rcode == nf_noerr ) THEN
    nqspecies = nqspecies + 1  ! QGRAUP is in the file
  ENDIF

  IF ( nqspecies == 3 ) GOTO 8300  ! not set up for QG without QI and QS

  RETURN

!-------------------------------------------------------------------------------
! Format statements.
!-------------------------------------------------------------------------------

 6000 FORMAT (/, 1x, '- SUBROUTINE SETUP_WRFEM - READING WRF HEADER')
 6100 FORMAT (3x, 'WRF GRID DIMENSIONS (X,Y,Z) ', i4, 1x, i4, 1x, i3, //)

!-------------------------------------------------------------------------------
! Error-handling section.
!-------------------------------------------------------------------------------

 8000 WRITE (6,9000) dx, dy
      GOTO 1001

 8225 WRITE (6,9225)
      GOTO 1001

 8250 WRITE (6,9250)
      GOTO 1001

 8275 WRITE (6,9275)
      GOTO 1001

 8300 WRITE (6,9300)
      GOTO 1001

 9000 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   MISMATCH IN DX AND DY',                        &
              /, 1x, '***   DX, DY = ', 2(f7.2),                           &
              /, 1x, 70('*'))

 9100 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   UNKNOWN LAND USE CLASSIFICATION',              &
              /, 1x, '***   FIRST THREE LETTERS = ', a,                    &
              /, 1x, 70('*'))

 9225 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   QCLOUD NOT FOUND IN WRF OUTPUT...STOPPING',    &
              /, 1x, 70('*'))

 9250 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   ETA/FERRIER SCHEME HAS TOTAL CONDENSATE IN',   &
              /, 1x, '***   QCLOUD RATHER THAN CLOUD WATER MIXING RATIO.', &
              /, 1x, '***   CMAQ NEEDS QC AND QR AS MIXING RATIOS AND ',   &
              /, 1x, '***   IS NOT SET UP FOR TOTAL CONDENSATE.',          &
              /, 1x, '***   PLEASE SELECT A DIFFERENT MP_PHYSICS OPTION',  &
              /, 1x, '***   IN WRF AND RE-RUN.  SORRY...',                 &
              /, 1x, 70('*'))

 9275 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   FOUND QCLOUD BUT NOT QRAIN...STOPPING',        &
              /, 1x, 70('*'))

 9300 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   NQSPECIES SET AT 3',                           &
              /, 1x, '***   MCIP NEEDS TO BE MODIFIED FOR THIS CASE',      &
              /, 1x, 70('*'))

 9400 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   ERROR RETRIEVING VARIABLE FROM WRF FILE',      &
              /, 1x, '***   VARIABLE = ', a,                               &
              /, 1x, '***   RCODE = ', i3,                                 &
              /, 1x, 70('*'))

 9500 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   ERROR SETTING OUTPUT FREQUENCY FROM WRF FILE', &
              /, 1x, '***   ONLY FOUND ONE FILE WITH ONE TIME PERIOD',     &
              /, 1x, '***   SETTING OUTPUT FREQUENCY TO 1 MINUTE',         &
              /, 1x, 70('*'))

 9600 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   ERROR OPENING WRF NETCDF FILE',                &
              /, 1x, '***   FILE = ', a,                                   &
              /, 1x, 70('*'))

 9700 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   ERROR CLOSING WRF NETCDF FILE',                &
              /, 1x, '***   FILE = ', a,                                   &
              /, 1x, 70('*'))

 9800 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: SETUP_WRFEM',                        &
              /, 1x, '***   DID NOT FIND FRACTIONAL LAND USE IN wrfout',   &
              /, 1x, '***   AND DID NOT FIND GEOGRID FILE'                 &
              /, 1x, '***   -- WILL NOT USE FRACTIONAL LAND USE DATA'      &
              /, 1x, 70('*'))

 1001 CALL graceful_stop (pname)
      RETURN

END SUBROUTINE setup_wrfem