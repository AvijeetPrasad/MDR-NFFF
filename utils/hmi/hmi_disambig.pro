;+
; NAME:
;   hmi_disambig
; PURPOSE:
;	Combine HMI disambiguation result with azimuth
;	For details, see Section 5
;	Hoeksema et al., 2014, SoPh, online (doi:10.1007/s11207-014-0516-8)
; SAMPLE CALLS:
;	IDL> file_azi = 'hmi.B_720s.20110215_000000_TAI.azimuth.fits'
;	IDL> file_ambig = 'hmi.B_720s.20110215_000000_TAI.disambig.fits'
;	IDL> read_sdo, file_azi, index, azi
;	IDL> read_sdo, file_ambig, index, ambig
;	IDL> hmi_disambig, azi, ambig, 2
; INPUT:
;	azimuth:	azimuth image, with values between 0 and 180.
;	disambig:	bit mask with the same size as azimuth
;				bit 1 indicates the azimuth needs to be flipped (plus 180)
;				For full disk, three bits are set, giving three disambiguation
;				solutions from different methods. Note the strong field pixels
;				have the same solution (000 or 111, that is, 0 or 7) from the 
;				annealing method. The weak field regions differ 
;				lowest: potential field acute
;				middle: radial acute (default)
;				highest: random
; OPTIONAL INPUT:
;	method:		integer from 0 to 2 indicating the bit used.
;				0 for potential acute, 1 for random, 2 for radial acute (default)
;				Out-of-range values are ignored and set to 2
; OUTPUT:
;	azimuth:	modified azimuth image, with values between 0 and 360	
; HISTORY:
;   2014.05.13 - Xudong Sun (xudongs@sun.stanford.edu)
;	2016.05.06 -
;			fixed a bug. Originally optional method=method changed to mandatory
;			b.c. if user wanted method=0, keyword_set(method)=0: was considered as
;			keyword NOT set, then it automatically used method=2.
; NOTE:
;	Written for HMI data. Minimal check implemented so far
;	Note SHARP data are already disambiguated
;	
;-

pro hmi_disambig, azimuth, disambig, method

; Check dimensions only
; No further WCS check implemented

sz = size(azimuth) & nx = sz[1] & ny = sz[2]
sz1 = size(disambig) & nx1 = sz1[1] & ny1 = sz1[2]
if (nx ne nx1 or ny ne ny1) then begin
	print, 'Dimension of two images don not agree'
	return
endif

disambig = fix(disambig)

; Check method

if (method lt 0 or method gt 2) then begin
	method = 2
	print, 'Invalid disambiguation method, set to default method = 2'
endif

; Perform disambiguation

disambig = disambig / (2 ^ method)		; Move the corresponding bit to the lowest
index = where(disambig mod 2 ne 0, num)

if (num ne 0) then azimuth[index] = azimuth[index] + 180.

;

return


end
