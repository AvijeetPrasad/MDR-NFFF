pro bnfff_prep, input_vars, prepsav=prepsav

; created-on: June 25, 2018 by Avijeet Prasad
; description: prepare the input data for NFFF extrapolations
; input: 
	;input_vars: save file containing all the input variables

Common Block,BVX,BVY,BVZ,Bres
Common Block2,bx0,by0,bz0,Jz0,bzc0,bx03,by03,bz03,bxc,byc

;--- Reading input variables ---
;restore the input parameter file
isf = obj_new('IDL_Savefile', filename = input_vars)
;print the variables saved in the input file
print, isf->names() 
; restore the paths
isf->restore,['datadir','run','ds','event','time','check_crop','harp','id','dataformat']
;restore download
if (dataformat eq 'sav') then isf->restore, ['savdir','savfile','bvecs']
; restore crop parameters
if (check_crop eq 'no') then $
isf->restore, 'cropsav'
; destroy object
obj_destroy, isf

;=== Downloading/Restoring data ===
if (ds eq 'hmi.sharp_cea_720s') then begin 
	if (dataformat eq 'fits') then begin 
		print, '=== downloaing files from JSOC ==='
		segments = ['Br', 'Bp', 'Bt', 'Dopplergram', 'continuum']
		seg_length = n_elements(segment)
		hmi_download, segments, input_vars	
		read_sdo, datadir + run + 'Br.fits', index, br
		read_sdo, datadir + run + 'Bp.fits', index_bp, bp
		read_sdo, datadir + run + 'Bt.fits', index_bt, bt
		read_sdo, datadir + run + 'Dopplergram.fits', index_dopp, dopp
		read_sdo, datadir + run + 'continuum.fits', index_cont, cont 
		
		bz = br
		bx = bp 
		by = -bt 
		
		hmisav = datadir + run + 'hmi.sav'
		save, bx, by, bz, dopp, cont, index, $
		description = 'hmi sharp data', filename = hmisav
	endif else begin
		print, '======= restoring save file: ', hmisav 
		restore, hmisav, /v
		br = bz
		bp = bx
		bt = -by
		xorg = 0
		yorg = 0
	endelse  
endif else begin 
	print, '======= restoring save file: ', savfile 
	if (not(isa(bvecs))) then bvecs = ['bx0','by0','bz0']
	bvecsav = savdir + savfile
	isf = obj_new('IDL_Savefile', filename = bvecsav)
	isf->restore, bvecs,/v
	
	; define the magnetic field variables from the bvec list
	bx = scope_varfetch(bvecs[0])
	by = scope_varfetch(bvecs[1])
	bz = scope_varfetch(bvecs[2])
	help, bz
endelse 

; === Cropping the field of view ===
if (check_crop eq 'yes') then begin 
	print, '=== cropping fov ==='
	crop_data, bz, input_vars, cropsav = cropsav
endif	else begin 
	cropsav = datadir + run + id + 'crop.sav'
endelse 

isf = obj_new('IDL_Savefile', filename = cropsav)
isf->restore, ['xorg','yorg','xsize','ysize','scl','nx','ny','xys']
if (check_crop eq 'no') then begin
	isf->restore, 'nz' ; restore nz from the input file
endif else begin ; else take input from user
	read, nz, prompt='enter height nz =  '
  nz = fix(nz)
endelse 
obj_destroy, isf

xyz  = strtrim(fix(nx),2) + '_' + strtrim(fix(ny),2) + '_' + strtrim(nz,2) + '_'
suff = run + id + xyz 

if isa(index) then begin
	rescale_data, bz, cropsav, bz0, index=index, solx=solx, soly=soly
	rescale_data, bx, cropsav, bx0, index=index
	rescale_data, by, cropsav, by0, index=index 

	if (ds eq 'hmi.sharp_cea_720s') then begin
		rescale_data, dopp, cropsav, index=index, dopp0
		rescale_data, cont, cropsav, index=index, cont0
	endif 
endif 

; rescale sav input also 
if (dataformat eq 'sav') then begin 
	rescale_data, bz, cropsav, bz0
	rescale_data, bx, cropsav, bx0
	rescale_data, by, cropsav, by0
endif 


;else begin 
		; rescale_data, bz, cropsav, bz0
		; rescale_data, bx, cropsav, bx0
		; rescale_data, by, cropsav, by0 		
;endelse  

;=== Calculation of Jz at the bottom boundary ===
xx = findgen(nx)
yy = findgen(ny)
; calculating dbx_dy

	dbx_dy=fltarr(nx,ny)
	for i=0,nx-1 do begin
		dbx_dy[i,*]=deriv(yy,bx0[i,*])
	endfor

; calculating dby_dx

	dby_dx=fltarr(nx,ny)
	for j=0,ny-1 do begin
		dby_dx[*,j]=deriv(xx,by0[*,j])
	endfor

	jz0 = dby_dx-dbx_dy

	;window, 0
	;loadct, 0
	;plot_image,(mean(jz0)-4*stddev(jz0))>jz0<(mean(jz0)+4*stddev(jz0))
	alpha = make_array(nx, ny,/float,value=0.0)
	for i=0, nx-1 do begin
		for j=0, ny-1 do begin
			if abs(bz0[i,j] ge 20) then alpha[i,j] = jz0[i,j]/bz0[i,j]
		endfor
	endfor
	pos = where (alpha ne 0)
	alphaf = alpha(pos)
	;window,1

;=== Exporting final inputs for extrapolation 

prepsav = datadir + suff + 'prep.sav'
save, bx0, by0, bz0, jz0, nx, ny, nz, xsize, ysize, suff,$
xorg, yorg, scl, event, time, xys, xyz, filename = prepsav

outfile= datadir + suff + 'prep.txt';
if not file_test(outfile) then openw, unitout, outfile,/get_lun $
  else openu, unitout, outfile,/append, /get_lun
printf, unitout, 'event: ' + event
printf, unitout, 'time: '  + time
printf, unitout, 'nx: '    + string(nx)
printf, unitout, 'ny: '    + string(ny)
printf, unitout, 'nz: '    + string(nz)
printf, unitout, 'xsize: ' + string(xsize)
printf, unitout, 'ysize: ' + string(ysize)
printf, unitout, 'xorg: '  + string(xorg)
printf, unitout, 'yorg: '  + string(yorg)
printf, unitout, 'scl: '   + string(scl)
free_lun,unitout

;--------- the last bit :) ---------------
; print, 'copying the modified file to: ' + outdir
; prof1   = strsplit(prof, '.',/ extract)
; outf = outdir+prof1[0]+'_'+suff+'.pro'
; spawn, 'cp '+ prof+'.pro' +' '+ outf
; spawn, 'clear'

print, '--------------------!!! DATA READY FOR EXTRAPOLATION !!! --------------'
print, 'event = '   + event
print, 'time  = '   + time
print, 'xyz = '     + xyz.substring(0,-2)
print, 'savfile = ' + prepsav 

end

