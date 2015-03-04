// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Summarizes the information produced by the checker.
library ddc.src.report;

import 'dart:math' show max;

import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:logging/logging.dart';

import 'info.dart';
import 'utils.dart';

// Interface used to report error messages from the checker.
abstract class CheckerReporter {
  /// Called when starting to process a library.
  void enterLibrary(LibraryInfo info);
  void leaveLibrary();

  /// Called when starting to process a source. All subsequent log entries must
  /// belong to this source until the next call to enterSource.
  void enterSource(Source source);
  void leaveSource();

  void log(StaticInfo info);

  // TODO(sigmund): merge this and [log]
  void logAnalyzerError(String message, Level level, int begin, int end);
}

final _checkerLogger = new Logger('ddc.checker');

/// Simple reporter that logs checker messages as they are seen.
class LogReporter implements CheckerReporter {
  final bool useColors;
  SourceFile _file;
  Source _current;

  LogReporter([this.useColors = false]);

  void enterLibrary(LibraryInfo info) {}
  void leaveLibrary() {}

  void enterSource(Source source) {
    _file = new SourceFile(source.contents.data, url: source.uri);
    _current = source;
  }

  void leaveSource() {
    _file = null;
    _current = null;
  }

  void log(StaticInfo info) {
    assert((info.node as dynamic).root.element.source == _current);
    final span = _spanForNode(_file, info.node);
    final color = useColors ? colorOf(info.level.name) : null;
    _checkerLogger.log(info.level, span.message(info.message, color: color));
  }

  void logAnalyzerError(String message, Level level, int begin, int end) {
    var span = _file.span(begin, end);
    final color = useColors ? colorOf(level.name) : null;
    _checkerLogger.log(
        level, span.message('[from analyzer]: ${message}', color: color));
  }
}

/// A reporter that gathers all the information in a [GlobalSummary].
class SummaryReporter implements CheckerReporter {
  GlobalSummary result = new GlobalSummary();
  LibrarySummary _currentLibrary;
  SourceFile _file;

  clear() {
    result = new GlobalSummary();
  }

  void enterLibrary(LibraryInfo lib) {
    var libKey = '${lib.library.source.uri}';
    var libSummary = _currentLibrary = new LibrarySummary(libKey);

    var uri = lib.library.source.uri;
    if (uri.scheme == 'package') {
      var pname = path.split(uri.path)[0];
      result.packages.putIfAbsent(pname, () => new PackageSummary(pname));
      if (result.packages[pname].libraries[libKey] != null) {
        print('ERROR: duplicate ${libKey}');
      }
      result.packages[pname].libraries[libKey] = libSummary;
    } else if (uri.scheme == 'dart') {
      if (result.system[libKey] != null) {
        print('ERROR: duplicate ${libKey}');
      }
      result.system[libKey] = libSummary;
    } else {
      if (result.loose[libKey] != null) {
        print('ERROR: duplicate ${libKey}');
      }
      result.loose[libKey] = libSummary;
    }
  }

  void leaveLibrary() {
    _currentLibrary = null;
  }

  void enterSource(Source source) {
    _file = new SourceFile(source.contents.data, url: source.uri);
    _currentLibrary.lines += _file.lines;
  }

  void leaveSource() {
    _file = null;
  }

  void log(StaticInfo info) {
    assert(_file != null);
    var span = _spanForNode(_file, info.node);
    _currentLibrary.messages.add(new MessageSummary('${info.runtimeType}',
        info.level.name.toLowerCase(), span, info.message));
  }

  void logAnalyzerError(String message, Level level, int begin, int end) {
    var span = _file.span(begin, end);
    _currentLibrary.messages.add(new MessageSummary(
        'AnalyzerError', level.name.toLowerCase(), span, message));
  }
}

/// Summary information computed by the DDC checker.
abstract class Summary {
  Map toJsonMap();

  void accept(SummaryVisitor visitor);
}

/// Summary for the entire program.
class GlobalSummary implements Summary {
  /// Summary from the system libaries.
  final Map<String, LibrarySummary> system = <String, LibrarySummary>{};

  /// Summary for libraries in packages.
  final Map<String, PackageSummary> packages = <String, PackageSummary>{};

  /// Summary for loose files
  // TODO(sigmund): consider inferring the package from the pubspec instead?
  final Map<String, LibrarySummary> loose = <String, LibrarySummary>{};

  GlobalSummary();

