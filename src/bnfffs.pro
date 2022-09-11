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

;@input  ; <--- Include the input file
; Check input and restore the input variables
check_input, input, input_vars = input_vars, ts_index=0
restore, input_vars,/v 

; Check if a list of ids was provided at the input else initalize an array
if not isa(ids) then ids = strarr(nt)
; id =ids[0]
; Check if the id has a trailing underscore else add it
check_id = id.substring(-1) ne '_'
if check_id then id = id + '_'
; Initialize an array for saving the inputs at various time steps
inputs = strarr(nt)
; Define a file name for saving ids, and inputs for later use
savts = tsdir + event + '_' + id + 'ts.sav'
;TODO add a condition to restore savts from previous runs if the file exists
; Give the file name for the vdc file for the entire time series
  vdcfile = tsdir + event + '_' + id + 'ts.vdc'
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
  save, ids, inputs, current, qfactor, decay, filename = savts
endif 

;TODO add dims in the output vdc file usind check_dims procedure
;------------------------
if (mode eq 'analysis') then begin
  if not isa(ids) then begin
    checksav = file_test(savts)
    if (checksav) then restore, savts,/v else print, 'ids not found!'
  endif else begin 
    print, 'ids = ', n_elements(ids)
    if not file_test(savts) then begin 
      save, ids, inputs, current, qfactor, decay, filename = savts
    endif 
  endelse   
  
  ; Start of time loop 
  for t = 0, nt - 1 do begin
    print, '----------------------------------'
    print, 't = ' + strtrim(t+1,2) + ' out of ' + strtrim(nt,2)
    print, 'time = ', tseq[t]
    print, '----------------------------------'

    ; setup the time step and id
    time = times[t]
    id = ids[t]
    if (id.substring(-1) ne '_') then id = id + '_'

    ; ensure that numts and ts are strings passed without trailing spaces
    numts = strtrim(nt,2)
    ts = strtrim(t,2)

    ; restore the magnetic field data and input variables file
    outdir   = eventdir + '/extrapolation/' + time + '/'
    run = event + '_' + time + '_' + ds +'_' + proc + '_' 
    input_vars = outdir + run + id + 'input_vars.sav' 

    bnfffsav = file_search(outdir + run + id + '*_Bnfff.sav')
    isf = obj_new('IDL_Savefile', filename = bnfffsav)
    isf->restore,['bx','by','bz']  
    obj_destroy, isf

    ; calculate decay index
    ;if (decay   eq 1) then  cal_di, bx, by, bz, disav=disav, vars=input_vars
    ; calculate qfactor
   ; if (qfactor eq 1) then cal_qfactor, bx, by, bz, qfsav=qfsav, vars=input_vars 
    ; write the vapor output
    if (vapor eq 1) then begin 
      ; single file outputs for each time step
    ;  sav2vdc, bnfffsav, insav=input_vars
      ; combined vdf file for all time steps 
      sav2vdc, bnfffsav, insav=input_vars, numts=numts, ts=ts, vdcfile=vdcfile,$
        savts=savts
    endif 

  endfor 
endif
input_copy = tsdir + event + '_' + id + 'input.pro'
file_copy, 'input.pro', input_copy, /overwrite 

print, '======================================'
print, '    --------- RUN COMPLETE -------      '
print, '======================================'

stop
end
