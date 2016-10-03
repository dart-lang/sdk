// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../log/log.dart';
import '../server.dart';

typedef void Writer(StringSink sink);

/**
 * A class used to write an HTML page.
 */
abstract class PageWriter {
  /**
   * The object used to escape special HTML characters.
   */
  static final HtmlEscape htmlEscape = new HtmlEscape();

  /**
   * Initialize a newly create page writer.
   */
  PageWriter();

  /**
   * Return the length of the common prefix for time stamps associated with the
   * given log [entries].
   */
  int computePrefixLength(List<LogEntry> entries) {
    int length = entries.length;
    if (length < 2) {
      return 0;
    }
    String firstTime = entries[0].timeStamp.toString();
    String lastTime = entries[length - 1].timeStamp.toString();
    int prefixLength = 0;
    int timeLength = firstTime.length;
    while (prefixLength < timeLength &&
        firstTime.codeUnitAt(prefixLength) ==
            lastTime.codeUnitAt(prefixLength)) {
      prefixLength++;
    }
    return prefixLength;
  }

  /**
   * Return an escaped version of the given [unsafe] text.
   */
  String escape(String unsafe) {
    // We double escape single quotes because the escaped characters are
    // processed as part of reading the HTML, which means that single quotes
    // end up terminating string literals too early when they appear in event
    // handlers (which in turn leads to JavaScript syntax errors).
    return htmlEscape.convert(unsafe).replaceAll('&#39;', '&amp;#39;');
  }

  /**
   * Write the body of the page (without the 'body' tag) to the given [sink].
   */
  void writeBody(StringSink sink);

  /**
   * Write the given [date] to the given [sink].
   */
  void writeDate(StringSink sink, DateTime date) {
    String isoString = date.toIso8601String();
    int index = isoString.indexOf('T');
    String dateString = isoString.substring(0, index);
    String timeString = isoString.substring(index + 1);
    sink.write(dateString);
    sink.write(' at ');
    sink.write(timeString);
  }

  /**
   * Write the body of the page (without the 'body' tag) to the given [sink].
   */
  void writeMenu(StringSink sink) {
    sink.writeln('<div class="menu">');
    sink.write('<a href="${WebServer.logPath}" class="menuItem">Log</a>');
    sink.write('&nbsp;&bullet;&nbsp;');
    sink.write('<a href="${WebServer.statsPath}" class="menuItem">Stats</a>');
    sink.writeln('</div>');
  }

  /**
   * Write the contents of the instrumentation log to the given [sink].
   */
  void writePage(StringSink sink) {
    sink.writeln('<!DOCTYPE html>');
    sink.writeln('<html lang="en-US">');
    sink.writeln('<head>');
    sink.writeln('<meta charset="utf-8">');
    sink.writeln(
        '<meta name="viewport" content="height=device-height, width=device-width, initial-scale=1.0">');
    sink.writeln('<title>Instrumentation Log</title>');
    sink.writeln('<style>');
    writeStyleSheet(sink);
    sink.writeln('</style>');
    sink.writeln('<script>');
    writeScripts(sink);
    sink.writeln('</script>');
    sink.writeln('</head>');
    sink.writeln('<body>');
    writeBody(sink);
    sink.writeln('</body>');
    sink.writeln('</html>');
  }

  /**
   * Write the scripts for the page (without the 'script' tag) to the given
   * [sink].
   */
  void writeScripts(StringSink sink) {
    // No common scripts.
  }

  /**
   * Write the content of the style sheet (without the 'script' tag) for the
   * page to the given [sink].
   */
  void writeStyleSheet(StringSink sink) {
    sink.writeln(r'''
a {
  color: #000000;
  text-decoration: none;
}
a.menuItem {
  font-weight: bold;
}
body {
  font-family: sans-serif;
  height: 100%;
  margin: 0px;
  overflow: hidden;
  padding: 0px;
  width: 100%;
}
div.columnHeader {
}
div.button {
  display: inline-block;
  border-radius: 4px;
  border: 1px solid;
  height: 16px;
  text-align: center;
  vertical-align: middle;
  width: 16px;
}
div.inset {
  padding: 10px;
}
div.menu {
  background-color: #cce6ff;
  padding: 5px;
}
html {
  height: 100%;
  width: 100%;
}
span.button {
  border-radius: 5px;
  border: 1px solid;
  height: 16px;
  width: 16px;
}
span.error {
  color: #ff0000;
}
span.gray {
  color: #777777;
}
span.label {
  font-weight: bold;
}
table.fullWidth {
  border: 0px;
  width: 100%;
}
td.halfWidth {
  width: 50%;
  vertical-align: top;
}
td.int {
  text-align: right;
}
th {
  text-align: left;
}
th.narrow {
  width: 16px;
}

#container {
  height: 100%;
  min-height: 100%;
  position: relative;
  width: 100%;
}
#content {
  height: 90%;
  width: 100%;
}
''');
  }

