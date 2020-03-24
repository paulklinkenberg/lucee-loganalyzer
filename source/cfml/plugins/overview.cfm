<!---
 *
 * Copyright (c) 2016, Paul Klinkenberg, Utrecht, The Netherlands.
 * Originally written by Gert Franz, Switzerland.
 * All rights reserved.
 *
 * Date: 2016-02-11 13:45:05
 * Revision: 2.3.1.
 * Project info: http://www.lucee.nl/post.cfm/railo-admin-log-analyzer
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 --->
<!--- when viewing logs in the server admin, then a webID must be defined --->

<cfscript>
	request.title = "Log Viewer";
	request.subtitle = "";
	param name="req.xhr" default="false";
	param name="req.severity"  default="";
	param name="req.q"  default="";
	param name="req.start"  default="";
	param name="req.end"  default="";
	formAction = trim(action('overview'));

	st_severity = {};
	if (len(req.severity) gt 0){
		var _severity = ListToArray(req.severity);
		for (var h in _severity)
			st_severity[h] = true;
	}
	param name="req.file"  default="";
	st_files = {};
	if (len(req.file) gt 0){
		var _file = ListToArray(req.file);
		for (var f in _file)
			st_files[f] = true;
	}
	st_all_files = {};

	var info = {};
	for (var f in req.logs){
		if (f neq "Q_LOG")
			info[f]=req.logs[f];
	}
	if (req.start eq "")
		req.start = DateFormat(req.logs.q_log.LOGTIMESTAMP, "yyyy-mm-dd");
	if (req.end eq "")
		req.end = DateFormat(req.logs.q_log.LOGTIMESTAMP[req.logs.q_log.recordcount], "yyyy-mm-dd");

</cfscript>

<cfif request.admintype eq "server">
	<cfinclude  template="contextSelector.cfm">
</cfif>
<cfoutput>

<script>
	var logViewerStats = #serializeJSON(info)#;
	console.table(logViewerStats.STATS);
	console.log(logViewerStats);

	var logViewerDates = {
		start: '#req.start#',
		end: '#req.end#',
		firstLogDate: '#req.logs.firstLogDate#'
	};
</script>

<cfsavecontent variable="formControls">
	<form action="#formAction#" method="get" class="log-actions">
		<input type="hidden" name="plugin" value="#req.plugin#">
		<input type="hidden" name="action" value="#req.action#">
		<input type="hidden" name="pluginAction" value="#req.pluginAction#">
		<div class="log-controls">
			<input type="text" name="q" class="search-logs" size="50" value="#htmleditformat(req.q)#">
			<input class="button" data-action="search" type="button" value="#i18n('Search')#"
				title="#htmleditformat(i18n('searchHint'))#"/>
			<input class="button" data-action="clear-search" type="button" value="#i18n('Clear')#"/>
			<input class="button" data-action="poll" type="button" value="#i18n('Poll')#"/>
			<input class="button" data-action="reload" type="button" value="#i18n('Reload')#"/>
			<div class="log-toolbar-group">
				<select class="poll-period" size=1>
					<option value="30" selected>30s</option>
					<option value="60">1m</option>
					<option value="300" >5m</option>
					<option value="900">15m</option>
					<option value="1800">30m</option>
				</select>
				<input class="button" data-action="auto-refresh" type="button" value="#i18n('StartAutoRefresh')#"/>
			</div>
			<input class="daterange" type="text" value="" size="30">
			<div class="log-severity-filter">
				<cfloop list="INFO,INFORMATION|WARN,WARNING|ERROR|FATAL|DEBUG|TRACE" index="variables.severity" delimiters="|">
					<span class="log-severity-filter-type">
						<cfset variables.sev = listFirst(variables.severity,",")>
						<label class="log-severity-#variables.sev#">
							#sev# <input name="severity" type="checkbox" value="#variables.sev#"
								<cfif not structKeyExists(st_severity, variables.sev)>checked</cfif>>
						</label>
					</span>
				</cfloop>
				<input class="button" data-action="admin" type="button" value="#i18n('AdminLogFiles')#"/>
			</div>

		</div>
		<div class="log-file-selector">
			<cfset q = req.logs.q_log_files>
			<cfloop query="q">
				<cfset st_all_files[q.name] = true>
				<label class="log-file-filter">
					#q.name#
					<input name="file" type="checkbox" value="#q.name#" <cfif structKeyExists(st_files, q.name)>checked</cfif>>
				</label>
			</cfloop>
		</div>

	</form>
	<style class="log-severity-filter-css">
		<cfsetting enablecfoutputonly="true">
		<cfloop collection="#st_severity#" item="h">
			.log-severity-#h#.log { display: none;}
		</cfloop>
		<cfsetting enablecfoutputonly="false">
	</style>
	<!--- file filter work by reverse selection --->
	<style class="log-file-filter-css">
		<cfif structcount(st_files) gt 0>
			<cfloop collection="#st_all_files#" item="f">
				<cfif not structKeyExists(st_files, f)>
					.log-file-filter-#replace(f,".","_","all")#.log { display: none;}
				</cfif>
			</cfloop>
		</cfif>
	</style>
