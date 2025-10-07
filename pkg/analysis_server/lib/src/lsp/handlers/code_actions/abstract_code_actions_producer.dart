// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/lsp/handlers/commands/apply_code_action.dart';
library;

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart'
    hide AnalysisOptions, Position;
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:meta/meta.dart';

typedef CodeActionWithPriority = ({CodeAction action, int priority});

typedef CodeActionWithPriorityAndIndex = ({
  CodeAction action,
  int priority,
  int index,
});

/// A base for classes that produce [CodeAction]s for the LSP handler.
abstract class AbstractCodeActionsProducer
    with RequestHandlerMixin<AnalysisServer> {
  final File file;
  final LineInfo lineInfo;
  final int offset;
  final int length;
  final bool Function(CodeActionKind?) shouldIncludeKind;

  /// Whether non-standard LSP snippets are allowed in edits produced.
  ///
  /// This is usually true for the `textDocument/codeAction` request (because we
  /// support it for [CodeActionLiteral]s) but `false` for the
  /// [Commands.applyCodeAction] handler because it's not supported for
  /// `workspace/applyEdit` reverse requests.
  final bool allowSnippets;

  /// The capabilities of the caller making the request for [CodeAction]s.
  final LspClientCapabilities callerCapabilities;

  /// The capabilities of the editor (which may or may not be the same as
  /// [callerCapabilities] depending on whether the request came from the editor
  /// or another client - such as over DTD).
  final LspClientCapabilities editorCapabilities;

  final AnalysisOptions analysisOptions;

  @override
  final AnalysisServer server;

  /// Whether [CodeAction]s can be [Command]s or not.
  ///
  /// This is usually true (because there is no capability for this), however
  /// it will be disabled by [ApplyCodeActionCommandHandler] so that we can't
  /// recursively return command-based actions.
  final bool allowCommands;

  /// Whether [CodeAction]s can be [CodeActionLiteral]s or not.
  ///
  /// This is usually based on the callers capabilities, however
  /// for [ApplyCodeActionCommandHandler] it will be based on the editor's
  /// capabilities since it will compute the edits and send them to the editor
  /// directly.
  final bool allowCodeActionLiterals;

  AbstractCodeActionsProducer(
    this.server,
    this.file,
    this.lineInfo, {
    required this.offset,
    required this.length,
    required this.shouldIncludeKind,
    required this.callerCapabilities,
    required this.editorCapabilities,
    required this.allowCommands,
    required this.allowCodeActionLiterals,
    required this.allowSnippets,
    required this.analysisOptions,
  });

  Set<DiagnosticTag> get callerSupportedDiagnosticTags =>
      callerCapabilities.diagnosticTags;

  bool get callerSupportsCodeDescription =>
      callerCapabilities.diagnosticCodeDescription;

  bool get editorSupportsApplyEdit => editorCapabilities.applyEdit;

  String get name;

  String get path => file.path;

  /// Creates a command to apply a CodeAction later.
  Command createApplyCodeActionCommand(
    String title,
    CodeActionKind kind,
    String? loggedId,
    OptionalVersionedTextDocumentIdentifier textDocument,
    Range range,
  ) {
    return Command(
      title: title,
      command: Commands.applyCodeAction,
      // The arguments here must match those in `ApplyCodeActionCommandHandler`.
      arguments: [
        {
          'textDocument': textDocument,
          'range': range,
          'kind': kind,
          'loggedAction': loggedId,
        },
      ],
    );
  }

  /// Creates a CodeAction to apply this change.
  ///
  /// This code will fetch the version of each document being modified so it's
  /// important to call this immediately after computing edits to ensure the
  /// document is not modified before the version number is read.
  @protected
  CodeActionLiteral createCodeActionLiteral(
    protocol.SourceChange change,
    CodeActionKind kind,
    String? loggedId,
    String path,
    LineInfo lineInfo, {
    Diagnostic? diagnostic,
  }) {
    return CodeActionLiteral(
      title: change.message,
      kind: kind,
      diagnostics: diagnostic != null ? [diagnostic] : const [],
      command: createLogActionCommand(loggedId),
      edit: createWorkspaceEdit(
        server,
        editorCapabilities,
        change,
        allowSnippets: allowSnippets,
        filePath: path,
        lineInfo: lineInfo,
      ),
    );
  }

  /// Creates a [CodeAction] that is:
  ///
  /// - a [CodeActionLiteral] if [allowCodeActionLiterals], or
  /// - a [Command] for [Commands.applyCodeAction] if [allowCommands], or
  /// - null
  CodeAction? createCodeActionLiteralOrApplyCommand(
    String path,
    OptionalVersionedTextDocumentIdentifier textDocument,
    Range range,
    LineInfo lineInfo,
    SourceChange change,
    CodeActionKind kind,
    String? loggedId, {
    Diagnostic? diagnostic,
  }) {
    if (allowCodeActionLiterals) {
      return CodeAction.t1(
        createCodeActionLiteral(
          change,
          kind,
          loggedId,
          path,
          lineInfo,
          diagnostic: diagnostic,
        ),
      );
    } else if (allowCommands) {
      return CodeAction.t2(
        createApplyCodeActionCommand(
          change.message,
          kind,
          loggedId,
          textDocument,
          range,
        ),
      );
    } else {
      return null;
    }
  }

  /// Create an LSP [Diagnostic] for [diagnostic].
  @protected
  Diagnostic createDiagnostic(
    LineInfo lineInfo,
    engine.ErrorsResultImpl result,
    engine.Diagnostic diagnostic,
  ) {
    return pluginToDiagnostic(
      server.uriConverter,
      (_) => lineInfo,
      protocol.newAnalysisError_fromEngine(result, diagnostic),
      supportedTags: callerSupportedDiagnosticTags,
      clientSupportsCodeDescription: callerSupportsCodeDescription,
    );
  }

  /// Creates a command to log that a CodeAction was selected.
  ///
  /// Code Actions that provide their edits inline (and not via a command) do
  /// not normally call back to the server when an action is selected so this
  /// provides some visibility of them being chosen.
  Command? createLogActionCommand(String? action) {
    if (action == null) {
      return null;
    }

    return Command(
      command: Commands.logAction,
      title: 'Log Action',
      arguments: [
        {'action': action},
      ],
    );
  }

  @protected
  engine.ErrorsResultImpl createResult(
    AnalysisSession session,
    LineInfo lineInfo,
    List<engine.Diagnostic> diagnostics,
  ) {
    return engine.ErrorsResultImpl(
      session: session,
      file: file,
      content: file.readAsStringSync(),
      uri: server.uriConverter.toClientUri(path),
      lineInfo: lineInfo,
      isLibrary: true,
      isPart: false,
      diagnostics: diagnostics,
      analysisOptions: analysisOptions,
    );
  }

  Future<List<CodeActionWithPriority>> getAssistActions({
    OperationPerformanceImpl? performance,
  });

  Future<List<CodeActionWithPriority>> getFixActions(
    OperationPerformance? performance,
  );

  Future<List<CodeAction>> getRefactorActions(
    OperationPerformance? performance,
  );

  Future<List<CodeAction>> getSourceActions();

  /// Return the contents of the [file], or `null` if the file does not exist or
  /// cannot be read.
  @protected
  String? safelyRead(File file) {
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }

  /// Checks whether the server supports a given command.
  bool serverSupportsCommand(String command) {
    var handler = server.executeCommandHandler;

    // `null` should never happen, it's set by the constructor of
    // ExecuteCommandHandler which is invoked as part of initialization.
    assert(handler != null);
    if (handler == null) {
      return false;
    }

    return handler.commandHandlers[command] != null;
  }
}
