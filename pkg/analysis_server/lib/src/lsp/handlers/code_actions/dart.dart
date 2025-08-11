// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart'
    hide AnalysisOptions, Position;
import 'package:analysis_server/src/services/correction/fix_performance.dart';
import 'package:analysis_server/src/services/correction/refactoring_performance.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analysis_server_plugin/edit/assist/dart_assist_context.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/src/correction/assist_performance.dart';
import 'package:analysis_server_plugin/src/correction/assist_processor.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_processor.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart'
    show InconsistentAnalysisException;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Produces [CodeActionLiteral]s from Dart source commands, fixes, assists and
/// refactors from the server.
class DartCodeActionsProducer extends AbstractCodeActionsProducer {
  ResolvedLibraryResult libraryResult;
  ResolvedUnitResult unitResult;
  Range range;
  final OptionalVersionedTextDocumentIdentifier docIdentifier;
  final CodeActionTriggerKind? triggerKind;
  final bool willBeDeduplicated;

  DartCodeActionsProducer(
    super.server,
    super.file,
    super.lineInfo,
    this.docIdentifier,
    this.libraryResult,
    this.unitResult, {
    required this.range,
    required super.offset,
    required super.length,
    required super.shouldIncludeKind,
    required super.editorCapabilities,
    required super.callerCapabilities,
    required super.allowCodeActionLiterals,
    required super.allowCommands,
    required super.allowSnippets,
    required super.analysisOptions,
    required this.triggerKind,
    required this.willBeDeduplicated,
  });

  @override
  String get name => 'ServerDartActionsComputer';

  /// Helper to create a [CodeAction] for the given arguments in the current
  /// file based on client capabilities.
  CodeAction createAction(
    CodeActionKind actionKind,
    String title,
    String command,
  ) {
    assert(
      (() => Commands.serverSupportedCommands.contains(command))(),
      'serverSupportedCommands did not contain $command',
    );
    return _maybeWrapCommandInCodeActionLiteral(
      actionKind,
      Command(
        title: title,
        command: command,
        arguments: [
          {
            'path': path,
            if (triggerKind == CodeActionTriggerKind.Automatic)
              'autoTriggered': true,
          },
        ],
      ),
    );
  }

  /// Helper to create refactors that execute commands provided with
  /// the current file, location and document version.
  CodeAction createRefactor(
    CodeActionKind actionKind,
    String name,
    RefactoringKind refactorKind, [
    Map<String, Object?>? options,
  ]) {
    var command = Commands.performRefactor;
    assert(
      (() => Commands.serverSupportedCommands.contains(command))(),
      'serverSupportedCommands did not contain $command',
    );
    assert(
      (() => serverSupportsCommand(command))(),
      'This kind of server does not support $command',
    );

    return _maybeWrapCommandInCodeActionLiteral(
      actionKind,
      Command(
        title: name,
        command: command,
        arguments: [
          // TODO(dantup): Change this to a single entry that is a Map once
          //  enough time has passed that old versions of Dart-Code prior to
          //  to June 2022 need not be supported against newer SDKs.
          refactorKind.toJson(clientUriConverter: server.uriConverter),
          path,
          docIdentifier.version,
          offset,
          length,
          options,
        ],
      ),
    );
  }

  @override
  Future<List<CodeActionWithPriority>> getAssistActions({
    OperationPerformanceImpl? performance,
  }) async {
    try {
      var context = DartAssistContext(
        server.instrumentationService,
        DartChangeWorkspace(await server.currentSessions),
        libraryResult,
        unitResult,
        offset,
        length,
      );

      late List<Assist> assists;
      if (performance != null) {
        var performanceTracker = AssistPerformance();
        assists = await computeAssists(
          context,
          performance: performanceTracker,
        );

        server.recentPerformance.getAssists.add(
          GetAssistsPerformance(
            performance: performance,
            path: path,
            content: unitResult.content,
            offset: offset,
            requestLatency: performanceTracker.computeTime!.inMilliseconds,
            producerTimings: performanceTracker.producerTimings,
          ),
        );
      } else {
        assists = await computeAssists(context);
      }

      return assists
          .map((assist) {
            var change = assist.change;
            var kind = toCodeActionKind(change.id, CodeActionKind.Refactor);
            // TODO(dantup): Find a way to filter these earlier, so we don't
            //  compute fixes we will filter out.
            if (!shouldIncludeKind(kind)) {
              return null;
            }
            var action = createCodeActionLiteralOrApplyCommand(
              unitResult.path,
              docIdentifier,
              range,
              unitResult.lineInfo,
              change,
              kind,
              change.id,
            );
            if (action == null) {
              return null;
            }
            return (action: action, priority: assist.kind.priority);
          })
          .nonNulls
          .toList();
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return const [];
    }
  }

