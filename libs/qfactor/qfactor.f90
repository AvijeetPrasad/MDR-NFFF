!    ifort -o qfactor.x qfactor.f90 -fopenmp -mcmodel=medium -O3 -xHost -ipo
! gfortran -o qfactor.x qfactor.f90 -fopenmp -mcmodel=medium -O3
! -O3, -xHost, -ipo are for a better efficiency
! the efficiency of ifort (version 2021.4.0) is slightly (~1.40 times) faster than gfortran (version 9.3.0)

include  'trace_bline.f90'
include  'trace_scott.f90'

subroutine qfactor0_bridge(i,j)
use qfactor_common
implicit none
real:: bzp, bp(0:2), vp(0:2), rs(0:2), re(0:2), twist0, line_length, q0, q_perp0, incline
integer:: i, j, rbs, rbe, s_index, e_index
!----------------------------------------------------------------------------

call ij2vp(i, j, vp)
call interpolateB(vp, bp)
bzp=bp(2)

if (scottFlag) then 
	call trace_scott(vp, q0, q_perp0, rs, re, rbs, rbe, line_length, twist0, twistFlag)
	q(i,j)=q0
	q_perp(i,j)=q_perp0
else
	incline=abs(bzp/norm2(bp))
	call trace_bline(vp, rs, re, rbs, rbe, line_length, twist0, twistFlag, incline)
endif

length(i, j)=line_length
if (twistFlag) twist(i, j)=twist0  


if( bzp>0.0) then 
	sign2d(i,j)=1.0
	reboundary(i, j)=rbe
	if (vflag) rboundary_tmp(i, j)=1+8*rbe
	
	reF(:, i, j)=re
	if ( (rbe .ne. 0) .and.(rbe .ne. 7)) then 
		call interpolateB(re, bp)
		e_index=(6-rbe)/2
		bnr(i, j)=abs(DBLE(bzp)/bp(e_index))
	endif
else 
	sign2d(i,j)=-1.0
	reboundary(i, j)=rbs	
	if (vflag) rboundary_tmp(i, j)=rbs+8
	
	reF(:, i, j)=rs
	if ( (rbs .ne. 0) .and.(rbs .ne. 7)) then 	
		call interpolateB(rs, bp)
		s_index=(6-rbs)/2
		bnr(i, j)=abs(DBLE(bzp)/bp(s_index))
	endif
endif

if (bzp .eq. 0.0) then
	sign2d(i,j)=0.0
	reboundary(i, j)=0
	if (vflag) rboundary_tmp(i, j)=0
endif

END subroutine qfactor0_bridge


subroutine qfactor0_calculate(i,j)
!calculate the Q at the photosphere by Titov (2002), some problematic sites are filled by trace_scott
use qfactor_common
use trace_common
implicit none
integer:: i, j, rb, rbs, rbe, m_index, index1, index2, sign_index1, sign_index2
logical:: bkey1, bkey2, bkey11, bkey12, bkey21, bkey22, margin_flag 
real:: nxx, nxy, nyx, nyy, q0, vp(0:2), q_perp0
real:: rs(0:2), re(0:2), line_length, twist0
!----------------------------------------------------------------------------
rb=reboundary(i,j)

if ((rb .eq. 0) .or. (rb .eq. 7) .or. (bnr(i,j) .eq. 0.0)) then
	q(i,j)=NaN
	return
endif

m_index=(6-rb)/2
index1=mod(m_index+1,3)
index2=mod(m_index+2,3)


margin_flag= (i .eq. 0) .or. (j .eq. 0) .or. (i .eq. q1m1) .or. (j .eq. q2m1)

bkey1= (.not. margin_flag) .and. ( rb .eq. reboundary(i+1,j)) .and. ( rb .eq. reboundary(i-1,j)) 
bkey2= (.not. margin_flag) .and. ( rb .eq. reboundary(i,j+1)) .and. ( rb .eq. reboundary(i,j-1))

