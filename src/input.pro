; ==== Template for extrapolation inputs ===
; Last update: 2022/08/17
; ======

; --- Input paths ---
  ;path to codes
codesdir = '/mn/stornext/d18/RoCS/avijeetp/codes/extrapolation/MDR-NFFF/src/'
  ; hard-disk path
hd = '/mn/stornext/d18/RoCS/avijeetp/1_Projects/33_SST/2020-08-07/'

; --- Event details ---
event   = 'AR12770'
source   = 'sst'
ds      = 'crisp' ;input dataset
tstart  = '08:22 07-aug-2020'
; source  = 'hmi'
; ds      = 'hmi.sharp_cea_720s' ;input dataset
; tstart  = '06:36 07-aug-2020'

; --- Run settings ---
prof     = 'bnfff'
download = 'no'; 'yes', 'no'
crop     = 'no'; 'yes', 'no' 
mode     = 'calculate'; 'calculate', 'analysis'
; for analysis mode, give the run id below
if (mode eq 'analysis') then id = '1661006033'

if (download eq 'no') then begin 
  savfile = 'SST_2020-08-07_08-22_512_512_040_Bxyz.sav'
endif 

; --- Cropping details ---
if (crop eq 'no') then begin
; crop details known from previous runs
  ; --- SST ---
  xsize  = 512
  ysize  = 512
  xorg   = 0
  yorg   = 0
  scl    = 4.
  nz     = 512
  harp   = 7436

  ;--- HMI ---
  ; xsize  = 360
  ; ysize  = 256
  ; xorg   = 150
  ; yorg   = 0
  ; scl    = 2
  ; nz     = 256
  ; harp   = 7436
endif

; --- NFFF extrapolation ---
if (prof eq 'bnfff') then begin 
  ; --- NFFF Extrapolation settings ---
  nk0	    = 10 ; number of loops in potential field correction,typically >= 300
  nl	     = 8 ;number of steps in the alpha loop, typically >= 8
  itaperx	= 16 ; tapering in x, based on domain size
  itapery	= 16 ; tapering in y, based on domain size
  dx      = 1
  dz      = 1
  wt_set	= 1.1 ; weight with transverse field strength for calculating En
  ; output settings
  current  = 0 ; 0/1 calculate current
  qfactor  = 0 ; 0/1 calculate qfactor
  decay    = 0 ; 0/1 calculate decay index
  vapor    = 1 ; 0/1 save output as vapor file
  outtxt 	 = 0 ; save dat output for reading in EULAG
endif

; --- HMI vector plot ---
if (prof eq 'hmi_vplot') then begin
	outformat    = 'eps'; options: eps, png, tiff
  download     = 'yes'; 'yes', 'no',
	;source	     = 'local' ; 'jsoc' or 'local' ;! <-- same as download
	;run	   		 = 'cropped'; 'tocrop' or 'cropped' ;! <--- conflicts with run
	scl	       	 = 1 ; rescaling the data,scl=1 is the original size
	series	     = 'cea'; options: 'cea' or 'full' ;! <--- same as ds
endif


