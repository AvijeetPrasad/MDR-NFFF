pro img2heliovec, bxImg, byImg, bzImg, bxHelio, byHelio, bzHelio, lon, lat, lonc, latc, pAng

  a11 = - sin(latc) * sin(pAng) * sin(lon - lonc) + cos(pAng) * cos(lon - lonc)
  a12 =  sin(latc) * cos(pAng) * sin(lon - lonc) + sin(pAng) * cos(lon - lonc)
  a13 = - cos(latc) * sin(lon - lonc)
  a21 = - sin(lat) * (sin(latc) * sin(pAng) * cos(lon - lonc) + cos(pAng) * sin(lon - lonc)) - cos(lat) * cos(latc) * sin(pAng)
  a22 =  sin(lat) * (sin(latc) * cos(pAng) * cos(lon - lonc) - sin(pAng) * sin(lon - lonc)) + cos(lat) * cos(latc) * cos(pAng)
  a23 = - cos(latc) * sin(lat) * cos(lon - lonc) + sin(latc) * cos(lat)
  a31 =  cos(lat) * (sin(latc) * sin(pAng) * cos(lon - lonc) + cos(pAng) * sin(lon - lonc)) - sin(lat) * cos(latc) * sin(pAng)
  a32 = - cos(lat) * (sin(latc) * cos(pAng) * cos(lon - lonc) - sin(pAng) * sin(lon - lonc)) + sin(lat) * cos(latc) * cos(pAng)
  a33 =  cos(lat) * cos(latc) * cos(lon - lonc) + sin(lat) * sin(latc)

  bxHelio = a11 * bxImg + a12 * byImg + a13 * bzImg
  byHelio = a21 * bxImg + a22 * byImg + a23 * bzImg
  bzHelio = a31 * bxImg + a32 * byImg + a33 * bzImg

end