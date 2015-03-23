<!---
/*
 * download.cfm, written by Paul Klinkenberg
 * http://www.lucee.nl/post.cfm/railo-admin-log-analyzer
 *
 * Date: 2015-03-23 22:25:00 +0100
 * Revision: 2.3.0
 *
 * Copyright (c) 2015 Paul Klinkenberg, lucee.nl
 * Licensed under the GPL license.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *    ALWAYS LEAVE THIS COPYRIGHT NOTICE IN PLACE!
 */
--->		
<cfset var tempFilePath = getLogPath(file=url.file) />

<cfheader name="Content-Disposition" value="attachment;filename=#listLast(tempFilePath, '/\')#" />
<cfcontent type="text/plain" file="#tempFilePath#" reset="yes" />