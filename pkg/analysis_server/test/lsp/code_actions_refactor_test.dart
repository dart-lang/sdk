// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractMethodRefactorCodeActionsTest);
    defineReflectiveTests(ExtractWidgetRefactorCodeActionsTest);
    defineReflectiveTests(ExtractVariableRefactorCodeActionsTest);
    defineReflectiveTests(InlineLocalVariableRefactorCodeActionsTest);
    defineReflectiveTests(InlineMethodRefactorCodeActionsTest);
    defineReflectiveTests(ConvertGetterToMethodCodeActionsTest);
    defineReflectiveTests(ConvertMethodToGetterCodeActionsTest);
  });
}

@reflectiveTest
class ConvertGetterToMethodCodeActionsTest extends AbstractCodeActionsTest {
  final refactorTitle = 'Convert Getter to Method';

  Future<void> test_refactor() async {
    const content = '''
int get ^test => 42;
main() {
  var a = test;
  var b = test;
}
''';
    const expectedContent = '''
int test() => 42;
main() {
  var a = test();
  var b = test();
}
''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        position: positionFromMarker(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, refactorTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }
}

@reflectiveTest
class ConvertMethodToGetterCodeActionsTest extends AbstractCodeActionsTest {
  final refactorTitle = 'Convert Method to Getter';

  Future<void> test_refactor() async {
    const content = '''
int ^test() => 42;
main() {
  var a = test();
  var b = test();
}
''';
    const expectedContent = '''
int get test => 42;
main() {
  var a = test;
  var b = test;
}
''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        position: positionFromMarker(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, refactorTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }
}

@reflectiveTest
class ExtractMethodRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractMethodTitle = 'Extract Method';

  /// A stream of strings (CREATE, BEGIN, END) corresponding to progress
  /// requests and notifications for convenience in testing.
  ///
  /// Analyzing statuses are not included.
  Stream<String> get progressUpdates {
    final controller = StreamController<String>();

    requestsFromServer
        .where((r) => r.method == Method.window_workDoneProgress_create)
        .listen((request) async {
      final params = WorkDoneProgressCreateParams.fromJson(
          request.params as Map<String, Object?>);
      if (params.token != analyzingProgressToken) {
        controller.add('CREATE');
      }
    }, onDone: controller.close);
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .listen((notification) {
      final params =
          ProgressParams.fromJson(notification.params as Map<String, Object?>);
      if (params.token != analyzingProgressToken) {
        if (WorkDoneProgressBegin.canParse(params.value, nullLspJsonReporter)) {
          controller.add('BEGIN');
        } else if (WorkDoneProgressEnd.canParse(
            params.value, nullLspJsonReporter)) {
          controller.add('END');
        }
      }
    });

    return controller.stream;
  }

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    const expectedContent = '''
main() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_cancelsInProgress() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    const expectedContent = '''
main() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    // Respond to any applyEdit requests from the server with successful responses
    // and capturing the last edit.
    late WorkspaceEdit edit;
    requestsFromServer.listen((request) async {
      if (request.method == Method.workspace_applyEdit) {
        final params = ApplyWorkspaceEditParams.fromJson(
            request.params as Map<String, Object?>);
        edit = params.edit;
        respondTo(request, ApplyWorkspaceEditResponse(applied: true));
      }
    });

    // Send two requests together.
    final req1 = executeCodeAction(codeAction);
    final req2 = executeCodeAction(codeAction);

    // Expect the first will have cancelled the second.
    await expectLater(
        req1, throwsA(isResponseError(ErrorCodes.RequestCancelled)));
    await req2;

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, edit.changes!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_contentModified() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    // Send an edit request immediately after the refactor request.
    final req1 = executeCodeAction(codeAction);
    await replaceFile(100, mainFileUri, 'new test content');

