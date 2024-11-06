// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/perform_refactor.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'code_actions_abstract.dart';
import 'request_helpers_mixin.dart';

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
class ConvertGetterToMethodCodeActionsTest extends RefactorCodeActionsTest {
  final refactorTitle = 'Convert Getter to Method';

  Future<void> test_refactor() async {
    const content = '''
int get ^test => 42;
void f() {
  var a = test;
  var b = test;
}
''';
    const expectedContent = '''
int test() => 42;
void f() {
  var a = test();
  var b = test();
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: refactorTitle,
    );
  }

  Future<void> test_setter_notAvailable() async {
    const content = '''
set ^a(String value) {}
''';

    await expectNoAction(
      content,
      command: Commands.performRefactor,
      title: refactorTitle,
    );
  }
}

@reflectiveTest
class ConvertMethodToGetterCodeActionsTest extends RefactorCodeActionsTest {
  final refactorTitle = 'Convert Method to Getter';

  Future<void> test_constructor_notAvailable() async {
    const content = '''
class A {
  ^A();
}
''';

    await expectNoAction(
      content,
      command: Commands.performRefactor,
      title: refactorTitle,
    );
  }

  Future<void> test_refactor() async {
    const content = '''
int ^test() => 42;
void f() {
  var a = test();
  var b = test();
}
''';
    const expectedContent = '''
int get test => 42;
void f() {
  var a = test;
  var b = test;
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: refactorTitle,
    );
  }
}