bkey11=(i+2 .le. q1m1) .and. ( rb .eq. reboundary(i+1,j)) .and. ( rb .eq. reboundary(i+2,j))
bkey12=(i-2 .ge.    0) .and. ( rb .eq. reboundary(i-1,j)) .and. ( rb .eq. reboundary(i-2,j)) .and. (.not. bkey11)
bkey21=(j+2 .le. q2m1) .and. ( rb .eq. reboundary(i,j+1)) .and. ( rb .eq. reboundary(i,j+2))
bkey22=(j-2 .ge.    0) .and. ( rb .eq. reboundary(i,j-1)) .and. ( rb .eq. reboundary(i,j-2)) .and. (.not. bkey21)

if (bkey11) sign_index1= 1
if (bkey12) sign_index1=-1
if (bkey21) sign_index2= 1
if (bkey22) sign_index2=-1

if (bkey1) then
	nxx=reF(index1, i+1,j)-reF(index1, i-1,j)
	nyx=reF(index2, i+1,j)-reF(index2, i-1,j)
else if (bkey11 .or. bkey12) then
	nxx=(-3*reF(index1, i,j)+4*reF(index1, i+sign_index1,j)-reF(index1, i+2*sign_index1,j))*sign_index1	
	nyx=(-3*reF(index2, i,j)+4*reF(index2, i+sign_index1,j)-reF(index2, i+2*sign_index1,j))*sign_index1
endif


if (bkey2) then
	nxy=reF(index1, i,j+1)-reF(index1, i,j-1)
	nyy=reF(index2, i,j+1)-reF(index2, i,j-1)
else if (bkey21 .or. bkey22) then
	nxy=(-3*reF(index1, i,j)+4*reF(index1, i,j+sign_index2)-reF(index1, i,j+2*sign_index2))*sign_index2	
	nyy=(-3*reF(index2, i,j)+4*reF(index2, i,j+sign_index2)-reF(index2, i,j+2*sign_index2))*sign_index2
endif

if ((bkey1 .or. bkey11 .or. bkey12) .and.&
    (bkey2 .or. bkey21 .or. bkey22)) then
	q(i,j)=(nxx*nxx+nxy*nxy+nyx*nyx+nyy*nyy) / (bnr(i,j) * (2.0*delta)**2.0)
else	
 	call ij2vp(i, j, vp)
	call trace_scott(vp, q0, q_perp0, rs, re, rbs, rbe, line_length, twist0, .false.)
	q(i,j)=q0
endif
end subroutine qfactor0_calculate


subroutine qfactor0()
use qfactor_common
implicit none
integer:: i, j
!----------------------------------------------------------------------------
allocate(sign2d(0:q1m1, 0:q2m1))
 cut_coordinate=0.0

!$OMP PARALLEL DO PRIVATE(i,j), schedule(DYNAMIC) 
	DO j= 0, q2m1
	DO i= 0, q1m1		 
		call  qfactor0_bridge(i,j)
	enddo	
	enddo
!$OMP END PARALLEL DO


if (.not. scottFlag) then 
!$OMP PARALLEL DO PRIVATE(i,j), schedule(DYNAMIC) 
	DO j= 0, q2m1
	DO i= 0, q1m1 
		call  qfactor0_calculate(i,j)
	enddo	
	enddo
!$OMP END PARALLEL DO
endif

call qmin2()
call out_slogq()

end subroutine qfactor0


subroutine qcs_bridge(i,j)
use qfactor_common
use trace_common
implicit none
real:: bp(0:2), vp(0:2), br(0:2), rs(0:2), re(0:2), &
	twist0, bn_0, bn_s, bn_e, bnt_tmp, line_length, &
	vpa1(0:2), rsa1(0:2), rea1(0:2), vpa2(0:2), rsa2(0:2), rea2(0:2), &
	vpb1(0:2), rsb1(0:2), reb1(0:2), vpb2(0:2), rsb2(0:2), reb2(0:2), &
	nxx, nxy, nyx, nyy, sxx, sxy, syx, syy, exx, exy, eyx, eyy, &
	q0, q_perp0, incline, u0(0:2), v0(0:2)
integer:: i, j, rbs, rbe, &
	rbsa1, rbea1, rbsa2, rbea2, rbsb1, rbeb1, rbsb2, rbeb2, &
	maxdim, index1, index2, pmin_mark(0:2), pmax_mark(0:2), &
	s_index0, s_index1, s_index2, e_index0, e_index1, e_index2, index_a, index_b
