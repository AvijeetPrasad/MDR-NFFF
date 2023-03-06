; This module converts FD or cutout vector field to CEA maps
; Input: File names of field, inclination, azimuth
; Output: File names of Bp, Bt, Br
; Optional input: center coordinate, image size, pixel size
;		(if not provided, compute from cutout header;
;		 if there is no info of patches, as in FD, the module fails)
; Example: creating a 600x600 CEA map centered at Carrington lon 170, lat 13
; bvec2cea, 'hmi.B_720s.20160524_140000_TAI.field.fits', $
; 			'hmi.B_720s.20160524_140000_TAI.inclination.fits', $
; 			'hmi.B_720s.20160524_140000_TAI.azimuth.fits', $
; 			bp, bt, br, hd_out, $
; 			infile_disamb='hmi.B_720s.20160524_140000_TAI.disambig.fits', $
; 			phi_c=170, lambda_c=13, nx=600, ny=600
;writefits, 'br.fits', br, hd_out

pro bvec2cea, infile_fld, infile_inc, infile_azi, bp, bt, br, hd_out, $
			infile_disamb=infile_disamb, amb=amb, $
			phi_c=phi_c, lambda_c=lambda_c, nx=nx, ny=ny, dx=dx, dy=dy, xyz=xyz,$
			codesdir=codesdir

; Check file consistency
so_path = codesdir + 'utils/hmi'
;TODO remove the hard-coded path for `so_path` and make it more general

print,'====== HELLO!!! ==========='
fld = fitsio_read_image(infile_fld, hd, so_path=so_path)
inc = fitsio_read_image(infile_inc, so_path=so_path) * !dtor
azi = fitsio_read_image(infile_azi, so_path=so_path) * !dtor

if (keyword_set(infile_disamb)) then begin			; disambiguation
	disamb = fitsio_read_image(infile_disamb, so_path=so_path)
	sz = size(disamb) & sz_a = size(azi)
	if (sz[1] ne sz_a[1] or sz[2] ne sz_a[2]) then begin
		printf, 'disambiguation resolution does not match azimuth'
		return
	endif
	if (not keyword_set(amb)) then begin
		amb = 2
	endif else begin
		amb = fix(amb)
		if (amb gt 2 or amb lt 0) then amb = 2		; default radial acute
	endelse
	disamb = disamb / (2 ^ amb)
	idx = where(disamb ne 0, cc)
	if (cc ne 0) then azi[idx] += !pi 
endif

sz_f = size(fld) & sz_i = size(inc) & sz_a = size(azi)
if (sz_f[1] ne sz_i[1] or sz_f[2] ne sz_i[2] or $
	sz_f[1] ne sz_a[1] or sz_f[2] ne sz_a[2]) then begin
	print, 'input image size do not match'
	return
endif

; Check requested output parameters

keys = ['crlt_obs','crln_obs','crota2','rsun_obs','cdelt1','crpix1','crpix2']
nkeys = n_elements(keys)

have_keys = 1
for i = 0, nkeys - 1 do begin
	key_val = sxpar(hd, keys[i], count=ct)
	if (ct eq 0) then $
		print, 'Keyword '+keys[i]+' missing'
	have_keys *= ct
endfor

if (have_keys eq 0) then return

maxlon = sxpar(hd, 'LONDTMAX', count=cln1)
minlon = sxpar(hd, 'LONDTMIN', count=cln0)
maxlat = sxpar(hd, 'LATDTMAX', count=clt1)
minlat = sxpar(hd, 'LATDTMIN', count=clt0)

if (not keyword_set(phi_c)) then begin
	if (cln1 eq 0 or cln0 eq 0) then begin
		print, 'No x center' & return
	endif
	phi_c = (maxlon + minlon) / 2. + sxpar(hd, 'CRLN_OBS')
endif

if (not keyword_set(lambda_c)) then begin
	if (clt1 eq 0 or clt0 eq 0) then begin
		print, 'No y center' & return
	endif
	lambda_c = (maxlat + minlat) / 2.
endif

if (not keyword_set(dx)) then dx = 0.03 else dx = abs(dx) 
if (not keyword_set(dy)) then dy = 0.03 else dy = abs(dy)

if (not keyword_set(nx)) then begin
	if (cln1 eq 0 or cln0 eq 0) then begin
		print, 'No x dimension' & return
	endif
	nx = round(round((maxlon - minlon) * 1.d3) / 1.d3 / dx)
endif

if (not keyword_set(ny)) then begin
	if (clt1 eq 0 or clt0 eq 0) then begin
		print, 'No y dimension' & return
	endif
	ny = round(round((maxlat - minlat) * 1.d3) / 1.d3 / dx)
endif

; Find coordinate

xi = dblarr(nx, ny)		; in pixel wrt lower left of patch (0,0)
eta = dblarr(nx, ny)
lat = dblarr(nx, ny)
lon = dblarr(nx, ny)

find_cea_coord, hd, xi, eta, lat, lon, $
			phi_c, lambda_c, nx, ny, dx, dy		; get xi, eta

; Get bxyz_img

bx_img = - fld * sin(inc) * sin(azi)
by_img = fld * sin(inc) * cos(azi)
bz_img = fld * cos(inc)

; Perform sampling

bx_map = interpolate(bx_img, xi, eta, missing=!values.f_nan)
by_map = interpolate(by_img, xi, eta, missing=!values.f_nan)
bz_map = interpolate(bz_img, xi, eta, missing=!values.f_nan)

; Vector transform

disk_lonc = 0.
disk_latc = sxpar(hd, 'CRLT_OBS') * !dtor
pa = sxpar(hd, 'CROTA2') * (-1.) * !dtor

img2heliovec, bx_map, by_map, bz_map, bp, bt, br, lon, lat, disk_lonc, disk_latc, pa
if (not keyword_set(xyz)) then bt *= (-1.)

; Prepare header

prep_hd, hd, hd_out, phi_c, lambda_c, nx, ny, dx, dy

end
