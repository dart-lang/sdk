// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

/// Base class for an operation that locks the server to prevent other requests
/// from being processed and overlays to be temporarily updated.
///
/// This can be used for operations that make multiple rounds of edits that
/// need to be merged together (to be mappable to LSP document changes) and then
/// reverted to allow the client to apply the change.
abstract class TemporaryOverlayOperation {
  final LspAnalysisServer server;
  final ContextManager contextManager;
  final OverlayResourceProvider resourceProvider;

  final Map<String, String?> _originalOverlays = {};
  final Set<AnalysisContext> _affectedContexts = {};
  final Map<AnalysisDriver, Set<String>> _originalAddedFiles = {};

  TemporaryOverlayOperation(this.server)
      : contextManager = server.contextManager,
        resourceProvider = server.resourceProvider;

  /// Apply pending file changes in any context that has a temporary overlay.
  Future<void> applyOverlays() async {
    for (final context in _affectedContexts) {
      await context.applyPendingFileChanges();
    }
    _affectedContexts.clear();
  }

  /// Applies edits as a temporary overlay.
  void applyTemporaryOverlayEdits(SourceFileEdit fileEdit) {
    final path = fileEdit.file;
    final context = contextManager.getContextFor(path);
    if (context == null) {
      throw ArgumentError(
          'Unable to apply a temporary overlay for file with no context: $path');
    }

    // We expect the content from any overlay and that in fsState to match
    // because we have paused watchers and incoming events and expect a
    // consistent state.
    final overlayContent = resourceProvider.getFile(path).readAsStringSync();
    final stateContent = context.driver.fsState.getFileForPath(path).content;
    if (overlayContent != stateContent) {
      throw StateError('Overlay and analyzed content do not match');
    }

    // Store the original overlay content if we haven't already, so we can
    // revert to it at the end.
    _originalOverlays.putIfAbsent(
        path, () => resourceProvider.hasOverlay(path) ? overlayContent : null);

    // Keep track of which contexts will have pending changes.
    _affectedContexts.add(context);

    // Finally, update the overlay and notify the driver.
    final newContent = SourceEdit.applySequence(overlayContent, fileEdit.edits);
    resourceProvider.setOverlay(path,
        content: newContent, modificationStamp: -1);
    context.changeFile(path);
  }

  /// Locks the server from processing incoming messages until [operation]
  /// completes just like [lockRequestsWhile] but additionally provides a
  /// function for writing temporary overlays that will be reverted when the
  /// operation completes.
  ///
  /// Additionally, sending diagnostics, outlines, etc. are suppressed by the
  /// temporary overlays and re-enabled after the overlays are restored.
  Future<T> lockRequestsWithTemporaryOverlays<T>(
    Future<T> Function() operation,
  ) async {
    return server.lockRequestsWhile(() async {
      // Wait for any in-progress analysis to complete before we start
      // suppressing analysis results.
      server.contextManager.pauseWatchers();
      await server.analysisDriverScheduler.waitForIdle();
      server.suppressAnalysisResults = true;
      _removeAddedFiles();
      try {
        // await is required to ensure we don't run the finally code until
        // the operation completes.
        return await operation();
      } finally {
        // Ensure we always revert overlays even if the operation did not
        // explicitly do it.
        revertOverlays();
        await server.analysisDriverScheduler.waitForIdle();
        _restoreAddedFiles();
        server.suppressAnalysisResults = false;
        server.contextManager.resumeWatchers();
      }
    });
  }

  /// Restore all overlays to the original content before any temporary overlays
  /// were added.
  void revertOverlays() {
    for (final entry in _originalOverlays.entries) {
      final path = entry.key;
      final overlayContent = entry.value;
      if (overlayContent != null) {
        resourceProvider.setOverlay(path,
            content: overlayContent, modificationStamp: -1);
      } else {
        resourceProvider.removeOverlay(path);
      }
      contextManager.getContextFor(path)?.changeFile(path);
    }
    _originalOverlays.clear();
  }

  /// Removes all `addedFiles` from all drivers to prevent modifications to
  /// overlays from triggering analysis of files that depend on them.
  void _removeAddedFiles() {
    if (_originalAddedFiles.isNotEmpty) {
      throw StateError(
        'Cannot remove addedFiles if they have already been removed',
      );
    }
    for (final driver in server.driverMap.values) {
      _originalAddedFiles[driver] = driver.addedFiles.toSet();
      driver.addedFiles.clear();
    }
  }

  /// Restores all `addedFiles` that were removed by [_removeAddedFiles].
  void _restoreAddedFiles() {
    for (final entry in _originalAddedFiles.entries) {
      final driver = entry.key;
      final originalFiles = entry.value;
      driver.addedFiles.addAll(originalFiles);
    }
    _originalAddedFiles.clear();
  }
}