    // Expect the first to fail because of the modified content.
    await expectLater(
        req1, throwsA(isResponseError(ErrorCodes.ContentModified)));
  }

  Future<void> test_filtersCorrectly() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
        emptyTextDocumentClientCapabilities,
        [CodeActionKind.Empty], // Support everything (empty prefix matches all)
      ),
    );

    final ofKind = (CodeActionKind kind) => getCodeActions(
          mainFileUri.toString(),
          range: rangeFromMarkers(content),
          kinds: [kind],
        );

    // Helper that requests CodeActions for [kind] and ensures all results
    // returned have either an equal kind, or a kind that is prefixed with the
    // requested kind followed by a dot.
    Future<void> checkResults(CodeActionKind kind) async {
      final results = await ofKind(kind);
      for (final result in results) {
        final resultKind = result.map(
          (cmd) => throw 'Expected CodeAction, got Command: ${cmd.title}',
          (action) => action.kind,
        );
        expect(
          '$resultKind',
          anyOf([
            equals('$kind'),
            startsWith('$kind.'),
          ]),
        );
      }
    }

    // Check a few of each that will produces multiple matches and no matches.
    await checkResults(CodeActionKind.Refactor);
    await checkResults(CodeActionKind.RefactorExtract);
    await checkResults(CodeActionKind('refactor.extract.foo'));
    await checkResults(CodeActionKind.RefactorRewrite);
  }

  Future<void> test_generatesNames() async {
    const content = '''
Object main() {
  return Container([[Text('Test!')]]);
}

Object Container(Object text) => null;
Object Text(Object text) => null;
    ''';
    const expectedContent = '''
Object main() {
  return Container(text());
}

Object text() => Text('Test!');

Object Container(Object text) => null;
Object Text(Object text) => null;
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
main() {}
    ''';
    newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNull);
  }

  Future<void> test_progress_clientProvided() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    const expectedContent = '''
main() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
        windowCapabilities:
            withWorkDoneProgressSupport(emptyWindowClientCapabilities));

    // Expect begin/end progress updates without a create, since the
    // token was supplied by us (the client).
    expect(progressUpdates, emitsInOrder(['BEGIN', 'END']));

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent,
        workDoneToken: clientProvidedTestWorkDoneToken);
  }

  Future<void> test_progress_notSupported() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    const expectedContent = '''
main() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    var didGetProgressNotifications = false;
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .listen((_) => didGetProgressNotifications = true);

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);

    expect(didGetProgressNotifications, isFalse);
  }

  Future<void> test_progress_serverGenerated() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    const expectedContent = '''
main() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize(
        windowCapabilities:
            withWorkDoneProgressSupport(emptyWindowClientCapabilities));

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle)!;

    // Ensure the progress messages come through and in the correct order.
    expect(progressUpdates, emitsInOrder(['CREATE', 'BEGIN', 'END']));

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }
}

@reflectiveTest
class ExtractVariableRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractVariableTitle = 'Extract Local Variable';

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
main() {
  foo([[1 + 2]]);
}

void foo(int arg) {}
    ''';
    const expectedContent = '''
main() {
  var arg = 1 + 2;
  foo(arg);
}

void foo(int arg) {}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction = findCommand(
        codeActions, Commands.performRefactor, extractVariableTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_doesNotCreateNameConflicts() async {
    const content = '''
main() {
  var arg = "test";
  foo([[1 + 2]]);
}

void foo(int arg) {}
    ''';
    const expectedContent = '''
main() {
  var arg = "test";
  var arg2 = 1 + 2;
  foo(arg2);
}

void foo(int arg) {}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction = findCommand(
        codeActions, Commands.performRefactor, extractVariableTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }
}

@reflectiveTest
class ExtractWidgetRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractWidgetTitle = 'Extract Widget';

  @override
  void setUp() {
    super.setUp();
    writePackageConfig(
      projectFolderPath,
      flutter: true,
    );
  }

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new [[Column]](
          children: <Widget>[
            new Text('AAA'),
            new Text('BBB'),
          ],
        ),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}
    ''';
    const expectedContent = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        NewWidget(),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Text('AAA'),
        new Text('BBB'),
      ],
    );
  }
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractWidgetTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
main() {}
    ''';
    newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractWidgetTitle);
    expect(codeAction, isNull);
  }
}

@reflectiveTest
class InlineLocalVariableRefactorCodeActionsTest
    extends AbstractCodeActionsTest {
  final inlineVariableTitle = 'Inline Local Variable';

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
void main() {
  var a^ = 1;
  print(a);
  print(a);
  print(a);
}
    ''';
    const expectedContent = '''
void main() {
  print(1);
  print(1);
  print(1);
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        position: positionFromMarker(content));
    final codeAction = findCommand(
        codeActions, Commands.performRefactor, inlineVariableTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }
}

@reflectiveTest
class InlineMethodRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final inlineMethodTitle = 'Inline Method';

  Future<void> test_inlineAtCallSite() async {
    const content = '''
void foo1() {
  ba^r();
}

void foo2() {
  bar();
}

void bar() {
  print('test');
}
    ''';
    const expectedContent = '''
void foo1() {
  print('test');
}

void foo2() {
  bar();
}

void bar() {
  print('test');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        position: positionFromMarker(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, inlineMethodTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_inlineAtMethod() async {
    const content = '''
void foo1() {
  bar();
}

void foo2() {
  bar();
}

void ba^r() {
  print('test');
}
    ''';
    const expectedContent = '''
void foo1() {
  print('test');
}

void foo2() {
  print('test');
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        position: positionFromMarker(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, inlineMethodTitle)!;

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }
}
