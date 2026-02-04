// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart'
    show LspAnalysisServer;
import 'package:analysis_server/src/server/http_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/status/pages/analysis_driver_page.dart';
import 'package:analysis_server/src/status/pages/analysis_performance_log_page.dart';
import 'package:analysis_server/src/status/pages/assists_page.dart';
import 'package:analysis_server/src/status/pages/ast_page.dart';
import 'package:analysis_server/src/status/pages/client_page.dart';
import 'package:analysis_server/src/status/pages/code_completion_page.dart';
import 'package:analysis_server/src/status/pages/collect_report_page.dart';
import 'package:analysis_server/src/status/pages/communications_page.dart';
import 'package:analysis_server/src/status/pages/contents_page.dart';
import 'package:analysis_server/src/status/pages/contexts_page.dart';
import 'package:analysis_server/src/status/pages/element_model_page.dart';
import 'package:analysis_server/src/status/pages/environment_variables_page.dart';
import 'package:analysis_server/src/status/pages/exception_page.dart';
import 'package:analysis_server/src/status/pages/exceptions_page.dart';
import 'package:analysis_server/src/status/pages/feedback_page.dart';
import 'package:analysis_server/src/status/pages/file_byte_store_timing_page.dart';
import 'package:analysis_server/src/status/pages/fixes_page.dart';
import 'package:analysis_server/src/status/pages/legacy_plugins_page.dart';
import 'package:analysis_server/src/status/pages/lsp_capabilities_page.dart';
import 'package:analysis_server/src/status/pages/lsp_client_page.dart';
import 'package:analysis_server/src/status/pages/lsp_registrations_page.dart';
import 'package:analysis_server/src/status/pages/memory_and_cpu_page.dart';
import 'package:analysis_server/src/status/pages/message_scheduler_page.dart';
import 'package:analysis_server/src/status/pages/not_found_page.dart';
import 'package:analysis_server/src/status/pages/plugins_page.dart';
import 'package:analysis_server/src/status/pages/refactorings_page.dart';
import 'package:analysis_server/src/status/pages/session_log_page.dart';
import 'package:analysis_server/src/status/pages/status_page.dart';
import 'package:analysis_server/src/status/pages/subscriptions_page.dart';
import 'package:analysis_server/src/status/pages/timing_page.dart';
import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:collection/collection.dart';

String get sdkVersion {
  var version = Platform.version;
  if (version.contains(' ')) {
    version = version.substring(0, version.indexOf(' '));
  }
  return version;
}

CollectedOptionsData collectOptionsData(AnalysisDriver driver) {
  var collectedData = CollectedOptionsData();
  if (driver.analysisContext?.allAnalysisOptions case var allAnalysisOptions?) {
    for (var analysisOptions in allAnalysisOptions) {
      collectedData.lints.addAll(analysisOptions.lintRules.map((e) => e.name));
      collectedData.plugins.addAll(analysisOptions.enabledLegacyPluginNames);
    }
  }
  return collectedData;
}

({int time, String details}) producerTimeAndDetails(
  ProducerRequestPerformance request,
) {
  var details = StringBuffer();

  var totalProducerTime = 0;
  var producerTimings = request.producerTimings;

  for (var timing in producerTimings.sortedBy((t) => t.elapsedTime).reversed) {
    var producerTime = timing.elapsedTime;
    totalProducerTime += producerTime;
    details.write(timing.className);
    details.write(': ');
    details.writeln(printMilliseconds(producerTime));
  }

  return (time: totalProducerTime, details: details.toString());
}

String writeOption(String name, Object value) {
  return '$name: <code>$value</code><br> ';
}

class AnalyticsPage extends DiagnosticPageWithNav {
  AnalyticsPage(DiagnosticsSite site)
    : super(
        site,
        'analytics',
        'Analytics',
        description: 'Analytics gathered by the analysis server.',
      );

  @override
  String? get navDetail => null;

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var manager = server.analyticsManager;
    //
    // Display the standard header.
    //
    if (!manager.analytics.telemetryEnabled) {
      p('Analytics reporting disabled. In order to enable it, run:');
      p('&nbsp;&nbsp;<code>dart --enable-analytics</code>');
      p(
        'If analytics had been enabled, the information below would have been '
        'reported.',
      );
    } else {
      p(
        'The Dart tool uses Google Analytics to report feature usage '
        'statistics and to send basic crash reports. This data is used to '
        'help improve the Dart platform and tools over time.',
      );
      p('To disable reporting of analytics, run:');
      p('&nbsp;&nbsp;<code>dart --disable-analytics</code>', raw: true);
      p(
        'The information below will be reported the next time analytics are '
        'sent.',
      );
    }
    //
    // Display the analytics data that has been gathered.
    //
    manager.toHtml(buf);
  }
}

class CollectedOptionsData {
  final Set<String> lints = <String>{};
  final Set<String> plugins = <String>{};
}

/// A page with a proscriptive notion of layout.
abstract class DiagnosticPage extends Page {
  final DiagnosticsSite site;

