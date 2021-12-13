// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddNullCheckTest);
  });
}

@reflectiveTest
class AddNullCheckTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_NULL_CHECK;

  Future<void> test_argument() async {
    await resolveTestCode('''
void f(int x) {}
void g(int? y) {
  f(y);
}
''');
    await assertHasFix('''
void f(int x) {}
void g(int? y) {
  f(y!);
}
''');
  }

  Future<void> test_argument_differByMoreThanNullability() async {
    await resolveTestCode('''
void f(int x) {}
void g(String y) {
  f(y);
}
''');
    await assertNoFix();
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
void f(int x, int? y) {
  x = y;
}
''');
    await assertHasFix('''
void f(int x, int? y) {
  x = y!;
}
''');
  }

  Future<void>
      test_assignment_differByMoreThanNullability_nonNullableRight() async {
    await resolveTestCode('''
void f(int x, String y) {
  x = y;
}
''');
    await assertNoFix();
  }

  Future<void>
      test_assignment_differByMoreThanNullability_nullableRight() async {
    await resolveTestCode('''
void f(int x, String? y) {
  x = y;
}
''');
    await assertNoFix();
  }

  Future<void> test_assignment_needsParens() async {
    await resolveTestCode('''
void f(A x) {
  x = x + x;
}
class A {
  A? operator +(A a) => null;
}
''');
    await assertHasFix('''
void f(A x) {
  x = (x + x)!;
}
class A {
  A? operator +(A a) => null;
}
''');
  }

  Future<void> test_binaryOperator_leftSide() async {
    await resolveTestCode('''
f(int? i) => i + 1;
''');
    await assertHasFix('''
f(int? i) => i! + 1;
''');
  }

  Future<void> test_binaryOperator_rightSide() async {
    await resolveTestCode('''
f(int? i) => 1 + i;
''');
    await assertHasFix('''
f(int? i) => 1 + i!;
''');
  }

  Future<void> test_forEachWithDeclarationCondition() async {
    await resolveTestCode('''
void f (List<String>? args) {
  for (var e in args) print(e);
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  for (var e in args!) print(e);
}
''');
  }

  Future<void>
      test_forEachWithDeclarationCondition_differByMoreThanNullability() async {
    await resolveTestCode('''
void f (List<int>? args) {
  for (String e in args) print(e);
}
''');
    await assertNoFix();
  }

  Future<void> test_forEachWithIdentifierCondition() async {
    await resolveTestCode('''
void f (List<String>? args) {
  String s = "";
  for (s in args) print(s);
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  String s = "";
  for (s in args!) print(s);
}
''');
  }

  Future<void>
      test_forEachWithIdentifierCondition_differByMoreThanNullability() async {
    await resolveTestCode('''
void f (List<int>? args) {
  String s = "";
  for (s in args) print(s);
}
''');
    await assertNoFix();
  }

  Future<void> test_functionExpressionInvocation() async {
    await resolveTestCode('''
int f(C c) => c.func();
class C {
  int Function()? get func => null;
}
''');
    await assertHasFix('''
int f(C c) => c.func!();
class C {
  int Function()? get func => null;
}
''');
  }

  Future<void> test_indexExpression() async {
    await resolveTestCode('''
void f (List<String>? args) {
  print(args[0]);
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  print(args![0]);
}
''');
  }

  Future<void> test_initializer() async {
    await resolveTestCode('''
void f(int? x) {
  int y = x;
  print(y);
}
''');
    await assertHasFix('''
void f(int? x) {
  int y = x!;
  print(y);
}
''');
  }

  Future<void> test_initializer_assignable() async {
    await resolveTestCode('''
void f(int? x) {
  num y = x;
  print(y);
}
''');
    await assertHasFix('''
void f(int? x) {
  num y = x!;
  print(y);
}
''');
  }

  Future<void> test_initializer_differByMoreThanNullability() async {
    await resolveTestCode('''
void f(String x) {
  int y = x;
  print(y);
}
''');
    await assertNoFix();
  }

  Future<void> test_methodInvocation() async {
    await resolveTestCode('''
String f(String? s) => s.substring(0);
''');
    await assertHasFix('''
String f(String? s) => s!.substring(0);
''');
  }

  Future<void> test_postfixOperator() async {
    await resolveTestCode('''
f(int? i) => i++;
''');
    await assertNoFix();
  }

  Future<void> test_prefixedIdentifier() async {
    await resolveTestCode('''
int f(String? s) => s.length;
''');
    await assertHasFix('''
int f(String? s) => s!.length;
''');
  }

  Future<void> test_prefixOperator() async {
    await resolveTestCode('''
f(int? i) => -i;
''');
    await assertHasFix('''
f(int? i) => -i!;
''');
  }

  Future<void> test_propertyAccess() async {
    await resolveTestCode('''
int f(String? s) => (s).length;
''');
    await assertHasFix('''
int f(String? s) => (s)!.length;
''');
  }

  Future<void> test_propertyAccess_cascade() async {
    await resolveTestCode('''
String? f(String? s) => s..length;
''');
    await assertHasFix('''
String? f(String? s) => s!..length;
''');
  }

  Future<void> test_propertyAccess_cascadeAfterNullProperty() async {
    await resolveTestCode('''
String? f(String? s) => s..hashCode..length;
''');
    await assertHasFix('''
String? f(String? s) => s!..hashCode..length;
''');
  }

  Future<void> test_spreadList() async {
    await resolveTestCode('''
void f (List<String>? args) {
  [...args];
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  [...args!];
}
''');
  }

  Future<void> test_spreadList_differByMoreThanNullability() async {
    await resolveTestCode('''
void f (List<int>? args) {
  <String>[...args];
}
''');
    await assertNoFix(
        errorFilter: (AnalysisError error) =>
            error.errorCode !=
            CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE);
  }

  Future<void> test_spreadMap() async {
    await resolveTestCode('''
void f (Map<int, String>? args) {
  print({...args});
}
''');
    await assertHasFix('''
void f (Map<int, String>? args) {
  print({...args!});
}
''');
  }

  Future<void> test_spreadSet() async {
    await resolveTestCode('''
void f (List<String>? args) {
  print({...args});
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  print({...args!});
}
''');
  }

  Future<void> test_yieldEach_closure() async {
    await resolveTestCode('''
g(Iterable<String> Function() cb) {}
f(List<String>? args) {
  g(() sync* {
    yield* args;
  });
}
''');
    await assertHasFix('''
g(Iterable<String> Function() cb) {}
f(List<String>? args) {
  g(() sync* {
    yield* args!;
  });
}
''',
        errorFilter: (AnalysisError error) =>
            error.errorCode != CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE);
  }

  Future<void> test_yieldEach_localFunction() async {
    await resolveTestCode('''
g() {
  Iterable<String> f(List<String>? args) sync* {
    yield* args;
  }
}
''');
    await assertHasFix('''
g() {
  Iterable<String> f(List<String>? args) sync* {
    yield* args!;
  }
}
''',
        errorFilter: (AnalysisError error) =>
            error.errorCode ==
            CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH);
  }

  Future<void> test_yieldEach_method() async {
    await resolveTestCode('''
class C {
  Iterable<String> f(List<String>? args) sync* {
    yield* args;
  }
}
''');
    await assertHasFix('''
class C {
  Iterable<String> f(List<String>? args) sync* {
    yield* args!;
  }
}
''',
        errorFilter: (AnalysisError error) =>
            error.errorCode != CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE);
  }

  Future<void> test_yieldEach_topLevel() async {
    await resolveTestCode('''
Iterable<String> f(List<String>? args) sync* {
  yield* args;
}
''');
    await assertHasFix('''
Iterable<String> f(List<String>? args) sync* {
  yield* args!;
}
''',
        errorFilter: (AnalysisError error) =>
            error.errorCode != CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE);
  }
}
