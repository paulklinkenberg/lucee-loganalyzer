<!--- show a select list of all the web contexts --->
<cfif request.admintype eq "server">
	<cfparam name="url.nextAction" default="overview">	
	<cfparam name="session.loganalyzer.webID" default="serverContext" />	
	<cfset var webContexts = logGateway.getWebContexts() />
	<cfoutput><form action="#action('setContext', '&nextAction=#url.nextAction#')#" method="post"></cfoutput>
		<cfoutput>#i18n('chooseLogLocation')#</cfoutput>
		<select name="webID">
			<cfoutput><option value="serverContext">#i18n('serverContext')#</option></cfoutput>
			<optgroup label="Web contexts">
				<cfoutput query="webContexts">
					<option value="#webContexts.id#"<cfif session.loganalyzer.webID eq webContexts.id> selected</cfif>><cfif len(webContexts.path) gt 68>#rereplace(webContexts.path, "^(.{25}).+(.{40})$", "\1...\2")#<cfelse>#webContexts.path#</cfif> - #webContexts.url#</option>
				</cfoutput>
			</optgroup>
		</select>
		<cfoutput>
			<input type="submit" value="#i18n('Go')#" class="button" />
		</cfoutput>		
	</form>
	<cfif not len(session.loganalyzer.webID)>
		<cfexit method="exittemplate" />
	<cfelse>
		<cfif session.loganalyzer.webID eq "serverContext">
			<cfoutput><h3>#i18n('ServerContextLogFiles')#</h3></cfoutput>
		<cfelse>
			<cfoutput><h3>#i18n('webContext')# <em>#logGateway.getWebRootPathByWebID(session.loganalyzer.webID)#</em></h3></cfoutput>
		</cfif>
	</cfif>
</cfif>
