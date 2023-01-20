pro cal_qfactor, bx, by, bz, qfsav=qfsav, vars=vars 
;pro cal_qfactor, bvx, bvy, bvz, varfile, qfsav,nbridges, slq, tw

  ;+
  ; NAME: cal_qfactor
  ; PURPOSE: calculate the squashing factor for a magnetic field
  ; NOTES: It needs the intel compiler to be setup for mpi run.
  ; Avijeet Prasad
  ; 2022-05-08
  ;-

; 2022/05/08: ensure that the input variables are in float
; bx = float(bx)
; by = float(by)
; bz = float(bz)

;restore, vars
isf = obj_new('IDL_Savefile', filename = vars)
isf->restore,['datadir', 'run', 'id', 'qpath','codesdir']
obj_destroy, isf

print,'status: calculating the squashing factor'
ss = size(bx)
nx = ss(1)
ny = ss(2)
nz = ss(3)
odir = datadir
xreg = [0, nx - 1]
yreg = [0, ny - 1]
zreg = [0, nz - 1];[0,0]
fstr = run + id 
nbridges = fix(0.9 * !CPU.HW_NCPU) ; use 90% of the available CPUs
twistFlag = 1
factor = 1
no_preview = 1 
;qpath  = codesdir
;csFlag=1
;2023/01/17: create qfactor executable in the qpath
cd, qpath
spawn,'ifort -o qfactor.x qfactor.f90 -fopenmp -mcmodel=medium -O3 -xHost -ipo'
cd, codesdir
; 2022/05/08: trying -r8 for forcing double precision

qfrun = odir + fstr + 'qfactor_run.sav'
if not(file_test(qfrun)) then begin 
  qfactor, bx, by, bz, xreg=xreg, yreg=yreg, zreg=zreg, factor=factor, $
    twistFlag=twistFlag, csFlag=csFlag,no_preview=no_preview, $
    nbridges=nbridges, step=step, odir=odir, fstr=fstr, qpath = qpath
endif else begin 
  print, '--- QFactor sav file already exists! --'
endelse 
restore, qfrun,/v 

;---- Convert to qfactor to log scale ---
q3dtmp = reform(q3d(*,*,*))
nan1 = where(~finite(q3dtmp), /null)
q3d1 = q3dtmp
q3d1(nan1) = 1.
q3d2 = congrid(abs(q3d1) + 1, nx, ny, nz)
slq = alog10(q3d2)
undefine, q3d, q3dtmp, nan1, q3d1, q3d2

tw    = fltarr(nx, ny, nz,/nozero)
twtmp = reform(twist3d(*, *, *))
nan2  = where(~finite(twtmp), /null)
tw3d1 = twtmp
tw3d1(nan2) = 0.
nan3 = where(abs(tw3d1) gt 10)
tw3d1(nan3) = 0.
tw = congrid(tw3d1,nx,ny,nz)
undefine, twist3d, twtmp, tw3d1, nan2, nan3

qfsav = odir + fstr + 'qfactor.sav'
save, slq, tw, filename=qfsav, description='Twist (tw), Log(10) QFactor(slq)'
end
