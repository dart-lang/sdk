// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_diagnostic.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/server/http_server.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/ast_writer.dart';
import 'package:analysis_server/src/status/element_writer.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:path/path.dart' as pathPackage;

final String kCustomCss = '''
.lead, .page-title+.markdown-body>p:first-child {
  margin-bottom: 30px;
  font-size: 20px;
  font-weight: 300;
  color: #555;
}

.container {
  width: 1160px;
}

.masthead {
  padding-top: 1rem;
  padding-bottom: 1rem;
  margin-bottom: 1.5rem;
  text-align: center;
  background-color: #4078c0;
}

.masthead .masthead-logo {
  display: inline-block;
  font-size: 1.5rem;
  color: #fff;
  float: left;
}

.masthead .mega-octicon {
  font-size: 1.5rem;
}

.masthead-nav {
  float: right;
  margin-top: .5rem;
}

.masthead-nav a:not(:last-child) {
  margin-right: 1.25rem;
}

.masthead a {
  color: rgba(255,255,255,0.5);
  font-size: 1rem;
}

.masthead a:hover {
  color: #fff;
  text-decoration: none;
}

.masthead-nav .active {
  color: #fff;
  font-weight: 500;
}

.counter {
  display: inline-block;
  padding: 2px 5px;
  font-size: 11px;
  font-weight: bold;
  line-height: 1;
  color: #666;
  background-color: #eee;
  border-radius: 20px;
}

.menu-item .counter {
  float: right;
  margin-left: 5px;
}

td.right {
  text-align: right;
}

table td {
  max-width: 600px;
  vertical-align: text-top;
}

td.pre {
  white-space: pre;
}

.nowrap {
  white-space: nowrap;
}

.scroll-table {
  max-height: 190px;
  overflow-x: auto;
}

.footer {
  padding-top: 3rem;
  padding-bottom: 3rem;
  margin-top: 3rem;
  line-height: 1.75;
  color: #7a7a7a;
  border-top: 1px solid #eee;
}

.footer strong {
  color: #333;
}
''';

final bool _showLints = false;

String get _sdkVersion {
  String version = Platform.version;
  if (version.contains(' ')) {
    version = version.substring(0, version.indexOf(' '));
  }
  return version;
}

String writeOption(String name, dynamic value) {
  return '$name: <code>$value</code><br> ';
}

class AstPage extends DiagnosticPageWithNav {
  String _description;

  AstPage(DiagnosticsSite site)
      : super(site, 'ast', 'AST', description: 'The AST for a file.');

  @override
  String get description => _description ?? super.description;

  @override
  bool get showInNav => false;

  @override
  Future<Null> generateContent(Map<String, String> params) async {
    String path = params['file'];
    if (path == null) {
      p('No file path provided.');
      return;
    }
    AnalysisDriver driver = server.getAnalysisDriver(path);
    if (driver == null) {
      p('The file <code>${escape(path)}</code> is not being analyzed.',
          raw: true);
      return;
    }
    AnalysisResult result = await driver.getResult(path);
    if (result == null) {
      p(
          'An AST could not be produced for the file '
          '<code>${escape(path)}</code>.',
          raw: true);
      return;
    }

    AstWriter writer = new AstWriter(buf);
    result.unit.accept(writer);
  }

  @override
  Future<Null> generatePage(Map<String, String> params) async {
    try {
      _description = params['file'];
      await super.generatePage(params);
    } finally {
      _description = null;
    }
  }
}

class CommunicationsPage extends DiagnosticPageWithNav {
  CommunicationsPage(DiagnosticsSite site)
      : super(site, 'communications', 'Communications',
            description:
                'Latency statistics for analysis server communications.');

