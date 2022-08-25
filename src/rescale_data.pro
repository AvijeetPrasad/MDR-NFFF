pro rescale_data, data, cropsav, scaled_data,index=index, solx=solcx, soly=solcy

; author : Avijeet Prasad
; created on : 2022-08-02
; purpose : 
; input : 
  ;cropsav: sav file containing cropping details (from crop_segment)
; output :
; updates : 
; DONE 2022/08/18: remove @input file dependence
; DONE 022/08/18: 8make code more flexible for non HMI data

isf = obj_new('IDL_Savefile', filename = cropsav)
isf->restore, ['outdir','run','xorg','yorg','xsize','ysize','scl','nx','ny']
obj_destroy, isf

; file = datadir + run + segment + '.fits'
; read_sdo, file, index, data

cropped_data = data[xorg:(xorg+xsize-1),yorg:(yorg+ysize-1)]
; ss = size(cropped_data)
; nx = fix(xsize / scl)
; ny = fix(ysize / scl)
scaled_data = congrid(cropped_data, nx, ny)
;checking for NAN in the input data and replacing it with 0 
nandata = where(~finite(scaled_data), /null)
scaled_data(nandata) = 0

if keyword_set(index) then begin
  ;* Add solar coordinates in axes labels
  wcs = fitshead2wcs(index)
  coord = wcs_get_coord(wcs)
  wcs_convert_from_coord, wcs, coord, 'HPC', solx_hpc, soly_hpc, /arcseconds

  ;* crop the solar coordinates ranges to new data size
  solx=solx_hpc[xorg:(xorg+xsize-1),yorg:(yorg+ysize-1)]
  soly=soly_hpc[xorg:(xorg+xsize-1),yorg:(yorg+ysize-1)]

  ; rebin the solar coordinates as well to the cropped fov
  solcx = congrid(solx, nx, ny)
  solcy = congrid(soly, nx, ny)  
endif


end