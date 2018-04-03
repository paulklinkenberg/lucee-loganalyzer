'use strict';
var viewLog = {
	nl: String.fromCharCode(10),
	crlf: String.fromCharCode(10) + String.fromCharCode(13),
	i18n: function(key, _default){
		key = key.toLowerCase();
		if (viewLog.langBundle[key]){
			return viewLog.langBundle[key];
		} else {
			console.warn("missing language string: [" + key + "] for locale: [" + viewLog.locale + "] from javascript");
			if (_default)
				return _default;
			else 
				return key;	
		}
	},
	langBundle: {},
	locale: "en",
	importi18n: function(pluginLanguage){
		for (var str in pluginLanguage.STRINGS)
			viewLog.langBundle[(String(str).toLowerCase())] = pluginLanguage.STRINGS[str];
		viewLog.locale = pluginLanguage.locale;
	},
	updateSeverityFilter: function(){
		var css = "";
		var hidden = [];
		$(".log-severity-filter input:not(:checked)").each(function(){
			var item = $(this).parent().attr("class");
			css += "." + item + ".log { display: none; } " + viewLog.nl;
			hidden.push(item.split("-").pop());
		});
		$(".log-severity-filter-css").text(css);
		history.pushState({},"", viewLog.updateUrl(null, "severity", hidden.join()) );
	},
	updateFileFilter: function(){
		var css = "";
		var files = {};
		var selected = {};
		var checked = 0;
		$(".log-file-filter input").each(function(){
			var isChecked = $(this).is(":checked");
			var file = $(this).val();
			files[$(this).val()] = isChecked;
			if (isChecked){
				checked ++;
				selected[file] = true;
			}
		});
		var urlParam = "";
		if (checked === 0){
			// no filter
		} else {
			for (var f in files){
				if (files.hasOwnProperty(f) && !files[f])
					css += ".log-file-filter-" + f.replace(".", "_") + ".log { display: none; } " + viewLog.nl;
			}
			urlParam = Object.keys(selected).join();
		}
		// check the requested files are present in the initial page
		var loadedFiles = $(".logs").data("files");
		var newUrl = viewLog.updateUrl(null, "file", urlParam);

		var reload = viewLog.reloadRequiredFiles(urlParam, loadedFiles, selected);
		console.log(reload, urlParam, loadedFiles, selected);
		if (!reload){
			console.log(urlParam, css);
			$(".logs-loading").show();
			$(".log-file-filter-css").text(css);
			if ($(".logs .log:visible").length === 0){
				reload = true; // nothing visible, reload anyway
				//console.log("nothing visible, force reload");
			} else {
				$(".logs-loading").hide();
			}
		}
		if (reload){
			//console.log("reloading");
			$(".logs-loading").show();
			setTimeout(function(){
				document.location = newUrl;// updateUrl(newUrl, "since", ""); // start over
			}, 100);
		} else {
			history.pushState({},"", viewLog.updateUrl(newUrl, "file", urlParam) );
		}
	},
	reloadRequiredFiles: function(urlParam, loadedFiles, selected){
		if (!loadedFiles || loadedFiles.length === 0)
			return false; // page was loaded without a file filter
		if (urlParam.length === 0 && loadedFiles.length > 0)
			return true; // page was loaded with a file filter

		var files = {}, _files = loadedFiles.split();
		for (var f in _files)
			files[f] = true;
		for (var requested in Object.keys(selected).join() ){
			if (!files[requested])
				return true; // at least one file wasn't loaded
		}
		return false; // all requested files are loaded
	},
	updateUrl: function(url, param, val){
		if (!url)
			url = document.location.href;
		var key = "&" + param + "=";
		var h = url.indexOf(key);
		if (h === -1){
			url += key + val;
		} else {
			var after="", pos = url.indexOf("&", h+1);
			if (pos > -1)
				after = url.substr(pos);
			url = url.substr(0,h);
			url += key + val;
			url += after;
		}
		return url;
	},
	logActions: function(){
		var data = $(this).data();
		switch (data.action){
			case "poll":
				viewLog.pollServerForUpdates();
				break;
			case "reload":
				document.location.reload();
				break;
			case "search":
				viewLog.doSearch();
				break;
			case "clear-search":
				viewLog.doSearch("", true);
				break;
			case "auto-refresh":
				viewLog.toggleAutoRefresh($(this));
				break;
			case "expand-all":
				viewLog.expandAll();
				break;
			case "admin":
				document.location=  viewLog.updateUrl(null, "pluginAction","admin");
			default:
				//console.warn("unsupported action: " + data.action);
		};
	},
	searchSelect: function(ev){
		var el = $(ev.target);
		var sel = window.getSelection();
		if (sel.toString().length > 0){
			window.scrollTo(0, 0);
			viewLog.doSearch(sel.toString());
		}
	},
	clickLog: function(ev){
		var el = $(ev.target);
		var log = $(ev.target).closest(".log");
		if ( el[0].nodeName === "A" ){
			window.scrollTo(0, 0);
			viewLog.doSearch($(el[0]).text());
		} else {
			var collapsed = log.find(".log-stacktrace");
			var expanded = collapsed.is(":VISIBLE");
			collapsed.toggle(!expanded);
			log.find("a.log-expand").toggle(expanded);
		}
	},
	pollServerForUpdates: function(cb){
		var $logs = $(".logs");
		var fetched = $logs.data("fetched");
		var url = viewLog.updateUrl(null, "since", fetched);
		var $loading = $(".logs-loading").show();

		var url = viewLog.updateUrl(url, "pluginAction", "getLogJson");
		$.ajax({
			url: url + "&xhr=true",
			type: "GET"
		}).done(function(data) {
			$loading.hide();

			var logs = viewLog.renderLog(data.Q_LOG);

			/*

			var $data = $(data);
			var $newLogs = $data.find(".logs");
			var fetched = $newLogs.data("fetched");
			$logs.data("fetched", $newLogs.data("fetched") );
			var $new = $newLogs.find(".log");
			*/
			$logs.data("fetched", data.FETCHED);
			var $status = $("<div>").addClass("logs-update");
			var now = moment().format("HH:MM:ss");
			if (logs.length > 0){
				$logs.prepend(logs);
				$logs.prepend(
					$status.text("" + now + ", " + logs.length + ' ' + viewLog.i18n('newLogs') + ' ' + ((logs.length > 1) ? "s":"") )
				);
				
				viewLog.updateTitleCount(logs.length);
				viewLog.trimLogs();
			} else {
				$logs.prepend($status.text(viewLog.i18n('noNewLogs') + ", " + now));
			}
			if (cb)
				cb();
		}).error(function(jqXHR){
			$loading.hide();
			$(".logs-error").show().html(jqXHR.responseText);
		});
		//document.location.reload();
	},
	maxDisplaylimit: 2000,
	trimLogs: function(){
		var $logs = $(".logs .log");
		var total = $logs.length;
		if ($logs.length > viewLog.maxDisplaylimit){
			$logs.slice(viewLog.maxDisplaylimit).remove();
		}
		$logs = $(".logs .log");
		var removed = (total-$logs.length);
		if (removed)
			console.log("removed " + removed + " logs for performance");
	},
	updateTitleCount: function(newLogCount){
		var title = document.title.split(/[(/(/)\)]+/);
		if (title.length > 2)
			title.shift();
		if (document.hasFocus())	
		newLogCount = null;
		if (newLogCount === null){
			// on focus reset title
			if (title.length === 1){
				return;
			} else {
				document.title = title[1];
				return;
			}
		}
		if (title.length > 1){
			document.title = "(" + (newLogCount + Number(title[0])) + ") " + title[1];
		} else {
			document.title = "(" + newLogCount + ") " + title[0];
		}
		console.log(document.title);
	},
	expandAll: function(){
		var state = $(this).data("expanded");
		$(".log-stacktrace").toggle(!state);
		$("a.log-expand").toggle(!state);
		if (state){
			$(this).val("Collapse All");
		} else {
			$(this).val("Expand All");
		}
		$(this).data("expanded", !state);
	},
	doSearch: function(str, force){
		var $el = $(".search-logs");
		if (str || force){
			$el.val(str);
		}
		str = $.trim($el.val()).toLowerCase();
		if (str.length === 0){
			$(".logs .log.search-hidden").removeClass("search-hidden");
		} else {
			$(".logs .log").each(function(){
				var txt = $(this).text().toLowerCase();
				var match = (txt.indexOf(str) === -1);
				$(this).toggleClass("search-hidden", match);
			});
		}
	},
	debounceTimer: null,
	refreshTimer: null,
	toggleAutoRefresh: function($el){
		if (viewLog.refreshTimer){
			clearTimeout(viewLog.refreshTimer);
			$el.val(viewLog.i18n('StartAutoRefresh'));
			viewLog.refreshTimer = null;
		} else {
			$el.val(viewLog.i18n('StopAutoRefresh'));
			viewLog.refreshTimer = setTimeout(viewLog.autoRefresh(), viewLog.getRefreshPeriod());
		}
	},
	getRefreshPeriod: function(){
		return Number($(".poll-period").val()) * 1000; // timeouts in ms, drop down has seconds
	},
	autoRefresh: function(){
		viewLog.refreshTimer = setTimeout(function doPoll (){
			viewLog.pollServerForUpdates(function callback(){
				viewLog.refreshTimer = setTimeout(viewLog.autoRefresh, viewLog.getRefreshPeriod());
			});
		}, 5000);
	},
	renderLog: function(q_logs){
		var logs = [];
		for ( var l = 0; l < q_logs.DATA.length; l++ ){
			logs.push(
				viewLog.renderLogEntry( viewLog.readLog(q_logs, l), l )
			);
		}
		return logs;
	},
	readLog: function (logs, l){
		var log = {};
		for ( var c = 0; c < logs.COLUMNS.length; c++)
			log[logs.COLUMNS[c]]= logs.DATA[l][c];
		return log;
	},
	jsonDateFormat: "MMMM, Do YYYY, h:mm:ss ZZ",
	renderLogEntry: function(log, l){
		var hideHeader = false;
		if (l > 0) {
			if ( log.LOGFILE === log.LOGFILE[l-1] &&
					log.SEVERITY === log.SEVERITY[l-1] &&
					log.THREAD === log.THREAD[l-1] &&
					log.LOGTIMESTAMP === log.LOGTIMESTAMP[l-1] )
			var hideHeader = true;						
		}

		var el = $('<div>').addClass('log log-severity-' + log.SEVERITY + ' log-file-filter-' + log.LOGFILE.replace(".","_") );
		el.append('<a class="log-expand"></a>').text( viewLog.i18n('expand') );
		var header = $('<div class="log-header">');
		if (hideHeader)
			header.hide();
		
		header.append( $('<span class="log-file">').text(log.LOGFILE) );
		header.append( $('<span class="log-severity">').text(log.SEVERITY) );
		header.append( 
			$('<span class="log-timestamp">').text( 
				moment(log.LOGTIMESTAMP, viewLog.jsonDateFormat).format(
					viewLog.i18n('momentdateformat', 'D MMM, YYYY') + ' ' + viewLog.i18n('timeformat','HH:mm:ss') 
				)  
			)
		); 
		header.append( $('<span class="log-thread">').text("(" + log.THREAD) + ")" );

		el.append(header);

		var detail = $('<div class="log-detail">').text(log.LOG);
		if (log.CFSTACK.length){
			var cfstack = $('<ol class="cfstack">');
			for (var c = 0; c < log.CFSTACK.length; c++)
				cfstack.append( $('<li>').append($("<a>").text(log.CFSTACK[c]) ) );
			detail.append(cfstack);
		}
		
		if (log.STACK.length){
			var stack  = $('<div style="display:none;" class="log-stacktrace">').html(
				log.STACK.replace(viewLog.crlf,"<br>").replace(viewLog.nl, "<br>")
			);
			detail.append(stack);
		}
		el.append(detail);
		return el;
	}
};

