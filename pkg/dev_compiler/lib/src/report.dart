// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Summarizes the information produced by the checker.
library dev_compiler.src.report;

import 'dart:math' show max;

import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';

import 'info.dart';
import 'utils.dart';
import 'summary.dart';

/// A message (error or warning) produced by the dev_compiler and it's location
/// information.
///
/// Currently the location information includes only the offsets within a file
/// where the error occurs. This is used in the context of a [CheckerReporter],
/// where the current file is being tracked.
abstract class Message {
  // Message description.
  final String message;

  /// Log level. This is a placeholder for severity.
  final Level level;

  /// Offset where the error message begins in the tracked source file.
  final int begin;

  /// Offset where the error message ends in the tracked source file.
  final int end;

  const Message(this.message, this.level, this.begin, this.end);
}

/// Like [Message], but with a precomputed source span.
abstract class MessageWithSpan implements Message {
  final String message;

  final Level level;

  final SourceSpan span;

  int get begin => span.start.offset;
  int get end => span.end.offset;

  const MessageWithSpan(this.message, this.level, this.span);
}

// Interface used to report error messages from the checker.
abstract class CheckerReporter {
  /// Called when starting to process a library.
  void enterLibrary(Uri uri);
  void leaveLibrary();

  /// Called when starting to process an HTML source file.
  void enterHtml(Uri uri);
  void leaveHtml();

  /// Called when starting to process a source. All subsequent log entries must
  /// belong to this source until the next call to enterSource.
  void enterSource(Source source);
  void leaveSource();
  void log(Message message);

  // Called in server-mode.
  void clearLibrary(Uri uri);
  void clearHtml(Uri uri);
  void clearAll();
}

final _checkerLogger = new Logger('dev_compiler.checker');

/// Simple reporter that logs checker messages as they are seen.
class LogReporter implements CheckerReporter {
  final bool useColors;
  SourceFile _file;
  Source _current;

  LogReporter([this.useColors = false]);

  void enterLibrary(Uri uri) {}
  void leaveLibrary() {}

  void enterHtml(Uri uri) {}
  void leaveHtml() {}

  void enterSource(Source source) {
    _file = new SourceFile(source.contents.data, url: source.uri);
    _current = source;
  }

  void leaveSource() {
    _file = null;
    _current = null;
  }

  void log(Message message) {
    if (message is StaticInfo) {
      assert((message.node as dynamic).root.element.source == _current);
    }
    // TODO(sigmund): convert to use span information from AST (issue #73)
    final span = message is MessageWithSpan
        ? message.span
        : _file.span(message.begin, message.end);
    final level = message.level;
    final color = useColors ? colorOf(level.name) : null;
    final text = '[${message.runtimeType}] ${message.message}';
    _checkerLogger.log(level, span.message(text, color: color));
  }

  void clearLibrary(Uri uri) {}
  void clearHtml(Uri uri) {}
  void clearAll() {}
}

/// A reporter that gathers all the information in a [GlobalSummary].
class SummaryReporter implements CheckerReporter {
  GlobalSummary result = new GlobalSummary();
  IndividualSummary _current;
  SourceFile _file;

  void enterLibrary(Uri uri) {
    var container;
    if (uri.scheme == 'package') {
      var pname = path.split(uri.path)[0];
      result.packages.putIfAbsent(pname, () => new PackageSummary(pname));
      container = result.packages[pname].libraries;
    } else if (uri.scheme == 'dart') {
      container = result.system;
    } else {
      container = result.loose;
    }
    _current = container.putIfAbsent('$uri', () => new LibrarySummary('$uri'));
  }

  void leaveLibrary() {
    _current = null;
  }

  void enterHtml(Uri uri) {
    _current = result.loose.putIfAbsent('$uri', () => new HtmlSummary('$uri'));
  }

  void leaveHtml() {
    _current = null;
  }

  void enterSource(Source source) {
    _file = new SourceFile(source.contents.data, url: source.uri);
    if (_current is LibrarySummary) {
      (_current as LibrarySummary).lines += _file.lines;
    }
  }

  void leaveSource() {
    _file = null;
  }

  void log(Message message) {
    assert(message is MessageWithSpan || _file != null);
    // TODO(sigmund): convert to use span information from AST (issue #73)
    final span = message is MessageWithSpan
        ? message.span
        : _file.span(message.begin, message.end);
    _current.messages.add(new MessageSummary('${message.runtimeType}',
        message.level.name.toLowerCase(), span, message.message));
  }

  void clearLibrary(Uri uri) {
    enterLibrary(uri);
    _current.messages.clear();
    (_current as LibrarySummary).lines = 0;
    leaveLibrary();
  }

  void clearHtml(Uri uri) {
    HtmlSummary htmlSummary = result.loose['$uri'];
    if (htmlSummary != null) htmlSummary.messages.clear();
  }

  clearAll() {
    result = new GlobalSummary();
  }
}

