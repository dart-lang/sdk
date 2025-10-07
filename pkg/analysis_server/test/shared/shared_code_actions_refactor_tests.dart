// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/perform_refactor.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../lsp/code_actions_mixin.dart';
import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

mixin SharedConvertGetterToMethodRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
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

    await verifyCodeActionLiteralEdits(
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

mixin SharedConvertMethodToGetterRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspReverseRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: refactorTitle,
    );
  }
}

mixin SharedExtractMethodRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspReverseRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin,
        LspProgressNotificationsMixin {
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
    await verifyCodeActionLiteralEdits(
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
>>>>>>>>>> lib/test.dart
void f() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
''';

    var codeAction = await expectCodeActionLiteral(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );

    // Respond to any applyEdit requests from the server with successful responses
    // and capturing the last edit.
    late WorkspaceEdit edit;
    requestsFromServer.listen((request) {
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
      throwsA(
        isResponseError(
          ErrorCodes.RequestCancelled,
          message:
              'Another workspace/executeCommand request for a refactor was started',
        ),
      ),
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

    var codeAction = await expectCodeActionLiteral(
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
      var req2 = replaceFile(100, testFileUri, '// new test content');
      completer.complete();

      // Expect the first to fail because of the modified content.
      await expectLater(
        req1,
        throwsA(isResponseError(ErrorCodes.ContentModified)),
      );
      await req2;
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
    createFile(testFilePath, code.code);
    await initializeServer();

    ofKind(CodeActionKind kind) =>
        getCodeActions(testFileUri, range: code.range.range, kinds: [kind]);

    // The code above will return a 'refactor.extract' (as well as some other
    // refactors, but not rewrite).
    expect(await ofKind(CodeActionKind.Refactor), isNotEmpty);
    expect(await ofKind(CodeActionKind.RefactorExtract), isNotEmpty);
    expect(await ofKind(CodeActionKind('refactor.extract.foo')), isEmpty);
    expect(await ofKind(CodeActionKind.RefactorRewrite), isEmpty);
  }

  Future<void> test_generatesNames() async {
    const content = '''
Object? F() {
  return Container([!Text('Test!')!]);
}

Object? Container(Object? text) => null;
Object? Text(Object? text) => null;
''';
    const expectedContent = '''
Object? F() {
  return Container(text());
}

Object? text() => Text('Test!');

Object? Container(Object? text) => null;
Object? Text(Object? text) => null;
''';

    await verifyCodeActionLiteralEdits(
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

i^o.File? a;
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
    var action = await expectCodeActionLiteral(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );

    await executeCommandForEdits(action.command!);
    expectCommandLogged('dart.refactor.extract_method');
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
    var codeAction = await expectCodeActionLiteral(
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

  Future<void> test_validLocation_passesInitialValidation() async {
    const content = '''
f() {
  doFoo([!() => print(1)!]);
}

void doFoo(void Function() a) => a();

''';

    var codeAction = await expectCodeActionLiteral(
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

mixin SharedExtractVariableRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }

  Future<void> test_methodToGetter_function_startOfParameterList() async {
    const content = '''
int test^() => 42;
''';
    const expectedContent = '''
int get test => 42;
''';

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: convertMethodToGetterTitle,
    );
  }
}

mixin SharedExtractWidgetRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  final extractWidgetTitle = 'Extract Widget';

  String get expectedNewWidgetConstructorDeclaration => '''
const NewWidget({
    super.key,
  });
''';

  @override
  Future<void> setUp() async {
    await super.setUp();
    writeTestPackageConfig(flutter: true);
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
    var expectedContent =
        '''
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractWidgetTitle,
      openTargetFile: true,
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

mixin SharedInlineLocalVariableRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineVariableTitle,
      openTargetFile: true,
    );
  }
}

mixin SharedInlineMethodRefactorCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: inlineMethodTitle,
    );
  }
}
