$(function(){
    //$("#layout").addClass("layout-fullwidth");
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
        document.location.reload();
    });

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