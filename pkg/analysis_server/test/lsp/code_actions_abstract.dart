// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../utils/test_code_extensions.dart';
import 'change_verifier.dart';
import 'server_abstract.dart';

abstract class AbstractCodeActionsTest extends AbstractLspAnalysisServerTest {
  /// Initializes the server with some basic configuration and expects to find
  /// a [CodeAction] with [kind]/[command]/[title].
  Future<CodeAction> expectAction(
    String content, {
    CodeActionKind? kind,
    String? command,
    String? title,
    CodeActionTriggerKind? triggerKind,
    String? filePath,
    bool openTargetFile = false,
    bool failTestOnAnyErrorNotification = true,
  }) async {
    filePath ??= mainFilePath;
    final fileUri = pathContext.toUri(filePath);
    final code = TestCode.parse(content);
    newFile(filePath, code.code);

    await initialize(
      failTestOnAnyErrorNotification: failTestOnAnyErrorNotification,
    );

    if (openTargetFile) {
      await openFile(fileUri, code.code);
    }

    final codeActions = await getCodeActions(
      fileUri,
      position: code.positions.isNotEmpty ? code.position.position : null,
      range: code.ranges.isNotEmpty ? code.range.range : null,
      triggerKind: triggerKind,
    );

    return findAction(codeActions, kind: kind, command: command, title: title)!;
  }

  /// Expects that command [commandName] was logged to the analytics manager.
  void expectCommandLogged(String commandName) {
    expect(
      server.analyticsManager
          .getRequestData(Method.workspace_executeCommand.toString())
          .additionalEnumCounts['command']!
          .keys,
      contains(commandName),
    );
  }

  /// Initializes the server with some basic configuration and expects not to
  /// find a [CodeAction] with [kind]/[command]/[title].
  Future<void> expectNoAction(
    String content, {
    String? filePath,
    CodeActionKind? kind,
    String? command,
    String? title,
    ProgressToken? workDoneToken,
  }) async {
    filePath ??= mainFilePath;
    final code = TestCode.parse(content);
    newFile(filePath, code.code);

    if (workDoneToken != null) {
      setWorkDoneProgressSupport();
    }
    await initialize();

    final codeActions = await getCodeActions(
      pathContext.toUri(filePath),
      position: code.positions.isNotEmpty ? code.position.position : null,
      range: code.ranges.isNotEmpty ? code.range.range : null,
      workDoneToken: workDoneToken,
    );

    expect(
      findAction(codeActions, kind: kind, command: command, title: title),
      isNull,
    );
  }

  /// Finds the single action matching [title], [kind] and [command].
  ///
  /// Throws if zero or more than one actions match.
  CodeAction? findAction(List<Either2<Command, CodeAction>> actions,
      {String? title, CodeActionKind? kind, String? command}) {
    return findActions(actions, title: title, kind: kind, command: command)
        .singleOrNull;
  }

  List<CodeAction> findActions(List<Either2<Command, CodeAction>> actions,
      {String? title, CodeActionKind? kind, String? command}) {
    return actions
        .map((action) => action.map((cmd) => null, (action) => action))
        .where((action) => title == null || action?.title == title)
        .where((action) => kind == null || action?.kind == kind)
        .where(
            (action) => command == null || action?.command?.command == command)
        .map((action) {
          // Always expect a command (either to execute, or for logging)
          assert(action!.command != null);
          // Expect an edit if we weren't looking for a command-action.
          if (command == null) {
            assert(action!.edit != null);
          }
          return action;
        })
        .whereNotNull()
        .toList();
  }

  Either2<Command, CodeAction>? findCommand(
      List<Either2<Command, CodeAction>> actions, String commandID,
      [String? wantedTitle]) {
    for (var codeAction in actions) {
      final id = codeAction.map(
        (cmd) => cmd.command,
        (action) => action.command?.command,
      );
      final title = codeAction.map(
        (cmd) => cmd.title,
        (action) => action.title,
      );
      if (id == commandID && (wantedTitle == null || wantedTitle == title)) {
        return codeAction;
      }
    }
    return null;
  }

  @override
  void setUp() {
    super.setUp();

    // Some defaults that most tests use. Tests can opt-out by overwriting these
    // before initializing.
    setApplyEditSupport();
    setDocumentChangesSupport();
  }

  /// Initializes the server with some basic configuration and expects to find
  /// a [CodeAction] with [kind]/[title] that applies edits resulting in
  /// [expected].
  Future<LspChangeVerifier> verifyActionEdits(
    String content,
    String expected, {
    String? filePath,
    CodeActionKind? kind,
    String? command,
    String? title,
    ProgressToken? commandWorkDoneToken,
  }) async {
    filePath ??= mainFilePath;

    // For convenience, if a test doesn't provide an full set of edits
    // we assume only a single edit of the file that was being modified.
    if (!expected.startsWith(LspChangeVerifier.editMarkerStart)) {
      expected = '''
${LspChangeVerifier.editMarkerStart} ${relativePath(filePath)}
$expected''';
    }

    final action = await expectAction(
      filePath: filePath,
      content,
      kind: kind,
      command: command,
      title: title,
    );

    // Verify the edits either by executing the command we expected, or
    // the edits attached directly to the code action.
    if (command != null) {
      return await verifyCommandEdits(
        action.command!,
        expected,
        workDoneToken: commandWorkDoneToken,
      );
    } else {
      final edit = action.edit!;
      return verifyEdit(edit, expected);
    }
  }
}
