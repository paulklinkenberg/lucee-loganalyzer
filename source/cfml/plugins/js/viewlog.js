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
				document.location = newUrl;// updateUrl(newUrl, "start", ""); // start over
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
				viewLog.doSearchSubmit();
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
		if (sel.toString().length > 0 && sel.toString().length < 50){
			window.scrollTo(0, 0);
			viewLog.doSearch(sel.toString());
		}
	},
	clickLog: function(ev){
		var el = $(ev.target);
		var log = $(ev.target).closest(".log");
		if (el.hasClass("log-expand")){
			var collapsed = log.find(".log-stacktrace");
			var expanded = collapsed.is(":VISIBLE");
			collapsed.toggle(!expanded);
			log.find("a.log-expand").toggle(expanded);
		} else if (el[0].nodeName === "A" ){
			window.scrollTo(0, 0);
			viewLog.doSearch($(el[0]).text());
		}
	},
	pollServerForUpdates: function(cb){
		var $logs = $(".logs");
		var fetched = $logs.data("fetched");
		var url = viewLog.updateUrl(null, "start", fetched);
		url = viewLog.updateUrl(url, "end", "");
		var $loading = $(".logs-loading").show();

		var url = viewLog.updateUrl(url, "pluginAction", "getLogJson");
		var poll = $.ajax({
			url: url + "&xhr=true",
			type: "GET"
		}).done(function(data) {
			$loading.hide();
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

			// handle logged out sessions, login page gets returned
			if (this.dataTypes[1] !== 'json'){
				$logs.prepend($status.text("non json response.. logged out?"));
				console.warn("non json response", poll, this);
				/*if (poll.status === 200){
					// logged out
					document.location.reload();
				}*/
				$logs.prepend(poll.responseText)
				return;
			}

			var logs = viewLog.renderLog(data.Q_LOG);

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
	doSearch: function(str, force){ // force is for clear
		var $el = $(".search-logs");
		if (str || force){
			$el.val(str);
		}
		if (String($(".logs").data("search")).length > 0)
			viewLog.doSearchSubmit(); // was a server side search, need to reset

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
	doSearchSubmit: function(ev){
		var $frm = $("form.log-actions");
		// need to reverse the check box state of severity, it works in reverse
		$(".log-severity-filter input").each(function(){
			var checked = $(this).is(":checked");
			$(this).attr("checked", !checked);
		});
		var newUrl = $frm.serialize();
		document.location = "?" + newUrl;
		return false;
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
			if ( log.logFile === log.logFile[l-1] &&
					log.severity === log.severity[l-1] &&
					log.thread === log.thread[l-1] &&
					log.logTimestamp === log.logTimestamp[l-1] )
			var hideHeader = true;
		}

		var el = $('<div>').addClass('log log-severity-' + log.severity + ' log-file-filter-' + log.logFile.replace(".","_") );
		if (hideHeader)
			el.addClass("log-grouped");
		el.append('<a class="log-expand"></a>').text( viewLog.i18n('expand') );
		var header = $('<div class="log-header">');
		if (hideHeader)
			header.hide();

		header.append( $('<span class="log-file">').text(log.logFile) );
		header.append( $('<span class="log-severity">').text(log.severity) );
		header.append(
			$('<span class="log-timestamp">').text(
				moment(log.logTimestamp, viewLog.jsonDateFormat).format(
					viewLog.i18n('timeformat','HH:mm:ss') + ', ' + viewLog.i18n('momentdateformat', 'D MMM, YYYY')
				)
			)
		);
		header.append( $('<span class="log-thread">').text("(" + log.thread + ")" ) );

		el.append(header);

		var detail = $('<div class="log-detail">').text(log.log);
		if (log.cfStack.length){
			var cfstack = $('<ol class="cfstack">');
			for (var c = 0; c < log.cfStack.length; c++)
				cfstack.append( $('<li>').append($("<a>").text(log.cfStack[c]) ) );
			detail.append(cfstack);
		}

		if (log.stack.length){
			var stack  = $('<div style="display:none;" class="log-stacktrace">').html(
				log.stack.replace(viewLog.crlf,"<br>").replace(viewLog.nl, "<br>")
			);
			detail.append(stack);
		}
		el.append(detail);
		return el;
	},
	toggleLogConfigSelection: function(ev){
		var $el = $(ev.currentTarget);
		var state = $el.is(":checked");
		$el.closest("TABLE").find("INPUT.logConfig").each(function(){
			$(this).prop("checked", state);
		});
	},
	submitLogConfig: function(ev){
		var $el = $(ev.currentTarget);
		var state = $el.is(":checked");
		var logConfig = [];
		$el.closest("TABLE").find("INPUT.logConfig").each(function(){
			if($(this).is(":checked"))
				logConfig.push($(this).val());
		});
		var logStorage = $(".logStorage:checked").val();
		if (!logStorage){
			alert("Please select a Log storage option");
		} else if (!logConfig.length){
			alert("Please select at least one log");
		} else {
			$(".log-configure").submit();
		}
	},
	sortTable:		function (th, sortDefault){					
		var tr = th.parentElement;
		var table = tr.parentElement.parentElement; // table;
		var tbodys = table.getElementsByTagName("tbody");
		var theads = table.getElementsByTagName("thead");
		var rowspans = (table.dataset.rowspan !== "false");

		if (!th.dataset.type)
			th.dataset.type = sortDefault; // otherwise text
		if (!th.dataset.dir){
			th.dataset.dir = "asc";
		} else {
			if (th.dataset.dir == "desc")
				th.dataset.dir = "asc";
			else
				th.dataset.dir = "desc";
		}
		for (var h = 0; h < tr.children.length; h++){
			var cell = tr.children[h].style;
			if (h === th.cellIndex){
				cell.fontWeight = 700;
				cell.fontStyle = (th.dataset.dir == "desc") ? "normal" : "italic";
			} else {
				cell.fontWeight = 300;
				cell.fontStyle = "normal";
			}
		}
		var sortGroup = false;
		var localeCompare = "test".localeCompare ? true : false;
		var numberParser = new Intl.NumberFormat('en-US');
		var data = [];

		for ( var b = 0; b < tbodys.length; b++ ){
			var tbody =tbodys[b];
			for ( var r = 0; r < tbody.children.length; r++ ){
				var row = tbody.children[r];
				var group = false;
				if (row.classList.length > 0){
					// check for class sort-group
					group = row.classList.contains("sort-group");
				}
				// this is to handle secondary rows with rowspans, but this stops two column tables from sorting
				if (group){
					data[data.length-1][1].push(row);
				} else {
					switch (row.childElementCount){
						case 0:
						case 1:
							continue;
						case 2:
							if (!rowspans)
								break;
							if (data.length > 1)
								data[data.length-1][1].push(row);										
							continue;
						default:
							break;
					}								
					var cell = row.children[th.cellIndex];
					var val = cell.innerText;
					if (!localeCompare){
						switch (th.dataset.type){
							case "text":
								val = val.toLowerCase();
								break;
							case "numeric":
							case "number":
								switch (val){
									case "":
									case "-":
										val = -1;
										break;
									default:
										val = Number(val);
									break;
								}
								break;
						}
					} else {
						// hack to handle formatted numbers with commas for thousand separtors
						var tmpNum = val.split(",");
						if (tmpNum.length > 1){
							tmpNum = Number(tmpNum.join(""));
							if (tmpNum !== NaN)
								val = String(tmpNum);
						}
					}
					var _row = row;
					if (r === 0 && 
							theads.length > 1 &&
							tbody.previousElementSibling.nodeName === "THEAD" && 
							tbody.previousElementSibling.children.length){
						data.push([val, [tbody.previousElementSibling, row], tbody]);
						sortGroup = true;
					} else {
						data.push([val, [row]]);
					}
					
				}
			}
		}

		switch (th.dataset.type){
			case "text":
				data = data.sort(function(a,b){
					if (localeCompare){
						return a[0].localeCompare(b[0],"en", {numeric:true, ignorePunctuation: true});
					} else {
						if (a[0] < b[0])
							return -1;
						if (a[0] > b[0])
							return 1;
						return 0;
					}                    
				});
				break;
			case "numeric": 
			case "number":
				data = data.sort(function(a,b){
					return a[0] - b[0];
				}); 
		}
		
		if (th.dataset.dir === "asc")
			data.reverse();
		if (!sortGroup){
			for (r = 0; r < data.length; r++){
				for (var rr = 0; rr < data[r][1].length; rr++)
					tbody.appendChild(data[r][1][rr]);
			}						
		} else {
			for (r = 0; r < data.length; r++){
			
				if (data[r].length === 3){
					var _rows = data[r];
					table.appendChild(_rows[1][0]); // thead
					table.appendChild(_rows[2]); // tbody
					var _tbody = _rows[2];
					for (var rr = 1; rr < _rows[1].length; rr++)
						_tbody.appendChild(_rows[1][rr]); // tr
					
				} else {
					for (var rr = 0; rr < data[r][1].length; rr++)
						table.appendChild(data[r][1][rr]); 
				}
			}
		}

	}
};

$(function(){
	if (!pluginLanguage)
		console.warn("pluginLanguage missing, use #renderUtils.includeLang()#");
	else
		viewLog.importi18n(pluginLanguage);

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

	$(".logConfigToggle").on("change", viewLog.toggleLogConfigSelection);	
	$(".bulkUpdateLogConfig").on("click", viewLog.submitLogConfig);
	$(".sort-table THEAD TH").on("click", function(ev){
		viewLog.sortTable(ev.target, 'text');
	});	

	var midnight = moment().set('hour', 23).set('minute', 23);
	var ranges = {
		"Today": [
			moment().startOf('day'),
			midnight
		],
		"Yesterday": [
			moment().subtract(1, "days").startOf('day'),
			moment().subtract(1, "days").endOf('day'),
		],
		"Last 7 Days": [
			moment().subtract(7,'days').startOf('day'),
			midnight
		],
		"Last 30 Days": [
			moment().subtract(30,'days').startOf('day'),
			midnight
		],
		"This Month": [
			moment().startOf('month'),
			midnight
		],
		"Last Month": [
			moment().startOf('month').subtract(1, "months"),
			moment().startOf('month').subtract(1, "months").endOf('month')
		]
	};
	if ($('.daterange').length){
		$('.daterange').daterangepicker({
			"ranges": ranges,
			"alwaysShowCalendars": false,
			"startDate": (logViewerDates.start == "") ? null : moment(logViewerDates.start, 'YYYY-MM-DD'),
			"endDate": (logViewerDates.end == "") ? null : moment(logViewerDates.end, 'YYYY-MM-DD'),
			"minDate": moment(logViewerDates.firstLogDate, 'YYYY-MM-DD'),
			"maxDate": moment(),
			"opens": "left",
			"timePicker": true,
			"timePickerSeconds": false,
			"timePicker24Hour": true,
			"showDropdowns": true,
			"autoUpdateInput": true,
			locale: {
				format: 'MMMM D, YYYY'
			}
		}, function(start, end, label) {
			console.log('New date range selected: ' + start.format('YYYY-MM-DD') + ' to '
				+ end.format('YYYY-MM-DD') + ' (predefined range: ' + label + ')');
			if (!start.isValid() || !end.isValid() )
				return;
			var newUrl = viewLog.updateUrl(null, "start", start.format('YYYY-MM-DD') );
			newUrl = viewLog.updateUrl(newUrl, "end", end.format('YYYY-MM-DD') );
			document.location = newUrl;
		});
		viewLog.daterangepicker = $('.daterange').data('daterangepicker');
	}
});