logical:: surface_flag, edge_flag, bkey
!----------------------------------------------------------------------------

call ij2vp(i, j, vp)

if (scottFlag) then 
	call trace_scott(vp, q0, q_perp0, rs, re, rbs, rbe, line_length, twist0, twistFlag)
	q(i,j)=q0
	q_perp(i,j)=q_perp0
else
	call interpolateB(vp, bp)	
	if (csflag) then
		incline=abs(dot_product(ev3,bp)/ norm2(bp))
	else
		incline=abs(bp(Normal_index)/ norm2(bp))
	endif
	call trace_bline(vp, rs, re, rbs, rbe, line_length, twist0, twistFlag, incline)
endif

rsF(:, i, j)=rs
reF(:, i, j)=re
rsboundary( i, j)=rbs
reboundary( i, j)=rbe

length(i, j)=line_length
if (twistFlag) twist(i, j)=twist0

if (scottFlag) return

if ((rbe .eq. 0) .or. (rbs .eq. 0) .or. (rbe .eq. 7) .or. (rbs .eq. 7))  return

!----------------------------------------------------------------------------
! deal with field lines touching the cut plane
e_index0=(6-rbe)/2
s_index0=(6-rbs)/2
call interpolateB(re, br)
bn_e=br(e_index0)
call interpolateB(rs, br)
bn_s=br(s_index0)

pmin_mark=0
pmax_mark=0

where(vp .lt. (pmin+delta) ) pmin_mark=1
where(vp .gt. (pmax-delta) ) pmax_mark=1

select case( sum(pmin_mark+pmax_mark))
	case(0)
		surface_flag=.false.
		edge_flag=.false.
	case(1)
		surface_flag=.true.		
		edge_flag=.false.
	case(2:3)
		surface_flag=.true. 
		edge_flag=.true.
		tangent_Flag(i, j)=.true.! unreal, for preventing bug
		q(i,j)=NaN
end select	


if (csflag) then 
	bn_0=sum(DBLE(bp)*ev3)
else
	bn_0=bp(Normal_index)
endif

bnr(i, j)=abs(DBLE(bn_s)*bn_e/(DBLE(bn_0)**2.))

if (surface_flag) then 	
	maxdim=sum(maxloc(pmin_mark+pmax_mark))-1
else
	maxdim=sum(maxloc(abs(bp)))-1
endif

