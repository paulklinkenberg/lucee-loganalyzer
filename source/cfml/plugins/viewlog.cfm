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

	<!--- to fix any problems with urlencoding etc. for logfile paths, we just use the filename of 'form.logfile'.
	The rest of the path is always recalculated anyway. --->
	<cfset url.logfile = listLast(url.file, "/\") />

	<cfhtmlhead text='<style type="text/css">pre div { padding: 2px 5px; background-color:##eee} pre .odd { background-color:##D2E0EE}</style>' />

	<h3>View #url.file#</h3>

	<form action="#action('overview')#" method="post">
		<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
	</form>

	<cfset num=0/>
	<pre style="border:1px solid ##999;padding: 5px 0px;" class="longwords"><cfloop file="#getLogPath(url.file)#" index="line"><!---
		---><div#num mod 2 ? ' class="odd"':''#>#htmleditformat(line)##server.separator.line#</div><!---
		---><cfif find('"', right(line, 2))><cfset num++ /></cfif><!---
	---></cfloop></pre>

	<form action="#action('overview')#" method="post">
		<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
	</form>
</cfoutput>