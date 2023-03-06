function ssw_jsoc, ds, p1, debug=debug, jsoc_url=jsoc_url, $
   _extra=_extra, service=service, show_series=show_series, $
   info=info, series_struct=series_struct, $
   rs_summary=rs_summary, rs_list=rs_list, exp_kinds=exp_kinds, $
   export=export, exp_status=exp_status, method=method, protocol=protocol, $
   serstr=serstr, plain_text=plain_text, interactive=interactive, jsoc2=jsoc2, $
   status=status, nostrcompress=nostrcompress, xquery=xquery, $
   hidden_keys=hidden_keys
;+
;   Name: ssw_jsoc
;
;   Purpose: ssw client/socket interface to SDO JSOC cgi/json
;
;   Input Parameters:
;      ds - Data Series name (alternate to use of keyword ds="<ds>")
;
;   Keyword Parameters:
;      jsoc_url - optional parent IP; default=jsoc.stanford.edu
;      service - service name; default='show_series' -
;                for example, 'jsoc_info' works and future>
;      _extra - cgi service parameters of form PARAM=VALUE (via keyword inherit)
;      /rs_summary,/show_series,
;      exp_request -(input) JSOC requestID -or- structrure from previous exp_request
;      status (output) - 1 if ok, 0 if NotOK
;      add_query(switch) - if set and rs_list, add JS_QUERY tag to structure
;      hidden_keys - optional list of "hidden" keys, like *recnum* (only via user DS &key= for today)
;
;   Calling Examples/Context:
;
;   IDL> ser=ssw_jsoc(service='show_series',filter='mdi')
;
;   IDL> help,ser,ser.names,/str,out=out
; ** Structure <261d3f4>, 3 tags, length=764, data length=760, refs=1:
;    STATUS          INT              0
;    NAMES           STRUCT    -> <Anonymous> Array[21]
;    N               INT             21
; ** Structure <261d294>, 3 tags, length=36, data length=36, refs=2:
;    NAME            STRING    'ds_mdi.fd_M_01h_lev1_8'
;    PRIMEKEYS       STRING    ' series_num'
;    NOTE            STRING    'test series for storage of MDI dataset'
;
;    Get info re: one of the above Data Series
;    IDL> reccnt=ssw_jsoc(ds=ser.names(10).name,service='jsoc_info',op='rs_summary')
;    IDL> help,reccnt,/str,out=arr
;  ** Structure <2620be4>, 2 tags, length=4, data length=4, refs=1:
;     COUNT           INT            201 <<< #i Recordds
;     STATUS          INT              0
;
;   History:
;      Circa March 2008 - S.L.Freeland - socket/jsoc interface check
;      9-jun-2008 - S.L.Freeland - flesh this out; add SERVICE & _EXTRA
;     11-jun-2008 - S.L.Freeland - call to proto-ssw_json2struct.pro
;     17-jun-2008 - S.L.Freeland - web_dechunk calls etc...
;     20-jun-2008 - S.L.Freeland - extend ssw_json2struct -> show_series
;                                  (ssw_json2struct exented to Longish JSON)
;      8-mar-2009 - S.L.Freelando - dust off, better json->struct, rs_list typing
;     16-mar-2008 - S.L.Freeland - enable exp_status=requestIDL
;     18-feb-2010 - S.L.Freeland - minor tweaks - needs a few more...
;     26-feb-2010 - S.L.Freeland - email address tweak
;     22-may-2010 - S.L.Freeland - switch default back to "public" default jsoc.stanford.edu
;      9-jul-2010 - S.L.Freeland - abort on series not found...
;     26-jul-2010 - S.L.Freeland - assure jsoc url includes trailing '/'
;      1-jul-2010 - S.L.Freeland - add explicit /JSOC2 switch (or via $ssw_jsoc environ.)
;      8-sep-2010 - S.L.Freeland - jsoc_info.csh -> jsoc_info for /RS_LIST
;      9-dec-2010 - S.L.Freeland - add /add_query
;      8-apr-2011 - S.L.Freeland - /show_series - handle "large" # entries
;     22-jul-2011 - S.L.Freeland - sock_list2 for client side firewall via  $http_proxy support
;     24-jul-2012 - S.L.Freeland - jsoc_fetch_test -> jsoc_fetch
;     20-sep-2012 - S.L.Freeland - fix issue with /PLAIN_TEXT option (verbatim show_info)
;     28-sep-2012 - S.L.Freeland - allow "hidden keys" in DS like &key=*recnum*
;     25-apr-2013 - Zarro (ADNET) - replace sock_list2 by sock_list
;     18-jul-2013 - S.L.Freeland - by popular demand, a bit quieter (no functional change)
;     18-mar-2015 - S.L.Freeland - enforce new JSOC export requirement to include NOTIFY
;     31-mar-2015 - S.L.Freeland - made NOTIFY message a little less cryptic/added jsoc-register URL
;
;   Restrictions:
;      Yes. check back tommorrow for better&faster version
;   ref: http://www.lmsal.com/solarsoft/jsoc/ssw_jsoc_routines.html
;
debug=keyword_set(debug)