@reflectiveTest
class ExtractMethodRefactorCodeActionsTest extends RefactorCodeActionsTest
    with LspProgressNotificationsMixin {
  final extractMethodTitle = 'Extract Method';

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';
    const expectedContent = '''
void f() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
''';
    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
  }

  Future<void> test_cancelsInProgress() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';
    const expectedContent = '''
>>>>>>>>>> lib/main.dart
void f() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
''';

    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );

    // Respond to any applyEdit requests from the server with successful responses
    // and capturing the last edit.
    late WorkspaceEdit edit;
    requestsFromServer.listen((request) async {
      if (request.method == Method.workspace_applyEdit) {
        var params = ApplyWorkspaceEditParams.fromJson(
          request.params as Map<String, Object?>,
        );
        edit = params.edit;
        respondTo(request, ApplyWorkspaceEditResult(applied: true));
      }
    });

    // Send two requests together.
    var req1 = executeCommand(codeAction.command!);
    var req2 = executeCommand(codeAction.command!);

    // Expect the first will have cancelled the second.
    await expectLater(
      req1,
      throwsA(isResponseError(ErrorCodes.RequestCancelled)),
    );
    await req2;

    // Ensure applying the changes will give us the expected content.
    verifyEdit(edit, expectedContent);
  }

  Future<void> test_contentModified() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';

    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
      openTargetFile: true,
    );

    // Use a Completer to control when the refactor handler starts computing.
    var completer = Completer<void>();
    PerformRefactorCommandHandler.delayAfterResolveForTests = completer.future;
    try {
      // Send an edit request immediately after the refactor request.
      var req1 = executeCommand(codeAction.command!);
      await replaceFile(100, mainFileUri, 'new test content');
      completer.complete();

      // Expect the first to fail because of the modified content.
      await expectLater(
        req1,
        throwsA(isResponseError(ErrorCodes.ContentModified)),
      );
    } finally {
      // Ensure we never leave an incomplete future if anything above throws.
      PerformRefactorCommandHandler.delayAfterResolveForTests = null;
    }
  }

  Future<void> test_filtersCorrectly() async {
    // Support everything (empty prefix matches all)
    setSupportedCodeActionKinds([CodeActionKind.Empty]);

    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';
    var code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    ofKind(CodeActionKind kind) =>
        getCodeActions(mainFileUri, range: code.range.range, kinds: [kind]);

    // Helper that requests CodeActions for [kind] and ensures all results
    // returned have either an equal kind, or a kind that is prefixed with the
    // requested kind followed by a dot.
    Future<void> checkResults(CodeActionKind kind) async {
      var results = await ofKind(kind);
      for (var result in results) {
        var resultKind = result.map(
          (cmd) => throw 'Expected CodeAction, got Command: ${cmd.title}',
          (action) => action.kind,
        );
        expect('$resultKind', anyOf([equals('$kind'), startsWith('$kind.')]));
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
Object F() {
  return Container([!Text('Test!')!]);
}

Object Container(Object text) => null;
Object Text(Object text) => null;
''';
    const expectedContent = '''
Object F() {
  return Container(text());
}

Object text() => Text('Test!');

Object Container(Object text) => null;
Object Text(Object text) => null;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
  }

  Future<void> test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
void f() {}
''';

    await expectNoAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
  }

  Future<void> test_invalidLocation_importPrefix() async {
    const content = '''
import 'dart:io' as io;

i^o.File a;
''';

    await expectNoAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
  }

  Future<void> test_logsAction() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';

    setDocumentChangesSupport(false);
    var action = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );

    await executeCommandForEdits(action.command!);
    expectCommandLogged('dart.refactor.extract_method');
  }

  Future<void> test_progress_clientProvided() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';
    const expectedContent = '''
void f() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
''';

    // Expect begin/end progress updates without a create, since the
    // token was supplied by us (the client).
    expect(progressUpdates, emitsInOrder(['BEGIN', 'END']));

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractMethodTitle,
      commandWorkDoneToken: clientProvidedTestWorkDoneToken,
    );
  }

  Future<void> test_progress_notSupported() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';
    const expectedContent = '''
void f() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
''';

    var didGetProgressNotifications = false;
    progressUpdates.listen((_) => didGetProgressNotifications = true);

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );

    expect(didGetProgressNotifications, isFalse);
  }

  Future<void> test_progress_serverGenerated() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';
    const expectedContent = '''
void f() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
''';

    // Expect create/begin/end progress updates, because in this case the server
    // generates the token.
    expect(progressUpdates, emitsInOrder(['CREATE', 'BEGIN', 'END']));

    setWorkDoneProgressSupport();
    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
  }

  Future<void> test_validLocation_failsInitialValidation() async {
    const content = '''
f() {
  var a = 0;
  doFoo([!() => print(a)!]);
  print(a);
}

void doFoo(void Function() a) => a();

''';
    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
    var command = codeAction.command!;

    // Call the `refactor.validate` command with the same arguments.
    // Clients that want validation behaviour will need to implement this
    // themselves (via middleware).
    var response = await executeCommand(
      Command(
        title: command.title,
        command: Commands.validateRefactor,
        arguments: command.arguments,
      ),
      decoder: ValidateRefactorResult.fromJson,
    );

    expect(response.valid, isFalse);
    expect(
      response.message,
      contains('Cannot extract the closure as a method'),
    );
  }

  /// Test if the client does not call refactor.validate it still gets a
  /// sensible `showMessage` call and not a failed request.
  Future<void> test_validLocation_failsInitialValidation_noValidation() async {
    const content = '''
f() {
  var a = 0;
  doFoo([!() => print(a)!]);
  print(a);
}

void doFoo(void Function() a) => a();
''';

    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
    var command = codeAction.command!;

    // Call the refactor without any validation and expected an error message
    // without a request failure.
    var errorNotification = await expectErrorNotification(() async {
      var response = await executeCommand(
        Command(
          title: command.title,
          command: command.command,
          arguments: command.arguments,
        ),
      );
      expect(response, isNull);
    });
    expect(
      errorNotification.message,
      contains('Cannot extract the closure as a method'),
    );
  }

  Future<void> test_validLocation_passesInitialValidation() async {
    const content = '''
f() {
  doFoo([!() => print(1)!]);
}

void doFoo(void Function() a) => a();

''';

    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );
    var command = codeAction.command!;

    // Call the `Commands.validateRefactor` command with the same arguments.
    // Clients that want validation behaviour will need to implement this
    // themselves (via middleware).
    var response = await executeCommand(
      Command(
        title: command.title,
        command: Commands.validateRefactor,
        arguments: command.arguments,
      ),
      decoder: ValidateRefactorResult.fromJson,
    );

    expect(response.valid, isTrue);
    expect(response.message, isNull);
  }
}

@reflectiveTest
class ExtractVariableRefactorCodeActionsTest extends RefactorCodeActionsTest {
  final convertMethodToGetterTitle = 'Convert Method to Getter';
  final extractVariableTitle = 'Extract Local Variable';
  final inlineMethodTitle = 'Inline Method';

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
void f() {
  foo([!1 + 2!]);
}

void foo(int arg) {}
''';
    const expectedContent = '''
void f() {
  var arg = 1 + 2;
  foo(arg);
}

void foo(int arg) {}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractVariableTitle,
    );
  }

  Future<void> test_doesNotCreateNameConflicts() async {
    const content = '''
void f() {
  var arg = "test";
  foo([!1 + 2!]);
}

void foo(int arg) {}
''';
    const expectedContent = '''
void f() {
  var arg = "test";
  var arg2 = 1 + 2;
  foo(arg2);
}

void foo(int arg) {}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractVariableTitle,
    );
  }

  Future<void> test_inlineMethod_function_startOfParameterList() async {
    const content = '''
test^(a, b) {
  print(a);
  print(b);
}
void f() {
  test(1, 2);
}
''';
    const expectedContent = '''
void f() {
  print(1);
  print(2);
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }

  Future<void> test_inlineMethod_function_startOfTypeParameterList() async {
    const content = '''
test^<T>(T a, T b) {
  print(a);
  print(b);
}
void f() {
  test(1, 2);
}
''';
    const expectedContent = '''
void f() {
  print(1);
  print(2);
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }

  Future<void> test_inlineMethod_method_startOfParameterList() async {
    const content = '''
class A {
  test^(a, b) {
    print(a);
    print(b);
  }
  void f() {
    test(1, 2);
  }
}
''';
    const expectedContent = '''
class A {
  void f() {
    print(1);
    print(2);
  }
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }

  Future<void> test_inlineMethod_method_startOfTypeParameterList() async {
    const content = '''
class A {
  test^<T>(T a, T b) {
    print(a);
    print(b);
  }
  void f() {
    test(1, 2);
  }
}
''';
    const expectedContent = '''
class A {
  void f() {
    print(1);
    print(2);
  }
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }

  Future<void> test_macroGenerated() async {
    setDartTextDocumentContentProviderSupport();
    var macroFilePath = join(projectFolderPath, 'lib', 'test.macro.dart');
    var content = '''
int f(int a, int b) {
  return [!a + b!];
}
''';
    await expectNoAction(
      content,
      command: Commands.performRefactor,
      filePath: macroFilePath,
      title: extractVariableTitle,
    );
  }

  Future<void> test_methodToGetter_function_startOfParameterList() async {
    const content = '''
int test^() => 42;
''';
    const expectedContent = '''
int get test => 42;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: convertMethodToGetterTitle,
    );
  }

  Future<void> test_methodToGetter_function_startOfTypeParameterList() async {
    const content = '''
int test^<T>() => 42;
''';
    const expectedContent = '''
int get test<T> => 42;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: convertMethodToGetterTitle,
    );
  }

  Future<void> test_methodToGetter_method_startOfParameterList() async {
    const content = '''
class A {
  int test^() => 42;
}
''';
    const expectedContent = '''
class A {
  int get test => 42;
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: convertMethodToGetterTitle,
    );
  }

  Future<void> test_methodToGetter_method_startOfTypeParameterList() async {
    const content = '''
class A {
  int test^<T>() => 42;
}
''';
    const expectedContent = '''
class A {
  int get test<T> => 42;
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: convertMethodToGetterTitle,
    );
  }
}

