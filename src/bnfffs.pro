pro bnfffs

;+ 
; name: bnfffs
;
; purpose: Give a time series run for NFFF extrapolations
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
; created on : 2022-09-09
;
; updates :
;-

@compile_routine

;include the input parameter file
codesdir = '/mn/stornext/u3/avijeetp/codes/idl/extrapolation/'
input = codesdir + 'input.pro'

@input  ; <--- Include the input file

tstart = tobs[0]
tend = tobs[1]
cad = tobs[2]
mktseq, tstart, tend, tseq, times, nt, cad=cad

for t = 0, nt - 1 do begin 
  print, 't = ' + strtrim(t+1,2) + ' out of ' + strtrim(nt,2)
  print, 'time = ', tseq[t]
	check_input, input, input_vars=input_vars, index=t
  restore, input_vars,/v 
  bnfff_prep, input_vars, prepsav=prepsav
  nonff2, input_vars, prepsav
  nonff25d, input_vars, prepsav, bnfffsav=bnfffsav
endfor 

print, '======================================'
print, '    --------- RUN COMPLETE -------      '
print, '======================================'

stop
end
