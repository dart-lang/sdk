// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
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
class OrganizeImportsSourceCodeActionsTest extends AbstractCodeActionsTest {
  test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
import 'dart:math';
import 'dart:async';
import 'dart:convert';

Future foo;
int minified(int x, int y) => min(x, y);
    ''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Future foo;
int minified(int x, int y) => min(x, y);
    ''';
    await newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withDocumentChangesSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    ApplyWorkspaceEditParams editParams;

    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return new ApplyWorkspaceEditResponse(true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using the documentChanges.
    expect(editParams, isNotNull);
    expect(editParams.edit.documentChanges, isNotNull);
    expect(editParams.edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, editParams.edit.documentChanges);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    const content = '''
import 'dart:math';
import 'dart:async';
import 'dart:convert';

Future foo;
int minified(int x, int y) => min(x, y);
    ''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Future foo;
int minified(int x, int y) => min(x, y);
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    ApplyWorkspaceEditParams editParams;

    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return new ApplyWorkspaceEditResponse(true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using changes.
    expect(editParams, isNotNull);
    expect(editParams.edit.changes, isNotNull);
    expect(editParams.edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, editParams.edit.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  test_availableAsCodeActionLiteral() async {
    await newFile(mainFilePath);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Source]),
    );

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
    final codeAction = findCommand(codeActions, Commands.organizeImports);
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

  test_noEdits() async {
    const content = '''
import 'dart:async';
import 'dart:math';

Future foo;
int minified(int x, int y) => min(x, y);
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    // Execute the command and it should return without needing us to process
    // a workspace/applyEdit command because there were no edits.
    final commandResponse = await executeCommand(command);
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);
  }

  test_unavailableWhenNotRequested() async {
    await newFile(mainFilePath);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
    );

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNull);
  }
}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends AbstractCodeActionsTest {
  test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
    String b;
    String a;
    ''';
    const expectedContent = '''
    String a;
    String b;
    ''';
    await newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withDocumentChangesSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    ApplyWorkspaceEditParams editParams;

    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return new ApplyWorkspaceEditResponse(true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using the documentChanges.
    expect(editParams, isNotNull);
    expect(editParams.edit.documentChanges, isNotNull);
    expect(editParams.edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, editParams.edit.documentChanges);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
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
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    ApplyWorkspaceEditParams editParams;

    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(command),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return new ApplyWorkspaceEditResponse(true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using changes.
    expect(editParams, isNotNull);
    expect(editParams.edit.changes, isNotNull);
    expect(editParams.edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, editParams.edit.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  test_availableAsCodeActionLiteral() async {
    await newFile(mainFilePath);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Source]),
    );

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
    const content = '''
    String b;
    String a;
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
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
    final codeAction = findCommand(codeActions, Commands.sortMembers);
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
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
    );

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNull);
  }
}
