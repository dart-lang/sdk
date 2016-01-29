// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;
import 'dart:convert' show HTML_ESCAPE;
import 'dart:io';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart' as yaml;

import '../../devc.dart';
import '../options.dart';
import '../report.dart';
import '../summary.dart';
import 'html_gen.dart';

/// Generate a compilation summary using the [Primer](http://primercss.io) css.
class HtmlReporter implements AnalysisErrorListener {
  final AnalysisContext context;
  SummaryReporter reporter;
  List<AnalysisError> errors = [];

  HtmlReporter(this.context) {
    reporter = new SummaryReporter(context);
  }

  void onError(AnalysisError error) {
    try {
      reporter.onError(error);
    } catch (e, st) {
      // TODO: This can fail when extracting context spans.
      print('${e}:${st}');
    }

    errors.add(error);
  }

  void finish(CompilerOptions options) {
    GlobalSummary result = reporter.result;

    // Find all referenced packages - both those with and without issues.
    List<String> allPackages = context.sources
        .where((s) => s.uriKind == UriKind.PACKAGE_URI)
        .map((s) => s.uri.pathSegments.first)
        .toSet()
        .toList();

    String input = options.inputs.first;
    List<SummaryInfo> summaries = [];

    // Hoist the self-ref package to an `Application` category.
    String packageName = _getPackageName();
    if (result.packages.containsKey(packageName)) {
      PackageSummary summary = result.packages[packageName];
      List<MessageSummary> issues = summary.libraries.values
          .expand((LibrarySummary l) => l.messages)
          .toList();
      summaries.add(new SummaryInfo(
          'Application code', packageName, 'package:${packageName}', issues));
    }

    // package: code
    List<String> keys = result.packages.keys.toList();
    allPackages.forEach((name) {
      if (!keys.contains(name)) keys.add(name);
    });
    keys.sort();

    for (String name in keys) {
      if (name == packageName) continue;

      PackageSummary summary = result.packages[name];

      if (summary == null) {
        summaries.add(new SummaryInfo('Package: code', name));
      } else {
        List<MessageSummary> issues = summary.libraries.values
            .expand((LibrarySummary summary) => summary.messages)
            .toList();
        summaries.add(
            new SummaryInfo('Package: code', name, 'package:${name}', issues));
      }
    }

    // dart: code
    keys = result.system.keys.toList()..sort();
    for (String name in keys) {
      LibrarySummary summary = result.system[name];
      if (summary.messages.isNotEmpty) {
        summaries.add(new SummaryInfo(
            'Dart: code', name, 'dart:${name}', summary.messages));
      }
    }

    // Loose files
    if (result.loose.isNotEmpty) {
      List<MessageSummary> issues = result.loose.values
          .expand((IndividualSummary summary) => summary.messages)
          .toList();
      summaries.add(new SummaryInfo('Files', 'files', 'files', issues));
    }

    // Write the html report.
    var page = new Page(input, input, summaries);
    var outPath = '${input.replaceAll('.', '_')}_results.html';
    var link = outPath;
    if (options.serverMode) {
      var base = path.basename(outPath);
      outPath = path.join(options.codegenOptions.outputDir, base);
      link = 'http://${options.host}:${options.port}/$base';
    }
    new File(outPath).writeAsStringSync(page.create());
    print('Compilation report available at ${link}; ${errors.length} issues.');
  }

  String _getPackageName() {
    File file = new File('pubspec.yaml');
    if (file.existsSync()) {
      var doc = yaml.loadYaml(file.readAsStringSync());
      return doc['name'];
    } else {
      return null;
    }
  }
}

class SummaryInfo {
  static int _compareIssues(MessageSummary a, MessageSummary b) {
    int result = _compareSeverity(a.level, b.level);
    if (result != 0) return result;
    result = a.span.sourceUrl.toString().compareTo(b.span.sourceUrl.toString());
    if (result != 0) return result;
    return a.span.start.compareTo(b.span.start);
  }

  static const _sevTable = const {'error': 0, 'warning': 1, 'info': 2};

  static int _compareSeverity(String a, String b) =>
      _sevTable[a] - _sevTable[b];

  final String category;
  final String shortTitle;
  final String longTitle;
  final List<MessageSummary> issues;

  SummaryInfo(this.category, this.shortTitle, [this.longTitle, this.issues]) {
    issues?.sort(_compareIssues);
  }

  String get ref => longTitle == null ? null : longTitle.replaceAll(':', '_');

