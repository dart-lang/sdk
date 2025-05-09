// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../utils/lsp_protocol_extensions.dart';
import '../utils/test_code_extensions.dart';
import 'change_verifier.dart';
import 'server_abstract.dart';

mixin CodeActionsTestMixin on AbstractLspAnalysisServerTest {
  /// Initializes the server with some basic configuration and expects to find
  /// a [CodeAction] with [kind]/[command]/[title].
  Future<CodeAction> expectCodeAction(
    TestCode code, {
    CodeActionKind? kind,
    String? command,
    List<Object>? commandArgs,
    String? title,
    CodeActionTriggerKind? triggerKind,
    String? filePath,
    bool openTargetFile = false,
  }) async {
    filePath ??= mainFilePath;
    newFile(filePath, code.code);

    await initialize();

    var fileUri = uriConverter.toClientUri(filePath);
    if (openTargetFile) {
      await openFile(fileUri, code.code);
    }

    var codeActions = await getCodeActions(
      fileUri,
      position: code.positions.isNotEmpty ? code.position.position : null,
      range: code.ranges.isNotEmpty ? code.range.range : null,
      triggerKind: triggerKind,
    );

    var action = findCodeAction(
      codeActions,
      kind: kind,
      command: command,
      commandArgs: commandArgs,
      title: title,
    );
    if (action == null) {
      fail('Failed to find a code action titled "$title".');
    }
    return action;
  }

  /// Initializes the server with some basic configuration and expects to find
  /// a [CodeAction] with [kind]/[command]/[title].
  Future<CodeActionLiteral> expectCodeActionLiteral(
    String content, {
    CodeActionKind? kind,
    String? command,
    List<Object>? commandArgs,
    String? title,
    CodeActionTriggerKind? triggerKind,
    String? filePath,
    bool openTargetFile = false,
  }) async {
    var action = await expectCodeAction(
      TestCode.parse(content),
      kind: kind,
      command: command,
      commandArgs: commandArgs,
      title: title,
      triggerKind: triggerKind,
      filePath: filePath,
      openTargetFile: openTargetFile,
    );
    return action.asCodeActionLiteral;
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
    var code = TestCode.parse(content);
    newFile(filePath, code.code);

    if (workDoneToken != null) {
      setWorkDoneProgressSupport();
    }
    await initialize();

    var codeActions = await getCodeActions(
      uriConverter.toClientUri(filePath),
      position: code.positions.isNotEmpty ? code.position.position : null,
      range: code.ranges.isNotEmpty ? code.range.range : null,
      workDoneToken: workDoneToken,
    );

    expect(
      findCodeAction(codeActions, kind: kind, command: command, title: title),
      isNull,
    );
  }

  /// Finds the single [CodeAction] matching [title], [kind] and [command].
  ///
  /// If [command] and/or [commandArgs] are supplied, ensures the result is
  /// either that command, or a literal code action with that command.
  ///
  /// Returns `null` if there is not exactly one match.
  CodeAction? findCodeAction(
    List<CodeAction> actions, {
    String? title,
    CodeActionKind? kind,
    String? command,
    List<Object>? commandArgs,
  }) {
    return findCodeActions(
      actions,
      title: title,
      kind: kind,
      command: command,
      commandArgs: commandArgs,
    ).singleOrNull;
  }

  /// Finds the single [CodeActionLiteral] matching [title], [kind] and [command].
  ///
  /// If [command] and/or [commandArgs] are supplied, ensures the result is
  /// either that command, or a literal code action with that command.
  ///
  /// Returns `null` if there is not exactly one match.
  CodeActionLiteral? findCodeActionLiteral(
    List<CodeAction> actions, {
    String? title,
    CodeActionKind? kind,
    String? command,
    List<Object>? commandArgs,
  }) {
    return findCodeAction(
      actions,
      title: title,
      kind: kind,
      command: command,
      commandArgs: commandArgs,
    )?.asCodeActionLiteral;
  }

  List<CodeAction> findCodeActions(
    List<CodeAction> actions, {
    String? title,
    CodeActionKind? kind,
    String? command,
    List<Object>? commandArgs,
  }) {
    return actions.where((action) {
      var actionLiteral = action.map((action) => action, (command) => null);
      var actionCommand = action.map(
        // Always expect a command (either to execute, or for logging)
        (action) => action.command!,
        (command) => command,
      );
      var actionTitle = actionLiteral?.title ?? actionCommand.title;
      var actionKind = actionLiteral?.kind;

      if (title != null && actionTitle != title) {
        return false;
      }

      if (kind != null) {
        expect(actionKind, kind);
      }

      // Some tests filter by only supplying a command, so if there is no
      // title given, filter by the command. If a title was given, don't
      // filter by the command and assert it below. This results in a better
      // failure message if the action existed by title but without the correct
      // command.
      if (title == null &&
          command != null &&
          actionCommand.command != command) {
        return false;
      }

      if (command != null) {
        expect(actionCommand.command, command);
      } else {
        // Expect an edit if we weren't looking for a command-action.
        expect(actionLiteral?.edit, isNotNull);
      }
      if (commandArgs != null) {
        expect(actionCommand.arguments, equals(commandArgs));
      }

      return true;
    }).toList();
  }

  CodeAction? findCommand(
    List<CodeAction> actions,
    String commandID, [
    String? wantedTitle,
  ]) {
    for (var codeAction in actions) {
      var id = codeAction.command?.command;
      var title = codeAction.title;
      if (id == commandID && (wantedTitle == null || wantedTitle == title)) {
        return codeAction;
      }
    }
    return null;
  }

  /// Verifies that executing the given Code Action (either via a command or
  /// an inline edit) results in the files matching the expected content.
  Future<LspChangeVerifier> verifyCodeActionEdits(
    CodeAction action,
    String expectedContent, {
    ProgressToken? workDoneToken,
  }) async {
    var command = action.command;
    var edit = action.map((literal) => literal.edit, (_) => null);

    // Verify the edits either by executing the command we expected, or
    // the edits attached directly to the code action.
    // Don't try to execute 'dart.logAction' because it will never produce
    // edits.
    if (command != null && command.command != Commands.logAction) {
      assert(edit == null, 'Got a command but also a literal edit');
      return await verifyCommandEdits(
        command,
        expectedContent,
        workDoneToken: workDoneToken,
      );
    } else if (edit != null) {
      return verifyEdit(edit, expectedContent);
    } else {
      throw 'CodeAction had neither a command or a literal edit';
    }
  }

  /// Initializes the server with some basic configuration and expects to find
  /// a [CodeActionLiteral] with [kind]/[title] that applies edits resulting in
  /// [expected].
  Future<LspChangeVerifier> verifyCodeActionLiteralEdits(
    String content,
    String expected, {
    String? filePath,
    CodeActionKind? kind,
    String? command,
    List<Object>? commandArgs,
    String? title,
    ProgressToken? commandWorkDoneToken,
    bool openTargetFile = false,
  }) async {
    filePath ??= mainFilePath;

    // For convenience, if a test doesn't provide an full set of edits
    // we assume only a single edit of the file that was being modified.
    if (!expected.startsWith(LspChangeVerifier.editMarkerStart)) {
      expected = '''
${LspChangeVerifier.editMarkerStart} ${relativePath(filePath)}
$expected''';
    }

    var action = await expectCodeActionLiteral(
      filePath: filePath,
      content,
      kind: kind,
      command: command,
      commandArgs: commandArgs,
      title: title,
      openTargetFile: openTargetFile,
    );

    return await verifyCodeActionEdits(
      CodeAction.t1(action),
      expected,
      workDoneToken: commandWorkDoneToken,
    );
  }
}
