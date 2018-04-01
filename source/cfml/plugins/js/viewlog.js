$(function(){
	'use strict';
	var nl = String.fromCharCode(10);
	var updateSeverityFilter =  function(){
		var css = "";
		var hidden = [];
		$(".log-severity-filter input:not(:checked)").each(function(){
			var item = $(this).parent().attr("class");
			css += "." + item + ".log { display: none; } " + nl;
			hidden.push(item.split("-").pop());
		});
		$(".log-severity-filter-css").text(css);
		history.pushState({},"", updateUrl(null, "severity", hidden.join()) );
	};

	var updateFileFilter =  function(){
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
					css += ".log-file-filter-" + f.replace(".", "_") + ".log { display: none; } " + nl;
			}
			urlParam = Object.keys(selected).join();
		}
		// check the requested files are present in the initial page
		var loadedFiles = $(".logs").data("files");
		var newUrl = updateUrl(null, "file", urlParam);

		var reload = reloadRequiredFiles(urlParam, loadedFiles, selected);
		console.log(reload, urlParam, loadedFiles, selected);
		if (!reload){
			console.log(urlParam, css);
			$(".log-file-filter-css").text(css);
			if ($(".logs .log:visible").length === 0){
				reload = true; // nothing visible, reload anyway
				//console.log("nothing visible, force reload");
			}
		}
		if (reload){
			//console.log("reloading");
			document.location = newUrl;// updateUrl(newUrl, "since", ""); // start over
		} else {
			history.pushState({},"", updateUrl(newUrl, "file", urlParam) );
		}
	};

	var reloadRequiredFiles = function(urlParam, loadedFiles, selected){
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
	};

	var updateUrl = function(url, param, val){
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
	}

	$(".log-severity-filter INPUT").on("change", updateSeverityFilter);
	$(".log-file-filter INPUT").on("change", updateFileFilter);

	$(".log-actions INPUT").click(function(){
		var data = $(this).data();
		switch (data.action){
			case "poll":
				pollServerForUpdates();
				break;
			case "reload":
				document.location.reload();
				break;
			case "search":
				doSearch();
				break;
			case "auto-refresh":
				toggleAutoRefresh($(this));
				break;
			case "expand-all":
				expandAll();
				break;
			default:
				//console.warn("unsupported action: " + data.action);
		};
	});

	$(".log").click(function(){
		var data = $(this).data();
		var expanded = $(".long-log-" + data.log).is(":VISIBLE");
		$(".long-log-" + data.log).toggle(!expanded);
		if (this.nodeName == "A"){
			$(this).toggle(!expanded);
		} else {
			$(this).find("a.log-expand").toggle(expanded);
		}
	});
	var pollServerForUpdates = function(cb){
		var $logs = $(".logs");
		var fetched = $logs.data("fetched");
		var url = updateUrl(null, "since", fetched);
		$.ajax({
			url: url,
			type: "GET"
		}).done(function(data) {
			var $data = $(data);
			var $newLogs = $data.find(".logs");
			var fetched = $newLogs.data("fetched");
			$logs.data("fetched", $newLogs.data("fetched") );
			var $new = $newLogs.find(".log");
			var $status = $("<div>").addClass("logs-update");

			if ($newLogs.length > 0){
				$logs.prepend($status.text("polled logs " + new Date()),$new);
				trimLogs();
			} else {
				$logs.prepend($status.text("polled logs, no updates, " + new Date()));
			}
			if (cb)
				cb();
		}).error(function(jqXHR){
			$(".logs-error").show().html(jqXHR.responseText);
		});
		//document.location.reload();
	};
	var limit = 2000;
	var trimLogs = function(){
		var $logs = $(".logs .log");
		var total = $logs.length;
		if ($logs.length > 2000){
			$logs.slice(2000).remove();
		}
		$logs = $(".logs .log");
		var removed = (total-$logs.length);
		if (removed)
			console.log("removed " + removed + " logs for performance");
	};

	var expandAll = function(){
		var state = $(this).data("expanded");
		$(".collapsed-log").toggle(!state);
		$("a.log-expand").toggle(!state);
		if (state){
			$(this).val("Collapse All");
		} else {
			$(this).val("Expand All");
		}
		$(this).data("expanded", !state);
	};

	var doSearch = function(){
		var $el = $(".search-logs");
		var str = $.trim($el.val()).toLowerCase();
		if (str.length === 0){
			$(".logs .log.search-hidden").removeClass("search-hidden");
		} else {
			$(".logs .log").each(function(){
				var txt = $(this).text().toLowerCase();
				var match = (txt.indexOf(str) === -1);
				$(this).toggleClass("search-hidden", match);
			});
		}
	};
	var debounceTimer = null;
	$(".search-logs").on("keyup", function(){
		clearTimeout(debounceTimer);
		debounceTimer = setTimeout(doSearch, 250);
	}).on("submit", function(){
		return false;
	});
	var refreshTimer = null;
	var toggleAutoRefresh = function($el){
		if (refreshTimer){
			clearTimeout(refreshTimer);
			$el.val("Auto-refresh");
			refreshTimer = null;
		} else {
			$el.val("Stop Auto-refresh");
			refreshTimer = setTimeout(autoRefresh(), getRefreshPeriod());
		}
	};
	var getRefreshPeriod = function(){
		return Number($(".poll-period").val()) * 1000; // timeouts in ms, drop down has seconds
	};
	var autoRefresh = function(){
		refreshTimer = setTimeout(function doPoll (){
			pollServerForUpdates(function callback(){
				refreshTimer = setTimeout(autoRefresh, getRefreshPeriod());
			});
		}, 5000);
	};
});