$(function(){

	$(".log-severity-filter INPUT").on("change", viewLog.updateSeverityFilter);
	$(".log-file-filter INPUT").on("change", viewLog.updateFileFilter);
	$(".log-actions INPUT:not('.daterange')").on("click", viewLog.logActions);
	$(".logs").on("click", viewLog.clickLog);
	$(".logs").on("mouseup", viewLog.searchSelect);
	$(".search-logs").on("keyup", function(){
		clearTimeout(viewLog.debounceTimer);
		viewLog.debounceTimer = setTimeout(viewLog.doSearch, 250);
	}).on("submit", function(){
		return false;
	});
	$(window).on("focus", function(){
		viewLog.updateTitleCount(null);		
	});
	/*
	var midnght = moment().set('hour', 23).set('minute', 23);
	$('.daterange').daterangepicker({
		"ranges": {
			"Today": [
				midnght,
				moment().startOf('day'),
			],
			"Yesterday": [
				midnght,
				moment().subtract('d',1).startOf('day'),
			],
			"Last 7 Days": [
				midnght,
				moment().subtract('d',7).startOf('day'),
			],
			"Last 30 Days": [
				midnght,
				moment().subtract('d',30).startOf('day'),
			],
			"This Month": [
				midnght,
				moment().startOf('month')
			],
			"Last Month": [
				moment().subtract("m",1).endOf('month'),
				moment().subtract("m",1).startOf('month')
			]
		},
		"alwaysShowCalendars": false,
		"startDate": "03/27/2018",
		"endDate": "04/02/2018",
		"minDate": "01/01/2016",
		"opens": "left",
		"timePicker": true
	}, function(start, end, label) {
	  console.log('New date range selected: ' + start.format('YYYY-MM-DD') + ' to '
	  	+ end.format('YYYY-MM-DD') + ' (predefined range: ' + label + ')');
	});
	viewLog.daterangepicker =$('.daterange').data('daterangepicker');
	*/
});
