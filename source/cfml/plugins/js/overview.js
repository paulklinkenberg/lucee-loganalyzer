$(function(){			
    $(".log-overview INPUT.button").click(function(){
        var data = $(this).data();
        var logfile = $(this).closest("TR").data('logfile');
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
    });
});