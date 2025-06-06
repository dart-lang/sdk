// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_fixes_tests.dart';
import 'abstract_code_actions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CodeActionFixesTest);
  });
}

@reflectiveTest
class CodeActionFixesTest extends AbstractCodeActionsTest
    with
        // Tests are defined in a shared mixin.
        SharedFixesCodeActionsTests {}
