// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_source_tests.dart';
import 'code_actions_mixin.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceCodeActionsTest);
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
    defineReflectiveTests(FixAllSourceCodeActionsTest);
  });
}

abstract class AbstractSourceCodeActionsTest
    extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin {}

@reflectiveTest
class FixAllSourceCodeActionsTest extends AbstractSourceCodeActionsTest {
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
    newFile(analysisOptionsPath, analysisOptionsContent);
    newFile(mainFilePath, content);

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
    newFile(analysisOptionsPath, analysisOptionsContent);
    newFile(mainFilePath, content);

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
    newFile(analysisOptionsPath, analysisOptionsContent);

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
    newFile(analysisOptionsPath, analysisOptionsContent);

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
      handler: (edit) {
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
    var containerFilePath = join(projectFolderPath, 'lib', 'container.dart');
    var partFilePath = join(projectFolderPath, 'lib', 'part.dart');
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
    newFile(analysisOptionsPath, analysisOptionsContent);
    newFile(containerFilePath, containerFileContent);
    newFile(partFilePath, content);

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
  _MyClass();
}
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.fixAll,
    );
  }

  Future<void> test_unavailable_outsideAnalysisRoot() async {
    var otherFile = convertPath('/other/file.dart');
    var content = '';

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

@reflectiveTest
class OrganizeImportsSourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedOrganizeImportsSourceCodeActionsTests {}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedSortMembersSourceCodeActionsTests {}

@reflectiveTest
class SourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedSourceCodeActionsTests {}
