# MDR-NFFF

Non-Force-Free-Field extrapolation code based on the Minimum Dissipation Rate (MDR)
principle. See [Hu et al. 2010](https://ui.adsabs.harvard.edu/abs/2010JASTP..72..219H/abstract) for details on the implementation.


## Table of Contents

- [MDR-NFFF](#mdr-nfff)
  - [Table of Contents](#table-of-contents)
  - [Dependencies](#dependencies)
  - [Input File Parameters Documentation](#input-file-parameters-documentation)
    - [Input Paths](#input-paths)
    - [Event Details](#event-details)
    - [Data Input Settings](#data-input-settings)
      - [Additional Settings for `'sav'` Format](#additional-settings-for-sav-format)
      - [Additional Settings for `'fcube'` Format](#additional-settings-for-fcube-format)
    - [Cropping Details](#cropping-details)
    - [Run Mode](#run-mode)
  - [NFFF Extrapolation Settings](#nfff-extrapolation-settings)
  - [Output Settings](#output-settings)
  - [Additional Comments](#additional-comments)
  - [Issues and suggestions](#issues-and-suggestions)
  - [Contact](#contact)

---

## Dependencies
The code is written in IDL (Interactive Data Language) and requires the some functions from the following dependencies:

- Calculate Squashing Factor and Twist Number: [qfactor](http://staff.ustc.edu.cn/~rliu/qfactor.html)
- Updated versions of the Squashing Factor code are also available at: [FastQSL (CPU)](https://github.com/el2718/FastQSL) and [FastQSL (GPU)](https://github.com/peijin94/FastQSL)
- SolarSoft IDL: [SSW](https://soho.nascom.nasa.gov/solarsoft/)
- Collection of IDL routines written and maintained by Chris Beaumont [beaumont-idl-library](https://github.com/ChrisBeaumont/beaumont-idl-library)

## Input File Parameters Documentation

This section provides detailed explanations and input examples of the parameters defined in the `input_sample.pro` file. 
The first step is to rename `input_sample.pro` to `input.pro` before running any codes.

The `input.pro` file serves as a common input file to pass parameters to various codes used for the non-force-free field extrapolation 
code `bnfff.pro` or any related procedures.

### Input Paths

- **`codesdir`**: *(String)*

  Path to the root directory containing all the codes. This path will be added to the top of your IDL path.
  This is where this `input.pro` file should be present.

  ```idl
  codesdir = '/Users/avijeetp/codes/extrapolation/'
  ```

- **`projectdir`**: *(String)*

  Path to the main project folder or the hard-disk path where your project resides.
  This would be top folder under which the outputs will be saved.

  ```idl
  projectdir = '/Users/avijeetp/extrapolations/'
  ```

### Event Details

- **`event`**: *(String)*

  Name of the event to analyze. Typically, this is the NOAA number of an active region (e.g., `'AR12192'`). For quiet sun data, you can set any other string eg. `event = 'QS'`.

  ```idl
  event = 'AR12192'
  ```

- **`source`**: *(String)*

  Name of the instrument used as the data source. Examples: `'sdo_hmi'`, `'hinode_sot'`, `'sst_crisp'`.
  This is used to identify the source of the data and load the appropriate routines.

  ```idl
  source = 'sdo_hmi'
  ```

- **`ds`**: *(String)*

  Dataseries name. Examples: `'hmi.B_720s'`, `'hmi.sharp_cea_720s'`, `'hmi.sharp_cea_720s_dconS'`, `'nb_6173'`, etc.

  ```idl
  ds = 'hmi.sharp_cea_720s'
  ```

- **`tobs`**: *(String or Array of Strings)*

  Time of the observation in the format `'HH:MM DD-MMM-YYYY'`. 
  It can be a single string or an array of strings with start and end time.
  Examples: `'09:36 20-oct-2023'`, `['10:00 26-jul-2023', '10:24 26-jul-2023', '12']`.

  ```idl
  tobs = '09:36 20-oct-2023'
  ```

### Data Input Settings

- **`dataformat`**: *(String)*

  Format of the input data. Options are `'fits'`, `'sav'`, `'fcube'`.

  - `'fits'`: For JSOC downloads or FITS files.
  - `'sav'`: For data already saved in an IDL `.sav` file.
  - `'fcube'`: For data in cube format (e.g., SST cubes).

  ```idl
  dataformat = 'fits'
  ```

#### Additional Settings for `'sav'` Format

If `dataformat` is set to `'sav'`, the following parameters should be specified:

- **`savdir`**: *(String)*

  Directory path where the `.sav` file is located.

  ```idl
  savdir = projectdir
  ```

- **`savfile`**: *(String)*

  Name of the `.sav` file containing the data.

  ```idl
  savfile = '201109062236_bxbybz.sav'
  ```

- **`bvecs`**: *(Array of Strings)*

  Names of the magnetic field components within the `.sav` file. Typically `['bx', 'by', 'bz']`.

  ```idl
  bvecs = ['bx', 'by', 'bz']
  ```

#### Additional Settings for `'fcube'` Format

If `dataformat` is set to `'fcube'`, specify the following:

- **`datadir`**: *(String)*

  Directory path where the cube data is saved.

  ```idl
  ; datadir = '/Users/avijeetp/1_Projects/2020-08-07/'
  ```

### Cropping Details

- **`check_crop`**: *(String)*

  Determines how to handle the cropping of the data. Options are:

  - `'yes'`: Opens an interactive window to define cropping details.
  - `'no'`: Uses predefined cropping parameters without user interaction.

  ```idl
  check_crop = 'yes'
  ```

If `check_crop` is set to `'no'`, the following parameters must be specified:

- **`xsize`**: *(Integer)*
  
  Number of pixels in the x-direction after cropping.

  ```idl
  xsize = 1280
  ```

- **`ysize`**: *(Integer)*

  Number of pixels in the y-direction after cropping.

  ```idl
  ysize = 832
  ```

- **`xorg`**: *(Integer)*

  X-coordinate of the bottom-left pixel in the cropped region.

  ```idl
  xorg = 50
  ```

- **`yorg`**: *(Integer)*

  Y-coordinate of the bottom-left pixel in the cropped region.

  ```idl
  yorg = 0
  ```

- **`scl`**: *(Float)*

  Scaling factor for rescaling the data. The data will be rescaled to `xsize / scl`.

  ```idl
  scl = 1.0
  ```

- **`nz`**: *(Integer)*

  Number of grid points in the z-direction. Typically calculated as `ysize / scl`.

  ```idl
  nz = 416
  ```

### Run Mode

- **`mode`**: *(String)*

  Determines whether to perform a new calculation or analyze an existing run. Options are:

  - `'calculate'`: Initiates a new calculation and automatically generates a run ID based on the timestamp.
  - `'analysis'`: Analyzes results from a previous run using specified run IDs.

  ```idl
  mode = 'calculate'
  ```

If `mode` is set to `'analysis'`, specify the following:

- **`ids`/`id`**: *(Array of Strings)*
  - Single ID Example: `id = '1673877191'`

  -  List of run IDs to analyze.

  ```idl
  ids = [ $
    '1710927883', $
    '1710937796' $
    ]
  ```

---

## NFFF Extrapolation Settings

Parameters specific to the Non-Force-Free Field (NFFF) extrapolation:

- **`nk0`**: *(Integer)*

  Number of iterations in the potential field correction loop. A typical value is `>= 300`.

  ```idl
  nk0 = 3000
  ```

- **`nl`**: *(Integer)*

  Number of steps in the alpha loop. A typical value is `>= 8`.

  ```idl
  nl = 8
  ```

- **`itaperx`**: *(Integer)*

  Tapering parameter in the x-direction, based on the domain size.

  ```idl
  itaperx = 16
  ```

- **`itapery`**: *(Integer)*

  Tapering parameter in the y-direction, based on the domain size.

  ```idl
  itapery = 8
  ```

- **`dx`**: *(Float)*

  Grid spacing in the x-direction. Only uniform grids are supported.

  ```idl
  dx = 1
  ```

- **`dz`**: *(Float)*

  Grid spacing in the z-direction. Non-uniform grids in z are possible but not yet supported.

  ```idl
  dz = 1
  ```

- **`wt_set`**: *(Float)*

  Weighting factor with the transverse field strength for calculating the normalized energy (`En`).

  ```idl
  wt_set = 1.1
  ```

---

## Output Settings

Settings related to the output of the extrapolation and analysis:

- **`current`**: *(Integer)*

  Flag to calculate the electric current. Set to `1` to enable calculation, `0` to disable.

  ```idl
  current = 1
  ```

- **`qfactor`**: *(Integer)*

  Flag to calculate the squashing factor (`Q-factor`). Requires `ifort` (Intel Fortran Compiler). Set to `1` to enable, `0` to disable.

  ```idl
  qfactor = 1
  ```

- **`qpath`**: *(String)*

  Path to the directory containing the `qfactor` calculation libraries.

  ```idl
  qpath = codesdir + 'MDR-NFFF/libs/qfactor/'
  ```

- **`decay`**: *(Integer)*

  Flag to calculate the decay index. Set to `1` to enable, `0` to disable.

  ```idl
  decay = 1
  ```

- **`vapor`**: *(Integer)*

  Flag to save output in VAPOR (Visualization and Analysis Platform for Ocean, Atmosphere, and Solar Researchers) format. Requires VAPOR software. Set to `1` to enable, `0` to disable.

  ```idl
  vapor = 1
  ```

- **`outtxt`**: *(Integer)*

  Flag to save data output in `.dat` format for reading in EULAG (Eulerian and Lagrangian fluid dynamics code). Set to `1` to enable, `0` to disable.

  ```idl
  outtxt = 0
  ```

---

**Note**: Ensure all paths specified exist on your system, and the required software dependencies (like `ifort` and VAPOR) are installed if you enable features that require them.

---

## Additional Comments

- Always verify the parameter values before running any codes to avoid unexpected behavior.
- The parameters `xsize`, `ysize`, `xorg`, `yorg`, `scl`, and `nz` are critical for data cropping and must be set accurately if `check_crop` is set to `'no'`.
- The `mode` parameter controls whether a new calculation is performed or existing results are analyzed. Ensure that run IDs are correctly specified when in `'analysis'` mode.
- The NFFF extrapolation parameters (`nk0`, `nl`, `itaperx`, `itapery`, `dx`, `dz`, `wt_set`) should be set based on the specifics of your simulation and desired accuracy.

---

## Issues and suggestions
Issues and suggestions can be reported [here](https://github.com/AvijeetPrasad/MDR-NFFF/issues).

## Contact
For any questions or further assistance, please contact the author:

**Author**: Avijeet Prasad  
**Created On**: 2024-11-14