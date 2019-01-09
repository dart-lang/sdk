// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  Method get handlesMessage => Method.textDocument_didChange;

  @override
  DidChangeTextDocumentParams convertParams(Map<String, dynamic> json) =>
      DidChangeTextDocumentParams.fromJson(json);

  ErrorOr<void> handle(DidChangeTextDocumentParams params) {
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
    final newContents =
        applyEdits(oldContents, params.contentChanges, failureIsCritical: true);
    return newContents.mapResult((newcontents) {
      server.documentVersions[path] = params.textDocument;
      server.updateOverlay(path, newContents.result);
      return success();
    });
  }
}

class TextDocumentCloseHandler
    extends MessageHandler<DidCloseTextDocumentParams, void> {
  TextDocumentCloseHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_didClose;

  @override
  DidCloseTextDocumentParams convertParams(Map<String, dynamic> json) =>
      DidCloseTextDocumentParams.fromJson(json);

  ErrorOr<void> handle(DidCloseTextDocumentParams params) {
    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) {
      server.removePriorityFile(path);
      server.documentVersions[path] = null;
      server.updateOverlay(path, null);
      return success();
    });
  }
}

class TextDocumentOpenHandler
    extends MessageHandler<DidOpenTextDocumentParams, void> {
  TextDocumentOpenHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_didOpen;

  @override
  DidOpenTextDocumentParams convertParams(Map<String, dynamic> json) =>
      DidOpenTextDocumentParams.fromJson(json);

  ErrorOr<void> handle(DidOpenTextDocumentParams params) {
    final doc = params.textDocument;
    final path = pathOfDocItem(doc);
    return path.mapResult((path) {
      server.addPriorityFile(path);
      // We don't get a VersionedTextDocumentIdentifier with a didOpen but we
      // do get the necessary info to create one.
      server.documentVersions[path] = new VersionedTextDocumentIdentifier(
        params.textDocument.version,
        params.textDocument.uri,
      );
      server.updateOverlay(path, doc.text);

      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.
      server.contextManager.getDriverFor(path)?.addFile(path);

      return success();
    });
  }
}
