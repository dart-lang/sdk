// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/context_manager.dart'
    show ContextManagerImpl;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' show dirname, join;

/// Finds the nearest ancestor to [filePath] that contains a pubspec/.packages/build file.
String _findProjectFolder(ResourceProvider resourceProvider, String filePath) {
  // TODO(dantup): Is there something we can reuse for this?
  var folder = dirname(filePath);
  while (folder != dirname(folder)) {
    final pubspec =
        resourceProvider.getFile(join(folder, ContextManagerImpl.PUBSPEC_NAME));
    final packages = resourceProvider
        .getFile(join(folder, ContextManagerImpl.PACKAGE_SPEC_NAME));
    final build = resourceProvider.getFile(join(folder, 'BUILD'));

    if (pubspec.exists || packages.exists || build.exists) {
      return folder;
    }
    folder = dirname(folder);
  }
  return null;
}

class TextDocumentChangeHandler
    extends MessageHandler<DidChangeTextDocumentParams, void> {
  TextDocumentChangeHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_didChange;

  @override
  LspJsonHandler<DidChangeTextDocumentParams> get jsonHandler =>
      DidChangeTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidChangeTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) => _changeFile(path, params));
  }

  ErrorOr<void> _changeFile(String path, DidChangeTextDocumentParams params) {
    String oldContents;
    if (server.resourceProvider.hasOverlay(path)) {
      oldContents = server.resourceProvider.getFile(path).readAsStringSync();
    }
    // If we didn't have the file contents, the server and client are out of sync
    // and this is a serious failure.
    if (oldContents == null) {
      return error(
        ServerErrorCodes.ClientServerInconsistentState,
        'Unable to edit document because the file was not previously opened: $path',
        null,
      );
    }
    final newContents = applyAndConvertEditsToServer(
        oldContents, params.contentChanges,
        failureIsCritical: true);
    return newContents.mapResult((result) {
      server.documentVersions[path] = params.textDocument;
      server.onOverlayUpdated(path, result.last, newContent: result.first);
      return success();
    });
  }
}

class TextDocumentCloseHandler
    extends MessageHandler<DidCloseTextDocumentParams, void> {
  TextDocumentCloseHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_didClose;

  @override
  LspJsonHandler<DidCloseTextDocumentParams> get jsonHandler =>
      DidCloseTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidCloseTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) {
      server.removePriorityFile(path);
      server.documentVersions.remove(path);
      server.onOverlayDestroyed(path);
      server.removeTemporaryAnalysisRoot(path);

      return success();
    });
  }
}

class TextDocumentOpenHandler
    extends MessageHandler<DidOpenTextDocumentParams, void> {
  TextDocumentOpenHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_didOpen;

  @override
  LspJsonHandler<DidOpenTextDocumentParams> get jsonHandler =>
      DidOpenTextDocumentParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidOpenTextDocumentParams params, CancellationToken token) {
    final doc = params.textDocument;
    final path = pathOfDocItem(doc);
    return path.mapResult((path) {
      // We don't get a OptionalVersionedTextDocumentIdentifier with a didOpen but we
      // do get the necessary info to create one.
      server.documentVersions[path] = VersionedTextDocumentIdentifier(
        version: params.textDocument.version,
        uri: params.textDocument.uri,
      );
      server.onOverlayCreated(path, doc.text);

      final driver = server.getAnalysisDriver(path);
      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.

      driver?.addFile(path);

      // Figure out the best analysis root for this file and register it as a temporary
      // analysis root. We need to register it even if we found a driver, so that if
      // the driver existed only because of another open file, it will not be removed
      // when that file is closed.
      final analysisRoot = driver?.contextRoot?.root ??
          _findProjectFolder(server.resourceProvider, path) ??
          dirname(path);
      if (analysisRoot != null) {
        server.addTemporaryAnalysisRoot(path, analysisRoot);
      }

      server.addPriorityFile(path);

      return success();
    });
  }
}
