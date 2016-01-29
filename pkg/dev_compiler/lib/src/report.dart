// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Summarizes the information produced by the checker.

import 'dart:math' show max;

import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/error.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';

import 'utils.dart';
import 'summary.dart';

final _checkerLogger = new Logger('dev_compiler.checker');

/// Collects errors, and then sorts them and sends them
class ErrorCollector implements AnalysisErrorListener {
  final AnalysisErrorListener listener;
  final List<AnalysisError> _errors = [];

  ErrorCollector(this.listener);

  /// Flushes errors to the log. Until this is called, errors are buffered.
  void flush() {
    // TODO(jmesserly): this code was taken from analyzer_cli.
    // sort errors
    _errors.sort((AnalysisError error1, AnalysisError error2) {
      // severity
      var severity1 = _strongModeErrorSeverity(error1);
      var severity2 = _strongModeErrorSeverity(error2);
      int compare = severity2.compareTo(severity1);
      if (compare != 0) return compare;

      // path
      compare = Comparable.compare(error1.source.fullName.toLowerCase(),
          error2.source.fullName.toLowerCase());
      if (compare != 0) return compare;

      // offset
      compare = error1.offset - error2.offset;
      if (compare != 0) return compare;

      // compare message, in worst case.
      return error1.message.compareTo(error2.message);
    });

    _errors.forEach(listener.onError);
    _errors.clear();
  }

  void onError(AnalysisError error) {
    _errors.add(error);
  }
}

ErrorSeverity _strongModeErrorSeverity(AnalysisError error) {
  // Upgrade analyzer warnings to errors.
  // TODO(jmesserly: reconcile this with analyzer_cli
  var severity = error.errorCode.errorSeverity;
  if (!isStrongModeError(error.errorCode) &&
      severity == ErrorSeverity.WARNING) {
    return ErrorSeverity.ERROR;
  }
  return severity;
}

/// Simple reporter that logs checker messages as they are seen.
class LogReporter implements AnalysisErrorListener {
  final AnalysisContext _context;
  final bool useColors;
  final List<AnalysisError> _errors = [];

  LogReporter(this._context, {this.useColors: false});

  void onError(AnalysisError error) {
    var level = _severityToLevel[_strongModeErrorSeverity(error)];

    // TODO(jmesserly): figure out what to do with the error's name.
    var lineInfo = _context.computeLineInfo(error.source);
    var location = lineInfo.getLocation(error.offset);

    // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
    var text = new StringBuffer()
      ..write('[${errorCodeName(error.errorCode)}] ')
      ..write(error.message)
      ..write(' (${path.prettyUri(error.source.uri)}')
      ..write(', line ${location.lineNumber}, col ${location.columnNumber})');

    // TODO(jmesserly): just print these instead of sending through logger?
    _checkerLogger.log(level, text);
  }
}

// TODO(jmesserly): remove log levels, instead just use severity.
const _severityToLevel = const {
  ErrorSeverity.ERROR: Level.SEVERE,
  ErrorSeverity.WARNING: Level.WARNING,
  ErrorSeverity.INFO: Level.INFO
};

/// A reporter that gathers all the information in a [GlobalSummary].
class SummaryReporter implements AnalysisErrorListener {
  GlobalSummary result = new GlobalSummary();
  final Level _level;
  final AnalysisContext _context;

  SummaryReporter(this._context, [this._level = Level.ALL]);

  IndividualSummary _getIndividualSummary(Uri uri) {
    if (uri.path.endsWith('.html')) {
      return result.loose.putIfAbsent('$uri', () => new HtmlSummary('$uri'));
    }

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
    return container.putIfAbsent('$uri', () => new LibrarySummary('$uri'));
  }

  void onError(AnalysisError error) {
    // Only summarize messages per configured logging level
    var code = error.errorCode;
    if (_severityToLevel[code.errorSeverity] < _level) return;

    var span = _toSpan(_context, error);
    var summary = _getIndividualSummary(error.source.uri);
    if (summary is LibrarySummary) {
      summary.recordSourceLines(error.source.uri, () {
        // TODO(jmesserly): parsing is serious overkill for this.
        // Should be cached, but still.
        // On the other hand, if we are going to parse, we could get a much
        // better source lines of code estimate by excluding things like
        // comments, blank lines, and closing braces.
        var unit = _context.parseCompilationUnit(error.source);
        return unit.lineInfo.getLocation(unit.endToken.end).lineNumber;
      });
    }
    summary.messages.add(new MessageSummary(errorCodeName(code),
        code.errorSeverity.displayName, span, error.message));
  }

  // TODO(jmesserly): fix to not depend on SourceSpan. This will be really slow
  // because it will reload source text from disk, for every single message...
  SourceSpanWithContext _toSpan(AnalysisContext context, AnalysisError error) {
    var source = error.source;
    var lineInfo = context.computeLineInfo(source);
    var content = context.getContents(source).data;
    var start = error.offset;
    var end = start + error.length;
    return createSpanHelper(lineInfo, start, end, source, content);
  }

  void clearLibrary(Uri uri) {
    (_getIndividualSummary(uri) as LibrarySummary).clear();
  }

  void clearHtml(Uri uri) {
    HtmlSummary htmlSummary = result.loose['$uri'];
    if (htmlSummary != null) htmlSummary.messages.clear();
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

  var activeInfoTypes = counter.totals.keys;
  activeInfoTypes.forEach((t) => table.declareColumn(t, abbreviate: true));
  table.declareColumn('LinesOfCode', abbreviate: true);
  table.addHeader();

  // Add entries for each package
  appendCount(count) => table.addEntry(count == null ? 0 : count);
  for (var package in counter.errorCount.keys) {
    appendCount(package);
    appendCount(counter.errorCount[package]['AnalyzerError']);
    activeInfoTypes.forEach((t) => appendCount(counter.errorCount[package][t]));
    appendCount(counter.linesOfCode[package]);
  }

  // Add totals, percents and a new header for quick reference
  table.addEmptyRow();
  table.addHeader();
  table.addEntry('total');
  appendCount(counter.totals['AnalyzerError']);
  activeInfoTypes.forEach((t) => appendCount(counter.totals[t]));
  appendCount(counter.totalLinesOfCode);

  appendPercent(count, total) {
    if (count == null) count = 0;
    var value = (count * 100 / total).toStringAsFixed(2);
    table.addEntry(value);
  }

  var totalLOC = counter.totalLinesOfCode;
  table.addEntry('%');
  appendPercent(counter.totals['AnalyzerError'], totalLOC);
  activeInfoTypes.forEach((t) => appendPercent(counter.totals[t], totalLOC));
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
    widths.add(max(5, headerName.length + 1) as int);
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
