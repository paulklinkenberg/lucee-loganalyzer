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
	request.subTitle = "Log Monitor";
	param name="url.xhr" default="false";
	param name="url.severity"  default="";
	st_severity = {};
	if (len(url.severity) gt 0){
		var _severity = ListToArray(url.severity);
		for (var h in _severity)
			st_severity[h] = true;
	}
	param name="url.file"  default="";
	st_files = {};
	if (len(url.file) gt 0){
		var _file = ListToArray(url.file);
		for (var f in _file)
			st_files[f] = true;
	}
	st_all_files = {};
</cfscript>

<cfif request.admintype eq "server">
	<cfparam name="session.loganalyzer.webID" default="" />
	<cfif not len(session.loganalyzer.webID)>
		<cfset var gotoUrl = rereplace(action('overview'), "^[[:space:]]+", "") />
		<cflocation url="#gotoUrl#" addtoken="no" />
	</cfif>
	<cfif session.loganalyzer.webID eq "serverContext">
		<cfoutput><h3>Server context log files</h3></cfoutput>
	<cfelse>
		<cfoutput><h3>Web context <em>#getWebRootPathByWebID(session.loganalyzer.webID)#</em></h3></cfoutput>
	</cfif>
</cfif>
<cfset formAction = trim(action('overview'))>
<cfoutput>
<cfsavecontent variable="formControls">
	<form action="#formAction#" method="post" class="log-actions">
		<div class="log-controls">
			Search: <input type="text" class="search-logs" size="50">
			<input class="button" data-action="search" type="button" value="Search"/>
			<input class="button" data-action="clear-search" type="button" value="Clear"/>
			<!---<input class="daterange" type="text" value="" size="20"> --->

			<input class="button" data-action="poll" type="button" value="Poll"/>
			<input class="button" data-action="reload" type="button" value="Reload"/>
			<select class="poll-period" size=1>
				<option value="30">30s</option>
				<option value="60">1m</option>
				<option value="300" selected>5m</option>
				<option value="900">15m</option>
				<option value="1800">30m</option>
			</select>
			<input class="button" data-action="auto-refresh" type="button" value="Start Auto Refresh"/>

			<div class="log-severity-filter">
				<cfloop list="INFO,INFORMATION|WARN,WARNING|ERROR|FATAL|DEBUG|TRACE" index="severity" delimiters="|">
					<span class="log-severity-filter-type">
						<cfset sev = listFirst(severity,",")>
						<label class="log-severity-#sev#">
							#sev# <input name="severity" type="checkbox" value="#sev#" <cfif not structKeyExists(st_severity, sev)>checked</cfif>>
						</label>
					</span>
				</cfloop>
				<input class="button" data-action="admin" type="button" value="Administer Log Files"/>
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
<cfif url.xhr>
	<Cfcontent reset="yes">
</cfif>
<div class="logs-error" style="display:none;"></div>
<div class="logs-loading" style="display:none;">Loading Logs.... please wait</div>
<cfset num=0/>
<cfset limit=5/>
<cfoutput>
	<div class="longwords logs" data-fetched="#DateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ss")#"
		data-files="#url.file#">
</cfoutput>
	<cfscript>
		q_log = req.logs.q_log;
	</cfscript>
	<cfsetting enablecfoutputonly="true">
	<cfloop query="q_log">
		<cfoutput><div class="log log-severity-#q_log.severity# log-file-filter-#replace(q_log.logfile,".","_","all")# #num mod 2 ? 'odd':''#"></cfoutput>
		<Cfif len(q_log.stack) gt 0>
			<cfoutput><a class="log-expand" data-log="#num#">expand</a></cfoutput>
		</cfif>
		<cfoutput><div class="log-header"><span class="log-fie">#q_log.logfile#</span></cfoutput>
			<cfoutput><span class="log-severity">#q_log.severity#</span></cfoutput>
			<cfoutput><span class="log-timestamp">#LSDateFormat(q_log.logtimestamp)# #LSTimeFormat(q_log.logtimestamp,"hh:mm:ss:l")#</span></cfoutput>
		<cfoutput></div></cfoutput>
		<cfoutput><div class="log-detail"></cfoutput>
		<cfset r = 1>
		<!---
		<cfdump var="#dump(queryGetRow(q_log, q_log.currentrow))#" expand="false">
		--->

		<cfoutput>#htmleditformat(q_log.log)#</cfoutput>
		<Cfif q_log.cfstack.len() gt 0>
			<cfset _stack = q_log.cfstack[currentrow]>
			<cfoutput><ol class="cfstack"></cfoutput>
			<Cfset maxrows = Min(ArrayLen(_stack),15)>
			<cfloop from="1" to="#maxrows#" index="s">
				<cfoutput><li>#_stack[s]#</li></cfoutput>
			</cfloop>
			<cfoutput></ol></cfoutput>
		</cfif>
		<Cfif len(q_log.stack) gt 0>
			<cfoutput><div style="display:none;" class="collapsed-log"></cfoutput>
			<cfloop list="#q_log.stack#" item="item" delimiters="#chr(10)#">
				<cfoutput>#htmleditformat(item)#<br></cfoutput>
			</cfloop>
			<cfoutput></div></cfoutput>
		</cfif>
		<cfoutput></div><!---log-detail---></cfoutput>
		<cfoutput></div><!---log---></cfoutput>
		<cfset num++ />
	</cfloop>
	<cfsetting enablecfoutputonly="false">
</div>
<cfoutput>

	<cfif url.xhr>
		<cfabort>
	<cfelse>
		<form action="#formAction#" method="post">
			<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
		</form>
		<!---
		#renderUtils.includeCss("daterangepicker")#
		#renderUtils.includeCss("bootstrap.min")#
		#renderUtils.includeJavascript("bootstrap.min")#
		#renderUtils.includeJavascript("moment-with-locales.min")#
		#renderUtils.includeJavascript("daterangepicker")#
		--->
		#renderUtils.includeJavascript("viewlog")#

	</cfif>
</cfoutput>
