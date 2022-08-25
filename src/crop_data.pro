pro crop_data, data, input_vars, cropsav=cropsav

; author : Avijeet Prasad
; created on : 2022-08-02
; purpose : to crop in segments downloaded from JSOC
; input : 
; output :
; updates :
	; TODO crop the coordinate values also 
	; DOING 2022/08/11: add option to crop local dataset

;--- Reading input variables ---
;restore the input parameter file
isf = obj_new('IDL_Savefile', filename = input_vars)
isf->restore, ['outdir','datadir','run','source','id']
obj_destroy, isf
; source = ds.substring(0,2)


;______________________ Cropping the field to optimum size ____________________
ss = size(data)
nx = ss[1]
ny = ss[2]
iaspect = float(nx)/float(ny)

spawn, 'clear'
print, 'initial nx = ' + string(nx)
print, 'initial ny = ' + string(ny)
print, 'initial aspect = ' + string(iaspect)

set_plot,'X'
loadct,0
plot_image, -1000 > data < 1000, charsize=2, charthick=2
cropin = ''
while (cropin ne 'y') do begin
	plot_image, -1000 > data < 1000, charsize=2, charthick=2
	read, xsize, prompt = 'new xsize  =  '
 	read, ysize, prompt = 'new ysize  =  '
	read, xorg, prompt  = 'new xorg   =  '
	read, yorg, prompt  = 'new yorg   =  '
	cropped_data = data[xorg:(xorg+xsize-1),yorg:(yorg+ysize-1)]
	plot_image, cropped_data
	print,'mean = ', mean(cropped_data)
	read, cropin, prompt = 'is the cropping fine? y(yes)/n(no): '
endwhile

xsize = fix(xsize)
ysize = fix(ysize)
xorg  = fix(xorg)
yorg  = fix(yorg)

print, 'cropped xsize = ' + string(xsize)
print, 'cropped ysize = ' + string(ysize)
print, 'crop xorg     = ' + string(xorg)
print, 'crop yorg     = ' + string(yorg)

iscl=''
scl = 1 
read, iscl, prompt = 'do you want to rescale the data? y(yes)/n(no):  '
if (iscl eq 'y') then begin
	read, nxsize, prompt=' new xsize  = : '
	scl = xsize/nxsize
endif
nx = fix(xsize / scl)
ny = fix(ysize / scl)
print, ' final nx = ' + string(nx)
print, ' final ny = ' + string(ny)

xys = strtrim(xsize,2) + '_' + strtrim(ysize,2) + '_' + strtrim(fix(scl),2)
cropsav = outdir + run + id + 'crop.sav'
save, outdir, run, xsize, ysize, xorg, yorg, scl, nx, ny, xys, $
	description = 'Cropping details for the data',$
	filename = cropsav
print, 'New crop details saved in: ', cropsav
end