  @override
  void generateContent(Map<String, String> params) {
    void writeRow(List<String> data, {List<String> classes}) {
      buf.write("<tr>");
      for (int i = 0; i < data.length; i++) {
        String c = classes == null ? null : classes[i];
        if (c != null) {
          buf.write('<td class="$c">${escape(data[i])}</td>');
        } else {
          buf.write('<td>${escape(data[i])}</td>');
        }
      }
      buf.writeln("</tr>");
    }

    buf.writeln('<div class="columns">');

    ServerPerformance perf = server.performanceAfterStartup;
    if (perf != null) {
      buf.writeln('<div class="column one-half">');
      h3('Current');

      int requestCount = perf.requestCount;
      int averageLatency =
          requestCount > 0 ? (perf.requestLatency ~/ requestCount) : 0;
      int maximumLatency = perf.maxLatency;
      double slowRequestPercent =
          requestCount > 0 ? (perf.slowRequestCount / requestCount) : 0.0;

      buf.write('<table>');
      writeRow([printInteger(requestCount), 'requests'],
          classes: ["right", null]);
      writeRow([printMilliseconds(averageLatency), 'average latency'],
          classes: ["right", null]);
      writeRow([printMilliseconds(maximumLatency), 'maximum latency'],
          classes: ["right", null]);
      writeRow([printPercentage(slowRequestPercent), '> 150 ms latency'],
          classes: ["right", null]);
      buf.write('</table>');

      String time = server.uptime.toString();
      if (time.contains('.')) {
        time = time.substring(0, time.indexOf('.'));
      }
      buf.writeln(writeOption('Uptime', time));

      buf.write('</div>');
    }

    buf.writeln('<div class="column one-half">');
    h3('Startup');
    perf = server.performanceDuringStartup;

    int requestCount = perf.requestCount;
    int averageLatency =
        requestCount > 0 ? (perf.requestLatency ~/ requestCount) : 0;
    int maximumLatency = perf.maxLatency;
    double slowRequestPercent =
        requestCount > 0 ? (perf.slowRequestCount / requestCount) : 0.0;

    buf.write('<table>');
    writeRow([printInteger(requestCount), 'requests'],
        classes: ["right", null]);
    writeRow([printMilliseconds(averageLatency), 'average latency'],
        classes: ["right", null]);
    writeRow([printMilliseconds(maximumLatency), 'maximum latency'],
        classes: ["right", null]);
    writeRow([printPercentage(slowRequestPercent), '> 150 ms latency'],
        classes: ["right", null]);
    buf.write('</table>');

    if (server.performanceAfterStartup != null) {
      int startupTime =
          server.performanceAfterStartup.startTime - perf.startTime;
      buf.writeln(
          writeOption('Initial analysis time', printMilliseconds(startupTime)));
    }
    buf.write('</div>');

    buf.write('</div>');
  }
}

class CompletionPage extends DiagnosticPageWithNav {
  CompletionPage(DiagnosticsSite site)
      : super(site, 'completion', 'Code Completion',
            description: 'Latency statistics for code completion.');

  @override
  void generateContent(Map<String, String> params) {
    CompletionDomainHandler completionDomain = server.handlers
        .firstWhere((handler) => handler is CompletionDomainHandler);

    List<CompletionPerformance> completions =
        completionDomain.performanceList.items.toList();

    if (completions.isEmpty) {
      blankslate('No completions recorded.');
      return;
    }

    int fastCount =
        completions.where((c) => c.elapsedInMilliseconds <= 100).length;
    p('${completions.length} results; ${printPercentage(
        fastCount / completions.length)} within 100ms.');

    // draw a chart
    buf.writeln(
        '<div id="chart-div" style="width: 700px; height: 300px;"></div>');
    StringBuffer rowData = new StringBuffer();
    for (int i = completions.length - 1; i >= 0; i--) {
      // [' ', 101.5]
      if (rowData.isNotEmpty) {
        rowData.write(',');
      }
      rowData.write("[' ', ${completions[i].elapsedInMilliseconds}]");
    }
    buf.writeln('''
      <script type="text/javascript">
      google.charts.load('current', {'packages':['bar']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Completions', 'Time'],
          $rowData
        ]);
        var options = { bars: 'vertical', vAxis: {format: 'decimal'}, height: 300 };
        var chart = new google.charts.Bar(document.getElementById('chart-div'));
        chart.draw(data, google.charts.Bar.convertOptions(options));
      }
      </script>
''');

    // emit the data as a table
    buf.writeln('<table>');
    buf.writeln(
        '<tr><th>Time</th><th>Results</th><th>Source</th><th>Snippet</th></tr>');
    for (CompletionPerformance completion in completions) {
      buf.writeln('<tr>'
          '<td class="pre right">${printMilliseconds(
          completion.elapsedInMilliseconds)}</td>'
          '<td class="right">${completion.suggestionCount}</td>'
          '<td>${escape(completion.source.shortName)}</td>'
          '<td><code>${escape(completion.snippet)}</code></td>'
          '</tr>');
    }
    buf.writeln('</table>');
  }
}

class ContextsPage extends DiagnosticPageWithNav {
  ContextsPage(DiagnosticsSite site)
      : super(site, 'contexts', 'Contexts',
            description:
                'An analysis context defines the options and the set of sources being analyzed.');

  String get navDetail => printInteger(server.driverMap.length);

