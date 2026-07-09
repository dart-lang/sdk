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
  AssistKind get kind => DartAssistKind.convertIntoFinalField;

  Future<void> test_blockBody_onlyReturnStatement() async {
    await resolveTestCode('''
class A {
  int ^get foo {
    return 1 + 2;
  }
}
''');
    await assertHasAssist('''
class A {
  final int foo = 1 + 2;
}
''');
  }

  Future<void> test_extension_instance() async {
    await resolveTestCode('''
extension E on int {
  int ^get foo => 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_extension_static() async {
    await resolveTestCode('''
extension E on int {
  static int ^get foo => 0;
}
''');
    await assertHasAssist('''
extension E on int {
  static final int foo = 0;
}
''');
  }

  Future<void> test_extensionType_instance() async {
    await resolveTestCode('''
extension type E(int v) {
  int ^get foo => 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_extensionType_static() async {
    await resolveTestCode('''
extension type E(int v) {
  static int ^get foo => 0;
}
''');
    await assertHasAssist('''
extension type E(int v) {
  static final int foo = 0;
}
''');
  }

  Future<void> test_hasOverride() async {
    await resolveTestCode('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  int ^get foo => 42;
}
''');
    await assertHasAssist('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  final int foo = 42;
}
''');
  }

  Future<void> test_hasSetter_inSuper() async {
    await resolveTestCode('''
class A {
  void set foo(_) {}
}
class B extends A {
  int ^get foo => 3;
}
''');
    await assertHasAssist('''
class A {
  void set foo(_) {}
}
class B extends A {
  final int foo = 3;
}
''');
  }

  Future<void> test_hasSetter_inThisClass() async {
    await resolveTestCode('''
class A {
  int ^get foo => 0;
  void set foo(_) {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_noReturnType() async {
    await resolveTestCode('''
class A {
  ^get foo => 42;
}
''');
    await assertHasAssist('''
class A {
  final foo = 42;
}
''');
  }

  Future<void> test_noReturnType_static() async {
    await resolveTestCode('''
class A {
  static ^get foo => 42;
}
''');
    await assertHasAssist('''
class A {
  static final foo = 42;
}
''');
  }

  Future<void> test_notExpressionBody() async {
    await resolveTestCode('''
class A {
  int ^get foo {
    int v = 1 + 2;
    return v + 3;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_notGetter() async {
    await resolveTestCode('''
class A {
  int ^foo() => 42;
}
''');
    await assertNoAssist();
  }

  Future<void> test_notNull() async {
    await resolveTestCode('''
class A {
  int ^get foo => 1 + 2;
}
''');
    await assertHasAssist('''
class A {
  final int foo = 1 + 2;
}
''');
  }

  Future<void> test_null() async {
    await resolveTestCode('''
class A {
  int? ^get foo => null;
}
''');
    await assertHasAssist('''
class A {
  final int? foo;
}
''');
  }

  Future<void> test_onName() async {
    await resolveTestCode('''
class A {
  int get ^foo => 42;
}
''');
    await assertHasAssist('''
class A {
  final int foo = 42;
}
''');
  }

  Future<void> test_onReturnType_parameterized() async {
    await resolveTestCode('''
class A {
  List<i^nt>? get foo => null;
}
''');
    await assertHasAssist('''
class A {
  final List<int>? foo;
}
''');
  }

  Future<void> test_onReturnType_simple() async {
    await resolveTestCode('''
class A {
  ^int get foo => 42;
}
''');
    await assertHasAssist('''
class A {
  final int foo = 42;
}
''');
  }
}
