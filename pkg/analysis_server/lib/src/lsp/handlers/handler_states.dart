// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handler_completion.dart';
import 'package:analysis_server/src/lsp/handler_definition.dart';
import 'package:analysis_server/src/lsp/handler_formatting.dart';
import 'package:analysis_server/src/lsp/handler_hover.dart';
import 'package:analysis_server/src/lsp/handler_references.dart';
import 'package:analysis_server/src/lsp/handler_signature_help.dart';
import 'package:analysis_server/src/lsp/handler_text_document_changes.dart';
import 'package:analysis_server/src/lsp/handlers/handler_initialize.dart';
import 'package:analysis_server/src/lsp/handlers/handler_initialized.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

/// A handler that requests requests but drops notifications. Used for handling
/// unknown messages prior to the initialisation stage.
FutureOr<Object> _rejectRequests(IncomingMessage message) {
  // Silently drop non-requests.
  if (message is! RequestMessage) {
    return null;
  }
  throw new ResponseError(ErrorCodes.ServerNotInitialized,
      'Unable to handle ${message.method} before server is initialized', null);
}

class InitializedStateMessageHandler extends ServerStateMessageHandler {
  InitializedStateMessageHandler(LspAnalysisServer server) : super(server) {
    reject('initialize', ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    reject('initialized', ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(new TextDocumentOpenHandler(server));
    registerHandler(new TextDocumentChangeHandler(server));
    registerHandler(new TextDocumentCloseHandler(server));
    registerHandler(new HoverHandler(server));
    registerHandler(new CompletionHandler(server));
    registerHandler(new SignatureHelpHandler(server));
    registerHandler(new DefinitionHandler(server));
    registerHandler(new ReferencesHandler(server));
    registerHandler(new FormattingHandler(server));
  }
}

class InitializingStateMessageHandler extends ServerStateMessageHandler {
  InitializingStateMessageHandler(
      LspAnalysisServer server, List<String> openWorkspacePaths)
      : super(server) {
    reject('initialize', ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(new IntializedMessageHandler(server, openWorkspacePaths));
  }

  @override
  FutureOr<Object> handleUnknownMessage(IncomingMessage message) =>
      _rejectRequests(message);
}

class UninitializedStateMessageHandler extends ServerStateMessageHandler {
  UninitializedStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(new InitializeMessageHandler(server));
  }

  @override
  FutureOr<Object> handleUnknownMessage(IncomingMessage message) =>
      _rejectRequests(message);
}
