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

	public void function _readLog(required string logPath,
			required string logName,
			required string context,
			required query qLog,
			any since="") output=false {
		var line = "";
		var row = [];
		var timestamp = "";
		var num = 0;
		var javaFile   = createObject("java", "java.io.File").init(logPath);
		var reader = createObject("java", "org.apache.commons.io.input.ReversedLinesFileReader").init(javaFile);
		var maxLogRows = 20000;
		var wrapLinesAt = 300;
		// reading the log files in reverse

		if (arguments.since eq "")
			arguments.since = false;
		else if (not isDate(arguments.since))
			throw text="bad since date: " & since;

		LineLoop: while (num < maxLogRows) {
			line = reader.readLine();
			if (isNull(line))
				break; // start of file
			if (len(line) gt wrapLinesAt) // split super long lines
				line =  wrap(line, wrapLinesAt);
			if (len(line) gt 0 and left(line, 1) eq '"'){
				// double quotes are escaped, don't get tripped up by wierd logs
				if (line neq '"' and left(line,2) neq '""' ){ // new log row
					var entry = parseLogEntry(line, row.reverse().toList( chr(10) ) );
					switch(structCount(entry)){
						case 0:
							break LineLoop;
						case 7:
							break; // normal
						default:
							dump (entry);
							abort;
					}

					if (arguments.since){
						if (dateCompare(entry.timeStamp, arguments.since) eq -1)  {
							break;
						}
					}
					insertLogEntry(qLog, logName, context, entry);
					row = [];
				} else {
					arrayAppend(row, line);
				}
				//num++;
			} else {
				arrayAppend(row, line);
			}
			num++;
		}
		reader.close();
	}

	public query function readLog(required string logPath,
			required string logName,
			required string context,
			required query qLog
			date since) output=false {
		_readLog(logPath, logName, context, qLog, since);
		return qLog;
	}

	public struct function parseLogEntry(required string log, string stack=""){
		// make some assumptions here, the stack traces are all embeded
		if (arguments.log.startsWith('"Severity"'))
			return {}; // header row
		var entry = {};
		var str = arguments.log;
		if ( len(arguments.stack) )
			str = str & chr(10) & arguments.stack;
		var header =  REMatch('(?:[^\"]*\"){11}', str);
		str = mid(str, len(header[1]));
		// get rid of the double quotes
		header = listToArray(Replace(header[1], '"',"","ALL"), ",", true);
		try {
			entry.severity = header[1];
			entry.thread = header[2];
			entry.timestamp = lsparseDateTime(header[3] & " " & header[4]);
			entry.app = header[5];
			entry.cfstack = REMatch("\(([\/a-zA-Z\_]*\.(cfc|cfm|lucee)\:\d*\))", str);
			for (var cf = 1; cf <= entry.cfstack.len(); cf++)
				entry.cfstack[cf] = ListFirst(entry.cfstack[cf],"()");
		} catch (any){
			dump(header);
			dump(cfcatch);
			abort;
		}
		// now to parse out the error message and stack trace
		var firstTab = find(chr(9), str); // stack traces have leading tabs
		if (firstTab gt 0){
			entry.log = mid(str,1,firstTab);
			entry.stack = mid(str,firstTab);
		} else {
			// no stack stace
			entry.log = str;
			entry.stack = "";
		}

		if (entry.stack contains '"ERROR","'
				or entry.log contains '"ERROR","'){
			writeoutput('"<h1>"ERROR" in log message</h1><pre>#str#</pre>');
			dump (entry);
			dump (local);
			abort;
		}
		return entry;
	}

	public query function createLogQuery(){
		return QueryNew(
			"context, logFile, logDate,  logTimestamp, thread, app,     severity, log,    stack,    cfstack",
			"varchar, varchar, date,     timestamp,    varchar,varchar, varchar,  varchar, varchar, array"
		);
	}

	public void function insertLogEntry(required query q,
			required string logFile,
			required string context,
			required struct entry){

		var row = queryAddRow(q);
		try {
			querySetCell(q, "logfile",      arguments.logFile, row);
			querySetCell(q, "severity",     entry.severity, row);
			querySetCell(q, "app",          entry.app, row);
			querySetCell(q, "thread",       entry.thread, row);
			querySetCell(q, "logTimestamp", entry.timestamp, row);
			querySetCell(q, "cfstack", entry.cfstack, row);
			querySetCell(q, "log",        entry.log, row);
			querySetCell(q, "stack",        entry.stack, row);
		} catch (any){
			dump(entry);
			dump(cfcatch);
			abort;
		}

	}

	/**
	 * analyze the logfile, old style
	 */
	public struct function analyzeLog(required string logFile, string sort, string sortDir) output=false {
		var stErrors = {};
		var sLine    = "";
		var aDump    = [];
		var sTmp     = "";
		var st       = [];
		var aTmp	 = "";
		var result = {};

		loop file="#logfile#" index="sLine" {
			<!--- If line starts with a quote, then it is either an error line, or the end of a dump--->
			if (left(sLine, 1) == '"') {
				//if not a new error
				if (not refind('^"[A-Z-]+","', sLine)) {
					if (isDefined("aDump") and ArrayLen(aDump) > 1) {
						if (isStruct(aDump[6])) {
							aDump[6].detail &= Chr(13) & Chr(10) & sLine;
						} else {
							sTmp = aDump[6];
							aDump[6] = structNew();
							aDump[6].error = sTmp;
							aDump[6].detail = sLine;
							aDump[6].fileName = "";
							aDump[6].lineNo = "";
							sTmp = "";
						}
					}
				//new error
				} else {
					aTmp = ListToArray(rereplace(rereplace(trim(sLine), '(^"|"$)', '', 'all'), '",("|$)', chr(10), "all"), chr(10), true);
					//was there a previous error
					if (ArrayLen(aDump) == 6) {
						__addError(aDump, stErrors);
					}
					//create new error container
					aDump = aTmp;
					sTmp = aDump[6];
					//in some cases, there == no message text on the first line of the error output.
					WriteOutput('This seems to have to do with customly thrown errors, where message="". ');
					if (sTmp == "") {
						sTmp = "no error msg #structCount(stErrors)#";
					}
					aDump[6] = structNew();
					aDump[6].error = sTmp;
					aDump[6].detail = sLine;
					aDump[6].fileName = "";
					aDump[6].lineNo = 0;
					sTmp = "";
				}
		 	   //within a dump output
			} else {
				if (isDefined("aDump") and ArrayLen(aDump) > 1){
					if (isStruct(aDump[6])) {
						aDump[6].detail &= Chr(13) & Chr(10) & sLine;
					} else {
						sTmp = aDump[6];
						aDump[6] = structNew();
						aDump[6].error = sTmp;
						aDump[6].detail = sLine;
						aDump[6].fileName = "";
						aDump[6].lineNo = 0;
						sTmp = "";
					}
				}
			}
		}

		//  add the last error
		if ( ArrayLen(aDump) == 6 ) {
			__addError(aDump, stErrors);
		}
		//  orderby can change
		if ( arguments.sort == "msg" ) {
			st = structSort(stErrors, "textnocase", arguments.sortDir, "message");
		} else if ( arguments.sort == "date" ) {
			st = structSort(stErrors, "textnocase", arguments.sortDir, "lastdate");
		} else {
			st = structSort(stErrors, "numeric", arguments.sortDir, "icount");
		}
		result.sortOrder = st;
		result.stErrors  = stErrors;

		return result;
	}

	public void function __addError(array aDump, struct stErrors) output=false {
		try {
			//  	at test_cfm$cf.call(/developing/tools/test.cfm:1):1
			var aLine = REFind("\(([^\(\)]+\.cfm):([0-9]+)\)", aDump[6].detail, 1, true);
			if ( aLine.pos[1] > 0 ) {
				aDump[6].fileName = Mid(aDump[6].detail, aLine.pos[2], aLine.len[2]);
				aDump[6].lineNo   = Mid(aDump[6].detail, aLine.pos[3], aLine.len[3]);
			}
			var sHash = Hash(aDump[6].error);
			var tempdate = parsedatetime(aDump[3] & " " & aDump[4]);
			if ( structKeyExists(stErrors, sHash) ) {
				stErrors[sHash].iCount++;
				ArrayAppend(stErrors[sHash].datetime, tempdate);
				stErrors[sHash].lastdate = tempdate;
			} else {
				stErrors[sHash] = {
					"message":aDump[6].error,
					"detail":aDump[6].detail,
					"file":aDump[6].fileName,
					"line":aDump[6].lineNo,
					"type":aDump[1],
					"thread":aDump[2],
					"datetime":[tempdate],
					"iCount":1
					, "firstdate": tempdate
					, "lastdate": tempdate
				};
			}
		} catch (any cfcatch) {
		}
	}
}
