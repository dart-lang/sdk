// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/custom/handler_diagnostic_server.dart';
import 'package:analysis_server/src/lsp/handlers/custom/handler_reanalyze.dart';
import 'package:analysis_server/src/lsp/handlers/custom/handler_super.dart';
import 'package:analysis_server/src/lsp/handlers/handler_call_hierarchy.dart';
import 'package:analysis_server/src/lsp/handlers/handler_change_workspace_folders.dart';
import 'package:analysis_server/src/lsp/handlers/handler_code_actions.dart';
import 'package:analysis_server/src/lsp/handlers/handler_completion.dart';
import 'package:analysis_server/src/lsp/handlers/handler_completion_resolve.dart';
import 'package:analysis_server/src/lsp/handlers/handler_definition.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_color.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_color_presentation.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_highlights.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_symbols.dart';
import 'package:analysis_server/src/lsp/handlers/handler_execute_command.dart';
import 'package:analysis_server/src/lsp/handlers/handler_exit.dart';
import 'package:analysis_server/src/lsp/handlers/handler_folding.dart';
import 'package:analysis_server/src/lsp/handlers/handler_format_on_type.dart';
import 'package:analysis_server/src/lsp/handlers/handler_format_range.dart';
import 'package:analysis_server/src/lsp/handlers/handler_formatting.dart';
import 'package:analysis_server/src/lsp/handlers/handler_hover.dart';
import 'package:analysis_server/src/lsp/handlers/handler_implementation.dart';
import 'package:analysis_server/src/lsp/handlers/handler_initialize.dart';
import 'package:analysis_server/src/lsp/handlers/handler_initialized.dart';
import 'package:analysis_server/src/lsp/handlers/handler_inlay_hint.dart';
import 'package:analysis_server/src/lsp/handlers/handler_references.dart';
import 'package:analysis_server/src/lsp/handlers/handler_rename.dart';
import 'package:analysis_server/src/lsp/handlers/handler_selection_range.dart';
import 'package:analysis_server/src/lsp/handlers/handler_semantic_tokens.dart';
import 'package:analysis_server/src/lsp/handlers/handler_shutdown.dart';
import 'package:analysis_server/src/lsp/handlers/handler_signature_help.dart';
import 'package:analysis_server/src/lsp/handlers/handler_text_document_changes.dart';
import 'package:analysis_server/src/lsp/handlers/handler_type_definition.dart';
import 'package:analysis_server/src/lsp/handlers/handler_type_hierarchy.dart';
import 'package:analysis_server/src/lsp/handlers/handler_will_rename_files.dart';
import 'package:analysis_server/src/lsp/handlers/handler_workspace_configuration.dart';
import 'package:analysis_server/src/lsp/handlers/handler_workspace_symbols.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

typedef _RequestHandlerGenerator<T extends AnalysisServer>
    = MessageHandler<Object?, Object?, T> Function(T);

/// The server moves to this state when a critical unrecoverable error (for
/// example, inconsistent document state between server/client) occurs and will
/// reject all messages.
class FailureStateMessageHandler extends ServerStateMessageHandler {
  FailureStateMessageHandler(super.server);

  @override
  FutureOr<ErrorOr<Object?>> handleUnknownMessage(IncomingMessage message) {
    return error(
        ErrorCodes.InternalError,
        'An unrecoverable error occurred and the server cannot process messages',
        null);
  }
}

class InitializedLspStateMessageHandler extends InitializedStateMessageHandler {
  /// Generators for handlers that require an [LspAnalysisServer].
  static const lspHandlerGenerators =
      <_RequestHandlerGenerator<LspAnalysisServer>>[
    ShutdownMessageHandler.new,
    ExitMessageHandler.new,
    TextDocumentOpenHandler.new,
    TextDocumentChangeHandler.new,
    TextDocumentCloseHandler.new,
    CompletionHandler.new,
    CompletionResolveHandler.new,
    DefinitionHandler.new,
    SuperHandler.new,
    ReferencesHandler.new,
    CodeActionHandler.new,
    ExecuteCommandHandler.new,
    ChangeWorkspaceFoldersHandler.new,
    PrepareRenameHandler.new,
    RenameHandler.new,
    FoldingHandler.new,
    DiagnosticServerHandler.new,
    WorkspaceDidChangeConfigurationMessageHandler.new,
    ReanalyzeHandler.new,
    WillRenameFilesHandler.new,
    SelectionRangeHandler.new,
    SemanticTokensFullHandler.new,
    SemanticTokensRangeHandler.new,
    InlayHintHandler.new,
  ];

