// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/operations/abstract_fix_all.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Runs an iterative fix-all loop for Dart fixes followed by a set of Pubspec
/// fixes for the whole workspace.
///
/// Used by:
///
/// - Apply/Preview Fix All in Workspace command (a Source CodeAction)
/// - dart/workspace/fixes/get request (`dart fix`)
class FixAllInWorkspaceOperation extends AbstractFixAllOperation {
  final bool requireConfirmation;

  new({
    required super.server,
    required super.message,
    required super.cancellationToken,
    required this.requireConfirmation,
    super.diagnosticCodes,
  });

  @override
  ChangeAnnotations get changeAnnotations {
    return requireConfirmation ? .requireConfirmation : .include;
  }

  @override
  Future<IterativeBulkFixRequestResult> getFixEdits(
    IterativeBulkFixProcessor processor,
    OperationPerformanceImpl performance,
  ) {
    var contexts = server.contextManager.analysisContexts;
    return processor.fixErrors(performance, contexts);
  }
}
