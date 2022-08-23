function id2commit, id

;+ 
; name: id2commit
;
; purpose: find the git commit hash closest to the time specified by a run id
;
; calling sequence: 
;                   id2commit, id 
;                   id2commit, '1661246977'
; 
; inputs: 
;        id: A string containing the systime when the run was made
;
; outputs:
;         commit id: commit id closest to the input time
;
; author : Avijeet Prasad
; created on : 2022-08-23
;
; updates :
;-
if not isa(id) then id = systime(/seconds)
idtime = strtrim(systime(elapsed=id),1)
spawn, "git log --until='" + idtime + "' -1" + " --pretty=format:'%h'", commitid
print, 'ID systime: ', idtime 
print, 'Closest commit: ', commitid
spawn, 'git --no-pager show ' + commitid + ' --no-patch'
return, commitid
end