; Adapted from Cartography.c by Rick Bogart, by Xudong Sun
; Not thoroughly tested, use with care.
;
; Convert (x, y) of a CEA map to Stonyhurst/Carrington (lat, lon)
;
; Original comments below the code.
;
; Input:
; x, y: coordinate of a CEA map pixel relative to map reference point (usually center), in radian
; latc, lonc: Stonyhurst latitude and longitude of map reference point (usually center), inradian
;
; Output:
; lat, lon: Stonyhurst latitude and longitude of the map pixel, in radian
;

pro plane2sphere, x, y, latc, lonc, lat, lon

  if abs(y) gt 1 then begin
    lat = !values.f_nan
    lon = !values.f_nan
    return
  endif
  
  coslatc = cos(latc)
  sinlatc = sin(latc)
  
  cosphi = sqrt(1. - y*y)
  lat = asin ((y * coslatc) + (cosphi * cos (x) * sinlatc));
  
  if cos(lat) eq 0. then test = 0.0 else test = cosphi * sin (x) / cos (lat);
  lon = asin(test) + lonc
  
  x0 = x
  if (abs(x0) gt !pi/2.) then begin
    while (x0 gt !pi/2.) do begin
      lon = !pi - lon
      x0 = x0 - !pi
    endwhile
    while (x0 lt -!pi/2.) do begin
      lon = -!pi - lon
      x0 = x0 + !pi
    endwhile
  endif

end

;  Perform the inverse mapping from rectangular coordinates x, y on a map
;    in a particular projection to heliographic (or geographic) coordinates
;    latitude and longitude (in radians).
;  The map coordinates are first transformed into arc and azimuth coordinates
;    relative to the center of the map according to the appropriate inverse
;    transformation for the projection, and thence to latitude and longitude
;    from the known heliographic coordinates of the map center (in radians).
;  The scale of the map coordinates is assumed to be in units of radians at
;    the map center (or other appropriate location of minimum distortion).
;
;      CYLEQA          Lambert's normal equal cylindrical (equal-area)
;                      projection, in which evenly-spaced meridians are
;                      evenly spaced in x and evenly-spaced parallels are
;                      separated by the cosine of the latitude
;
;  The function returns -1 if the requested point on the map does not project
;    back to the sphere or is not a principal value, 1 if it projects to a
;    point on a hidden hemisphere (if that makes sense), 0 otherwise
