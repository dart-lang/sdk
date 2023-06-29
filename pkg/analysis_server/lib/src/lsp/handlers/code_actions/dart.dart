// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Position;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart'
    show InconsistentAnalysisException;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

/// Produces [CodeAction]s from Dart source commands, fixes, assists and
/// refactors from the server.
class DartCodeActionsProducer extends AbstractCodeActionsProducer {
  ResolvedLibraryResult library;
  ResolvedUnitResult unit;
  Range range;
  final OptionalVersionedTextDocumentIdentifier docIdentifier;
  final CodeActionTriggerKind? triggerKind;

  DartCodeActionsProducer(
    super.server,
    super.path,
    super.lineInfo,
    this.docIdentifier,
    this.library,
    this.unit, {
    required this.range,
    required super.offset,
    required super.length,
    required super.shouldIncludeKind,
    required super.capabilities,
    required this.triggerKind,
  });

  @override
  String get name => 'ServerDartActionsComputer';

  /// Helper to create a [CodeAction] or [Command] for the given arguments in
  /// the current file based on client capabilities.
  Either2<CodeAction, Command> createCommand(
    CodeActionKind actionKind,
    String title,
    String command,
  ) {
    assert(
      (() => Commands.serverSupportedCommands.contains(command))(),
      'serverSupportedCommands did not contain $command',
    );
    return _commandOrCodeAction(
      actionKind,
      Command(
        title: title,
        command: command,
        arguments: [
          {
            'path': path,
            if (triggerKind == CodeActionTriggerKind.Automatic)
              'autoTriggered': true,
          }
        ],
      ),
    );
  }

  /// Helper to create refactors that execute commands provided with
  /// the current file, location and document version.
  Either2<CodeAction, Command> createRefactor(
    CodeActionKind actionKind,
    String name,
    RefactoringKind refactorKind, [
    Map<String, dynamic>? options,
  ]) {
    final command = Commands.performRefactor;
    assert(
      (() => Commands.serverSupportedCommands.contains(command))(),
      'serverSupportedCommands did not contain $command',
    );

    return _commandOrCodeAction(
        actionKind,
        Command(
          title: name,
          command: command,
          arguments: [
            // TODO(dantup): Change this to a single entry that is a Map once
            //  enough time has passed that old versions of Dart-Code prior to
            //  to June 2022 need not be supported against newer SDKs.
            refactorKind.toJson(),
            path,
            docIdentifier.version,
            offset,
            length,
            options,
          ],
        ));
  }

