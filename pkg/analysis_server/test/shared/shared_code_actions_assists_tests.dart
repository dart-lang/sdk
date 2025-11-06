// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../lsp/code_actions_mixin.dart';
import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedAssistsCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  @override
  Future<void> setUp() async {
    await super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);

    registerBuiltInAssistGenerators();

    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    // This code should get an assist to add a show combinator.
    const content = '''
import '[!dart:async!]';

Future? f;
''';

    const expectedContent = '''
import 'dart:async' show Future;

Future? f;
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.add.showCombinator'),
      title: "Add explicit 'show' combinator",
    );
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    // This code should get an assist to add a show combinator.
    const content = '''
import '[!dart:async!]';

Future? f;
''';

    const expectedContent = '''
import 'dart:async' show Future;

Future? f;
''';

    setDocumentChangesSupport(false);
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.add.showCombinator'),
      title: "Add explicit 'show' combinator",
    );
  }

  Future<void> test_codeActionLiterals_supported() async {
    setSnippetTextEditSupport();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);

    const content = '''
import 'package:flutter/widgets.dart';
Widget build() {
  return Te^xt('');
}
''';

    const expectedContent = r'''
>>>>>>>>>> lib/test.dart
import 'package:flutter/widgets.dart';
Widget build() {
  return Center($0child: Text(''));
}
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      title: 'Wrap with Center',
    );
  }

  Future<void> test_codeActionLiterals_unsupported() async {
    setSnippetTextEditSupport();
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport

    const content = '''
import 'package:flutter/widgets.dart';
Widget build() {
  return Te[!!]xt('');
}
''';

    const expectedContent = r'''
>>>>>>>>>> lib/test.dart
import 'package:flutter/widgets.dart';
Widget build() {
  return Center(child: Text(''));
}
''';

    await verifyCommandCodeActionEdits(
      content,
      expectedContent,
      command: Commands.applyCodeAction,
      title: 'Wrap with Center',
    );

    expectCommandLogged(Commands.applyCodeAction);
    expectCommandLogged('dart.assist.flutter.wrap.center');
  }

  Future<void> test_errorMessage_invalidIntegers() async {
    // A VS Code code coverage extension has been seen to use Number.MAX_VALUE
    // for the character position and resulted in:
    //
    //     type 'double' is not a subtype of type 'int'
    //
    // This test ensures the error message for these invalid params is clearer,
    // indicating this is not a valid (Dart) int.
    // https://github.com/dart-lang/sdk/issues/42786

    createFile(testFilePath, '');
    await initializeServer();

    var request = makeRequest(
      Method.textDocument_codeAction,
      _RawParams('''
      {
        "textDocument": {
          "uri": "$testFileUri"
        },
        "context": {
          "diagnostics": []
        },
        "range": {
          "start": {
            "line": 3,
            "character": 2
          },
          "end": {
            "line": 3,
            "character": 1.7976931348623157e+308
          }
        }
      }
'''),
    );
    var resp = await sendRequestToServer(request);
    var error = resp.error!;
    expect(error.code, equals(ErrorCodes.InvalidParams));
    expect(
      error.message,
      allOf([
        contains('Invalid params for textDocument/codeAction'),
        contains('params.range.end.character must be of type int'),
      ]),
    );
  }

  Future<void> test_flutterWrap_selection() async {
    const content = '''
import 'package:flutter/widgets.dart';
Widget build() {
  return Te^xt('');
}
''';

    // For testing, the snippet will be inserted literally into the text, as
    // this requires some magic on the client. The expected text should
    // therefore contain '$0' at the location of the selection/final tabstop.
    const expectedContent = r'''
import 'package:flutter/widgets.dart';
Widget build() {
  return Center($0child: Text(''));
}
''';

    setSnippetTextEditSupport();
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.flutter.wrap.center'),
      title: 'Wrap with Center',
    );
  }

  Future<void> test_logsExecution() async {
    const content = '''
import '[!dart:async!]';

Future? f;
''';

    var action = await expectCodeActionLiteral(
      content,
      kind: CodeActionKind('refactor.add.showCombinator'),
      title: "Add explicit 'show' combinator",
    );

    await executeCommand(action.command!);
    expectCommandLogged('dart.assist.add.showCombinator');
  }

  Future<void> test_nonDartFile() async {
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);

    createFile(pubspecFilePath, simplePubspecContent);
    await initializeServer();

    var codeActions = await getCodeActions(
      pubspecFileUri,
      range: startOfDocRange,
    );
    expect(codeActions, isEmpty);
  }

  Future<void> test_snippetTextEdits_multiEditGroup() async {
    // As test_snippetTextEdits_singleEditGroup, but uses an assist that
    // produces multiple linked edit groups.

    const content = '''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Ro^w(
      children: [
        Text('111'),
        Text('222'),
        Container(),
      ],
    ),
  );
}
''';

    const expectedContent = r'''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: ${1:widget}(
      ${2:child}: Row(
        children: [
          Text('111'),
          Text('222'),
          Container(),
        ],
      ),
    ),
  );
}
''';

    setSnippetTextEditSupport();
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.flutter.wrap.generic'),
      title: 'Wrap with widget...',
    );
  }

  Future<void> test_snippetTextEdits_singleEditGroup() async {
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
    // this requires some magic on the client. The expected text should
    // therefore contain the snippets in the standard format.
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

    setSnippetTextEditSupport();
    var verifier = await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.flutter.wrap.generic'),
      title: 'Wrap with widget...',
    );

    // Also ensure there was a single edit that was correctly marked
    // as a SnippetTextEdit.
    var textEdits = extractTextDocumentEdits(verifier.edit.documentChanges!)
        .expand((tde) => tde.edits)
        .map(
          (edit) => edit.map(
            (e) => throw 'Expected SnippetTextEdit, got AnnotatedTextEdit',
            (e) => e,
            (e) => throw 'Expected SnippetTextEdit, got TextEdit',
          ),
        )
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

    var assist = await expectCodeActionLiteral(
      content,
      kind: CodeActionKind('refactor.flutter.wrap.generic'),
      title: 'Wrap with widget...',
    );

    // Extract just TextDocumentEdits, create/rename/delete are not relevant.
    var edit = assist.edit!;
    var textDocumentEdits = extractTextDocumentEdits(edit.documentChanges!);
    var textEdits = textDocumentEdits
        .expand((tde) => tde.edits)
        .map((edit) => edit.map((e) => e, (e) => e, (e) => e))
        .toList();

    // Ensure the edit does _not_ have a format of Snippet, nor does it include
    // any $ characters that would indicate snippet text.
    for (var edit in textEdits) {
      expect(edit, isNot(TypeMatcher<SnippetTextEdit>()));
      expect(edit.newText, isNot(contains(r'$')));
    }
  }

  Future<void> test_sort() async {
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);

    var code = TestCode.parse('''
import 'package:flutter/widgets.dart';

build() => Contai^ner(child: Container());
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      position: code.position.position,
    );
    var codeActionTitles = codeActions.map((action) => action.title);

    expect(
      codeActionTitles,
      containsAllInOrder([
        // Check the ordering for two well-known assists that should always be
        // sorted this way.
        // https://github.com/Dart-Code/Dart-Code/issues/3646
        'Wrap with widget...',
        'Remove this widget',
      ]),
    );
  }

  Future<void> test_surround_editGroupsAndSelection() async {
    const content = '''
void f() {
  [!print(0);!]
}
''';

    const expectedContent = r'''
void f() {
  if (${1:condition}) {
    print(0);
  }$0
}
''';

    setSnippetTextEditSupport();
    var verifier = await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.surround.if'),
      title: "Surround with 'if'",
    );

    // Also ensure there was a single edit that was correctly marked
    // as a SnippetTextEdit.
    var textEdits = extractTextDocumentEdits(verifier.edit.documentChanges!)
        .expand((tde) => tde.edits)
        .map(
          (edit) => edit.map(
            (e) => throw 'Expected SnippetTextEdit, got AnnotatedTextEdit',
            (e) => e,
            (e) => throw 'Expected SnippetTextEdit, got TextEdit',
          ),
        )
        .toList();
    expect(textEdits, hasLength(1));
    expect(textEdits.first.insertTextFormat, equals(InsertTextFormat.Snippet));
  }
}

class _RawParams extends ToJsonable {
  final String _json;

  _RawParams(this._json);

  @override
  Object toJson() => jsonDecode(_json) as Object;
}
