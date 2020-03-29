<cfscript>
	var logs = logGateway.getLog(adminType=variables.logGateway.getAdminType(), files=req.file, startDate=req.start, endDate=req.end,
		defaultDays=7, parseLogs=true, search=req.q);
	logs.FETCHED = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
	variables.renderUtils.renderServerTimingHeaders(logs.timings);
	setting showdebugoutput="false";
	content type="application/json" reset="yes";
	writeOutput(serializeJson(logs));
	abort;
</cfscript>