  /**
   * Write to the given [sink] the HTML required to display content in two
   * columns. The content of the columns will be written by the functions
   * [writeLeftColumn], [writeCenterColumn] and [writeRightColumn] and will be
   * contained in 'div' elements with the id's [leftColumnId], [centerColumnId]
   * and [rightColumnId].
   */
  void writeThreeColumns(
      StringSink sink,
      String leftColumnId,
      Writer writeLeftColumn,
      String centerColumnId,
      Writer writeCenterColumn,
      String rightColumnId,
      Writer writeRightColumn) {
    sink.writeln('<div>');
    sink.writeln('  <div>');
    sink.writeln('    <div id="$leftColumnId">');
    sink.writeln('      <div class="inset">');
    writeLeftColumn(sink);
    sink.writeln('      </div>');
    sink.writeln('    </div>');
    sink.writeln('    <div id="$rightColumnId">');
    sink.writeln('      <div class="inset">');
    writeRightColumn(sink);
    sink.writeln('      </div>');
    sink.writeln('    </div>');
    sink.writeln('    <div id="$centerColumnId">');
    sink.writeln('      <div class="inset">');
    writeCenterColumn(sink);
    sink.writeln('      </div>');
    sink.writeln('    </div>');
    sink.writeln('  </div>');
    sink.writeln('</div>');
  }

  /**
   * Writeto the given [sink] the styles needed by a three column section where
   * the columns have the ids [leftColumnId], [centerColumnId] and
   * [rightColumnId].
   */
  void writeThreeColumnStyles(StringSink sink, String leftColumnId,
      String centerColumnId, String rightColumnId) {
    sink.writeln('''
#$leftColumnId {
  float: left;
  height: 100%;
  overflow: auto;
  width: 33%;
}
#$centerColumnId {
  height: 100%;
  overflow: auto;
  width: 33%;
}
#$rightColumnId {
  float: right;
  height: 100%;
  overflow: auto;
  width: 33%;
}
''');
  }

  /**
   * Write to the given [sink] the HTML required to display content in two
   * columns. The content of the columns will be written by the functions
   * [writeLeftColumn] and [writeRightColumn] and will be contained in 'div'
   * elements with the id's [leftColumnId] and [rightColumnId].
   */
  void writeTwoColumns(StringSink sink, String leftColumnId,
      Writer writeLeftColumn, String rightColumnId, Writer writeRightColumn) {
    sink.writeln('<div id="container">');
    sink.writeln('  <div id="content">');
    sink.writeln('    <div id="$leftColumnId">');
    sink.writeln('      <div class="inset">');
    writeLeftColumn(sink);
    sink.writeln('      </div>');
    sink.writeln('    </div>');
    sink.writeln('    <div id="$rightColumnId">');
    sink.writeln('      <div class="inset">');
    writeRightColumn(sink);
    sink.writeln('      </div>');
    sink.writeln('    </div>');
    sink.writeln('  </div>');
    sink.writeln('</div>');
  }

  /**
   * Writeto the given [sink] the styles needed by a two column section where
   * the columns have the ids [leftColumnId] and [rightColumnId].
   */
  void writeTwoColumnStyles(
      StringSink sink, String leftColumnId, String rightColumnId) {
    sink.writeln('''
#$leftColumnId {
  float: left;
  height: 100%;
  overflow: auto;
  width: 50%;
}
#$rightColumnId {
  float: right;
  height: 100%;
  overflow: auto;
  width: 50%;
}
''');
  }
}
