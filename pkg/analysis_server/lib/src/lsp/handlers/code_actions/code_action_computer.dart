// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/lsp/handlers/commands/apply_code_action.dart';
/// @docImport 'package:language_server_protocol/protocol_special.dart';
/// @docImport 'package:analysis_server/src/lsp/handlers/handler_code_actions.dart';
library;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/analysis_options.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/dart.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/plugins.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/pubspec.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart' show groupBy;
import 'package:path/src/context.dart';

/// A helper class for computing [CodeAction]s that is used by both the
/// [CodeActionHandler] and [ApplyCodeActionCommandHandler].
class CodeActionComputer with HandlerHelperMixin<AnalysisServer> {
  /// The text document to compute code actions for.
  final TextDocumentIdentifier textDocument;

  /// The range to compute code actions for.
  final Range range;

  /// The kinds of [CodeAction]s the caller would like returned.
  ///
  /// Code actions can be filtered by kind, even if they will ultimately be
  /// returned as [Command]s (without kinds).
  final List<CodeActionKind>? only;

  /// How the request was triggered.
  final CodeActionTriggerKind? triggerKind;

  /// Whether non-standard LSP snippets are allowed in edits produced.
  ///
  /// This is usually true for the `textDocument/codeAction` request (because we
  /// support it for [CodeActionLiteral]s) but `false` for the
  /// [Commands.applyCodeAction] handler because it's not supported for
  /// `workspace/applyEdit` reverse requests.
  final bool allowSnippets;

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

  final OperationPerformanceImpl performance;

  /// The capabilities of the caller making the request for [CodeAction]s.
  final LspClientCapabilities callerCapabilities;

  /// The capabilities of the editor (which may or may not be the same as
  /// [callerCapabilities] depending on whether the request came from the editor
  /// or another client - such as over DTD).
  final LspClientCapabilities editorCapabilities;

  @override
  final AnalysisServer server;

  /// The kinds of [CodeAction]s that the caller supports.
  ///
  /// `null` if the caller does not support [CodeActionLiteral]s.
  ///
  /// This set is ignored if the caller provided an explicit filter in [only].
  final Set<CodeActionKind>? supportedKinds;

  CodeActionComputer(
    this.server,
    this.textDocument,
    this.range, {
    required this.editorCapabilities,
    required this.callerCapabilities,
    required this.only,
    required this.supportedKinds,
    required this.triggerKind,
    required this.allowCommands,
    required this.allowCodeActionLiterals,
    required this.allowSnippets,
    required this.performance,
  });

  Future<ErrorOr<TextDocumentCodeActionResult>> compute() {
    var path = pathOfDoc(textDocument);
    return path.mapResult((unitPath) async {
      if (!server.isAnalyzed(unitPath) ||
          !isEditableDocument(textDocument.uri)) {
        return success(const []);
      }

      var pathContext = server.resourceProvider.pathContext;
      var docIdentifier = server.getVersionedDocumentIdentifier(unitPath);

      var library = await requireResolvedLibrary(unitPath);
      var libraryResult = library.resultOrNull;
      var unit = libraryResult?.unitWithPath(unitPath);

      // For non-Dart files we don't have a unit and must get the best LineInfo we
      // can for current content.
      var lineInfo = unit?.lineInfo ?? server.getLineInfo(unitPath);
      if (lineInfo == null) {
        return success([]);
      }

      var startOffset = toOffset(lineInfo, range.start);
      var endOffset = toOffset(lineInfo, range.end);
      if (startOffset.isError || endOffset.isError) {
        return success([]);
      }

      return (startOffset, endOffset).mapResults((
        startOffset,
        endOffset,
      ) async {
        var actions = await _computeActions(
          startOffset,
          endOffset,
          pathContext,
          unitPath,
          unit,
          libraryResult,
          lineInfo,
          docIdentifier,
        );

        return success(actions);
      });
    });
  }

  /// Whether any fixes of kind [kind] should be included in the results.
  ///
  /// Unlike [shouldIncludeKind], this function is called with a more general
  /// action kind and answers the question "Should we include any actions of
  /// kind CodeActionKind.Source?".
  bool shouldIncludeAnyOfKind(CodeActionKind? kind) {
    /// Checks whether the kind matches the [wanted] kind.
    ///
    /// If `kind` is `refactor.foo` then for these `wanted` values:
    ///  - wanted=refactor.foo - true
    ///  - wanted=refactor.foo.bar - true
    ///  - wanted=refactor - false
    ///  - wanted=refactor.bar - false
    bool isMatch(CodeActionKind wanted) =>
        kind == wanted || wanted.toString().startsWith('$kind.');

    if (only case var only?) {
      return only.any(isMatch);
    }

    return true;
  }

