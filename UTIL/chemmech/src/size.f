
C***************************************************************************
C  Significant portions of Models-3/CMAQ software were developed by        *
C  Government employees and under a United States Government contract.     *
C  Portions of the software were also based on information from non-       *
C  Federal sources, including software developed by research institutions  *
C  through jointly funded cooperative agreements. These research institu-  *
C  tions have given the Government permission to use, prepare derivative   *
C  works, and distribute copies of their work to the public within the     *
C  Models-3/CMAQ software release and to permit others to do so. EPA       *
C  therefore grants similar permissions for use of Models-3/CMAQ software, *
C  but users are requested to provide copies of derivative works to the    *
C  Government without re-strictions as to use by others.  Users are        *
C  responsible for acquiring their own copies of commercial software       *
C  associated with the Models-3/CMAQ release and are also responsible      *
C  to those vendors for complying with any of the vendors' copyright and   *
C  license restrictions. In particular users must obtain a Runtime license *
C  for Orbix from IONA Technologies for each CPU used in Models-3/CMAQ     *
C  applications.                                                           *
C                                                                          *
C  Portions of I/O API, PAVE, and the model builder are Copyrighted        *
C  1993-1997 by MCNC--North Carolina Supercomputing Center and are         *
C  used with their permissions subject to the above restrictions.          *
C***************************************************************************

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header$

C what(1) key, module and SID; SCCS file; date and time of last delta:
C @(#)SIZE.F	1.1 /project/mod3/MECH/src/driver/mech/SCCS/s.SIZE.F 02 Jan 1997 15:26:50

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      INTEGER FUNCTION SIZE ( LD, TR, CHAR )

C returns length of CHAR with leading blanks:   LD = 'LEADING', etc.
C returns length of CHAR with trailing blanks:  TR = 'TRAILING', etc.
C returns length of CHAR with leading and trailing blanks:  both
C returns length of CHAR minus leading and trailing blanks:  neither

      IMPLICIT NONE
      CHARACTER( * ) :: LD, TR, CHAR
      INTEGER START, FINI, INDX
      LOGICAL NO_LDNG, NO_TRLNG

      START = 1
      FINI = LEN( CHAR )
      NO_LDNG = .TRUE.
      NO_TRLNG = .TRUE.
      IF ( LD( 1:2 ) .EQ. 'LE' .OR.
     &     LD( 1:2 ) .EQ. 'le' .OR.
     &     LD( 1:2 ) .EQ. 'Le' ) NO_LDNG = .FALSE.
      IF ( TR( 1:2 ) .EQ. 'TR' .OR.
     &     TR( 1:2 ) .EQ. 'tr' .OR.
     &     TR( 1:2 ) .EQ. 'Tr' ) NO_TRLNG = .FALSE.

      IF ( NO_TRLNG ) THEN
         DO INDX = FINI, START, -1
            IF ( CHAR( INDX:INDX ) .NE. ' ' ) EXIT
         END DO
         FINI = INDX
      END IF
      IF ( NO_LDNG ) THEN
         DO INDX = 1, FINI
            IF ( CHAR( INDX:INDX ) .NE. ' ' ) EXIT
         END DO
         START = INDX
      END IF
      SIZE = FINI - START + 1

      RETURN
      END
