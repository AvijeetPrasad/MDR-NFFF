pro bnfffs

;+ 
; name: bnfffs
;
; purpose: Give a time series run for NFFF extrapolations
;
; calling sequence: 
;
; inputs: 
;        input: 
;
; outputs:
;         output:
;
; author : Avijeet Prasad
; created on : 2022-09-09
;
; updates :
;-

@compile_routine

;include the input parameter file
codesdir = '/mn/stornext/u3/avijeetp/codes/idl/extrapolation/'
input = codesdir + 'input.pro'

@input  ; <--- Include the input file

eventdir = projectdir + event
tstart = tobs[0]
tend = tobs[1]
cad = tobs[2]
mktseq, tstart, tend, tseq, times, nt, cad=cad
tsdir =  projectdir + event + '/extrapolation/ts_' + times[0] + '_' + times[-1] +'/'
check_dir, tsdir
if not isa(ids) then begin 
  ids = strarr(nt)
  id =ids[0]
endif 
inputs = strarr(nt)
tssav = tsdir + event + '_' + id + '_tseries.sav'

;-----------------------
if (mode eq 'calculate') then begin
  for t = 0, nt - 1 do begin 
    print, 't = ' + strtrim(t+1,2) + ' out of ' + strtrim(nt,2)
    print, 'time = ', tseq[t]
    check_input, input, input_vars=input_vars, index=t
    restore, input_vars,/v 
    ids[t] = id
    inputs[t] = input_vars
    bnfff_prep, input_vars, prepsav=prepsav
    nonff2, input_vars, prepsav
    nonff25d, input_vars, prepsav, bnfffsav=bnfffsav
  endfor 
  save, ids, inputs, filename = tssav
endif 

;------------------------
if (mode eq 'analysis') then begin
  if not isa(ids) then begin
    checksav = file_test(tssav)
    if (checksav) then restore, tssav,/v else print, 'ids not found!'
  endif else begin 
    print, 'ids = ', n_elements(ids)
    if not file_test(tssav) then save, ids, inputs, filename = tssav
  endelse   
  for t = 0, nt - 1 do begin
    print, 't = ' + strtrim(t+1,2) + ' out of ' + strtrim(nt,2)
    print, 'time = ', tseq[t]
    time = times[t]
    id = ids[t]+'_'
  
    outdir   = eventdir + '/extrapolation/' + time + '/'
    run = event + '_' + time + '_' + ds +'_' + proc + '_' 
    bnfffsav = file_search(outdir + run + id + '*_Bnfff.sav')

    isf = obj_new('IDL_Savefile', filename = bnfffsav)
    isf->restore,['bx','by','bz']  
    obj_destroy, isf

    input_vars = outdir + run + id + 'input_vars.sav' 
    if (decay   eq 1) then  cal_di, bx, by, bz, disav=disav, vars=input_vars
    if (qfactor eq 1) then cal_qfactor, bx, by, bz, qfsav=qfsav, vars=input_vars 
    if (vapor eq 1) then sav2vdc, bnfffsav, insav=input_vars 

  endfor 
endif


print, '======================================'
print, '    --------- RUN COMPLETE -------      '
print, '======================================'

stop
end
