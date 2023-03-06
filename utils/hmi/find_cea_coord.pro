; Convert the cutout index to CCD coordinate (xi,eta)
; Input: index, CEA patch center Carrington coordinate [phi_c,lambda_c], patch size [nx,ny], [dx, dy]
; Output: images xi and eta for CCD coordinate, lat and lon (Stonyhurst)

pro find_cea_coord, header, xi, eta, lat, lon, $
		phi_c, lambda_c, nx, ny, dx, dy
		
; Parameters

nx = fix(nx) & ny = fix(ny)

; Array of CEA coords

x = dblarr(nx, ny)
y = dblarr(nx, ny)

for i = 0, nx - 1 do x[i,*] = (i - (nx - 1.) / 2.) * dx * !dtor		; Stonyhurst rad
for j = 0, ny - 1 do y[*,j] = (j - (ny - 1.) / 2.) * dy * !dtor	

; Relevant ephemeris

rSun = sxpar(header, 'RSUN_OBS') / sxpar(header, 'CDELT1')		; solar radius in pixel
disk_latc = sxpar(header, 'CRLT_OBS') * !dtor
disk_lonc = sxpar(header, 'CRLN_OBS') * !dtor
disk_xc = sxpar(header, 'CRPIX1') - 1.		; in pixel wrt lower left of patch (0,0)
disk_yc = sxpar(header, 'CRPIX2') - 1.
pa = sxpar(header, 'CROTA2') * (-1.) * !dtor
print, rSun, disk_latc/!dtor, disk_lonc/!dtor, disk_xc, disk_yc, pa/!dtor

latc = lambda_c * !dtor
lonc = phi_c * !dtor - disk_lonc		; Stonyhurst

; Convert coordinate

lat = dblarr(nx, ny)
lon = dblarr(nx, ny)
for i = 0, nx - 1 do begin
for j = 0, ny - 1 do begin
	plane2sphere, x[i,j], y[i,j], latc, lonc, lat0, lon0		; Stonyhurst
	lat[i,j] = lat0
	lon[i,j] = lon0
endfor
endfor

xi = dblarr(nx, ny)		; in pixel wrt lower left of patch (0,0)
eta = dblarr(nx, ny)
for i = 0, nx - 1 do begin
for j = 0, ny - 1 do begin
	sphere2img, lat[i,j], lon[i,j], disk_latc, 0., xi0, eta0, $
			disk_xc, disk_yc, rSun, pa
	xi[i,j] = xi0
	eta[i,j] = eta0
endfor
endfor

;

return

end
