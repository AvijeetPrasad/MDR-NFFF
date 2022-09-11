pro check_dims, var, dims

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
; created on : 2022-09-11
;
; updates :
;-

ss = size(var)
dims = ''
ndim = ss[0]
for i = 1, ndim do begin 
  dim  = strtrim(ss[i],2)
  dims += dim + '_'  
endfor
;dims = dims.substring(0,-2)
end 