  int get errorCount =>
      issues == null ? 0 : issues.where((i) => i.level == 'error').length;
  int get warningCount =>
      issues == null ? 0 : issues.where((i) => i.level == 'warning').length;
  int get infoCount =>
      issues == null ? 0 : issues.where((i) => i.level == 'info').length;

  bool get hasIssues => issues == null ? false : issues.isNotEmpty;
}

class Page extends HtmlGen {
  final String pageTitle;
  final String inputFile;
  final List<SummaryInfo> summaries;

  Page(this.pageTitle, this.inputFile, this.summaries);

  String get subTitle => 'DDC compilation report for ${inputFile}';

  String create() {
    start(
        title: 'DDC ${pageTitle}',
        theme: 'http://primercss.io/docs.css',
        inlineStyle: _css);

    header();
    startTag('div', c: "container");
    startTag('div', c: "columns docs-layout");

    startTag('div', c: "column one-fourth");
    nav();
    endTag();

    startTag('div', c: "column three-fourths");
    subtitle();
    contents();
    endTag();

    endTag();
    footer();
    endTag();
    end();

    return toString();
  }

  void header() {
    startTag('header', c: "masthead");
    startTag('div', c: "container");
    title();
    startTag('nav', c: "masthead-nav");
    tag("a",
        href:
            "https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md",
        text: "Strong Mode");
    tag("a",
        href: "https://github.com/dart-lang/dev_compiler", text: "DDC Repo");
    endTag();
    endTag();
    endTag();
  }

  void title() {
    tag("a", c: "masthead-logo", text: pageTitle);
  }

  void subtitle() {
    tag("h1", text: subTitle, c: "page-title");
  }

  void contents() {
    int errorCount = summaries.fold(
        0, (int count, SummaryInfo info) => count + info.errorCount);
    int warningCount = summaries.fold(
        0, (int count, SummaryInfo info) => count + info.warningCount);
    int infoCount = summaries.fold(
        0, (int count, SummaryInfo info) => count + info.infoCount);

    List<String> messages = [];

    if (errorCount > 0) {
      messages.add("${_comma(errorCount)} ${_pluralize(errorCount, 'error')}");
    }
    if (warningCount > 0) {
      messages.add(
          "${_comma(warningCount)} ${_pluralize(warningCount, 'warning')}");
    }
    if (infoCount > 0) {
      messages.add("${_comma(infoCount)} ${_pluralize(infoCount, 'info')}");
    }

    String message;

    if (messages.isEmpty) {
      message = 'no issues';
    } else if (messages.length == 2) {
      message = messages.join(' and ');
    } else {
      message = messages.join(', ');
    }

    tag("p", text: 'Found ${message}.');

    for (SummaryInfo info in summaries) {
      if (!info.hasIssues) continue;

      tag("h2", text: info.longTitle, attributes: "id=${info.ref}");
      contentItem(info);
    }
  }

  void nav() {
    startTag("nav", c: "menu docs-menu");
    Iterable<String> categories =
        new LinkedHashSet.from(summaries.map((s) => s.category));
    for (String category in categories) {
      navItems(category, summaries.where((s) => s.category == category));
    }
    endTag();
  }

  void navItems(String category, List<SummaryInfo> infos) {
    if (infos.isEmpty) return;

    span(c: "menu-heading", text: category);

    for (SummaryInfo info in infos) {
      if (info.hasIssues) {
        startTag("a", c: "menu-item", attributes: 'href="#${info.ref}"');

        span(text: info.shortTitle);

        int errorCount = info.errorCount;
        int warningCount = info.warningCount;
        int infoCount = info.infoCount;

        if (infoCount > 0) {
          span(c: "counter info", text: '${_comma(infoCount)}');
        }
        if (warningCount > 0) {
          span(c: "counter warning", text: '${_comma(warningCount)}');
        }
        if (errorCount > 0) {
          span(c: "counter error", text: '${_comma(errorCount)}');
        }

        endTag();
      } else {
        tag("div", c: "menu-item", text: info.shortTitle);
      }
    }
  }

  void footer() {
    startTag('footer', c: "footer");
    writeln("${inputFile} • DDC version ${devCompilerVersion}");
    endTag();
  }

  void contentItem(SummaryInfo info) {
    int errors = info.errorCount;
    int warnings = info.warningCount;
    int infos = info.infoCount;

    if (errors > 0) {
      span(
          c: 'counter error',
          text: '${_comma(errors)} ${_pluralize(errors, 'error')}');
    }
    if (warnings > 0) {
      span(
          c: 'counter warning',
          text: '${_comma(warnings)} ${_pluralize(warnings, 'warning')}');
    }
    if (infos > 0) {
      span(
          c: 'counter info',
          text: '${_comma(infos)} ${_pluralize(infos, 'info')}');
    }

    info.issues.forEach(emitMessage);
  }