  String describe(AnalysisOptionsImpl options) {
    StringBuffer b = new StringBuffer();

    b.write(
        writeOption('Analyze function bodies', options.analyzeFunctionBodies));
    b.write(writeOption('Enable super mixins', options.enableSuperMixins));
    b.write(writeOption('Generate dart2js hints', options.dart2jsHint));
    b.write(writeOption(
        'Generate errors in implicit files', options.generateImplicitErrors));
    b.write(
        writeOption('Generate errors in SDK files', options.generateSdkErrors));
    b.write(writeOption('Generate hints', options.hint));
    b.write(writeOption('Preserve comments', options.preserveComments));
    b.write(writeOption('Strong mode', options.strongMode));
    b.write(writeOption('Strong mode hints', options.strongModeHints));

    return b.toString();
  }

  @override
  void generateContent(Map<String, String> params) {
    Map<Folder, AnalysisDriver> driverMap = server.driverMap;
    if (driverMap.isEmpty) {
      blankslate('No contexts.');
      return;
    }

    String contextPath = params['context'];
    List<Folder> folders = driverMap.keys.toList();
    folders
        .sort((first, second) => first.shortName.compareTo(second.shortName));
    Folder folder =
        folders.firstWhere((f) => f.path == contextPath, orElse: () => null);

    if (folder == null) {
      folder = folders.first;
      contextPath = folder.path;
    }

    AnalysisDriver driver = driverMap[folder];

    buf.writeln('<div class="tabnav">');
    buf.writeln('<nav class="tabnav-tabs">');
    for (Folder f in folders) {
      if (f == folder) {
        buf.writeln(
            '<a class="tabnav-tab selected">${escape(f.shortName)}</a>');
      } else {
        String p = '$path?context=${Uri.encodeQueryComponent(f.path)}';
        buf.writeln(
            '<a href="$p" class="tabnav-tab">${escape(f.shortName)}</a>');
      }
    }
    buf.writeln('</nav>');
    buf.writeln('</div>');

    buf.writeln(writeOption('Context location', escape(contextPath)));
    buf.writeln(writeOption('Analysis options path',
        escape(driver.contextRoot.optionsFilePath ?? 'none')));

    buf.writeln('<div class="columns">');

    buf.writeln('<div class="column one-half">');
    h3('Analysis options');
    p(describe(driver.analysisOptions), raw: true);
    buf.writeln(
        writeOption('Has .packages file', folder.getChild('.packages').exists));
    buf.writeln(writeOption(
        'Has pubspec.yaml file', folder.getChild('pubspec.yaml').exists));
    buf.writeln('</div>');

    buf.writeln('<div class="column one-half">');
    DartSdk sdk = driver?.sourceFactory?.dartSdk;
    AnalysisOptionsImpl sdkOptions = sdk?.context?.analysisOptions;
    if (sdkOptions != null) {
      h3('SDK analysis options');
      p(describe(sdkOptions), raw: true);

      if (sdk is FolderBasedDartSdk) {
        p(writeOption('Use summaries', sdk.useSummary), raw: true);
      }
    }
    buf.writeln('</div>');

    buf.writeln('</div>');

    h3('Lints');
    p(driver.analysisOptions.lintRules.map((l) => l.name).join(', '));

    h3('Error processors');
    p(driver.analysisOptions.errorProcessors
        .map((e) => e.description)
        .join(', '));

    h3('Plugins');
    p(driver.analysisOptions.enabledPluginNames.join(', '));

    List<String> priorityFiles = driver.priorityFiles;
    List<String> addedFiles = driver.addedFiles.toList();
    List<String> implicitFiles =
        driver.knownFiles.difference(driver.addedFiles).toList();
    addedFiles.sort();
    implicitFiles.sort();

    String lenCounter(List list) {
      return '<span class="counter" style="float: right;">${list
          .length}</span>';
    }

    h3('Context files');

    void writeFile(String file) {
      String astPath = '/ast?file=${Uri.encodeQueryComponent(file)}';
      String elementPath = '/element?file=${Uri.encodeQueryComponent(file)}';

      buf.write(file);
      buf.writeln(' <a href="$astPath">ast</a>');
      buf.write(' ');
      buf.writeln('<a href="$elementPath">element</a>');
    }

    h4('Priority files ${lenCounter(priorityFiles)}', raw: true);
    ul(priorityFiles, writeFile, classes: 'scroll-table');

    h4('Added files ${lenCounter(addedFiles)}', raw: true);
    ul(addedFiles, writeFile, classes: 'scroll-table');

    h4('Implicit files ${lenCounter(implicitFiles)}', raw: true);
    ul(implicitFiles, writeFile, classes: 'scroll-table');

