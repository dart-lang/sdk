// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixesCodeActionsTest);
  });
}

@reflectiveTest
class FixesCodeActionsTest extends AbstractCodeActionsTest {
  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    // This code should get a fix to remove the unused import.
    const content = '''
    import 'dart:async';
    [[import]] 'dart:convert';

    Future foo;
    ''';

    const expectedContent = '''
    import 'dart:async';

    Future foo;
    ''';
    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final fixAction = findEditAction(codeActions,
        CodeActionKind('quickfix.remove.unusedImport'), 'Remove unused import');

    // Ensure the edit came back, and using documentChanges.
    expect(fixAction, isNotNull);
    expect(fixAction.edit.documentChanges, isNotNull);
    expect(fixAction.edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, fixAction.edit.documentChanges);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    // This code should get a fix to remove the unused import.
    const content = '''
    import 'dart:async';
    [[import]] 'dart:convert';

    Future foo;
    ''';

    const expectedContent = '''
    import 'dart:async';

    Future foo;
    ''';
    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final fixAction = findEditAction(codeActions,
        CodeActionKind('quickfix.remove.unusedImport'), 'Remove unused import');

    // Ensure the edit came back, and using changes.
    expect(fixAction, isNotNull);
    expect(fixAction.edit.changes, isNotNull);
    expect(fixAction.edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, fixAction.edit.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_noDuplicates() async {
    const content = '''
    var a = [Test, Test, Te[[]]st];
    ''';

    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final createClassActions = findEditActions(codeActions,
        CodeActionKind('quickfix.create.class'), "Create class 'Test'");

    expect(createClassActions, hasLength(1));
    expect(createClassActions.first.diagnostics, hasLength(3));
  }

  Future<void> test_noDuplicates_withDocumentChangesSupport() async {
    const content = '''
    var a = [Test, Test, Te[[]]st];
    ''';

    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
        workspaceCapabilities: withApplyEditSupport(
            withDocumentChangesSupport(emptyWorkspaceClientCapabilities)));

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final createClassActions = findEditActions(codeActions,
        CodeActionKind('quickfix.create.class'), "Create class 'Test'");

    expect(createClassActions, hasLength(1));
    expect(createClassActions.first.diagnostics, hasLength(3));
  }

  Future<void> test_nonDartFile() async {
    await newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(pubspecFileUri.toString(), range: startOfDocRange);
    expect(codeActions, isEmpty);
  }

  Future<void> test_organizeImportsFix_namedOrganizeImports() async {
    registerLintRules();
    newFile(analysisOptionsPath, content: '''
linter:
  rules:
    - directives_ordering
    ''');

    // This code should get a fix to sort the imports.
    const content = '''
import 'dart:io';
[[import 'dart:async']];

Completer a;
ProcessInfo b;
    ''';

    const expectedContent = '''
import 'dart:async';
import 'dart:io';

Completer a;
ProcessInfo b;
    ''';
    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final fixAction = findEditAction(codeActions,
        CodeActionKind('quickfix.organize.imports'), 'Organize Imports');

    // Ensure the edit came back, and using changes.
    expect(fixAction, isNotNull);
    expect(fixAction.edit.changes, isNotNull);
    expect(fixAction.edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, fixAction.edit.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }
}
