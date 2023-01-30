// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/analysis_options.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/dart.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/plugins.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/pubspec.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:collection/collection.dart' show groupBy;

class CodeActionHandler
    extends MessageHandler<CodeActionParams, TextDocumentCodeActionResult> {
  CodeActionHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_codeAction;

  @override
  LspJsonHandler<CodeActionParams> get jsonHandler =>
      CodeActionParams.jsonHandler;

  @override
  Future<ErrorOr<TextDocumentCodeActionResult>> handle(CodeActionParams params,
      MessageInfo message, CancellationToken token) async {
    final performance = message.performance;

    final path = pathOfDoc(params.textDocument);
    if (path.isError) {
      return failure(path);
    }
    final unitPath = path.result;
    if (!server.isAnalyzed(unitPath)) {
      return success(const []);
    }

    final capabilities = server.clientCapabilities;
    if (capabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    final supportsLiterals = capabilities.literalCodeActions;
    final supportedKinds = capabilities.codeActionKinds;

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
      final only = params.context.only;
      if (only != null) {
        return only.any(isMatch);
      }

      // Otherwise, filter out anything not supported by the client (if they
      // advertised that they provided the kinds).
      if (supportsLiterals && !supportedKinds.any(isMatch)) {
        return false;
      }

      return true;
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

      final only = params.context.only;
      if (only != null) {
        return only.any(isMatch);
      }

      return true;
    }

    final pathContext = server.resourceProvider.pathContext;
    final docIdentifier = server.getVersionedDocumentIdentifier(unitPath);

    final library = await requireResolvedLibrary(unitPath);
    final libraryResult = library.resultOrNull;
    final unit = libraryResult?.unitWithPath(unitPath);

    // For non-Dart files we don't have a unit and must get the best LineInfo we
    // can for current content.
    final lineInfo = unit?.lineInfo ?? server.getLineInfo(unitPath);
    if (lineInfo == null) {
      return success([]);
    }

    final startOffset = toOffset(lineInfo, params.range.start);
    final endOffset = toOffset(lineInfo, params.range.end);
    if (startOffset.isError || endOffset.isError) {
      return success([]);
    }

    final startOffsetResult = startOffset.result;
    final endOffsetResult = endOffset.result;

    final offset = startOffsetResult;
    final length = endOffsetResult - startOffsetResult;

    final isDart = file_paths.isDart(pathContext, unitPath);
    final isPubspec = file_paths.isPubspecYaml(pathContext, unitPath);
    final isAnalysisOptions =
        file_paths.isAnalysisOptionsYaml(pathContext, unitPath);
    final includeSourceActions = shouldIncludeAnyOfKind(CodeActionKind.Source);
    final includeQuickFixes = shouldIncludeAnyOfKind(CodeActionKind.QuickFix);
    final includeRefactors = shouldIncludeAnyOfKind(CodeActionKind.Refactor);

    final actionComputers = [
      if (isDart && libraryResult != null && unit != null)
        DartCodeActionsProducer(
          server,
          unitPath,
          lineInfo,
          docIdentifier,
          range: params.range,
          offset: offset,
          length: length,
          libraryResult,
          unit,
          shouldIncludeKind: shouldIncludeKind,
          capabilities: capabilities,
          triggerKind: params.context.triggerKind,
        ),
      if (isPubspec)
        PubspecCodeActionsProducer(
          server,
          unitPath,
          lineInfo,
          offset: offset,
          length: length,
          shouldIncludeKind: shouldIncludeKind,
          capabilities: capabilities,
        ),
      if (isAnalysisOptions)
        AnalysisOptionsCodeActionsProducer(
          server,
          unitPath,
          lineInfo,
          offset: offset,
          length: length,
          shouldIncludeKind: shouldIncludeKind,
          capabilities: capabilities,
        ),
      PluginCodeActionsProducer(
        server,
        unitPath,
        lineInfo,
        offset: offset,
        length: length,
        shouldIncludeKind: shouldIncludeKind,
        capabilities: capabilities,
      ),
    ];
    final sorter = _CodeActionSorter(params.range, shouldIncludeKind);

    final allActions = <Either2<CodeAction, Command>>[
      // Like-kinded actions are grouped (and prioritized) together
      // regardless of which producer they came from.

      // Source.
      if (includeSourceActions)
        for (final computer in actionComputers)
          ...await performance.runAsync('${computer.name}.getSourceActions',
              (_) => computer.getSourceActions()),

      // Fixes.
      if (includeQuickFixes)
        ...sorter.sort([
          for (final computer in actionComputers)
            ...await performance.runAsync('${computer.name}.getFixActions',
                (_) => computer.getFixActions()),
        ]),

      // Refactors  (Assists + Refactors).
      if (includeRefactors)
        ...sorter.sort([
          for (final computer in actionComputers)
            ...await performance.runAsync('${computer.name}.getAssistActions',
                (_) => computer.getAssistActions()),
        ]),
      if (includeRefactors)
        for (final computer in actionComputers)
          ...await performance.runAsync('${computer.name}.getRefactorActions',
              (_) => computer.getRefactorActions()),
    ];

    return success(allActions);
  }
}