    SourceFactory sourceFactory = driver.sourceFactory;
    if (sourceFactory is SourceFactoryImpl) {
      h3('Resolvers');
      for (UriResolver resolver in sourceFactory.resolvers) {
        h4(resolver.runtimeType.toString());
        buf.write('<p class="scroll-table">');
        if (resolver is DartUriResolver) {
          DartSdk sdk = resolver.dartSdk;
          buf.write(' (sdk = ');
          buf.write(sdk.runtimeType);
          if (sdk is FolderBasedDartSdk) {
            buf.write(' (path = ');
            buf.write(sdk.directory.path);
            buf.write(')');
          } else if (sdk is EmbedderSdk) {
            buf.write(' (map = ');
            writeMap(sdk.urlMappings);
            buf.write(')');
          }
          buf.write(')');
        } else if (resolver is SdkExtUriResolver) {
          buf.write(' (map = ');
          writeMap(resolver.urlMappings);
          buf.write(')');
        } else if (resolver is PackageMapUriResolver) {
          writeMap(resolver.packageMap);
        }
        buf.write('</p>');
      }
    }
  }

  void writeList<E>(List<E> list) {
    buf.writeln('[${list.join(', ')}]');
  }

  void writeMap<V>(Map<String, V> map) {
    List<String> keys = map.keys.toList();
    keys.sort();
    int length = keys.length;
    buf.write('{');
    for (int i = 0; i < length; i++) {
      buf.write('<br>');
      String key = keys[i];
      V value = map[key];
      buf.write(key);
      buf.write(' = ');
      if (value is List) {
        writeList(value);
      } else {
        buf.write(value);
      }
      buf.write(',');
    }
    buf.write('<br>}');
  }
}

/// A page with a proscriptive notion of layout.
abstract class DiagnosticPage extends Page {
  final Site site;

  DiagnosticPage(this.site, String id, String title, {String description})
      : super(id, title, description: description);

  bool get isNavPage => false;

  AnalysisServer get server =>
      (site as DiagnosticsSite).socketServer.analysisServer;

  Future<Null> generateContainer(Map<String, String> params) async {
    buf.writeln('<div class="columns docs-layout">');
    buf.writeln('<div class="three-fourths column markdown-body">');
    h1(title, classes: 'page-title');
    await asyncDiv(() async {
      p(description);
      await generateContent(params);
    }, classes: 'markdown-body');
    buf.writeln('</div>');
    buf.writeln('</div>');
  }

  void generateContent(Map<String, String> params);

  void generateFooter() {
    buf.writeln('''
    <footer class="footer">
      Dart ${site.title} <span style="float:right">SDK $_sdkVersion</span>
    </footer>
''');
  }

  void generateHeader() {
    buf.writeln('''
    <header class="masthead">
    <div class="container">
      <span class="masthead-logo">
      <span class="mega-octicon octicon-dashboard"></span>
        ${site.title} Diagnostics
      </span>

      <nav class="masthead-nav">
        <a href="/status" ${isNavPage ? ' class="active"' : ''}>Diagnostics</a>
        <a href="/feedback" ${isCurrentPage('/feedback')
        ? ' class="active"'
        : ''}>Feedback</a>
        <a href="https://www.dartlang.org/tools/analyzer" target="_blank">Docs</a>
        <a href="https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/doc/api.html" target="_blank">Spec</a>
      </nav>
    </div>
    </header>
''');
  }

  Future<Null> generatePage(Map<String, String> params) async {
    buf.writeln('<!DOCTYPE html><html lang="en">');
    buf.write('<head>');
    buf.write('<meta charset="utf-8">');
    buf.write('<meta name="viewport" content="width=device-width, '
        'initial-scale=1.0">');
    buf.writeln('<title>${site.title}</title>');
    buf.writeln('<link rel="stylesheet" '
        'href="https://cdnjs.cloudflare.com/ajax/libs/Primer/6.0.0/build.css">');
    buf.writeln('<link rel="stylesheet" '
        'href="https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/font/octicons.css">');
    buf.writeln('<script type="text/javascript" '
        'src="https://www.gstatic.com/charts/loader.js"></script>');
    buf.writeln('<style>${site.customCss}</style>');
    buf.writeln('</head>');

    buf.writeln('<body>');
    generateHeader();
    buf.writeln('<div class="container">');
    await generateContainer(params);
    generateFooter();
    buf.writeln('</div>'); // div.container
    buf.writeln('</body>');
    buf.writeln('</html>');
  }
}

abstract class DiagnosticPageWithNav extends DiagnosticPage {
  DiagnosticPageWithNav(Site site, String id, String title,
      {String description})
      : super(site, id, title, description: description);

  bool get isNavPage => true;

  String get navDetail => null;

  bool get showInNav => true;

