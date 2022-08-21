;.................................................................
;___________________________________________________________________
;___________________________________________________________________
;
      PRO ALEX1,ITAPERx,ITAPERy,ALPHA,Z,BZO,BXP,BYP,BZP,OBLIQUE,$
               LATI=LATI,LONGI=LONGI,BORDER=BORDER

      FORWARD_FUNCTION HANNG
;
;     PROGRAM:   ALEX
;     METHOD:    ALISSANDRAKIS FFT APPROACH TO CONSTANT ALPHA FORCE-FREE FIELDS
;                MATRIX VERSION
;     REFERENCE: C.E.ALISSANDRAKIS,1981, ASTRONOMY & ASTROPHSICS, VOL.100, PP.197-200.
;     PROGRAM:   G.ALLEN GARY/MSFC: IDL VERISON OF GAG FORTRAN PROGRAM DEVELOPED
;                                   FOR RECTANGULAR ARRAYS FOR EXVM ANALYSIS.
;
;     The parameters are:
;        ITAPER(X,Y) = the sizes of the Hanning boundary used
;        ALPHA       = the linear force-free field constant "alpha"
;        BZO         = the input photospheric longitudinal magentic field
;        BXP,BYP,BZP = the potential field components (OUTPUT)
;        OBLIQUE     = the variable set to 1 if off-disk center field of view are used
;        LATI,LONGI  = the latitude and longitude of the center of the field of view if Oblique ne 0
;        BORDER      = the border width used to place a border of zeros around the FOV
;                      (Note: Use even arrays or add appropriate border)
      IF OBLIQUE eq 1 then begin ; BZO is B-longitudinal
        phi=!dPI/2. - LATI*!DTOR      ;(northfrom Equator positive angle)
        theta=LONGi*!DTOR            ;(west from Central Meridian positive angle)
        CosA=sin(phi)*sin(theta)
        CosB=cos(phi)
        CosC=sin(phi)*cos(theta)
       ENDIF
      ;BZO=fltarr(NUMx,NUMy)
         Siz=SIZE(BZO)
         NUMx=Siz(1) & NUMy=Siz(2)
         Nxsav=NUMx  & Nysav=NUMy
   ;
   ;  BORDER APPLIED (to minimized effect of periodic boundary conditions/side walls)
        IF BORDER NE 0. THEN BEGIN
         BZO_save=BZO
         if itaperx*itapery ne 0 then BZO=HANNG(BZO,NUMx,NUMy,ITAPERx,ITAPERy)  ; SMOOTH EDGE TO ZERO VIA COSINE FUNCTION
         BZmod=Make_ARRAY(NUMx+2*BORDER,NUMy+2*BORDER,VALUE=0.0)
         BZmod(Border:Border+(NUMx-1),Border:Border+(NUMy-1))=BZO(0:(NUMx-1),0:(NUMy-1))
         BZO=BZmod
         Siz=SIZE(BZO) & NUMx=Siz(1) & NUMy=Siz(2)  ; reset size
        ENDIF
   ;
      BXP=dblarr(NUMx,NUMy)
      BYP=dblarr(NUMx,NUMy)
      BZP=dblarr(NUMx,NUMy)
     ;
      BZ=Dcomplexarr(NUMx,NUMy)
      BX=Dcomplexarr(NUMx,NUMy)
      BY=Dcomplexarr(NUMx,NUMy)
     ;
      LENGTHx=NUMx  ; Length scale set to 1.0
      LENGTHy=Numy
      Lx=NUMx
      Ly=NUMy
      FL2=Lx*Ly
;     SMOOTH EDGE TO ZERO VIA COSINE FUNCTION
      BZ=DCOMPLEX(BZO,0.)
      if border eq 0 AND itaperx*itapery ne 0 then BZ=HANNG(BZ,Lx,Ly,ITAPERx,ITAPERy)
;
;     REQUIRE TOTAL FLUX TO ZERO of oblique is set to -1
      if oblique eq -1 then begin
      BAVG=TOTAL(double(BZ))
      BZ=BZ-dcomplex(BAVG/FL2,0.)
      endif
