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
	/**
	 * read a log file and parse into an array
	 */
    /*
	public struct function getLog(required string file) output=false {
		var line = "";
		var logs = [];
		var row = [];
		var num = 0;
		var columns = "";
		var log = getLogPath(arguments.file);
		var wrapLinesAt = 150;

		loop file="#log#" index="line" {			
			if (num eq 0){
				columns = line;
				num++;
				row = [];
			} else {
				if (len(line) gt wrapLinesAt){ // split super long lines
					ArrayAppend(row, ListToArray( wrap(line, wrapLinesAt),"#chr(13)##chr(10)#"), true);
				} else {
					arrayAppend(row, line);
				}
				if (find('"', right(line, 2))){ // new log row
					arrayAppend(logs, row);
					row = [];
					num++;
				}
			}			
		}
		if (arrayLen(row))
			arrayAppend(logs, row);		
		return {
			"columns": columns,
			"logs": logs
		};
	}
    */

	public void function _readLog(required string logPath, 
            required string logName,
            required string context,
            required query qLog) output=false {
		var line = "";		
		var row = [];
		var num = 0;				
		var javaFile   = createObject("java", "java.io.File").init(logPath);
		var reader = createObject("java", "org.apache.commons.io.input.ReversedLinesFileReader").init(javaFile);
		var maxLogRows = 20000;
		var wrapLinesAt = 300;        
		// reading the log files in reverse
		while (num < maxLogRows) {
			line = reader.readLine();			
            if (isNull(line))
				break; // start of file
			if (len(line) gt wrapLinesAt) // split super long lines
				line =  wrap(line, wrapLinesAt);				
			if (num gt 0 and left(line, 1) eq '"' and line neq '"' ){ // new log row								
				insertLog(qLog, logName, context, line, row.reverse().toList( chr(10) ) );				
				row = [];
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
        required query qLog) output=false {
        _readLog(logPath, logName, context, qLog);                
        return qLog;
    }
    
    public query function createLogQuery(){
        return QueryNew(
            "context, logFile, logDate,  logTimestamp, thread,  severity, log, raw", 
            "varchar, varchar, date, timestamp,    varchar, varchar,  varchar, varchar"
        );
    }

    public any function insertLog(required query q, 
            required string logFile, 
            required string context, 
            required string log,
            required string stack){
        var data = listToArray(arguments.log, ",", true);
        //dump(data);
        for (var d = 1; d lte data.len(); d++)
            data[d] = listFirst(data[d],'""');
        if (data[1] eq "Severity" or data.len() lte 5)    
            return; // header row
        try {
            var row = queryAddRow(q);
            var timestamp = lsparseDateTime(data[3]); // , "MM-DD-yyyy HH:mm:ss"
            var logDate = lsparseDateTime(data[3] & " " & data[4]); // , "MM-DD-yyyy HH:mm:ss"
            querySetCell(q, "logfile", arguments.logFile, row);
            querySetCell(q, "severity", data[1], row);
            querySetCell(q, "thread", data[2], row);
            querySetCell(q, "logTimestamp", timestamp, row);
            querySetCell(q, "logDate", logDate, row);
            querySetCell(q, "log", data[5], row);        
            querySetCell(q, "raw", arguments.log & arguments.stack, row);        
        } catch (e){
            dump(log);
            dump (data);
            dump(e);            
            abort;
        }
        return timestamp;        
    }

	/**
	 * analyze the logfile
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