  Future<Null> generateContainer(Map<String, String> params) async {
    buf.writeln('<div class="columns docs-layout">');

    bool shouldShowInNav(Page page) {
      return page is DiagnosticPageWithNav && page.showInNav;
    }

    buf.writeln('<div class="one-fifth column">');
    buf.writeln('<nav class="menu docs-menu">');
    for (Page page in site.pages.where(shouldShowInNav)) {
      buf.write('<a class="menu-item ${page == this ? ' selected' : ''}" '
          'href="${page.path}">${escape(page.title)}');
      String detail = (page as DiagnosticPageWithNav).navDetail;
      if (detail != null) {
        buf.write('<span class="counter">$detail</span>');
      }
      buf.writeln('</a>');
    }
    buf.writeln('</nav>');
    buf.writeln('</div>');

    buf.writeln('<div class="four-fifths column markdown-body">');
    h1(title, classes: 'page-title');
    await asyncDiv(() async {
      p(description);
      await generateContent(params);
    }, classes: 'markdown-body');
    buf.writeln('</div>');

    buf.writeln('</div>');
  }
}

class DiagnosticsSite extends Site implements AbstractGetHandler {
  /// An object that can handle either a WebSocket connection or a connection
  /// to the client over stdio.
  SocketServer socketServer;

  /// The last few lines printed.
  List<String> lastPrintedLines = <String>[];

  DiagnosticsSite(this.socketServer, this.lastPrintedLines)
      : super('Analysis Server') {
    pages.add(new CompletionPage(this));
    pages.add(new CommunicationsPage(this));
    pages.add(new ContextsPage(this));
    pages.add(new EnvironmentVariablesPage(this));
    pages.add(new ExceptionsPage(this));
    pages.add(new InstrumentationPage(this));
    pages.add(new OverlaysPage(this));
    pages.add(new PluginsPage(this));
    pages.add(new ProfilePage(this));
    pages.add(new SubscriptionsPage(this));

    ProcessProfiler profiler = ProcessProfiler.getProfilerForPlatform();
    if (profiler != null) {
      pages.add(new MemoryAndCpuPage(this, profiler));
    }

    pages.sort(((Page a, Page b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase())));

    // Add the status page at the beginning.
    pages.insert(0, new StatusPage(this));

    // Add non-nav pages.
    pages.add(new FeedbackPage(this));
    pages.add(new AstPage(this));
    pages.add(new ElementModelPage(this));
  }

  String get customCss => kCustomCss;

  Page createExceptionPage(String message, StackTrace trace) =>
      new ExceptionPage(this, message, trace);

  Page createUnknownPage(String unknownPath) =>
      new NotFoundPage(this, unknownPath);
}

class ElementModelPage extends DiagnosticPageWithNav {
  String _description;

  ElementModelPage(DiagnosticsSite site)
      : super(site, 'element', 'Element model',
            description: 'The element model for a file.');

  @override
  String get description => _description ?? super.description;

  @override
  bool get showInNav => false;

  @override
  Future<Null> generateContent(Map<String, String> params) async {
    String path = params['file'];
    if (path == null) {
      p('No file path provided.');
      return;
    }
    AnalysisDriver driver = server.getAnalysisDriver(path);
    if (driver == null) {
      p('The file <code>${escape(path)}</code> is not being analyzed.',
          raw: true);
      return;
    }
    AnalysisResult result = await driver.getResult(path);
    if (result == null) {
      p(
          'An element model could not be produced for the file '
          '<code>${escape(path)}</code>.',
          raw: true);
      return;
    }

    ElementWriter writer = new ElementWriter(buf);
    result.unit.element.accept(writer);
  }

  @override
  Future<Null> generatePage(Map<String, String> params) async {
    try {
      _description = params['file'];
      await super.generatePage(params);
    } finally {
      _description = null;
    }
  }
}

class EnvironmentVariablesPage extends DiagnosticPageWithNav {
  EnvironmentVariablesPage(DiagnosticsSite site)
      : super(site, 'environment', 'Environment Variables',
            description:
                'System environment variables as seen from the analysis server.');

  @override
  void generateContent(Map<String, String> params) {
    buf.writeln('<table>');
    buf.writeln('<tr><th>Variable</th><th>Value</th></tr>');
    for (String key in Platform.environment.keys.toList()..sort()) {
      String value = Platform.environment[key];
      buf.writeln('<tr><td>${escape(key)}</td><td>${escape(value)}</td></tr>');
    }
    buf.writeln('</table>');
  }
}

class ExceptionPage extends DiagnosticPage {
  final StackTrace trace;

  ExceptionPage(Site site, String message, this.trace)
      : super(site, '', '500 Oops', description: message);

  void generateContent(Map<String, String> params) {
    p(trace.toString(), style: 'white-space: pre');
  }
}

