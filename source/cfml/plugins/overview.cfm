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
<cfparam name="url.file" default="">
<cfset thispageaction = rereplace(action('overview'), "^[[:space:]]+", "") />

<!--- show a select list of all the web contexts --->
<cfif request.admintype eq "server">
	<cfparam name="session.loganalyzer.webID" default="serverContext" />
	<cfset var webContexts = logGateway.getWebContexts() />
	<cfoutput><form action="#thispageaction#" method="post"></cfoutput>
		Choose a log location:
		<select name="webID">
			<option value="serverContext">Server context</option>
			<optgroup label="Web contexts">
				<cfoutput query="webContexts">
					<option value="#webContexts.id#"<cfif session.loganalyzer.webID eq webContexts.id> selected</cfif>><cfif len(webContexts.path) gt 68>#rereplace(webContexts.path, "^(.{25}).+(.{40})$", "\1...\2")#<cfelse>#webContexts.path#</cfif> - #webContexts.url#</option>
				</cfoutput>
			</optgroup>
		</select>
		<input type="submit" value="go" class="button" />
	</form>
	<cfif not len(session.loganalyzer.webID)>
		<cfexit method="exittemplate" />
	<cfelse>
		<cfif session.loganalyzer.webID eq "serverContext">
			<cfoutput><h3>Server context log files</h3></cfoutput>
		<cfelse>
			<cfoutput><h3>Web context <em>#getWebRootPathByWebID(session.loganalyzer.webID)#</em></h3></cfoutput>
		</cfif>
	</cfif>
</cfif>

<cfoutput>
	<table class="maintbl log-overview">
	<thead>
		<tr>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=name<cfif url.sort eq 'name' and url.dir neq 'desc'>&amp;dir=desc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'name'> style="font-weight:bold"</cfif>>#arguments.lang.logfilename#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=datelastmodified<cfif url.sort neq 'datelastmodified' or url.dir neq 'desc'>&amp;dir=desc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'datelastmodified'> style="font-weight:bold"</cfif>>#arguments.lang.logfiledate#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=size<cfif url.sort neq 'size' or url.dir neq 'desc'>&amp;dir=desc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'size'> style="font-weight:bold"</cfif>>#arguments.lang.logfilesize#</a></th>
			<th>#arguments.lang.actions#</th>
		</tr>
	</thead>
	<tbody>
		<cfloop query="arguments.req.logfiles">
			<tr data-logfile="#htmleditformat(name)#">
				<td class="tblContent">#name#</td>
				<td class="tblContent"><abbr title="#dateformat(datelastmodified, arguments.lang.dateformat)# #timeformat(datelastmodified, arguments.lang.timeformatshort)#">#getTextTimeSpan(datelastmodified, arguments.lang)#</abbr></td>
				<td class="tblContent"><cfif size lt 1024>#size# #arguments.lang.bytes#<cfelse>#ceiling(size/1024)# #arguments.lang.KB#</cfif></td>
				<td class="tblContent" style="text-align:right; white-space:nowrap; width:1%">	
				<input type="submit" class="button" data-action="list" value="#arguments.lang.analyse#"/>
				<input type="button" class="button" data-action="viewLog" value="#arguments.lang.viewlog#" />
				<input type="button" class="button" data-action="download"value="#arguments.lang.download#" />
				<input type="button" class="button" data-action="delete" value="#arguments.lang.delete#" />
				</td>
			</tr>
		</cfloop>
	</tbody>
	</table>
	<p>#arguments.lang.logfilelocation#: <em>#arguments.req.logfiles.directory#</em></p>
	<div class="csrf-token" data-token="#getCSRF()#">
	#includeJavascript("overview")#
</cfoutput>	


