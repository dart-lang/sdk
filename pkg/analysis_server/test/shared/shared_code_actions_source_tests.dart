// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';

import '../lsp/code_actions_mixin.dart';
import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../tool/lsp_spec/matchers.dart';
import 'shared_test_interface.dart';

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedOrganizeImportsSourceCodeActionsTests
    on
        SharedTestInterface,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
import 'dart:math';
import 'dart:async';
import 'dart:convert';

Completer? foo;
int minified(int x, int y) => min(x, y);
''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Completer? foo;
int minified(int x, int y) => min(x, y);
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.organizeImports,
    );
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    const content = '''
import 'dart:math';
import 'dart:async';
import 'dart:convert';

Completer? foo;
int minified(int x, int y) => min(x, y);
''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Completer? foo;
int minified(int x, int y) => min(x, y);
''';

    setDocumentChangesSupport(false);
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.organizeImports,
    );
  }

  Future<void> test_availableAsCodeActionLiteral() async {
    const content = '';

    await expectCodeActionLiteral(content, command: Commands.organizeImports);
  }

  Future<void> test_availableAsCommand() async {
    createFile(testFilePath, '');
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport
    await initializeServer();

    var actions = await getCodeActions(testFileUri);
    var action = findCommand(actions, Commands.organizeImports)!;
    action.map(
      (codeActionLiteral) => throw 'Expected command, got codeActionLiteral',
      (command) {},
    );
  }

  Future<void> test_fileHasErrors_failsSilentlyForAutomatic() async {
    failTestOnErrorDiagnostic = false;
    var content = 'invalid dart code';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.organizeImports,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    var command = codeAction.command!;

    // Expect a valid null result.
    var response = await executeCommand(command);
    expect(response, isNull);
  }

  Future<void> test_fileHasErrors_failsWithErrorForManual() async {
    failTestOnErrorDiagnostic = false;
    var content = 'invalid dart code';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.organizeImports,
    );
    var command = codeAction.command!;

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(
      executeCommand(command),
      throwsA(isResponseError(ServerErrorCodes.FileHasErrors)),
    );
  }

  Future<void> test_noEdits() async {
    const content = '''
import 'dart:async';
import 'dart:math';

Completer? foo;
int minified(int x, int y) => min(x, y);
''';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.organizeImports,
    );
    var command = codeAction.command!;

    // Execute the command and it should return without needing us to process
    // a workspace/applyEdit command because there were no edits.
    var commandResponse = await executeCommand(command);
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);
  }

  Future<void> test_unavailableWhenNotRequested() async {
    var content = '';

    setSupportedCodeActionKinds([CodeActionKind.Refactor]); // not Source
    await expectNoAction(content, command: Commands.organizeImports);
  }

  Future<void> test_unavailableWithoutApplyEditSupport() async {
    var content = '';

    setApplyEditSupport(false);
    await expectNoAction(content, command: Commands.organizeImports);
  }
}

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedSortMembersSourceCodeActionsTests
    on
        SharedTestInterface,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
String? b;
String? a;
''';
    const expectedContent = '''
String? a;
String? b;
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    const content = '''
String? b;
String? a;
''';
    const expectedContent = '''
String? a;
String? b;
''';

    setDocumentChangesSupport(false);
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_availableAsCodeActionLiteral() async {
    const content = '';

    await expectCodeActionLiteral(content, command: Commands.sortMembers);
  }

  Future<void> test_availableAsCommand() async {
    createFile(testFilePath, '');
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport
    await initializeServer();

    var actions = await getCodeActions(testFileUri);
    var action = findCommand(actions, Commands.sortMembers)!;
    action.map(
      (codeActionLiteral) => throw 'Expected command, got codeActionLiteral',
      (command) {},
    );
  }

  Future<void> test_failsIfClientDoesntApplyEdits() async {
    const content = '''
String? b;
String? a;
''';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.sortMembers,
    );
    var command = codeAction.command!;

    var commandResponse =
        handleExpectedRequest<
          Object?,
          ApplyWorkspaceEditParams,
          ApplyWorkspaceEditResult
        >(
          Method.workspace_applyEdit,
          ApplyWorkspaceEditParams.fromJson,
          () => executeCommand(command),
          // Claim that we failed tpo apply the edits. This is what the client
          // would do if the edits provided were for an old version of the
          // document.
          handler: (edit) => ApplyWorkspaceEditResult(
            applied: false,
            failureReason: 'Document changed',
          ),
        );

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(
      commandResponse,
      throwsA(isResponseError(ServerErrorCodes.ClientFailedToApplyEdit)),
    );
  }

  Future<void> test_fileHasErrors_failsSilentlyForAutomatic() async {
    failTestOnErrorDiagnostic = false;
    var content = 'invalid dart code';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.sortMembers,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    var command = codeAction.command!;

    // Expect a valid null result.
    var response = await executeCommand(command);
    expect(response, isNull);
  }

  Future<void> test_fileHasErrors_failsWithErrorForManual() async {
    failTestOnErrorDiagnostic = false;
    var content = 'invalid dart code';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.sortMembers,
    );
    var command = codeAction.command!;

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(
      executeCommand(command),
      throwsA(isResponseError(ServerErrorCodes.FileHasErrors)),
    );
  }

  Future<void> test_nonDartFile() async {
    await expectNoAction(
      filePath: pubspecFilePath,
      simplePubspecContent,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_unavailableWhenNotRequested() async {
    var content = '';

    setSupportedCodeActionKinds([CodeActionKind.Refactor]); // not Source
    await expectNoAction(content, command: Commands.sortMembers);
  }

  Future<void> test_unavailableWithoutApplyEditSupport() async {
    var content = '';

    setApplyEditSupport(false);
    await expectNoAction(content, command: Commands.sortMembers);
  }
}

mixin SharedSourceCodeActionsTestMixin
    on
        SharedTestInterface,
        LspRequestHelpersMixin,
        ClientCapabilitiesHelperMixin {
  /// For convenience since source code actions do not rely on a position (but
  /// one must be provided), uses [startOfDocPos] to avoid every test needing
  /// to include a '^' marker.
  @override
  Future<List<CodeAction>> getCodeActions(
    Uri fileUri, {
    Range? range,
    Position? position,
    List<CodeActionKind>? kinds,
    CodeActionTriggerKind? triggerKind,
    ProgressToken? workDoneToken,
  }) {
    return super.getCodeActions(
      fileUri,
      position: startOfDocPos,
      kinds: kinds,
      triggerKind: triggerKind,
      workDoneToken: workDoneToken,
    );
  }

  @override
  Future<void> setUp() async {
    await super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.Source]);
  }
}

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedSourceCodeActionsTests
    on
        SharedTestInterface,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  Future<void> test_filtersCorrectly() async {
    createFile(testFilePath, '');
    await initializeServer();

    ofKind(CodeActionKind kind) => getCodeActions(testFileUri, kinds: [kind]);

    var serverSupportsFixAll = this.serverSupportsFixAll;

    expect(
      await ofKind(CodeActionKind.Source),
      hasLength(serverSupportsFixAll ? 3 : 2),
    );
    expect(await ofKind(CodeActionKind.SourceOrganizeImports), hasLength(1));
    expect(await ofKind(DartCodeActionKind.SortMembers), hasLength(1));
    expect(
      await ofKind(DartCodeActionKind.FixAll),
      hasLength(serverSupportsFixAll ? 1 : 0),
    );
    expect(await ofKind(CodeActionKind('source.foo')), isEmpty);
    expect(await ofKind(CodeActionKind.Refactor), isEmpty);
  }
}