if ( ((incline .le. min_incline) .or. surface_flag) &
   .and. (maxdim .ne. Normal_index) .and. (.not. edge_flag)) then

	tangent_Flag(i, j)=.true.
	
	index1=mod(maxdim+1,3)
	index2=mod(maxdim+2,3)
	
	if (surface_flag) then	
		u0=[0.,0.,0.]
		u0(index1)=1.
		v0=[0.,0.,0.]
		v0(index2)=1.
		incline=abs(bp(maxdim)/ norm2(bp))
		bn_0=bp(maxdim)
	else
		!use the plane perpendicular to the field line	
		bn_0=norm2(bp)
		
		v0(maxdim)= bp(index1)
		v0(index1)=-bp(maxdim)
		v0(index2)=0.
		
		v0   =v0 - dot_product(v0, bp)*bp /(bn_0*bn_0)
		v0   =v0/norm2(v0)

		u0(0)=dble(bp(1))*v0(2)-dble(bp(2))*v0(1)
		u0(1)=dble(bp(2))*v0(0)-dble(bp(0))*v0(2)
		u0(2)=dble(bp(0))*v0(1)-dble(bp(1))*v0(0)
		u0   =u0/norm2(u0)
		incline=1.
		
	endif
	
	bnt_tmp=abs(bn_s*bn_e/(dble(bn_0)**2.))	
		
	vpa1=vp+delta*u0
	call trace_bline(vpa1, rsa1, rea1, rbsa1, rbea1, line_length, twist0, .false., incline)
	vpa2=vp-delta*u0
	call trace_bline(vpa2, rsa2, rea2, rbsa2, rbea2, line_length, twist0, .false., incline)
	vpb1=vp+delta*v0
	call trace_bline(vpb1, rsb1, reb1, rbsb1, rbeb1, line_length, twist0, .false., incline)
	vpb2=vp-delta*v0
	call trace_bline(vpb2, rsb2, reb2, rbsb2, rbeb2, line_length, twist0, .false., incline)
	
	bkey= ( rbs .eq. rbsa1) .and. ( rbs .eq. rbsa2) .and. &
	      ( rbs .eq. rbsb1) .and. ( rbs .eq. rbsb2) .and. &
	      ( rbe .eq. rbea1) .and. ( rbe .eq. rbea2) .and. &
	      ( rbe .eq. rbeb1) .and. ( rbe .eq. rbeb2)

	s_index1=mod(s_index0+1,3)
	s_index2=mod(s_index0+2,3)

	e_index1=mod(e_index0+1,3)
	e_index2=mod(e_index0+2,3)

	if (bkey) then
		sxx = rsa1(s_index1)-rsa2(s_index1)
		syx = rsa1(s_index2)-rsa2(s_index2)
		exx = rea1(e_index1)-rea2(e_index1)
		eyx = rea1(e_index2)-rea2(e_index2)
		sxy = rsb1(s_index1)-rsb2(s_index1)
		syy = rsb1(s_index2)-rsb2(s_index2)
		exy = reb1(e_index1)-reb2(e_index1)
		eyy = reb1(e_index2)-reb2(e_index2)
	
		nxx =  exx*syy - exy*syx
		nxy = -exx*sxy + exy*sxx
		nyx =  eyx*syy - eyy*syx
		nyy = -eyx*sxy + eyy*sxx	
		qtmp(i,j) = (nxx*nxx + nxy*nxy + nyx*nyx + nyy*nyy) * bnt_tmp /((2.*delta)**4.)
	else
		call trace_scott(vp, q0, q_perp0, rs, re, rbs, rbe, line_length, twist0, .false.)
		qtmp(i,j)=q0
	endif
endif

END subroutine qcs_bridge


subroutine qcs_calculate(i,j)
use qfactor_common
use trace_common
implicit none
integer:: i, j, rbs, rbe
integer:: s_index0, s_index1, s_index2, sign_s_index1, sign_s_index2, e_index0, e_index1, e_index2, sign_e_index1, sign_e_index2
logical:: bkeys1, bkeys2, bkeys11, bkeys12, bkeys21, bkeys22, bkeye1,bkeye2, bkeye11, bkeye12, bkeye21, bkeye22
logical:: margin_flag1, margin_flag2
real:: sxx, sxy, syx, syy, exx, exy, eyx, eyy, nxx, nxy, nyx, nyy, vp(0:2), q0, q_perp0, rs(0:2), re(0:2), line_length, twist0
!----------------------------------------------------------------------------

rbs=rsboundary(i,j)
rbe=reboundary(i,j)

if((rbs .eq. 0) .or. (rbe .eq. 0) .or. (rbs .eq. 7) .or. (rbe .eq. 7)) then 
	q(i,j)=NaN
	return
endif

if (tangent_Flag(i,j)) then 
	q(i,j)=qtmp(i, j)
	return
endif

margin_flag1= (i .eq. 0) .or. (i .eq. q1m1) 
margin_flag2= (j .eq. 0) .or. (j .eq. q2m1)

bkeys1 = (.not. margin_flag1) .and. ( rbs .eq. rsboundary(i+1,j)) .and. ( rbs .eq. rsboundary(i-1,j)) 
bkeys2 = (.not. margin_flag2) .and. ( rbs .eq. rsboundary(i,j+1)) .and. ( rbs .eq. rsboundary(i,j-1))
bkeye1 = (.not. margin_flag1) .and. ( rbe .eq. reboundary(i+1,j)) .and. ( rbe .eq. reboundary(i-1,j)) 
bkeye2 = (.not. margin_flag2) .and. ( rbe .eq. reboundary(i,j+1)) .and. ( rbe .eq. reboundary(i,j-1))


