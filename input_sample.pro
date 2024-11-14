;+
; name: input
;
; purpose: common input file to pass parameters to various codes
;
; calling sequence: included as @input in check_input.pro file
;
;
; author : Avijeet Prasad
; created on : 2024-11-12
; comment: rename `input_sample.pro` to `input.pro` before running bnfff.pro
;-

; --- Input paths ---
; Enter the path to root directory to all your codes
; This path would be added to the top of your idl path
codesdir = '/Users/avijeetp/codes/idl/extrapolation/'

; Enter the hard-disk path or the path to the main project folder
projectdir = '/Users/avijeetp/extrapolations/'

; --- Event details ---
; Enter the event name. Typically the NOAA number of an active region
; eg: 'AR12192', the noaa number is later extracted from this string
; for quiet sun data, set event = 'QS'
event = 'AR12192'

; Enter the instrument name as the data source
; eg: 'sdo_hmi', 'hinode_sot', 'sst_crisp',
source = 'sdo_hmi'

; Enter the dataseries name
; eg: 'hmi.sharp_cea_720s', 'nb_6173'
; ds = 'embedded_niris_hmi' ;input dataset
; ds = 'hmi.B_720s' ; input dataset
; ds = 'hmi.sharp_cea_720s'
; ds = 'hmi.sharp_cea_720s_dconS'
; ds = 'nb_6173'
ds = 'hmi.sharp_cea_720s'

; Enter the time of the observation
; eg: '11:48 01-jul-2022'
; tobs = ['10:00 26-jul-2023', '10:24 26-jul-2023', '12']
tobs = '09:36 20-oct-2023'

; --- Data input settings ---
; Enter the input data format
; options: 'fits', 'sav', 'fcube'
; set dataformat = 'fits' for JSOC downloads
; dataformat = 'fcube'
dataformat = 'fits'

if (dataformat eq 'sav') then begin
  ; If the data is already saved in an IDL savfile, then provide its path below
  ; savdir = projectdir + 'downloads/'
  savdir = projectdir
  savfile = '201109062236_bxbybz.sav'
  bvecs = ['bx', 'by', 'bz'] ; specify as bx, by, bz
endif

if (dataformat eq 'fcube') then begin
  ; Enter the path where the sst cubes are saved
  ; datadir = '/Users/avijeetp/1_Projects/2020-08-07/'
endif

; --- Cropping details ---
; Do you want an interactive window to fix cropping details?
; options: 'yes', 'no', 'input'
; 'yes' will create an interactive window
; 'no' will take the input data as it is
check_crop = 'yes' ;
if (check_crop eq 'no') then begin
  ; crop details known from previous runs
  xsize = 1280 ; number of pixels in x after cropping
  ysize = 832 ; number of pixels in y after cropping
  xorg = 50 ; x coordinate of bottom left pixel
  yorg = 0 ; y coordinate of bottom left pixel
  scl = 1. ; factor for rescaling the data to xsize / scl
  nz = 416 ; specify nz based on the scl value, typically nz = ysize / scl
endif

; --- Run mode ---
; Is it a new calculation or analysis of an existing run?
; options: 'calculate', 'analysis'
; 'calculate' automatically generates a run id based on the timestamp
; for 'analysis', this id is entered manually
; mode = 'analysis'
; for analysis mode, give the run id below
; eg: id = '1661006033'
mode = 'calculate'
if (mode eq 'analysis') then begin
  ; id = '1673877191'
  ids = [ $
    '1710927883', $
    '1710937796' $
    ]
endif

  ; --- NFFF Extrapolation settings ---
  nk0 = 3000 ; number of loops in potential field correction,typically >= 300
  nl = 8 ; number of steps in the alpha loop, typically >= 8
  itaperx = 16 ; tapering in x, based on domain size
  itapery = 8 ; tapering in y, based on domain size
  dx = 1 ; step size in x (only uniform grid supported)
  dz = 1 ; step size in z (non-uniform grid in z possible but not yet supported)
  wt_set = 1.1 ; weight with transverse field strength for calculating En

  ; --- output settings ---
  current = 1 ; 0/1 calculate current
  qfactor = 1 ; 0/1 calculate qfactor -> needs ifort
  qpath = codesdir + 'MDR-NFFF/libs/qfactor/'
  decay = 1 ; 0/1 calculate decay index
  vapor = 1 ; 0/1 save output as vapor file -> needs vapor
  outtxt = 0 ; 0/1 save dat output for reading in EULAG