;

;     **FOURIER TRANSFORM PROCEDURE FOR LINEAR FORCE-FREE FIELD EQUATIONS**
;
;
;     FAST FOURIER TRANSFORM OF BZ(0)
      BZ=FFT(BZ,-1,/Double,/Overwrite) ;1/N normal factor for -1(Inv) only; CALL FOURT(BZ,NN,2,-1,1,0)
;
;
;     FREQUENCY DOMAIN VARIABLES
      V=dblarr(NUMx,NUMy)
      U=dblarr(NUMx,NUMy)
;
;     Note: Reference E. Oran Brigham, The Fast Fourier Transform,
;                                      Prentice-Hall, Inc., 1974
;                     Chapter 9: Applying The Discrete Fourier Transform (p. 132)
;                     The discrete transform of G must be symmetrical about the
;                     midpoint of the array size and since the function G is real
;                     the real part of G-transform is even and
;                     the imaginary part of G-transform is odd
;
;
      Vp=dindgen(Ly)/LENGTHy
      RVp=REVERSE(Vp)
      IHALFy=Ly/2.                       ; Implies even values of Ly,Lx
      Vp(Ihalfy+1:Ly-1)=-RVp(Ihalfy:Ly-1-1)
      ;Vp(Ihalfy)=0.0
      For I=0,NUMx-1 Do  V(I,*)=VP(*)    ; The transform space of x - frequency domain
;
      Up=dindgen(Lx)/LENGTHx
      RUp=REVERSE(Up)
      IHALFx=Lx/2.
      Up(Ihalfx+1:Lx-1)=-RUp(Ihalfx:Lx-1-1)
      ;Up(Ihalfx)=0.0
      For J=0,NUMy-1 Do  U(*,J)=UP(*)    ; The transform space of x - frequency domain


;
         GX=Make_array(Value=dcomplex(0.,0.),Lx,Ly)  ; TRANSFORMED GREEN'S FUNCTIONS
         GY=Make_array(Value=dcomplex(0.,0.),Lx,Ly)
         GZ=Make_array(Value=dcomplex(1.,0.),Lx,Ly)
;
            Q=SQRT(U^2+V^2)
               Zero_index=WHERE( Q eq 0.)
               Q(Zero_index)=1.0
            PQ2=2.*!dPI*Q^2
            FK2=4.*!dPI^2*Q^2-ALPHA^2
            
            if min(fk2) le 0. then begin
                print, "!!!!! error: check the range of alpha !!!!"
                stop
            endif

            ;print,'zero indices=', zero_index
  ;
  ;         PHYSICAL FIELDS (Alpha small)
              Small=Where(FK2 GE 0.,count)
             If count gt 0 then begin
              FK=SQRT(FK2(small))                     ; the "k" variable
              FKs=FK
              GZ(small)=dcomplex(EXP(-FKs*Z),0.)
              GY(small)=dcomplex(-(V(small)*FKs+U(small)*ALPHA)/PQ2(small),0.)
              GY(small)=GY(small)*GZ(small)
              GY(small)=GY(small)*dcomplex(0.,1.)  ; multibly by complex-i
              GX(small)=dcomplex(-(U(small)*FKs-V(small)*ALPHA)/PQ2(small),0.)
              GX(small)=GX(small)*GZ(small)
              GX(small)=GX(small)*dcomplex(0.,1.)  ; multibly by complex-i
             Endif

