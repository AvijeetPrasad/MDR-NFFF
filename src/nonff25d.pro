pro nonff25d, input_vars, prepsav, bnfffsav=bnfffsav, bpotsav=bpotsav

; codesdir=codesdir, event=event, time=time, outdir=outdir,$
; 	datadir=datadir,run=run,xysize=xysize,suff=suff,wt_set=wt_set,$
; 	nz=nz, dz=dz, oblique=oblique, method=method,nx1=nx1,ny1=ny1,$
; 	nx0=nx0,ny0=ny0,wang=wang,seehfr=seehfr,outtxt=outtxt,outdisk=outdisk
; Last modified: Apr 10, 2018 by Avijeet Prasad

;set outtxt=1 to save output in .txt format
;
Common Block,BVX,BVY,BVZ,Bres
Common Block2,bx0,by0,bz0,Jz0,bzc0,bx03,by03,bz03,bxc,byc
;common D2Bz,Bz0,Jz0

isf = obj_new('IDL_Savefile', filename = input_vars)
isf->restore,['codesdir','event','time','outdir','datadir','run','nfffvars',$
		'dx','dz','outtxt']
obj_destroy, isf

isf2 = obj_new('IDL_Savefile', filename = prepsav)
isf2->restore,['nx','ny','nz','suff']
obj_destroy, isf2
;____________INPUT BLOCK___________ 
n = 2
cdr = datadir
cd, cdr & print, cdr

oblique=0
method=1   ;Alex1

while not file_test(nfffvars) do print, 'wait...'
restore, nfffvars

if (not (isa(dz))) then dz = dx
print, 'dx=', dx

if (not (isa(nz))) then nz = ny 

;z=fltarr(nz,1, /nozero)
if (nz eq 3) then z=[0.0,-1.0,1.0]*dz/dx else z=double(dindgen(nz)*dz/dx)
 ; both dz and dx are dimensional, but z has to be normalized by dx

nzstr=strtrim(nz,1)
print, 'Parameters:', lmbd1, lmbd2, cmin, mul, minerr, nx, ny, dx

cmin = double(cmin)
a = dblarr(n)
a(0) = double(lmbd1) & a(1) = double(lmbd2)
print, 'alpha=', a
nser = nx
npts = ny

if (size(bz0,/type) eq 0) then begin
	file='Bz0_'+suff+'.txt' ;Bz at z=0
	;nz=nx
	openr, unitin, datadir+file, /get_lun
	;for i=1, fix(ntext) do readf, unitin, line
	Bz0=dblarr(nser, npts, /nozero)
	readf, unitin, Bz0
	free_lun, unitin
	file='Jz0_'+suff+'.txt' ;Jz (\curl B)z at z=0 from Low's solution
	openr, unitin, datadir+file, /get_lun
	;for i=1, fix(ntext) do readf, unitin, line
	Jz0=dblarr(nser, npts, /nozero)
	readf, unitin, Jz0
	free_lun, unitin
	Jz0=Jz0*double(dx)
endif

cd, codesdir
border=fix(nx*mul)
lati=0 & longi=0

BZ=dblarr(nser, npts, /nozero)
BXP=dblarr(nser, npts, /nozero)
BYP=dblarr(nser, npts, /nozero)
BZP=dblarr(nser, npts, /nozero)
BVX=dblarr(nser, npts, nz, /nozero)
BVY=dblarr(nser, npts, nz, /nozero)
BVZ=dblarr(nser, npts, nz, /nozero)
;Bx12=fltarr(nser, npts, n, /nozero)
;By12=Bx12
;Bz12=Bx12
;Bx01=BVX & Bx02=Bx01 & By01=Bx01 & By02=By01 & Bz01=Bx01 & Bz02=Bz01
;Bx03=Bx01 & By03=By01 & Bz03=Bz01
;if not file_test('BVp_'+suff+nzstr+'.cdf') or (nz le 3) then
Bres=dblarr(3,nser,npts,nz,/nozero)
tmpx=dblarr(nser, npts, nz,/nozero)
tmpy=dblarr(nser, npts, nz,/nozero)
tmpz=dblarr(nser, npts, nz,/nozero)
;for l1=0, nl-1 do begin
;for l2=0, nl-1 do begin
;    ;if l2 gt l1 then begin
;    ;
;     ;if (l1 gt l2) and (l1+l2 eq nl-1) then begin
;    if l1 gt l2 then begin
;    a(0)=lmbd(l1)
;    a(2)=lmbd(l2)
;    ;print, 'alpha=', a
    ;lVl=(a(1)-a(0))*(a(2)-a(1))*(a(2)-a(0))

