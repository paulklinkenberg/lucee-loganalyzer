component hint="update log configuration" {
	public void function init() {
    }    

    public query function getLogConfig(required string adminType, boolean file=true, boolean datasource=true) output="false" {
		admin 
        	action="getLogSettings" 
        	type="#arguments.adminType#"
        	password="#session["password"&arguments.adminType]#"        
        	returnVariable="local.logConfig"
            remoteClients="#request.getRemoteClients()#";
        var opts = arguments;
        if (!arguments.file || ! arguments.datasource){
            return local.logConfig.filter(function(row){
                var isDatasource = structKeyExists(arguments.row.appenderArgs,"datasource");
                if (opts.datasource and isDatasource)
                    return true;
                if (opts.file and not isDatasource)
                    return true;
                return false;
            });
        } else {
            return local.logConfig;
        }
    }	

	public string function updateLogConfig(required string adminType, string logConfig, string logStorage) output="false" {
		local.existinglogConfig = getLogConfig(arguments.adminType);
		var _logConfig = {};
		ListToArray(arguments.logConfig).each(function(v){
			_logConfig[v]=true;
		});
		if (logStorage eq "file"){
			var _log = {
				charset	: "windows-1252",
				maxfiles: "10",
				maxfilesize: "10485760",
				path: "{lucee-config}/logs",
				timeout :"60"
			}
			var _java = {				
				layoutClass: "lucee.commons.io.log.log4j.layout.ClassicLayout",
				appenderClass: "lucee.commons.io.log.log4j.appender.RollingResourceAppender"
			};
			//if ( request.admintype != "server")
			//	_log.path = "{lucee-config}/logs";
			loop query="#local.existinglogConfig#"  {
				if (StructKeyExists(_logconfig, local.existinglogConfig.name)){					
					var _logSettings = duplicate(_log);
					_logSettings.path = _log.path & "/" & local.existinglogConfig.name & ".log";
					updateLogSetting(local.existinglogConfig.name, _logSettings, _java,
						QueryRowData(local.existinglogConfig, local.existinglogConfig.currentrow)
					);
				}				
			}
		} else {
			var _datasource = {
				custom: nullValue(),	
				datasource: "",
				password: nullValue(),
				table: "",
				username: nullValue()
			}
			var _java = {
				layoutClass: "lucee.commons.io.log.log4j.layout.DatasourceLayout",
				appenderClass: "lucee.commons.io.log.log4j.appender.DatasourceAppender"
			};	
			// datastore storage			
			listToArray(arguments.logStorage).each( 
				function(v){					
					switch (listFirst(arguments.v,":")){
						case "datasource":
							_datasource.datasource = listLast(arguments.v,":");
							break;
						case "table":
							_datasource.table = listLast(arguments.v,":");
							break;
						default:
							throw ="message: #listLast(arguments.v,":")# not supported";
					}
					
				}
			);
			if  (_datasource.datasource eq "" || _datasource.table eq "")
				throw message="bad storage config: #arguments.logstorage# #serializeJSON(_datasource)# #serializeJSON(listToArray(arguments.logStorage))#" ;

			loop query="#local.existinglogConfig#"  {
				if (StructKeyExists(_logconfig, local.existinglogConfig.name)){					
					updateLogSetting(local.existinglogConfig.name, _datasource, _java,
						QueryRowData(local.existinglogConfig, local.existinglogConfig.currentrow)
					);
				}				
			}
				
		}	
		return "Log files updated";
	}

	public void function updateLogSetting (string name, struct appenderArgs, struct java, struct current){
		admin
			action="updateLogSettings"
			type="#request.adminType#"
			password="#session["password"&request.adminType]#"
			name="#trim(arguments.name)#"
			level="#current.level#" // keep the same
			appenderClass="#trim(java.appenderClass)#"
			appenderBundleName=""
			appenderBundleVersion=""
			appenderArgs="#arguments.appenderArgs#"
			layoutClass="#arguments.java.layoutClass#"
			layoutBundleName=""
			layoutBundleVersion=""
			layoutArgs={};
		cflog(text="LogViewer.updateLogSettings #name#");
	};
}
