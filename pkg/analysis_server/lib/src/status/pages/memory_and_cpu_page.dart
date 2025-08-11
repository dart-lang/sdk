// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/utilities/profiling.dart';

class MemoryAndCpuPage extends DiagnosticPageWithNav {
  final ProcessProfiler profiler;

  MemoryAndCpuPage(DiagnosticsSite site, this.profiler)
    : super(
        site,
        'memory-and-cpu-usage',
        'Memory and CPU usage',
        description: 'Memory and CPU usage for the analysis server.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var usage = await profiler.getProcessUsage(pid);

    var serviceProtocolInfo = await developer.Service.getInfo();

    if (usage != null) {
      var cpuPercentage = usage.cpuPercentage;
      if (cpuPercentage != null) {
        buf.writeln(writeOption('CPU', printPercentage(cpuPercentage / 100.0)));
      }
      buf.writeln(writeOption('Memory', '${usage.memoryMB.round()} MB'));

      h3('VM');

      if (serviceProtocolInfo.serverUri == null) {
        p('Service protocol not enabled.');
      } else {
        buf.writeln(
          writeOption(
            'Service protocol connection available at',
            '${serviceProtocolInfo.serverUri}',
          ),
        );
        buf.writeln('<br>');
        p(
          'To get detailed performance data on the analysis server, we '
          'recommend using Dart DevTools. For instructions on installing and '
          'using DevTools, see '
          '<a href="https://dart.dev/tools/dart-devtools">dart.dev/tools/dart-devtools</a>.',
          raw: true,
        );
      }
    } else {
      p('Error retrieving the memory and cpu usage information.');
    }
  }
}