bkeye11=(i+2 .le. q1m1) .and. ( rbe .eq. reboundary(i+1,j)) .and. ( rbe .eq. reboundary(i+2,j))
bkeye12=(i-2 .ge.    0) .and. ( rbe .eq. reboundary(i-1,j)) .and. ( rbe .eq. reboundary(i-2,j)) .and. (.not. bkeye11)
bkeye21=(j+2 .le. q2m1) .and. ( rbe .eq. reboundary(i,j+1)) .and. ( rbe .eq. reboundary(i,j+2))
bkeye22=(j-2 .ge.    0) .and. ( rbe .eq. reboundary(i,j-1)) .and. ( rbe .eq. reboundary(i,j-2)) .and. (.not. bkeye21)


bkeys11=(i+2 .le. q1m1) .and. ( rbs .eq. rsboundary(i+1,j)) .and. ( rbs .eq. rsboundary(i+2,j))
bkeys12=(i-2 .ge.    0) .and. ( rbs .eq. rsboundary(i-1,j)) .and. ( rbs .eq. rsboundary(i-2,j)) .and. (.not. bkeys11)
bkeys21=(j+2 .le. q2m1) .and. ( rbs .eq. rsboundary(i,j+1)) .and. ( rbs .eq. rsboundary(i,j+2))
bkeys22=(j-2 .ge.    0) .and. ( rbs .eq. rsboundary(i,j-1)) .and. ( rbs .eq. rsboundary(i,j-2)) .and. (.not. bkeys21)

s_index0=(6-rbs)/2
s_index1=mod(s_index0+1,3)
s_index2=mod(s_index0+2,3)

e_index0=(6-rbe)/2
e_index1=mod(e_index0+1,3)
e_index2=mod(e_index0+2,3)


if (bkeys11) sign_s_index1= 1
if (bkeys12) sign_s_index1=-1
if (bkeys21) sign_s_index2= 1
if (bkeys22) sign_s_index2=-1

if (bkeye11) sign_e_index1= 1
if (bkeye12) sign_e_index1=-1
if (bkeye21) sign_e_index2= 1
if (bkeye22) sign_e_index2=-1


if (bkeys1) then
	sxx = rsF(s_index1, i+1, j)-rsF(s_index1, i-1, j)
	syx = rsF(s_index2, i+1, j)-rsF(s_index2, i-1, j)
else if ((bkeys11) .or. (bkeys12)) then 
	sxx = (-3*rsF(s_index1, i, j)+4*rsF(s_index1, i+sign_s_index1, j)-rsF(s_index1, i+2*sign_s_index1, j))*sign_s_index1
	syx = (-3*rsF(s_index2, i, j)+4*rsF(s_index2, i+sign_s_index1, j)-rsF(s_index2, i+2*sign_s_index1, j))*sign_s_index1
endif

if (bkeys2) then
	sxy = rsF(s_index1, i, j+1)-rsF(s_index1, i, j-1)
	syy = rsF(s_index2, i, j+1)-rsF(s_index2, i, j-1)
else if ((bkeys21) .or. (bkeys22)) then 
	sxy = (-3*rsF(s_index1, i, j)+4*rsF(s_index1, i, j+sign_s_index2)-rsF(s_index1, i, j+2*sign_s_index2))*sign_s_index2
	syy = (-3*rsF(s_index2, i, j)+4*rsF(s_index2, i, j+sign_s_index2)-rsF(s_index2, i, j+2*sign_s_index2))*sign_s_index2
endif


if (bkeye1) then
	exx = reF(e_index1, i+1, j)-reF(e_index1, i-1, j)
	eyx = reF(e_index2, i+1, j)-reF(e_index2, i-1, j)
else if ((bkeye11) .or. (bkeye12)) then 
	exx = (-3*reF(e_index1, i, j)+4*reF(e_index1, i+sign_e_index1, j)-reF(e_index1, i+2*sign_e_index1, j))*sign_e_index1
	eyx = (-3*reF(e_index2, i, j)+4*reF(e_index2, i+sign_e_index1, j)-reF(e_index2, i+2*sign_e_index1, j))*sign_e_index1
endif

if (bkeye2) then
	exy = reF(e_index1, i, j+1)-reF(e_index1, i, j-1)
	eyy = reF(e_index2, i, j+1)-reF(e_index2, i, j-1)
