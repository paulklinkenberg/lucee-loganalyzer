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
component hint="I parse log files " {

	public void function init() {

	}

	public struct function readDatasource(required struct db,
			required string logName,
			required struct files,
			required string context,
			required query qLog, // pass by reference
			any start=false,
			any end=false,
			required string search) output="true"{

		var fileNames = {};
		arguments.files.each(function(filename){
			if (listLast(filename,".") eq "log")
				fileNames[mid(filename,1,len(filename)-4)]=1;
			else
				fileNames[filename] = 2;
	   });

		if (listLen(arguments.db.table,"; :,") gt 1)			
			throw message = "invalid table name: #arguments.db.table#";
		```
		<cfquery name="local.q_log" datasource="#arguments.db.datasource#" maxrows="1000" result="local.stats">
			SELECT 	pid,id,name,severity,threadid,time,application,message,exception,custom, name logFile
			FROM 	#arguments.db.table#
			WHERE	0=0
					<cfif len(arguments.search)>
						and (message like <cfqueryparam sqltype="varchar" value="%#arguments.search#%">
							or application like <cfqueryparam sqltype="varchar" value="%#arguments.search#%">
							or exception like <cfqueryparam sqltype="varchar" value="%#arguments.search#%">)
					</cfif>
					<cfif arguments.start neq false and arguments.end neq false>
						and time between <cfqueryparam sqltype="date" value="#arguments.start#">	
							and <cfqueryparam sqltype="date" value="#arguments.end#">
					<cfelseif arguments.start neq false>
						and time >= <cfqueryparam sqltype="date" value="#arguments.start#">						
					<cfelseif arguments.end neq false>
						and time >= <cfqueryparam sqltype="date" value="#arguments.end#">
					</cfif>
					<cfif structCount(fileNames)>
						and name in (<cfqueryparam sqltype="varchar" value="#structKeyList(fileNames)#" list="true">)
					</cfif>
			order 	by time desc
		</cfquery>
		```		
		loop query="local.q_log" {
			var entry = queryRowData (local.q_log, local.q_log.currentrow);
			entry.cfStack = "";
			insertLogEntry(arguments.qLog, local.q_log.name & ".log", arguments.context, entry, 0);
		}
		return {
			executionTime: local.stats.executionTime,
			logs: local.q_log.recordcount
		};	
	};

	public struct function readLog(required string logPath,
			required string logName,
			required string context,
			required query qLog, // pass by reference
			any start="",
			any end="",
			required string search,
			//required string singleFile,
			numeric maxStackTrace = 4000,
			numeric maxLines = 50000,
			numeric maxLogs = 5000 ) output="true" {

		var line = "";
		var row = [];
		var timestamp = "";
		var javaFile   = createObject("java", "java.io.File").init(arguments.logPath);
		var reader = createObject("java", "org.apache.commons.io.input.ReversedLinesFileReader").init(javaFile);		
		var stats = structNew("linked");
		stats.logs = 0; // number of logs counted
		stats.lines = 0; // number of lines processed
		stats.search = arguments.search;
		stats.lastDateScanned = "";
		stats.logScanned = 0;
		stats.maxLogs = arguments.maxLogs;
		stats.maxLines = arguments.maxLines;
		stats.maxStackTrace = arguments.maxStackTrace;
		stats.executionTime = getTickCount();
		stats.skipped = [];

		if (arguments.search.len() gt 0){
			stats.maxLogs = 50;
			stats.maxLines = 10000;
		}
		var entry = {
			timeStamp: ""
		};

		// reading the log files in reverse
		try {
			LineLoop: while (stats.logs < stats.maxLogs) {
				line = reader.readLine();
				stats.lines++;
				if (isNull(line)){
					//writeOutput("null");
					break; // start of file
				}
				if (stats.lines > stats.maxLines )
					break;
				if (len(line) gt 0 and left(line, 1) eq '"'){
					// double quotes are escaped, don't get tripped up by weird logs
					if (line neq '"' and left(line,2) neq '""' ){ // new log row
						stats.logScanned++;
						entry = parseLogEntry(log=line, stack=row.reverse().toList( chr(10) ),
							search=arguments.search );
						switch(structCount(entry)){
							case 0:
								continue LineLoop;
							case 1:  // search no match
								continue LineLoop;
							case 6:
								break; // normal
							case 7:
								break; // normal
							default:
								// shouldn't ever get this far
								throw (message="#arguments.logName# entry had #structCount(entry)# items, expected 7",
									detail="#line#");
						}
						var diff = 0;
						if (arguments.start neq false and arguments.end neq false){
							// request for specific date range
							var diff = dateCompare(entry.time, arguments.end,'d');
							if (diff eq 1){
								// log entry is more recent than end date
								row = [];
								stats.skipped = entry.time;
								stats._skipped = diff;
								continue;
							}
							if (dateCompare(entry.time, arguments.start,'d') eq -1)  {
								// log entry is before  start date, stop
								row = [];
								stats.bailed = entry.time;
								break;
							}
						} else if (arguments.start neq false){
							// polling for updated since last fetch
							if (dateCompare(entry.time, arguments.start) eq -1)  {
								row = [];
								break;
							}
						}
						stats.logs++;
						insertLogEntry(arguments.qLog, arguments.logName, arguments.context, entry, stats.maxStackTrace);
						row = [];
					} else {
						arrayAppend(row, line);
					}
					//num++;
				} else {
					arrayAppend(row, line);
				}
			}
		} catch (any){			
			reader.close();
			rethrow;
		}

		//throw message="zac";

		reader.close();
		stats.lastDateScanned = entry.timestamp ?: "";
		stats.executionTime = getTickCount()-stats.executionTime;
		//dump(qLog);		dump(arguments);		dump(stats);		abort;
		return stats;
	}

	private struct function parseLogEntry(required string log, string stack="", required string search){
		if (arguments.log.startsWith('"Severity"'))
			return {}; // header row, ignore it

		var entry = {};
		var str = arguments.log;
		if ( len(arguments.stack) )
			str = str & chr(10) & arguments.stack;
		try {
			// the start of the log entry is very structured, extract the first 5 quoted items
			var header =  REMatch('\A(?:[^\"]*\"){11}', str);
			if (header.len() eq 0)
				throw "Couldn't parse empty header";

			str = mid(str, len(header[1]));
			// get rid of the double quotes
			header = listToArray(Replace(header[1], '"',"","ALL"), ",", true);

			entry.severity = header[1];
			entry.threadid = header[2];
			entry.time = parseDateTime(header[3] & " " & header[4]);
			entry.application = header[5];			
		} catch (any){
			dump(left(str,500));
			dump(header);
			rethrow();
		}
		// now to parse out the error message and stack trace
		var firstTab = find(chr(9), str); // the java stack traces have leading tabs
		if (firstTab gt 0){
			entry.message = mid(str, 1, firstTab);
			entry.exception = mid(str, firstTab);
		} else {
			// exception exception trace
			entry.message = str;
			entry.exception = "";
		}
		if (arguments.search.len() gt 0){
			if ( FindNoCase(arguments.search, entry.message) eq 0 and
				 FindNoCase(arguments.search, entry.exception) eq 0 ){
				return { search: false };
			}
		}
				
		// sanity checking
		/*
		if (entry.exception contains '"ERROR","'
				or entry.message contains '"ERROR","'){
			writeoutput('<pre>#str#</pre>');
			dump (entry);
			dump (local);
			throw text='"ERROR" found in parsed log message</h1>"';
		}
		*/
		return entry;
	}

	public query function createLogQuery(){
		return QueryNew(
			"context, logFile, logDate,  logTimestamp, thread, app,     severity, log,    stack,    cfStack",
			"varchar, varchar, date,     timestamp,    varchar,varchar, varchar,  varchar, varchar, array"
		);
	}

	public array function parseCfmlStack(string str){
		var cfStack = REMatch("(\([\/a-zA-Z\_\-\.\$]*[\.cfc|\.cfm|\.lucee)]\:\d+\))", arguments.str);
		for (var cf = 1; cf <= cfStack.len(); cf++){
			// strip out the wrapping braces
			cfStack[cf] = ListFirst(cfStack[cf],"()");
		}
		// https://regex101.com/r/Fd8qCi/1/
		var logStack = REMatch("(\[[\:\/\\a-zA-Z\_\-\.\$]*\])", arguments.str);
		if (logStack.len() gt 0){
			// de dup
			var ls = StructNew('linked');
			for (var s in logstack)
				ls[listFirst(s,"[]")]="";
			logStack = StructKeyList(ls);
			ArrayAppend(cfStack, logStack, true);
		}
		return cFstack;
	}

	private void function insertLogEntry(required query q,
			required string logFile,
			required string context,
			required struct entry,
			required numeric maxStackTrace){

		var row = queryAddRow(arguments.q);
		try {
			querySetCell(arguments.q, "logfile",      arguments.logFile, row);
			querySetCell(arguments.q, "severity",     arguments.entry.severity, row);
			querySetCell(arguments.q, "app",          arguments.entry.application, row);
			querySetCell(arguments.q, "thread",       arguments.entry.threadid, row);
			querySetCell(arguments.q, "logTimestamp", arguments.entry.time, row);
			//querySetCell(arguments.q, "cfStack", 		arguments.entry.cfStack, row);
			querySetCell(arguments.q, "log",        	arguments.entry.message, row);
			if (arguments.maxStackTrace lt 1){
				querySetCell(arguments.q, "stack",        arguments.entry.exception, row);
			} else {
				if (len(arguments.entry.exception) gt arguments.maxStackTrace ){
					querySetCell(arguments.q, "stack", left(arguments.entry.exception, arguments.maxStackTrace)
						& "#chr(10)# -- very long stack, omitted #(len(arguments.entry.exception)-arguments.maxStackTrace)# bytes" , row);
				} else {
					querySetCell(arguments.q, "stack", arguments.entry.exception, row);
				}

			}
		} catch (any){
			dump(entry);
			rethrow;
		}
	}
}
