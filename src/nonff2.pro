pro nonff2, input_vars, prepsav 

; created-on: Aug 21, 2018 by Avijeet Prasad
; Non force free extrapolation based on minimum dissipation rate principle
; the solution is the linear superposition of 2 linear FF and a potential
;field, see Hu et al. 2010

Common Block,BVX,BVY,BVZ,Bres
Common Block2,bx0,by0,bz0,Jz0,bzc0,bx03,by03,bz03,bxc,byc

isf = obj_new('IDL_Savefile', filename = input_vars)
isf->restore,['datadir','run','nk0','nl','itaperx','itapery','wt_set','nfffvars']
obj_destroy, isf

isf2 = obj_new('IDL_Savefile', filename = prepsav)
isf2->restore,['nx','ny','suff']
obj_destroy, isf2

if file_test(nfffvars) then begin 
	print, 'Extrapolation already exists!'
	goto, last 
endif 
;____________INPUT BLOCK___________
n=2
cmin    = 0.0 ; fixed
dx	    = 1 ; fixed
oblique	= 0 ; fixed
outdisk = 0 ; fixed

;# number of points in x and y
;nk0=50; 5 ;400 ;600 ;600 ;600 ;400 ;300 ;150 ;150 ;25 ;24 ;32 ;12 ;32 ;6
; >1; =1 for disambibuity
nk=nk0    ; nk0=nk
cmin=double(cmin)
;if (n_params() lt 2) then oblique=0 
	;oblique=-1 force normal flux to be zero; 1 for LOS
;if (n_params() lt 1) then wt_set=0.
;save, filename=outdir+'suff.sav', wt_set, suff
;# saving an sav file with wt_set and suff written

outfile = datadir + suff + 'out.txt';
if not file_test(outfile) then openw, unitout, outfile,  /get_lun $
else openu, unitout, outfile,/append, /get_lun

print, 'dx=', dx, '        cmin=',cmin, '     oblique=',oblique
printf,unitout, '     '
printf,unitout, 'dx=', dx, '        cmin=',cmin, '     oblique=',oblique
flag=0

;!!!!!!!!!!!!!!!!!check here
if (nx gt ny) then begin
	lmbd1=2.*!dpi/double(nx)/dx  ; small scale only ;8. a1
endif else begin
	lmbd1=2.*!dpi/double(ny)/dx  ; small scale only ;8. a1
endelse

;if keyword_set(seehfr) then lmbd1=lmbd1/2.0
lmbd2=sqrt(0.) ; minimum
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;nl=8 ;8 ;32 ;32 ;64 ;64 ;64 ;64 ;64
nl0=nl
mul=0. ;0.5 ;1.5 .268
dl=(lmbd1-lmbd2)/(nl-1)
lmbd=indgen(nl, /double)

;dmin0=-1. & dmax=1.
;dk=(dmax-dmin0)/float(nk-1)         ; d \in [cmin, cmax]
;d=indgen(nk,/double)*dk+dmin0
;d=[0., 1.]
;;c=[reverse(-c), c(1:nk-1)]
;;nk=nk*2-1

lmbd=double((lmbd*dl+lmbd2+dl)*dx)
lmbd=[reverse(-lmbd), lmbd]
nl=nl*2
print, 'alpha_max = ', max(lmbd), ' alpha_min = ',min(lmbd)
Bterr=dblarr(nl, nl, nk)

;lmbd=float(sqrt(Lambda))*dx
;print, 'lmbd=', lmbd

a=dblarr(n) ;& a(1)=0.0  ; alpha2=0 as required by the MDR equation
;alpha(0)=lmbd
;alpha(1)=-lmbd
;print, alpha

;----------- Reading initial file ------------------
;restore, outdir+suff+'.sav'

;## input of Bz0
nser=nx
npts=ny

Bt=sqrt(Bx0^2+By0^2)
maxBt=max(Bt) ;& avgBt=mean(Bt)
wt=1.0 ;Bt ;1.0
if wt_set eq 1.1 then wt=Bt
sigma=0.0 & count=0
if wt_set eq 1 then begin
  sigma=0.0 ;*stddev(Bt(long(where(Bt gt 0.0))))   
	;maxBt/10.0 ;~149; ;/4.0 ;sigma=stddev(Bt(*)) ;
  print, 'sigma=', sigma & printf,unitout, 'sigma=', sigma
  wtind=where(Bt le sigma, count)
  print, 'Bt <=',sigma, '   ,count=', count
  if count ne 0 then Bt(wtind)=0.0
endif

lBtl=total(Bt*wt)  &  wt2=1.0 ;Bt/maxBt
print, 'max lBtl=', maxBt, ' total Bt=', lBtl
printf,unitout, 'max lBtl=', maxBt, ' total Bt=', lBtl

