$(function(){
	var doAction = function(data, logfile){
		var token = $(".csrf-token").data('token');
		var actionUrl = "?action=plugin&plugin=loganalyzer&file=" + logfile;

		switch (data.action){
			case  "delete":
				data.action = "deleteLog";
				actionUrl += "&delete=true&token=" + token;
				if (!confirm("delete " + logfile + "?"))
					return false;
				break;
		}
		document.location = actionUrl + "&pluginAction=" + data.action ;
	};
	$(".log-overview INPUT").on("click", function(ev){
		doAction($(this).data(), $(this).closest("TR").data('logfile') );
	});
	$(".log-overview TD.name").on("click", function(ev){
		var $el = $(ev.currentTarget);
		doAction( {action:"viewLog"}, $el.closest("TR").data("logfile") );
	});
});