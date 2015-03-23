<cfcomponent output="no">

	<cffunction name="validate" returntype="void" output="no" hint="called to validate the entered data">
		<cfargument name="error" type="struct" required="yes" />
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="config" type="struct" required="yes" />
		<cfargument name="step" type="numeric" required="yes" />
	</cffunction>


	<cffunction name="update" returntype="string" access="public" output="no" hint="called from Lucee to update application">
		<cfset var sReturn = "" />
		
		<cfreturn install(argumentCollection=arguments) />
<!--- 		<cfsavecontent variable="sReturn"><cfoutput>
			<h3>Updated!</h3>
			<p>The Log anayzer plugin is now updated.</p>
			<p>&nbsp;</p>
		</cfoutput></cfsavecontent>
		<cfreturn sReturn />
--->
	</cffunction>
	
	
	<cffunction name="install" returntype="string" access="public" output="no" hint="called from Lucee to install application">
		<cfargument name="error" type="struct" required="yes" />
		<cfargument name="path" type="string" required="yes" />
		<cfargument name="config" type="struct" required="yes" />
		<cfset var allformdata = config.mixed />
		<cfset var sReturn = "" />
		<cfset var savePath = "" />
		<cfadmin type="#request.admintype#" password="#session['password#request.admintype#']#" action="getPluginDirectory" returnVariable="savePath" />
		<cfset savePath &= server.separator.file & "Log analyzer" & server.separator.file />
		
		<!--- create a new directory for the code files --->
		<cfif not directoryExists(savepath)>
			<cfdirectory action="create" directory="#savepath#" recurse="yes" />
		</cfif>
		
		<!--- save the path in the config, so we can use it when uninstalling --->
		<cfset allformdata.savePath = savePath />
		
		<!--- add the cfc to the lucee root path --->
		<cfzip action="unzip" file="#arguments.path#thecode.zip"
		destination="#savepath#" overwrite="yes" storepath="no" />

		<cfsavecontent variable="sReturn"><cfoutput>
			<h3>Alomost done...</h3>
			<p>The Log anayzer plugin is almost installed.</p>
			<p><a href="?alwaysNew=true" style="font-weight:bold;">Click here</a> to finish the installation</p>
			<p>&nbsp;</p>
		</cfoutput></cfsavecontent>
		<cfreturn sReturn />
	</cffunction>


	<cffunction name="uninstall" returntype="string" output="no" hint="called by Lucee to uninstall the application">
		<cfargument name="path" type="string">
		<cfargument name="config" type="struct">
		<cfset var allformdata = arguments.config.mixed />
		<cfset var errors = [] />
		<!---  remove the files --->
		<cftry>
			<cfdirectory action="delete" directory="#allformdata.savePath#" recurse="yes" />
			<cfcatch>
				<cfset arrayAppend(errors, cfcatch.message & " " & cfcatch.detail) />
			</cfcatch>
		</cftry>
		
		<!--- clear the cached plugin data --->
		<cfset structdelete(application, "plugin", false) />
		<cfset structdelete(application, "pluginlanguage", false) />

		<cfset var ret = "<strong>You have succesfully uninstalled the log analyzer</strong>.<br />
			Was there a problem with the plugin? Then please let me know at <a href='mailto:paul@lucee.nl'>paul@lucee.nl</a>" />
			
		<cfif arrayLen(errors)>
			<cfset ret &= "<br /><br />One or more errors were reported while uninstalling."
				& "<br />The errors:<ul><li>#arrayToList(errors, '</li><li>')#</li></ul>" />
		</cfif>
		<cfreturn ret />
	</cffunction>

</cfcomponent>