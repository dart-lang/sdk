// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_refactor_tests.dart';
import 'code_actions_mixin.dart';
import 'request_helpers_mixin.dart';
import 'server_abstract.dart';

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
class ConvertGetterToMethodCodeActionsTest extends RefactorCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedConvertGetterToMethodRefactorCodeActionsTests {}

@reflectiveTest
class ConvertMethodToGetterCodeActionsTest extends RefactorCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedConvertMethodToGetterRefactorCodeActionsTests {}

@reflectiveTest
class ExtractMethodRefactorCodeActionsTest extends RefactorCodeActionsTest
    with
        LspProgressNotificationsMixin,
        // Most tests are defined in a shared mixin.
        SharedExtractMethodRefactorCodeActionsTests {
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
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
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      command: Commands.performRefactor,
      title: extractMethodTitle,
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

    var codeAction = await expectCodeActionLiteral(
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
}

@reflectiveTest
class ExtractVariableRefactorCodeActionsTest extends RefactorCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedExtractVariableRefactorCodeActionsTests {}

@reflectiveTest
class ExtractWidgetRefactorCodeActionsTest extends RefactorCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedExtractWidgetRefactorCodeActionsTests {}

@reflectiveTest
class InlineLocalVariableRefactorCodeActionsTest extends RefactorCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedInlineLocalVariableRefactorCodeActionsTests {}

@reflectiveTest
class InlineMethodRefactorCodeActionsTest extends RefactorCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedInlineMethodRefactorCodeActionsTests {}

abstract class RefactorCodeActionsTest extends AbstractLspAnalysisServerTest
    with LspSharedTestMixin, CodeActionsTestMixin {
  @override
  void setUp() {
    super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);
  }
}