  @override
  Future<List<CodeActionWithPriority>> getFixActions(
    OperationPerformance? performance,
  ) async {
    var lineInfo = unitResult.lineInfo;
    var codeActions = <CodeActionWithPriority>[];

    try {
      // If deduplicating the result only do the expensive "fix all in file"
      // calculation when we haven't before.
      Set<String>? skipAlreadyCalculatedIfNonNull =
          willBeDeduplicated ? {} : null;
      var workspace = DartChangeWorkspace(await server.currentSessions);
      CorrectionUtils? correctionUtils;
      for (var error in unitResult.diagnostics) {
        // Return fixes for any part of the line where a diagnostic is.
        // If a diagnostic spans multiple lines, the fix will be included for
        // all of those lines.
        // Server lineNumbers are one-based so subtract one.
        var errorStartLine = lineInfo.getLocation(error.offset).lineNumber - 1;
        var errorEndLine =
            lineInfo.getLocation(error.offset + error.length).lineNumber - 1;
        if (range.end.line < errorStartLine ||
            range.start.line > errorEndLine) {
          continue;
        }
        var context = DartFixContext(
          instrumentationService: server.instrumentationService,
          workspace: workspace,
          libraryResult: libraryResult,
          unitResult: unitResult,
          error: error,
          correctionUtils: correctionUtils ??= CorrectionUtils(unitResult),
        );

        var performanceTracker = FixPerformance();
        var fixes = await computeFixes(
          context,
          performance: performanceTracker,
          skipAlreadyCalculatedIfNonNull: skipAlreadyCalculatedIfNonNull,
        );

        if (performance != null) {
          server.recentPerformance.getFixes.add(
            GetFixesPerformance(
              performance: performance,
              path: path,
              content: unitResult.content,
              offset: offset,
              requestLatency: performanceTracker.computeTime!.inMilliseconds,
              producerTimings: performanceTracker.producerTimings,
            ),
          );
        }

        if (fixes.isNotEmpty) {
          var diagnostic = toDiagnostic(
            server.uriConverter,
            unitResult,
            error,
            supportedTags: callerSupportedDiagnosticTags,
            clientSupportsCodeDescription: callerSupportsCodeDescription,
          );
          codeActions.addAll(
            fixes.map((fix) {
              var change = fix.change;
              var kind = toCodeActionKind(change.id, CodeActionKind.QuickFix);
              // TODO(dantup): Find a way to filter these earlier, so we don't
              //  compute fixes we will filter out.
              if (!shouldIncludeKind(kind)) {
                return null;
              }
              var action = createCodeActionLiteralOrApplyCommand(
                unitResult.path,
                docIdentifier,
                range,
                lineInfo,
                change,
                kind,
                change.id,
                diagnostic: diagnostic,
              );
              if (action == null) {
                return null;
              }
              return (action: action, priority: fix.kind.priority);
            }).nonNulls,
          );
        }
      }

      return codeActions;
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  @override
  Future<List<CodeAction>> getRefactorActions(
    OperationPerformance? performance,
  ) async {
    // If the client does not support workspace/applyEdit, we won't be able to
    // run any of these.
    if (!editorSupportsApplyEdit) {
      return const [];
    }

    var refactorActions = <CodeAction>[];
    var performanceTracker = RefactoringPerformance();

    try {
      // New interactive refactors.
      var context = RefactoringContext(
        server: server,
        startSessions: await server.currentSessions,
        resolvedLibraryResult: libraryResult,
        resolvedUnitResult: unitResult,
        // TODO(dantup): Determine if we need to provide both editor+caller
        //  capabilities here.
        clientCapabilities: editorCapabilities,
        selectionOffset: offset,
        selectionLength: length,
        includeExperimental:
            server.lspClientConfiguration.global.experimentalRefactors,
      );
      var processor = RefactoringProcessor(
        context,
        performance: performanceTracker,
      );
      var actions = await processor.compute();
      refactorActions.addAll(
        actions
            .where((literal) => shouldIncludeKind(literal.kind))
            .map(CodeAction.t1),
      );

      // Extracts
      if (shouldIncludeKind(CodeActionKind.RefactorExtract)) {
        var timer = Stopwatch()..start();
        // Extract Method
        if (ExtractMethodRefactoring(
          server.searchEngine,
          unitResult,
          offset,
          length,
        ).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorExtract,
              'Extract Method',
              RefactoringKind.EXTRACT_METHOD,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'ExtractMethodRefactoring',
          timer: timer,
        );

        // Extract Local Variable
        if (ExtractLocalRefactoring(unitResult, offset, length).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorExtract,
              'Extract Local Variable',
              RefactoringKind.EXTRACT_LOCAL_VARIABLE,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'ExtractLocalRefactoring',
          timer: timer,
        );

        // Extract Widget
        if (ExtractWidgetRefactoring(
          server.searchEngine,
          unitResult,
          offset,
          length,
        ).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorExtract,
              'Extract Widget',
              RefactoringKind.EXTRACT_WIDGET,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'ExtractWidgetRefactoring',
          timer: timer,
        );
      }

      var timer = Stopwatch();
      // Inlines
      if (shouldIncludeKind(CodeActionKind.RefactorInline)) {
        timer.start();
        // Inline Local Variable
        if (InlineLocalRefactoring(
          server.searchEngine,
          unitResult,
          offset,
        ).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorInline,
              'Inline Local Variable',
              RefactoringKind.INLINE_LOCAL_VARIABLE,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'InlineLocalRefactoring',
          timer: timer,
        );

        // Inline Method
        if (InlineMethodRefactoring(
          server.searchEngine,
          unitResult,
          offset,
        ).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorInline,
              'Inline Method',
              RefactoringKind.INLINE_METHOD,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'InlineMethodRefactoring',
          timer: timer,
        );
      }

      // Converts/Rewrites
      if (shouldIncludeKind(CodeActionKind.RefactorRewrite)) {
        timer.restart();

        var node = unitResult.unit.nodeCovering(offset: offset);
        var element = node?.getElement();

        // Getter to Method
        if (element is GetterElement &&
            ConvertGetterToMethodRefactoring(
              server.refactoringWorkspace,
              unitResult.session,
              element,
            ).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorRewrite,
              'Convert Getter to Method',
              RefactoringKind.CONVERT_GETTER_TO_METHOD,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'ConvertGetterToMethodRefactoring',
          timer: timer,
        );

        // Method to Getter
        if (element is ExecutableElement &&
            ConvertMethodToGetterRefactoring(
              server.refactoringWorkspace,
              unitResult.session,
              element,
            ).isAvailable()) {
          refactorActions.add(
            createRefactor(
              CodeActionKind.RefactorRewrite,
              'Convert Method to Getter',
              RefactoringKind.CONVERT_METHOD_TO_GETTER,
            ),
          );
        }
        performanceTracker.addTiming(
          className: 'ConvertMethodToGetterRefactoring',
          timer: timer,
        );
      }
      if (performance != null) {
        server.recentPerformance.getRefactorings.add(
          GetRefactoringsPerformance(
            performance: performance,
            path: path,
            content: unitResult.content,
            offset: offset,
            requestLatency: performanceTracker.computeTime!.inMilliseconds,
            producerTimings: performanceTracker.producerTimings,
          ),
        );
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
  @override
  Future<List<CodeAction>> getSourceActions() async {
    // If the client does not support workspace/applyEdit, we won't be able to
    // run any of these.
    if (!editorSupportsApplyEdit) {
      return const [];
    }

    return [
      if (shouldIncludeKind(DartCodeActionKind.SortMembers))
        createAction(
          DartCodeActionKind.SortMembers,
          'Sort Members',
          Commands.sortMembers,
        ),
      if (shouldIncludeKind(CodeActionKind.SourceOrganizeImports))
        createAction(
          CodeActionKind.SourceOrganizeImports,
          'Organize Imports',
          Commands.organizeImports,
        ),
      if (serverSupportsCommand(Commands.fixAll) &&
          shouldIncludeKind(DartCodeActionKind.FixAll))
        createAction(DartCodeActionKind.FixAll, 'Fix All', Commands.fixAll),
    ];
  }

  /// Returns a [CodeAction] that is [command] wrapped in a [CodeActionLiteral]
  /// (to allow a [CodeActionKind] to be supplied) if the client supports it,
  /// otherwise the bare command.
  CodeAction _maybeWrapCommandInCodeActionLiteral(
    CodeActionKind kind,
    Command command,
  ) {
    return allowCodeActionLiterals
        ? CodeAction.t1(
          CodeActionLiteral(title: command.title, kind: kind, command: command),
        )
        : CodeAction.t2(command);
  }
}

extension on Stopwatch {
  void restart() {
    reset();
    start();
  }
}

extension on RefactoringPerformance {
  void addTiming({required String className, required Stopwatch timer}) {
    producerTimings.add((
      className: 'InlineMethodRefactoring',
      elapsedTime: timer.elapsedMilliseconds,
    ));
    timer.restart();
  }
}