else if ((bkeye21) .or. (bkeye22)) then 
	exy = (-3*reF(e_index1, i, j)+4*reF(e_index1, i, j+sign_e_index2)-reF(e_index1, i, j+2*sign_e_index2))*sign_e_index2
	eyy = (-3*reF(e_index2, i, j)+4*reF(e_index2, i, j+sign_e_index2)-reF(e_index2, i, j+2*sign_e_index2))*sign_e_index2
endif


if ((bkeys1 .or.  bkeys11 .or. bkeys12) .and. &
    (bkeys2 .or.  bkeys21 .or. bkeys22) .and. &
    (bkeye1 .or.  bkeye11 .or. bkeye12) .and. &
    (bkeye2 .or.  bkeye21 .or. bkeye22)) then
    
	nxx =  exx*syy - exy*syx
	nxy = -exx*sxy + exy*sxx
	nyx =  eyx*syy - eyy*syx
	nyy = -eyx*sxy + eyy*sxx

	q(i,j) = (nxx*nxx + nxy*nxy + nyx*nyx + nyy*nyy) * bnr(i,j) / ((2.*delta)**4.)
else
	call ij2vp(i, j, vp)
	call trace_scott(vp, q0, q_perp0, rs, re, rbs, rbe, line_length, twist0, .false.)
	q(i,j)=q0
endif

end subroutine qcs_calculate


subroutine qcs()
use qfactor_common
implicit none
integer:: i,j
!----------------------------------------------------------------------------
tangent_Flag=.false.
!$OMP PARALLEL DO PRIVATE(i,j), schedule(DYNAMIC) 	
	DO j= 0, q2m1
	DO i= 0, q1m1 
		call  qcs_bridge(i,j)
	enddo
	enddo
!$OMP END PARALLEL DO

if (.not. scottFlag) then

!$OMP PARALLEL DO PRIVATE(i,j), schedule(DYNAMIC) 
	DO j= 0, q2m1
	DO i= 0, q1m1 
		call  qcs_calculate(i,j)
	enddo	
	enddo
!$OMP END PARALLEL DO

endif

call qmin2()

end subroutine qcs


subroutine ij2vp(i, j, vp)
use qfactor_common
implicit none
integer:: i, j
real:: vp(0:2)
!----------------------------------------------------------------------------
select case(Normal_index)
	case(-1)
		vp=point0+dble(i*delta)*ev1+dble(j*delta)*ev2
	case(0) 				
		vp=[cut_coordinate , i*delta+yreg(0), j*delta+zreg(0)]
	case(1) 
		vp=[i*delta+xreg(0),  cut_coordinate, j*delta+zreg(0)]
	case(2) 
		vp=[i*delta+xreg(0), j*delta+yreg(0),  cut_coordinate]
end select
end subroutine ij2vp


subroutine qmin2()
use qfactor_common
implicit none
integer:: i, j
!----------------------------------------------------------------------------
DO j= 0, q2m1
DO i= 0, q1m1
	if (.not. ISNAN(q(i,j)) .and. (q(i,j).lt. 2.0)) q(i,j)=2.0
enddo	
enddo

if (scottFlag) then 
	DO j= 0, q2m1
	DO i= 0, q1m1
		if (.not. ISNAN(q_perp(i,j)) .and. (q_perp(i,j) .lt. 2.0)) q_perp(i,j)=2.0
	enddo	
	enddo
endif

end subroutine qmin2


subroutine out_slogq()
use qfactor_common
implicit none
integer:: i, j
real, allocatable:: slogq(:,:)
!----------------------------------------------------------------------------
allocate(slogq(0:q1m1, 0:q2m1))
slogq=sign2d*log10(q)

DO j= 0, q2m1
DO i= 0, q1m1		 
	if (ISNAN(q(i,j))) slogq(i,j)=0.0
enddo	
enddo


open(unit=8, file='slogq.bin', access='stream')
write(8) slogq
 close(8)

