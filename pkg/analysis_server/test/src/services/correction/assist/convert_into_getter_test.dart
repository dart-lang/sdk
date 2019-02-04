// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoGetterTest);
  });
}

@reflectiveTest
class ConvertIntoGetterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_GETTER;

  test_noInitializer() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
class A {
  final int foo;
}
''');
    await assertNoAssistAt('foo');
  }

  test_notFinal() async {
    await resolveTestUnit('''
class A {
  int foo = 1;
}
''');
    await assertNoAssistAt('foo');
  }

  test_notSingleField() async {
    await resolveTestUnit('''
class A {
  final int foo = 1, bar = 2;
}
''');
    await assertNoAssistAt('foo');
  }

  test_noType() async {
    await resolveTestUnit('''
class A {
  final foo = 42;
}
''');
    await assertHasAssistAt('foo =', '''
class A {
  get foo => 42;
}
''');
  }

  test_type() async {
    await resolveTestUnit('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  final int foo = 1 + 2;
}
''');
    await assertHasAssistAt('foo =', '''
const myAnnotation = const Object();
class A {
  @myAnnotation
  int get foo => 1 + 2;
}
''');
  }
}
