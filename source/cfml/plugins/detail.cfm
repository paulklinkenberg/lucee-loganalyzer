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
 ---><cfoutput>
	<!--- when viewing logs in the server admin, then a webID must be defined --->
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
	
	<cfset stData = deserializeJSON(form.data)>
	<cfset dMin = stData.firstdate />
	<cfset dMax = stData.lastdate />
	
	<!--- to fix any problems with urlencoding etc. for logfile paths, we just use the filename of 'form.logfile'.
	The rest of the path is always recalculated anyway. --->
	<cfset form.logfile = listLast(form.logfile, "/\") />

	<cfset request.subTitle = "Detail from #htmleditformat(form.logfile)#">
	
	<cfset stOccurences = {} />
	<cfloop from="1" to="#arrayLen(stData.dateTime)#" index="i">
		<cfset tempdate = dateFormat(stData.dateTime[i], "yyyy-mm-dd ") & timeformat(stData.dateTime[i], "HH:mm") />
		<cfif not structKeyExists(stOccurences, tempdate)>
			<cfset stOccurences[tempdate] = 1 />
		<cfelse>
			<cfset stOccurences[tempdate]++ />
		</cfif>
	</cfloop>
	
	<cfset qValues = queryNew("date,datedisplay,occurences", "timestamp,varchar,integer") />
	<cfloop collection="#stOccurences#" item="i">
		<cfset queryAddRow(qValues) />
		<cfset querySetCell(qValues, "date", parseDateTime(i)) /> 
		<cfset querySetCell(qValues, "datedisplay", dateformat(parseDateTime(i), arguments.lang.dateformatchart) & timeformat(parseDateTime(i), arguments.lang.timeformatchart)) /> 
		<cfset querySetCell(qValues, "occurences", stOccurences[i]) /> 
	</cfloop>
	<cfquery name="qValues" dbtype="query">
		SELECT *
		FROM qValues
		ORDER BY date
	</cfquery>	
	<form action="#action('list')#" method="post">
		<input type="hidden" name="logfile" value="#form.logfile#" />
		<input class="button submit" type="submit" value="#arguments.lang.Back#" name="mainAction" />
	</form>
	<table class="maintbl">
		<tbody>						
			<tr>
				<th class="row">#arguments.lang.Message#</th>
				<td><h2 class="black">#htmlEditFormat(rereplace(stData.message, "([^[:space:]]{50}.*?[,\.\(\)\{\}\[\]])", "\1 ", "all"))#</h2></td>
			</tr>			
			<tr>
				<th class="row" style="white-space:nowrap">#arguments.lang.Lastoccurence#</th>
				<td>#getTextTimeSpan(dMax, arguments.lang)#: #dateFormat(dMax, arguments.lang.dateformat)# #timeFormat(dMax, arguments.lang.timeformat)#</td>
			</tr>
			<tr>
				<th class="row">#arguments.lang.Threadname#</th>
				<td>#stData.thread#</td>
			</tr>
			<tr>
				<th class="row">#arguments.lang.Type#</th>
				<td>#stData.type#</td>
			</tr>
			<cfif len(trim(stData.file))>
				<tr>
					<th class="row">#arguments.lang.File#</th>
					<td>#stData.file#, #arguments.lang.line# #stData.line#</td>
				</tr>
			</cfif>
			<tr>
				<th class="row" style="vertical-align:top;">#arguments.lang.Occurences#</th>
				<td>#stData.iCount#<!---
					---><cfif stData.iCount gt 1>,
						<cfif dMin eq dMax>#arguments.lang.allinthesameminute#: #DateFormat(dMin, arguments.lang.dateformat)# #TimeFormat(dMin, arguments.lang.timeformatshort)#
						<cfelse>
							#arguments.lang.from# #DateFormat(dMin, arguments.lang.dateformat)# #TimeFormat(dMin, arguments.lang.timeformatshort)# #arguments.lang.untill#
							#DateFormat(dMax, arguments.lang.dateformat)# #TimeFormat(dMax, arguments.lang.timeformatshort)#
							<br /><br />
							<cfset maxOccurences = listFirst(listSort(valueList(qValues.occurences), "numeric", "desc")) />
							<cfset chartMax = ceiling(maxOccurences/8)*8 />
							<cfchart format="png" chartheight="200" chartwidth="500" showygridlines="no" backgroundcolor="##FFFFFF"
							seriesplacement="default" labelformat="number" xaxistitle="#arguments.lang.date#" yaxistitle="#arguments.lang.Occurences#"
							xaxistype="date" yaxistype="scale" sortxaxis="no" scalefrom="0" scaleto="#chartMax#" gridlines="9">
								<cfchartseries type="line" itemcolumn="datedisplay" valuecolumn="occurences" query="qValues" seriescolor="##00F000" markerstyle="circle"></cfchartseries>
							</cfchart>
						</cfif>
					</cfif>
				</td>
			</tr>
			<tr>
				<th class="row">#arguments.lang.Detail#</th>
				<td class="longwords">#replace(rereplace(htmlEditFormat(rereplace(stData.detail, "([^[:space:]]{90}.*?[,\.\(\)\{\}\[\]])", "\1 ", "all")), "\(([^\(\)]+\. ?cf[cm]:[0-9]+)\)", "(<strong style='background-color:##FF3'>\1</strong>)", "all"), chr(10), '<br />', 'all')#</td>
			</tr>
		</tbody>
		<tfoot>
			<tr>
				<td colspan="2">
					<form action="#action('list')#" method="post">
						<input type="hidden" name="logfile" value="#form.logfile#" />
						<input class="button submit" type="submit" value="#arguments.lang.Back#" name="mainAction" />
					</form>
				</td>
			</tr>
		</tfoot>
	</table>
</cfoutput>