jsoc=get_logenv('jsoc_url')
jsoc2env=get_logenv('jsoc2') ne ''
case 1 of
   keyword_set(jsoc2) or jsoc2env: jsoc_url='http://jsoc2.stanford.edu/'
   jsoc ne '': jsoc_url=jsoc
   else:
endcase

if n_elements(jsoc_url) eq 0 then jsoc_url='http://jsoc.stanford.edu/'

jsoc_url=jsoc_url + (['','/'])(strlastchar(jsoc_url) ne '/')
cgibin=jsoc_url + 'cgi-bin/'
ajax=cgibin+'ajax/'

export=keyword_set(export)
expstat=keyword_set(exp_status)

series_struct=keyword_set(series_struct)

checkkey=0
plain_text=keyword_set(plain_text) ; override json default
case 1 of  ; setup some common operations/service combos (keywords)
   plain_text: begin
      service='show_info'
      op=''
   endcase
   keyword_set(rs_list): begin
      op='rs_list'
      service='jsoc_info' ; jsoc_info.csh -> jsoc_info Sept. 8, 2010 slf
      checkkey=1 ; require 'key' parameter
   endcase
   keyword_set(rs_summary): begin
      op='rs_summary'
      service='jsoc_info'
   endcase
   series_struct: begin
      op='series_struct'
      service='jsoc_info'
   endcase
   export or expstat: begin
      service= 'jsoc_fetch'  ;_test' ;jsoc_fetch.csh'
      if n_elements(method) eq 0 then method='url_quick'
      protocolx=n_elements(protocol) gt 0 or required_tags(_extra,/protocol)
      if n_elements(protocol) eq 0 then protocol='as-is'
      if export then begin
         op='exp_request'
         _extra=add_tag(_extra,method,'method',/quiet)
         _extra=add_tag(_extra,protocol,'protocol',/quiet)
         jsoc_notify=get_logenv('jsoc_notify')
         ssw_mail_address=get_logenv('ssw_email_address') ;
         _enotify=gt_tagval(_extra,/notify,missing=gt_tagval(_extra,/jsoc_notify,missing=''))
         case 1 of
            strmatch(_enotify,'*@*'): emailadd=_enotify ; user supplied NOTIFY or JSOC_NOTIFY via keyword
            strmatch(jsoc_notify,'*@*'): emailadd=jsoc_notify ; user supplied $jsoc_notify
            strmatch(ssw_mail_address,'*@*'): emailadd=ssw_mail_address ; user supplied $ssw_mail_address
            else: begin
               box_message,['Spoofing jsoc NOTIFY email via freeland@lmsal.com', $
                            'You may avoid this message by registering Your email@jsoc via:',$
                            'http://jsoc.stanford.edu/ajax/register_email.html']
               emailadd='avijeet.prasad@astro.uio.no'
            endcase
         endcase
         if _enotify eq '' then _extra=add_tag(_extra,emailadd,'notify',/quiet)
         if not required_tags(_extra,'requester') then _extra=add_tag(_extra,emailadd,'requestor',/quiet)
      endif else begin
         op='exp_status'
         requestid=gt_tagval(exp_status,/requestid,missing=exp_status)
         _extra=add_tag(_extra,requestid,'requestid')
         if not tag_exist(_extra,'format') then $
           _extra=add_tag(_extra,'json','format')
      endelse

   endcase
   keyword_set(info): service='jsoc_info'
   else:
endcase

if data_chk(op,/string) then begin
   if data_chk(_extra,/struct) then _extra=add_tag(_extra,op,'op') else $
      _extra={op:op}
endif


if n_elements(service) eq 0 then service='show_series'
params=''
if data_chk(_extra,/struct) then begin
   pnames=strlowcase(strtrim(tag_names(_extra),2)+'=')
   params=params+'?'+pnames(0)+url_encode(strtrim(_extra.(0),2))
   for pn=1,n_elements(pnames)-1 do begin
      params=params+'&'+pnames(pn)+url_encode(strtrim(_extra.(pn),2))
   endfor
endif
cmd=ajax+service+params

if checkkey then begin ; check for some KEY definition
   if strpos(cmd,'key') eq -1 then $
      cmd=cmd+'&key=**ALL**' ; needed for success
endif

status = 0 ; as with life, assume failure
;sock_list2,cmd,/cgi, json_data    ;commented out by DMZ (4/25/13)

sock_list,cmd,json_data,err=err

if debug then stop,'cmd,json_data'
if is_string(err) then begin
   box_message,['jsoc returned error; assume timeout', $
     'may indicate "too much data" requested"', $
     'reduce time range and/or use WAVES list and/or use KEY (param. subset), or...' ]
     return,'' ; !! EARLY EXIT on jsoc error Return
endif

