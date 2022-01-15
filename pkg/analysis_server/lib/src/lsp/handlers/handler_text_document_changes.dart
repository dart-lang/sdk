// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';

class TextDocumentChangeHandler
    extends MessageHandler<DidChangeTextDocumentParams, void> {
  TextDocumentChangeHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_didChange;

  @override
  LspJsonHandler<DidChangeTextDocumentParams> get jsonHandler =>
      DidChangeTextDocumentParams.jsonHandler;

  @override
  FutureOr<ErrorOr<Null>> handle(
      DidChangeTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) => _changeFile(path, params));
  }

  FutureOr<ErrorOr<Null>> _changeFile(
      String path, DidChangeTextDocumentParams params) {
    String? oldContents;
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
      return success(null);
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
  FutureOr<ErrorOr<Null>> handle(
      DidCloseTextDocumentParams params, CancellationToken token) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      await server.removePriorityFile(path);
      server.documentVersions.remove(path);
      server.onOverlayDestroyed(path);

      return success(null);
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
  FutureOr<ErrorOr<Null>> handle(
      DidOpenTextDocumentParams params, CancellationToken token) {
    final doc = params.textDocument;
    final path = pathOfDocItem(doc);
    return path.mapResult((path) async {
      // We don't get a OptionalVersionedTextDocumentIdentifier with a didOpen but we
      // do get the necessary info to create one.
      server.documentVersions[path] = VersionedTextDocumentIdentifier(
        version: params.textDocument.version,
        uri: params.textDocument.uri,
      );
      server.onOverlayCreated(path, doc.text);

      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.
      server.contextManager.getDriverFor(path)?.addFile(path);

      await server.addPriorityFile(path);

      return success(null);
    });
  }
}
