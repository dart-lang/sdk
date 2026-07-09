// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTypeNameTest);
  });
}

@reflectiveTest
class AddTypeNameTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.addTypeName;

  Future<void> test_dotShorthandConstructorInvocation() async {
    await resolveTestCode('''
class C {
  C.m();
}

void foo(C c) => foo(.^m());
''');
    await assertHasAssist('''
class C {
  C.m();
}

void foo(C c) => foo(C.m());
''');
  }

  Future<void> test_dotShorthandInvocation() async {
    await resolveTestCode('''
class C {
  static C m() => C();
}

void foo(C c) => foo(.^m());
''');
    await assertHasAssist('''
class C {
  static C m() => C();
}

void foo(C c) => foo(C.m());
''');
  }

  Future<void> test_dotShorthandPropertyAccess() async {
    await resolveTestCode('''
enum E {a}

void foo(E e) => foo(.^a);
''');
    await assertHasAssist('''
enum E {a}

void foo(E e) => foo(E.a);
''');
  }

  Future<void> test_functionType() async {
    await resolveTestCode('''
// ignore: dot_shorthand_undefined_member
void f(int Function(int) g) => f(.^m());
''');
    await assertNoAssist();
  }

  Future<void> test_record() async {
    await resolveTestCode('''
// ignore: dot_shorthand_undefined_member
void f((int,) g) => f(.^m());
''');
    await assertNoAssist();
  }

  Future<void> test_typeParameter() async {
    await resolveTestCode('''
class C {}
// ignore: dot_shorthand_undefined_member
void f<T extends C>(T g) => f(.^m());
''');
    await assertNoAssist();
  }

  Future<void> test_withTypeParameter() async {
    await resolveTestCode('''
class C<T> {
  new m();
}
void f(C<int> c) => f(.^m());
''');
    await assertHasAssist('''
class C<T> {
  new m();
}
void f(C<int> c) => f(C.m());
''');
  }
}
