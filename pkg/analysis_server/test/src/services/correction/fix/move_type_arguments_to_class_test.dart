// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveTypeArgumentsToClassTest);
  });
}

@reflectiveTest
class MoveTypeArgumentsToClassTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.moveTypeArgumentsToClass;

  Future<void> test_explicitConst() async {
    await resolveTestCode('''
void f() {
  const C.named<int>();
}
class C<E> {
  const C.named();
}
''');
    await assertHasFix('''
void f() {
  const C<int>.named();
}
class C<E> {
  const C.named();
}
''');
  }

  Future<void> test_explicitNew() async {
    await resolveTestCode('''
void f() {
  new C.named<int>();
}
class C<E> {
  C.named();
}
''');
    await assertHasFix('''
void f() {
  new C<int>.named();
}
class C<E> {
  C.named();
}
''');
  }

  Future<void> test_explicitNew_alreadyThere() async {
    await resolveTestCode('''
void f() {
  new C<String>.named<int>();
}
class C<E> {
  C.named();
}
''');
    await assertNoFix();
  }

  Future<void> test_explicitNew_wrongNumber() async {
    await resolveTestCode('''
void f() {
  new C.named<int, String>();
}
class C<E> {
  C.named();
}
''');
    await assertNoFix();
  }

  Future<void> test_implicitConst() async {
    await resolveTestCode('''
void f() {
  const C c = C.named<int>();
  print(c);
}
class C<E> {
  const C.named();
}
''');
    await assertHasFix('''
void f() {
  const C c = C<int>.named();
  print(c);
}
class C<E> {
  const C.named();
}
''');
  }

  Future<void> test_implicitNew() async {
    await resolveTestCode('''
void f() {
  C.named<int>();
}
class C<E> {
  C.named();
}
''');
    await assertHasFix('''
void f() {
  C<int>.named();
}
class C<E> {
  C.named();
}
''');
  }
}
