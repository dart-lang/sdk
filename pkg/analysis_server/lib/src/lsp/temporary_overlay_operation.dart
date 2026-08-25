// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

/// Base class for an operation that locks the server to prevent other requests
/// from being processed and overlays to be temporarily updated.
///
/// This can be used for operations that make multiple rounds of edits that
/// need to be merged together (to be mappable to LSP document changes) and then
/// reverted to allow the client to apply the change.
abstract class TemporaryOverlayOperation {
  final AnalysisServer server;
  final ContextManager contextManager;
  final OverlayResourceProvider resourceProvider;

  final Map<String, String?> _originalOverlays = {};
  final Set<AnalysisContext> _affectedContexts = {};
  final Map<AnalysisDriver, Set<String>> _originalAddedFiles = {};

  new(this.server)
    : contextManager = server.contextManager,
      resourceProvider = server.resourceProvider;

  /// Apply pending file changes in any context that has a temporary overlay.
  Future<void> applyOverlays() async {
    for (var context in _affectedContexts) {
      await context.applyPendingFileChanges();
    }
    _affectedContexts.clear();
  }

  /// Applies a temporary overlay with the given [newContent].
  ///
  /// The [existingContent] will be saved as the original content to restore if
  /// [path] already has an active overlay.
  ///
  /// This can be used for files with or without an analysis context.
  void applyTemporaryOverlay(
    String path,
    String newContent,
    String existingContent,
  ) {
    // Store the original overlay content if we haven't already, so we can
    // revert to it at the end, otherwise store null so [revertOverlays]
    // removes the temporary overlay.
    if (!_originalOverlays.containsKey(path)) {
      _originalOverlays[path] = resourceProvider.hasOverlay(path)
          ? existingContent
          : null;
    }

    resourceProvider.setOverlay(
      path,
      content: newContent,
      modificationStamp: -1,
    );

    var context = contextManager.getContextFor(path);
    if (context != null) {
      _affectedContexts.add(context);
      context.changeFile(path);
    }
  }

  /// Applies edits as a temporary overlay.
  void applyTemporaryOverlayEdits(SourceFileEdit fileEdit) {
    var path = fileEdit.file;
    var context = contextManager.getContextFor(path);
    if (context == null) {
      throw ArgumentError(
        'Unable to apply a temporary overlay for file with no context: $path',
      );
    }

    // We expect the content from any overlay and that in fsState to match
    // because we have paused watchers and incoming events and expect a
    // consistent state.
    // FileSystemState only tracks Dart files, so non-Dart files
    // (such as pubspec.yaml) will not have their content updated in fsState.
    var overlayContent = resourceProvider.getFile(path).readAsStringSync();
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      assert(
        overlayContent == context.driver.fsState.getFileForPath(path).content,
        'Overlay and analyzed content do not match',
      );
    }

    var newContent = SourceEdit.applySequence(overlayContent, fileEdit.edits);
    applyTemporaryOverlay(path, newContent, overlayContent);
  }

  /// Locks the server from processing incoming messages until [operation]
  /// completes just like [AnalysisServer.pauseSchedulerWhile] but
  /// additionally provides a function for writing temporary overlays that will
  /// be reverted when the operation completes.
  ///
  /// Additionally, sending diagnostics, outlines, etc. are suppressed by the
  /// temporary overlays and re-enabled after the overlays are restored.
  Future<T> pauseSchedulerWithTemporaryOverlays<T>(
    Future<T> Function() operation,
  ) {
    return server.pauseSchedulerWhile(() async {
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
        await revertOverlays();
        await server.analysisDriverScheduler.waitForIdle();
        _restoreAddedFiles();
        server.suppressAnalysisResults = false;
        server.contextManager.resumeWatchers();
      }
    });
  }

  /// Restore all overlays to the original content before any temporary overlays
  /// were added and applies those changes.
  Future<void> revertOverlays() async {
    for (var entry in _originalOverlays.entries) {
      var path = entry.key;
      var overlayContent = entry.value;
      if (overlayContent != null) {
        resourceProvider.setOverlay(
          path,
          content: overlayContent,
          modificationStamp: -1,
        );
      } else {
        resourceProvider.removeOverlay(path);
      }

      var context = contextManager.getContextFor(path);
      if (context != null) {
        _affectedContexts.add(context);
        context.changeFile(path);
      }
    }
    _originalOverlays.clear();

    await applyOverlays();
  }

  /// Removes all `addedFiles` from all drivers to prevent modifications to
  /// overlays from triggering analysis of files that depend on them.
  void _removeAddedFiles() {
    if (_originalAddedFiles.isNotEmpty) {
      throw StateError(
        'Cannot remove addedFiles if they have already been removed',
      );
    }
    for (var driver in server.driverMap.values) {
      _originalAddedFiles[driver] = driver.addedFiles.toSet();
      driver.addedFiles.clear();
    }
  }

  /// Restores all `addedFiles` that were removed by [_removeAddedFiles].
  void _restoreAddedFiles() {
    for (var entry in _originalAddedFiles.entries) {
      var driver = entry.key;
      var originalFiles = entry.value;
      driver.addedFiles.addAll(originalFiles);
    }
    _originalAddedFiles.clear();
  }
}
