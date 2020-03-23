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
component hint="Actions for the log Viewer plugin" extends="lucee.admin.plugin.Plugin" {

	public void function init(required struct lang, required struct app) {
		variables.renderUtils = new RenderUtils(arguments.lang, action("asset"), this.action );
		variables.logGateway = new logGateway();
		variables._lang = arguments.lang;
		setting showdebugoutput="true";
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
		param name="req.sort" default="name";
		param name="req.dir" default="";
		param name="session.logViewer.webID" default="serverContext";
		//  web context chosen?
		if ( request.admintype == "server" && structKeyExists(req, "webID") && len(req.webID) ) {
			session.logViewer.webID = req.webID;
		}
		if ( request.admintype != "server" || len(session.logViewer.webID) ) {
			req.logfiles = logGateway.listLogs(sort=req.sort, dir=req.dir, listOnly=true);
		} else {
			location url=action("contextSelector", 'nextAction=admin') addtoken="false";
		}
	}

	public function overview(struct lang, struct app, struct req) output=true {
		param name="arguments.req.file" default="";
		param name="arguments.req.start" default=""; // default="#dateFormat(now(),'yyyy-mm-dd')#";
		param name="arguments.req.end" default=""; //default="#dateFormat(DateAdd('d',-7,now()),'yyyy-mm-dd')#";
		param name="arguments.req.q" default="";
		param name="session.logViewer.webID" default="serverContext";

		if ( request.admintype != "server" || len(session.logViewer.webID) ) {
			var logs = variables.logGateway.getLog(files=arguments.req.file, startDate=arguments.req.start,
				endDate=arguments.req.end,
				defaultDays=7, parseLogs=true, search=arguments.req.q);
			variables.renderUtils.renderServerTimingHeaders(logs.timings);
			logs.delete("timings");
			arguments.req.logs = logs;
		} else {
			location url=action("contextSelector", 'nextAction=overview') addtoken="false";
		}
	}

	public function contextSelector(struct lang, struct app, struct req) output=false {
	}

	public function setContext(struct lang, struct app, struct req) output=false {
		if ( request.admintype == "server" && structKeyExists(req, "webID") && len(req.webID) ) {
			session.logViewer.webID = req.webID;
		}
		param name="req.nextAction" default="overview";
		location url=action(req.nextAction) addtoken="false";
	}

	public function getLogJson(struct lang, struct app, struct req) output=false {
		param name="req.file" default="";
		param name="req.start" default="";
		param name="req.end" default="";
		param name="req.q" default="";

		var logs = logGateway.getLog(files=req.file, startDate=req.start, endDate=req.end,
			defaultDays=7, parseLogs=true, search=req.q);
		logs.FETCHED = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
		variables.renderUtils.renderServerTimingHeaders(logs.timings);
		setting showdebugoutput="false";
		content type="application/json" reset="yes";
		writeOutput(serializeJson(logs));
		abort;
	}

	public function getLang(struct lang, struct app, struct req) output=false {
		url.xhr=true;
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
		if (structKeyExists(req, "delete")){
			param name="req.token" default="";
			param name="req.file" default="";
			//if (checkCSRF( req.token))
			//	throw message="access denied";

			local.tempFilePath = logGateway.getLogPath(file=req.file);
			try {
				file action="delete" file="#local.tempFilePath#";
			} catch (any){
				file action="write" file="#local.tempFilePath#" output="";
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
