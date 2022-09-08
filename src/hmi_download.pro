pro hmi_download, segment, input_vars

; author : Avijeet Prasad
; created on : 2022-08-01
; purpose : download jsoc files and save them to a directory
; input : 
	; segments: input segments to download. Typical values
	; segments=['Br', 'Bp', 'Bt']
	; segments=['Br', 'Bp', 'Bt', 'Dopplergram', 'continuum']
; output :
; updates :
	; DONE 2022/08/02: Move the check for downloaded files to harp2fits.
	; DONE read a list of segments to download as input 
	; DONE 2022/08/18: restore sav file selectively instead of using input file

; --- Input files to set the parameters ---
isf = obj_new('IDL_Savefile', filename = input_vars)
isf->restore, ['tobs','ds','harp','datadir','run', 'tmpdir', 'outdir', 'time',$
 'jsoc_time']
obj_destroy, isf

; --- DOWNLOADING HMI DATA ---

;! -----> In case you get an error that email is not registered
; add the following line in ssw_jsoc.pro
ssw_mail_address = "avijeet.prasad@astro.uio.no"

if (n_elements(segment) eq 0) then begin 
	segment = ['Br', 'Bp', 'Bt', 'Dopplergram', 'continuum']
endif 

seg_length = n_elements(segment)

for i = 0, seg_length - 1 do begin 
	tmpfile = tmpdir + ds + '.' + harp + '.' + jsoc_time + segment[i] + '.fits'
	outfile = outdir + run + segment[i] + '.fits'
	;* check if the file already exists
	ff = findfile(tmpfile,count=count)
	if (count eq 1) then begin
  	spawn,'mv ' + tmpfile + ' ' + outfile
	endif  else harp2fits, segment[i], tobs, ds, harp, datadir, run
endfor 

print, '====================================='
print, '--------- ALL FILES DOWNLOADED. -----'
print, '====================================='

end

