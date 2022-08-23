pro check_input, input, input_vars=input_vars

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
;
; outputs:
;         input_vars: an idl sav file containing all the input parameters 
;         required for the run.
;
; author : Avijeet Prasad
; created on : 2022-08-23
;
; updates :
;-

;TODO check if the input file exists 
if (not (isa(input))) then begin 
  print, 'Input file not specified'
  codesdir='/mn/stornext/d18/RoCS/avijeetp/codes/extrapolation/MDR-NFFF/src/'
  input = codesdir + 'input.pro'
endif 

;* read the input file 
file_exists = file_test(input)
if not(file_exists) then begin 
  print, 'Input file not found!! '
  stop 
endif else print, '=== Reading input file ==='
@input
; --- Setup paths for saving output ---
mktime, tstart,time,jsoc_time ; formatted time string
;generate a unique run id from timestamp if not defined in the input file
if isa(id) then begin 
  id   = id + '_'
  mode = 'analysis' 
endif else id  = strtrim(round(systime(/seconds)),1) + '_' 
;id  = id.substring(-3) + '_'
run = event + '_' + time + '_' + ds +'_' + prof + '_' 
datadir = hd + event + '/extrapolation/' + time + '/'

if (prof eq 'bnfff') then begin 
  outdir  = datadir
  nfffvars = datadir + run + id + 'nfffvars.sav'
endif  

if (prof eq 'hmi_vplot') then begin
	outdir  = hd + event + '/plots/'
	outfile = 'HMI_' + event + '_' + time
endif

; --- Check paths ---
check_dir, datadir ; check if datadir exist else create it
check_dir, outdir 

if (download eq 'no') then begin
  if (ds eq 'hmi.sharp_cea_720s') $ 
    then check_file, datadir + run + 'hmi.sav' $
    else check_file, datadir + savfile
endif
if (crop eq 'no') then begin 
  ; should be same as crop_data
  xys = strtrim(xsize,2) + '_' + strtrim(ysize,2) + '_' + strtrim(fix(scl),2)
  nx = fix(xsize / scl)
  ny = fix(ysize / scl)
  cropsav = datadir + run + id + 'crop.sav'
  save, datadir, run, xsize, ysize, xorg, yorg, scl, nz, harp, nx, ny, xys, $
	  description = 'Cropping details for the segment',$
	  filename = cropsav
endif  

; --- If not specified find harp number for sharp cutouts ---
noaa     = strmid(event,2,5)	; NOAA number of the AR, read from event
if (n_elements (harp) eq 0) then begin
  findharp,noaa,harp,codesdir=codesdir
endif else begin
  print, 'harp = ', harp 
endelse 

cls 
if (mode eq 'analysis') then begin 
  print, 'mode = ', mode
  print, 'id   = ', id.substring(0,-2)
endif 
; --- print paths and event details for quick check ---
;PRINT, event, tstart, FORMAT = 'The values are: %s %s'
;https://www.l3harrisgeospatial.com/docs/using_explicitly_formatt.html#Examples
evdir = hd + event
print, '=== RUN DETAILS ==='
print, ' '
print, 'event = ', event
print, 'time  = ', tstart 
print, 'event directory  = ', hd + event + '/'
print, 'output directory = event dir + ', datadir.substring(evdir.strlen()+1)
if (download eq 'sav') then print, 'input file = ', savefile
print, ' '

input_vars = datadir + run + id + 'input_vars.sav' 
input_check = ' '
read, input_check, prompt='Do the parameters look correct (y/n)? : '
if (input_check eq 'y') then begin
  ; --- save the input file in the datadir
  outfile = datadir + run + id + 'input.pro' 
  file_copy, 'input.pro', outfile, /overwrite ;save the file
  print, 'input file saved in: ', outfile
endif else begin 
  print, 'Please re-enter the parameters'
  stop 
endelse 
save, /variables, filename = input_vars, $
  description = 'List of all the input variables'
print, 'Input variables saved in: ', input_vars

end 