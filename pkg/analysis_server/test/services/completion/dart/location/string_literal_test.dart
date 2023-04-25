// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringLiteralTest1);
    defineReflectiveTests(StringLiteralTest2);
  });
}

@reflectiveTest
class StringLiteralTest1 extends AbstractCompletionDriverTest
    with StringLiteralTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class StringLiteralTest2 extends AbstractCompletionDriverTest
    with StringLiteralTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin StringLiteralTestCases on AbstractCompletionDriverTest {
  Future<void> test_inArgumentList_named() async {
    await computeSuggestions('''
void f() {foo(bar: "^");}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_inArgumentList_positional() async {
    await computeSuggestions('''
void f() {foo("^");}
''');
    assertResponse(r'''
suggestions
''');
  }
}
