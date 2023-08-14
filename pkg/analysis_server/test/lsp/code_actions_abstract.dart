// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'server_abstract.dart';

abstract class AbstractCodeActionsTest extends AbstractLspAnalysisServerTest {
  Future<void> checkCodeActionAvailable(
    Uri uri,
    String command,
    String title, {
    Range? range,
    Position? position,
    bool asCodeActionLiteral = false,
    bool asCommand = false,
  }) async {
    final codeActions =
        await getCodeActions(uri, range: range, position: position);
    final codeAction = findCommand(codeActions, command)!;

    codeAction.map(
      (command) {
        if (!asCommand) {
          throw 'Got Command but expected CodeAction literal';
        }
        expect(command.title, equals(title));
        expect(
          command.arguments,
          equals([
            {'path': uri.toFilePath()}
          ]),
        );
      },
      (codeAction) {
        if (!asCodeActionLiteral) {
          throw 'Got CodeAction literal but expected Command';
        }
        expect(codeAction.title, equals(title));
        expect(codeAction.command!.title, equals(title));
        expect(
          codeAction.command!.arguments,
          equals([
            {'path': uri.toFilePath()}
          ]),
        );
      },
    );
  }

  /// Executes [command] which is expected to call back to the client to apply
  /// a [WorkspaceEdit].
  ///
  /// Changes are applied to [contents] to be verified by the caller.
  Future<void> executeCommandForEdits(
    Command command,
    // TODO(dantup): Change this map to use Uris for files.
    Map<String, String> contents, {
    bool expectDocumentChanges = false,
    ProgressToken? workDoneToken,
  }) async {
    ApplyWorkspaceEditParams? editParams;

    final commandResponse = await handleExpectedRequest<Object?,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResult>(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () => executeCommand(command, workDoneToken: workDoneToken),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified by the caller).
        editParams = edit;
        return ApplyWorkspaceEditResult(applied: true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using the expected change type.
    expect(editParams, isNotNull);
    final edit = editParams!.edit;
    if (expectDocumentChanges) {
      expect(edit.changes, isNull);
      expect(edit.documentChanges, isNotNull);
    } else {
      expect(edit.changes, isNotNull);
      expect(edit.documentChanges, isNull);
    }

    if (expectDocumentChanges) {
      applyDocumentChanges(contents, edit.documentChanges!);
    } else {
      applyChanges(contents, edit.changes!);
    }
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

  Either2<Command, CodeAction>? findCommand(
      List<Either2<Command, CodeAction>> actions, String commandID,
      [String? wantedTitle]) {
    for (var codeAction in actions) {
      final id = codeAction.map(
          (cmd) => cmd.command, (action) => action.command?.command);
      final title =
          codeAction.map((cmd) => cmd.title, (action) => action.title);
      if (id == commandID && (wantedTitle == null || wantedTitle == title)) {
        return codeAction;
      }
    }
    return null;
  }

  CodeAction? findEditAction(List<Either2<Command, CodeAction>> actions,
      CodeActionKind actionKind, String title) {
    return findEditActions(actions, actionKind, title).firstOrNull;
  }

  List<CodeAction> findEditActions(List<Either2<Command, CodeAction>> actions,
      CodeActionKind actionKind, String title) {
    return actions
        .map((action) => action.map((cmd) => null, (action) => action))
        .where((action) => action?.kind == actionKind && action?.title == title)
        .map((action) {
          // Expect matching actions to contain an edit (and a log command).
          assert(action!.command != null);
          assert(action!.edit != null);
          return action;
        })
        .whereNotNull()
        .toList();
  }

  /// Verifies that executing the given code actions command on the server
  /// results in an edit being sent to the client that updates the file to match
  /// the expected content.
  Future<void> verifyCodeActionEdits(Either2<Command, CodeAction> codeAction,
      String content, String expectedContent,
      {bool expectDocumentChanges = false,
      ProgressToken? workDoneToken}) async {
    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command!,
    );

    await verifyCommandEdits(command, content, expectedContent,
        expectDocumentChanges: expectDocumentChanges,
        workDoneToken: workDoneToken);
  }

  /// Verifies that executing the given command on the server results in an edit
  /// being sent in the client that updates the main file to match the expected
  /// content.
  Future<void> verifyCommandEdits(
    Command command,
    String content,
    String expectedContent, {
    bool expectDocumentChanges = false,
    ProgressToken? workDoneToken,
  }) async {
    final contents = {
      mainFilePath: withoutMarkers(content),
    };

    await executeCommandForEdits(
      command,
      contents,
      expectDocumentChanges: expectDocumentChanges,
      workDoneToken: workDoneToken,
    );

    expect(contents[mainFilePath], equals(expectedContent));
  }
}
