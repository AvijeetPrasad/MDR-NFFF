pro    mktime, tstart, time, jsoc_time, aia_time=aia_time
;+ 
; name: mktime
;
; purpose: Take input of the type tstart  = '21:24 18-dec-2014'
;   and return formatted output
;
; calling sequence: mktime, tstart, time, jsoc_time
;
; inputs: 
;        tstart: input of the type '21:24 18-dec-2014'
;
; outputs:
;         time: formatted output eg. 04_01_2015_h1524
;         jsoc_time: formatted output eg. 20150104_152400_TAI.
;
; author : Avijeet Prasad
; created on : 2022-09-11
;
; updates : 2022/09/17: add option to send AIA time
;-
;Decription: 

    t1=anytim(tstart,/ecs)
    yy=strmid(t1,0,4)
    mm=strmid(t1,5,2)
    dd=strmid(t1,8,2)
    hh=strmid(t1,11,2)
    min=strmid(t1,14,2)
    time=dd+'_'+mm+'_'+yy+'_h'+hh+min
    jsoc_time = yy+mm+dd+'_'+hh+min+'00_TAI.'
    aia_time = yy+'.'+mm+'.'+dd+'_'+hh+':'+min+'_TAI/'
 end
