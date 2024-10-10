// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';

typedef StaticOptions = Either2<TextDocumentSyncKind, TextDocumentSyncOptions>;

class TextDocumentChangeHandler
    extends LspMessageHandler<DidChangeTextDocumentParams, void> {
  TextDocumentChangeHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_didChange;

  @override
  LspJsonHandler<DidChangeTextDocumentParams> get jsonHandler =>
      DidChangeTextDocumentParams.jsonHandler;

  @override
  FutureOr<ErrorOr<void>> handle(DidChangeTextDocumentParams params,
      MessageInfo message, CancellationToken token) {
    var doc = params.textDocument;
    // Editors should never try to change our macro files, but just in case
    // we get these requests, ignore them.
    if (!isEditableDocument(doc.uri)) {
      return success(null);
    }

    var path = pathOfDoc(doc);
    return path.mapResultSync((path) => _changeFile(path, params));
  }

  ErrorOr<void> _changeFile(String path, DidChangeTextDocumentParams params) {
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
      );
    }
    var newContents = applyAndConvertEditsToServer(
        oldContents, params.contentChanges,
        failureIsCritical: true);
    return newContents.mapResultSync((result) {
      server.documentVersions[path] = params.textDocument;
      server.onOverlayUpdated(path, result.edits, newContent: result.content);
      return success(null);
    });
  }
}

class TextDocumentCloseHandler
    extends LspMessageHandler<DidCloseTextDocumentParams, void> {
  TextDocumentCloseHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_didClose;

  @override
  LspJsonHandler<DidCloseTextDocumentParams> get jsonHandler =>
      DidCloseTextDocumentParams.jsonHandler;

  @override
  FutureOr<ErrorOr<void>> handle(DidCloseTextDocumentParams params,
      MessageInfo message, CancellationToken token) {
    var doc = params.textDocument;
    var path = pathOfDoc(doc);
    return path.mapResult((path) async {
      if (isEditableDocument(doc.uri)) {
        // It's critical overlays are processed synchronously because other
        // requests that sneak in when we `await` rely on them being
        // correct.
        server.onOverlayDestroyed(path);
        server.documentVersions.remove(path);
      }

      // This is async because if onlyAnalyzeProjectsWithOpenFiles is true
      // it can trigger a change of analysis roots.
      await server.removePriorityFile(path);

      return success(null);
    });
  }
}

class TextDocumentOpenHandler
    extends LspMessageHandler<DidOpenTextDocumentParams, void> {
  TextDocumentOpenHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_didOpen;

  @override
  LspJsonHandler<DidOpenTextDocumentParams> get jsonHandler =>
      DidOpenTextDocumentParams.jsonHandler;

  @override
  FutureOr<ErrorOr<void>> handle(DidOpenTextDocumentParams params,
      MessageInfo message, CancellationToken token) {
    var doc = params.textDocument;
    var path = pathOfDocItem(doc);
    return path.mapResult((path) async {
      if (isEditableDocument(doc.uri)) {
        // We don't get a OptionalVersionedTextDocumentIdentifier with a didOpen but we
        // do get the necessary info to create one.
        server.documentVersions[path] = VersionedTextDocumentIdentifier(
          version: params.textDocument.version,
          uri: params.textDocument.uri,
        );
        // It's critical overlays are processed synchronously because other
        // requests that sneak in when we `await` rely on them being
        // correct.
        server.onOverlayCreated(path, doc.text);
      }

      // This is async because if onlyAnalyzeProjectsWithOpenFiles is true
      // it can trigger a change of analysis roots.
      await server.addPriorityFile(path);

      return success(null);
    });
  }
}

class TextDocumentRegistrations extends FeatureRegistration
    with StaticRegistration<StaticOptions> {
  TextDocumentRegistrations(super.info);

  @override
  List<LspDynamicRegistration> get dynamicRegistrations {
    return [
      (
        Method.textDocument_didOpen,
        TextDocumentRegistrationOptions(documentSelector: synchronisedTypes),
      ),
      (
        Method.textDocument_didClose,
        TextDocumentRegistrationOptions(documentSelector: synchronisedTypes),
      ),
      (
        Method.textDocument_didChange,
        TextDocumentChangeRegistrationOptions(
            syncKind: TextDocumentSyncKind.Incremental,
            documentSelector: synchronisedTypes),
      )
    ];
  }

  @override
  StaticOptions get staticOptions => Either2.t2(TextDocumentSyncOptions(
        openClose: true,
        change: TextDocumentSyncKind.Incremental,
        willSave: false,
        willSaveWaitUntil: false,
      ));

  @override
  bool get supportsDynamic => clientDynamic.textSync;

  List<TextDocumentFilterScheme> get synchronisedTypes {
    return {
      ...fullySupportedTypes,
      pubspecFile,
      analysisOptionsFile,
      fixDataFile,
    }.toList();
  }
}
