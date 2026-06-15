// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide MessageType, MessageActionItem;
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_refactor_tests.dart';
import 'abstract_code_actions.dart';

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
        // Tests are defined in a shared mixin.
        SharedExtractMethodRefactorCodeActionsTests {}

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

abstract class RefactorCodeActionsTest extends AbstractCodeActionsTest
    with SharedRefactorCodeActionsTests {
  @override
  Future<T> handleRefactorAnywayPrompt<T>(
    Future<T> Function() f, {
    required String expectedMessage,
    required List<String> expectedActions,
    String? selectAction,
  }) async {
    var subscription = serverChannel.serverToClientRequests
        .where((request) => request.method == serverRequestShowMessageRequest)
        .listen((request) {
          var params = ServerShowMessageRequestParams.fromRequest(
            request,
            clientUriConverter: uriConverter,
          );
          // Ensure the warning prompt is as expected.
          expect(params.type, equals(MessageType.WARNING));
          expect(params.message, equals(expectedMessage));
          expect(params.actions, hasLength(2));
          expect(
            params.actions[0],
            equals(MessageAction(UserPromptActions.refactorAnyway)),
          );
          expect(
            params.actions[1],
            equals(MessageAction(UserPromptActions.cancel)),
          );

          // Respond to the request with the required action.
          server.handleResponse(
            Response(request.id, result: {'action': selectAction}),
          );
        });
    var result = await f();
    await subscription.cancel();
    return result;
  }

  @override
  Future<void> setUp() async {
    await super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);
  }
}
