// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
    defineReflectiveTests(FixAllSourceCodeActionsTest);
  });
}

abstract class AbstractSourceCodeActionsTest extends AbstractCodeActionsTest {
  /// For convenience since source code actions do not rely on a position (but
  /// one must be provided), uses [startOfDocPos] to avoid every test needing
  /// to include a '^' marker.
  @override
  Future<List<Either2<Command, CodeAction>>> getCodeActions(
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
  void setUp() {
    super.setUp();
    setSupportedCodeActionKinds([CodeActionKind.Source]);
  }
}

@reflectiveTest
class FixAllSourceCodeActionsTest extends AbstractSourceCodeActionsTest {
  Future<void> test_appliesCorrectEdits() async {
    const analysisOptionsContent = '''
linter:
  rules:
    - unnecessary_new
    - prefer_collection_literals
''';
    const content = '''
final a = new Object();
final b = new Set<String>();
''';
    const expectedContent = '''
final a = Object();
final b = <String>{};
''';

    registerLintRules();
    newFile(analysisOptionsPath, analysisOptionsContent);
    newFile(mainFilePath, content);

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }

  Future<void> test_multipleIterations_noOverlay() async {
    const analysisOptionsContent = '''
linter:
  rules:
    - prefer_final_locals
    - prefer_const_declarations
    ''';
    const content = '''
void f() {
  var a = 'test';
}
''';
    const expectedContent = '''
void f() {
  const a = 'test';
}
''';

    registerLintRules();
    newFile(analysisOptionsPath, analysisOptionsContent);
    newFile(mainFilePath, content);

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }

  Future<void> test_multipleIterations_overlay() async {
    const analysisOptionsContent = '''
linter:
  rules:
    - prefer_final_locals
    - prefer_const_declarations
    ''';
    const content = '''
void f() {
  var a = 'test';
}
''';
    const expectedContent = '''
void f() {
  const a = 'test';
}
''';

    registerLintRules();
    newFile(analysisOptionsPath, analysisOptionsContent);

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }

  Future<void> test_multipleIterations_withClientModification() async {
    const analysisOptionsContent = '''
linter:
  rules:
    - prefer_final_locals
    - prefer_const_declarations
    ''';
    const content = '''
void f() {
  var a = 'test';
}
''';
    registerLintRules();
    newFile(analysisOptionsPath, analysisOptionsContent);

    final codeAction = await expectAction(
      content,
      command: Commands.fixAll,
    );
    final command = codeAction.command!;

    // Files must be open to apply edits.
    await openFile(mainFileUri, content);

    // Execute the command with a modification and capture the edit that is
    // sent back to us.
    ApplyWorkspaceEditParams? editParams;
    await handleExpectedRequest<Object?, ApplyWorkspaceEditParams,
        ApplyWorkspaceEditResult>(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () async {
        // Apply the command and immediately modify a file afterwards.
        final commandFuture = executeCommand(command);
        await replaceFile(12345, mainFileUri, 'client-modified-content');
        return commandFuture;
      },
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (we'll verify the actual edit below).
        editParams = edit;
        return ApplyWorkspaceEditResult(applied: true);
      },
    );

    // Extract the text edit from the 'workspace/applyEdit' params the server
    // sent us.
    final change = editParams?.edit.documentChanges!.single;
    final edit = change!.map(
      (create) => throw 'Expected edit, got create',
      (delete) => throw 'Expected edit, got delete',
      (rename) => throw 'Expected edit, got rename',
      (edit) => edit,
    );
    // Ensure the edit says that it was based on version 1 (the original
    // version) and not the updated 12345 version we sent.
    expect(edit.textDocument.version, 1);
  }

  Future<void> test_unavailable_outsideAnalysisRoot() async {
    final otherFile = convertPath('/other/file.dart');
    final content = '';

    await expectNoAction(
      filePath: otherFile,
      content,
      command: Commands.organizeImports,
    );
  }

  Future<void> test_unusedUsings_notRemovedIfSave() async {
    const content = '''
import 'dart:async';
int? a;
''';

    final codeAction = await expectAction(
      content,
      command: Commands.fixAll,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    final command = codeAction.command!;

    // We should not get an applyEdit call during the command execution because
    // no edits should be produced.
    final applyEditSubscription = requestsFromServer
        .where((n) => n.method == Method.workspace_applyEdit)
        .listen((_) => throw 'workspace/applyEdit was unexpectedly called');
    final commandResponse = await executeCommand(command);
    expect(commandResponse, isNull);

    await pumpEventQueue();
    await applyEditSubscription.cancel();
  }

  Future<void> test_unusedUsings_removedByDefault() async {
    const content = '''
import 'dart:async';
int? a;
''';
    const expectedContent = '''
int? a;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }
}

@reflectiveTest
class OrganizeImportsSourceCodeActionsTest
    extends AbstractSourceCodeActionsTest {
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

    await verifyActionEdits(
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

Completer foo;
int minified(int x, int y) => min(x, y);
''';
    const expectedContent = '''
import 'dart:async';
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
''';

    setDocumentChangesSupport(false);
    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.organizeImports,
    );
  }

  Future<void> test_availableAsCodeActionLiteral() async {
    const content = '';

    await expectAction(
      content,
      command: Commands.organizeImports,
    );
  }

