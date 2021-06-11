// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vm;

import 'adapters/dart.dart';
import 'isolate_manager.dart';
import 'protocol_generated.dart' as dap;

/// A helper that handlers converting to/from DAP and VM Service types and to
/// user-friendly display strings.
///
/// This class may call back to the VM Service to fetch additional information
/// when converting classes - for example when converting a stack frame it may
/// fetch scripts from the VM Service in order to map token positions back to
/// line/columns as required by DAP.
class ProtocolConverter {
  /// The parent debug adapter, used to access arguments and the VM Service for
  /// the debug session.
  final DartDebugAdapter _adapter;

  ProtocolConverter(this._adapter);

  /// Converts an absolute path to one relative to the cwd used to launch the
  /// application.
  ///
  /// If [sourcePath] is outside of the cwd used for launching the application
  /// then the full absolute path will be returned.
  String convertToRelativePath(String sourcePath) {
    final cwd = _adapter.args.cwd;
    if (cwd == null) {
      return sourcePath;
    }
    final rel = path.relative(sourcePath, from: cwd);
    return !rel.startsWith('..') ? rel : sourcePath;
  }

  /// Converts a VM Service stack frame to a DAP stack frame.
  Future<dap.StackFrame> convertVmToDapStackFrame(
    ThreadInfo thread,
    vm.Frame frame, {
    required bool isTopFrame,
    int? firstAsyncMarkerIndex,
  }) async {
    final frameId = thread.storeData(frame);

    if (frame.kind == vm.FrameKind.kAsyncSuspensionMarker) {
      return dap.StackFrame(
        id: frameId,
        name: '<asynchronous gap>',
        presentationHint: 'label',
        line: 0,
        column: 0,
      );
    }

    // The VM may supply frames with a prefix that we don't want to include in
    // the frame for the user.
    const unoptimizedPrefix = '[Unoptimized] ';
    final codeName = frame.code?.name;
    final frameName = codeName != null
        ? (codeName.startsWith(unoptimizedPrefix)
            ? codeName.substring(unoptimizedPrefix.length)
            : codeName)
        : '<unknown>';

    // If there's no location, this isn't source a user can debug so use a
    // subtle hint (which the editor may use to render the frame faded).
    final location = frame.location;
    if (location == null) {
      return dap.StackFrame(
        id: frameId,
        name: frameName,
        presentationHint: 'subtle',
        line: 0,
        column: 0,
      );
    }

    final scriptRef = location.script;
    final tokenPos = location.tokenPos;
    final uri = scriptRef?.uri;
    final sourcePath = uri != null ? await convertVmUriToSourcePath(uri) : null;
    var canShowSource = sourcePath != null && File(sourcePath).existsSync();

    // Download the source if from a "dart:" uri.
    int? sourceReference;
    if (uri != null &&
        (uri.startsWith('dart:') || uri.startsWith('org-dartlang-app:')) &&
        scriptRef != null) {
      sourceReference = thread.storeData(scriptRef);
      canShowSource = true;
    }

    var line = 0, col = 0;
    if (scriptRef != null && tokenPos != null) {
      try {
        final script = await thread.getScript(scriptRef);
        line = script.getLineNumberFromTokenPos(tokenPos) ?? 0;
        col = script.getColumnNumberFromTokenPos(tokenPos) ?? 0;
      } catch (e) {
        _adapter.logger?.call('Failed to map frame location to line/col: $e');
      }
    }

    final source = canShowSource
        ? dap.Source(
            name: sourcePath != null ? convertToRelativePath(sourcePath) : uri,
            path: sourcePath,
            sourceReference: sourceReference,
            origin: null,
            adapterData: location.script)
        : null;

    // The VM only allows us to restart from frames that are not the top frame,
    // but since we're also showing asyncCausalFrames any indexes past the first
    // async boundary will not line up so we cap it there.
    final canRestart = !isTopFrame &&
        (firstAsyncMarkerIndex == null || frame.index! < firstAsyncMarkerIndex);

    return dap.StackFrame(
      id: frameId,
      name: frameName,
      source: source,
      line: line,
      column: col,
      canRestart: canRestart,
    );
  }

  /// Converts the source path from the VM to a file path.
  ///
  /// This is required so that when the user stops (or navigates via a stack
  /// frame) we open the same file on their local disk. If we downloaded the
  /// source from the VM, they would end up seeing two copies of files (and they
  /// would each have their own breakpoints) which can be confusing.
  Future<String?> convertVmUriToSourcePath(String uri) async {
    if (uri.startsWith('file://')) {
      return Uri.parse(uri).toFilePath();
    } else if (uri.startsWith('package:')) {
      // TODO(dantup): Handle mapping package: uris ?
      return null;
    } else {
      return null;
    }
  }
}
