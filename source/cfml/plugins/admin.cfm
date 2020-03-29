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
<cfparam name="req.file" default="">
<cfparam name="req.result" default="">
<cfset thispageaction = rereplace(action('overview'), "^[[:space:]]+", "") />

<!--- show a select list of all the web contexts --->
<cfif request.admintype eq "server">
	<cfset url.nextAction="admin">
	<cfinclude  template="contextSelector.cfm">
</cfif>
<cfoutput>
	<cfif len(req.result)>
		<p><em>#req.result#</em></p>
	</cfif>
	
	<table class="maintbl log-overview">
	<thead>
		<tr>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=name<cfif req.sort eq 'name' and req.dir neq 'desc'>&amp;dir=desc</cfif>"
				title="#i18n('Orderonthiscolumn')#"<cfif req.sort eq 'name'>
				style="font-weight:bold"</cfif>>#i18n('logfilename')#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=datelastmodified<cfif req.sort neq 'datelastmodified' or req.dir neq 'desc'>&amp;dir=desc</cfif>"
				title="#i18n('Orderonthiscolumn')#"<cfif req.sort eq 'datelastmodified'>
				style="font-weight:bold"</cfif>>#i18n('logfiledate')#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=created<cfif req.sort neq 'created' or req.dir neq 'desc'>&amp;	dir=desc</cfif>"
				title="#i18n('Orderonthiscolumn')#" <cfif req.sort eq 'created'>
				style="font-weight:bold"</cfif>>#i18n('logfilecreated')#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=size<cfif req.sort neq 'size' or req.dir neq 'desc'>&amp;dir=desc</cfif>"
				title="#i18n('Orderonthiscolumn')#"<cfif req.sort eq 'size'>
				style="font-weight:bold"</cfif>>#i18n('logfilesize')#</a></th>
			<th>#i18n('actions')#</th>
		</tr>
	</thead>
	<tbody>
		<cfset q =arguments.req.logfiles>
		<cfloop query="q">
			<tr data-logfile="#htmleditformat(q.name)#">
				<td class="name">
				<cfif q.supportedFormat>
					<a href=#action('overview',"file=#q.name#")#>#name#</a>
				<cfelse>
					#name#
					<p class="log-unsupported">#i18n('unsupportedLogformat')#</p>
				</cfif>
				</td>
				<td><abbr title="#dateformat(q.datelastmodified, i18n('dateformat'))# #timeformat(q.datelastmodified, i18n('timeformatshort'))#">
					#renderUtils.getTextTimeSpan(q.datelastmodified)#</abbr></td>
				<td><abbr title="#dateformat(q.created, i18n('dateformat'))# #timeformat(q.created, i18n('timeformatshort'))#">
					#renderUtils.getTextTimeSpan(q.created)#</abbr></td>
				<td><cfif q.size lt 1024>#size# #i18n('bytes')#<cfelse>#ceiling(q.size/1024)# #i18n('KB')#</cfif></td>
				<td style="text-align:right; white-space:nowrap; width:1%">
					<!--<input type="submit" class="button" data-action="list" value="#i18n('analyse')#"/>-->
					<cfif q.supportedFormat>
						<input type="button" class="button" data-action="overview" value="#i18n('viewlog')#" />
					</cfif>
					<input type="button" class="button" data-action="download"value="#i18n('download')#" />
					<input type="button" class="button" data-action="delete" value="#i18n('delete')#" />
				</td>
			</tr>
		</cfloop>
	</tbody>
	</table>

	<h3>Log Storage</h3>
	<form name="log-configure" class="log-configure" action="?plugin=#req.plugin#&action=#req.action#&pluginAction=updateLogConfig" method="POST">
		<table class="maintbl log-config">
		<thead>
			<tr>
				<th><input type="checkbox" class="logConfigToggle" value="1"></th>
				<th><a class="tooltipMe" href="#thispageaction#&amp;sort=name<cfif req.sort eq 'name' and req.dir neq 'desc'>&amp;dir=desc</cfif>"
					title="#i18n('Orderonthiscolumn')#"<cfif req.sort eq 'name'>
					style="font-weight:bold"</cfif>>#i18n('logfilename')#</a></th>
				<th><a class="tooltipMe" href="#thispageaction#&amp;sort=datelastmodified<cfif req.sort neq 'datelastmodified' or req.dir neq 'desc'>&amp;dir=desc</cfif>"
					title="#i18n('Orderonthiscolumn')#"<cfif req.sort eq 'datelastmodified'>
					style="font-weight:bold"</cfif>>#i18n('logStorage')#</a></th>				
				<th><a class="tooltipMe" href="#thispageaction#&amp;sort=datelastmodified<cfif req.sort neq 'datelastmodified' or req.dir neq 'desc'>&amp;dir=desc</cfif>"
						title="#i18n('Orderonthiscolumn')#"<cfif req.sort eq 'datelastmodified'>
						style="font-weight:bold"</cfif>>#i18n('logStorageLayout')#</a></th>
			</tr>
		</thead>
		<tbody>
			<cfset q =arguments.req.logConfig>
			<cfset datastores={}>
			<cfloop query="q">
				<tr data-logfile="#htmleditformat(q.name)#">
					<td><input type="checkbox" class="logConfig" name="logConfig" value="#htmleditformat(q.name)#"></td>
					<td class="name">
					<cfif structKeyExists(q.appenderArgs,"datasource") or structKeyExists(q.appenderArgs,"path")>
						<a href=#action('overview',"file=#q.name#")#>#name#</a>
					<cfelse>
						#name# (#listLast(q.layoutClass,".")#)
						<p class="log-unsupported">#i18n('unsupportedLogformat')#</p>
					</cfif>
					</td>
					<td>
					<cfif structKeyExists(q.appenderArgs,"datasource")>
						dsn: #q.appenderArgs.datasource#, table: #q.appenderArgs.table#
						<cfset datastores[q.appenderArgs.datasource & ":" & q.appenderArgs.table]={
							datasource: q.appenderArgs.datasource, 
							table: q.appenderArgs.table
						}>
					<cfelseif structKeyExists(q.appenderArgs,"path")> 
						#q.appenderArgs.path#
					</cfif>
					</td>
					<td>#ListLast(q.layoutClass,".")#</td>
				</tr>
			</cfloop>
		</tbody>
		</table>
		
		<fieldset>
			<legend>Bulk Switch Storage</legend>
			<label>
				<input type="radio" class="logStorage" name="logStorage" value="file">
				File
			</label>			
			<cfloop collection=#datastores# item="dsn">
				<cfset ds = datastores[dsn]>			
				<label>
					<input type="radio" class="logStorage" name="logStorage" value="datasource:#ds.datasource#,table:#ds.table#">
					datasource: #ds.datasource#, TABLE:#ds.table#
				</label>
			</cfloop>
			<input type="button" class="button bulkUpdateLogConfig" data-action="bulkUpdateLogConfig" value="#i18n('bulkUpdateLogConfig')#" />
		</fieldset>
		<cfif structCount(datastores) eq 1>
			<p>#i18n('logStorageConfigHint')#</p>
		</cfif>			
	</form>
	<p>
		#i18n('logfilelocation')#: <em>#arguments.req.logfiles.directory#</em>
	</p>

	<div class="csrf-token" data-token="#renderUtils.getCSRF()#">
	#renderUtils.includeJavascript("overview")#
	#renderUtils.includeLang()#
	#renderUtils.includeJavascript("moment-with-locales.min")#
	#renderUtils.includeJavascript("viewlog")#
</cfoutput>
