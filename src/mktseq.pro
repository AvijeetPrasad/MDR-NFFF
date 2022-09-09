pro mktseq, tstart, tend, tseq, times, nt, cad=cad
;+ 
; name: mktseq
;
; purpose: generate time-sequences based on start time, end time and cadence
;
; calling sequence: mktseq, tstart, tend, tseq, times, nt, cad=cad
;
; inputs: 
;        tstart: start time , eg. '23:00 06-mar-2012'
;        tend: end time, eg. '02:48 07-mar-2012'
;        cad: cadence between timesteps in minutes (default: 12)
;
; outputs:
;         tseq: time sequence in format '2012/03/06 23:00:00.000'
;         times: time sequence in format '06_03_2012_h2300'
;         nt: number of time steps
;
; author : Avijeet Prasad
; created on : 2022-09-09
;
; updates :
;-

; Set a default value for cadence if not specified
if (not (keyword_set (cad))) then cad = 12 ;minutes

t1    = anytim(tstart, /ecs) ; start time
t2    = anytim(tend, /ecs)   ; end time 
tseq  = timegrid(t1, t2, minutes=cad,/ecs) ; generate the time sequence

; Initialize arrays
sz    = size(tseq)
nt    = sz[1]
yy    = strarr(nt)
mm    = yy
dd    = yy
hh    = yy
min   = yy
times = yy

; Write the outputs
for t = 0, nt - 1 do begin
  yy[t]  = strmid(tseq[t],0,4)
  mm[t]  = strmid(tseq[t],5,2)
  dd[t]  = strmid(tseq[t],8,2)
  hh[t]  = strmid(tseq[t],11,2)
  min[t] = strmid(tseq[t],14,2)
  times[t] = dd[t] + '_' + mm[t] + '_' + yy[t] + '_h' + hh[t] + min[t]
endfor

end