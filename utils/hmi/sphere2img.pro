; Adapted from Cartography.c by Rick Bogart, by Xudong Sun
; Not thoroughly tested, use with care.
;
; Convert Stonyhurst lat, lon to xi, eta in heliocentric-cartesian coord
;
; Original comments below the code.
;
; Input:
; lat, lon: latitude and longitude of desired pixel, in radian
; latc, lonc: latitude and longitude of disc center, in radian
; rsun: radius of Sun, arbiturary unit
; 
; Output:
; xi, eta: coordinate on image, in unit of rsun
; hemisphere (optional): 1 of farside
;


pro sphere2img, lat, lon, latc, lonc, xi, eta, xcenter, ycenter, rsun, peff, hemisphere=hemisphere
  
  ; correction of finite distance (1 AU)
  sin_asd = double(0.004660) & cos_asd = double(0.99998914)
  last_latc = 0.0 & cos_latc = 1.0 & sin_latc = 0.0

  if (latc ne last_latc) then begin
    sin_latc = sin(latc)
    cos_latc = cos(latc)
    last_latc = latc
  endif

  sin_lat = sin(lat)
  cos_lat = cos(lat)
  cos_lat_lon = cos_lat * cos(lon - lonc)

  cos_cang = sin_lat * sin_latc + cos_latc * cos_lat_lon
  if (cos_cang lt 0.0) then hemisphere = 1 else hemisphere = 0
  r = rsun * cos_asd / (1.0 - cos_cang * sin_asd)
  xr = r * cos_lat * sin(lon - lonc)
  yr = r * (sin_lat * cos_latc - sin_latc * cos_lat_lon)

  cospa = cos(peff)
  sinpa = sin(peff)
  xi = xr * cospa - yr * sinpa
  eta = xr * sinpa + yr * cospa

  xi = xi + xcenter
  eta = eta + ycenter

end

;  Perform a mapping from heliographic coordinates latitude and longitude
;    (in radians) to plate location on an image of the sun.  The plate
;    location is in units of the image radius and is given relative to
;    the image center.  The function returns 1 if the requested point is
;    on the far side (>90 deg from disc center), 0 otherwise.
;
;  The heliographic coordinates are first mapped into the polar coordinates
;    in an orthographic projection centered at the appropriate location and
;    oriented with north in direction of increasing y and west in direction
;    of increasing x.  The radial coordinate is corrected for foreshortening
;    due to the finite distance to the Sun. If the eccentricity of the fit
;    ellipse is non-zero the coordinate of the mapped point is proportionately
;    reduced in the direction parallel to the minor axis.