if plain_text then begin  ; show_info verbatim output
   return,json_data ; !!! EARLY EXIT if /PLAIN_TEXT (avoid json processing, verbatim json_info output
endif
json_data=web_dechunk(json_data,/compress)

sss=where(strpos(json_data,'{') ne -1,ssscnt)
sse=where(strpos(json_data,'}') ne -1,ssecnt)

if ssscnt eq 0  then begin
   box_message,'No records/series match your request '
   return,''  ; !!EARLY exit on no
endif

sdata=  json_data(sss(0):last_nelem(sse)) ; JSON object suset
if get_logenv('jsoc_check') ne '' then stop,'sdata
if n_elements(sdata) eq 1 and strpos(strlowcase(sdata(0)),'error') ne -1 and total(strlen(sdata)) lt 200 then begin
   box_message,['JSOC Error',sdata,'... aborting']
   return,''  ; !!! EARLY exit on jsoc error
endif

case 1 of
   service eq 'show_series': begin
      ss=where(strpos(sdata,'{"name":') ne -1, sscnt)
      if sscnt gt 0 then begin
         if n_elements(sdata) gt 100 then begin
            ns=n_elements(sdata)
            head=sdata(0:sse(0)-1)
            tail=sdata(last_nelem(sse)-1:*)
            limit=ns-n_elements(head) - n_elements(tail)+1
            b0=sse(0)
            while b0 lt limit do begin
               b1=b0+100 < limit ; ad-hoc N=100
               temp=ssw_json2struct([head,sdata(b0:b1),tail], debug=debug)
               b0=b1
               if not data_chk(retval,/struct) then begin
                  retval=temp
               endif else begin
                  ss=where_arr(temp.names.name,retval.names.name,count,/noteq)
                  if count gt 0 then begin
                     temp=rep_tag_value(temp,temp.names(ss),'names')
                     allnames=concat_struct(retval.names,temp.names)
                     retval=rep_tag_value(retval,allnames,'names')
                  endif
               endelse
            endwhile
         endif else retval=ssw_json2struct(sdata,debug=debug)
         if keyword_set(interactive) then begin
            menu=get_infox(retval.names,'name,note')
            ss=xmenu_sel(menu,/one)
            if ss(0) ne -1 then retval=strtrim(retval.names(ss).name,2) else box_message,'nothing selected...'

         endif
	 status=1
         if debug then stop,'retval'
      endif else begin
        retval=''
        box_message,'No series matching your FILTER'
      endelse

      if debug then stop,'sdata,retval'
   endcase
   op eq 'rs_list': begin
      if not data_chk(serstr,/struct) then begin
        if n_elements(ds) gt 0 then rootds=ds else $
           rootds=gt_tagval(_extra,/ds, missing='')
        if rootds eq '' then begin
           box_message,'Need Data Series positional -or- DS= keyword..'
           return,-1
        endif
        if strpos(rootds,'[') ne -1 then rootds=ssw_strsplit(rootds,'[',/head)
        serstr=ssw_jsoc(ds=rootds(0),/series_struct,jsoc2=jsoc2)  ; need for tag typing
        status=1
      endif
      if get_logenv('jsoc_check') then stop,'rslist/sdata'
      if strlen(sdata(0)) lt 25 or strpos(sdata(0),'"count":0') ne -1 then begin
         box_message,['JSOC repports > ' + sdata(0)]
         return,-1  ; EARLY Exit on Error
      endif else begin
         template=ssw_jsoc_keywords2struct(serstr) ; jsoc keyword->IDL template
         if strpos(cmd,'**ALL**') eq -1 or keyword_set(hidden_keys) then begin
            kdelim=(['&key%3D','&KEY%3D'])(strpos(cmd,'&KEY') ne -1)
            ukeys=strextract(cmd+'&',kdelim,'&')
            if strpos(ukeys,'*') ne -1 then begin
               ukeys=str2arr(ukeys)
               ssh=where(strpos(ukeys,'*') ne -1)
               skeys=ukeys(ssh)
               for ssk=0,n_elements(skeys)-1 do begin
                  vname=str_replace(skeys(ssk),'*','_')
                  sloc=where_pattern(sdata,skeys(ssk))
                  bdata=byte(sdata)
                  bdata(sloc(0)) = byte(vname) ; *blah* -> _blah_
                  template=add_tag(template,0,vname)
               endfor
            endif
         endif
         retval=ssw_nameval2struct(sdata,template) ; rs_list json->IDL struct
         if keyword_set(add_query) then begin
            retval=add_tag(temporary(retval),ds(0),'js_query')
         endif
      endelse
      if get_logenv('keycheck') then stop,'template,retval,sdta)
   endcase
   series_struct: begin

      retval=jsoc_series_json2struct(sdata) ; new pat
      if debug then stop,'series_struct'
      status=1
   endcase
   service eq 'jsoc_info': begin
      retval=ssw_json2struct(sdata,debug=debug) ; {JSON} -> {IDL}
      if  debug then stop,'service='+service
      status=1
   endcase
   else: begin
      dchk=where(strpos(sdata,'"data":[{') ne -1,dcnt)
      if dcnt gt 0 then retval=ssw_jsoc_datajson2struct(sdata) else $
         retval=ssw_json2struct(sdata,debug=debug)
      status=1
   endcase
endcase
return,retval

end
