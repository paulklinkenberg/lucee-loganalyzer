$(function(){
	'use strict';
	var updateSeverityFilter =  function(){
		var css = "";
		var hidden = [];
		$(".log-severity-filter input:not(:checked)").each(function(){
			var item = $(this).parent().attr("class");
			css += "." + item + ".log { display: none; } ";
			hidden.push(item.split("-").pop());
		});
		$(".log-severity-filter-css").text(css);
		history.pushState({},"", updateUrl("hidden", hidden.join()) );
	};

	var updateUrl = function(param, val){
		var url = document.location.href;
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

	$(".log").click(function(){
		var data = $(this).data();
		var expanded = $(".long-log-" + data.log).is(":VISIBLE");
		$(".long-log-" + data.log).toggle(!expanded);
		if (this.nodeName == "A"){
			$(this).toggle(!expanded);
		} else {
			$(this).find("a.expand-log").toggle(expanded);
		}
	});
	$(".reload-logs").click(function(){
		var $logs = $(".logs");
		var fetched = $logs.data("fetched");
		var url = updateUrl("since", fetched);
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

		}).error(function(jqXHR){
			$(".logs-error").show().html(jqXHR.responseText);
		});
		//document.location.reload();
	});
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

	$(".expand-all").click(function(){
		var state = $(this).data("expanded");
		$(".collapsed-log").toggle(!state);
		$("a.expand-log").toggle(!state);
		if (state){
			$(this).val("Collapse All");
		} else {
			$(this).val("Expand All");
		}
		$(this).data("expanded", !state);
	});

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
});
