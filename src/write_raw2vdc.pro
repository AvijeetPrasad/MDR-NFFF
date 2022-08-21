pro write_raw2vdc, vdcfile, type, varname, var 

; write data into vdc file from raw binary data
; Avijeet Prasad
; 2022-05-08

print, '=== writing ' + varname + ' to vdc ==='
; write the variable into

rawfile = 'temp_' + varname + '.raw'
openw, 1, rawfile
writeu, 1, var
close, 1

spawn, 'raw2vdc -ts 0 -type ' + type + ' -varname ' + varname + $
 ' ' + vdcfile + ' ' + rawfile 
;raw2vdc -ts 0 -varname bx bipole_hmi_res.vdc fbx_hmi_res.raw
;raw2vdc -type float64 -varname by test.vdc test_by.raw

spawn, 'rm ' + rawfile 

print, 'Done!'

end