/// Produces a string representation of the summary.
String summaryToString(GlobalSummary summary) {
  var counter = new _Counter();
  summary.accept(counter);

  var table = new _Table();
  // Declare columns and add header
  table.declareColumn('package');
  table.declareColumn('AnalyzerError', abbreviate: true);
  infoTypes.forEach((type) => table.declareColumn('$type', abbreviate: true));
  table.declareColumn('LinesOfCode', abbreviate: true);
  table.addHeader();

  // Add entries for each package
  appendCount(count) => table.addEntry(count == null ? 0 : count);
  for (var package in counter.errorCount.keys) {
    appendCount(package);
    appendCount(counter.errorCount[package]['AnalyzerError']);
    infoTypes.forEach((e) => appendCount(counter.errorCount[package]['$e']));
    appendCount(counter.linesOfCode[package]);
  }

  // Add totals, percents and a new header for quick reference
  table.addEmptyRow();
  table.addHeader();
  table.addEntry('total');
  appendCount(counter.totals['AnalyzerError']);
  infoTypes.forEach((type) => appendCount(counter.totals['$type']));
  appendCount(counter.totalLinesOfCode);

  appendPercent(count, total) {
    if (count == null) count = 0;
    var value = (count * 100 / total).toStringAsFixed(2);
    table.addEntry(value);
  }

  var totalLOC = counter.totalLinesOfCode;
  table.addEntry('%');
  appendPercent(counter.totals['AnalyzerError'], totalLOC);
  infoTypes.forEach((type) => appendPercent(counter.totals['$type'], totalLOC));
  appendCount(100);

  return table.toString();
}

/// Helper class to combine all the information in table form.
class _Table {
  int _totalColumns = 0;
  int get totalColumns => _totalColumns;

  /// Abbreviations, used to make headers shorter.
  Map<String, String> abbreviations = {};

  /// Width of each column.
  List<int> widths = <int>[];

  /// The header for each column (`header.length == totalColumns`).
  List header = [];

  /// Each row on the table. Note that all rows have the same size
  /// (`rows[*].length == totalColumns`).
  List<List> rows = [];

  /// Whether we started adding entries. Indicates that no more columns can be
  /// added.
  bool _sealed = false;

  /// Current row being built by [addEntry].
  List _currentRow;

  /// Add a column with the given [name].
  void declareColumn(String name, {bool abbreviate: false}) {
    assert(!_sealed);
    var headerName = name;
    if (abbreviate) {
      // abbreviate the header by using only the capital initials.
      headerName = name.replaceAll(new RegExp('[a-z]'), '');
      while (abbreviations[headerName] != null) headerName = "$headerName'";
      abbreviations[headerName] = name;
    }
    widths.add(max(5, headerName.length + 1));
    header.add(headerName);
    _totalColumns++;
  }

  /// Add an entry in the table, creating a new row each time [totalColumns]
  /// entries are added.
  void addEntry(entry) {
    if (_currentRow == null) {
      _sealed = true;
      _currentRow = [];
    }
    int pos = _currentRow.length;
    assert(pos < _totalColumns);

    widths[pos] = max(widths[pos], '$entry'.length + 1);
    _currentRow.add('$entry');

    if (pos + 1 == _totalColumns) {
      rows.add(_currentRow);
      _currentRow = [];
    }
  }

  /// Add an empty row to divide sections of the table.
  void addEmptyRow() {
    var emptyRow = [];
    for (int i = 0; i < _totalColumns; i++) {
      emptyRow.add('-' * widths[i]);
    }
    rows.add(emptyRow);
  }

  /// Enter the header titles. OK to do so more than once in long tables.
  void addHeader() {
    rows.add(header);
  }

  /// Generates a string representation of the table to print on a terminal.
  // TODO(sigmund): add also a .csv format
  String toString() {
    var sb = new StringBuffer();
    sb.write('\n');
    for (var row in rows) {
      for (int i = 0; i < _totalColumns; i++) {
        var entry = row[i];
        // Align first column to the left, everything else to the right.
        sb.write(
            i == 0 ? entry.padRight(widths[i]) : entry.padLeft(widths[i] + 1));
      }
      sb.write('\n');
    }
    sb.write('\nWhere:\n');
    for (var id in abbreviations.keys) {
      sb.write('  $id:'.padRight(7));
      sb.write(' ${abbreviations[id]}\n');
    }
    return sb.toString();
  }
}

/// An example visitor that counts the number of errors per package and total.
class _Counter extends RecursiveSummaryVisitor {
  String _currentPackage;
  String get currentPackage =>
      _currentPackage != null ? _currentPackage : "*other*";
  var sb = new StringBuffer();
  Map<String, Map<String, int>> errorCount = <String, Map<String, int>>{};
  Map<String, int> linesOfCode = <String, int>{};
  Map<String, int> totals = <String, int>{};
  int totalLinesOfCode = 0;

  void visitGlobal(GlobalSummary global) {
    if (!global.system.isEmpty) {
      for (var lib in global.system.values) {
        lib.accept(this);
      }
    }

    if (!global.packages.isEmpty) {
      for (var lib in global.packages.values) {
        lib.accept(this);
      }
    }

    if (!global.loose.isEmpty) {
      for (var lib in global.loose.values) {
        lib.accept(this);
      }
    }
  }

  void visitPackage(PackageSummary package) {
    _currentPackage = package.name;
    super.visitPackage(package);
    _currentPackage = null;
  }

  void visitLibrary(LibrarySummary lib) {
    super.visitLibrary(lib);
    linesOfCode.putIfAbsent(currentPackage, () => 0);
    linesOfCode[currentPackage] += lib.lines;
    totalLinesOfCode += lib.lines;
  }

  visitMessage(MessageSummary message) {
    var kind = message.kind;
    errorCount.putIfAbsent(currentPackage, () => <String, int>{});
    errorCount[currentPackage].putIfAbsent(kind, () => 0);
    errorCount[currentPackage][kind]++;
    totals.putIfAbsent(kind, () => 0);
    totals[kind]++;
  }
}