</cfsavecontent>
	#renderUtils.cleanHtml(formControls)# <!--- avoid lots of whitespace --->
</cfoutput>
<cfif req.xhr>
	<Cfcontent reset="yes">
</cfif>
<cfset variables.num=0/>
<cfset variables.limit=5/>
<cfoutput>
	<div class="logs-error" style="display:none;"></div>
	<div class="logs-loading" style="display:none;">#i18n('LoadingLogs')#</div>

	<div class="longwords logs" data-fetched="#DateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ss")#"
		data-search="#htmleditformat(req.q)#"
		data-files="#req.file#">
</cfoutput>
	<cfscript>
		q_log = req.logs.q_log;
	</cfscript>
	<cfsetting enablecfoutputonly="true">
	<cfloop query="q_log">
		<cfset variables.hideRow = "">
		<cfif variables.q_log.currentrow gt 1>
			<cfset variables.lastRow = variables.q_log.currentrow-1>
			<cfif variables.q_log.logfile eq variables.q_log.logfile[variables.lastrow]
					and variables.q_log.severity eq variables.q_log.severity[variables.lastrow]
					and variables.q_log.thread eq variables.q_log.thread[variables.lastrow]
					and variables.q_log.logtimestamp eq variables.q_log.logtimestamp[variables.lastrow]>
				<cfset variables.hideRow = ' style="display:none" '>
			</cfif>
		</cfif>

		<cfoutput><div class="log <cfif len(variables.hideRow)>log-grouped</cfif> log-severity-#variables.q_log.severity# log-file-filter-#replace(variables.q_log.logfile,".","_","all")# #variables.num mod 2 ? 'odd':''#"></cfoutput>
		<Cfif len(variables.q_log.stack) gt 0>
			<cfoutput><a class="log-expand" data-log="#variables.num#">expand</a></cfoutput>
		</cfif>
		<cfoutput><div class="log-header" #variables.hideRow#><span class="log-fie">#variables.q_log.logfile#</span></cfoutput>
			<cfoutput><span class="log-severity">#variables.q_log.severity#</span></cfoutput>
			<cfoutput><span class="log-timestamp"> #LSTimeFormat(variables.q_log.logtimestamp, i18n("timeformat") )#,
			#LSDateFormat(variables.q_log.logtimestamp, i18n("dateformat"))#</span></cfoutput>
			<cfoutput><span class="log-thread">#variables.q_log.thread#</span></cfoutput>
		<cfoutput></div></cfoutput>
		<cfoutput><div class="log-detail"></cfoutput>
		<cfset variables.r = 1>
		<!---
		<cfdump var="#dump(queryGetRow(q_log, q_log.currentrow))#" expand="false">
		--->

		<cfoutput>#htmleditformat(variables.q_log.log)#</cfoutput>
		<Cfif variables.q_log.cfstack.len() gt 0>
			<cfset variables._stack = variables.q_log.cfstack[variables.q_log.currentrow]>
			<cfoutput><ol class="cfstack"></cfoutput>
			<Cfset variables.maxrows = Min(ArrayLen(variables._stack),15)>
			<cfloop from="1" to="#variables.maxrows#" index="variables.s">
				<cfoutput><li><a title="show matching logs">#variables._stack[variables.s]#</a></li></cfoutput>
			</cfloop>
			<cfoutput></ol></cfoutput>
		</cfif>
		<Cfif len(variables.q_log.stack) gt 0>
			<cfoutput><div style="display:none;" class="log-stacktrace"></cfoutput>
			<cfloop list="#variables.q_log.stack#" item="variables.item" delimiters="#chr(10)#">
				<cfoutput>#htmleditformat(variables.item)#<br></cfoutput>
			</cfloop>
			<cfoutput></div></cfoutput>
		</cfif>
		<cfoutput></div><!---log-detail---></cfoutput>
		<cfoutput></div><!---log---></cfoutput>
		<cfset variables.num++ />
	</cfloop>
	<cfsetting enablecfoutputonly="false">
</div>
<cfoutput>

	<cfif url.xhr>
		<cfabort>
	<cfelse>
		<form action="#formAction#" method="post">
			<input class="submit" type="submit" value="#i18n('Back')#" name="mainAction"/>
		</form>
		#renderUtils.includeLang()#
		#renderUtils.includeJavascript("moment-with-locales.min")#
		#renderUtils.includeCss("daterangepicker")#
		#renderUtils.includeJavascript("daterangepicker")#
		#renderUtils.includeJavascript("viewlog")#
	</cfif>
</cfoutput>