border=fix(nx*mul) ;3.5
lati=0 & longi=0
BZ=dblarr(nser, npts, /nozero)

; corrector field
;BXP=fltarr(nser, npts, /nozero)
;BYP=fltarr(nser, npts, /nozero)
BZP=dblarr(nser, npts) & bxp=bzp & byp=bzp & bxc=bzp & byc=bzp & bzc0=bzp
BVX=dblarr(nser, npts, /nozero)
BVY=BVX
BVZ=BVX
Bx12=dblarr(nser, npts, n, /nozero)
By12=Bx12
Bz12=Bx12
Bx01=BVX & Bx02=Bx01 & By01=Bx01 & By02=By01 & Bz01=Bx01 & Bz02=Bz01
Bx03=Bx01 & By03=By01 & Bz03=Bz01

; potential feild as z=0 only derived from Bz0  ; not needed for cmin=0
ALEX1,ITAPERx,ITAPERy,0.0,0.0,Bz0,Bx03,By03,Bz03,0,$
	LATI=LATI,LONGI=LONGI,BORDER=BORDER

;PRO ALEX1,ITAPERx,ITAPERy,ALPHA,Z,BZO,BXP,BYP,BZP,OBLIQUE,$
;	LATI=LATI,LONGI=LONGI,BORDER=BORDER

;dBz=Bz0-Bz03
;print, max(dBz), '    ', min(dBz)   ; 1e-12

tmpx=dblarr(nser, npts)
tmpy=tmpx
tmpz=tmpx
tmp0=tmpx

for k=0, nk-1 do begin
	minerr=99999999.      ; reset
	bzc0=double(bzc0+bzp)
	Bzc=double(bz0-cmin*bz0-Bzc0) & bxc=bxc+bxp & byc=byc+byp
	if k gt nk0 then nl=1
	for l1=0+2, nl-1-2 do begin	; nl >= 5
		for l2=0+2, nl-1-2 do begin
			;if l2 gt l1 then begin
		  ;if (l1 gt l2) and (l1+l2 eq nl-1) then begin
			if l1 gt l2 or nl eq 1 then begin
				a(0)=lmbd(l1)
				a(1)=lmbd(l2)
				if nl eq 1 then begin
					a(0)=lmbd(l1min)
					a(1)=lmbd(l2min)
				endif
				;print, 'alpha=', a
				;c=1./a(0)/a(1)
				for i=0,n-1 do begin
					if (i eq 0) then $
						BZ=Jz0/(a(0)-a(1))+a(1)*Bzc/(a(1)-a(0));
					if (i eq 1) then $
						BZ=Jz0/(a(1)-a(0))+a(0)*Bzc/(a(0)-a(1));
					;if (i eq 2) then $
						;BZ=1./lVl*((a(0)*a(1)^2-a(0)^2*a(1))*Bz0+(a(0)^2-a(1)^2)*Jz0+$
						;(a(1)-a(0))*dJz0)
 					Zin=0.0
					;Print,Zin
					;if keyword_set(seehfr) then $
						;ALEX1_seehafer,ITAPERx,ITAPERy,a(i),ZIN,BZ,BVX,BVY,BVZ,OBLIQUE,$
							;LATI=LATI,LONGI=LONGI,BORDER=BORDER $
					;else $
 					ALEX1,ITAPERx,ITAPERy,a(i),ZIN,BZ,BVX,BVY,BVZ,OBLIQUE,$
						LATI=LATI,LONGI=LONGI,BORDER=BORDER
					;ALEX_OLD,ITAPERx,ITAPERy,ALPHA,ZIN,BZ,BXP,BYP,BZP,OBLIQUE,$
						;LATI=LATI,LONGI=LONGI,BORDER=BORDER
					;BVX(*,*)=BXP(*,*)
					;BVY(*,*)=BYP(*,*)
					;BVZ(*,*)=BZP(*,*)
					Bx12(*,*,i)=BVX(*,*)
					By12(*,*,i)=BVY(*,*)
					Bz12(*,*,i)=BVZ(*,*)
					BVX=BVX+tmpx
					BVY=BVY+tmpy
					BVZ=BVZ+tmpz
					tmpx=BVX
					tmpy=BVY
					tmpz=BVZ
				endfor
				tmpx=tmp0
				tmpy=tmp0
				tmpz=tmp0
				BVX=BVX+cmin*Bx03+bxc & BVY=BVY+cmin*By03+byc ;& BVZ=BVZ+c*Bz03
				Btdiff=sqrt((Bx0-BVX)^2+(By0-BVY)^2)
				if wt_set eq 1 then begin
					;wtind=where(Bt lt sigma, count)
					if count ne 0 then Btdiff(wtind)=0.0
				endif
				Bterr(l1,l2,k)=total(Btdiff*wt)/lBtl
				if Bterr(l1,l2,k) lt minerr then begin
					minerr=Bterr(l1,l2,k)
					if nl ne 1 then begin
						l1min=l1 & l2min=l2
					endif
					kmin=k
					Bx01=Bx12(*,*,0) & Bx02=Bx12(*,*,1) ;& Bx03=Bx12(*,*,2)
					By01=By12(*,*,0) & By02=By12(*,*,1) ;& By03=By12(*,*,2)
					Bz01=Bz12(*,*,0) & Bz02=Bz12(*,*,1) ;& Bz03=Bz12(*,*,2)
    		endif
			endif
		endfor
	endfor
	print, 'k=',k, '  Min. err = ', minerr,' at ', lmbd(l1min), lmbd(l2min)
	printf,unitout, 'k=',k, '  Min. err = ', minerr,' at ', $
		lmbd(l1min), lmbd(l2min)
	; the Min. err can later be extracted in shell script as follows
	; cat *.out.txt|grep k=| tr -s ' '| cut -d ' ' -f 6 > min_err.txt

	bx3=bx01+bx02+cmin*bx03+bxc
	by3=by01+by02+cmin*by03+byc
	bz3=bz01+bz02+cmin*bz03+bzc0

	Bxp=(bx0-bx3)*wt2
	Byp=(by0-by3)*wt2
	xoy=-1         ; get bzp from bx, by default
	;if total(bxp^2) lt total(byp^2) then xoy=1 ; otherwise, from byp

	ALEX1_inv2,ITAPERx,ITAPERy,0.0,0.0,Bzp,Bxp,Byp,xoy,0,$
		LATI=LATI,LONGI=LONGI,BORDER=BORDER
	print, 'Max bzp=', max(bzp), ' Min. bzp=', min(bzp);, ' Size =', size(bzp)
	printf,unitout, 'Max bzp=', max(bzp), ' Min. bzp=', min(bzp)

	;if keyword_set(seehfr) then $
	;     ALEX1_seehafer,ITAPERx,ITAPERy,0.0,0.0,Bzp,Bxp,Byp,Bzp0,0,$
		;LATI=LATI,LONGI=LONGI,BORDER=BORDER $
		;     else $
	ALEX1,ITAPERx,ITAPERy,0.0,0.0,Bzp,Bxp,Byp,Bzp0,0,$
		LATI=LATI,LONGI=LONGI,BORDER=BORDER
		print, '  ' & printf,unitout, '  '
endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BVZ(*,*,0)=Bz0

;  save,filename=outdir+'Bvolume.sav',BVX,BVY,BVZ
;  save, filename=outdir+'Bterrors.sav', Bterr
; output to ascii files for analysis in Matlab
;print, 'Bterror=', Bterr

print, 'Min error:', minerr, ' at ', l1min, l2min, kmin
print, 'lambda1, lambda2, k, mul =', lmbd(l1min), lmbd(l2min), kmin, mul
printf,unitout, 'Min error:', minerr, ' at ', l1min, l2min, kmin
printf,unitout, 'lambda1, lambda2, k, mul =',lmbd(l1min), lmbd(l2min), kmin, mul
lmbd1=lmbd(l1min) & lmbd2=lmbd(l2min) ;& cmin=c(kmin)

nl=nl0*2
 if nk0 gt 1 then begin
	save, filename = nfffvars, bxc, byc, bzc0, minerr, lmbd1, lmbd2, cmin, mul, $
		itaperx, itapery, nx, ny, dx, nk, nl, bz01, bz02, bz03
 endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Bx3=Bx01+Bx02+Bx03
;;By3=By01+By02+By03
;;Bz3=Bz01+Bz02+Bz03*cmin
;;Bz3=Bz01+Bz02+Bz03
dBz=Bz0-Bz3
;window,0,xsize=3*nx,ysize=ny & tvscl, [Bz0,Bz3,abs(dBz)]
;window,1 & tvscl, Bz3

print, 'Max. dBz=', max(dBz), '  Min. dBz=', min(dBz)
printf,unitout, 'Max. dBz=', max(dBz), '  Min. dBz=', min(dBz)
printf,unitout, '     '
free_lun,unitout
;print, 'Current Directory:' & CD, CURRENT=c & PRINT, c

last: 
print, '==============================================='
print, '--------- RUN COMPLETE. NOW RUN NONFF25D  -----'
print, '==============================================='

end ;end of main program
