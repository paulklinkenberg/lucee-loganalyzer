<!--- 
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
 --->
 <cfscript>
    param name="url.file" default="";
    var filePath = logGateway.getLogPath(file=url.file);    

    if (not fileExists(filePath)){
        header statuscode=404;
        abort;
    }       
    var raw = fileInfo(filePath);
    log text="download logfile: #url.file# #numberformat(raw.size/1024)#kb bytes";         
    
    header name="Content-Disposition" value="attachment;filename=#listLast(filePath, '/\')#";
    if (raw.size gt (1024*1024)){
        var tempFile =  GetTempFile( getTempDirectory(), "logs" );    
        log text="compressing log file:#url.file#";
        Compress("gzip", filePath, tempFile);    
        var compressed = fileInfo(tempFile);
        log text="download gzipped logfile:#url.file#, #numberFormat(compressed.size/1024)#kb";
        header name="Content-Length" value="#compressed.size#";        
        header name="content-encoding" value="gzip";    
        content type="text/plain" file="#tempFile#" reset="yes" deletefile="true";
    } else {        
        header name="Content-Length" value="#raw.size#";                
        content type="text/plain" file="#filePath#" reset="yes";
    }
 </cfscript>
 