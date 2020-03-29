/*
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
 */
component hint="enumerate logs directories and lucee contexts" {

	/**
	 * this function will be called to initialize
	 */
	public void function init() {
		variables.logParser = new LogParser();
		variables.logDirectory = new LogDirectory();
		variables.logConfig = new LogConfig();
	}
	/*
	public struct function analyzeLog(required string file, required string sort, required string sortDir){
		var log = getLogPath(arguments.file);
		return logParser.analyzeLog(log, arguments.sort, arguments.sortDir);
	}
	*/

	public string function getAdminType() {
		return request.admintype;
		/*
		if (request.admintype != "server")
			return "web"
		else 
			return len(session.logViewer.webID) ? "web" : "server";
			*/
	}

	public string function getLogPath(string file="") output=false {
		return variables.logDirectory.getLogPath(arguments.file);
	}


	public query function getWebContexts() output=false {
		return variables.logDirectory.getWebContexts();
	}

	public string function getWebRootPathByWebID(required string webID) output=false {
		return variables.logDirectory.getWebRootPathByWebID(arguments.webID);
	}

	public query function readLog(required string file, any startDate) output=false {
		var log = logDirectory.getLogPath(arguments.file);
		var qLog = logDirectory.logParser.createLogQuery();
		var start = processDate(arguments.startDate);

		logParser.readLog(log, arguments.file, "", qLog, start);
		return qLog;
	}

	public query function listLogs(string sort="name", string dir="asc",
			any startDate="", string filter="", required boolean listOnly="true") output=false {
		// TODO read variables.logConfig.getLogConfig(); 
		return	variables.logDirectory.listLogs(argumentCollection=arguments);
	}

	public struct function getLog(required string adminType, string files, any startDate, any endDate, numeric defaultDays=1,
		required boolean parseLogs, string search="") output="false" {
		var start = variables.logDirectory.processDate(arguments.startDate);
		var end = variables.logDirectory.processDate(arguments.endDate);
		var q_log = variables.logParser.createLogQuery();
		var rows = 0;
		var st_files = {};
		var file_stats = {};
		var timings = [];
		var startTime = getTickCount();
		// TODO need to handle rotated log files
		var q_log_files = variables.logDirectory.listLogs(filter="*.log", listOnly=arguments.parseLogs);
		var firstLogDate = "";

		timings.append({
			name: "list-logs",
			metric: "enumerate",
			data:  getTickCount()-startTime
		});

		if (len(arguments.files) gt 0){
			var _files = listToArray(arguments.files); // avoid crash on single file
			for (var file in _files)
				st_files[file] = true;
		}
		//if (len(arguments.search) gt 0)
		//	defaultDays = 14;
		if (start eq false)
			start = variables.logDirectory.getDefaultstart(q_log_files, st_files, arguments.defaultDays);
		
		// read everything from any configured log datasource	
		var q_log_datasource = variables.logConfig.getLogConfig(adminType=arguments.adminType, file=false); // only datasources
		var st_datasource = [:];
		loop query="q_log_datasource" {
			var _args = q_log_datasource.appenderArgs;
			_args.key = "datasource:" &_args.datasource & "." & _args.table;
			st_datasource[_args.key] =_args;
		}

		for (local.key in st_datasource){
			local.db = st_datasource[local.key];
			if (arguments.parseLogs){
				file_stats[local.db.key] = variables.logParser.readDatasource(db=local.db,
					logName=local.db.key, files=st_files,
					context="", qLog=q_log, 
					start=start, end=end, 
					search=arguments.search);
				// need to split the datasource file into logs
				local.datasourceLogs = {};
				loop query="local.q_log" {
					if (not structKeyExists(local.datasourceLogs, local.q_log.logfile))
						local.datasourceLogs[local.q_log.logfile] = 0;
					local.datasourceLogs[local.q_log.logfile]++;
				}
				for (local.dsLog in local.datasourceLogs){
					local.r = queryAddRow(local.q_log_files);
					querySetCell(local.q_log_files, "name", local.dsLog, local.r);
					querySetCell(local.q_log_files, "size", local.datasourceLogs[local.dsLog], local.r);
					querySetCell(local.q_log_files, "processed", true, local.r);
					querySetCell(local.q_log_files, "supportedFormat", true, local.r);
					querySetCell(local.q_log_files, "dateLastModified", local.q_log.logTimestamp[1], local.r);
					querySetCell(local.q_log_files, "created", local.q_log.logTimestamp[local.q_log.recordcount], local.r);
				}
				timings.append({
					name: local.db.key,
					metric: "select",
					data:  file_stats[local.db.key].executionTime
				});				
			}
			rows = q_log.recordcount;
		}	
		//dump (q_log_files); abort;

		loop query="q_log_files" {
			if (q_log_files.processed eq true)
				continue; // log datasource
			if (firstLogDate eq "")
				firstLogDate = q_log_files.created;
			else if (DateCompare(firstLogDate, q_log_files.created) eq 1 )
				firstLogDate= q_log_files.created;

			if (start neq false){
				if (dateCompare(q_log_files.dateLastModified, start) eq -1)
					continue; // log file hasn't been updated start last request
			}
			if (structCount(st_files) gt 0
					and not structKeyExists(st_files, q_log_files.name))
				continue; // this file wasn't requested
			if (arguments.parseLogs){
				file_stats[q_log_files.name] = variables.logParser.readLog(logPath=variables.logDirectory.getLogPath(q_log_files.name),
					logName=q_log_files.name, context="", qLog=q_log, start=start, end=end, search=arguments.search);
				timings.append({
					name: q_log_files.name,
					metric: "parse",
					data:  file_stats[q_log_files.name].executionTime
				});
				// TODO cache file timings use them to avoid searching files which don't contain the search string
			}
			rows = q_log.recordcount;
		}		

		QueryDeleteColumn( q_log_files, "TYPE");
		QueryDeleteColumn( q_log_files, "ATTRIBUTES");
		QueryDeleteColumn( q_log_files, "MODE");
		QueryDeleteColumn( q_log_files, "PROCESSED");

		// merge log files with datasources
		```
		<cfquery name="q_log_files"dbtype="query">
			select 	name, sum(size) size, max(dateLastModified) dateLastModified, 
					min(created) created, min(supportedFormat) supportedFormat
			from 	q_log_files
			group by name
		</cfquery>
		```

		QuerySort( q_log, "logTimestamp", "desc");
		if (q_log.recordcount gt 500) // only show the last 500 rows
			q_log = QuerySlice(q_log, 1, min(500, q_log.recordcount ));

		// extract out all the cfml source paths, far more interesting at a glance for cfml developers
		loop query="q_log"	{
			QuerySetCell(q_log, "cfstack", 
				variables.logParser.parseCfmlStack(q_log.log & " " & q_log.stack), 
				q_log.currentrow
			);			
		}

		//cflog(text="finished getLogs: #arguments.files# in #getTickCount()-startTimeLog#ms");
		// sort the logs from multiple sources by timestamp
		return {
			firstLogDate: DateFormat(firstLogDate,"yyyy-mm-dd"),
			start: start,
			search: arguments.search,
			timings: timings,
			stats: file_stats,
			q_log: q_log,
			q_log_files: q_log_files,
			totalTime:  getTickCount()-startTime
		};
	};

	}
