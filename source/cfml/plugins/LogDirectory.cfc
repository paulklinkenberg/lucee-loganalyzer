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
component hint="I enumerate logs directories" {

	/**
	 * this function will be called to initalize
	 */
	public void function init() {
	}

	public query function listLogs(string sort="name", string dir="asc",
			any sinceDate="", string filter="") output=false {
		var since = processDate(arguments.sinceDate);
		var q_log_files = "";
		var _filter = (len(arguments.filter) eq 0) ? logsFilter : arguments.filter;

		directory filter=_filter, directory=getLogPath() listinfo="all" name="q_log_files" action="list";

		// add log created date
		QueryAddColumn( q_log_files, "created", "date" );
		local.empty = [];
		loop query=q_log_files{
			QuerySetCell(q_log_files, "created",
				getFileCreationDate(q_log_files.directory & "/" & q_log_files.name),
				q_log_files.currentrow
			);
			if (q_log_files.size lt 100)
				local.empty.append(q_log_files.currentrow);
		}

		for (var row in local.empty.reverse())
			QueryDeleteRow(q_log_files, row); // just headers,  effectively empty
		QuerySort( q_log_files, arguments.sort, arguments.dir );
		return	q_log_files;
	}

	public query function getWebContexts(boolean fromCache="true") output=false {
		var qWebContexts = "";
		if ( !structKeyExists(variables, "qWebContexts") || !arguments.fromCache ) {
			//  get all web contexts
			local.admin = new Administrator( "server", password );
			qWebContexts = local.admin.getContextes();

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
			local.logDir = expandPath("{lucee-web}/logs/");
		} else if ( session.logAnalyzer.webID == "serverContext" ) {
			local.logDir = expandPath("{lucee-server}/logs/");
		} else {
			local.logDir = getLogPathByWebID(session.logAnalyzer.webID);
		}
		if ( structKeyExists(arguments, "file") && len(arguments.file) ) {
			local.logDir = rereplace(local.logDir, "\#server.separator.file#$", "") & server.separator.file & listLast(arguments.file, "/\");
			if ( !fileExists(local.logDir) )
				throw( message="log file '#local.logDir#' does not exist!" );
		}
		return local.logDir;
	}

	/**
	 * I return the path to the log directory for a given web context
	 */
	public string function getLogPathByWebID(required string webID) output=false {
		checkIsServerAdmin();
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
		checkIsServerAdmin();
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

	private boolean function logsFilter(path) output=false {
		return listfindNoCase("log,bak", right(path,3));
	}

	private void function checkIsServerAdmin() output=false {
		if ( request.admintype == "web" )
			throw( message="Server admin functionality called from Web admin!" );
	}

	public any function processDate(any reqDate) output=false {
		if (len(arguments.reqDate)){
			local.d = ParseDateTime(arguments.reqDate);
		} else {
			local.d = false;
		}
		return local.d;
	}

	public date function getDefaultSince(required query q_log_files,
			required struct files, required numeric defaultDays){
		if (arguments.q_log_files.recordcount eq 0)
			return DateAdd("d", -arguments.defaultDays, now());
		var q = duplicate(arguments.q_log_files);
		if (structCount(files) gt 0){
			loop query=q {
				if (not (structKeyExists(files, q.name))) // exclude this log file from check
					querySetCell(q, "dateLastModified", createDate(2000,1,1), q.currentrow);
			}
		}
		if (q.recordcount eq 0)
			return DateAdd("d", -arguments.defaultDays, now());

		QuerySort(q, "dateLastModified", "desc");
		return DateAdd("d", -arguments.defaultDays, q.dateLastModified[1]);
	}

	// Lucee doesn't return date created in cfdirectory or GetFileInfo
	private string function getFileCreationDate(required string file) output=false {
   		// Get file attributes using NIO
		var nioPath = createObject("java", "java.nio.file.Paths").get( arguments.file, [] );
		var nioAttributes = createObject("java", "java.nio.file.attribute.BasicFileAttributes");
		var nioFiles = createObject("java", "java.nio.file.Files");
		var fileAttr = nioFiles.readAttributes(nioPath, nioAttributes.getClass(), []);
   		// Display NIO results as date objects
   		return parseDateTime(fileAttr.creationTime().toString());
	}

}
