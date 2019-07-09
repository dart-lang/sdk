// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/custom/handler_diagnostic_server.dart';
import 'package:analysis_server/src/lsp/handlers/custom/handler_super.dart';
import 'package:analysis_server/src/lsp/handlers/handler_code_actions.dart';
import 'package:analysis_server/src/lsp/handlers/handler_completion.dart';
import 'package:analysis_server/src/lsp/handlers/handler_completion_resolve.dart';
import 'package:analysis_server/src/lsp/handlers/handler_definition.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_highlights.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_symbols.dart';
import 'package:analysis_server/src/lsp/handlers/handler_execute_command.dart';
import 'package:analysis_server/src/lsp/handlers/handler_exit.dart';
import 'package:analysis_server/src/lsp/handlers/handler_folding.dart';
import 'package:analysis_server/src/lsp/handlers/handler_format_on_type.dart';
import 'package:analysis_server/src/lsp/handlers/handler_formatting.dart';
import 'package:analysis_server/src/lsp/handlers/handler_hover.dart';
import 'package:analysis_server/src/lsp/handlers/handler_implementation.dart';
import 'package:analysis_server/src/lsp/handlers/handler_initialize.dart';
import 'package:analysis_server/src/lsp/handlers/handler_initialized.dart';
import 'package:analysis_server/src/lsp/handlers/handler_references.dart';
import 'package:analysis_server/src/lsp/handlers/handler_rename.dart';
import 'package:analysis_server/src/lsp/handlers/handler_shutdown.dart';
import 'package:analysis_server/src/lsp/handlers/handler_signature_help.dart';
import 'package:analysis_server/src/lsp/handlers/handler_text_document_changes.dart';
import 'package:analysis_server/src/lsp/handlers/handler_change_workspace_folders.dart';
import 'package:analysis_server/src/lsp/handlers/handler_workspace_symbols.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

/// The server moves to this state when a critical unrecoverrable error (for
/// example, inconsistent document state between server/client) occurs and will
/// reject all messages.
class FailureStateMessageHandler extends ServerStateMessageHandler {
  FailureStateMessageHandler(LspAnalysisServer server) : super(server);

  @override
  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    return error(
        ErrorCodes.InternalError,
        'An unrecoverable error occurred and the server cannot process messages',
        null);
  }
}

class InitializedStateMessageHandler extends ServerStateMessageHandler {
  InitializedStateMessageHandler(
    LspAnalysisServer server,
  ) : super(server) {
    reject(Method.initialize, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    reject(Method.initialized, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(new ShutdownMessageHandler(server));
    registerHandler(new ExitMessageHandler(server));
    registerHandler(
      new TextDocumentOpenHandler(
        server,
        server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles,
      ),
    );
    registerHandler(new TextDocumentChangeHandler(server));
    registerHandler(
      new TextDocumentCloseHandler(
        server,
        server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles,
      ),
    );
    registerHandler(new HoverHandler(server));
    registerHandler(new CompletionHandler(
      server,
      server.initializationOptions.suggestFromUnimportedLibraries,
    ));
    registerHandler(new CompletionResolveHandler(server));
    registerHandler(new SignatureHelpHandler(server));
    registerHandler(new DefinitionHandler(server));
    registerHandler(new SuperHandler(server));
    registerHandler(new ReferencesHandler(server));
    registerHandler(new ImplementationHandler(server));
    registerHandler(new FormattingHandler(server));
    registerHandler(new FormatOnTypeHandler(server));
    registerHandler(new DocumentHighlightsHandler(server));
    registerHandler(new DocumentSymbolHandler(server));
    registerHandler(new CodeActionHandler(server));
    registerHandler(new ExecuteCommandHandler(server));
    registerHandler(
      new WorkspaceFoldersHandler(
        server,
        !server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles,
      ),
    );
    registerHandler(new PrepareRenameHandler(server));
    registerHandler(new RenameHandler(server));
    registerHandler(new FoldingHandler(server));
    registerHandler(new DiagnosticServerHandler(server));
    registerHandler(new WorkspaceSymbolHandler(server));
  }
}

class InitializingStateMessageHandler extends ServerStateMessageHandler {
  InitializingStateMessageHandler(
    LspAnalysisServer server,
    List<String> openWorkspacePaths,
  ) : super(server) {
    reject(Method.initialize, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(new ShutdownMessageHandler(server));
    registerHandler(new ExitMessageHandler(server));
    registerHandler(new IntializedMessageHandler(
      server,
      openWorkspacePaths,
    ));
  }

  @override
  ErrorOr<void> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      server.instrumentationService
          .logInfo('Ignoring ${message.method} message while initializing');
      return success();
    }
    return error(
        ErrorCodes.ServerNotInitialized,
        'Unable to handle ${message.method} before the server is initialized '
        'and the client has sent the initialized notification');
  }
}

class UninitializedStateMessageHandler extends ServerStateMessageHandler {
  UninitializedStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(new ShutdownMessageHandler(server));
    registerHandler(new ExitMessageHandler(server));
    registerHandler(new InitializeMessageHandler(server));
  }

  @override
  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      server.instrumentationService
          .logInfo('Ignoring ${message.method} message while uninitialized');
      return success();
    }
    return error(ErrorCodes.ServerNotInitialized,
        'Unable to handle ${message.method} before client has sent initialize request');
  }
}

class ShuttingDownStateMessageHandler extends ServerStateMessageHandler {
  ShuttingDownStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(
        new ExitMessageHandler(server, clientDidCallShutdown: true));
  }

  @override
  FutureOr<ErrorOr<Object>> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      server.instrumentationService
          .logInfo('Ignoring ${message.method} message while shutting down');
      return success();
    }
    return error(ErrorCodes.InvalidRequest,
        'Unable to handle ${message.method} after shutdown request');
  }
}