  Future<void> test_availableAsCommand() async {
    newFile(mainFilePath, '');
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport
    await initialize();

    final actions = await getCodeActions(mainFileUri);
    final action = findCommand(actions, Commands.organizeImports)!;
    action.map(
      (command) {},
      (codeActionLiteral) => throw 'Expected command, got codeActionLiteral',
    );
  }

  Future<void> test_fileHasErrors_failsSilentlyForAutomatic() async {
    final content = 'invalid dart code';

    final codeAction = await expectAction(
      content,
      command: Commands.organizeImports,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    final command = codeAction.command!;

    // Expect a valid null result.
    final response = await executeCommand(command);
    expect(response, isNull);
  }

  Future<void> test_fileHasErrors_failsWithErrorForManual() async {
    final content = 'invalid dart code';

    final codeAction = await expectAction(
      content,
      command: Commands.organizeImports,
    );
    final command = codeAction.command!;

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(executeCommand(command),
        throwsA(isResponseError(ServerErrorCodes.FileHasErrors)));
  }

  Future<void> test_filtersCorrectly() async {
    newFile(mainFilePath, '');
    await initialize();

    ofKind(CodeActionKind kind) => getCodeActions(
          mainFileUri,
          kinds: [kind],
        );

    expect(await ofKind(CodeActionKind.Source), hasLength(3));
    expect(await ofKind(CodeActionKind.SourceOrganizeImports), hasLength(1));
    expect(await ofKind(DartCodeActionKind.SortMembers), hasLength(1));
    expect(await ofKind(DartCodeActionKind.FixAll), hasLength(1));
    expect(await ofKind(CodeActionKind('source.foo')), isEmpty);
    expect(await ofKind(CodeActionKind.Refactor), isEmpty);
  }

  Future<void> test_noEdits() async {
    const content = '''
import 'dart:async';
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
''';

    final codeAction = await expectAction(
      content,
      command: Commands.organizeImports,
    );
    final command = codeAction.command!;

    // Execute the command and it should return without needing us to process
    // a workspace/applyEdit command because there were no edits.
    final commandResponse = await executeCommand(command);
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);
  }

  Future<void> test_unavailableWhenNotRequested() async {
    final content = '';

    setSupportedCodeActionKinds([CodeActionKind.Refactor]); // not Source
    await expectNoAction(
      content,
      command: Commands.organizeImports,
    );
  }

  Future<void> test_unavailableWithoutApplyEditSupport() async {
    final content = '';

    setApplyEditSupport(false);
    await expectNoAction(
      content,
      command: Commands.organizeImports,
    );
  }
}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends AbstractSourceCodeActionsTest {
  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    const content = '''
String b;
String a;
''';
    const expectedContent = '''
String a;
String b;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.sortMembers,
    );
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

    setDocumentChangesSupport(false);
    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_availableAsCodeActionLiteral() async {
    const content = '';

    await expectAction(
      content,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_availableAsCommand() async {
    newFile(mainFilePath, '');
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport
    await initialize();

    final actions = await getCodeActions(mainFileUri);
    final action = findCommand(actions, Commands.sortMembers)!;
    action.map(
      (command) {},
      (codeActionLiteral) => throw 'Expected command, got codeActionLiteral',
    );
  }

  Future<void> test_failsIfClientDoesntApplyEdits() async {
    const content = '''
String b;
String a;
''';

    final codeAction = await expectAction(
      content,
      command: Commands.sortMembers,
    );
    final command = codeAction.command!;

    final commandResponse = handleExpectedRequest<Object?,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResult>(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () => executeCommand(command),
      // Claim that we failed tpo apply the edits. This is what the client
      // would do if the edits provided were for an old version of the
      // document.
      handler: (edit) => ApplyWorkspaceEditResult(
          applied: false, failureReason: 'Document changed'),
    );

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(commandResponse,
        throwsA(isResponseError(ServerErrorCodes.ClientFailedToApplyEdit)));
  }

  Future<void> test_fileHasErrors_failsSilentlyForAutomatic() async {
    final content = 'invalid dart code';

    final codeAction = await expectAction(
      content,
      command: Commands.sortMembers,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    final command = codeAction.command!;

    // Expect a valid null result.
    final response = await executeCommand(command);
    expect(response, isNull);
  }

  Future<void> test_fileHasErrors_failsWithErrorForManual() async {
    final content = 'invalid dart code';

    final codeAction = await expectAction(
      content,
      command: Commands.sortMembers,
    );
    final command = codeAction.command!;

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(executeCommand(command),
        throwsA(isResponseError(ServerErrorCodes.FileHasErrors)));
  }

  Future<void> test_nonDartFile() async {
    await expectNoAction(
      filePath: pubspecFilePath,
      simplePubspecContent,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_unavailableWhenNotRequested() async {
    final content = '';

    setSupportedCodeActionKinds([CodeActionKind.Refactor]); // not Source
    await expectNoAction(
      content,
      command: Commands.sortMembers,
    );
  }

  Future<void> test_unavailableWithoutApplyEditSupport() async {
    final content = '';

    setApplyEditSupport(false);
    await expectNoAction(
      content,
      command: Commands.sortMembers,
    );
  }
}
