// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
  });
}

@reflectiveTest
class OrganizeImportsSourceCodeActionsTest extends AbstractCodeActionsTest {
  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
import 'dart:math';
import 'dart:async';
import 'dart:convert';

Completer foo;
int minified(int x, int y) => min(x, y);
    ''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities: withApplyEditSupport(
            withDocumentChangesSupport(emptyWorkspaceClientCapabilities)));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(codeAction, content, expectedContent,
        expectDocumentChanges: true);
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    const content = '''
import 'dart:math';
import 'dart:async';
import 'dart:convert';

Completer foo;
int minified(int x, int y) => min(x, y);
    ''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(codeAction, content, expectedContent);
  }

  Future<void> test_availableAsCodeActionLiteral() async {
    newFile(mainFilePath);
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.Source]),
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.organizeImports,
      'Organize Imports',
      asCodeActionLiteral: true,
    );
  }

  Future<void> test_availableAsCommand() async {
    newFile(mainFilePath);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.organizeImports,
      'Organize Imports',
      asCommand: true,
    );
  }

  Future<void> test_failsSilentlyIfFileHasErrors() async {
    final content = 'invalid dart code';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNotNull);

    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command,
    );

    final commandResponse = await executeCommand(command);
    // Invalid code returns an empty success() response to avoid triggering
    // errors in the editor if run automatically on every save.
    expect(commandResponse, isNull);
  }

  Future<void> test_noEdits() async {
    const content = '''
import 'dart:async';
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

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

  Future<void> test_unavailableWhenNotRequested() async {
    newFile(mainFilePath);
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNull);
  }

  Future<void> test_unavailableWithoutApplyEditSupport() async {
    newFile(mainFilePath);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNull);
  }
}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends AbstractCodeActionsTest {
  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
    String b;
    String a;
    ''';
    const expectedContent = '''
    String a;
    String b;
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities: withApplyEditSupport(
            withDocumentChangesSupport(emptyWorkspaceClientCapabilities)));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(codeAction, content, expectedContent,
        expectDocumentChanges: true);
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    const content = '''
    String b;
    String a;
    ''';
    const expectedContent = '''
    String a;
    String b;
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(codeAction, content, expectedContent);
  }

  Future<void> test_availableAsCodeActionLiteral() async {
    newFile(mainFilePath);
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.Source]),
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.sortMembers,
      'Sort Members',
      asCodeActionLiteral: true,
    );
  }

  Future<void> test_availableAsCommand() async {
    newFile(mainFilePath);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.sortMembers,
      'Sort Members',
      asCommand: true,
    );
  }

  Future<void> test_failsIfClientDoesntApplyEdits() async {
    const content = '''
    String b;
    String a;
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

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
      ApplyWorkspaceEditParams.fromJson,
      () => executeCommand(command),
      // Claim that we failed tpo apply the edits. This is what the client
      // would do if the edits provided were for an old version of the
      // document.
      handler: (edit) => ApplyWorkspaceEditResponse(
          applied: false, failureReason: 'Document changed'),
    );

    // Ensure the request returned an error (error repsonses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(commandResponse,
        throwsA(isResponseError(ServerErrorCodes.ClientFailedToApplyEdit)));
  }

  Future<void> test_failsIfFileHasErrors() async {
    final content = 'invalid dart code';
    newFile(mainFilePath, content: content);
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

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

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.Source]),
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    final codeActions =
        await getCodeActions(pubspecFileUri.toString(), range: startOfDocRange);
    expect(codeActions, isEmpty);
  }

  Future<void> test_unavailableWhenNotRequested() async {
    newFile(mainFilePath);
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNull);
  }

  Future<void> test_unavailableWithoutApplyEditSupport() async {
    newFile(mainFilePath);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNull);
  }
}
