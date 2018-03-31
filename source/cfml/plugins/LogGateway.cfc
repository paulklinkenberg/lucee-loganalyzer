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
component hint="I enumerate logs and contexts" {

	/**
	 * this function will be called to initalize
	 */
	public void function init() {
		variables.logParser = new LogParser();
	}		
	
	public query function getWebContexts(boolean fromCache="true") output=false {
		var qWebContexts = "";
		if ( !structKeyExists(variables, "qWebContexts") || !arguments.fromCache ) {
			//  get all web contexts 
			var admin = new Administrator( "server", password );
			qWebContexts = admin.getContextes();

			QuerySort( qWebContexts, "path", "desc");
			variables.qWebContexts = qWebContexts;
		}
		return variables.qWebContexts;
	}

	/**
	 * This function returns the full log file path, and does some security checking
	 */
	public string function getLogPath(string file="") output=false {
		if ( request.admintype == "web" ) {
			var logDir = expandPath("{lucee-web}/logs/");
		} else if ( session.logAnalyzer.webID == "serverContext" ) {
			var logDir = expandPath("{lucee-server}/logs/");
		} else {
			var logDir = getLogPathByWebID(session.logAnalyzer.webID);
		}
		if ( structKeyExists(arguments, "file") && len(arguments.file) ) {
			logDir = rereplace(logDir, "\#server.separator.file#$", "") & server.separator.file & listLast(arguments.file, "/\");
			if ( !fileExists(logDir) ) {
				throw( message="log file '#logDir#' does not exist!" );
			}
		}
		return logDir;
	}

	/**
	 * I return the path to the log directory for a given web context
	 */
	public string function getLogPathByWebID(required string webID) output=false {
		if ( request.admintype == "web" ) {
			throw( message="Function getLogPathByWebID() may only be used in the server admin!" );
		}
		var cacheKey = "webContextLogPaths";
		if ( !structKeyExists(variables, cacheKey) ) {
			var webContexts = getWebContexts();
			var tmp = {};
			loop query="webContexts" {
				tmp[webContexts.id] = rereplace(webContexts.config_file, "[^/\\]+$", "") & "logs" & server.separator.file;
			}
			variables[cacheKey] = tmp;
		}
		return variables[cacheKey][arguments.webID];
	}

	/**
	 * I return the path to the webroot for a given web context
	 */
	public string function getWebRootPathByWebID(required string webID) output=false {
		if ( request.admintype == "web" ) {
			throw( message="Function getWebRootPathByWebID() may only be used in the server admin!" );
		}
		var cacheKey = "webrootPaths";
		if ( !structKeyExists(variables, cacheKey) ) {
			var webContexts = getWebContexts();
			var tmp = {};

			loop query="webContexts" {
				tmp[webContexts.id] = webContexts.path
			}			
			variables[cacheKey] = tmp;
		}
		return variables[cacheKey][arguments.webID];
	}

	public string function getFileCreationDate(required string file) output=false {
   		// Get file attributes using NIO
		var nioPath = createObject("java", "java.nio.file.Paths").get( arguments.file, [] );
		var nioAttributes = createObject("java", "java.nio.file.attribute.BasicFileAttributes");
		var nioFiles = createObject("java", "java.nio.file.Files");
		var fileAttr = nioFiles.readAttributes(nioPath, nioAttributes.getClass(), []);
   		// Display NIO results as date objects		   
   		return parseDateTime(fileAttr.creationTime().toString());
	}

	public query function getLogs(string sort="name", string dir="asc") output=false {
		var q_log_files = "";		
		directory filter=logsFilter, directory=getLogPath() listinfo="all" name="q_log_files" action="list";

		// add created date
		QueryAddColumn( q_log_files, "created", "date" );
		loop query=q_log_files{
			QuerySetCell(q_log_files, "created", 
				getFileCreationDate(q_log_files.directory & "/" & q_log_files.name), 
				q_log_files.currentrow
			);			
		}
		QuerySort( q_log_files, arguments.sort, arguments.dir );
		return	q_log_files;
		
	}

	public boolean function logsFilter(path) output=false {
		return listfindNoCase("log,bak", right(path,3));
	}

	public query function readLog(required string file, any sinceDate) output=false {
		var log = getLogPath(arguments.file);
		var qLog = logParser.createLogQuery();
		logParser.readLog(log, arguments.file, "", qLog, sinceDate);
		//throw "zac	zac	zaczac";
		return qLog;
	}

	public struct function readAllLogs() output=false {
		var qLog = logParser.createLogQuery();
		var q_log_files = getLogs();
		var timings = {};
		var rows = 0;
		loop query=q_log_files {
			var startTime = getTickCount();
			logParser.readLog(getLogPath(q_log_files.name), q_log_files.name, "", qLog);
			timings[q_log_files.name] = { 
				parseTime: getTickCount()-startTime,
				recordcount: qLog.recordcount - rows
			};
			if (timings[q_log_files.name].recordcount gt 0)
				timings[q_log_files.name].avg = timings[q_log_files.name].recordcount /  timings[q_log_files.name].parseTime;
			rows = qLog.recordcount;
		}
		return {
			timings: timings,
			qLog: qLog
		};

	}

	public struct function analyzeLog(required string file, required string sort, required string sortDir){
		var log = getLogPath(arguments.file);
		return logParser.analyzeLog(log, arguments.sort, arguments.sortDir);
	}
}
