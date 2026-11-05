// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/operations/abstract_fix_all.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Runs an iterative fix-all loop for Dart fixes followed by a set of Pubspec
/// fixes for a single file.
class FixAllInFileOperation extends AbstractFixAllOperation {
  final String path;
  final bool autoTriggered;

  new({
    required super.server,
    required super.message,
    required this.path,
    required super.cancellationToken,
    required this.autoTriggered,
  }) : super(diagnosticCodes: null);

  @override
  ChangeAnnotations get changeAnnotations => .none;

  @override
  Future<IterativeBulkFixRequestResult?> getFixEdits(
    IterativeBulkFixProcessor processor,
    OperationPerformanceImpl performance,
  ) async {
    var context = server.contextManager.getContextFor(path);
    if (context == null) {
      return null;
    }

    return await processor.fixErrorsForFile(
      message.performance,
      context,
      path,
      autoTriggered: autoTriggered,
    );
  }
}
