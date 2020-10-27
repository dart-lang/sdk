// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddNotNullAssertTest);
  });
}

@reflectiveTest
class AddNotNullAssertTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ADD_NOT_NULL_ASSERT;

  Future<void> test_function_expressionBody_noAssert() async {
    await resolveTestCode('''
int double(int x) => x * 2;
''');
    // todo (pq): support expression bodies.
    await assertNoAssistAt('x');
  }

  Future<void> test_function_noAssert() async {
    await resolveTestCode('''
foo(int x) {
}
''');
    await assertHasAssistAt('x', '''
foo(int x) {
  assert(x != null);
}
''');
  }

  Future<void> test_function_withAssert() async {
    await resolveTestCode('''
foo(int x) {
  assert(x != null);
}
''');
    await assertNoAssistAt('x');
  }

  Future<void> test_function_withAssert2() async {
    await resolveTestCode('''
foo(int x) {
  print('foo');
  assert(x != null);
}
''');
    await assertNoAssistAt('x');
  }

  Future<void> test_method_noAssert() async {
    await resolveTestCode('''
class A {
  foo(int x) {
  }
}''');
    await assertHasAssistAt('x', '''
class A {
  foo(int x) {
    assert(x != null);
  }
}''');
  }
}