  void emitMessage(MessageSummary issue) {
    startTag('div', c: 'file');
    startTag('div', c: 'file-header');
    span(c: 'counter ${issue.level}', text: issue.kind);
    span(c: 'file-info', text: issue.span.sourceUrl.toString());
    endTag();

    startTag('div', c: 'blob-wrapper');
    startTag('table');
    startTag('tbody');

    // TODO: Widen the line extracts - +2 on either side.
    // TODO: Highlight error ranges.
    if (issue.span is SourceSpanWithContext) {
      SourceSpanWithContext context = issue.span;
      String text = context.context.trimRight();
      int lineNum = context.start.line;

      for (String line in text.split('\n')) {
        lineNum++;
        startTag('tr');
        tag('td', c: 'blob-num', text: lineNum.toString());
        tag('td',
            c: 'blob-code blob-code-inner', text: HTML_ESCAPE.convert(line));
        endTag();
      }
    }

    startTag('tr', c: 'row-expandable');
    tag('td', c: 'blob-num blob-num-expandable');
    tag('td',
        c: 'blob-code blob-code-expandable',
        text: HTML_ESCAPE.convert(issue.message));
    endTag();

    endTag();
    endTag();
    endTag();

    endTag();
  }
}

String _pluralize(int count, String item) => count == 1 ? item : '${item}s';

String _comma(int count) {
  String str = '${count}';
  if (str.length <= 3) return str;
  int pos = str.length - 3;
  return str.substring(0, pos) + ',' + str.substring(pos);
}

/// Deltas from the baseline Primer css (http://primercss.io/docs.css).
const String _css = '''
h2 {
  margin-top: 2em;
  padding-bottom: 0.3em;
  font-size: 1.75em;
  line-height: 1.225;
  border-bottom: 1px solid #eee;
}

.error {
  background-color: #bf1515;
}

.menu-item .counter {
  margin-bottom: 0;
}

.counter.error {
  color: #eee;
  text-shadow: none;
}

.warning {
  background-color: #ffe5a7;
}

.counter.warning {
  color: #777;
}

.counter.error,
.counter.warning,
.counter.info {
  margin-bottom: 0;
}

nav.menu .menu-item {
  overflow-x: auto;
}

.info {
  background-color: #eee;
}

/* code snippets styles */

.file {
  position: relative;
  margin-top: 20px;
  margin-bottom: 15px;
  border: 1px solid #ddd;
  border-radius: 3px;
}

.file-header {
  padding: 5px 10px;
  background-color: #f7f7f7;
  border-bottom: 1px solid #d8d8d8;
  border-top-left-radius: 2px;
  border-top-right-radius: 2px;
}

.file-info {
  font-size: 12px;
  font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
}

table {
  border-collapse: collapse;
  border-spacing: 0;
  margin-bottom: 0;
}

.blob-wrapper {
  overflow-x: auto;
  overflow-y: hidden;
}

.blob-num {
  width: 1%;
  min-width: 50px;
  white-space: nowrap;
  font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
  font-size: 12px;
  line-height: 18px;
  color: rgba(0,0,0,0.3);
  vertical-align: top;
  text-align: right;
  border: solid #eee;
  border-width: 0 1px 0 0;
  cursor: pointer;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  padding-left: 10px;
  padding-right: 10px;
}

.blob-code {
  padding-left: 10px;
  padding-right: 10px;
  vertical-align: top;
}

.blob-code-inner {
  font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
  font-size: 12px;
  color: #333;
  white-space: pre;
  overflow: visible;
  word-wrap: normal;
}

.row-expandable {
  border-top: 1px solid #d8d8d8;
  border-bottom-left-radius: 3px;
  border-bottom-right-radius: 3px;
}

.blob-num-expandable,
.blob-code-expandable {
  vertical-align: middle;
  font-size: 14px;
  border-color: #d2dff0;
}

.blob-num-expandable {
  background-color: #edf2f9;
  border-bottom-left-radius: 3px;
}

.blob-code-expandable {
  padding-top: 4px;
  padding-bottom: 4px;
  background-color: #f4f7fb;
  border-width: 1px 0;
  border-bottom-right-radius: 3px;
}
''';