  DiagnosticPage(this.site, String id, String title, {String? description})
    : super(id, title, description: description);

  bool get isNavPage => false;

  AnalysisServer get server => site.socketServer.analysisServer!;

  Future<void> generateContainer(Map<String, String> params) async {
    buf.writeln('<div class="columns docs-layout">');
    buf.writeln('<div class="three-fourths column markdown-body">');
    h1(title, classes: 'page-title');
    await asyncDiv(() async {
      p(description ?? 'Unknown Page');
      await generateContent(params);
    }, classes: 'markdown-body');
    buf.writeln('</div>');
    buf.writeln('</div>');
  }

  Future<void> generateContent(Map<String, String> params);

  void generateFooter() {
    buf.writeln('''
    <footer class="footer">
      Dart ${site.title} <span style="float:right">SDK $sdkVersion</span>
    </footer>
''');
  }

  void generateHeader() {
    buf.writeln('''
    <header class="masthead">
    <div class="container">
      <span class="masthead-logo">
      <span class="mega-octicon octicon-dashboard"></span>
        ${site.title} Insights
      </span>

      <nav class="masthead-nav">
        <a href="status" ${isNavPage ? ' class="active"' : ''}>Insights</a>
        <a href="collect-report" ${isCurrentPage('collect-report') ? ' class="active"' : ''}>Collect Report</a>
        <a href="feedback" ${isCurrentPage('feedback') ? ' class="active"' : ''}>Feedback</a>
        <a href="https://dart.dev/tools/dart-analyze" target="_blank">Docs</a>
        <a href="https://htmlpreview.github.io/?https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/api.html" target="_blank">Spec</a>
      </nav>
    </div>
    </header>
''');
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    buf.writeln('<!DOCTYPE html><html lang="en">');
    buf.write('<head>');
    buf.write('<meta charset="utf-8">');
    buf.write(
      '<meta name="viewport" content="width=device-width, '
      'initial-scale=1.0">',
    );
    buf.writeln('<title>${site.title}</title>');
    buf.writeln(
      '<link rel="stylesheet" '
      'href="https://cdnjs.cloudflare.com/ajax/libs/Primer/6.0.0/build.css">',
    );
    buf.writeln(
      '<link rel="stylesheet" '
      'href="https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/font/octicons.css">',
    );
    buf.writeln(
      '<script type="text/javascript" '
      'src="https://www.gstatic.com/charts/loader.js"></script>',
    );
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
  final bool indentInNav;

  DiagnosticPageWithNav(
    super.site,
    super.id,
    super.title, {
    super.description,
    this.indentInNav = false,
  });

  @override
  bool get isNavPage => true;

  String? get navDetail => null;

  bool get showInNav => true;

  String formatLatencyTiming(int elapsed, int? latency) {
    var buffer = StringBuffer();
    buffer.write(printMilliseconds(elapsed));

    if (latency != null) {
      buffer
        ..write(' <small class="subtle" title="client-to-server latency">(+ ')
        ..write(printMilliseconds(latency))
        ..write(')</small>');
    }

    return buffer.toString();
  }

  @override
  Future<void> generateContainer(Map<String, String> params) async {
    buf.writeln('<div class="columns docs-layout">');

    bool shouldShowInNav(DiagnosticPageWithNav page) => page.showInNav;

    buf.writeln('<div class="one-fifth column">');
    buf.writeln('<nav class="menu docs-menu">');
    var navPages = site.pages.whereType<DiagnosticPageWithNav>().where(
      shouldShowInNav,
    );
    for (var page in navPages) {
      var classes = [
        'menu-item',
        if (page == this) 'selected',
        if (page.indentInNav) 'pl-5',
      ];
      buf.write(
        '<a class="${classes.join(' ')}" '
        'href="${page.path}">${escape(page.title)}',
      );
      var detail = page.navDetail;
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
      p(description ?? 'Unknown Page');
      await generateContent(params);
    }, classes: 'markdown-body');
    buf.writeln('</div>');

    buf.writeln('</div>');
  }
}

class DiagnosticsSite extends Site implements AbstractHttpHandler {
  /// A flag used to control whether developer support should be included when
  /// building the pages.
  static const bool includeDeveloperSupport = false;

  static const String kCustomCss = '''
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

.subtle {
  color: #333;
}
''';

  /// An object that can handle either a WebSocket connection or a connection
  /// to the client over stdio.
  AbstractSocketServer socketServer;

  /// The last few lines printed.
  final List<String> lastPrintedLines;

