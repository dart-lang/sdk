// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/status/utilities/element_writer.dart';
import 'package:analyzer/dart/analysis/results.dart';

class ElementModelPage extends DiagnosticPageWithNav {
  String? _description;

  ElementModelPage(DiagnosticsSite site)
    : super(
        site,
        'element-model',
        'Element model',
        description: 'The element model for a file.',
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
    var result = await driver.getResolvedUnit(filePath);
    if (result is! ResolvedUnitResult) {
      p(
        'The file <code>${escape(filePath)}</code> could not be resolved.',
        raw: true,
      );
      return;
    }
    var libraryFragment = result.unit.declaredFragment;
    if (libraryFragment != null) {
      var writer = ElementWriter(buf);
      writer.write(libraryFragment.element);
    } else {
      p(
        'An element model could not be produced for the file '
        '<code>${escape(filePath)}</code>.',
        raw: true,
      );
    }
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
