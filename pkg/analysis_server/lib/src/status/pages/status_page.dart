// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/protocol/protocol_constants.dart'
    show PROTOCOL_VERSION;
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analyzer/src/util/platform_info.dart';

class StatusPage extends DiagnosticPageWithNav {
  StatusPage(DiagnosticsSite site)
    : super(
        site,
        'status',
        'Status',
        description: 'General status and diagnostics for the analysis server.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    buf.writeln('<div class="columns">');

    buf.writeln('<div class="column one-half">');
    h3('Status');
    buf.writeln(writeOption('Server type', server.runtimeType));
    // buf.writeln(writeOption('Instrumentation enabled',
    //     AnalysisEngine.instance.instrumentationService.isActive));
    buf.writeln(
      writeOption(
        '(Scheduler) allow overlapping message handlers:',
        MessageScheduler.allowOverlappingHandlers,
      ),
    );
    buf.writeln(writeOption('Server process ID', pid));
    buf.writeln('</div>');

    buf.writeln('<div class="column one-half">');
    h3('Versions');
    buf.writeln(writeOption('Analysis server version', PROTOCOL_VERSION));
    buf.writeln(writeOption('Dart SDK', platform.version));
    buf.writeln('</div>');

    buf.writeln('</div>');

    // SDK configuration overrides.
    var sdkConfig = server.options.configurationOverrides;
    if (sdkConfig?.hasAnyOverrides == true) {
      buf.writeln('<div class="columns">');

      buf.writeln('<div class="column one-half">');
      h3('Configuration Overrides');
      buf.writeln(
        '<pre><code>${sdkConfig?.displayString ?? '<unknown overrides>'}</code></pre><br>',
      );
      buf.writeln('</div>');

      buf.writeln('</div>');
    }

    var lines = site.lastPrintedLines;
    if (lines.isNotEmpty) {
      h3('Debug output');
      p(lines.join('\n'), style: 'white-space: pre');
    }
  }
}