  DiagnosticsSite(this.socketServer, this.lastPrintedLines)
    : super('Analysis Server') {
    pages.add(CommunicationsPage(this));
    pages.add(ContextsPage(this));
    pages.add(EnvironmentVariablesPage(this));
    pages.add(ExceptionsPage(this));
    // pages.add(new InstrumentationPage(this));
    if (includeDeveloperSupport) {
      pages.add(AnalyticsPage(this));
    }

    // Add server-specific pages. Ordering doesn't matter as the items are
    // sorted later.
    var server = socketServer.analysisServer;
    if (server != null) {
      pages.add(PluginsPage(this, server));
      pages.add(LegacyPluginsPage(this, server));
    }
    if (server is LegacyAnalysisServer) {
      pages.add(ClientPage(this));
      pages.add(SubscriptionsPage(this, server));
    } else if (server is LspAnalysisServer) {
      pages.add(LspClientPage(this, server));
      pages.add(LspCapabilitiesPage(this, server));
      pages.add(LspRegistrationsPage(this, server));
    }

    pages.add(AnalysisPerformanceLogPage(this));

    var profiler = ProcessProfiler.getProfilerForPlatform();
    if (profiler != null) {
      pages.add(MemoryAndCpuPage(this, profiler));
    }

    pages.sort(
      (Page a, Page b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    // Add the status page at the beginning.
    pages.insert(0, StatusPage(this));

    // Add non-nav pages.
    pages.add(FeedbackPage(this));
    pages.add(CollectReportPage(this));
    pages.add(AstPage(this));
    pages.add(ElementModelPage(this));
    pages.add(ContentsPage(this));

    // Add logging pages
    pages.add(SessionLogPage(this));

    // Add timing pages
    pages.add(TimingPage(this));
    // (Nested)
    pages.add(AnalysisDriverPage(this));
    pages.add(AssistsPage(this));
    pages.add(FileByteStoreTimingPage(this));
    pages.add(CodeCompletionPage(this));
    pages.add(FixesPage(this));
    pages.add(MessageSchedulerPage(this));
    pages.add(RefactoringsPage(this));
  }

  @override
  String get customCss => kCustomCss;

  @override
  Page createExceptionPage(String message, StackTrace trace) =>
      ExceptionPage(this, message, trace);

  @override
  Page createUnknownPage(String unknownPath) => NotFoundPage(this, unknownPath);
}

/// A base class for pages that provide real-time logging over a WebSocket.
abstract class WebSocketLoggingPage extends DiagnosticPageWithNav
    implements WebSocketPage {
  WebSocketLoggingPage(super.site, super.id, super.title, {super.description});

  void button(String text, {String? id, String classes = '', String? onClick}) {
    var attributes = {
      'type': 'button',
      'id': ?id,
      'class': 'btn $classes'.trim(),
      'onclick': ?onClick,
      'value': text,
    };

    tag('input', attributes: attributes);
  }

  /// Writes an HTML tag for [tagName] with the given [attributes].
  ///
  /// If [gen] is supplied, it is executed to write child content to [buf].
  void tag(
    String tagName, {
    Map<String, String>? attributes,
    void Function()? gen,
  }) {
    buf.write('<$tagName');
    if (attributes != null) {
      for (var MapEntry(:key, :value) in attributes.entries) {
        buf.write(' $key="${escape(value)}"');
      }
    }
    buf.write('>');
    gen?.call();
    buf.writeln('</$tagName>');
  }

  /// Writes Start/Stop/Clear buttons and associated scripts to connect and
  /// disconnect a websocket back to this page, along with a panel to show
  /// any output received from the server over the WebSocket.
  void writeWebSocketLogPanel() {
    // Add buttons to start/stop logging. Using "position: sticky" so they're
    // always visible even when scrolled.
    tag(
      'div',
      attributes: {
        'style':
            'position: sticky; top: 10px; text-align: right; margin-bottom: 20px;',
      },
      gen: () {
        button(
          'Start Logging',
          id: 'btnStartLog',
          classes: 'btn-danger',
          onClick: 'startLogging()',
        );
        button(
          'Stop Logging',
          id: 'btnStopLog',
          classes: 'btn-danger',
          onClick: 'stopLogging()',
        );
        button('Clear', onClick: 'clearLog()');
      },
    );

    // Write the log container.
    pre(() {
      tag('code', attributes: {'id': 'logContent'});
    });

    // Write the scripts to connect/disconnect the websocket and display the
    // data.
    buf.write('''
<script>
  let logContent = document.getElementById('logContent');
  let btnEnable = document.getElementById('btnEnable');
  let btnDisable = document.getElementById('btnDisable');
  let socket;

  function clearLog(data) {
    logContent.textContent = '';
  }

  function append(data) {
    logContent.appendChild(document.createTextNode(data));
  }

  function startLogging() {
    append("Connecting...\\n");
    socket = new WebSocket("$path");
    socket.addEventListener("open", (event) => {
      append("Connected!\\n");
    });
    socket.addEventListener("close", (event) => {
      append("Disconnected!\\n");
      stopLogging();
    });
    socket.addEventListener("message", (event) => {
      append(event.data);
    });
    btnEnable.disabled = true;
    btnDisable.disabled = false;
  }

  function stopLogging() {
    socket?.close(1000, 'User closed');
    socket = undefined;
    btnEnable.disabled = false;
    btnDisable.disabled = true;
  }
</script>
''');
  }
}
