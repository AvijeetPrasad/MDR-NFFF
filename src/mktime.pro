pro    mktime, tstart, time, jsoc_time
;Decription: Take input of the type tstart  = '21:24 18-dec-2014'
;   and return formatted output

    t1=anytim(tstart,/ecs)
    yy=strmid(t1,0,4)
    mm=strmid(t1,5,2)
    dd=strmid(t1,8,2)
    hh=strmid(t1,11,2)
    min=strmid(t1,14,2)
    time=dd+'_'+mm+'_'+yy+'_h'+hh+min
    jsoc_time = yy+mm+dd+'_'+hh+min+'00_TAI.'

 end
