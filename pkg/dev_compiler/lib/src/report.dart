/// Summarizes the information produced by the checker.
library ddc.src.report;

import 'dart:math' show max;

import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';

import 'info.dart';
import 'utils.dart';

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
  final String name;
  final List<MessageSummary> messages;

  LibrarySummary(this.name, this.messages);

  Map toJsonMap() => {
    'library_name': name,
    'messages': messages.map((m) => m.toJsonMap()).toList(),
  };

  void accept(SummaryVisitor visitor) => visitor.visitLibrary(this);

  static LibrarySummary parse(Map json) =>
      new LibrarySummary(json['library_name'], json['messages']
          .map(MessageSummary.parse)
          .toList());
}

/// A single message produced by the checker.
class MessageSummary implements Summary {
  /// The kind of message, currently the name of the StaticInfo type.
  final String kind;

  /// Level (error, warning, etc).
  final String level;

  /// Location where the error is reported.
  final SourceSpan span;

  MessageSummary(this.kind, this.level, this.span);

  Map toJsonMap() => {
    'kind': kind,
    'level': level,
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
    return new MessageSummary(json['kind'], json['level'], span);
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

/// Converts results from the checker into a [Summary].
GlobalSummary checkerResultsToSummary(CheckerResults results) {
  var res = new GlobalSummary();
  for (var lib in results.libraries) {
    var libSummary = new LibrarySummary(
        lib.name, lib.nodeInfo.values.expand(_convertInfos).toList());

    var uri = lib.library.source.uri;
    if (uri.scheme == 'package') {
      var pname = path.split(uri.path)[0];
      res.packages.putIfAbsent(pname, () => new PackageSummary(pname));
      if (res.packages[pname].libraries[lib.name] != null) {
        print('ERROR: duplicate ${lib.name}');
      }
      res.packages[pname].libraries[lib.name] = libSummary;
    } else if (uri.scheme == 'dart') {
      if (res.system[lib.name] != null) print('ERROR: duplicate ${lib.name}');
      res.system[lib.name] = libSummary;
    } else {
      if (res.loose[lib.name] != null) print('ERROR: duplicate ${lib.name}');
      res.loose[lib.name] = libSummary;
    }
  }
  return res;
}

// Internal helper to convert a [SemanticNode] to a list of [MessageSummary]s.
List<MesageSummary> _convertInfos(SemanticNode semanticNode) {
  var res = <MessageSummary>[];
  var span = spanForNode(semanticNode.node);
  for (var info in semanticNode.messages) {
    res.add(new MessageSummary('${info.runtimeType}', info.level.name
        .toLowerCase(), span));
  }
  return res;
}

/// Produces a string representation of the summary.
String summaryToString(GlobalSummary summary) {
  var counter = new _Counter();
  summary.accept(counter);

  var typeMap = {};
  for (var type in infoTypes) {
    var id = '$type'.replaceAll(new RegExp('[a-z]'), '');
    while (typeMap[id] != null) id = "$id'";
    typeMap[id] = type;
  }

  var header = ['package']..addAll(typeMap.keys);
  var rows = [header];
  int nameColumnWidth = 10;
  int numberColumnWidth = 5;
  appendName(row, name) {
    row.add(name);
    nameColumnWidth = max(nameColumnWidth, name.length);
  }
  appendCount(row, count) {
    if (count == null) count = 0;
    row.add(count);
    if (count > 9999) {
      numberColumnWidth = max(numberColumnWidth, '$count'.length);
    }
  }

  for (var package in counter.errorCount.keys) {
    var row = [];
    appendName(row, package);
    for (var type in infoTypes) {
      appendCount(row, counter.errorCount[package]['$type']);
    }
    rows.add(row);
  }

  var totals = ['total'];
  for (var type in infoTypes) {
    appendCount(totals, counter.totals['$type']);
  }
  rows.add(totals);

  var sb = new StringBuffer();
  sb.write('\n');
  for (var row in rows) {
    var first = true;
    for (var column in row) {
      if (first) {
        sb.write('$column'.padRight(nameColumnWidth));
        first = false;
      } else {
        sb.write(' $column'.padLeft(numberColumnWidth));
      }
    }
    sb.write('\n');
  }
  sb.write('\nWhere:\n');
  for (var id in typeMap.keys) {
    sb.write('  $id:'.padRight(7));
    sb.write(' ${typeMap[id]}\n');
  }
  return sb.toString();
}

/// An example visitor that counts the number of errors per package and total.
class _Counter extends RecursiveSummaryVisitor {
  String currentPackage;
  var sb = new StringBuffer();
  Map<String, Map<String, int>> errorCount = <String, Map<String, int>>{};
  Map<String, int> totals = <String, int>{};

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
    currentPackage = package.name;
    super.visitPackage(package);
    currentPackage = null;
  }

  void visitLibrary(LibrarySummary lib) {
    super.visitLibrary(lib);
  }

  visitMessage(MessageSummary message) {
    addTo(currentPackage != null ? currentPackage : '*other*', message.kind);
  }

  addTo(String package, String kind) {
    errorCount.putIfAbsent(package, () => <String, int>{});
    errorCount[package].putIfAbsent(kind, () => 0);
    errorCount[package][kind]++;
    totals.putIfAbsent(kind, () => 0);
    totals[kind]++;
  }
}
