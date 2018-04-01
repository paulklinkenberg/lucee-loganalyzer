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
component hint="various rendering related files"{
	/**
	 * this function will be called to initalize
	 */
	public void function init(required struct lang) {
		variables.lang = arguments.lang;
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

	public void function includeCSS() {
		var css = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "/css/style.css");
		htmlhead text='<style id="log-analyzer" type="text/css">#css#</style>';
	}

	public void function includeJavascript(required string template) {
		var js = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "/js/#template#.js");
		htmlbody text='<script data-src="log-analyzer-plugin-#template#">#js#</script>';
	}
	/**
	 * creates a text string indicating the timespan between NOW and given datetime
	 */
	public function getTextTimeSpan(required date date) output=false {
		var diffSecs = dateDiff('s', arguments.date, now());
		if ( diffSecs < 60 ) {
			return replace(variables.lang.Xsecondsago, '%1', diffSecs);
		} else if ( diffSecs < 3600 ) {
			return replace(variables.lang.Xminutesago, '%1', int(diffSecs/60));
		} else if ( diffSecs < 86400 ) {
			return replace(variables.lang.Xhoursago, '%1', int(diffSecs/3600));
		} else {
			return replace(variables.lang.Xdaysago, '%1', int(diffSecs/86400));
		}
	}

	public function cleanHtml( required string content){
		return ReReplace(arguments.content, "[\r\n]\s*([\r\n]|\Z)", Chr(10), "ALL")
	}

}
