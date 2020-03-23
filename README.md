# Lucee Log Viewer
Log Viewer plugin for Lucee, to be used in the Lucee admin.

By Zac Spitzer https://twitter.com/zackster/

Based on https://github.com/paulklinkenberg/lucee-loganalyzer

- It's published on [ForgeBox](https://www.forgebox.io/view/LuceeLogViewer) and available via the Lucee Administrator

## Features
- Aggregrates all logs into a single combined view
- Search by date or string
- Auto refreshing / polling
- Filter by severity or source log file
- Stack traces are collapsed

## Building
The Build process uses [Apache Ant](https://ant.apache.org/) 

Simply run **ant** in the root directory to build the extension .lex file, which you can then manually install via the Lucee Administrator

## Hacking
Once installed, all the source cfml and js files can be found under the server or web context, depending where you installed it 

- web context: under the \WEB-INF\context\admin\plugin\logViewer
- server: C:\lucee\tomcat\lucee-server\context\context\admin\plugin\logViewer

![Sample Screenshot](https://github.com/zspitzer/lucee-logviewer/blob/refactoring/screenshot.jpg)
