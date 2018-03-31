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
component hint="I contain the main functions for the log Analyzer plugin" extends="lucee.admin.plugin.Plugin" {


	/**
	 * this function will be called to initalize
	 */
	public void function init(required struct lang, required struct app) {
		variables.logGateway = new logGateway();
	}

	public string function getCSRF(){
		return CSRFGenerateToken("log-analyzer");
	}

	private boolean function checkCSRF(required string token){
		if (not CSRFVerifyToken( arguments.token, "log-analyzer" ))
			throw message="access denied";
		else
			return true;
	}

	public void function _display(required string template, required struct lang, required struct app, required struct req) {
		var css = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "/css/style.css");
		htmlhead text='<style id="log-analyzer" type="text/css">#css#</style>';
		super._display(argumentcollection=arguments);
	}

	public void function includeJavascript(required string template) {
		var js = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "/js/#template#.js");
		htmlbody text='<script data-src="log-analyzer-plugin-#template#">#js#</script>';
	}
	/**
	 * creates a text string indicating the timespan between NOW and given datetime
	 */
	public function getTextTimeSpan(required date date, required struct lang) output=false {
		var diffSecs = dateDiff('s', arguments.date, now());
		if ( diffSecs < 60 ) {
			return replace(lang.Xsecondsago, '%1', diffSecs);
		} else if ( diffSecs < 3600 ) {
			return replace(lang.Xminutesago, '%1', int(diffSecs/60));
		} else if ( diffSecs < 86400 ) {
			return replace(lang.Xhoursago, '%1', int(diffSecs/3600));
		} else {
			return replace(lang.Xdaysago, '%1', int(diffSecs/86400));
		}
	}

	/**
	 * list all files from the local web
	 */
	public function overview(struct lang, struct app, struct req) output=true {
		param default="name", name="url.sort";
		param default="", name="url.dir";
		param default="", name="session.loganalyzer.webID";
		//  web context chosen?
		if ( request.admintype == "server" && structKeyExists(form, "webID") && len(form.webID) ) {
			session.logAnalyzer.webID = form.webID;
		}
		if ( request.admintype != "server" || len(session.loganalyzer.webID) ) {
			arguments.req.logfiles = logGateway.getLogs(sort=url.sort, dir=url.dir);
		}
	}

	public function list(struct lang, struct app, struct req) output=false {
		//  when viewing logs in the server admin, then a webID must be defined
		if ( request.admintype == "server" ) {
			param  default="" name="session.loganalyzer.webID";
			if ( !len(session.loganalyzer.webID) ) {
				var gotoUrl = rereplace(action('overview'), "^[[:space:]]+", "");
				location( gotoUrl, false );
			}
		}
		param  name="url.file" default="";
		param  name="url.sort" default="date";
		param  name="url.dir" default="desc";
		req.result = logGateway.analyzeLog(url.file, url.sort, url.dir);
	}

	public function viewLog(struct lang, struct app, struct req) output=false {
		param name="url.file" default="";
		param name="url.since" default="";

		var sinceDate = "";
		if (len(url.since)){
			sinceDate = ParseDateTime(since);
		}
		arguments.req.q_log = logGateway.readLog(url.file, sinceDate);
	}

	public function deleteLog(struct lang, struct app, struct req) output=false {
		if (structKeyExists(url, "delete")){
			param name="url.token" default="";
			param name="url.file" default="";
			//if (checkCSRF( url.token))
			//	throw message="access denied";

			var tempFilePath = logGateway.getLogPath(file=url.file);
			try {
				file action="delete" file="#tempFilePath#";
			} catch (any){
				file action="write" file="#tempFilePath#" output="";
			}
			location url=action("overview");
		} else {
			location url=action("overview","&missing=true");
		}

	}

}
