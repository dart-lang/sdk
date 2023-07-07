// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
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
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);
  }

  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    // This code should get an assist to add a show combinator.
    const content = '''
import '[!dart:async!]';

Future f;
''';

    const expectedContent = '''
import 'dart:async' show Future;

Future f;
''';
    await verifyActionEdits(
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

Future f;
''';

    const expectedContent = '''
import 'dart:async' show Future;

Future f;
''';

    setDocumentChangesSupport(false);
    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.add.showCombinator'),
      title: "Add explicit 'show' combinator",
    );
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

    newFile(mainFilePath, '');
    await initialize();

    final request = makeRequest(
      Method.textDocument_codeAction,
      _RawParams('''
      {
        "textDocument": {
          "uri": "$mainFileUri"
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
    final resp = await sendRequestToServer(request);
    final error = resp.error!;
    expect(error.code, equals(ErrorCodes.InvalidParams));
    expect(
        error.message,
        allOf([
          contains('Invalid params for textDocument/codeAction'),
          contains('params.range.end.character must be of type int'),
        ]));
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
    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.flutter.wrap.center'),
      title: 'Wrap with Center',
    );
  }

  Future<void> test_logsExecution() async {
    const content = '''
import '[!dart:async!]';

Future f;
''';

    final action = await expectAction(
      content,
      kind: CodeActionKind('refactor.add.showCombinator'),
      title: "Add explicit 'show' combinator",
    );

    await executeCommand(action.command!);
    expectCommandLogged('dart.assist.add.showCombinator');
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
    );

    final codeActions =
        await getCodeActions(pubspecFileUri, range: startOfDocRange);
    expect(codeActions, isEmpty);
  }

  Future<void> test_plugin() async {
    if (!AnalysisServer.supportsPlugins) return;
    // This code should get an assist to replace 'foo' with 'bar'.'
    const content = '''
[!foo!]
''';
    const expectedContent = '''
bar
''';

    final pluginResult = plugin.EditGetAssistsResult([
      plugin.PrioritizedSourceChange(
        0,
        plugin.SourceChange(
          "Change 'foo' to 'bar'",
          edits: [
            plugin.SourceFileEdit(mainFilePath, 0,
                edits: [plugin.SourceEdit(0, 3, 'bar')])
          ],
          id: 'fooToBar',
        ),
      )
    ]);
    configureTestPlugin(
      handler: (request) =>
          request is plugin.EditGetAssistsParams ? pluginResult : null,
    );

    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.fooToBar'),
      title: "Change 'foo' to 'bar'",
    );
  }

  Future<void> test_plugin_sortsWithServer() async {
    if (!AnalysisServer.supportsPlugins) return;
    // Produces a server assist of "Convert to single quoted string" (with a
    // priority of 30).
    final code = TestCode.parse('import "[!dart:async!]";');

    // Provide two plugin results that should sort either side of the server assist.
    final pluginResult = plugin.EditGetAssistsResult([
      plugin.PrioritizedSourceChange(10, plugin.SourceChange('Low')),
      plugin.PrioritizedSourceChange(100, plugin.SourceChange('High')),
    ]);
    configureTestPlugin(
      handler: (request) =>
          request is plugin.EditGetAssistsParams ? pluginResult : null,
    );

    newFile(mainFilePath, code.code);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
    final codeActionTitles = codeActions.map((action) =>
        action.map((command) => command.title, (action) => action.title));

    expect(
      codeActionTitles,
      containsAllInOrder([
        'High',
        'Convert to single quoted string',
        'Low',
      ]),
    );
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
    await verifyActionEdits(
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
    final verifier = await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.flutter.wrap.generic'),
      title: 'Wrap with widget...',
    );

    // Also ensure there was a single edit that was correctly marked
    // as a SnippetTextEdit.
    final textEdits = extractTextDocumentEdits(verifier.edit.documentChanges!)
        .expand((tde) => tde.edits)
        .map((edit) => edit.map(
              (e) => throw 'Expected SnippetTextEdit, got AnnotatedTextEdit',
              (e) => e,
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

    final assist = await expectAction(
      content,
      kind: CodeActionKind('refactor.flutter.wrap.generic'),
      title: 'Wrap with widget...',
    );

    // Extract just TextDocumentEdits, create/rename/delete are not relevant.
    final edit = assist.edit!;
    final textDocumentEdits = extractTextDocumentEdits(edit.documentChanges!);
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

  Future<void> test_sort() async {
    const content = '''
import 'package:flutter/widgets.dart';

build() => Contai^ner(child: Container());
''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.Refactor]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );

    final codeActions = await getCodeActions(mainFileUri,
        position: positionFromMarker(content));
    final names = codeActions.map(
      (e) => e.map((command) => command.title, (action) => action.title),
    );

    expect(
      names,
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
    final verifier = await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.surround.if'),
      title: "Surround with 'if'",
    );

    // Also ensure there was a single edit that was correctly marked
    // as a SnippetTextEdit.
    final textEdits = extractTextDocumentEdits(verifier.edit.documentChanges!)
        .expand((tde) => tde.edits)
        .map((edit) => edit.map(
              (e) => throw 'Expected SnippetTextEdit, got AnnotatedTextEdit',
              (e) => e,
              (e) => throw 'Expected SnippetTextEdit, got TextEdit',
            ))
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
