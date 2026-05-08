// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../shared/shared_test_interface.dart';
import '../utils/lsp_protocol_extensions.dart';
import '../utils/test_code_extensions.dart';
import 'change_verifier.dart';
import 'request_helpers_mixin.dart';

mixin CodeActionsTestMixin
    on
        SharedTestInterface,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin {
  final String simplePubspecContent = 'name: my_project';

  /// Whether the server supports the "Fix All" command (currently LSP-only).
  bool get serverSupportsFixAll => true;

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
    filePath ??= testFilePath;
    createFile(filePath, code.code);

    await initializeServer();

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
    content = normalizeNewlinesForPlatform(content);

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

  /// Initializes the server with some basic configuration and expects to find
  /// a [Command] code action (not a literal, even with a command) with
  /// [command]/[title].
  Future<Command> expectCommandCodeAction(
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
    return action.asCommand;
  }

  /// Verifies a command execution was logged to analytics.
  ///
  /// Implementations are provided by the in-process test base classes. This
  /// method will be a no-op for out-of-process tests because the analytics
  /// manager will not be accessible.
  void expectCommandLogged(String command);

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
    filePath ??= testFilePath;
    var code = TestCode.parse(content);
    createFile(filePath, code.code);

    if (workDoneToken != null) {
      setWorkDoneProgressSupport();
    }
    await initializeServer();

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

  List<TextDocumentEdit> extractTextDocumentEdits(
    DocumentChanges documentChanges,
  ) =>
      // Extract TextDocumentEdits from union of resource changes
      documentChanges
          .map(
            (change) => change.map(
              (create) => null,
              (delete) => null,
              (rename) => null,
              (textDocEdit) => textDocEdit,
            ),
          )
          .nonNulls
          .toList();

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

      if (kind != null && actionKind != kind) {
        return false;
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
    filePath ??= testFilePath;

    // For convenience, if a test doesn't provide a full set of edits
    // we assume only a single edit of the file that was being modified.
    if (!expected.startsWith(LspChangeVerifier.editMarkerStart)) {
      expected =
          '''
${LspChangeVerifier.editMarkerStart} ${relativePath(filePath)}
$expected''';
    }

    content = normalizeNewlinesForPlatform(content);
    expected = normalizeNewlinesForPlatform(expected);

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

  /// Initializes the server with some basic configuration and expects to find
  /// a [Command] code action (and not a literal, even with a command) with
  /// [title] that applies edits resulting in [expected].
  Future<LspChangeVerifier> verifyCommandCodeActionEdits(
    String content,
    String expected, {
    String? filePath,
    String? command,
    List<Object>? commandArgs,
    String? title,
    ProgressToken? commandWorkDoneToken,
    bool openTargetFile = false,
  }) async {
    filePath ??= testFilePath;

    // For convenience, if a test doesn't provide a full set of edits
    // we assume only a single edit of the file that was being modified.
    if (!expected.startsWith(LspChangeVerifier.editMarkerStart)) {
      expected =
          '''
${LspChangeVerifier.editMarkerStart} ${relativePath(filePath)}
$expected''';
    }

    content = normalizeNewlinesForPlatform(content);
    expected = normalizeNewlinesForPlatform(expected);

    var commandAction = await expectCommandCodeAction(
      filePath: filePath,
      content,
      command: command,
      commandArgs: commandArgs,
      title: title,
      openTargetFile: openTargetFile,
    );

    return await verifyCodeActionEdits(
      CodeAction.t2(commandAction),
      expected,
      workDoneToken: commandWorkDoneToken,
    );
  }
}
