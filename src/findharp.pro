pro findharp, noaa,harp,codesdir=codesdir,update=update 

; author : Avijeet Prasad
; created on : 2022-08-01
; purpose : find the harp number given the noaa number
; input : noaa; the active region number, say 11283 
; output : harp; the harp number, say 833
; optional keywords:
  ; codesdir: folder where the 'all_harps...' file is saved.
  ;update: to get the latest 'all_harps...' file from jsoc
; comments: The updated all harps with noaa file can be found here:
; http://jsoc.stanford.edu/doc/data/hmi/harpnum_to_noaa/all_harps_with_noaa_ars.txt
; updates :
  ; DONE 2022/08/01 define current directory as the default value for codesdir
  ; DONE 2022/08/01 add update keyword to download the latest file from jsoc
  ; DONE 2022/08/01 run test cases for multiple column entries
    
; --- check keyword: codesdir ---
; by default it assumes the 'all_harps ...' is present in the current dir
if not(keyword_set(codesdir)) then begin 
cd, current = codesdir 
codesdir = codesdir + '/'
print, 'using all_harps_with_noaa_ars.txt file in: ', codesdir 
endif 

;
fsearch = file_search(codesdir, 'all_harps_with_noaa_ars.txt', count=fcount)
if (fcount eq 0) then begin 
  print, 'all_harps_with_noaa_ars.txt file not found in codesdir'
  stop 
endif 
file = fsearch[0]

; --- check keyword: update ---
; download the latest txt file from jsoc
if keyword_set(update) then begin 
  print, 'update requested'
  print, 'downloading the latest all_harps_with_noaa_ars.txt file from jsoc'
  link='http://jsoc.stanford.edu/doc/data/hmi/harpnum_to_noaa/all_harps_with_noaa_ars.txt'
  spawn, 'rm ' + file   ; delete the old file
  spawn, 'wget ' + link + ' -P ' + codesdir + 'libs/hmi/';save the new file in codesdir
  fsearch = file_search(codesdir, 'all_harps_with_noaa_ars.txt')
endif 

; --- find the harp number for a given noaa ---
; assumes that you'll find the harp number within 6 columns 
; or else you enter harp manually 

readcol,file, harp_list,noaa_1,format='u,u',/silent 
pos = where(noaa_1 eq uint(noaa))

; fix for condition when the noaa number returns multiple values in column 1
if n_elements(pos) gt 1 then begin 
  print, 'multiple values returned, using first element'
  pos = pos[0]
endif  

if ( pos eq -1) then begin
	readcol,file, harp_list,noaa_1,noaa_2,format='u,u',/silent 
  pos = where(noaa_2 eq uint(noaa))
endif

if ( pos eq -1) then begin
	readcol,file, harp_list,noaa_1,noaa_2,noaa_3,format='u,u',/silent 
  pos = where(noaa_3 eq uint(noaa))
endif

if ( pos eq -1) then begin
	readcol,file, harp_list,noaa_1,noaa_2,noaa_3,noaa_4,format='u,u',/silent 
  pos = where(noaa_4 eq uint(noaa))
endif

if ( pos eq -1) then begin
	readcol,file, harp_list,noaa_1,noaa_2,noaa_3,noaa_4,noaa_5,format='u,u',/silent 
  pos = where(noaa_5 eq uint(noaa))
endif

if ( pos eq -1) then begin
	readcol,file, harp_list,noaa_1,noaa_2,noaa_3,noaa_4,noaa_5,noaa_6,format='u,u',/silent 
  pos = where(noaa_6 eq uint(noaa))
endif

if (pos eq -1) then begin
  print,"Unable to find HARP number. Enter manually!"
	read, harp, prompt= "HARP num = "
endif else begin 
  harp = string(harp_list(pos))
endelse 
; remove front and back trailing spaces
harp = strtrim(harp,2) 
cls 
print, 'noaa = ', noaa 
print, 'harp = ', harp 

end