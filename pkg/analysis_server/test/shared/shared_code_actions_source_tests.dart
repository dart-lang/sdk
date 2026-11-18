// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

import '../lsp/code_actions_mixin.dart';
import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedFixAllSourceCodeActionsTests
    on
        SharedTestInterface,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspReverseRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  @override
  Future<void> setUp() async {
    await super.setUp();

    // Fix tests are likely to have diagnostics that need fixing.
    failTestOnErrorDiagnostic = false;

    registerBuiltInFixGenerators();
  }

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
    createFile(analysisOptionsPath, analysisOptionsContent);
    createFile(testFilePath, content);

    await verifyCodeActionLiteralEdits(
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
    createFile(analysisOptionsPath, analysisOptionsContent);
    createFile(testFilePath, content);

    await verifyCodeActionLiteralEdits(
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
    createFile(analysisOptionsPath, analysisOptionsContent);

    await verifyCodeActionLiteralEdits(
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
    createFile(analysisOptionsPath, analysisOptionsContent);

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.fixAll,
    );
    var command = codeAction.command!;

    // Files must be open to apply edits.
    await openFile(testFileUri, content);

    // Execute the command with a modification and capture the edit that is
    // sent back to us.
    ApplyWorkspaceEditParams? editParams;
    await handleExpectedRequest<
      Object?,
      ApplyWorkspaceEditParams,
      ApplyWorkspaceEditResult
    >(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () async {
        // Apply the command and immediately modify a file afterwards without
        // awaiting.
        var commandFuture = executeCommand(command);
        await replaceFile(12345, testFileUri, 'client-modified-content');

        return commandFuture;
      },
      handler: (edit) async {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (we'll verify the actual edit below).
        editParams = edit;
        return ApplyWorkspaceEditResult(applied: true);
      },
    );

    // Extract the text edit from the 'workspace/applyEdit' params the server
    // sent us.
    var change = editParams?.edit.documentChanges!.single;
    var edit = change!.map(
      (create) => throw 'Expected edit, got create',
      (delete) => throw 'Expected edit, got delete',
      (rename) => throw 'Expected edit, got rename',
      (edit) => edit,
    );
    // Ensure the edit says that it was based on version 1 (the original
    // version) and not the updated 12345 version we sent.
    expect(edit.textDocument.version, 1);
  }

  Future<void> test_part() async {
    var containerFilePath = pathContext.join(
      projectFolderPath,
      'lib',
      'container.dart',
    );
    var partFilePath = pathContext.join(projectFolderPath, 'lib', 'part.dart');
    const analysisOptionsContent = '''
linter:
  rules:
    - unnecessary_new
    - prefer_collection_literals
''';
    const containerFileContent = '''
part 'part.dart';
''';
    const content = '''
part of 'container.dart';

final a = new Object();
final b = new Set<String>();
''';
    const expectedContent = '''
part of 'container.dart';

final a = Object();
final b = <String>{};
''';

    registerLintRules();
    createFile(analysisOptionsPath, analysisOptionsContent);
    createFile(containerFilePath, containerFileContent);
    createFile(partFilePath, content);

    await verifyCodeActionLiteralEdits(
      filePath: partFilePath,
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }

  Future<void> test_privateUnusedParameters_notRemovedIfSave() async {
    const content = '''
class _MyClass {
  int? _param;
  _MyClass({
    this._param,
  });
}
''';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.fixAll,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    var command = codeAction.command!;

    // We should not get an applyEdit call during the command execution because
    // no edits should be produced.
    var applyEditSubscription = requestsFromServer
        .where((n) => n.method == Method.workspace_applyEdit)
        .listen((_) => throw 'workspace/applyEdit was unexpectedly called');
    var commandResponse = await executeCommand(command);
    expect(commandResponse, isNull);

    await pumpEventQueue();
    await applyEditSubscription.cancel();
  }

  Future<void> test_privateUnusedParameters_removedByDefault() async {
    const content = '''
class _MyClass {
  int? param;
  _MyClass({
    this.param,
  });
}
''';
    const expectedContent = '''
class _MyClass {
  int? param;
  _MyClass() : param = null;
}
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }

  /// We should only add dependencies to pubspec to fix diagnostics in the
  /// current file and not other files.
  Future<void> test_pubspec() async {
    createFile(analysisOptionsPath, '''
linter:
  rules:
    - depend_on_referenced_packages
''');

    createFile(pubspecFilePath, '''
name: x
''');

    // Main file content. We should get a new dependency for this.
    const content = '''
import 'package:path/path.dart';
''';

    // Another file that we're not fixing. We should not get a dependency for
    // this.
    createFile(pathContext.join(projectFolderPath, 'lib', 'other.dart'), '''
import 'package:args/args.dart';
''');

    var action = await expectCodeActionLiteral(
      filePath: testFilePath,
      content,
      command: Commands.fixAll,
    );

    // Expect only 'path', not 'args'.
    await verifyCommandEdits(action.command!, '''
>>>>>>>>>> pubspec.yaml
name: x
dependencies:
  path: any
''');
  }

  Future<void> test_pubspec_noLint() async {
    createFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_final_locals
''');

    createFile(pubspecFilePath, '''
name: x
''');

    const content = '''
import 'package:path/path.dart';

void f() {
  var a = 'test';
}
''';

    var action = await expectCodeActionLiteral(
      filePath: testFilePath,
      content,
      command: Commands.fixAll,
    );

    // Expect only 'test.dart' edits, no pubspec edit.
    await verifyCommandEdits(action.command!, '''
>>>>>>>>>> lib/test.dart
import 'package:path/path.dart';

void f() {
  final a = 'test';
}
''');
  }

  Future<void> test_unavailable_outsideAnalysisRoot() async {
    var otherFilePath = pathContext.normalize(
      pathContext.join(projectFolderPath, '..', 'otherProject', 'file.dart'),
    );
    var content = '';

    await expectNoAction(
      filePath: otherFilePath,
      content,
      command: Commands.fixAll,
    );
  }

  Future<void> test_unusedUsings_notRemovedIfSave() async {
    const content = '''
import 'dart:async';
int? a;
''';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.fixAll,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    var command = codeAction.command!;

    // We should not get an applyEdit call during the command execution because
    // no edits should be produced.
    var applyEditSubscription = requestsFromServer
        .where((n) => n.method == Method.workspace_applyEdit)
        .listen((_) => throw 'workspace/applyEdit was unexpectedly called');
    var commandResponse = await executeCommand(command);
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }
}

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedFlutterFixAllSourceCodeActionsTests
    on
        SharedTestInterface,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  bool get addFlutterPackageDep => true;

  @override
  Future<void> setUp() async {
    await super.setUp();

    failTestOnErrorDiagnostic = false;
    registerBuiltInFixGenerators();
  }

  Future<void> test_removeNestedContainers_automatic() async {
    const analysisOptionsContent = '''
linter:
  rules:
    - avoid_unnecessary_containers
''';
    const content = '''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
    child: Row(
      children: [
        Container(
          child: Row(
            children: [Text('...')],
          ),
        ),
      ],
    ),
  );
}
''';
    const expectedContent = '''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Row(
    children: [
      Row(
        children: [Text('...')],
      ),
    ],
  );
}
''';

    registerLintRules();
    createFile(analysisOptionsPath, analysisOptionsContent);

    var action = await expectCodeActionLiteral(
      content,
      command: Commands.fixAll,
      triggerKind: CodeActionTriggerKind.Automatic,
    );
    await verifyCodeActionEdits(CodeAction.t1(action), '''
>>>>>>>>>> lib/test.dart
$expectedContent''');
  }
}

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
      throwsA(isResponseError(ServerErrorCodes.fileHasErrors)),
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
          handler: (edit) async => ApplyWorkspaceEditResult(
            applied: false,
            failureReason: 'Document changed',
          ),
        );

    // Ensure the request returned an error (error responses are thrown by
    // the test helper to make consuming success results simpler).
    await expectLater(
      commandResponse,
      throwsA(isResponseError(ServerErrorCodes.clientFailedToApplyEdit)),
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
      throwsA(isResponseError(ServerErrorCodes.fileHasErrors)),
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

    expect(await ofKind(CodeActionKind.Source), hasLength(3));
    expect(await ofKind(CodeActionKind.SourceOrganizeImports), hasLength(1));
    expect(await ofKind(DartCodeActionKind.sortMembers), hasLength(1));
    expect(await ofKind(DartCodeActionKind.fixAll), hasLength(1));
    expect(await ofKind(CodeActionKind('source.foo')), isEmpty);
    expect(await ofKind(CodeActionKind.Refactor), isEmpty);
  }

  /// Source actions should come last in case editors show them in the main
  /// CodeActions list.
  ///
  /// https://github.com/dart-lang/sdk/issues/64939
  Future<void> test_sortedLast() async {
    failTestOnErrorDiagnostic = false;

    // Include fixes so we can ensure we appear after them.
    setSupportedCodeActionKinds([
      CodeActionKind.Source,
      CodeActionKind.QuickFix,
    ]);
    registerBuiltInFixGenerators();

    var code = TestCode.parseNormalized('String x = 1^;');
    createFile(testFilePath, code.code);
    await initializeServer();

    var actions = await getCodeActions(
      testFileUri,
      position: code.position.position,
    );

    var titles = actions.map((action) => action.title).toList();

    expect(
      titles,
      containsAllInOrder([
        // Fixes
        'Change \'String\' to \'int\' type annotation',
        'Add cast',
        // Source
        'Sort Members',
        'Organize Imports',
      ]),
    );
  }
}