if (scottFlag) then 
	slogq=sign2d*log10(q_perp)
	
	DO j= 0, q2m1
	DO i= 0, q1m1		 
		if (ISNAN(q_perp(i,j))) slogq(i,j)=0.0
	enddo	
	enddo
	
	open(unit=8, file='slogq_perp.bin', access='stream')
	write(8) slogq
	close(8)
endif

deallocate(slogq, sign2d)

end subroutine out_slogq


subroutine show_time(percent)
real:: percent
integer:: times(8)
!----------------------------------------------------------------------------
call date_and_time(VALUES=times)	
print 600, percent, times(5), times(6), times(7)
600 format( '         ', F6.2, '%        ' ,I2.2, ':', I2.2, ':', I2.2)
end subroutine show_time


program qfactor
use qfactor_common
use field_common
implicit none
integer:: k, k0
!----------------------------------------------------------------------------
call initialize()

print*, '  _____________________________________'
print*, '        schedule         time'
call show_time(0.0)
!----------------------------------------------------------------------------
if (q0flag) then
!z=0 	
	call qfactor0()
	
	rboundary_tmp=reboundary(0:q1m1, 0:q2m1) ! For avoiding segmentation fault of IO
	open(unit=8, file='qfactor0.bin', access='stream')
	write(8) q, length, Bnr, reF, rboundary_tmp
	close(8)
	
	if (twistFlag) then
		open(unit=8, file='twist.bin', access='stream')
		write(8) twist
		close(8)
	endif
	
	if (scottFlag) then	
		open(unit=8, file='q_perp.bin', access='stream')
		write(8) q_perp
		close(8)		
	endif	
endif
!----------------------------------------------------------------------------
if (cflag) then
!qcs
	call qcs()
	
	open(unit=8, file='qcs.bin', access='stream')
	write(8) q, length, rsF, reF
	rboundary_tmp=rsboundary(0:q1m1, 0:q2m1) ! For avoiding segmentation fault of IO
	write(8) rboundary_tmp
	rboundary_tmp=reboundary(0:q1m1, 0:q2m1) ! For avoiding segmentation fault of IO
	write(8) rboundary_tmp
	close(8)
	 	
	if (twistFlag) then
		open(unit=8, file='twist.bin', access='stream')
		write(8) twist
		close(8)
	endif
	 	
	if (scottFlag) then	
		open(unit=8, file='q_perp.bin', access='stream')
		write(8) q_perp
		close(8)		
	endif
endif
!----------------------------------------------------------------------------	
if (vflag) then
!q3d
	open(unit=1, file='q3d.bin', access='stream')
	open(unit=2, file='rboundary3d.bin', access='stream')
	if(scottFlag) open(unit=3, file='q_perp3d.bin', access='stream')
	if(twistFlag) open(unit=4, file= 'twist3d.bin', access='stream')

	if (zreg(0) .eq. 0.0) then
		call qfactor0()
		write(1) q
		write(2) rboundary_tmp  ! had been transferred to rbs+8*rbe in subroutine qfactor0_bridge
		if (scottFlag) write(3) q_perp
		if (twistFlag) write(4) twist
		k0=1
	else
		k0=0
	endif
				
	do k=k0, qz-1			
		cut_coordinate=zreg(0)+k*delta
		call qcs()
		rboundary_tmp=rsboundary(0:qx-1, 0:qy-1)+8*reboundary(0:qx-1, 0:qy-1)	
		write(1) q
		write(2) rboundary_tmp
		if (scottFlag) write(3) q_perp
		if (twistFlag) write(4) twist
	
		if (mod(k+1, 4) .eq. 0) call show_time(float(k+1)/qz*100.0)
	enddo
	close(1)
	close(2)
	if (scottFlag) close(3)
	if (twistFlag) close(4)
endif
!----------------------------------------------------------------------------
if (.not. (vflag .and. (mod(qz, 4) .eq. 0))) call show_time(100.0)
!----------------------------------------------------------------------------
deallocate(Bfield, q, qtmp, reF, length, bnr, reboundary, rboundary_tmp)
if (twistFlag) deallocate(twist, curlB)
if (scottFlag) deallocate(q_perp, grad_unit_vec_Bfield)
if (cflag .or. vflag) deallocate(rsF, rsboundary, tangent_Flag)

end program qfactor