  InitializedLspStateMessageHandler(
    LspAnalysisServer server,
  ) : super(server) {
    for (final generator in lspHandlerGenerators) {
      registerHandler(generator(server));
    }
  }
}

/// A message handler for the initialized state that can be used by either
/// server.
///
/// Only handlers that can work with either server are available. Use
/// [InitializedLspStateMessageHandler] for full LSP support.
class InitializedStateMessageHandler extends ServerStateMessageHandler {
  /// Generators for handlers that work with any [AnalysisServer].
  static const sharedHandlerGenerators =
      <_RequestHandlerGenerator<AnalysisServer>>[
    DocumentColorHandler.new,
    DocumentColorPresentationHandler.new,
    DocumentHighlightsHandler.new,
    DocumentSymbolHandler.new,
    FormatOnTypeHandler.new,
    FormatRangeHandler.new,
    FormattingHandler.new,
    HoverHandler.new,
    ImplementationHandler.new,
    IncomingCallHierarchyHandler.new,
    OutgoingCallHierarchyHandler.new,
    PrepareCallHierarchyHandler.new,
    PrepareTypeHierarchyHandler.new,
    SignatureHelpHandler.new,
    TypeDefinitionHandler.new,
    TypeHierarchySubtypesHandler.new,
    TypeHierarchySupertypesHandler.new,
    WorkspaceSymbolHandler.new,
  ];

  InitializedStateMessageHandler(
    AnalysisServer server,
  ) : super(server) {
    reject(Method.initialize, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    reject(Method.initialized, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');

    for (final generator in sharedHandlerGenerators) {
      registerHandler(generator(server));
    }
  }
}

class InitializingStateMessageHandler extends ServerStateMessageHandler {
  InitializingStateMessageHandler(
    LspAnalysisServer server,
    List<String> openWorkspacePaths,
  ) : super(server) {
    reject(Method.initialize, ServerErrorCodes.ServerAlreadyInitialized,
        'Server already initialized');
    registerHandler(ShutdownMessageHandler(server));
    registerHandler(ExitMessageHandler(server));
    registerHandler(InitializedMessageHandler(
      server,
      openWorkspacePaths,
    ));
  }

  @override
  ErrorOr<Object?> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      server.instrumentationService
          .logInfo('Ignoring ${message.method} message while initializing');
      return success(null);
    }
    return error(
        ErrorCodes.ServerNotInitialized,
        'Unable to handle ${message.method} before the server is initialized '
        'and the client has sent the initialized notification');
  }
}

class ShuttingDownStateMessageHandler extends ServerStateMessageHandler {
  ShuttingDownStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(ExitMessageHandler(server, clientDidCallShutdown: true));
  }

  @override
  FutureOr<ErrorOr<Object?>> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      server.instrumentationService
          .logInfo('Ignoring ${message.method} message while shutting down');
      return success(null);
    }
    return error(ErrorCodes.InvalidRequest,
        'Unable to handle ${message.method} after shutdown request');
  }
}

class UninitializedStateMessageHandler extends ServerStateMessageHandler {
  UninitializedStateMessageHandler(LspAnalysisServer server) : super(server) {
    registerHandler(ShutdownMessageHandler(server));
    registerHandler(ExitMessageHandler(server));
    registerHandler(InitializeMessageHandler(server));
  }

  @override
  FutureOr<ErrorOr<Object?>> handleUnknownMessage(IncomingMessage message) {
    // Silently drop non-requests.
    if (message is! RequestMessage) {
      server.instrumentationService
          .logInfo('Ignoring ${message.method} message while uninitialized');
      return success(null);
    }
    return error(ErrorCodes.ServerNotInitialized,
        'Unable to handle ${message.method} before client has sent initialize request');
  }
}