/// Sorts [CodeActionWithPriority]s by priority, and removes duplicates keeping
/// the one nearest [range].
class _CodeActionSorter {
  final Range range;
  final bool Function(CodeActionKind?) shouldIncludeKind;

  _CodeActionSorter(this.range, this.shouldIncludeKind);

  List<Either2<CodeAction, Command>> sort(
      List<CodeActionWithPriority> actions) {
    final dedupedCodeActions = _dedupeActions(actions, range.start);
    dedupedCodeActions.sort(_compareCodeActions);

    return dedupedCodeActions
        .where((action) => shouldIncludeKind(action.action.kind))
        .map((action) => Either2<CodeAction, Command>.t1(action.action))
        .toList();
  }

  /// Creates a comparer for [CodeActions] that compares the column distance from [pos].
  int Function(CodeAction a, CodeAction b) _codeActionColumnDistanceComparer(
      Position pos) {
    Position posOf(CodeAction action) {
      final diagnostics = action.diagnostics;
      return diagnostics != null && diagnostics.isNotEmpty
          ? diagnostics.first.range.start
          : pos;
    }

    return (a, b) => _columnDistance(posOf(a), pos)
        .compareTo(_columnDistance(posOf(b), pos));
  }

  /// Returns the distance (in columns, ignoring lines) between two positions.
  int _columnDistance(Position a, Position b) =>
      (a.character - b.character).abs();

  /// A function that can be used to sort [CodeActionWithPriority]s.
  ///
  /// The highest number priority will be sorted before lower number priorities.
  /// Items with the same priority are sorted alphabetically by their title.
  int _compareCodeActions(CodeActionWithPriority a, CodeActionWithPriority b) {
    if (a.priority != b.priority) {
      return b.priority - a.priority;
    }
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
      Iterable<CodeActionWithPriority> actions, Position position) {
    final groups = groupBy(
        actions, (CodeActionWithPriority action) => action.action.title);
    return groups.entries.map((entry) {
      final actions = entry.value;

      // If there's only one in the group, just return it.
      if (actions.length == 1) {
        return actions.single;
      }

      // Otherwise, find the action nearest to the caret.
      final comparer = _codeActionColumnDistanceComparer(position);
      actions.sort((a, b) => comparer(a.action, b.action));
      final first = actions.first.action;
      final priority = actions.first.priority;

      // Get any actions with the same fix (edit/command) for merging diagnostics.
      final others = actions.skip(1).where(
            (other) =>
                // Compare either edits or commands based on which the selected action has.
                first.edit != null
                    ? first.edit == other.action.edit
                    : first.command != null
                        ? first.command == other.action.command
                        : false,
          );

      // Build a new CodeAction that merges the diagnostics from each same
      // code action onto a single one.
      return CodeActionWithPriority(
        CodeAction(
          title: first.title,
          kind: first.kind,
          // Merge diagnostics from all of the matching CodeActions.
          diagnostics: [
            ...?first.diagnostics,
            for (final other in others) ...?other.action.diagnostics,
          ],
          edit: first.edit,
          command: first.command,
        ),
        priority,
      );
    }).toList();
  }
}
