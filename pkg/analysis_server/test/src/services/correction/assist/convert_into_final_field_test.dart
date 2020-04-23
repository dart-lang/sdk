// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoFinalFieldTest);
  });
}

@reflectiveTest
class ConvertIntoFinalFieldTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_FINAL_FIELD;

  Future<void> test_blockBody_onlyReturnStatement() async {
    await resolveTestUnit('''
class A {
  int get foo {
    return 1 + 2;
  }
}
''');
    await assertHasAssistAt('get foo', '''
class A {
  final int foo = 1 + 2;
}
''');
  }

  Future<void> test_hasOverride() async {
    await resolveTestUnit('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  int get foo => 42;
}
''');
    await assertHasAssistAt('get foo', '''
const myAnnotation = const Object();
class A {
  @myAnnotation
  final int foo = 42;
}
''');
  }

  Future<void> test_hasSetter_inSuper() async {
    await resolveTestUnit('''
class A {
  void set foo(_) {}
}
class B extends A {
  int get foo => null;
}
''');
    await assertHasAssistAt('get foo', '''
class A {
  void set foo(_) {}
}
class B extends A {
  final int foo;
}
''');
  }

  Future<void> test_hasSetter_inThisClass() async {
    await resolveTestUnit('''
class A {
  int get foo => null;
  void set foo(_) {}
}
''');
    await assertNoAssistAt('get foo');
  }

  Future<void> test_noReturnType() async {
    await resolveTestUnit('''
class A {
  get foo => 42;
}
''');
    await assertHasAssistAt('get foo', '''
class A {
  final foo = 42;
}
''');
  }

  Future<void> test_noReturnType_static() async {
    await resolveTestUnit('''
class A {
  static get foo => 42;
}
''');
    await assertHasAssistAt('get foo', '''
class A {
  static final foo = 42;
}
''');
  }

  Future<void> test_notExpressionBody() async {
    await resolveTestUnit('''
class A {
  int get foo {
    int v = 1 + 2;
    return v + 3;
  }
}
''');
    await assertNoAssistAt('get foo');
  }

  Future<void> test_notGetter() async {
    await resolveTestUnit('''
class A {
  int foo() => 42;
}
''');
    await assertNoAssistAt('foo');
  }

  Future<void> test_notNull() async {
    await resolveTestUnit('''
class A {
  int get foo => 1 + 2;
}
''');
    await assertHasAssistAt('get foo', '''
class A {
  final int foo = 1 + 2;
}
''');
  }

  Future<void> test_null() async {
    await resolveTestUnit('''
class A {
  int get foo => null;
}
''');
    await assertHasAssistAt('get foo', '''
class A {
  final int foo;
}
''');
  }

  Future<void> test_onName() async {
    await resolveTestUnit('''
class A {
  int get foo => 42;
}
''');
    await assertHasAssistAt('foo', '''
class A {
  final int foo = 42;
}
''');
  }

  Future<void> test_onReturnType_parameterized() async {
    await resolveTestUnit('''
class A {
  List<int> get foo => null;
}
''');
    await assertHasAssistAt('nt> get', '''
class A {
  final List<int> foo;
}
''');
  }

  Future<void> test_onReturnType_simple() async {
    await resolveTestUnit('''
class A {
  int get foo => 42;
}
''');
    await assertHasAssistAt('int get', '''
class A {
  final int foo = 42;
}
''');
  }
}
