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
 <cfoutput>
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
	<cfset request.subTitle = "View  #htmleditformat(url.logfile)#">

	<form action="#action('overview')#" method="post">
		<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
		<input class="expand-all button" type="button" value="Expand All"/>
		<input class="reload-logs button" type="button" value="Refresh"/>
		Search: <input type="text" class="search-logs" size="25">
	</form>
</cfoutput>
<cfhtmlbody>
	<script data-src="log-analyzer-plugin">
		$(function(){
			//$("#layout").addClass("layout-fullwidth");
			$(".log").click(function(){
				var data = $(this).data();
				$(".long-log-" + data.log).show();
				if (this.nodeName == "A"){
					$(this).hide();
				} else {
					$(this).find("a.expand-log").hide();
				}
			});
			$(".reload-logs").click(function(){
				document.location.reload();
			});

			$(".expand-all").click(function(){
				$(".collapsed-log").show();
				$("a.expand-log").hide();
			});

			var doSearch = function(){
				var $el = $(".search-logs");
				var str = $.trim($el.val()).toLowerCase();
				if (str.length === 0){
					$(".logs .log.search-hidden").removeClass("search-hidden");
				} else {
					$(".logs .log").each(function(){
						var txt = $(this).text().toLowerCase();
						var match = (txt.indexOf(str) === -1);
						$(this).toggleClass("search-hidden", match);
					});
				}
			};
			var debounceTimer = null;
			$(".search-logs").on("keyup", function(){
				clearTimeout(debounceTimer);
				debounceTimer = setTimeout(doSearch, 250);
			}).on("submit", function(){
				return false;
			});
		});
	</script>
</cfhtmlbody>

<cfset num=0/>
<cfset limit=10/>
<div style="border:1px solid ##999;padding: 5px 0px;" class="longwords logs">
	<cfscript>
		log = getLog(url.file);
		logs = log.logs.reverse();
		//dump (var=#logs#, top=20, keys=20);
	</cfscript>
	<cfsetting enablecfoutputonly="true">
	<cfoutput><pre><b>#log.columns#</b></pre></cfoutput>
	<cfloop array="#logs#" index="line">
		<cfoutput><pre class="log #num mod 2 ? 'odd':''#" data-log="#num#"></cfoutput>
		<cfset r = 1>
		<cfloop array="#line#" index="row">
			<cfif r eq limit>
				<cfoutput><div style="display:none;" class="collapsed-log long-log-#num#"></cfoutput>
			</cfif>
			<cfoutput>#htmleditformat(wrap(row, 150))##chr(13)#</cfoutput>
			<Cfset r++>
		</cfloop>
		<cfif ArrayLen(line) gt limit>
			<cfoutput></div><a class="expand-log" data-log="#num#">Expand Log (#r- limit# more rows)</a></cfoutput>
		</cfif>
		<cfoutput></pre>
</cfoutput>
		<cfset num++ />

	</cfloop>
	<cfsetting enablecfoutputonly="false">
	</pre>
</div>

<!---
<div style="border:1px solid ##999;padding: 5px 0px;" class="longwords">
	<cfsetting enablecfoutputonly="true">
	<cfloop file="#getLogPath(url.file)#" index="line">
		<cfoutput>#htmleditformat(wrap(line, 150))##chr(13)#</cfoutput>
		<!---		--->
		<cfif find('"', right(line, 2))>
			<cfif num gt 0>
				<cfoutput></pre></cfoutput>
			</cfif>
			<cfoutput><pre #num mod 2 ? 'class="odd"':''#></cfoutput>
			<cfset num++ />
		</cfif>
		<!---	--->
	</cfloop>
	<cfsetting enablecfoutputonly="false">
	</pre>
</div>
--->

<cfoutput>
	<form action="#action('overview')#" method="post">
		<input class="submit" type="submit" value="#arguments.lang.Back#" name="mainAction"/>
	</form>
</cfoutput>