; prepare header

pro prep_hd, hd, hd_out, phi_c, lambda_c, nx, ny, dx, dy

; Get template


;restore, 'cea_header.sav'		; hdr

;hd_out = hdr

hd_out = hd
; Copy times, etc

keys0 = ['DATE','DATE_S','DATE-OBS','T_OBS','T_REC','TRECEPOC','HARPNUM']
keys1 = ['DSUN_OBS','DSUN_REF','RSUN_REF','CRLN_OBS','CRLT_OBS','CAR_ROT',$
		'OBS_VR','OBS_VW','OBS_VN','RSUN_OBS']
keys2 = ['QUALITY','QUAL_S','QUALLEV1']
n0 = n_elements(keys0)
n1 = n_elements(keys1)
n2 = n_elements(keys2)

for i = 0, n0 - 1 do sxaddpar, hd_out, keys0[i], sxpar(hd, keys0[i]), before='TRECSTEP'
for i = 0, n1 - 1 do sxaddpar, hd_out, keys1[i], sxpar(hd, keys1[i]), before='TELESCOP'
for i = 0, n2 - 1 do sxaddpar, hd_out, keys2[i], sxpar(hd, keys1[i]), before='BUNIT'

; Adding parameters

sxaddpar, hd_out, 'NAXIS', 2, format='(i)', before='EXTEND'
sxaddpar, hd_out, 'NAXIS1', nx, format='(i)', before='EXTEND'
sxaddpar, hd_out, 'NAXIS2', ny, format='(i)', before='EXTEND'

sxaddpar, hd_out, 'CRPIX1', (nx - 1.) / 2. + 1., format='(f)', before='CUNIT1'
sxaddpar, hd_out, 'CRPIX2', (ny - 1.) / 2. + 1., format='(f)', before='CUNIT1'
sxaddpar, hd_out, 'CRVAL1', phi_c, format='(f)', before='CUNIT1'
sxaddpar, hd_out, 'CRVAL2', lambda_c, format='(f)', before='CUNIT1'
sxaddpar, hd_out, 'CDELT1', dx, format='(f)', before='CUNIT1'
sxaddpar, hd_out, 'CDELT2', dy, format='(f)', before='CUNIT1'

end
