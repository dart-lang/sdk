// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddExplicitCastTest);
  });
}

@reflectiveTest
class AddExplicitCastTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_EXPLICIT_CAST;

  Future<void> test_as() async {
    await resolveTestUnit('''
f(A a) {
  C c = a as B;
  print(c);
}
class A {}
class B {}
class C {}
''');
    await assertNoFix();
  }

  Future<void> test_assignment_general() async {
    await resolveTestUnit('''
f(A a) {
  B b;
  b = a;
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(A a) {
  B b;
  b = a as B;
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_general_all() async {
    await resolveTestUnit('''
f(A a) {
  B b, b2;
  b = a;
  b2 = a;
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(A a) {
  B b, b2;
  b = a as B;
  b2 = a as B;
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_list() async {
    await resolveTestUnit('''
f(List<A> a) {
  List<B> b;
  b = a.where((e) => e is B).toList();
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(List<A> a) {
  List<B> b;
  b = a.where((e) => e is B).cast<B>().toList();
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_list_all() async {
    await resolveTestUnit('''
f(List<A> a) {
  List<B> b, b2;
  b = a.where((e) => e is B).toList();
  b2 = a.where((e) => e is B).toList();
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(List<A> a) {
  List<B> b, b2;
  b = a.where((e) => e is B).cast<B>().toList();
  b2 = a.where((e) => e is B).cast<B>().toList();
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_map() async {
    await resolveTestUnit('''
f(Map<A, B> a) {
  Map<B, A> b;
  b = a;
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(Map<A, B> a) {
  Map<B, A> b;
  b = a.cast<B, A>();
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_map_all() async {
    await resolveTestUnit('''
f(Map<A, B> a) {
  Map<B, A> b, b2;
  b = a;
  b2 = a;
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(Map<A, B> a) {
  Map<B, A> b, b2;
  b = a.cast<B, A>();
  b2 = a.cast<B, A>();
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_needsParens() async {
    await resolveTestUnit('''
f(A a) {
  B b;
  b = a..m();
  print(b);
}
class A {
  int m() => 0;
}
class B {}
''');
    await assertHasFix('''
f(A a) {
  B b;
  b = (a..m()) as B;
  print(b);
}
class A {
  int m() => 0;
}
class B {}
''');
  }

  Future<void> test_assignment_needsParens_all() async {
    await resolveTestUnit('''
f(A a) {
  B b, b2;
  b = a..m();
  b2 = a..m();
}
class A {
  int m() => 0;
}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(A a) {
  B b, b2;
  b = (a..m()) as B;
  b2 = (a..m()) as B;
}
class A {
  int m() => 0;
}
class B {}
''');
  }

  Future<void> test_assignment_set() async {
    await resolveTestUnit('''
f(Set<A> a) {
  Set<B> b;
  b = a;
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(Set<A> a) {
  Set<B> b;
  b = a.cast<B>();
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_assignment_set_all() async {
    await resolveTestUnit('''
f(Set<A> a) {
  Set<B> b, b2;
  b = a;
  b2 = a;
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(Set<A> a) {
  Set<B> b, b2;
  b = a.cast<B>();
  b2 = a.cast<B>();
}
class A {}
class B {}
''');
  }

  Future<void> test_cast() async {
    await resolveTestUnit('''
f(List<A> a) {
  List<B> b = a.cast<A>();
  print(b);
}
class A {}
class B {}
''');
    await assertNoFix();
  }

  Future<void> test_declaration_general() async {
    await resolveTestUnit('''
f(A a) {
  B b = a;
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(A a) {
  B b = a as B;
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_general_all() async {
    await resolveTestUnit('''
f(A a) {
  B b = a;
  B b2 = a;
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(A a) {
  B b = a as B;
  B b2 = a as B;
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_list() async {
    await resolveTestUnit('''
f(List<A> a) {
  List<B> b = a.where((e) => e is B).toList();
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(List<A> a) {
  List<B> b = a.where((e) => e is B).cast<B>().toList();
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_list_all() async {
    await resolveTestUnit('''
f(List<A> a) {
  List<B> b = a.where((e) => e is B).toList();
  List<B> b2 = a.where((e) => e is B).toList();
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(List<A> a) {
  List<B> b = a.where((e) => e is B).cast<B>().toList();
  List<B> b2 = a.where((e) => e is B).cast<B>().toList();
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_map() async {
    await resolveTestUnit('''
f(Map<A, B> a) {
  Map<B, A> b = a;
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(Map<A, B> a) {
  Map<B, A> b = a.cast<B, A>();
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_map_all() async {
    await resolveTestUnit('''
f(Map<A, B> a) {
  Map<B, A> b = a;
  Map<B, A> b2 = a;
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(Map<A, B> a) {
  Map<B, A> b = a.cast<B, A>();
  Map<B, A> b2 = a.cast<B, A>();
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_needsParens() async {
    await resolveTestUnit('''
f(A a) {
  B b = a..m();
  print(b);
}
class A {
  int m() => 0;
}
class B {}
''');
    await assertHasFix('''
f(A a) {
  B b = (a..m()) as B;
  print(b);
}
class A {
  int m() => 0;
}
class B {}
''');
  }

  Future<void> test_declaration_needsParens_all() async {
    await resolveTestUnit('''
f(A a) {
  B b = a..m();
  B b2 = a..m();
}
class A {
  int m() => 0;
}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(A a) {
  B b = (a..m()) as B;
  B b2 = (a..m()) as B;
}
class A {
  int m() => 0;
}
class B {}
''');
  }

  Future<void> test_declaration_set() async {
    await resolveTestUnit('''
f(Set<A> a) {
  Set<B> b = a;
  print(b);
}
class A {}
class B {}
''');
    await assertHasFix('''
f(Set<A> a) {
  Set<B> b = a.cast<B>();
  print(b);
}
class A {}
class B {}
''');
  }

  Future<void> test_declaration_set_all() async {
    await resolveTestUnit('''
f(Set<A> a) {
  Set<B> b = a;
  Set<B> b2 = a;
}
class A {}
class B {}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.INVALID_ASSIGNMENT, '''
f(Set<A> a) {
  Set<B> b = a.cast<B>();
  Set<B> b2 = a.cast<B>();
}
class A {}
class B {}
''');
  }

  Future<void> test_notExpression_incomplete() async {
    await resolveTestUnit(r'''
void foo(int a) {
  a = a < ;
}
''');
    await assertNoFix(
      errorFilter: (e) {
        return e.errorCode == StaticTypeWarningCode.INVALID_ASSIGNMENT;
      },
    );
  }
}