Bzc=double(bz0-cmin*bz0-bzc0); call bz2 = bzc0
for i=0,n-1 do begin
	print, '===== LFFF extrapolations ====='
	print, 'i = ' + string(i)
	if (i eq 0) then $
  	BZ=Jz0/(a(0)-a(1))+a(1)*Bzc/(a(1)-a(0)); call it bz1
  if (i eq 1) then $
  	BZ=Jz0/(a(1)-a(0))+a(0)*Bzc/(a(0)-a(1)); call it bz3

	; Then the split of NFFF is following
	; bz0 = bz1 + bz2 + bz3 and
	; bnfff = lfff(a0,bz1) + lfff(0, bz2) + lfff(a1, bz3)

	for Zin=0,nz-1 do begin
		Print,'z=', z(Zin)
		;if keyword_set(seehfr) then $
		;ALEX1_seehafer,ITAPERx,ITAPERy,a(i),z(ZIN),BZ,BXP,BYP,BZP,OBLIQUE,$
			;LATI=LATI,LONGI=LONGI,BORDER=BORDER $
		;else $
		ALEX1,ITAPERx,ITAPERy,a(i),z(ZIN),BZ,BXP,BYP,BZP,OBLIQUE,$
			LATI=LATI,LONGI=LONGI,BORDER=BORDER
		BVX(*,*,zin)=BXP(*,*)
		BVY(*,*,zin)=BYP(*,*)
		BVZ(*,*,zin)=BZP(*,*)
		; Bx12(*,*,i)=BVX(*,*)
		; By12(*,*,i)=BVY(*,*)
		; Bz12(*,*,i)=BVZ(*,*)
	endfor
  
	;!!!! MEMORY BOTTLENECK HERE !!!!
     ; BVX=TEMPORARY(BVX)+tmpx
     ; BVY=TEMPORARY(BVY)+tmpy
     ; BVZ=TEMPORARY(BVZ)+tmpz
     ; tmpx=BVX
     ; tmpy=BVY
     ; tmpz=BVZ

	;---> !!!! Changes by Avijeet on 23 July 2019
		;--- for optimizing memory in large runs ---check!!!!
		;----> This works only for n = 2 !!!!!
	if (i eq 0) then begin
		tmpx=BVX
		print,"clearing BVX"
		BVX=dblarr(nser, npts, nz, /nozero)
		tmpy=BVY
		print,"clearing BVY"
		BVY=dblarr(nser, npts, nz, /nozero)
		tmpz=BVZ
		print,"clearing BVZ"
		BVZ=dblarr(nser, npts, nz, /nozero)
	endif else begin
		BVX=TEMPORARY(BVX)+tmpx
		print,"clearing tmpx"
		undefine, tmpx
		BVY=TEMPORARY(BVY)+tmpy
		print,"clearing tmpy"
		undefine, tmpy
			BVZ=TEMPORARY(BVZ)+tmpz
		print,"clearing tmpz"
		undefine,tmpz
	endelse
	;-------> !!!!

endfor
;undefine, tmpx,tmpy,tmpz

; now calculate the reference field - 
; potential field in the volume from Bzc0+cmin*Bz0
print, '===== potential field extrapolation ====='
for Zin=0,nz-1 do begin
	Print,'z=', z(Zin)
  ALEX1,ITAPERx,ITAPERy,0.0,z(ZIN),Bzc0+cmin*Bz0,BXP,BYP,BZP,OBLIQUE,$
		LATI=LATI,LONGI=LONGI,BORDER=BORDER
	BVX(*,*,zin)=BXP(*,*)+BVX(*,*,zin)
	BVY(*,*,zin)=BYP(*,*)+BVY(*,*,zin)
	BVZ(*,*,zin)=BZP(*,*)+BVZ(*,*,zin)
  ;if not file_test('BVp_'+suff+nzstr+'.cdf') or $
	;	(nz le 3) or (size(Bres,/type) ne 0) then begin
	; Calculate the potential field for the initial boundary
	ALEX1,ITAPERx,ITAPERy,double(0.0),z(ZIN),Bz0,BXP,BYP,BZP,OBLIQUE,$
			LATI=LATI,LONGI=LONGI,BORDER=BORDER
		Bres(0,*,*,ZIN)=BXP(*,*)
		Bres(1,*,*,ZIN)=BYP(*,*)
		Bres(2,*,*,ZIN)=BZP(*,*)
  ;endif
endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;cd, datadir

; save the three components of the potential field
	bpx = reform(bres[0,*,*,*])
	bpy = reform(bres[1,*,*,*])
	bpz = reform(bres[2,*,*,*])

if nz gt 3 then begin
	;TODO !! check this keyword condition and update the code !!
	if (keyword_set(nx0)) then begin   ; all nx1, ny1, nx0, and ny0 are set
		nx2=nx1+nx0-1 & ny2=ny1+ny0-1
		BVX=temporary(BVX(nx1:nx2,ny1:ny2,*))
		BVY=temporary(BVY(nx1:nx2,ny1:ny2,*))
		BVZ=temporary(BVZ(nx1:nx2,ny1:ny2,*))
		if (size(Bres,/type) ne 0) then Bres=temporary(Bres(*,nx1:nx2,ny1:ny2,*))
		nx=nx0 & ny=ny0
		;goto, exitpro
	endif

	bx = bvx 
	by = bvy 
	bz = bvz 
	bnfffsav = cdr + suff + 'Bnfff.sav'
  save, filename = bnfffsav, BX, BY, BZ, nx, ny, nz
	undefine, bx, by, bz
	print, 'Output size:', size(BVZ)
	
	if (outtxt eq 1) then begin
		;openw, unitx, cdr+'BVX_'+suff+'_25c'+nzstr+'.dat', /get_lun
		;openw, unity, cdr+'BVY_'+suff+'_25c'+nzstr+'.dat', /get_lun
		;openw, unitz, cdr+'BVZ_'+suff+'_25c'+nzstr+'.dat', /get_lun
		openw, unitb, cdr + suff + 'Bnfff.dat', /get_lun
		;nz=nx/2
		;nz=32
		fmtstr='('+strtrim(ny,1)+'E20.5)'       ; ny=nx
		for k=0,nz-1 do begin   ; ny=128
	  		for j=0,ny-1 do begin
	    		for i=0, nx-1 do begin
				  	printf, unitb, FORMAT=fmtstr, BVX(i,j,k), BVY(i,j,k), BVZ(i,j,k)
				   	; printf, unitx, FORMAT=fmtstr, BVX(i,j,k)
				   	; printf, unity, FORMAT=fmtstr, BVY(i,j,k)
				   	; printf, unitz, FORMAT=fmtstr, BVZ(i,j,k)
	    		endfor
	  		endfor
		endfor
		;free_lun, unitx
		;free_lun, unity
		;free_lun, unitz
		free_lun, unitb
	endif
	
	; TODO check if the potential field is being saved properly
	bpotsav = cdr + suff + 'Bpot.sav'
	if not file_test(bpotsav) $
		or (size(Bres,/type) ne 0) then begin
		B2p=total(temporary(Bres)^2) 
		save, bpx, bpy, bpz, B2p, filename = bpotsav, $
			description='Bp(x,y,z)= components of the potential field, b2p= total(B^2)'
		; WARNING: MORE ZEROS SHOULD BE ADDED
		; SURROUNDING THE FIELD TO OBTAIN A MORE ACCURATE ESTIMATE OF B2p
		;Bres=0.0  ; free memory
	endif else restore, filename = bpotsav

	B2=total(BVX*BVX+BVY*BVY+BVZ*BVZ)
	epsp=B2/B2p
	print, 'Ep=', epsp, '  B2=',B2, '   B2p=',B2p
	save, bpx, bpy, bpz, B2p, B2, epsp, filename = bpotsav, $
		description='Bp(x,y,z)= components of the potential field, b2p= total(B^2)'
	;undefine, Bres ; Bres is the potential field for the same boundary
endif

cd, codesdir

print, '======================================'
print, '--------- EXTRAPOLATION COMPLETE -----'
print, '======================================'

end ;end of main program
