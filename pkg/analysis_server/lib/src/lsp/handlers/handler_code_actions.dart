// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/analysis_options.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/dart.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/plugins.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/pubspec.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:collection/collection.dart' show groupBy;

typedef StaticOptions = Either2<bool, CodeActionOptions>;

class CodeActionHandler
    extends LspMessageHandler<CodeActionParams, TextDocumentCodeActionResult> {
  CodeActionHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_codeAction;

  @override
  LspJsonHandler<CodeActionParams> get jsonHandler =>
      CodeActionParams.jsonHandler;

  @override
  Future<ErrorOr<TextDocumentCodeActionResult>> handle(CodeActionParams params,
      MessageInfo message, CancellationToken token) async {
    var performance = message.performance;

    var textDocument = params.textDocument;
    var path = pathOfDoc(textDocument);
    // TODO(dantup): Break this up, it's hundreds of lines.
    return path.mapResult((unitPath) async {
      if (!server.isAnalyzed(unitPath) ||
          !isEditableDocument(textDocument.uri)) {
        return success(const []);
      }

      var capabilities = message.clientCapabilities;
      if (capabilities == null) {
        // This should not happen unless a client misbehaves.
        return serverNotInitializedError;
      }

      var supportsLiterals = capabilities.literalCodeActions;
      var supportedKinds = capabilities.codeActionKinds;

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
        var only = params.context.only;
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

        var only = params.context.only;
        if (only != null) {
          return only.any(isMatch);
        }

        return true;
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

      var startOffset = toOffset(lineInfo, params.range.start);
      var endOffset = toOffset(lineInfo, params.range.end);
      if (startOffset.isError || endOffset.isError) {
        return success([]);
      }

      return (startOffset, endOffset)
          .mapResults((startOffset, endOffset) async {
        var offset = startOffset;
        var length = endOffset - startOffset;

        var isDart = file_paths.isDart(pathContext, unitPath);
        var isPubspec = file_paths.isPubspecYaml(pathContext, unitPath);
        var isAnalysisOptions =
            file_paths.isAnalysisOptionsYaml(pathContext, unitPath);
        var includeSourceActions =
            shouldIncludeAnyOfKind(CodeActionKind.Source);
        var includeQuickFixes = shouldIncludeAnyOfKind(CodeActionKind.QuickFix);
        var includeRefactors = shouldIncludeAnyOfKind(CodeActionKind.Refactor);

        Future<AnalysisOptions> getOptions() async {
          if (unit != null) return unit.analysisOptions;
          var session = await server.getAnalysisSession(unitPath);
          var fileResult = session?.getFile(unitPath);
          if (fileResult is FileResult) return fileResult.analysisOptions;
          // Default to empty options.
          return AnalysisOptionsImpl();
        }

        var analysisOptions = await getOptions();

        var actionComputers = [
          if (isDart && libraryResult != null && unit != null)
            DartCodeActionsProducer(
              server,
              unit.file,
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
              analysisOptions: analysisOptions,
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
              capabilities: capabilities,
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
              capabilities: capabilities,
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
            capabilities: capabilities,
            analysisOptions: analysisOptions,
          ),
        ];
        var sorter = _CodeActionSorter(params.range, shouldIncludeKind);

        var allActions = <Either2<CodeAction, Command>>[
          // Like-kinded actions are grouped (and prioritized) together
          // regardless of which producer they came from.

          // Source.
          if (includeSourceActions)
            for (var computer in actionComputers)
              ...await performance.runAsync('${computer.name}.getSourceActions',
                  (_) => computer.getSourceActions()),

          // Fixes.
          if (includeQuickFixes)
            ...sorter.sort([
              for (var computer in actionComputers)
                ...await performance.runAsync('${computer.name}.getFixActions',
                    (_) => computer.getFixActions()),
            ]),

          // Refactors  (Assists + Refactors).
          if (includeRefactors)
            ...sorter.sort([
              for (var computer in actionComputers)
                ...await performance.runAsync(
                    '${computer.name}.getAssistActions',
                    (_) => computer.getAssistActions()),
            ]),
          if (includeRefactors)
            for (var computer in actionComputers)
              ...await performance.runAsync(
                  '${computer.name}.getRefactorActions',
                  (_) => computer.getRefactorActions()),
        ];

        return success(allActions);
      });
    });
  }
}

class CodeActionRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  CodeActionRegistrations(super.info);

  bool get codeActionLiteralSupport => clientCapabilities.literalCodeActions;

  @override
  ToJsonable? get options => CodeActionRegistrationOptions(
        documentSelector: fullySupportedTypes,
        codeActionKinds: DartCodeActionKind.serverSupportedKinds,
      );

  @override
  Method get registrationMethod => Method.textDocument_codeAction;

  @override
  StaticOptions get staticOptions =>
      // "The `CodeActionOptions` return type is only valid if the client
      // signals code action literal support via the property
      // `textDocument.codeAction.codeActionLiteralSupport`."
      codeActionLiteralSupport
          ? Either2.t2(CodeActionOptions(
              codeActionKinds: DartCodeActionKind.serverSupportedKinds,
            ))
          : Either2.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.codeActions;
}

/// Sorts [CodeActionWithPriority]s by priority, and removes duplicates keeping
/// the one nearest [range].
class _CodeActionSorter {
  final Range range;
  final bool Function(CodeActionKind?) shouldIncludeKind;

  _CodeActionSorter(this.range, this.shouldIncludeKind);

  List<Either2<CodeAction, Command>> sort(
      List<CodeActionWithPriority> actions) {
    var dedupedActions = _dedupeActions(actions, range.start);

    // Add each index so we can do a stable sort on priority.
    var dedupedActionsWithIndex = dedupedActions.indexed.map((item) {
      var (index, action) = item;
      return (action: action.action, priority: action.priority, index: index);
    }).toList();
    dedupedActionsWithIndex.sort(_compareCodeActions);

    return dedupedActionsWithIndex
        .where((action) => shouldIncludeKind(action.action.kind))
        .map((action) => Either2<CodeAction, Command>.t1(action.action))
        .toList();
  }

  /// Creates a comparer for [CodeActions] that compares the column distance from [pos].
  int Function(CodeAction a, CodeAction b) _codeActionColumnDistanceComparer(
      Position pos) {
    Position posOf(CodeAction action) {
      var diagnostics = action.diagnostics;
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
      Iterable<CodeActionWithPriority> actions, Position position) {
    var groups = groupBy(
        actions, (CodeActionWithPriority action) => action.action.title);
    return groups.entries.map((entry) {
      var actions = entry.value;

      // If there's only one in the group, just return it.
      if (actions.length == 1) {
        return actions.single;
      }

      // Otherwise, find the action nearest to the caret.
      var comparer = _codeActionColumnDistanceComparer(position);
      actions.sort((a, b) => comparer(a.action, b.action));
      var first = actions.first.action;
      var priority = actions.first.priority;

      // Get any actions with the same fix (edit/command) for merging diagnostics.
      var others = actions.skip(1).where(
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
      return (
        action: CodeAction(
          title: first.title,
          kind: first.kind,
          // Merge diagnostics from all of the matching CodeActions.
          diagnostics: [
            ...?first.diagnostics,
            for (var other in others) ...?other.action.diagnostics,
          ],
          edit: first.edit,
          command: first.command,
        ),
        priority: priority,
      );
    }).toList();
  }
}
