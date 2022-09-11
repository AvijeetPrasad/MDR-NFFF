pro sav2vdc, bsav, insav=insav, numts=numts, ts=ts, vdcfile=vdcfile, savts=savts

;+ 
; name: sav2vdc
;
; purpose: writes a VDC (VAPOR 3) output from an IDL sav file
;
; calling sequence: 
;
; inputs: 
;         bsav: sav file containing the magnetic field input
;         insav: sav file containing the input variable data 
;         numts: (optional) number of time steps for time series run (default: 1)
;         ts: (optional) current time step in time series (default: 0)
;         vdcfile: (optional) name of the vdcfile to be saved
;         savts: (optional) for taking inputs from time series
; outputs: creates a vdc file and a data folder in outdir
;
; author : Avijeet Prasad
; created on : 2022-09-11
;
; updates :
;-

; Check keywords and set default values
if not keyword_set(numts) then numts = '1'
if not keyword_set(ts) then ts = '0'

;--- Read and restore the input sav file ---
isf = obj_new('IDL_Savefile', filename = bsav)
isf->restore,['bx','by','bz']  
obj_destroy, isf

isf = obj_new('IDL_Savefile', filename = insav)
;print, isf->names()
isf->restore,['outdir','run','id','current','decay','qfactor']  
obj_destroy, isf

if keyword_set(savts) then begin 
  isf = obj_new('IDL_Savefile', filename = savts)
  isf->restore,['current','decay','qfactor']  
  obj_destroy, isf
endif 
 
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

; Set vdcfile path if not given as input
if not keyword_set(vdcfile) then vdcfile = outdir + run + id + dims + '.vdc'


;varfile = outdir + suffz + "_vars.sav"
;save, hd, suff, outdir, qfactor, di, lor, cur, ss, nx, ny, nz, $
;codesdir, dim, suffz, dims, nbridges, filename=varfile
;vdc_prep, varfile, vdcfile

; numts = nt
dimension = strtrim(nx,1) + "x" + strtrim(ny,1) + "x" +strtrim(nz,1)
vars = 'bx:by:bz'

if (current eq 1) then vars += ':jx:jy:jz'
if (decay eq 1) then vars += ':di'
if (qfactor eq 1) then vars += ':slq:tw'
;vdccreate -dimension 272x136x136 -numts 1 -vars3d bx:by:bz test.vdc
;raw2vdc -ts 0 -varname bx bipole_hmi_res.vdc fbx_hmi_res.raw

; Open a new vdc file for writing  
if (ts eq '0') then begin
  ; If time step = 0, check if vdc file already exists and remove it
  if file_test(vdcfile) then begin
    file_delete, vdcfile
    vdcdir = vdcfile.substring(0,-5) + '_data'
    file_delete, vdcdir, /recursive
  endif
  ; print all the variables to be saved 
  
  ; Open the new vdcfile for writing
  print, 'new vdc file created in: ', vdcfile
  spawn, 'vdccreate -force -dimension ' + dimension + ' -numts ' + numts $
  + ' -vars3d ' + vars + ' ' + vdcfile  
endif
print, 'vars =  ', vars 

; Write the magnetic field variables 
write_raw2vdc, vdcfile, 'float64', 'bx', bx, ts=ts
write_raw2vdc, vdcfile, 'float64', 'by', by, ts=ts 
write_raw2vdc, vdcfile, 'float64', 'bz', bz, ts=ts

if (current eq 1) then begin 
  print, 'Calculating current'
  curl, bx, by, bz, jx, jy, jz, order = 2
  write_raw2vdc, vdcfile, 'float64', 'jx', jx, ts=ts 
  write_raw2vdc, vdcfile, 'float64', 'jy', jy, ts=ts 
  write_raw2vdc, vdcfile, 'float64', 'jz', jz, ts=ts
endif

if (decay eq 1) then begin 
  disav = outdir + run + 'di.sav'
  restore, disav,/v
  write_raw2vdc, vdcfile, 'float32', 'di', di, ts=ts
endif 

if (qfactor eq 1) then begin
  qfsav = outdir + run + id + 'qfactor.sav'
  ;print, 'Calculating Q factor'
  ;cal_qfactor, bx, by, bz, qfsav=qfsav, vars=insav
  restore, qfsav
  write_raw2vdc, vdcfile, 'float32', 'slq', slq, ts=ts
  write_raw2vdc, vdcfile, 'float32', 'tw', tw, ts=ts
endif

;vdfdata = suffz + "_data"
;file_move, vdffile, outdir + vdffile, /overwrite
;file_move, vdfdata, outdir + vdfdata, /overwrite

;print, '=== RUN COMPLETE! ==='
;stop

end
