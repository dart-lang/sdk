// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';

class ContentsPage extends DiagnosticPageWithNav {
  String? _description;

  ContentsPage(DiagnosticsSite site)
    : super(
        site,
        'contents',
        'Contents',
        description: 'The Contents/Overlay of a file.',
      );

  @override
  String? get description => _description ?? super.description;

  @override
  bool get showInNav => false;

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var filePath = params['file'];
    if (filePath == null) {
      p('No file path provided.');
      return;
    }
    var driver = server.getAnalysisDriver(filePath);
    if (driver == null) {
      p(
        'The file <code>${escape(filePath)}</code> is not being analyzed.',
        raw: true,
      );
      return;
    }
    var file = server.resourceProvider.getFile(filePath);
    if (!file.exists) {
      p('The file <code>${escape(filePath)}</code> does not exist.', raw: true);
      return;
    }

    if (server.resourceProvider.hasOverlay(filePath)) {
      p('Showing overlay for file.');
    } else {
      p('Showing file system contents for file.');
    }

    pre(() {
      buf.write('<code>');
      buf.write(escape(file.readAsStringSync()));
      buf.writeln('</code>');
    });
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    try {
      _description = params['file'];
      await super.generatePage(params);
    } finally {
      _description = null;
    }
  }
}