  @override
  Future<List<CodeActionWithPriority>> getAssistActions() async {
    // These assists are only provided as literal CodeActions.
    if (!supportsLiterals) {
      return [];
    }

    try {
      final workspace = DartChangeWorkspace(await server.currentSessions);
      var context = DartAssistContextImpl(
        server.instrumentationService,
        workspace,
        unit,
        offset,
        length,
      );
      final processor = AssistProcessor(context);
      final assists = await processor.compute();

      return assists.map((assist) {
        final action =
            createAssistAction(assist.change, unit.path, unit.lineInfo);
        return (action: action, priority: assist.kind.priority);
      }).toList();
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  @override
  Future<List<CodeActionWithPriority>> getFixActions() async {
    // These fixes are only provided as literal CodeActions.
    if (!supportsLiterals) {
      return [];
    }

    final lineInfo = unit.lineInfo;
    final codeActions = <CodeActionWithPriority>[];
    final fixContributor = DartFixContributor();

    try {
      final workspace = DartChangeWorkspace(await server.currentSessions);
      for (final error in unit.errors) {
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
        var context = DartFixContextImpl(
            server.instrumentationService, workspace, unit, error);
        final fixes = await fixContributor.computeFixes(context);
        if (fixes.isNotEmpty) {
          final diagnostic = toDiagnostic(
            unit,
            error,
            supportedTags: supportedDiagnosticTags,
            clientSupportsCodeDescription: supportsCodeDescription,
          );
          codeActions.addAll(
            fixes.map((fix) {
              final action =
                  createFixAction(fix.change, diagnostic, path, lineInfo);
              return (action: action, priority: fix.kind.priority);
            }),
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
  Future<List<Either2<CodeAction, Command>>> getRefactorActions() async {
    final refactorActions = <Either2<CodeAction, Command>>[];

    try {
      // New interactive refactors.
      final context = RefactoringContext(
        server: server,
        startSessions: await server.currentSessions,
        resolvedLibraryResult: library,
        resolvedUnitResult: unit,
        selectionOffset: offset,
        selectionLength: length,
        includeExperimental:
            server.lspClientConfiguration.global.experimentalRefactors,
      );
      final processor = RefactoringProcessor(context);
      final actions = await processor.compute();
      refactorActions.addAll(actions.map(Either2<CodeAction, Command>.t1));

      // Extracts
      if (shouldIncludeKind(CodeActionKind.RefactorExtract)) {
        // Extract Method
        if (ExtractMethodRefactoring(server.searchEngine, unit, offset, length)
            .isAvailable()) {
          refactorActions.add(createRefactor(CodeActionKind.RefactorExtract,
              'Extract Method', RefactoringKind.EXTRACT_METHOD));
        }

        // Extract Local Variable
        if (ExtractLocalRefactoring(unit, offset, length).isAvailable()) {
          refactorActions.add(createRefactor(
              CodeActionKind.RefactorExtract,
              'Extract Local Variable',
              RefactoringKind.EXTRACT_LOCAL_VARIABLE));
        }

        // Extract Widget
        if (ExtractWidgetRefactoring(server.searchEngine, unit, offset, length)
            .isAvailable()) {
          refactorActions.add(createRefactor(CodeActionKind.RefactorExtract,
              'Extract Widget', RefactoringKind.EXTRACT_WIDGET));
        }
      }

      // Inlines
      if (shouldIncludeKind(CodeActionKind.RefactorInline)) {
        // Inline Local Variable
        if (InlineLocalRefactoring(server.searchEngine, unit, offset)
            .isAvailable()) {
          refactorActions.add(createRefactor(CodeActionKind.RefactorInline,
              'Inline Local Variable', RefactoringKind.INLINE_LOCAL_VARIABLE));
        }

        // Inline Method
        if (InlineMethodRefactoring(server.searchEngine, unit, offset)
            .isAvailable()) {
          refactorActions.add(createRefactor(CodeActionKind.RefactorInline,
              'Inline Method', RefactoringKind.INLINE_METHOD));
        }
      }

      // Converts/Rewrites
      if (shouldIncludeKind(CodeActionKind.RefactorRewrite)) {
        final node = NodeLocator(offset).searchWithin(unit.unit);
        final element = server.getElementOfNode(node);

        // Getter to Method
        if (element is PropertyAccessorElement &&
            ConvertGetterToMethodRefactoring(
                    server.refactoringWorkspace, unit.session, element)
                .isAvailable()) {
          refactorActions.add(createRefactor(
              CodeActionKind.RefactorRewrite,
              'Convert Getter to Method',
              RefactoringKind.CONVERT_GETTER_TO_METHOD));
        }

        // Method to Getter
        if (element is ExecutableElement &&
            ConvertMethodToGetterRefactoring(
                    server.refactoringWorkspace, unit.session, element)
                .isAvailable()) {
          refactorActions.add(createRefactor(
              CodeActionKind.RefactorRewrite,
              'Convert Method to Getter',
              RefactoringKind.CONVERT_METHOD_TO_GETTER));
        }
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
  Future<List<Either2<CodeAction, Command>>> getSourceActions() async {
    // If the client does not support workspace/applyEdit, we won't be able to
    // run any of these.
    if (!supportsApplyEdit) {
      return const [];
    }

    return [
      if (shouldIncludeKind(DartCodeActionKind.SortMembers))
        createCommand(
          DartCodeActionKind.SortMembers,
          'Sort Members',
          Commands.sortMembers,
        ),
      if (shouldIncludeKind(CodeActionKind.SourceOrganizeImports))
        createCommand(
          CodeActionKind.SourceOrganizeImports,
          'Organize Imports',
          Commands.organizeImports,
        ),
      if (shouldIncludeKind(DartCodeActionKind.FixAll))
        createCommand(
          DartCodeActionKind.FixAll,
          'Fix All',
          Commands.fixAll,
        ),
    ];
  }

  /// Wraps a command in a CodeAction if the client supports it so that a
  /// CodeActionKind can be supplied.
  Either2<CodeAction, Command> _commandOrCodeAction(
    CodeActionKind kind,
    Command command,
  ) {
    return supportsLiterals
        ? Either2<CodeAction, Command>.t1(
            CodeAction(title: command.title, kind: kind, command: command),
          )
        : Either2<CodeAction, Command>.t2(command);
  }
}
