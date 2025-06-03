// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../lsp/request_helpers_mixin.dart';
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
        LspProgressNotificationsMixin,
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

abstract class RefactorCodeActionsTest extends AbstractCodeActionsTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);
  }
}