class ExceptionsPage extends DiagnosticPageWithNav {
  ExceptionsPage(DiagnosticsSite site)
      : super(site, 'exceptions', 'Exceptions',
            description: 'Exceptions from the analysis server.');

  Iterable<ServerException> get exceptions => server.exceptions.items;

  String get navDetail => printInteger(exceptions.length);

  @override
  void generateContent(Map<String, String> params) {
    if (exceptions.isEmpty) {
      blankslate('No exceptions encountered!');
    } else {
      for (ServerException ex in exceptions) {
        h3('Exception ${ex.exception}');
        p('${escape(ex.message)}<br>${writeOption('fatal', ex.fatal)}',
            raw: true);
        pre(() {
          buf.writeln('<code>${escape(ex.stackTrace.toString())}</code>');
        }, classes: "scroll-table");
      }
    }
  }
}

class FeedbackPage extends DiagnosticPage {
  FeedbackPage(DiagnosticsSite site)
      : super(site, 'feedback', 'Feedback',
            description: 'Providing feedback and filing issues.');

  @override
  void generateContent(Map<String, String> params) {
    final String issuesUrl = 'https://github.com/dart-lang/sdk/issues';
    p(
      'To file issues or feature requests, see our '
          '<a href="$issuesUrl">bug tracker</a>. When filing an issue, please describe:',
      raw: true,
    );
    ul([
      'what you were doing',
      'what occured',
      'what you think the expected behavior should have been',
    ], (line) => buf.writeln(line));

    List<String> ideInfo = [];
    if (server.options.clientId != null) {
      ideInfo.add(server.options.clientId);
    }
    if (server.options.clientVersion != null) {
      ideInfo.add(server.options.clientVersion);
    }
    String ideText = ideInfo.map((str) => '<code>$str</code>').join(', ');

    p('Other data to include:');
    ul([
      "the IDE you are using and it's version${ideText.isEmpty
          ? ''
          : ' ($ideText)'}",
      'the Dart SDK version (<code>${escape(_sdkVersion)}</code>)',
      'your operating system (<code>${escape(
          Platform.operatingSystem)}</code>)',
    ], (line) => buf.writeln(line));

    p('Thanks!');
  }
}

class InstrumentationPage extends DiagnosticPageWithNav {
  InstrumentationPage(DiagnosticsSite site)
      : super(site, 'instrumentation', 'Instrumentation',
            description:
                'Verbose instrumentation data from the analysis server.');

  @override
  void generateContent(Map<String, String> params) {
    p(
        'Instrumentation can be enabled by starting the analysis server with the '
        '<code>--instrumentation-log-file=path/to/file</code> flag.',
        raw: true);

    if (!AnalysisEngine.instance.instrumentationService.isActive) {
      blankslate('Instrumentation not active.');
      return;
    }

    h3('Instrumentation');

    p('Instrumentation active.');

    InstrumentationServer instrumentation =
        AnalysisEngine.instance.instrumentationService.instrumentationServer;
    String description = instrumentation.describe;
    HtmlEscape htmlEscape = new HtmlEscape(HtmlEscapeMode.ELEMENT);
    description = htmlEscape.convert(description);
    // Convert http(s): references to hyperlinks.
    final RegExp urlRegExp = new RegExp(r'[http|https]+:\/*(\S+)');
    description = description.replaceAllMapped(urlRegExp, (Match match) {
      return '<a href="${match.group(0)}">${match.group(1)}</a>';
    });
    p(description.replaceAll('\n', '<br>'), raw: true);
  }
}

class MemoryAndCpuPage extends DiagnosticPageWithNav {
  final ProcessProfiler profiler;

  MemoryAndCpuPage(DiagnosticsSite site, this.profiler)
      : super(site, 'memory', 'Memory and CPU Usage',
            description: 'Memory and CPU usage for the analysis server.');

  DiagnosticDomainHandler get diagnosticDomain {
    return server.handlers
        .firstWhere((handler) => handler is DiagnosticDomainHandler);
  }

  @override
  void generateContent(Map<String, String> params) {
    UsageInfo usage = profiler.getProcessUsageSync(pid);
    if (usage != null) {
      buf.writeln(
          writeOption('CPU', printPercentage(usage.cpuPercentage / 100.0)));
      buf.writeln(
          writeOption('Memory', '${printInteger(usage.memoryMB.round())} MB'));
    } else {
      p('Error retreiving the memory and cpu usage information.');
    }
  }
}

class NotFoundPage extends DiagnosticPage {
  final String path;

  NotFoundPage(Site site, this.path)
      : super(site, '', '404 Not found', description: "'$path' not found.");

  void generateContent(Map<String, String> params) {}
}