@reflectiveTest
class ExtractWidgetRefactorCodeActionsTest extends RefactorCodeActionsTest {
  final extractWidgetTitle = 'Extract Widget';

  String get expectedNewWidgetConstructorDeclaration => '''
const NewWidget({
    super.key,
  });
''';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);

    setDocumentChangesSupport();
  }

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new [!Column!](
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
    var expectedContent = '''
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
  $expectedNewWidgetConstructorDeclaration
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

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractWidgetTitle,
    );
  }

  Future<void> test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
void f() {}
''';

    await expectNoAction(
      content,
      command: Commands.performRefactor,
      title: extractWidgetTitle,
    );
  }
}

@reflectiveTest
class InlineLocalVariableRefactorCodeActionsTest
    extends RefactorCodeActionsTest {
  final inlineVariableTitle = 'Inline Local Variable';

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
void f() {
  var a^ = 1;
  print(a);
  print(a);
  print(a);
}
''';
    const expectedContent = '''
void f() {
  print(1);
  print(1);
  print(1);
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineVariableTitle,
    );
  }
}

@reflectiveTest
class InlineMethodRefactorCodeActionsTest extends RefactorCodeActionsTest {
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

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
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

    await verifyActionEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }
}

abstract class RefactorCodeActionsTest extends AbstractCodeActionsTest {
  @override
  void setUp() {
    super.setUp();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);
  }
}