  /// Whether a fix of kind [kind] should be included in the results.
  ///
  /// Unlike [shouldIncludeAnyOfKind], this function is called with a more
  /// specific action kind and answers the question "Should we include this
  /// specific fix kind?".
  bool shouldIncludeKind(CodeActionKind? kind) {
    /// Checks whether the kind matches the [wanted] kind.
    ///
    /// If `wanted` is `refactor.foo` then:
    ///  - refactor.foo - included
    ///  - refactor.foobar - not included
    ///  - refactor.foo.bar - included
    bool isMatch(CodeActionKind wanted) =>
        kind == wanted || kind.toString().startsWith('$wanted.');

    // If the client wants only a specific set, use only that filter.
    if (only case var only?) {
      return only.any(isMatch);
    }

    // Otherwise, filter out anything not supported by the client (if they
    // advertised that they provided the kinds).
    if (supportedKinds case var supportedKinds?) {
      return supportedKinds.any(isMatch);
    }

    return true;
  }

  Future<List<CodeAction>> _computeActions(
    int startOffset,
    int endOffset,
    Context pathContext,
    String unitPath,
    ResolvedUnitResult? unit,
    ResolvedLibraryResult? libraryResult,
    LineInfo lineInfo,
    OptionalVersionedTextDocumentIdentifier docIdentifier,
  ) async {
    var offset = startOffset;
    var length = endOffset - startOffset;

    var isDart = file_paths.isDart(pathContext, unitPath);
    var isPubspec = file_paths.isPubspecYaml(pathContext, unitPath);
    var isAnalysisOptions = file_paths.isAnalysisOptionsYaml(
      pathContext,
      unitPath,
    );
    var includeSourceActions = shouldIncludeAnyOfKind(CodeActionKind.Source);
    var includeQuickFixes = shouldIncludeAnyOfKind(CodeActionKind.QuickFix);
    var includeRefactors = shouldIncludeAnyOfKind(CodeActionKind.Refactor);

    var analysisOptions = await _getOptions(unitPath, unit);

    var actionComputers = [
      if (isDart && libraryResult != null && unit != null)
        DartCodeActionsProducer(
          server,
          unit.file,
          lineInfo,
          docIdentifier,
          range: range,
          offset: offset,
          length: length,
          libraryResult,
          unit,
          shouldIncludeKind: shouldIncludeKind,
          editorCapabilities: editorCapabilities,
          callerCapabilities: callerCapabilities,
          allowCodeActionLiterals: allowCodeActionLiterals,
          allowCommands: allowCommands,
          allowSnippets: allowSnippets,
          analysisOptions: analysisOptions,
          triggerKind: triggerKind,
          willBeDeduplicated: true,
        ),
      if (isPubspec)
        PubspecCodeActionsProducer(
          server,
          // TODO(pq): can we do better?
          server.resourceProvider.getFile(unitPath),
          lineInfo,
          offset: offset,
          length: length,
          shouldIncludeKind: shouldIncludeKind,
          editorCapabilities: editorCapabilities,
          callerCapabilities: callerCapabilities,
          allowCodeActionLiterals: allowCodeActionLiterals,
          allowCommands: allowCommands,
          allowSnippets: allowSnippets,
          analysisOptions: analysisOptions,
        ),
      if (isAnalysisOptions)
        AnalysisOptionsCodeActionsProducer(
          server,
          // TODO(pq): can we do better?
          server.resourceProvider.getFile(unitPath),
          lineInfo,
          offset: offset,
          length: length,
          shouldIncludeKind: shouldIncludeKind,
          editorCapabilities: editorCapabilities,
          callerCapabilities: callerCapabilities,
          allowCodeActionLiterals: allowCodeActionLiterals,
          allowCommands: allowCommands,
          allowSnippets: allowSnippets,
          analysisOptions: analysisOptions,
        ),
      PluginCodeActionsProducer(
        server,
        // TODO(pq): can we do better?
        server.resourceProvider.getFile(unitPath),
        lineInfo,
        offset: offset,
        length: length,
        shouldIncludeKind: shouldIncludeKind,
        editorCapabilities: editorCapabilities,
        callerCapabilities: callerCapabilities,
        allowCodeActionLiterals: allowCodeActionLiterals,
        allowCommands: allowCommands,
        allowSnippets: allowSnippets,
        analysisOptions: analysisOptions,
      ),
    ];
    var sorter = _CodeActionSorter(range);

    var allActions = <CodeAction>[
      // Like-kinded actions are grouped (and prioritized) together
      // regardless of which producer they came from.

      // Source.
      if (includeSourceActions)
        for (var computer in actionComputers)
          ...await performance.runAsync(
            '${computer.name}.getSourceActions',
            (_) => computer.getSourceActions(),
          ),

      // Fixes.
      if (includeQuickFixes)
        ...sorter.sort([
          for (var computer in actionComputers)
            ...await performance.runAsync(
              '${computer.name}.getFixActions',
              (_) => computer.getFixActions(performance),
            ),
        ]),

      // Refactors  (Assists + Refactors).
      if (includeRefactors)
        ...sorter.sort([
          for (var computer in actionComputers)
            ...await performance.runAsync(
              '${computer.name}.getAssistActions',
              (_) => computer.getAssistActions(performance: performance),
            ),
        ]),
      if (includeRefactors)
        for (var computer in actionComputers)
          ...await performance.runAsync(
            '${computer.name}.getRefactorActions',
            (_) => computer.getRefactorActions(performance),
          ),
    ];
    return allActions;
  }