class OverlaysPage extends DiagnosticPageWithNav {
  OverlaysPage(DiagnosticsSite site)
      : super(site, 'overlays', 'Overlays',
            description: 'Editing overlays - unsaved file changes.');

  @override
  void generateContent(Map<String, String> params) {
    FileContentOverlay overlays = server.fileContentOverlay;
    List<String> paths = overlays.paths.toList()..sort();

    String overlayPath = params['overlay'];
    if (overlayPath != null) {
      p(overlayPath);

      if (overlays[overlayPath] != null) {
        buf.write('<pre><code>');
        buf.write(escape(overlays[overlayPath]));
        buf.writeln('</code></pre>');
      } else {
        p('<code>${escape(overlayPath)}</code> not found.', raw: true);
      }

      return;
    }

    if (paths.isEmpty) {
      blankslate('No overlays.');
    } else {
      String lenCounter(List list) {
        return '<span class="counter" style="float: right;">${list
            .length}</span>';
      }

      h3('Overlays ${lenCounter(paths)}', raw: true);
      ul(paths, (String overlayPath) {
        String uri = '$path?overlay=${Uri.encodeQueryComponent(overlayPath)}';
        buf.writeln('<a href="$uri">${escape(overlayPath)}</a>');
      });
    }
  }
}

// TODO(devoncarew): We're not currently tracking the time spent in specific
// lints by default (analysisOptions / driverOptions enableTiming)
class PluginsPage extends DiagnosticPageWithNav {
  PluginsPage(DiagnosticsSite site)
      : super(site, 'plugins', 'Plugins', description: 'Plugins in use.');

  @override
  void generateContent(Map<String, String> params) {
    h3('Analysis plugins');
    List<PluginInfo> analysisPlugins = server.pluginManager.plugins;

    if (analysisPlugins.isEmpty) {
      blankslate('No known analysis plugins.');
    } else {
      for (PluginInfo plugin in analysisPlugins) {
        // TODO(brianwilkerson) Sort the plugins by name.
        String id = plugin.pluginId;
        PluginData data = plugin.data;

        List<String> components = pathPackage.split(id);
        int length = components.length;
        String name;
        if (length == 0) {
          name = 'unknown plugin';
        } else if (length > 2) {
          name = components[length - 3];
        } else {
          name = components[length - 1];
        }
        h4(name);
        p('bootstrap package path: $id');
        if (plugin is DiscoveredPluginInfo) {
          p('execution path: ${plugin.executionPath}');
          p('packages file path: ${plugin.packagesPath}');
        }
        if (data.name == null) {
          if (plugin.exception != null) {
            p('not running');
            pre(() {
              buf.write(plugin.exception);
            });
          } else {
            p('not running for unknown reason');
          }
        } else {
          p('name: ${data.name}');
          p('version: ${data.version}');
          p('Associated contexts:');
          Set<ContextRoot> contexts = plugin.contextRoots;
          if (contexts.isEmpty) {
            blankslate('none');
          } else {
            ul(contexts.toList(), (ContextRoot root) {
              buf.writeln(root.root);
            });
          }
        }
      }
    }
  }
}

class ProfilePage extends DiagnosticPageWithNav {
  ProfilePage(DiagnosticsSite site)
      : super(site, 'profile', 'Profiling Info',
            description: 'Profiling performance tag data.');

