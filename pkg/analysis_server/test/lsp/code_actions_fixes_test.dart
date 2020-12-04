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
    defineReflectiveTests(FixesCodeActionsWithNullSafetyTest);
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
    newFile(mainFilePath, content: withoutMarkers(content));
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
    newFile(mainFilePath, content: withoutMarkers(content));
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

  Future<void> test_noDuplicates_sameFix() async {
    const content = '''
    var a = [Test, Test, Te[[]]st];
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
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

    newFile(mainFilePath, content: withoutMarkers(content));
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
    newFile(pubspecFilePath, content: simplePubspecContent);
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
    newFile(mainFilePath, content: withoutMarkers(content));
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

  Future<void> test_outsideRoot() async {
    final otherFilePath = '/home/otherProject/foo.dart';
    final otherFileUri = Uri.file(otherFilePath);
    newFile(otherFilePath, content: 'bad code to create error');
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions = await getCodeActions(otherFileUri.toString());
    expect(codeActions, isEmpty);
  }
}

@reflectiveTest
class FixesCodeActionsWithNullSafetyTest extends AbstractCodeActionsTest {
  @override
  String get testPackageLanguageVersion => latestLanguageVersion;

  Future<void> test_fixAll_notForAmbigiousProducers() async {
    // The ReplaceWithIsEmpty producer does not provide a FixKind up-front, as
    // it may produce `REPLACE_WITH_IS_EMPTY` or `REPLACE_WITH_IS_NOT_EMPTY`
    // depending on the code.
    // This test ensures this does not crash, and does not produce an apply-all.
    registerLintRules();
    newFile(analysisOptionsPath, content: '''
linter:
  rules:
    - prefer_is_empty
    ''');

    const content = '''
var a = [];
var b = a.[[length]] == 0;
var c = a.length == 0;
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final allFixes = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));

    // Expect only the single-fix, there should be no apply-all.
    expect(allFixes, hasLength(1));
    final fixTitle = allFixes.first.map((f) => f.title, (f) => f.title);
    expect(fixTitle, equals("Replace with \'isEmpty\'"));
  }

  Future<void> test_fixAll_notWhenNoBatchFix() async {
    // Some fixes (for example 'create function foo') are not available in the
    // batch processor, so should not generate Apply-all fixes even if there
    // are multiple.
    const content = '''
var a = [[foo]]();
var b = bar();
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final allFixes = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));

    // Expect only the single-fix, there should be no apply-all.
    expect(allFixes, hasLength(1));
    final fixTitle = allFixes.first.map((f) => f.title, (f) => f.title);
    expect(fixTitle, equals("Create function 'foo'"));
  }

  Future<void> test_fixAll_notWhenSingle() async {
    const content = '''
void f(String a) {
  [[print(a!)]];
}
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final fixAction = await getFixAllAction(
        "Apply all: Remove the '!'", mainFileUri, content);

    // Should not appear if there was only a single error.
    expect(fixAction, isNull);
  }

  Future<void> test_fixAll_whenMultiple() async {
    const content = '''
void f(String a) {
  [[print(a!!)]];
  print(a!!);
}
    ''';

    const expectedContent = '''
void f(String a) {
  print(a);
  print(a);
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final fixAction = await getFixAllAction(
        "Apply all: Remove the '!'", mainFileUri, content);

    expect(fixAction, isNotNull);

    await verifyCodeActionEdits(
        fixAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_noDuplicates_differentFix() async {
    // For convenience, quick-fixes are usually returned for the entire line,
    // though this can lead to duplicate entries (by title) when multiple
    // diagnostics have their own fixes of the same type.
    //
    // Expect only the only one nearest to the start of the range to be returned.
    const content = '''
    main() {
      var a = [];
      print(a!!);^
    }
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final caretPos = positionFromMarker(content);

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: Range(start: caretPos, end: caretPos));
    final removeNnaAction = findEditActions(codeActions,
        CodeActionKind('quickfix.remove.nonNullAssertion'), "Remove the '!'");

    // Expect only one of the fixes.
    expect(removeNnaAction, hasLength(1));

    // Ensure the action is for the diagnostic on the second bang which was
    // closest to the range requested.
    final secondBangPos =
        positionFromOffset(withoutMarkers(content).indexOf('!);'), content);
    expect(removeNnaAction.first.diagnostics, hasLength(1));
    final diagStart = removeNnaAction.first.diagnostics.first.range.start;
    expect(diagStart, equals(secondBangPos));
  }
}
