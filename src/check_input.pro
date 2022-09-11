pro check_input, input, input_vars=input_vars, ts_index = ts_index

;+ 
; name: check_input
;
; purpose: read the input file for a run, perform some checks and generate
;           an sav file containing all the final input parameters
;
; calling sequence: check_input, input, input_vars=input_vars
;
; inputs: 
;        input: full path of the input parameter file
;        ts_index: (optional) time index of the time series runs
; outputs:
;         input_vars: an idl sav file containing all the input parameters 
;         required for the run.
;
; author : Avijeet Prasad
; created on : 2022-08-23
;
; updates :
;-

; check if input parameter is specified
if (not (isa(input))) then begin 
  codesdir='/mn/stornext/u3/avijeetp/codes/idl/extrapolation/'
  ;input = codesdir + 'input.pro'
  input = file_search(codesdir, 'input.pro', count=fcount)
  print, 'Input file not specified, using: ', input
  if (fcount eq 0) then begin 
    print, 'Input file not found!'
    stop 
  endif 
endif 

;* read the input file 
file_exists = file_test(input)
if not(file_exists) then begin 
  print, 'Input file not found!! '
  stop 
endif else print, '=== Reading input file ==='

@input  ; <--- Include the input file

; setup output directory for different procedures
; define an event directory
eventdir = projectdir + event

; define a local temp directory for the folder where data would be temporarily
; saved. this would be the default location to check for savfiles
tmpdir = eventdir + '/data/'

;--- Check for time series option ---
if isa(ts_index) then  begin 
  print, 'Time series run, index = ', ts_index
  if (n_elements(tobs) gt 1) then begin
    tstart = tobs[0]
    tend = tobs[1]
    if n_elements(tobs) eq 3 then cad = tobs[2]
    mktseq, tstart, tend, tseq, times, nt, cad=cad
    tobs = tseq[ts_index]
    ;create a directory to hold the time series run info
    tsdir = eventdir + '/extrapolation/' + times[0] + '_' + times[-1] +'/'
    check_dir, tsdir ; check time series directory
  endif
endif 

; --- Setup paths for saving output ---
; formatted time string from observation time
mktime, tobs, time, jsoc_time 

; generate a unique run id from timestamp if not defined in the input file
; mode is automatically set to analysis if id is specified
if isa(id) then begin 
  id   = id + '_'
  mode = 'analysis' 
endif else id  = strtrim(round(systime(/seconds)),1) + '_' 
 
; create a suffix string based on the event, time, dataset and procedure
run = event + '_' + time + '_' + ds +'_' + proc + '_' 

if (proc eq 'ambig') then begin
  outdir    = eventdir + '/ambig/' + time + '/'
  ambigvars = outdir + run + id + 'ambigvars.sav'
endif 

if (proc eq 'bnfff') then begin 
  outdir   = eventdir + '/extrapolation/' + time + '/'
  datadir  = outdir
  nfffvars = outdir + run + id + 'nfffvars.sav'
endif  

if (proc eq 'hmi_vplot') then begin
  datadir = eventdir + '/extrapolation/' + time + '/'
	outdir  = datadir  
	outfile = 'HMI_' + event + '_' + time
endif

; --- Check paths and create if they don't exist---
check_dir, projectdir ; check project directory
check_dir, eventdir   ; check event directory
check_dir, tmpdir     ; check datadir 
check_dir, datadir    ; check datadir 
check_dir, outdir     ; check outdir 

; if the dataformat is sav, then check for savfile 
; first in the tmpdir and then in the outdir
; stop execution if file not found
if (dataformat eq 'sav') then begin 
  check1 = file_test(tmpdir + savfile)
  if check1 then begin 
    print, 'sav file found in temp directory, copying it to outdir'
    file_copy, tmpdir + savfile, outdir + savfile, /overwrite
  endif else begin 
    check2 = file_test(savdir + savfile)
    if not check2 then begin 
      print, 'sav file not found'
      stop 
    endif else begin
      file_copy, savdir + savfile, outdir + savfile, /overwrite
    endelse
  endelse  
endif 

; if (download eq 'no') then begin
;   if (ds eq 'hmi.sharp_cea_720s') $ 
;     then check_file, datadir + run + 'hmi.sav' $
;     else check_file, datadir + savfile
; endif

if (check_crop eq 'no') then begin 
  ; should be same as crop_data
  xys = strtrim(xsize,2) + '_' + strtrim(ysize,2) + '_' + strtrim(fix(scl),2)
  nx = fix(xsize / scl)
  ny = fix(ysize / scl)
  cropsav = outdir + run + id + 'crop.sav'
  save, outdir, run, xsize, ysize, xorg, yorg, scl, nz, harp, nx, ny, xys, $
	  description = 'Cropping details for the segment',$
	  filename = cropsav
endif  

; --- If not specified find harp number for sharp cutouts ---
if (event eq 'QS') then begin 
  harp = 0
endif else begin 
  noaa = strmid(event,2,5)	; NOAA number of the AR, read from event
  if (n_elements (harp) eq 0) then begin
    findharp, noaa, harp
  endif else begin
    print, 'harp = ', harp 
  endelse 
endelse

cls 
if (mode eq 'analysis') then begin 
  print, 'mode = ', mode
  print, 'id   = ', id.substring(0,-2)
endif 
; --- print paths and event details for quick check ---
;PRINT, event, tobs, FORMAT = 'The values are: %s %s'
;https://www.l3harrisgeospatial.com/docs/using_explicitly_formatt.html#Examples

print, '=== RUN DETAILS ==='
print, ' '
print, 'event = ', event
print, 'time  = ', tobs 
print, 'event directory  = ', eventdir + '/'
print, 'output directory = event dir + ', outdir.substring(eventdir.strlen()+1)
print, 'run id = ', id.substring(0,-2)
if (dataformat eq 'sav') then print, 'input file = ', savfile
print, ' '

input_vars = outdir + run + id + 'input_vars.sav' 
input_check = ' '
; do not check inputs for time series run with ts_index greater than 0
if (isa(ts_index)) then begin 
  if (ts_index gt 0) then input_check = 'y' $
  else read, input_check, prompt='Do the parameters look correct (y/n)? : '
endif else read, input_check, prompt='Do the parameters look correct (y/n)? : '
if (input_check eq 'y') then begin
  ; --- save the input file in the outdir
  outfile = outdir + run + id + 'input.pro' 
  file_copy, 'input.pro', outfile, /overwrite ;save the file
  print, 'input file saved in: ', outfile

  ;Optionally save a copy in include folder of the codesdir for future reference
  if (file_test(codesdir + 'include',/directory)) then begin 
    include_copy = codesdir + 'include/in_' + proc + '_' + event $
      + '_' + ds.substring(0,2) + '.pro' 
    file_copy, 'input.pro', include_copy, /overwrite 
  endif 

endif else begin 
  print, 'Please re-enter the parameters'
  stop 
endelse 
save, /variables, filename = input_vars, $
  description = 'List of all the input variables'
print, 'Input variables saved in: ', input_vars

end 