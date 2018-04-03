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
	<cfset url.nextAction="admin">
	<cfinclude  template="contextSelector.cfm">
</cfif>
<cfoutput>
	<table class="maintbl log-overview">
	<thead>
		<tr>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=name<cfif url.sort eq 'name' and url.dir neq 'desc'>&amp;dir=desc</cfif>" 
				title="#i18n('Orderonthiscolumn')#"<cfif url.sort eq 'name'> 
				style="font-weight:bold"</cfif>>#i18n('logfilename')#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=datelastmodified<cfif url.sort neq 'datelastmodified' or url.dir neq 'desc'>&amp;dir=desc</cfif>" 
				title="#i18n('Orderonthiscolumn')#"<cfif url.sort eq 'datelastmodified'> 
				style="font-weight:bold"</cfif>>#i18n('logfiledate')#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=created<cfif url.sort neq 'created' or url.dir neq 'desc'>&amp;	dir=desc</cfif>" 	
				title="#i18n('Orderonthiscolumn')#" <cfif url.sort eq 'created'> 
				style="font-weight:bold"</cfif>>#i18n('logfilecreated')#</a></th>
			<th><a class="tooltipMe" href="#thispageaction#&amp;sort=size<cfif url.sort neq 'size' or url.dir neq 'desc'>&amp;dir=desc</cfif>" 
				title="#i18n('Orderonthiscolumn')#"<cfif url.sort eq 'size'> 
				style="font-weight:bold"</cfif>>#i18n('logfilesize')#</a></th>
			<th>#i18n('actions')#</th>
		</tr>
	</thead>
	<tbody>
		<cfset q =arguments.req.logfiles>
		<cfloop query="q">
			<tr data-logfile="#htmleditformat(q.name)#">
				<td class="name"><a href=#action('overview',"file=#q.name#")#>#name#</a></td>
				<td><abbr title="#dateformat(q.datelastmodified, i18n('dateformat'))# #timeformat(q.datelastmodified, i18n('timeformatshort'))#">			
					#renderUtils.getTextTimeSpan(q.datelastmodified)#</abbr></td>
				<td><abbr title="#dateformat(q.created, i18n('dateformat'))# #timeformat(q.created, i18n('timeformatshort'))#">
					#renderUtils.getTextTimeSpan(q.created)#</abbr></td>
				<td><cfif q.size lt 1024>#size# #i18n('bytes')#<cfelse>#ceiling(q.size/1024)# #i18n('KB')#</cfif></td>
				<td style="text-align:right; white-space:nowrap; width:1%">
					<!--<input type="submit" class="button" data-action="list" value="#i18n('analyse')#"/>-->
					<input type="button" class="button" data-action="overview" value="#i18n('viewlog')#" />
					<input type="button" class="button" data-action="download"value="#i18n('download')#" />
					<input type="button" class="button" data-action="delete" value="#i18n('delete')#" />
				</td>
			</tr>
		</cfloop>
	</tbody>
	</table>
	<p>#i18n('logfilelocation')#: <em>#arguments.req.logfiles.directory#</em></p>
	<div class="csrf-token" data-token="#renderUtils.getCSRF()#">
	#renderUtils.includeJavascript("overview")#
</cfoutput>
