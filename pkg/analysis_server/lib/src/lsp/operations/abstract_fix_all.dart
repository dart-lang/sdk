// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/lsp/temporary_overlay_operation.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/utilities/source_change_merger.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A base class for operations that run an iterative fix-all loop for Dart
/// fixes followed by a set of Pubspec fixes.
///
/// This class handles pausing the scheduler and locking overlays before running
/// multiple rounds of fixes via [IterativeBulkFixProcessor]. Once complete,
/// overlays are restored and the scheduler unpaused before the deits are
/// returned.
abstract class AbstractFixAllOperation extends TemporaryOverlayOperation
    with HandlerHelperMixin<AnalysisServer> {
  final MessageInfo message;
  final CancellationToken cancellationToken;
  final List<String>? diagnosticCodes;

  new({
    required AnalysisServer server,
    required this.message,
    required this.cancellationToken,
    this.diagnosticCodes,
  }) : super(server);

  /// The kind of change annotations to include in the computed edits.
  ///
  /// For changes sent to a client with `workspace/applyEdit` this can control
  /// whether previews of the edits are shown or whether the edits are applied
  /// immediately.
  ChangeAnnotations get changeAnnotations;

  Future<ErrorOr<(WorkspaceEdit?, List<LspBulkFix>)>> compute() async {
    return await pauseSchedulerWithTemporaryOverlays(_computeImpl);
  }

  /// Gets the edits to fix the current round of diagnostics.
  Future<IterativeBulkFixRequestResult?> getFixEdits(
    IterativeBulkFixProcessor processor,
    OperationPerformanceImpl performance,
  );

  Future<ErrorOr<(WorkspaceEdit?, List<LspBulkFix>)>> _computeImpl() async {
    if (cancellationToken.isCancellationRequested) {
      return cancelled(cancellationToken);
    }

    var processor = IterativeBulkFixProcessor(
      instrumentationService: server.instrumentationService,
      byteStore: server.byteStore,
      applyTemporaryOverlayEdits: applyTemporaryOverlayEdits,
      applyOverlays: applyOverlays,
      diagnosticCodes: diagnosticCodes,
      cancellationToken: cancellationToken,
    );

    var result = await getFixEdits(processor, message.performance);
    if (result == null) {
      return success((null, []));
    }
    var errorMessage = result.errorMessage;
    if (errorMessage != null) {
      return ErrorOr.error(
        ResponseError(code: ErrorCodes.RequestFailed, message: errorMessage),
      );
    }
    var changes = result.edits;
    if (changes.isEmpty) {
      return success((null, []));
    }

    // We only need to merge if we know we did multiple passes.
    if (processor.passesWithEdits > 1) {
      changes = message.performance.run(
        'SourceChangeMerger.merge',
        (_) => SourceChangeMerger().merge(changes),
      );
    }

    // We must revert overlays before mapping edits, because we need any
    // LineInfos to reflect the original state while mapping to LSP.
    await revertOverlays();

    var edit = createPlainWorkspaceEdit(
      server,
      server.editorClientCapabilities!,
      changes,
      annotateChanges: changeAnnotations,
    );

    var details = _mergeDetails(result.details);

    return success((edit, details));
  }

  /// Merge the fix details from multiple rounds and return them as
  /// [LspBulkFix]es.
  List<LspBulkFix> _mergeDetails(List<BulkFix> details) {
    var countByCodeByFile = <String, Map<String, int>>{};
    for (var detail in details) {
      var detailsForFile = countByCodeByFile.putIfAbsent(detail.path, () => {});
      for (var fix in detail.fixes) {
        var occurrences = (detailsForFile[fix.code] ?? 0) + fix.occurrences;
        detailsForFile[fix.code] = occurrences;
      }
    }

    return countByCodeByFile.entries.map((entry) {
      var MapEntry(key: filePath, value: detail) = entry;
      return LspBulkFix(
        uri: pathContext.toUri(filePath),
        fixes: detail.entries.map((entry) {
          var MapEntry(key: code, value: occurrences) = entry;
          return LspBulkFixDetail(code: code, occurrences: occurrences);
        }).toList(),
      );
    }).toList();
  }
}
