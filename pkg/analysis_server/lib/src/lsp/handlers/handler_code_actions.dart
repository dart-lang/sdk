// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Position;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart'
    show InconsistentAnalysisException;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart' show groupBy;

class CodeActionHandler extends MessageHandler<CodeActionParams,
    List<Either2<Command, CodeAction>>> {
  CodeActionHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_codeAction;

  @override
  LspJsonHandler<CodeActionParams> get jsonHandler =>
      CodeActionParams.jsonHandler;

  @override
  Future<ErrorOr<List<Either2<Command, CodeAction>>>> handle(
      CodeActionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final path = pathOfDoc(params.textDocument);
    if (!path.isError && !server.isAnalyzedFile(path.result)) {
      return success(const []);
    }

    final capabilities = server?.clientCapabilities?.textDocument;

    final clientSupportsWorkspaceApplyEdit =
        server?.clientCapabilities?.workspace?.applyEdit == true;

    final clientSupportsLiteralCodeActions =
        capabilities?.codeAction?.codeActionLiteralSupport != null;

    final clientSupportedCodeActionKinds = HashSet<CodeActionKind>.of(
        capabilities?.codeAction?.codeActionLiteralSupport?.codeActionKind
                ?.valueSet ??
            []);

    final clientSupportedDiagnosticTags = HashSet<DiagnosticTag>.of(
        capabilities?.publishDiagnostics?.tagSupport?.valueSet ?? []);

    final unit = await path.mapResult(requireResolvedUnit);

    return unit.mapResult((unit) {
      final startOffset = toOffset(unit.lineInfo, params.range.start);
      final endOffset = toOffset(unit.lineInfo, params.range.end);
      return startOffset.mapResult((startOffset) {
        return endOffset.mapResult((endOffset) {
          final offset = startOffset;
          final length = endOffset - startOffset;
          return _getCodeActions(
              clientSupportedCodeActionKinds,
              clientSupportsLiteralCodeActions,
              clientSupportsWorkspaceApplyEdit,
              clientSupportedDiagnosticTags,
              path.result,
              params.range,
              offset,
              length,
              unit);
        });
      });
    });
  }

  /// Creates a comparer for [CodeActions] that compares the column distance from [pos].
  Function(CodeAction a, CodeAction b) _codeActionColumnDistanceComparer(
      Position pos) {
    Position posOf(CodeAction action) => action.diagnostics.isNotEmpty
        ? action.diagnostics.first.range.start
        : pos;

    return (a, b) => _columnDistance(posOf(a), pos)
        .compareTo(_columnDistance(posOf(b), pos));
  }

  /// Returns the distance (in columns, ignoring lines) between two positions.
  int _columnDistance(Position a, Position b) =>
      (a.character - b.character).abs();

  /// Wraps a command in a CodeAction if the client supports it so that a
  /// CodeActionKind can be supplied.
  Either2<Command, CodeAction> _commandOrCodeAction(
    bool clientSupportsLiteralCodeActions,
    CodeActionKind kind,
    Command command,
  ) {
    return clientSupportsLiteralCodeActions
        ? Either2<Command, CodeAction>.t2(
            CodeAction(title: command.title, kind: kind, command: command),
          )
        : Either2<Command, CodeAction>.t1(command);
  }

  /// Creates a CodeAction to apply this assist. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  CodeAction _createAssistAction(Assist assist) {
    return CodeAction(
      title: assist.change.message,
      kind: toCodeActionKind(assist.change.id, CodeActionKind.Refactor),
      diagnostics: const [],
      edit: createWorkspaceEdit(server, assist.change.edits),
    );
  }

  /// Creates a CodeAction to apply this fix. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  CodeAction _createFixAction(Fix fix, Diagnostic diagnostic) {
    return CodeAction(
      title: fix.change.message,
      kind: toCodeActionKind(fix.change.id, CodeActionKind.QuickFix),
      diagnostics: [diagnostic],
      edit: createWorkspaceEdit(server, fix.change.edits),
    );
  }

  /// Creates a CodeAction command to apply a particular fix for all instances of
  /// a specific error in the file for [path].
  CodeAction _createFixAllCommand(Fix fix, Diagnostic diagnostic, String path) {
    final title = 'Apply all: ${fix.change.message}';
    return CodeAction(
      title: title,
      kind: CodeActionKind.QuickFix,
      diagnostics: [diagnostic],
      command: Command(
        command: Commands.fixAllOfErrorCodeInFile,
        title: title,
        arguments: [
          diagnostic.code,
          path,
          server.getVersionedDocumentIdentifier(path).version
        ],
      ),
    );
  }

  /// Dedupes/merges actions that have the same title, selecting the one nearest [pos].
  ///
  /// If actions perform the same edit/command, their diagnostics will be merged
  /// together. Otherwise, the additional accounts are just dropped.
  ///
  /// The first diagnostic for an action is used to determine the position (using
  /// its `start`). If there is no diagnostic, it will be treated as being at [pos].
  ///
  /// If multiple actions have the same position, one will arbitrarily be chosen.
  List<CodeAction> _dedupeActions(Iterable<CodeAction> actions, Position pos) {
    final groups = groupBy(actions, (CodeAction action) => action.title);
    return groups.keys.map((title) {
      final actions = groups[title];

      // If there's only one in the group, just return it.
      if (actions.length == 1) {
        return actions.single;
      }

      // Otherwise, find the action nearest to the caret.
      actions.sort(_codeActionColumnDistanceComparer(pos));
      final first = actions.first;

      // Get any actions with the same fix (edit/command) for merging diagnostics.
      final others = actions.skip(1).where(
            (other) =>
                // Compare either edits or commands based on which the selected action has.
                first.edit != null
                    ? first.edit == other.edit
                    : first.command != null
                        ? first.command == other.command
                        : false,
          );

      // Build a new CodeAction that merges the diagnostics from each same
      // code action onto a single one.
      return CodeAction(
        title: first.title,
        kind: first.kind,
        // Merge diagnostics from all of the matching CodeActions.
        diagnostics: [
          ...?first.diagnostics,
          for (final other in others) ...?other.diagnostics,
        ],
        edit: first.edit,
        command: first.command,
      );
    }).toList();
  }

  Future<List<Either2<Command, CodeAction>>> _getAssistActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    Range range,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    // We only support these for clients that advertise codeActionLiteralSupport.
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Refactor)) {
      return const [];
    }

    try {
      var context = DartAssistContextImpl(
        server.instrumentationService,
        DartChangeWorkspace(server.currentSessions),
        unit,
        offset,
        length,
      );
      final processor = AssistProcessor(context);
      final assists = await processor.compute();
      assists.sort(Assist.SORT_BY_RELEVANCE);

      final assistActions =
          _dedupeActions(assists.map(_createAssistAction), range.start);

      return assistActions
          .map((action) => Either2<Command, CodeAction>.t2(action))
          .toList();
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  Future<ErrorOr<List<Either2<Command, CodeAction>>>> _getCodeActions(
    HashSet<CodeActionKind> kinds,
    bool supportsLiterals,
    bool supportsWorkspaceApplyEdit,
    HashSet<DiagnosticTag> supportedDiagnosticTags,
    String path,
    Range range,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    final results = await Future.wait([
      _getSourceActions(
          kinds, supportsLiterals, supportsWorkspaceApplyEdit, path),
      _getAssistActions(kinds, supportsLiterals, range, offset, length, unit),
      _getRefactorActions(kinds, supportsLiterals, path, offset, length, unit),
      _getFixActions(
          kinds, supportsLiterals, supportedDiagnosticTags, range, unit),
    ]);
    final flatResults = results.expand((x) => x).toList();

    return success(flatResults);
  }

  Future<List<Either2<Command, CodeAction>>> _getFixActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    HashSet<DiagnosticTag> supportedDiagnosticTags,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // We only support these for clients that advertise codeActionLiteralSupport.
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.QuickFix)) {
      return const [];
    }

    final lineInfo = unit.lineInfo;
    final codeActions = <CodeAction>[];
    final fixAllCodeActions = <CodeAction>[];
    final fixContributor = DartFixContributor();

    try {
      final errorCodeCounts = <ErrorCode, int>{};
      // Count the errors by code so we know whether to include a fix-all.
      for (final error in unit.errors) {
        errorCodeCounts[error.errorCode] =
            (errorCodeCounts[error.errorCode] ?? 0) + 1;
      }

      // Because an error code may appear multiple times, cache the possible fixes
      // as we discover them to avoid re-computing them for a given diagnostic.
      final possibleFixesForErrorCode = <ErrorCode, Set<FixKind>>{};
      final workspace = DartChangeWorkspace(server.currentSessions);
      final processor =
          BulkFixProcessor(server.instrumentationService, workspace);

      for (final error in unit.errors) {
        // Server lineNumber is one-based so subtract one.
        var errorLine = lineInfo.getLocation(error.offset).lineNumber - 1;
        if (errorLine < range.start.line || errorLine > range.end.line) {
          continue;
        }
        var workspace = DartChangeWorkspace(server.currentSessions);
        var context = DartFixContextImpl(
            server.instrumentationService, workspace, unit, error, (name) {
          var tracker = server.declarationsTracker;
          return TopLevelDeclarationsProvider(tracker).get(
            unit.session.analysisContext,
            unit.path,
            name,
          );
        });
        final fixes = await fixContributor.computeFixes(context);
        if (fixes.isNotEmpty) {
          fixes.sort(Fix.SORT_BY_RELEVANCE);

          final diagnostic = toDiagnostic(
            unit,
            error,
            supportedTags: supportedDiagnosticTags,
          );
          codeActions.addAll(
            fixes.map((fix) => _createFixAction(fix, diagnostic)),
          );

          // Only consider an apply-all if there's more than one of these errors.
          if (errorCodeCounts[error.errorCode] > 1) {
            // Find out which fixes the bulk processor can handle.
            possibleFixesForErrorCode[error.errorCode] ??=
                processor.producableFixesForError(unit, error).toSet();

            // Get the intersection of single-fix kinds we created and those
            // the bulk processor can handle.
            final possibleFixes = possibleFixesForErrorCode[error.errorCode]
                .intersection(fixes.map((f) => f.kind).toSet())
                  // Exclude data-driven fixes as they're more likely to apply
                  // different fixes for the same error/fix kind that users
                  // might not expect.
                  ..remove(DartFixKind.DATA_DRIVEN);

            // Until we can apply a specific fix, only include apply-all when
            // there's exactly one.
            if (possibleFixes.length == 1) {
              fixAllCodeActions.addAll(fixes.map(
                  (fix) => _createFixAllCommand(fix, diagnostic, unit.path)));
            }
          }
        }
      }

      // Append all fix-alls to the very end.
      codeActions.addAll(fixAllCodeActions);

      final dedupedActions = _dedupeActions(codeActions, range.start);

      return dedupedActions
          .map((action) => Either2<Command, CodeAction>.t2(action))
          .toList();
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  Future<List<Either2<Command, CodeAction>>> _getRefactorActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    // The refactor actions supported are only valid for Dart files.
    if (!AnalysisEngine.isDartFileName(path)) {
      return const [];
    }

    // If the client told us what kinds they support but it does not include
    // Refactor then don't return any.
    if (clientSupportsLiteralCodeActions &&
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Refactor)) {
      return const [];
    }

    /// Helper to create refactors that execute commands provided with
    /// the current file, location and document version.
    Either2<Command, CodeAction> createRefactor(
      CodeActionKind actionKind,
      String name,
      RefactoringKind refactorKind, [
      Map<String, dynamic> options,
    ]) {
      return _commandOrCodeAction(
          clientSupportsLiteralCodeActions,
          actionKind,
          Command(
            title: name,
            command: Commands.performRefactor,
            arguments: [
              refactorKind.toJson(),
              path,
              server.getVersionedDocumentIdentifier(path).version,
              offset,
              length,
              options,
            ],
          ));
    }

    try {
      final refactorActions = <Either2<Command, CodeAction>>[];

      // Extract Method
      if (ExtractMethodRefactoring(server.searchEngine, unit, offset, length)
          .isAvailable()) {
        refactorActions.add(createRefactor(CodeActionKind.RefactorExtract,
            'Extract Method', RefactoringKind.EXTRACT_METHOD));
      }

      // Extract Widget
      if (ExtractWidgetRefactoring(server.searchEngine, unit, offset, length)
          .isAvailable()) {
        refactorActions.add(createRefactor(CodeActionKind.RefactorExtract,
            'Extract Widget', RefactoringKind.EXTRACT_WIDGET));
      }

      return refactorActions;
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  /// Gets "Source" CodeActions, which are actions that apply to whole files of
  /// source such as Sort Members and Organise Imports.
  Future<List<Either2<Command, CodeAction>>> _getSourceActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    bool clientSupportsWorkspaceApplyEdit,
    String path,
  ) async {
    // The source actions supported are only valid for Dart files.
    if (!AnalysisEngine.isDartFileName(path)) {
      return const [];
    }

    // If the client told us what kinds they support but it does not include
    // Source then don't return any.
    if (clientSupportsLiteralCodeActions &&
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Source)) {
      return const [];
    }

    // If the client does not support workspace/applyEdit, we won't be able to
    // run any of these.
    if (!clientSupportsWorkspaceApplyEdit) {
      return const [];
    }

    return [
      _commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        DartCodeActionKind.SortMembers,
        Command(
            title: 'Sort Members',
            command: Commands.sortMembers,
            arguments: [path]),
      ),
      _commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        CodeActionKind.SourceOrganizeImports,
        Command(
            title: 'Organize Imports',
            command: Commands.organizeImports,
            arguments: [path]),
      ),
    ];
  }
}
