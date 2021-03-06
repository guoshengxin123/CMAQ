
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!
 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! The Reaction Rates File
! 
! Generated by KPP-2.2.3 symbolic chemistry Kinetics PreProcessor
!       (http://www.cs.vt.edu/~asandu/Software/KPP)
! KPP is distributed under GPL, the general public licence
!       (http://www.gnu.org/copyleft/gpl.html)
! (C) 1995-1997, V. Damian & A. Sandu, CGRER, Univ. Iowa
! (C) 1997-2005, A. Sandu, Michigan Tech, Virginia Tech
!     With important contributions from:
!        M. Damian, Villanova University, USA
!        R. Sander, Max-Planck Institute for Chemistry, Mainz, Germany
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



MODULE aqchem_Rates

  USE aqchem_Parameters
  USE aqchem_Global
  IMPLICIT NONE

CONTAINS



! Begin Rate Law Functions from KPP_HOME/util/UserRateLaws

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!  User-defined Rate Law functions
!  Note: the default argument type for rate laws, as read from the equations file, is single precision
!        but all the internal calculations are performed in double precision
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!~~~>  Arrhenius
   REAL(kind=dp) FUNCTION ARR( A0,B0,C0 )
      REAL A0,B0,C0      
      ARR =  DBLE(A0) * EXP(-DBLE(B0)/TEMP) * (TEMP/300.0_dp)**DBLE(C0)
   END FUNCTION ARR        

!~~~> Simplified Arrhenius, with two arguments
!~~~> Note: The argument B0 has a changed sign when compared to ARR
   REAL(kind=dp) FUNCTION ARR2( A0,B0 )
      REAL A0,B0           
      ARR2 =  DBLE(A0) * EXP( DBLE(B0)/TEMP )              
   END FUNCTION ARR2          

   REAL(kind=dp) FUNCTION EP2(A0,C0,A2,C2,A3,C3)
      REAL A0,C0,A2,C2,A3,C3
      REAL(kind=dp) K0,K2,K3            
      K0 = DBLE(A0) * EXP(-DBLE(C0)/TEMP)
      K2 = DBLE(A2) * EXP(-DBLE(C2)/TEMP)
      K3 = DBLE(A3) * EXP(-DBLE(C3)/TEMP)
      K3 = K3*CFACTOR*1.0E6_dp
      EP2 = K0 + K3/(1.0_dp+K3/K2 )
   END FUNCTION EP2

   REAL(kind=dp) FUNCTION EP3(A1,C1,A2,C2) 
      REAL A1, C1, A2, C2
      REAL(kind=dp) K1, K2      
      K1 = DBLE(A1) * EXP(-DBLE(C1)/TEMP)
      K2 = DBLE(A2) * EXP(-DBLE(C2)/TEMP)
      EP3 = K1 + K2*(1.0E6_dp*CFACTOR)
   END FUNCTION EP3 

   REAL(kind=dp) FUNCTION FALL ( A0,B0,C0,A1,B1,C1,CF)
      REAL A0,B0,C0,A1,B1,C1,CF
      REAL(kind=dp) K0, K1     
      K0 = DBLE(A0) * EXP(-DBLE(B0)/TEMP)* (TEMP/300.0_dp)**DBLE(C0)
      K1 = DBLE(A1) * EXP(-DBLE(B1)/TEMP)* (TEMP/300.0_dp)**DBLE(C1)
      K0 = K0*CFACTOR*1.0E6_dp
      K1 = K0/K1
      FALL = (K0/(1.0_dp+K1))*   &
           DBLE(CF)**(1.0_dp/(1.0_dp+(LOG10(K1))**2))
   END FUNCTION FALL

  !---------------------------------------------------------------------------

  ELEMENTAL REAL(kind=dp) FUNCTION k_3rd(temp,cair,k0_300K,n,kinf_300K,m,fc)

    INTRINSIC LOG10

    REAL(kind=dp), INTENT(IN) :: temp      ! temperature [K]
    REAL(kind=dp), INTENT(IN) :: cair      ! air concentration [molecules/cm3]
    REAL, INTENT(IN) :: k0_300K   ! low pressure limit at 300 K
    REAL, INTENT(IN) :: n         ! exponent for low pressure limit
    REAL, INTENT(IN) :: kinf_300K ! high pressure limit at 300 K
    REAL, INTENT(IN) :: m         ! exponent for high pressure limit
    REAL, INTENT(IN) :: fc        ! broadening factor (usually fc=0.6)
    REAL(kind=dp) :: zt_help, k0_T, kinf_T, k_ratio

    zt_help = 300._dp/temp
    k0_T    = k0_300K   * zt_help**(n) * cair ! k_0   at current T
    kinf_T  = kinf_300K * zt_help**(m)        ! k_inf at current T
    k_ratio = k0_T/kinf_T
    k_3rd   = k0_T/(1._dp+k_ratio)*fc**(1._dp/(1._dp+LOG10(k_ratio)**2))

  END FUNCTION k_3rd

  !---------------------------------------------------------------------------

  ELEMENTAL REAL(kind=dp) FUNCTION k_arr (k_298,tdep,temp)
    ! Arrhenius function

    REAL,     INTENT(IN) :: k_298 ! k at T = 298.15K
    REAL,     INTENT(IN) :: tdep  ! temperature dependence
    REAL(kind=dp), INTENT(IN) :: temp  ! temperature

    INTRINSIC EXP

    k_arr = k_298 * EXP(tdep*(1._dp/temp-3.3540E-3_dp)) ! 1/298.15=3.3540e-3

  END FUNCTION k_arr

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!  End of User-defined Rate Law functions
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

! End Rate Law Functions from KPP_HOME/util/UserRateLaws


! Begin INLINED Rate Law Functions


      REAL( kind=dp )FUNCTION DISF ( KEQ, DH, KB, G1 )

            IMPLICIT NONE
       
            REAL( kind=dp ) DH, KEQ, KB
            INTEGER  G1
     
            DISF = KB * ( KEQ * EXP( DH * DELINVT ) )
            IF( G1 .eq. 1 ) DISF = DISF * ( GM1 ) 
        
            RETURN
     
      END FUNCTION DISF 
      
      REAL( kind=dp )FUNCTION DISB ( KB, G1 )

            IMPLICIT NONE
       
            REAL( kind=dp ) KB
            INTEGER G1
       
            DISB = KB
            IF( G1 .eq. 1 ) DISB   = DISB * GM1 * GM2
            IF( G1 .eq. 2 ) DISB   = DISB * GM1 * GM1
            DISB = DISB * PHI2     
             
            RETURN
     
      END FUNCTION DISB

      REAL( kind=dp )FUNCTION KRXN ( KR, DH, RTYPE, QY, METAL )

            IMPLICIT NONE
       
            REAL( kind=dp ) KR, DH
            REAL( kind=dp ) Q, q1, COTHq, SVIinh
            REAL( kind=dp ) kO31, kO32, kO33, kO3T
            INTEGER QY, RTYPE, METAL
        
            SVIinh = 1.0D0 + 75.0D0 * ((VAR(ind_L_H2SO4) &
                   + VAR(ind_L_HSO4MIN) + VAR(ind_L_SO4MIN2)) &
                   * PHI2)**0.67D0 !SO4 inhibition of metal catalysis

            KRXN = KR * EXP( DH * DELINVT)
     
            IF ( RTYPE .EQ. 1 ) THEN   ! SO2 - H2O2 OXIDATION
               KRXN = (KRXN / (1.0D0 + 13.0D0*VAR(ind_L_HPLUS) * PHI2)) * PHI2
!           ELSE IF ( RTYPE .EQ. 2 ) then   ! SO2 - PAA OXIDATION
!              KRXN = KRXN * (VAR(ind_L_HPLUS) * PHI2) + 7.00D2  
            ELSE IF ( RTYPE .EQ. 3 ) then   ! SO2 - Fe3/Mn2 synergism and 
               KRXN = KRXN * PHI2           ! MHP and PAA reaction
            ELSE IF ( RTYPE .EQ. 4 ) then   ! only one reactant
               KRXN = KRXN / PHI2     
            END IF
       
            IF (METAL .GT. 0) KRXN = KRXN / SVIinh  !SO4 inhibition only for 
                                                    !metal-catalyzed oxidation

!           Ionic strength impact on SIV-O3 reaction rate       
!                 IF (QY .GT. 0) THEN
!                    KRXN = KRXN * (1.0D0 + 2.5 * STION)
!                 END IF       

!           Aqueous diffusion limitation for O3

            q1 = 0.0D0
            Q = 1.0D0
    
            IF( QY .GE. 1 ) THEN    
       
               kO31 = 2.4D+4 * EXP( 0.0D0 * DELINVT)
               kO32 = 3.7D+5 * EXP( -5530.88D0 * DELINVT)
               kO33 = 1.5D+9 * EXP( -5280.56D0 * DELINVT)
               kO3T = ( kO31 * VAR( ind_L_SO2 ) + kO32 &
                    * VAR( ind_L_HSO3MIN ) &
                    + kO33 * VAR( ind_L_SO3MIN2 ) ) * PHI2

               IF(kO3T .LT. 0.d0) THEN
	          q1 = 0.d0
	       ELSE	
                  q1 = DDIAM / 2.0D0 * SQRT( kO3T / DAQ )  ! diffuso-reactive parameter  
	       END IF

               IF ( q1 .GT. 1.0D-3 ) THEN
                  IF ( q1 .LE. 100.0D0 ) THEN
                     COTHq = ( EXP( 2 * q1 ) + 1 ) / ( EXP( 2 * q1 ) - 1 )
                     Q = 3 * ( ( COTHq / q1 ) - ( 1 / ( q1 * q1 ) ) )
                     IF ( Q .GT. 1.0D0 ) Q = 1.0D0
                  ELSE
                     Q = 3.d0/q1
                  END IF
               ELSE
                  Q = 1.0D0
               END IF
       
               KRXN = KRXN * Q 
    
            END IF      
      
            KRXN = KRXN * PHI2
       
            RETURN
     
      END FUNCTION KRXN
      
REAL( kind=dp )FUNCTION KIEPOX ( KH, KHSO4, TYPE )

            IMPLICIT NONE
      
            REAL( kind=dp ) KH, KHSO4
            REAL( kind=dp ) K1, K2
            REAL( kind=dp ) KIEPOXT, KMAET
            REAL( kind=dp ) Q, q1, COTHq
            INTEGER TYPE
    
            IF( ISPC8 .LE. 0 ) THEN
               IF( TYPE .GT. 0 ) THEN
                  KIEPOX = 0.d0
                  RETURN
               END IF
            ELSE
               IF( TYPE .LT. 1 ) THEN
                  KIEPOX = 0.d0
                  RETURN
               END IF
            END IF
        
            K1 = KH * VAR( ind_L_HPLUS ) * PHI2
            K2 = KHSO4 * VAR( ind_L_HSO4MIN ) * PHI2
        
            KIEPOX = K1 + K2 
!
! Aqueous diffusion limitation for IEPOX and MAE
!
!
            q1 = 0.0D0
            Q = 1.0D0

            IF( TYPE .le. 1 ) THEN   ! FOR IEPOX

               K1 = 9.0D-4 * VAR( ind_L_HPLUS ) * PHI2
               K2 = 1.31D-5 * VAR( ind_L_HSO4MIN ) * PHI2        
               KIEPOXT = (K1 + K2) * FIX( indf_L_H2O ) * PHI2  ! IEPOX + H2O
        
               K1 = 8.83D-3 * VAR( ind_L_HPLUS ) * PHI2  
               K2 = 2.92D-6 * VAR( ind_L_HSO4MIN ) * PHI2        
               KIEPOXT = KIEPOXT + (K1 + K2) * VAR( ind_L_SO4MIN2 ) &
                       * PHI2  ! IEPOX + SO4
                                  
               K1 = 2.0D-4 * VAR( ind_L_HPLUS ) * PHI2
               K2 = 2.92D-6 * VAR( ind_L_HSO4MIN ) * PHI2  
                             
               IF( ISPC8 .LE. 0 ) THEN
                  KIEPOXT = KIEPOXT + (K1 + K2) * VAR( ind_L_NO3MIN ) * PHI2    
               ELSE
                  KIEPOXT = KIEPOXT + (K1 + K2) * VAR( ind_L_IETET ) &
                          * PHI2    ! IEPOX + IETET
                  KIEPOXT = KIEPOXT + (K1 + K2) * VAR( ind_L_IEOS ) &
                          * PHI2     ! IEPOX + IEOS
               ENDIF
	       
	       IF(KIEPOXT .LT. 0.d0) THEN
	          q1 = 0.d0
	       ELSE	
                  q1 = DDIAM/2.0D0 * SQRT( KIEPOXT / DAQ )  ! diffuso-reactive parameter  
	       END IF
       
               IF ( q1 .GT. 1.0D-3 ) THEN
                  IF ( q1 .LE. 100.0D0 ) THEN
                     COTHq = ( EXP( 2 * q1 ) + 1 ) / ( EXP( 2 * q1 ) - 1 )
                     Q = 3 * ( ( COTHq / q1 ) - ( 1 / ( q1 * q1 ) ) )
                     IF ( Q .GT. 1.0D0 ) Q = 1.0D0
                  ELSE
                     Q = 3.d0/q1
                  END IF
               ELSE
                  Q = 1.0D0
               END IF             
     
            ELSE   ! FOR MAE OR HMML

               K1 = 9.0D-4 * VAR( ind_L_HPLUS ) * PHI2
               K2 = 1.31D-5 * VAR( ind_L_HSO4MIN ) * PHI2        
               KMAET = (K1 + K2) * FIX( indf_L_H2O ) &
                     * PHI2  ! MAE/HMML + H2O
    
               K1 = 2.0D-4 * VAR( ind_L_HPLUS ) * PHI2
               K2 = 2.92D-6 * VAR( ind_L_HSO4MIN ) * PHI2        
               KMAET = KMAET + (K1 + K2) * VAR( ind_L_SO4MIN2 ) &
                     * PHI2  ! MAE/HMML + SO4
	       
	       IF(KMAET .LT. 0.d0) THEN
	          q1 = 0.d0
	       ELSE	
                  q1 = DDIAM/2.0D0 * SQRT( KMAET / DAQ )  ! diffuso-reactive parameter  
	       END IF

               IF ( q1 .GT. 1.0D-3 ) THEN
                  IF ( q1 .LE. 100.0D0 ) THEN
                     COTHq = ( EXP( 2 * q1 ) + 1 ) / ( EXP( 2 * q1 ) - 1 )
                     Q = 3 * ( ( COTHq / q1 ) - ( 1 / ( q1 * q1 ) ) )
                     IF ( Q .GT. 1.0D0 ) Q = 1.0D0
                  ELSE
                     Q = 3.d0/q1
                  END IF
               ELSE
                  Q = 1.0D0
               END IF       
            END IF
     
            KIEPOX = KIEPOX * Q     
       
            KIEPOX = KIEPOX * PHI2  
       
            RETURN
     
END FUNCTION KIEPOX      


! End INLINED Rate Law Functions

! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! Update_SUN - update SUN light using TIME
!   Arguments :
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  SUBROUTINE Update_SUN()
      !USE aqchem_Parameters
      !USE aqchem_Global

    IMPLICIT NONE

    REAL(kind=dp) :: SunRise, SunSet
    REAL(kind=dp) :: Thour, Tlocal, Ttmp 
    ! PI - Value of pi
    REAL(kind=dp), PARAMETER :: PI = 3.14159265358979d0
    
    SunRise = 4.5_dp 
    SunSet  = 19.5_dp 
    Thour = TIME/3600.0_dp 
    Tlocal = Thour - (INT(Thour)/24)*24

    IF ((Tlocal>=SunRise).AND.(Tlocal<=SunSet)) THEN
       Ttmp = (2.0*Tlocal-SunRise-SunSet)/(SunSet-SunRise)
       IF (Ttmp.GT.0) THEN
          Ttmp =  Ttmp*Ttmp
       ELSE
          Ttmp = -Ttmp*Ttmp
       END IF
       SUN = ( 1.0_dp + COS(PI*Ttmp) )/2.0_dp 
    ELSE
       SUN = 0.0_dp 
    END IF

 END SUBROUTINE Update_SUN

! End of Update_SUN function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! Update_RCONST - function to update rate constants
!   Arguments :
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SUBROUTINE Update_RCONST ( )




! Begin INLINED RCONST


      STION = 0.5D0  &
            * ( VAR( ind_L_HPLUS ) + VAR( ind_L_NH4PLUS ) &
            + VAR( ind_L_OHMIN )  &
            + VAR( ind_L_HCO3MIN ) + VAR( ind_L_O2MIN ) &
            + VAR( ind_L_NO2MIN ) &
            + VAR( ind_L_NO4MIN ) + VAR( ind_L_GLYACMIN ) &
            + VAR( ind_L_OXLACMIN ) &
            + VAR( ind_L_PYRACMIN ) + VAR( ind_L_GCOLACMIN ) &
            + VAR( ind_L_CCOOHMIN ) &
            + VAR( ind_L_HSO3MIN ) + VAR( ind_L_HCOOMIN ) &
            + VAR( ind_L_NO3MIN ) &
            + VAR( ind_L_HSO4MIN ) + VAR( IND_L_HMSMIN)  &
            + VAR( ind_L_NAPLUS ) + VAR( ind_L_KPLUS ) + VAR( ind_L_CLMIN ) &
            + VAR( ind_L_SO4MIN ) + VAR( ind_L_SO3MIN ) + &
            + VAR( ind_L_HMSMIN ) + VAR( ind_L_SO5MIN ) + &
            + VAR( ind_L_HSO5MIN ) + VAR( ind_L_CO2MIN ) + &
            + 3.0D0 * VAR( ind_L_FEPLUS3 ) + 2.0D0 * VAR( ind_L_MNPLUS2 ) &
            + 4.0D0 * ( VAR( ind_L_SO4MIN2 ) + VAR( ind_L_CO3MIN2 ) &
            + VAR( ind_L_OXLACMIN2 ) &
            + VAR( ind_L_SO3MIN2 ) + VAR( ind_L_MNPLUS2 ) &
            + VAR( ind_L_CAPLUS2 ) &
            + VAR( ind_L_MGPLUS2 ) ) &
            + 9.0D0 * VAR( ind_L_FEPLUS3 ) ) * PHI2 !includes anions for 
                                                    !Fe3+ and Mn2+    
            
      GM1LOG = -0.509D0 * ( SQRT( STION ) &
             / ( 1.0D0 + SQRT( STION ) ) - 0.2D0 * STION )
      GM2LOG = GM1LOG * 4.0D0
      GM1    = 10.0D0**GM1LOG
      GM2    = MAX( 10.0D0**GM2LOG, 1.0d-30 )  


! End INLINED RCONST

  RCONST(41) = ((DISF(1.39D-02,1.87D+03,2.0D8,0)))
  RCONST(42) = ((DISF(6.72D-08,3.55D+02,5.0D10,1)))
  RCONST(43) = ((DISF(1.7D+01,0.0D0,5.0D10,0)))
  RCONST(44) = ((DISF(4.30D-07,-9.95D+02,6.4D4,0)))
  RCONST(45) = ((DISF(4.68D-11,-1.785D+03,5.0D10,1)))
  RCONST(46) = ((DISF(1.77D-5,-7.10D+02,3.4D10,0)))
  RCONST(47) = ((DISF(1.80D-4,-2.00D+01,5.0D10,0)))
  RCONST(48) = ((DISF(1.74D+06,6.89D+03,5.0D10,0)))
  RCONST(49) = ((DISF(1.80D-16,-6.955D+03,1.4D11,0)))
  RCONST(50) = ((DISF(1000.0D0,0.0D0,5.0D10,0)))
  RCONST(51) = ((DISF(1.02D-2,2.445D+03,1.0D11,1)))
  RCONST(52) = ((DISF(1.6D-5,0.0D0,5.0D10,0)))
  RCONST(53) = ((DISF(5.3D-4,-1760.D0,5.0D10,0)))
  RCONST(54) = ((DISF(1.0D-5,0.D0,5.0D10,0)))
  RCONST(55) = ((DISB(2.0D8,2)))
  RCONST(56) = ((DISB(5.0D10,1)))
  RCONST(57) = ((DISB(5.0D10,2)))
  RCONST(58) = ((DISB(6.4D4,2)))
  RCONST(59) = ((DISB(5.0D10,1)))
  RCONST(60) = ((DISB(3.4D10,2)))
  RCONST(61) = ((DISB(5.0D10,2)))
  RCONST(62) = ((DISB(5.0D10,2)))
  RCONST(63) = ((DISB(1.4D11,2)))
  RCONST(64) = ((DISB(5.0D10,2)))
  RCONST(65) = ((DISB(1.0D11,1)))
  RCONST(66) = ((DISB(5.0D10,2)))
  RCONST(67) = ((DISB(5.0D10,2)))
  RCONST(68) = ((DISB(5.0D10,2)))
  RCONST(69) = ((KRXN(7.45D+7,-4756.08D0,1,0,0)))
  RCONST(70) = ((KRXN(2.4D+4,0.0D0,0,1,0)))
  RCONST(71) = ((KRXN(3.7D+5,-5530.88D0,0,2,0)))
  RCONST(72) = ((KRXN(1.5D+9,-5280.56D0,0,3,0)))
  RCONST(73) = ((KRXN(750.D0,0.0D0,0,0,1)))
  RCONST(74) = ((KRXN(750.D0,0.0D0,0,0,1)))
  RCONST(75) = ((KRXN(750.D0,0.0D0,0,0,1)))
  RCONST(76) = ((KRXN(2600.D0,0.0D0,0,0,1)))
  RCONST(77) = ((KRXN(2600.D0,0.0D0,0,0,1)))
  RCONST(78) = ((KRXN(2600.D0,0.0D0,0,0,1)))
  RCONST(79) = ((KRXN(1.0D10,0.0D0,3,0,1)))
  RCONST(80) = ((KRXN(1.0D10,0.0D0,3,0,1)))
  RCONST(81) = ((KRXN(1.0D10,0.0D0,3,0,1)))
  RCONST(82) = ((KRXN(1.90D+07,-3799.5D0,3,0,0)))
  RCONST(83) = ((KRXN(3.60D+07,-3999.2D0,3,0,0)))
  RCONST(84) = ((KRXN(7.0D+02,0.0D0,0,0,0)))
  RCONST(85) = ((KRXN(8.3D5,-2700.D0,0,0,0)))
  RCONST(86) = ((KRXN(9.6D7,-910.D0,0,0,0)))
  RCONST(87) = ((KRXN(1.5D9,-1500.D0,0,0,0)))
  RCONST(88) = ((KRXN(2.0D6,0.D0,0,0,0)))
  RCONST(89) = ((KRXN(2.0D6,0.D0,0,0,0)))
  RCONST(90) = ((KRXN(2.0D6,0.D0,0,0,0)))
  RCONST(91) = ((KRXN(3.3D5,0.D0,0,0,0)))
  RCONST(93) = ((KRXN(5.D5,-7000.D0,0,0,0)))
  RCONST(94) = ((KRXN(1.D10,0.D0,0,0,0)))
  RCONST(95) = ((KRXN(1.D10,0.D0,0,0,0)))
  RCONST(147) = ((KIEPOX(9.0D-4,1.31D-5,1)))
  RCONST(148) = ((KIEPOX(8.83D-3,2.92D-6,1)))
  RCONST(149) = ((KIEPOX(2.0D-4,2.92D-6,1)))
  RCONST(150) = ((KIEPOX(2.0D-4,2.92D-6,1)))
  RCONST(151) = ((KIEPOX(9.0D-4,1.31D-5,0)))
  RCONST(152) = ((KIEPOX(8.83D-3,2.92D-6,0)))
  RCONST(153) = ((KIEPOX(2.0D-4,2.92D-6,0)))
  RCONST(154) = ((KIEPOX(9.0D-4,1.31D-5,2)))
  RCONST(155) = ((KIEPOX(2.0D-4,2.92D-6,2)))
  RCONST(156) = ((KIEPOX(9.0D-4,1.31D-5,2)))
  RCONST(157) = ((KIEPOX(2.0D-4,2.92D-6,2)))
  RCONST(177) = ((DISF(3.47D-4,-2.67D+2,2.D+10,0)))
  RCONST(178) = ((DISF(5.6D-2,-4.53D+2,5.D+10,0)))
  RCONST(179) = ((DISF(5.42D-5,-8.05D+2,5.D+10,1)))
  RCONST(180) = ((DISF(3.2D-3,0.d0,2.D+10,0)))
  RCONST(181) = ((DISF(1.48D-4,-8.05D+1,2.D+10,0)))
  RCONST(182) = ((DISF(1.75D-5,4.6D+1,5.D+10,0)))
  RCONST(183) = ((DISB(2.D10,2)))
  RCONST(184) = ((DISB(5.D10,2)))
  RCONST(185) = ((DISB(5.D10,1)))
  RCONST(186) = ((DISB(2.D10,2)))
  RCONST(187) = ((DISB(2.D10,2)))
  RCONST(188) = ((DISB(5.D10,2)))
  RCONST(194) = ((KRXN(5.0D+8,0.D0,0,0,0)))
  RCONST(195) = ((KRXN(1.0D+9,0.D0,0,0,0)))
  RCONST(196) = ((KRXN(6.0D+8,0.D0,0,0,0)))
  RCONST(197) = ((KRXN(8.6D+8,0.D0,0,0,0)))
  RCONST(198) = ((KRXN(1.1D+9,-1516.D0,0,0,0)))
  RCONST(199) = ((KRXN(1.5D+8,0.D0,0,0,0)))
  RCONST(200) = ((KRXN(1.2D+9,0.D0,0,0,0)))
  RCONST(201) = ((KRXN(1.4D+6,0.D0,0,0,0)))
  RCONST(202) = ((KRXN(4.7D+7,0.D0,0,0,0)))
  RCONST(203) = ((KRXN(7.7D+6,0.D0,0,0,0)))
  RCONST(204) = ((KRXN(7.0D+8,0.D0,0,0,0)))
  RCONST(205) = ((KRXN(6.0D+7,0.D0,0,0,0)))
  RCONST(206) = ((KRXN(6.0D+7,0.D0,0,0,0)))
  RCONST(207) = ((KRXN(1.6D+7,0.D0,0,0,0)))
  RCONST(208) = ((KRXN(8.5D+7,0.D0,0,0,0)))
  RCONST(209) = ((KRXN(1.1D+9,-1020.D0,0,0,0)))
  RCONST(210) = ((KRXN(1.2D+8,-990.D0,0,0,0)))
  RCONST(211) = ((KRXN(1.1D+9,-1020.D0,0,0,0)))
  RCONST(233) = ((KRXN(3.6D+9,-930.D0,0,0,0)))
  RCONST(234) = ((KRXN(2.8D+10,0.D0,0,0,0)))
  RCONST(235) = ((KRXN(3.5D+10,-720.D0,0,0,0)))
  RCONST(236) = ((KRXN(3.2D+7,-1700.D0,0,0,0)))
  RCONST(237) = ((KRXN(2.7D+9,0.D0,0,0,0)))
  RCONST(238) = ((KRXN(1.8D+9,0.D0,0,0,0)))
  RCONST(239) = ((KRXN(4.5D+9,0.D0,0,0,0)))
  RCONST(240) = ((KRXN(2.6D-2,0.D0,4,0,0)))
  RCONST(241) = ((KRXN(1.0D+5,0.D0,0,0,0)))
  RCONST(242) = ((KRXN(1.3D+9,-2200.D0,0,0,0)))
  RCONST(243) = ((KRXN(1.1D+9,0.D0,0,0,0)))
  RCONST(244) = ((KRXN(1.7D+9,0.D0,0,0,0)))
  RCONST(245) = ((KRXN(2.2D+8,-2600.D0,0,0,0)))
  RCONST(246) = ((KRXN(7.1D+6,0.D0,3,0,0)))
  RCONST(247) = ((KRXN(4.6D+2,-1100.D0,0,0,0)))
  RCONST(248) = ((KRXN(1.7D+8,-2200.D0,0,0,0)))
  RCONST(249) = ((KRXN(5.0D+5,0.D0,0,0,0)))
  RCONST(250) = ((KRXN(3.4D+9,-1200.D0,0,0,0)))
  RCONST(251) = ((KRXN(7.9D+2,-2900.D0,0,0,0)))
  RCONST(252) = ((KRXN(2.5D+7,-2450.D0,0,0,0)))
  RCONST(253) = ((KRXN(7.7D-3,-9200.D0,4,0,0)))
  RCONST(254) = ((KRXN(3.7D3,0.D0,0,0,0)))
  RCONST(255) = ((KRXN(3.0D8,0.D0,0,0,0)))
  RCONST(256) = ((KRXN(7.9D+2,-2900.D0,0,0,0)))
  RCONST(257) = ((KRXN(2.5D+7,-2450.D0,0,0,0)))
  RCONST(258) = ((KRXN(7.7D-3,-9200.D0,4,0,0)))
  RCONST(259) = ((KRXN(3.7D3,0.D0,0,0,0)))
  RCONST(260) = ((KRXN(3.0D8,0.D0,0,0,0)))
      
END SUBROUTINE Update_RCONST

! End of Update_RCONST function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! Update_PHOTO - function to update photolytical rate constants
!   Arguments :
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SUBROUTINE Update_PHOTO ( )


   USE aqchem_Global

      
END SUBROUTINE Update_PHOTO

! End of Update_PHOTO function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



END MODULE aqchem_Rates

