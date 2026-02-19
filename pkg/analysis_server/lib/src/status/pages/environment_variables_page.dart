// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/src/util/platform_info.dart';

class EnvironmentVariablesPage extends DiagnosticPageWithNav {
  EnvironmentVariablesPage(DiagnosticsSite site)
    : super(
        site,
        'environment',
        'Environment variables',
        description:
            'System environment variables as seen from the analysis server.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    buf.writeln('<table>');
    buf.writeln('<tr><th>Variable</th><th>Value</th></tr>');
    for (var key in platform.environment.keys.toList()..sort()) {
      var value = platform.environment[key];
      buf.writeln('<tr><td>${escape(key)}</td><td>${escape(value)}</td></tr>');
    }
    buf.writeln('</table>');
  }
}