  Future<AnalysisOptions> _getOptions(
    String unitPath,
    ResolvedUnitResult? unit,
  ) async {
    if (unit != null) return unit.analysisOptions;
    var session = await server.getAnalysisSession(unitPath);
    var fileResult = session?.getFile(unitPath);
    if (fileResult is FileResult) return fileResult.analysisOptions;
    // Default to empty options.
    return AnalysisOptionsImpl();
  }
}

/// Sorts [CodeActionWithPriority]s by priority, and removes duplicates keeping
/// the one nearest [range].
class _CodeActionSorter {
  final Range range;

  _CodeActionSorter(this.range);

  List<CodeAction> sort(List<CodeActionWithPriority> actions) {
    var dedupedActions = _dedupeActions(actions, range.start);

    // Add each index so we can do a stable sort on priority.
    var dedupedActionsWithIndex =
        dedupedActions.indexed.map((item) {
          var (index, action) = item;
          return (
            action: action.action,
            priority: action.priority,
            index: index,
          );
        }).toList();
    dedupedActionsWithIndex.sort(_compareCodeActions);

    return dedupedActionsWithIndex.map((action) => action.action).toList();
  }

  /// Creates a comparer for [CodeAction]s that compares the column
  /// distance from [pos].
  ///
  /// If a [CodeAction] has no diagnostics, considers the action at [pos].
  int Function(CodeAction a, CodeAction b) _codeActionColumnDistanceComparer(
    Position pos,
  ) {
    Position posOf(CodeAction action) {
      var diagnostics = action.map(
        (literal) => literal.diagnostics,
        (command) => null,
      );
      return diagnostics != null && diagnostics.isNotEmpty
          ? diagnostics.first.range.start
          : pos;
    }

    return (a, b) => _columnDistance(
      posOf(a),
      pos,
    ).compareTo(_columnDistance(posOf(b), pos));
  }

  /// Returns the distance (in columns, ignoring lines) between two positions.
  int _columnDistance(Position a, Position b) =>
      (a.character - b.character).abs();

  /// A function that can be used to sort [CodeActionWithPriorityAndIndex]es.
  ///
  /// The highest number priority will be sorted before lower number priorities.
  /// Items with the same priority are sorted by their index (ascending).
  int _compareCodeActions(
    CodeActionWithPriorityAndIndex a,
    CodeActionWithPriorityAndIndex b,
  ) {
    // Priority, descending.
    if (a.priority != b.priority) {
      return b.priority - a.priority;
    }
    // Index, ascending.
    assert(a.index != b.index);
    if (a.index != b.index) {
      return a.index - b.index;
    }
    // We should never have the same index, but just in case - ensure the sort
    // is stable.
    return a.action.title.compareTo(b.action.title);
  }

  /// Dedupes/merges actions that have the same title, selecting the one nearest
  /// [position].
  ///
  /// If actions perform the same edit/command, their diagnostics will be merged
  /// together. Otherwise, the additional accounts are just dropped.
  ///
  /// The first diagnostic for an action is used to determine the position
  /// (using its `start`). If there is no diagnostic, it will be treated as
  /// being at [position].
  ///
  /// If multiple actions have the same position, one will arbitrarily be
  /// chosen.
  List<CodeActionWithPriority> _dedupeActions(
    Iterable<CodeActionWithPriority> actions,
    Position position,
  ) {
    var groups = groupBy(
      actions,
      (CodeActionWithPriority action) => action.action.title,
    );
    return groups.entries.map((entry) {
      var actions = entry.value;

      // If there's only one in the group, just return it.
      if (actions.length == 1) {
        return actions.single;
      }

      // Otherwise, find the action nearest to the caret.
      var comparer = _codeActionColumnDistanceComparer(position);
      actions.sort((a, b) => comparer(a.action, b.action));
      var first = actions.first;
      var firstAction = first.action;
      var priority = actions.first.priority;

      // If this action is not a literal (it is a command), just return as-is
      // because we can't merge any diagnostics into it.
      var firstLiteral = firstAction.map(
        (literal) => literal,
        (command) => null,
      );
      if (firstLiteral == null) {
        return first;
      }

      // Get any literal actions with the same fix (edit/command) for merging
      // diagnostics.
      var others = actions
          .skip(1)
          .map(
            (action) =>
                action.action.map((literal) => literal, (command) => null),
          )
          .nonNulls
          .where((other) {
            // Compare either edits or commands based on which the selected action has.
            return firstLiteral.edit != null
                ? firstLiteral.edit == other.edit
                : firstLiteral.command != null &&
                    firstLiteral.command == other.command;
          });

      // Build a new CodeAction that merges the diagnostics from each same
      // code action onto a single one.
      return (
        action: CodeAction.t1(
          CodeActionLiteral(
            title: firstAction.title,
            kind: firstLiteral.kind,
            // Merge diagnostics from all of the matching CodeActions.
            diagnostics: [
              ...?firstLiteral.diagnostics,
              for (var other in others) ...?other.diagnostics,
            ],
            edit: firstLiteral.edit,
            command: firstAction.command,
          ),
        ),
        priority: priority,
      );
    }).toList();
  }
}
