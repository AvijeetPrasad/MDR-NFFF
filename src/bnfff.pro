pro bnfff

;+created: Oct 08, 2021 by Avijeet Prasad

; 
;Compile the routines called in this program
;-
@compile_routine
;include the input parameter file
codesdir = '/mn/stornext/u3/avijeetp/codes/idl/extrapolation/'
input = codesdir + 'input.pro'
check_input, input, input_vars = input_vars
restore, input_vars,/v 

if (mode eq 'calculate') then begin 
  bnfff_prep, input_vars, prepsav=prepsav
  nonff2, input_vars, prepsav
  nonff25d, input_vars, prepsav, bnfffsav=bnfffsav
endif else bnfffsav = file_search(datadir + run + id + '*_Bnfff.sav')

isf = obj_new('IDL_Savefile', filename = bnfffsav)
isf->restore,['bx','by','bz']  
obj_destroy, isf
 
;if (current eq 1) then curl, bx, by, bz, jx, jy, jz, order = 2
if (decay   eq 1) then cal_di, bx, by, bz, disav=disav, vars=input_vars
if (qfactor eq 1) then cal_qfactor, bx, by, bz, qfsav=qfsav, vars=input_vars 
if (vapor   eq 1) then sav2vdc, bnfffsav, insav=input_vars 

print, '======================================'
print, '    --------- RUN COMPLETE -------      '
print, '======================================'

stop
end
