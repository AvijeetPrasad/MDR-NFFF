pro sav2vdc, bsav, insav=insav

	;+
  ; NAME: sav2vdc
  ; PURPOSE: writes a VDC (VAPOR 3) output from an IDL sav file
  ; Avijeet Prasad
  ; 2022-05-08
  ;-

;--- Include the input file ---
;@include/in_ar12017_hmlf
;@include/in_muram_spd2
;@include/in_ar11515
;@include/in_ar12418_spd_cospar
; @input
; @compile_routine

; ;--- Read and restore the input sav file ---
; ;savfile = datadir + run + '.sav'
; suff = run+'vectorb_'+xysize
; suffz = suff+'_'+strtrim(nz,1)
; savefile = datadir+'bnfff_'+suffz+'.sav'
; ;TODO check_sav, savfile, savfile ;check and rename the variables.
; print, '=== Restoring ' + savefile + ' ==='
; restore, savefile,/v

isf = obj_new('IDL_Savefile', filename = bsav)
isf->restore,['bx','by','bz']  
obj_destroy, isf

isf = obj_new('IDL_Savefile', filename = insav)
print, isf->names()
isf->restore,['datadir','run','id','current','decay','qfactor']  
obj_destroy, isf

; ;--- Switches for calculations ---
; lor = 0
; cur = 0
; di  = 0
; qfactor = 0
; nbridges = 30

; ;--- Rename the magnetic field variables ---

; bx = bvx
; by = bvy
; bz = bvz

;--- Check the size of the input data
ss = size(bx)
nx = ss[1]
ny = ss[2]
nz = ss[3]
dim = [nx,ny,nz]
dims = strtrim(nx,1) + "_" + strtrim(ny,1) + "_" +strtrim(nz,1) 
;suffz2 = event + '_' + time + '_'+'vectorb_'+dims

;varfile = datadir + suffz + "_vars.sav"
;save, hd, suff, datadir, qfactor, di, lor, cur, ss, nx, ny, nz, $
;codesdir, dim, suffz, dims, nbridges, filename=varfile

vdcfile = datadir + run + id + dims + '.vdc'
;vdc_prep, varfile, vdcfile

numts = '1'
dimension = strtrim(nx,1) + "x" + strtrim(ny,1) + "x" +strtrim(nz,1)
vars = 'bx:by:bz'

if (current eq 1) then vars += ':jx:jy:jz'
if (decay eq 1) then vars += ':di'
if (qfactor eq 1) then vars += ':slq:tw'

;vdccreate -dimension 272x136x136 -numts 1 -vars3d bx:by:bz test.vdc
;raw2vdc -ts 0 -varname bx bipole_hmi_res.vdc fbx_hmi_res.raw
 
spawn, 'vdccreate -force -dimension ' + dimension + ' -numts ' + numts $
  + ' -vars3d ' + vars + ' ' + vdcfile

write_raw2vdc, vdcfile, 'float64', 'bx', bx 
write_raw2vdc, vdcfile, 'float64', 'by', by 
write_raw2vdc, vdcfile, 'float64', 'bz', bz

if (current eq 1) then begin 
  print, 'Calculating current'
  curl, bx, by, bz, jx, jy, jz, order = 2
  write_raw2vdc, vdcfile, 'float64', 'jx', jx 
  write_raw2vdc, vdcfile, 'float64', 'jy', jy 
  write_raw2vdc, vdcfile, 'float64', 'jz', jz
endif

if (decay eq 1) then begin 
  disav = datadir + run + 'di.sav'
  restore, disav,/v
  write_raw2vdc, vdcfile, 'float32', 'di', di
endif 

if (qfactor eq 1) then begin
  qfsav = datadir + run + id + 'qfactor.sav'
  ;print, 'Calculating Q factor'
  ;cal_qfactor, bx, by, bz, qfsav=qfsav, vars=insav
  restore, qfsav
  write_raw2vdc, vdcfile, 'float32', 'slq', slq
  write_raw2vdc, vdcfile, 'float32', 'tw', tw
endif

;vdfdata = suffz + "_data"
;file_move, vdffile, datadir + vdffile, /overwrite
;file_move, vdfdata, datadir + vdfdata, /overwrite

;print, '=== RUN COMPLETE! ==='
;stop

end
