pro harp2fits,segment,t,ds,harp,outdir,run  
; purpose: download a segment from JSOC and write it out to a local fits file
; author: Avijeet Prasad
; created on: 2022/08/02
; inputs: see example below
	; segment: 'continuum' ; jsoc segment to download
	; t: '10:36 02-jul-2012' ; start time of download
	; ds: 'hmi.sharp_cea_720s' ; jsoc data series
	; harp: 1807 ; harp number of the active region 
; updates:
  ; DONE 2022/08/02: add a check to see if file is already downloaded

file = run + segment + '.fits'
;* check if the file already exists
ff = findfile(outdir + file,count=count)
if (count eq 1) then begin
  print, file, ' already exists!'
endif else begin
	ssw_jsoc_time2data, t, t, index, data, ds=ds, harpnum=harp, segment=segment, $
	outdir_top = outdir, /comp_delete, /uncomp_delete
	mwritefits, index, data, outfile = outdir + file
	print, segment + '.fits written in: ', outdir + file
endelse 

end 