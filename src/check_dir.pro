pro check_dir, dir 

; author: Avijeet Prasad
; created on: 2022-08-01
; purpose: Check if a directory exists, if not, then create it
; input: dir, string   
; updates:
; TODO read the dir variable literall and use it for the print statement
  ; eg check_dir, datadir should print -> datadir : ....

if not(file_test(dir,/directory)) then begin 
  spawn,   'mkdir -p '+ dir 
endif else begin 
  print, 'Directory: ', dir + ' already exists!'
endelse 

end 