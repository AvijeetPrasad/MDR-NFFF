pro write_raw2vdc, vdcfile, type, varname, var, ts = ts
  compile_opt idl2
  ;+
  ; name: write_raw2vdc
  ;
  ; purpose: write data into vdc file from raw binary data
  ;
  ; calling sequence: vdcfile, type, varname, var, ts=ts
  ;
  ; inputs:
  ;         vdcfile: name of the vdcfile to be saved
  ;         type: data type 'float64' or 'float32'
  ;         varname: string with the variable name
  ;         var: variable with data
  ;         ts: (optional) time step for time series runs (default: 0)
  ;
  ; outputs: vdcfile created in the outdir
  ;
  ; author : Avijeet Prasad
  ; created on : 2022-09-11
  ;
  ; updates :
  ;-

  ; Check if time step is set else set it to 0
  if not keyword_set(ts) then ts = '0'
  ts = strtrim(ts, 2)
  if (ts eq '0') then print, '=== writing ' + varname + ' to vdc ==='
  ; print, 'time step = ', ts

  ; Temporarily write the variable into a raw file in the codedir
  rawfile = 'temp_' + varname + '.raw'
  openw, 1, rawfile
  writeu, 1, var
  close, 1

  ; Run the raw2vdc command to populate the vdcfile
  spawn, 'raw2vdc -ts ' + ts + ' -type ' + type + ' -varname ' + varname + $
    ' ' + vdcfile + ' ' + rawfile
  ; raw2vdc -ts 0 -varname bx bipole_hmi_res.vdc fbx_hmi_res.raw
  ; raw2vdc -type float64 -varname by test.vdc test_by.raw

  ; Delete the temporary raw file
  spawn, 'rm ' + rawfile

  ; print, 'Done!'
end