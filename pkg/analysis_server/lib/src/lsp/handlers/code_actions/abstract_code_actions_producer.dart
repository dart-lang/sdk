// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Position;
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:meta/meta.dart';

/// A base for classes that produce [CodeAction]s for the LSP handler.
abstract class AbstractCodeActionsProducer
    with RequestHandlerMixin<LspAnalysisServer> {
  final String path;
  final LineInfo lineInfo;
  final int offset;
  final int length;
  final bool Function(CodeActionKind?) shouldIncludeKind;
  final LspClientCapabilities capabilities;

  @override
  final LspAnalysisServer server;

  AbstractCodeActionsProducer(
    this.server,
    this.path,
    this.lineInfo, {
    required this.offset,
    required this.length,
    required this.shouldIncludeKind,
    required this.capabilities,
  });

  String get name;

  Set<DiagnosticTag> get supportedDiagnosticTags => capabilities.diagnosticTags;

  bool get supportsApplyEdit => capabilities.applyEdit;

  bool get supportsCodeDescription => capabilities.diagnosticCodeDescription;

  bool get supportsLiterals => capabilities.literalCodeActions;

  /// Creates a CodeAction to apply this assist. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  @protected
  CodeAction createAssistAction(
      SourceChange change, String path, LineInfo lineInfo) {
    return CodeAction(
      title: change.message,
      kind: toCodeActionKind(change.id, CodeActionKind.Refactor),
      diagnostics: const [],
      edit: createWorkspaceEdit(server, change,
          allowSnippets: true, filePath: path, lineInfo: lineInfo),
    );
  }

  /// Creates a CodeAction to apply this fix. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  @protected
  CodeAction createFixAction(SourceChange change, Diagnostic diagnostic,
      String path, LineInfo lineInfo) {
    return CodeAction(
      title: change.message,
      kind: toCodeActionKind(change.id, CodeActionKind.QuickFix),
      diagnostics: [diagnostic],
      edit: createWorkspaceEdit(server, change,
          allowSnippets: true, filePath: path, lineInfo: lineInfo),
    );
  }

  Future<List<CodeActionWithPriority>> getAssistActions();

  Future<List<CodeActionWithPriority>> getFixActions();

  Future<List<Either2<CodeAction, Command>>> getRefactorActions();

  Future<List<Either2<CodeAction, Command>>> getSourceActions();
}

/// A wrapper that contains an LSP [CodeAction] and a server-supplied priority
/// used for sorting before sending to the client.
class CodeActionWithPriority {
  final CodeAction action;
  final int priority;

  CodeActionWithPriority(this.action, this.priority);
}