  @override
  void generateContent(Map<String, String> params) {
    h3('Profiling performance tag data');

    // prepare sorted tags
    List<PerformanceTag> tags = PerformanceTag.all.toList();
    tags.remove(ServerPerformanceStatistics.idle);
    tags.remove(PerformanceTag.unknown);
    tags.removeWhere((tag) => tag.elapsedMs == 0);
    tags.sort((a, b) => b.elapsedMs - a.elapsedMs);

    // print total time
    int totalTime =
        tags.fold<int>(0, (int a, PerformanceTag tag) => a + tag.elapsedMs);
    p('Total measured time: ${printMilliseconds(totalTime)}');

    // draw a pie chart
    String rowData =
        tags.map((tag) => "['${tag.label}', ${tag.elapsedMs}]").join(',');
    buf.writeln(
        '<div id="chart-div" style="width: 700px; height: 300px;"></div>');
    buf.writeln('''
      <script type="text/javascript">
        google.charts.load('current', {'packages':['corechart']});
        google.charts.setOnLoadCallback(drawChart);

        function drawChart() {
          var data = new google.visualization.DataTable();
          data.addColumn('string', 'Tag');
          data.addColumn('number', 'Time (ms)');
          data.addRows([$rowData]);
          var options = {'title': 'Performance Tag Data', 'width': 700, 'height': 300};
          var chart = new google.visualization.PieChart(document.getElementById('chart-div'));
          chart.draw(data, options);
        }
      </script>
''');

    // write out a table
    void _writeRow(List<String> data, {bool header: false}) {
      buf.write('<tr>');
      if (header) {
        for (String d in data) {
          buf.write('<th>$d</th>');
        }
      } else {
        buf.write('<td>${data[0]}</td>');

        for (String d in data.sublist(1)) {
          buf.write('<td class="right">$d</td>');
        }
      }
      buf.writeln('</tr>');
    }

    buf.write('<table>');
    _writeRow(['Tag name', 'Time (in ms)', 'Percent'], header: true);
    void writeRow(PerformanceTag tag) {
      double percent = tag.elapsedMs / totalTime;
      _writeRow([
        tag.label,
        printMilliseconds(tag.elapsedMs),
        printPercentage(percent)
      ]);
    }

    tags.forEach(writeRow);
    buf.write('</table>');

    if (_showLints) {
      h3('Lint rule timings');
      List<LintRule> rules = Registry.ruleRegistry.rules.toList();
      int totalLintTime = rules.fold(0,
          (sum, rule) => sum + lintRegistry.getTimer(rule).elapsedMilliseconds);
      p('Total time spent in lints: ${printMilliseconds(totalLintTime)}');

      rules.sort((first, second) {
        int firstTime = lintRegistry.getTimer(first).elapsedMilliseconds;
        int secondTime = lintRegistry.getTimer(second).elapsedMilliseconds;
        if (firstTime == secondTime) {
          return first.lintCode.name.compareTo(second.lintCode.name);
        }
        return secondTime - firstTime;
      });
      buf.write('<table>');
      _writeRow(['Lint code', 'Time (in ms)'], header: true);
      for (var rule in rules) {
        int time = lintRegistry.getTimer(rule).elapsedMilliseconds;
        _writeRow([rule.lintCode.name, printMilliseconds(time)]);
      }
      buf.write('</table>');
    }
  }
}

class StatusPage extends DiagnosticPageWithNav {
  StatusPage(DiagnosticsSite site)
      : super(site, 'status', 'Status',
            description:
                'General status and diagnostics for the analysis server.');

  @override
  void generateContent(Map<String, String> params) {
    DiagnosticsSite diagnosticsSite = site;

    buf.writeln('<div class="columns">');

    buf.writeln('<div class="column one-half">');
    h3('Status');
    buf.writeln(writeOption('Preview-dart-2',
        diagnosticsSite.socketServer.analysisServerOptions.previewDart2));
    buf.writeln(writeOption('Use common front end',
        diagnosticsSite.socketServer.analysisServerOptions.useCFE));
    buf.writeln(writeOption('Instrumentation enabled',
        AnalysisEngine.instance.instrumentationService.isActive));
    buf.writeln(writeOption('Server process ID', pid));
    buf.writeln('</div>');

    buf.writeln('<div class="column one-half">');
    h3('Versions');
    buf.writeln(writeOption('Analysis server version', AnalysisServer.VERSION));
    buf.writeln(writeOption('Dart SDK', Platform.version));
    buf.writeln('</div>');

    buf.writeln('</div>');

    List<String> lines = (site as DiagnosticsSite).lastPrintedLines;
    if (lines.isNotEmpty) {
      h3('Debug output');
      p(lines.join('\n'), style: 'white-space: pre');
    }
  }
}

class SubscriptionsPage extends DiagnosticPageWithNav {
  SubscriptionsPage(DiagnosticsSite site)
      : super(site, 'subscriptions', 'Subscriptions',
            description: 'Registered subscriptions to analysis server events.');

  @override
  void generateContent(Map<String, String> params) {
    // server domain
    h3('Server domain subscriptions');
    ul(ServerService.VALUES, (item) {
      if (server.serverServices.contains(item)) {
        buf.write('$item (has subscriptions)');
      } else {
        buf.write('$item (no subscriptions)');
      }
    });

    // analysis domain
    h3('Analysis domain subscriptions');
    for (AnalysisService service in AnalysisService.VALUES) {
      buf.writeln('${service.name}<br>');
      ul(server.analysisServices[service] ?? [], (item) {
        buf.write('$item');
      });
    }

    // execution domain
    ExecutionDomainHandler domain = server.handlers.firstWhere(
        (handler) => handler is ExecutionDomainHandler,
        orElse: () => null);

    h3('Execution domain');
    ul(ExecutionService.VALUES, (item) {
      if (domain.onFileAnalyzed != null) {
        buf.write('$item (has subscriptions)');
      } else {
        buf.write('$item (no subscriptions)');
      }
    });
  }
}
