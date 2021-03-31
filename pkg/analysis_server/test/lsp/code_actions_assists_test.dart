// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssistsCodeActionsTest);
  });
}

@reflectiveTest
class AssistsCodeActionsTest extends AbstractCodeActionsTest {
  @override
  void setUp() {
    super.setUp();
    writePackageConfig(
      projectFolderPath,
      flutter: true,
    );
  }

  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    // This code should get an assist to add a show combinator.
    const content = '''
    import '[[dart:async]]';

    Future f;
    ''';

    const expectedContent = '''
    import 'dart:async' show Future;

    Future f;
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final assist = findEditAction(
        codeActions,
        CodeActionKind('refactor.add.showCombinator'),
        "Add explicit 'show' combinator");

    // Ensure the edit came back, and using documentChanges.
    expect(assist, isNotNull);
    expect(assist.edit.documentChanges, isNotNull);
    expect(assist.edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, assist.edit.documentChanges);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    // This code should get an assist to add a show combinator.
    const content = '''
    import '[[dart:async]]';

    Future f;
    ''';

    const expectedContent = '''
    import 'dart:async' show Future;

    Future f;
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
    );

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final assistAction = findEditAction(
        codeActions,
        CodeActionKind('refactor.add.showCombinator'),
        "Add explicit 'show' combinator");

    // Ensure the edit came back, and using changes.
    expect(assistAction, isNotNull);
    expect(assistAction.edit.changes, isNotNull);
    expect(assistAction.edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, assistAction.edit.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
    );

    final codeActions =
        await getCodeActions(pubspecFileUri.toString(), range: startOfDocRange);
    expect(codeActions, isEmpty);
  }

  Future<void> test_snippetTextEdits_supported() async {
    // This tests experimental support for including Snippets in TextEdits.
    // https://github.com/rust-analyzer/rust-analyzer/blob/b35559a2460e7f0b2b79a7029db0c5d4e0acdb44/docs/dev/lsp-extensions.md#snippet-textedit
    //
    // This allows setting the cursor position/selection in TextEdits included
    // in CodeActions, for example Flutter's "Wrap with widget" assist that
    // should select the text "widget".

    const content = '''
    import 'package:flutter/widgets.dart';
    build() {
      return Container(
        child: Row(
          children: [^
            Text('111'),
            Text('222'),
            Container(),
          ],
        ),
      );
    }
    ''';

    // For testing, the snippet will be inserted literally into the text, as
    // this requires some magic on the client. The expected text should therefore
    // contain the snippets in the standard format.
    const expectedContent = r'''
    import 'package:flutter/widgets.dart';
    build() {
      return Container(
        child: Row(
          children: [
            ${0:widget}(
              children: [
                Text('111'),
                Text('222'),
                Container(),
              ],
            ),
          ],
        ),
      );
    }
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
      experimentalCapabilities: {
        'snippetTextEdit': true,
      },
    );

    final marker = positionFromMarker(content);
    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: Range(start: marker, end: marker));
    final assist = findEditAction(codeActions,
        CodeActionKind('refactor.flutter.wrap.generic'), 'Wrap with widget...');

    // Ensure the edit came back, and using documentChanges.
    expect(assist, isNotNull);
    expect(assist.edit.documentChanges, isNotNull);
    expect(assist.edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, assist.edit.documentChanges);
    expect(contents[mainFilePath], equals(expectedContent));

    // Also ensure there was a single edit that was correctly marked
    // as a SnippetTextEdit.
    final textEdits = _extractTextDocumentEdits(assist.edit.documentChanges)
        .expand((tde) => tde.edits)
        .map((edit) => edit.map(
              (e) => e,
              (e) => throw 'Expected SnippetTextEdit, got AnnotatedTextEdit',
              (e) => throw 'Expected SnippetTextEdit, got TextEdit',
            ))
        .toList();
    expect(textEdits, hasLength(1));
    expect(textEdits.first.insertTextFormat, equals(InsertTextFormat.Snippet));
  }

  Future<void> test_snippetTextEdits_unsupported() async {
    // This tests experimental support for including Snippets in TextEdits
    // is not active when the client capabilities do not advertise support for it.
    // https://github.com/rust-analyzer/rust-analyzer/blob/b35559a2460e7f0b2b79a7029db0c5d4e0acdb44/docs/dev/lsp-extensions.md#snippet-textedit

    const content = '''
    import 'package:flutter/widgets.dart';
    build() {
      return Container(
        child: Row(
          children: [^
            Text('111'),
            Text('222'),
            Container(),
          ],
        ),
      );
    }
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );

    final marker = positionFromMarker(content);
    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: Range(start: marker, end: marker));
    final assist = findEditAction(codeActions,
        CodeActionKind('refactor.flutter.wrap.generic'), 'Wrap with widget...');

    // Ensure the edit came back, and using documentChanges.
    expect(assist, isNotNull);
    expect(assist.edit.documentChanges, isNotNull);
    expect(assist.edit.changes, isNull);

    // Extract just TextDocumentEdits, create/rename/delete are not relevant.
    final textDocumentEdits =
        _extractTextDocumentEdits(assist.edit.documentChanges);
    final textEdits = textDocumentEdits
        .expand((tde) => tde.edits)
        .map((edit) => edit.map((e) => e, (e) => e, (e) => e))
        .toList();

    // Ensure the edit does _not_ have a format of Snippet, nor does it include
    // any $ characters that would indicate snippet text.
    for (final edit in textEdits) {
      expect(edit, isNot(TypeMatcher<SnippetTextEdit>()));
      expect(edit.newText, isNot(contains(r'$')));
    }
  }

  List<TextDocumentEdit> _extractTextDocumentEdits(
          Either2<
                  List<TextDocumentEdit>,
                  List<
                      Either4<TextDocumentEdit, CreateFile, RenameFile,
                          DeleteFile>>>
              documentChanges) =>
      documentChanges.map(
        // Already TextDocumentEdits
        (edits) => edits,
        // Extract TextDocumentEdits from union of resource changes
        (changes) => changes
            .map(
              (change) => change.map(
                (textDocEdit) => textDocEdit,
                (create) => null,
                (rename) => null,
                (delete) => null,
              ),
            )
            .where((e) => e != null)
            .toList(),
      );
}
