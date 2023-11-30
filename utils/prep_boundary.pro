pro prep_boundary,input, output, pad=pad 
;+ 
; name: 
;
; purpose: 
;
; calling sequence: 
;
; inputs: 
;        input: 
;
; outputs:
;         output:
;
; author : Avijeet Prasad
; created on : 2023-02-05
;
; updates :
;-

; set the input and output directories
input_dir = '/mn/stornext/d9/data/avijeetp/1_Projects/16_AR12241_flare/extrapolation/18_12_2014_h2124/'
input_sav = 'hmi.sharp_cea_720s_ar12241_18_12_2014_h2124_vectorb_680_340.sav'

restore, input_dir+input_sav, /v

nx = 768
ny = 384

; read the size of the bz0 variable
ss = size(bz0)
size_x = ss[1]
size_y = ss[2]

; create an empty array of size nx, ny with zeros
bz0_new = fltarr(nx, ny)

; fill the central values with the variable bz0
pad_x = fix((nx-size_x)/2)
pad_y = fix((ny-size_y)/2)
bz0_new[pad_x:pad_x+size_x-1, pad_y:pad_y+size_y-1] = bz0

; create a 2D cosine function to taper the edges in the padded region
x = findgen(nx)
y = findgen(ny)
xx = replicate(x, ny, 1)
yy = replicate(y, nx, 2)
cos_x = 0.5*(1-cos((xx-pad_x+0.5)*!dpi/pad_x))
cos_y = 0.5*(1-cos((yy-pad_y+0.5)*!dpi/pad_y))
cos2d = cos_x * cos_y

; apply the 2D cosine function to the padded array
bz0_new = bz0_new * cos2d

stop
end