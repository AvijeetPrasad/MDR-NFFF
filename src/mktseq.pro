pro mktseq, tstart, tend, cad, tstartseq, times, nt
;+ 
; name: 
;
; purpose: generate time-sequences
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
  
t1=anytim(tstart,/ecs)
t2=anytim(tend,/ecs)
tstartseq=timegrid(t1, t2, minutes=12,/ecs)
sz = size(tstartseq)
nt = sz[1]
yy = strarr(nt)
mm = yy
dd = yy
hh = yy
min = yy
times= yy

for t=0, nt-1 do begin
  yy[t]=strmid(tstartseq[t],0,4)
  mm[t]=strmid(tstartseq[t],5,2)
  dd[t]=strmid(tstartseq[t],8,2)
  hh[t]=strmid(tstartseq[t],11,2)
  min[t]=strmid(tstartseq[t],14,2)
  times[t]=dd[t]+'_'+mm[t]+'_'+yy[t]+'_h'+hh[t]+min[t]
endfor

end