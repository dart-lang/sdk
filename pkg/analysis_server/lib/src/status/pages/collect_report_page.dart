// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/utilities/report_data.dart';

class CollectReportPage extends DiagnosticPage {
  CollectReportPage(DiagnosticsSite site)
    : super(
        site,
        'collect-report',
        'Collect report',
        description: 'Collect a shareable report for filing issues.',
      );

  @override
  String? contentDispositionString(Map<String, String> params) {
    if (params['collect'] != null) {
      return 'attachment; filename="dart_analyzer_diagnostics_report.json"';
    }
    return super.contentDispositionString(params);
  }

  @override
  ContentType contentType(Map<String, String> params) {
    if (params['collect'] != null) {
      return ContentType.json;
    }
    return super.contentType(params);
  }

  @override
  Future<void> generateContent(Map<String, String> params) async {
    p(
      'To download a report click the link below. '
      'When the report is downloaded you can share it with the '
      'Dart developers.',
    );
    p('<a href="$path?collect=true">Download report</a>.', raw: true);
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    if (params['collect'] != null) {
      // No added header etc.
      String data = await collectAllData(server);
      buf.write(data);
      return;
    }
    return await super.generatePage(params);
  }
}
