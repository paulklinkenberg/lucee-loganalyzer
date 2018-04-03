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
		variables.renderUtils = new RenderUtils(arguments.lang, action("asset"), this.action );
		variables._lang = arguments.lang;
	}

	public void function _display(required string template, required struct lang, required struct app, required struct req) {
		param name="url.xhr" default="false";
		request._missing_lang = {};
		if ( not url.xhr)
			renderUtils.includeCSS("style");
		super._display(argumentcollection=arguments);
		renderUtils.warnMissingLang(request._missing_lang);
	}

	/**
	 * list all files from the local web
	 */
	public function admin(struct lang, struct app, struct req) output=true {
		param default="name", name="url.sort";
		param default="", name="url.dir";
		param default="", name="session.loganalyzer.webID";
		//  web context chosen?
		if ( request.admintype == "server" && structKeyExists(req, "webID") && len(req.webID) ) {
			session.logAnalyzer.webID = req.webID;
		}
		if ( request.admintype != "server" || len(session.loganalyzer.webID) ) {
			arguments.req.logfiles = logGateway.listLogs(sort=url.sort, dir=url.dir, listOnly=true);
		} else {
			location url=action("contextSelector", 'nextAction=admin') addtoken="false";
		}
	}

	public function overview(struct lang, struct app, struct req) output=false {
		param name="url.file" default="";
		param name="url.start" default="";
		param default="", name="session.loganalyzer.webID";

		if ( request.admintype != "server" || len(session.loganalyzer.webID) ) {
			var logs = logGateway.getLog(url.file, url.start, 7, true);
			variables.renderUtils.renderServerTimingHeaders(logs.timings);
			arguments.req.logs = logs;
		} else {
			location url=action("contextSelector", 'nextAction=overview') addtoken="false";
		}
	}

	public function contextSelector(struct lang, struct app, struct req) output=false {
	}

	public function setContext(struct lang, struct app, struct req) output=false {
		if ( request.admintype == "server" && structKeyExists(req, "webID") && len(req.webID) ) {
			session.logAnalyzer.webID = req.webID;
		}
		param name="req.nextAction" default="overview";
		location url=action(req.nextAction) addtoken="false";
	}

	public function getLogJson(struct lang, struct app, struct req) output=false {
		param name="url.file" default="";
		param name="url.start" default="";

		var logs = logGateway.getLog(url.file, url.start, 7, true);
		logs.FETCHED = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
		variables.renderUtils.renderServerTimingHeaders(logs.timings);
		setting showdebugoutput="false";
		content type="application/json" reset="yes";
		writeOutput(serializeJson(logs));
		abort;
	}

	public function getLang(struct lang, struct app, struct req) output=false {
		var pluginLanguage = {
			strings: arguments.lang,
			locale: session.LUCEE_ADMIN_LANG
		};
		setting showdebugoutput="false";
		content type="text/javascript" reset="yes";
		writeOutput("var pluginLanguage = #serializeJson(pluginLanguage)#;");
		abort;
	}

	public string function i18n(string key) output=false {
		if (structKeyExists(variables._lang, arguments.key)){
			return variables._lang[arguments.key];
		} else {
			request._missing_lang[arguments.key]="";
			return arguments.key;
		}
	}

	public function viewLog(struct lang, struct app, struct req) output=false {
		location url=action("overview") addtoken="false";
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

	public function asset(struct lang, struct app, struct req) output=false {
		param name="req.asset";
		// dunno why, sometimes this doesn't exist and throws an error
		if (not structKeyExists(variables, "renderUtils") )
			variables.renderUtils = new RenderUtils(arguments.lang, action("asset"), this.action );
		renderUtils.returnAsset(url.asset);
	}
}
