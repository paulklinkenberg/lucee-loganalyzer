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
 ---><cfparam name="url.startrow" default="1" type="integer" />
<cfparam name="url.pagesperrow" default="10" type="integer" />
<!--- to fix any problems with urlencoding etc. for logfile paths, we just use the filename of 'form.logfile'.
The rest of the path is always recalculated anyway. --->
<cfset form.logfile = listLast(form.logfile, "/\") />

<cfset maxrows = ArrayLen(req.result.sortOrder) />
<cfset iFrom = url.startrow />
<cfset iTo = Min(url.startrow+url.pagesperrow-1, maxrows) />

<cfset var detailUrl = rereplace(action('detail'), "^[[:space:]]+", "") />
<cfset var thisUrl = rereplace(action('list'), "^[[:space:]]+", "") & "&amp;logfile=#urlEncodedFormat(form.logfile)#" />

<cfif request.admintype eq "server">
	<cfif session.loganalyzer.webID eq "serverContext">
		<cfoutput><h3>Server context log files</h3></cfoutput>
	<cfelse>
		<cfoutput><h3>Web context <em>#getWebRootPathByWebID(session.loganalyzer.webID)#</em></h3></cfoutput>
	</cfif>
</cfif>

<cfoutput>
<h2>#form.logfile#<cfif maxrows gt 0> - #arguments.lang.message# #iFrom# #arguments.lang.to# #iTo# (#maxrows# results<cfif maxrows gt 10>,
	<select name="pagesperrow" onchange="self.location.href='#jsStringFormat(thisUrl)#&pagesperrow='+this.value">
		<cfset var skiprest=false />
		<cfloop list="10,20,30,50,100" index="i"><cfif not skiprest><option value="#i#"<cfif i eq url.pagesperrow> selected="selected"</cfif>>#i#</option></cfif>
			<cfif i gt maxrows><cfset skiprest = true /></cfif>
		</cfloop>
	</select> #arguments.lang.perpage#</cfif>)
</cfif></h2>
<cfset var paging = "" />
<cfsavecontent variable="paging">
	<cfif maxrows gt url.pagesperrow>
		<div class="maincontent" style="text-align:center; padding: 10px">#arguments.lang.Page#
			<cfloop from="1" to="#maxrows#" step="#url.pagesperrow#" index="i">
				<a href="#thisUrl#&amp;sort=#url.sort#&amp;dir=#url.dir#&amp;startrow=#i#"<cfif i eq url.startrow> style="border:1px solid ##ccc;padding:2px 4px;"</cfif>><strong>#ceiling(i/url.pagesperrow)#</strong></a>
				&nbsp;
			</cfloop>
		</div>
	</cfif>
</cfsavecontent>

#paging#
<table class="maintbl">
	<thead>
		<tr>
			<th></th>
			<th><a class="tooltipMe" href="#thisUrl#&amp;pagesperrow=#url.pagesperrow#&amp;sort=msg<cfif url.sort eq 'msg' and url.dir eq 'desc'>&amp;dir=asc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'msg'> style="font-weight:bold"</cfif>>#arguments.lang.Errormessage#</a></th>
			<th><a class="tooltipMe" href="#thisUrl#&amp;pagesperrow=#url.pagesperrow#&amp;sort=date<cfif url.sort eq 'date' and url.sort eq 'desc'>&amp;dir=asc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'date'> style="font-weight:bold"</cfif>>#arguments.lang.Lastoccurence#</a></th>
			<th><a class="tooltipMe" href="#thisUrl#&amp;pagesperrow=#url.pagesperrow#&amp;sort=occurences<cfif url.sort eq 'occurences' and url.sort eq 'desc'>&amp;dir=asc</cfif>" title="#arguments.lang.Orderonthiscolumn#"<cfif url.sort eq 'occurences'> style="font-weight:bold"</cfif>>#arguments.lang.Count#</a></th>
			<th>#arguments.lang.actions#</th>
		</tr>
	</thead>
	<tbody>
		<cfloop from="#iFrom#" to="#iTo#" index="i">
			<cfset el = req.result.sortOrder[i]>
			<tr>
				<td style="width:1px;text-align:right;">#i#&nbsp;</td>
				<td class="tblContent" valign="top">
					&nbsp;#htmlEditFormat(rereplace(req.result.stErrors[el].message, "([^[:space:]]{50}.*?[,\.\(\)\{\}\[\]])", "\1 ", "all"))#
				</td>
				<td class="tblContent" valign="top"><cfset dates = req.result.stErrors[el].datetime />
					<abbr title="#dateFormat(dates[arrayLen(dates)], arguments.lang.dateformat)# #timeFormat(dates[arrayLen(dates)], arguments.lang.timeformat)#">#getTextTimeSpan(dates[arrayLen(dates)], arguments.lang)#</abbr>
				</td>
				<td class="tblContent" valign="top" align="right">
					#req.result.stErrors[el].iCount#&nbsp;&nbsp;&nbsp;
				</td>
				<td class="tblContent"><form action="#detailUrl#" method="post" name="el" style="margin:0;">
					<input type="hidden" name="logfile" value="#form.logfile#">
					<input type="hidden" name="data" value="#htmleditformat(serialize(req.result.stErrors[el]))#">
					<input type="submit" value="#arguments.lang.Details#" class="button" />
				</form></td>
			</tr>
		</cfloop>
		<cfif maxrows eq 0>
			<tr>
				<td></td>
				<td colspan="3" class="tblContent"><span class="CheckError">#arguments.lang.Nologentriesfound#</span></td>
			</tr>
		</cfif>
	</tbody>
</table>
#paging#
<form action="#action('overview')#" method="post">
	<input type="hidden" name="logfile" value="#form.logfile#">
	<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
</form>
</cfoutput>