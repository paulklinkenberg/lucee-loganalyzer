<cfparam name="url.nextAction" default="overview">
<cfset thispageaction = action('setContext', "&nextAction=#url.nextAction#")/>
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
			<cfoutput><h3>Web context <em>#logGateway.getWebRootPathByWebID(session.loganalyzer.webID)#</em></h3></cfoutput>
		</cfif>
	</cfif>
</cfif>