  Map toJsonMap() => {
    'system': system.values.map((l) => l.toJsonMap()).toList(),
    'packages': packages.values.map((p) => p.toJsonMap()).toList(),
    'loose': loose.values.map((l) => l.toJsonMap()).toList(),
  };

  void accept(SummaryVisitor visitor) => visitor.visitGlobal(this);

  static GlobalSummary parse(Map json) {
    var res = new GlobalSummary();
    json['system'].map(LibrarySummary.parse).forEach((l) {
      res.system[l.name] = l;
    });
    json['packages'].map(PackageSummary.parse).forEach((p) {
      res.packages[p.name] = p;
    });
    json['loose'].map(LibrarySummary.parse).forEach((l) {
      res.loose[l.name] = l;
    });
    return res;
  }
}

/// A summary of a package.
class PackageSummary implements Summary {
  final String name;
  final Map<String, LibrarySummary> libraries = <String, LibrarySummary>{};

  PackageSummary(this.name);

  Map toJsonMap() => {
    'package_name': name,
    'libraries': libraries.values.map((l) => l.toJsonMap()).toList(),
  };

  void accept(SummaryVisitor visitor) => visitor.visitPackage(this);

  static PackageSummary parse(Map json) {
    var res = new PackageSummary(json['package_name']);
    json['libraries'].map(LibrarySummary.parse).forEach((l) {
      res.libraries[l.name] = l;
    });
    return res;
  }
}

/// A summary at the level of a library.
class LibrarySummary implements Summary {
  /// Name of the library.
  final String name;

  /// All messages collected for the library.
  final List<MessageSummary> messages;

  /// Total lines of code (including all parts of the library).
  int lines;

  LibrarySummary(this.name, [List<MessageSummary> messages, this.lines = 0])
      : messages = messages == null ? <MessageSummary>[] : messages;

  Map toJsonMap() => {
    'library_name': name,
    'messages': messages.map((m) => m.toJsonMap()).toList(),
    'lines': lines,
  };

  void accept(SummaryVisitor visitor) => visitor.visitLibrary(this);

  static LibrarySummary parse(Map json) => new LibrarySummary(
      json['library_name'], json['messages'].map(MessageSummary.parse).toList(),
      json['lines']);
}

/// A single message produced by the checker.
class MessageSummary implements Summary {
  /// The kind of message, currently the name of the StaticInfo type.
  final String kind;

  /// Level (error, warning, etc).
  final String level;

  /// Location where the error is reported.
  final SourceSpan span;
  final String message;

  MessageSummary(this.kind, this.level, this.span, this.message);

  Map toJsonMap() => {
    'kind': kind,
    'level': level,
    'message': message,
    'url': '${span.sourceUrl}',
    'start': span.start.offset,
    'end': span.end.offset,
    'text': span.text,
  };

  void accept(SummaryVisitor visitor) => visitor.visitMessage(this);

  static MessageSummary parse(Map json) {
    var start = new SourceLocation(json['start'], sourceUrl: json['url']);
    var end = new SourceLocation(json['end'], sourceUrl: json['url']);
    var span = new SourceSpanBase(start, end, json['text']);
    return new MessageSummary(
        json['kind'], json['level'], span, json['message']);
  }
}

/// A visitor of the [Summary] hierarchy.
abstract class SummaryVisitor {
  void visitGlobal(GlobalSummary global);
  void visitPackage(PackageSummary package);
  void visitLibrary(LibrarySummary lib);
  void visitMessage(MessageSummary message);
}

/// A recursive [SummaryVisitor] that visits summaries on a top-down fashion.
class RecursiveSummaryVisitor implements SummaryVisitor {
  void visitGlobal(GlobalSummary global) {
    for (var lib in global.system.values) {
      lib.accept(this);
    }
    for (var package in global.packages.values) {
      package.accept(this);
    }
    for (var lib in global.loose.values) {
      lib.accept(this);
    }
  }

  void visitPackage(PackageSummary package) {
    for (var lib in package.libraries.values) {
      lib.accept(this);
    }
  }
  void visitLibrary(LibrarySummary lib) {
    for (var msg in lib.messages) {
      msg.accept(this);
    }
  }
  void visitMessage(MessageSummary message) {}
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

/// Returns a [SourceSpan] in [file] for the offsets of [node].
// TODO(sigmund): convert to use span information from AST (issue #73)
SourceSpan _spanForNode(SourceFile file, AstNode node) {
  final begin = node is AnnotatedNode
      ? node.firstTokenAfterCommentAndMetadata.offset
      : node.offset;
  return file.span(begin, node.end);
}
