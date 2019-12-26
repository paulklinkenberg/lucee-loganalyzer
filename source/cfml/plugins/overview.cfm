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
 
 <cfif structKeyExists(url, "delfile")>
	<cfset var tempFilePath = getLogPath(file=url.delfile) />
	<cftry>
		<cffile action="delete" file="#tempFilePath#" />
		<cflocation url="#cgi.http_referer#">
		<cfoutput><p class="message">#replace(arguments.lang.logfilehasbeendeleted, "%1", listLast(tempFilePath, '/\'))#</p></cfoutput>
		<cfcatch>
			<p class="error">The file could not be deleted; instead we will erase the contents:</p>
			<cffile action="write" file="#tempFilePath#" output="" />
			<cfoutput><p class="message">#replace(arguments.lang.logfilehasbeencleared, "%1", listLast(tempFilePath, '/\'))#</p></cfoutput>
		</cfcatch>
	</cftry>
</cfif>

<cfset thispageaction = rereplace(action('overview'), "^[[:space:]]+", "") />

<!--- show a select list of all the web contexts --->
<cfif request.admintype eq "server">
	<cfparam name="session.loganalyzer.webID" default="serverContext" />
	<cfset var webContexts = getWebContexts() />
	<cfoutput><form action="#thispageaction#" method="post"></cfoutput>
		Choose a log location:
		<select name="webID">
			<option value="serverContext">Server context</option>
			<optgroup label="Web contexts">
				<cfoutput query="webContexts">
					<option value="#webContexts.id#"<cfif session.loganalyzer.webID eq webContexts.id> selected</cfif>><cfif len(webContexts.path) gt 68>#rereplace(webContexts.path, "^(.{25}).+(.{40})$", "\1...\2")#<cfelse>#webContexts.path#</cfif></option>
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

<cfoutput><table class="maintbl">
	<thead>
		<tr>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=name<cfif url.sort eq 'name' and url.dir neq 'desc'>&amp;dir=desc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'name'> style="font-weight:bold"</cfif>>#arguments.lang.logfilename#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=datelastmodified<cfif url.sort neq 'datelastmodified' or url.dir neq 'desc'>&amp;dir=desc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'datelastmodified'> style="font-weight:bold"</cfif>>#arguments.lang.logfiledate#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=size<cfif url.sort neq 'size' or url.dir neq 'desc'>&amp;dir=desc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'size'> style="font-weight:bold"</cfif>>#arguments.lang.logfilesize#</a></th>
			<th>#arguments.lang.actions#</th>
		</tr>
	</thead>
	<cfset frmaction = rereplace(action('list'), "^[[:space:]]+", "") />
	<cfset downloadaction = rereplace(action('download'), "^[[:space:]]+", "") />
	<cfset viewlogaction = rereplace(action('viewlog'), "^[[:space:]]+", "") />

	<tbody>
		<cfloop query="arguments.req.logfiles">
			<tr>
				<td class="tblContent">#name#</td>
				<td class="tblContent"><abbr title="#dateformat(datelastmodified, arguments.lang.dateformat)# #timeformat(datelastmodified, arguments.lang.timeformatshort)#">#getTextTimeSpan(datelastmodified, arguments.lang)#</abbr></td>
				<td class="tblContent"><cfif size lt 1024>#size# #arguments.lang.bytes#<cfelse>#ceiling(size/1024)# #arguments.lang.KB#</cfif></td>
				<td class="tblContent" style="text-align:right; white-space:nowrap; width:1%"><form action="#frmaction#" method="post" style="display:inline;margin:0;padding:0;">
					<input type="hidden" name="logfile" value="#name#" />
					<input type="submit" value="#arguments.lang.details#" class="button" />
					<input type="button" class="button" onclick="self.location.href='#viewlogaction#&amp;file=#name#'" value="#arguments.lang.viewlog#" />
					<input type="button" class="button" onclick="self.location.href='#downloadaction#&amp;file=#name#'" value="#arguments.lang.download#" />
					<input type="button" class="button" onclick="self.location.href='#thispageaction#&amp;delfile=#name#'" value="#arguments.lang.delete#" />
				</form></td>
			</tr>
		</cfloop>
	</tbody>
</table>
<p>#arguments.lang.logfilelocation#: <em>#arguments.req.logfiles.directory#</em></p>
</cfoutput>