;           UNPHYSICAL COMPLEX FIELDS (Alpha too large)
              large=Where(FK2 LT 0.,count)
              ;if count gt 0 then print, 'large count:', count
             if count gt 0 then begin
              GAMMA=SQRT(-FK2(large))
              UG=U(large)*GAMMA
              VG=V(large)*GAMMA
              AG=ALPHA*GAMMA
              ZG=Z*GAMMA
              SZ=SIN(ZG)
              CZ=COS(ZG)
              VA=V(large)*ALPHA
              UA=U(large)*ALPHA
              ;C=0.001
              C=0.0
              GX(large)=dcomplex(-((UG*SZ-VA*CZ)-C*(UG*CZ+VA*SZ))/PQ2(large),0.)
              GX(large)=GX(large)*dcomplex(0.,1.)
              GY(large)=dcomplex(-((VG*SZ+UA*CZ)-C*(VG*CZ-UA*SZ))/PQ2(large),0.)
              GY(large)=GY(large)*dcomplex(0.,1.)
              GZ(large)=dcomplex(CZ+C*SZ,0.)
              ;;;; discard the large scale solution
              ;BZ(large)=dcomplex(0.0, 0.0)
              ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ENDIF
;
            IF Oblique eq 1 then begin
;              FOR OBLIQUE OBSERVATION WE HAVE THE FOLLOWING EQNS.
;              Bzo' = Bl/( a Gxo' + b Gyo' + c Gzo' )
;              WHERE a,b,c ARE DIRECTIONAL COSINE
               GZinv=EXP(FK*Z) ; Correction Needed if Z ne 0
               BZ= BZ/( CosA*GX*GZinv + CosB*GY*GZinv + CosC*GZ*GZinv)
            ENDIF
;
         GX(zero_index)=dcomplex(0.,0.)
         GY(zero_index)=dcomplex(0.,0.)
         GZ(zero_index)=dcomplex(1.,0.)

           BX=GX*BZ   ; Bz= Transform of BZ(Z=0)
           BY=GY*BZ
           BZ=(GZ)*BZ
;
;     TRANSFORM INVERSE
;
      Bx=FFT(Bx,/Inverse,/Double,/Overwrite)
      By=FFT(By,/Inverse,/Double,/Overwrite)
      Bz=FFT(BZ,/Inverse,/Double,/Overwrite)
;
      BXP=double(BX)
      BYP=double(BY)
      BZP=double(BZ)
;
      IF BORDER NE 0. THEN BEGIN ; Reset array back to original size
      BZO=BZO_save
      BXP=REFORM(double(BX(Border:(Border+Nxsav-1),Border:(Border+Nysav-1)) ),Nxsav,Nysav)
      BYP=REFORM(double(BY(Border:(Border+Nxsav-1),Border:(Border+Nysav-1)) ),Nxsav,Nysav)
      BZP=REFORM(double(BZ(Border:(Border+Nxsav-1),Border:(Border+Nysav-1)) ),Nxsav,Nysav)
      ENDIF
;
      RETURN
      END
;..................................
;________________________________________________________________________________________

      Function HANNG,BZ,Lx,Ly,LDx,LDy
;     FUNCTION TO SMOOTH EDGE OF ARRAY TO
;     ZERO TO INSURE PERIODIC BOUNDARY CONDITION
      ; LD = number of elements in taper [X,Y]
      ; L  = number of elements (0:L-1)  [X,Y]
      ; BZ=Dcomplexarr(Lx,Ly)
       BZT=BZ
       Qix=dindgen(LDx)
       X=0.5*(1.0-COS(QIx*!dPI/LDx))
       Qiy=dindgen(LDy)
       Y=0.5*(1.0-COS(QIy*!dPI/LDy))
       FOR J=0,Ly-1 DO  BZt(     0:LDx-1, J) = BZT(0:LDx-1,J)*X(0:LDx-1)
       FOR J=0,Ly-1 DO  BZt(Lx-LDx: Lx-1, J)   = BZt(Lx-LDx: Lx-1,J)*(1.-X(0:LDx-1))
       FOR I=0,Lx-1 DO  BZt( I, 0:LDy-1)     = BZt(I,0:LDy-1)*Y(0:LDy-1)
       FOR I=0,Lx-1 DO  BZt( I, Ly-LDy:Ly-1)   = BZt(I,Ly-LDy:Ly-1)*(1.-Y(0:LDy-1))
      ;
      RETURN,BZt
      END
