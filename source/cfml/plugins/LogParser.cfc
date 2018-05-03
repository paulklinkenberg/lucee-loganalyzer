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
/**
 * I contain the main functions for the log Analyzer plugin
 */
component hint="I parse log files " {

	public void function init() {
	}

	public struct function readLog(required string logPath,
			required string logName,
			required string context,
			required query qLog, // pass by reference
			any start="",
			required string search,
			//required string singleFile,
			numeric maxStackTrace = 4000,
			numeric maxLines = 1000,
			numeric maxLogs = 1000 ) output=false {

		var line = "";
		var row = [];
		var timestamp = "";
		var javaFile   = createObject("java", "java.io.File").init(logPath);
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
					writeOutput("null");
					break; // start of file
				}
				if (stats.lines > stats.maxLines )
					break;
				if (len(line) gt 0 and left(line, 1) eq '"'){
					// double quotes are escaped, don't get tripped up by wierd logs
					if (line neq '"' and left(line,2) neq '""' ){ // new log row
						stats.logScanned++
						entry = parseLogEntry(log=line, stack=row.reverse().toList( chr(10) ),
							search=arguments.search );
						switch(structCount(entry)){
							case 0:
								continue LineLoop;
							case 1:  // search no match
								continue LineLoop;
							case 7:
								break; // normal
							default:
								dump (entry); // shouldn't ever get this far
								throw (text="entry had #structCount(entry)# items, expected 7");
						}
						if (arguments.start neq false){
							if (dateCompare(entry.timeStamp, arguments.start) eq -1)  {
								row = [];
								break;
							}
						}
						stats.logs++;
						insertLogEntry(qLog, logName, context, entry, stats.maxStackTrace);
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
			dump(cfcatch);
			abort;
		}
		reader.close();
		stats.lastDateScanned = entry.timestamp ?: "";
		stats.executionTime = getTickCount()-stats.executionTime;
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
				throw "couldn't parse header";

			str = mid(str, len(header[1]));
			// get rid of the double quotes
			header = listToArray(Replace(header[1], '"',"","ALL"), ",", true);

			entry.severity = header[1];
			entry.thread = header[2];
			entry.timestamp = parseDateTime(header[3] & " " & header[4]);
			entry.app = header[5];
			// extract out all the cfml source paths, far more interesting at a glance for cfml developers
			entry.cfstack = REMatch("(\([\/a-zA-Z\_\-\.\$]*[\.cfc|\.cfm|\.lucee)]\:\d+\))", str);
			for (var cf = 1; cf <= entry.cfstack.len(); cf++){
				// strip out the wrapping braces
				entry.cfstack[cf] = ListFirst(entry.cfstack[cf],"()");
			}
		} catch (any){
			dump(left(str,500));
			dump(header);
			rethrow();
		}
		// now to parse out the error message and stack trace
		var firstTab = find(chr(9), str); // the java stack traces have leading tabs
		if (firstTab gt 0){
			entry.log = mid(str, 1, firstTab);
			entry.stack = mid(str, firstTab);
		} else {
			// no stack strace
			entry.log = str;
			entry.stack = "";
		}
		if (arguments.search.len() gt 0){
			if ( FindNoCase(arguments.search, entry.log) eq 0 and
				 FindNoCase(arguments.search, entry.stack) eq 0 ){
				return { search: false };
			}
		}

		// https://regex101.com/r/Fd8qCi/1/
		var logStack = REMatch("(\[[\:\/\\a-zA-Z\_\-\.\$]*\])", entry.log);
		if (logStack.len() gt 0){
			// de dup
			var ls = StructNew('linked');
			for (var s in logstack)
				ls[listFirst(s,"[]")]="";
			logStack = StructKeyList(ls);
			ArrayAppend(entry.cfstack, logStack, true);
		}

		// sanity checking
		if (entry.stack contains '"ERROR","'
				or entry.log contains '"ERROR","'){
			writeoutput('<pre>#str#</pre>');
			dump (entry);
			dump (local);
			throw text='"ERROR" found in parsed log message</h1>"';
		}
		return entry;
	}

	public query function createLogQuery(){
		return QueryNew(
			"context, logFile, logDate,  logTimestamp, thread, app,     severity, log,    stack,    cfstack",
			"varchar, varchar, date,     timestamp,    varchar,varchar, varchar,  varchar, varchar, array"
		);
	}

	private void function insertLogEntry(required query q,
			required string logFile,
			required string context,
			required struct entry,
			required numeric maxStackTrace){

		var row = queryAddRow(q);
		try {
			querySetCell(q, "logfile",      arguments.logFile, row);
			querySetCell(q, "severity",     entry.severity, row);
			querySetCell(q, "app",          entry.app, row);
			querySetCell(q, "thread",       entry.thread, row);
			querySetCell(q, "logTimestamp", entry.timestamp, row);
			querySetCell(q, "cfstack", 		entry.cfstack, row);
			querySetCell(q, "log",        	entry.log, row);
			if (arguments.maxStackTrace lt 1){
				querySetCell(q, "stack",        entry.stack, row);
			} else {
				if (len(entry.stack) gt arguments.maxStackTrace ){
					querySetCell(q, "stack", left(entry.stack, arguments.maxStackTrace)
						& "#chr(10)# -- very long stack, omitted #(len(entry.stack)-arguments.maxStackTrace)# bytes" , row);
				} else {
					querySetCell(q, "stack", entry.stack, row);
				}

			}
		} catch (any){
			dump(entry);
			rethrow;
		}
	}
}
