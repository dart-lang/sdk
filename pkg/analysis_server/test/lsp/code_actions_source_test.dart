// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'code_actions_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
  });
}

@reflectiveTest
class OrganizeImportsSourceCodeActionsTest extends SourceCodeActionsTest {
  test_appliesCorrectEdits() async {
    const content = '''
import 'dart:convert';
import 'dart:async';
    ''';
    const expectedContent = '''
import 'dart:async';
import 'dart:convert';
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      handler: (edit) {
        // Handle the edit request that came from the server.
        expect(edit, isNotNull);
        final contents = {
          mainFilePath: content,
        };
        applyDocumentChanges(contents, edit.edit.documentChanges);
        expect(contents[mainFilePath], equals(expectedContent));

        // Send a success response back to the server.
        return new ApplyWorkspaceEditResponse(true);
      },
    );

    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);
  }

  test_availableAsCodeActionLiteral() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Source]);

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.organizeImports,
      'Organize Imports',
      asCodeActionLiteral: true,
    );
  }

  test_availableAsCommand() async {
    await newFile(mainFilePath);
    await initialize();

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.organizeImports,
      'Organize Imports',
      asCommand: true,
    );
  }

  test_failsIfFileHasErrors() async {
    final content = 'invalid dart code';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    // Ensure the request returned an error (error repsonses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(executeCommand(command),
        throwsA(isResponseError(ServerErrorCodes.FileHasErrors)));
  }

  test_unavailableWhenNotRequested() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Refactor]);

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNull);
  }
}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends SourceCodeActionsTest {
  test_appliesCorrectEdits() async {
    const content = '''
    String b;
    String a;
    ''';
    const expectedContent = '''
    String a;
    String b;
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      handler: (edit) {
        // Handle the edit request that came from the server.
        expect(edit, isNotNull);
        final contents = {
          mainFilePath: content,
        };
        applyDocumentChanges(contents, edit.edit.documentChanges);
        expect(contents[mainFilePath], equals(expectedContent));

        // Send a success response back to the server.
        return new ApplyWorkspaceEditResponse(true);
      },
    );

    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);
  }

  test_availableAsCodeActionLiteral() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Source]);

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.sortMembers,
      'Sort Members',
      asCodeActionLiteral: true,
    );
  }

  test_availableAsCommand() async {
    await newFile(mainFilePath);
    await initialize();

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.sortMembers,
      'Sort Members',
      asCommand: true,
    );
  }

  test_failsIfClientDoesntApplyEdits() async {
    await newFile(mainFilePath);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    final commandResponse = handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      // Claim that we failed tpo apply the edits. This is what the client
      // would do if the edits provided were for an old version of the
      // document.
      handler: (edit) => new ApplyWorkspaceEditResponse(false),
    );

    // Ensure the request returned an error (error repsonses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(commandResponse,
        throwsA(isResponseError(ServerErrorCodes.ClientFailedToApplyEdit)));
  }

  test_failsIfFileHasErrors() async {
    final content = 'invalid dart code';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    // Ensure the request returned an error (error repsonses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(executeCommand(command),
        throwsA(isResponseError(ServerErrorCodes.FileHasErrors)));
  }

  test_unavailableWhenNotRequested() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Refactor]);

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNull);
  }
}

abstract class SourceCodeActionsTest extends AbstractCodeActionsTest {
  Future<void> checkCodeActionAvailable(
    Uri uri,
    String command,
    String title, {
    bool asCodeActionLiteral = false,
    bool asCommand = false,
  }) async {
    final codeActions = await getCodeActions(uri.toString());
    final codeAction = _findCommand(codeActions, command);
    expect(codeAction, isNotNull);

    codeAction.map(
      (command) {
        if (!asCommand) {
          throw 'Got Command but expected CodeAction literal';
        }
        expect(command.title, equals(title));
        expect(command.arguments, equals([uri.toFilePath()]));
      },
      (codeAction) {
        if (!asCodeActionLiteral) {
          throw 'Got CodeAction literal but expected Command';
        }
        expect(codeAction, isNotNull);
        expect(codeAction.title, equals(title));
        expect(codeAction.command.title, equals(title));
        expect(codeAction.command.arguments, equals([uri.toFilePath()]));
      },
    );
  }

  Either2<Command, CodeAction> _findCommand(
      List<Either2<Command, CodeAction>> actions, String commandID) {
    for (var codeAction in actions) {
      final id = codeAction.map(
          (cmd) => cmd.command, (action) => action.command.command);
      if (id == commandID) {
        return codeAction;
      }
    }
    return null;
  }
}
