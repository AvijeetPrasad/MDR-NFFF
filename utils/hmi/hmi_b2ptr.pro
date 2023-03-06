;+
; NAME:
;   hmi_b2ptr
; PURPOSE:
;	Convert HMI vector field in native components
;	(field, inclination, azimuth w.r.t. plane of sky)
;	into spherical coordinate components
;	(zonal B_p, meridional B_t, radial B_r)
;	For details, see
;	Sun, 2013, ArXiv, 1309.2392 (http://arxiv.org/abs/1309.2392)
; SAMPLE CALLS:
;	IDL> files = ['hmi.sharp_720s.377.20110215_000000_TAI.field.fits', $
;	IDL> 		  'hmi.sharp_720s.377.20110215_000000_TAI.inclination.fits', $
;	IDL> 		  'hmi.sharp_720s.377.20110215_000000_TAI.azimuth.fits']
;	IDL> read_sdo, files, index, data
;	IDL> hmi_b2rtp, index[0], data, bptr, lonlat=lonlat
; INPUT:
;	index:	Index structure
;	bvec:	Three dimensional array [nx,ny,3], for three images: field (G), 
;			inclination (deg) and azimuth (deg) arrays. Inclination is defined 0
;			perpendicular out of the plane-of-sky (POS) and !pi into the POS.
;			Azimuth is 0 in +y CCD direction and increase CCW
; OUTPUT:
;	bptr:	Three dimensional array [nx,ny,3], for three images: Bp, Bt, Br (G)
;			Bp is positive when pointing west; Bt is positive when pointing south
; OPTIONAL OUTPUT:
;	lonlat:	Three dimensional array [nx,ny,2], for two images: 
;			Stonyhurst longitude and latitude
; HISTORY:
;   2014.02.01 - Xudong Sun (xudongs@sun.stanford.edu)
; NOTE:
;	Written for HMI full disk and SHARP data, header needs to conform
;	WCS standard. Minimal check implemented so far
;	For full disk images, large memory is needed
;	Note the output retains the p-angle of bvec
;	The sign of the field vector is independent of the image orientation 
;	i.e. if Bt is positive (southward) and the image is upside-down (p=180),
;	it remains positive (southward) when the image is rotated by 180 deg
;-

pro hmi_b2ptr, index, bvec, bptr, lonlat=lonlat

; Check dimensions only
; No further WCS check implemented

sz = size(bvec)
nx = sz[1] & ny = sz[2] & nz = sz[3]
if (sz[0] ne 3 or nx ne index.naxis1 or ny ne index.naxis2 or nz ne 3) then begin
	print, 'Dimension of bvec incorrect'
	return
endif

; Convert bvec to B_xi, B_eta, B_zeta
; as defined in Eq (1) in Sun (2013)

field = bvec[*,*,0]
gamma = bvec[*,*,1] * !dtor
psi = bvec[*,*,2] * !dtor

b_xi = - field * sin(gamma) * sin(psi)
b_eta = field * sin(gamma) * cos(psi)
b_zeta = field * cos(gamma)

; HMI pipeline uses ref solar radius 6.96d8, different
; from SSW default. See wcs_rsun.pro

setenv, 'WCS_RSUN=6.96d8' ; value used by HMI pipeline

; WCS conversion

wcs = fitshead2wcs(index)
coord = wcs_get_coord(wcs)

; Get Stonyhurst lon/lat

wcs_convert_from_coord, wcs, coord, 'HG', phi, lambda

lonlat = fltarr(nx,ny,2)
lonlat[*,*,0] = phi
lonlat[*,*,1] = lambda

; Get matrix to convert, according to Eq (1) in Gary & Hagyard (1990)
; See Eq (7)(8) in Sun (2013) for implementation

b = index.crlt_obs * !dtor		; b-angle, disk center latitude
p = - index.crota2 * !dtor		; p-angle, negative of CROTA2

phi = phi * !dtor
lambda = lambda * !dtor

sinb = sin(b) & cosb = cos(b)
sinp = sin(p) & cosp = cos(p)
sinphi = sin(phi) & cosphi = cos(phi)			; nx*ny
sinlam = sin(lambda) & coslam = cos(lambda)		; nx*ny

k11 = coslam * (sinb * sinp * cosphi + cosp * sinphi) - sinlam * cosb * sinp
k12 = - coslam * (sinb * cosp * cosphi - sinp * sinphi) + sinlam * cosb * cosp
k13 = coslam * cosb * cosphi + sinlam * sinb
k21 = sinlam * (sinb * sinp * cosphi + cosp * sinphi) + coslam * cosb * sinp
k22 = - sinlam * (sinb * cosp * cosphi - sinp * sinphi) - coslam * cosb * cosp
k23 = sinlam * cosb * cosphi - coslam * sinb
k31 = - sinb * sinp * sinphi + cosp * cosphi
k32 = sinb * cosp * sinphi + sinp * cosphi
k33 = - cosb * sinphi

; Output, (Bp,Bt,Br) is identical to (Bxh, -Byh, Bzh)
; in Gary & Hagyard (1990), see Appendix in Sun (2013)

bptr = fltarr(nx,ny,3)

bptr[*,*,0] = k31 * b_xi + k32 * b_eta + k33 * b_zeta
bptr[*,*,1] = k21 * b_xi + k22 * b_eta + k23 * b_zeta
bptr[*,*,2] = k11 * b_xi + k12 * b_eta + k13 * b_zeta

end
