// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Summary of error messages produced by a `SummaryReporter`.

import 'dart:collection' show HashSet;

import 'package:source_span/source_span.dart';

/// Summary information computed by the DDC checker.
abstract class Summary {
  Map toJsonMap();

  void accept(SummaryVisitor visitor);
}

/// Summary for the entire program.
class GlobalSummary implements Summary {
  /// Summary from the system libraries.
  final Map<String, LibrarySummary> system = <String, LibrarySummary>{};

  /// Summary for libraries in packages.
  final Map<String, PackageSummary> packages = <String, PackageSummary>{};

  /// Summary for loose files
  // TODO(sigmund): consider inferring the package from the pubspec instead?
  final Map<String, IndividualSummary> loose = <String, IndividualSummary>{};

  GlobalSummary();

  Map toJsonMap() => {
        'system': system.values.map((l) => l.toJsonMap()).toList(),
        'packages': packages.values.map((p) => p.toJsonMap()).toList(),
        'loose': loose.values
            .map((l) => ['${l.runtimeType}', l.toJsonMap()])
            .toList(),
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
    json['loose'].forEach((e) {
      var summary = e[0] == 'LibrarySummary'
          ? LibrarySummary.parse(e[1])
          : HtmlSummary.parse(e[1]);
      res.loose[summary.name] = summary;
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

/// A summary for a library or an html file.
abstract class IndividualSummary extends Summary {
  /// Unique name for this library.
  String get name;

  List<MessageSummary> get messages;
}

/// A summary at the level of a library.
class LibrarySummary implements IndividualSummary {
  /// Unique name for this library.
  final String name;

  /// All messages collected for the library.
  final List<MessageSummary> messages;

  /// All parts of this library. Only used for computing _lines.
  final _uris = new HashSet<Uri>();

  int _lines;

  LibrarySummary(this.name, {List<MessageSummary> messages, lines})
      : messages = messages == null ? <MessageSummary>[] : messages,
        _lines = lines != null ? lines : 0;

  void clear() {
    _uris.clear();
    _lines = 0;
    messages.clear();
  }

  /// Total lines of code (including all parts of the library).
  int get lines => _lines;

  Map toJsonMap() => {
        'library_name': name,
        'messages': messages.map((m) => m.toJsonMap()).toList(),
        'lines': lines,
      };

  void recordSourceLines(Uri uri, int computeLines()) {
    if (_uris.add(uri)) {
      _lines += computeLines();
    }
  }

  void accept(SummaryVisitor visitor) => visitor.visitLibrary(this);

  static LibrarySummary parse(Map json) =>
      new LibrarySummary(json['library_name'],
          messages: new List<MessageSummary>.from(
              json['messages'].map(MessageSummary.parse)),
          lines: json['lines']);
}

/// A summary at the level of an HTML file.
class HtmlSummary implements IndividualSummary {
  /// Unique name used to identify the HTML file.
  final String name;

  /// All messages collected on the file.
  final List<MessageSummary> messages;

  HtmlSummary(this.name, [List<MessageSummary> messages])
      : messages = messages == null ? <MessageSummary>[] : messages;

  Map toJsonMap() =>
      {'name': name, 'messages': messages.map((m) => m.toJsonMap()).toList()};

  void accept(SummaryVisitor visitor) => visitor.visitHtml(this);

  static HtmlSummary parse(Map json) => new HtmlSummary(
      json['name'],
      new List<MessageSummary>.from(
          json['messages'].map(MessageSummary.parse)));
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
        'start': [span.start.offset, span.start.line, span.start.column],
        'end': [span.end.offset, span.end.line, span.end.column],
        'text': span.text,
        'context': span is SourceSpanWithContext
            ? (span as SourceSpanWithContext).context
            : null,
      };

  void accept(SummaryVisitor visitor) => visitor.visitMessage(this);

  static MessageSummary parse(Map json) {
    var start = new SourceLocation(json['start'][0],
        sourceUrl: json['url'],
        line: json['start'][1],
        column: json['start'][2]);
    var end = new SourceLocation(json['end'][0],
        sourceUrl: json['url'], line: json['end'][1], column: json['end'][2]);
    var context = json['context'];
    var span = context != null
        ? new SourceSpanWithContext(start, end, json['text'], context)
        : new SourceSpan(start, end, json['text']);
    return new MessageSummary(
        json['kind'], json['level'], span, json['message']);
  }
}

/// A visitor of the [Summary] hierarchy.
abstract class SummaryVisitor {
  void visitGlobal(GlobalSummary global);
  void visitPackage(PackageSummary package);
  void visitLibrary(LibrarySummary lib);
  void visitHtml(HtmlSummary html);
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
    for (var libOrHtml in global.loose.values) {
      libOrHtml.accept(this);
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

  void visitHtml(HtmlSummary html) {
    for (var msg in html.messages) {
      msg.accept(this);
    }
  }

  void visitMessage(MessageSummary message) {}
}
