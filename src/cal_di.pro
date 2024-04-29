pro cal_di, bx, by, bz, disav=disav, vars=vars 

  ;+
	;   Name: cal_di
	;
	;   Purpose: Calculate the decay index for a magnetic field
	;
	;   Input Parameters: bx(x,y,z); x component of magnetic filed
  ;                     by(x,y,z); y component of magnetic filed
  ;                     bz(x,y,z); z component of magnetic filed
	;
	;   Output Parameters: di(xnynz); decay index calculated along z-axis
	;   Keyword Parameters: vars: input variables
	;
	;   History: 2022-01-16: added the first outline.
	;
	;   NOTES: The formula for the decay index can be checked (...here...)
	;
	;-

ss = size(bz)
nx = ss(1)
ny = ss(2)
nz = ss(3)

;---AP (2022-06-02): Use transverse field for decay index calculation---
print,'status: calculating the decay index'
bb  = sqrt(bx^2. + by^2. + bz^2.)
bbh = sqrt(bx^2. + by^2.)
di  = fltarr(nx, ny, nz, /nozero)
fz  = findgen(nz) + 1.
lz  = alog(fz)

for i=0, nx-1 do begin
  for j=0, ny-1 do begin
    lbb = alog(bbh(i,j,*)) ;lbb = alog(bb(i,j,*))
    diff = -deriv(lz,lbb)
    di(i,j,*)= diff
  endfor
endfor

print,'status: done'

if keyword_set(vars) then begin
  isf = obj_new('IDL_Savefile', filename = vars)
  isf->restore,['datadir','run', 'id']
  obj_destroy, isf
endif

disav = datadir + run + '_' + id + '_'+ 'di.sav'
save, di, filename = disav

end

