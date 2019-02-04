// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFunctionTest);
  });
}

@reflectiveTest
class CreateFunctionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FUNCTION;

  assert_returnType_bool(String lineWithTest) async {
    await resolveTestUnit('''
main() {
  bool b = true;
  $lineWithTest
  print(b);
}
''');
    await assertHasFix('''
main() {
  bool b = true;
  $lineWithTest
  print(b);
}

bool test() {
}
''');
  }

  test_bottomArgument() async {
    await resolveTestUnit('''
main() {
  test(throw 42);
}
''');
    await assertHasFix('''
main() {
  test(throw 42);
}

void test(param0) {
}
''');
  }

  test_duplicateArgumentNames() async {
    await resolveTestUnit('''
class C {
  int x;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}
''');
    await assertHasFix('''
class C {
  int x;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}

void bar(int x, int x2) {
}
''');
  }

  test_dynamicArgument() async {
    await resolveTestUnit('''
main() {
  dynamic v;
  test(v);
}
''');
    await assertHasFix('''
main() {
  dynamic v;
  test(v);
}

void test(v) {
}
''');
  }

  test_dynamicReturnType() async {
    await resolveTestUnit('''
main() {
  dynamic v = test();
  print(v);
}
''');
    await assertHasFix('''
main() {
  dynamic v = test();
  print(v);
}

test() {
}
''');
  }

  test_fromFunction() async {
    await resolveTestUnit('''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
}
''');
    await assertHasFix('''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  test_fromMethod() async {
    await resolveTestUnit('''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
    print(v);
  }
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  test_functionType_cascadeSecond() async {
    await resolveTestUnit('''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}
''');
    await assertHasFix('''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}

int test(double a, String b) {
}
''');
  }

  test_functionType_coreFunction() async {
    await resolveTestUnit('''
main() {
  useFunction(g: test);
}
useFunction({Function g}) {}
''');
    await assertHasFix('''
main() {
  useFunction(g: test);
}
useFunction({Function g}) {}

test() {
}
''');
  }

  test_functionType_dynamicArgument() async {
    await resolveTestUnit('''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}
''');
    await assertHasFix('''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}

int test(a, b) {
}
''');
  }

  test_functionType_function() async {
    await resolveTestUnit('''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}

int test(double a, String b) {
}
''');
  }

  test_functionType_function_namedArgument() async {
    await resolveTestUnit('''
main() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)}) {}
''');
    await assertHasFix('''
main() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)}) {}

int test(double a, String b) {
}
''');
  }

  test_functionType_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
''');
    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

useFunction(int g(A a)) {}
''');
    await resolveTestUnit('''
import 'package:test/b.dart';

main() {
  useFunction(test);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  useFunction(test);
}

int test(A a) {
}
''');
  }

  test_functionType_notFunctionType() async {
    await resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
typedef A();
useFunction(g) {}
''');
    await assertNoFix();
  }

  test_generic_type() async {
    await resolveTestUnit('''
class A {
  List<int> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A {
  List<int> items;
  main() {
    process(items);
  }
}

void process(List<int> items) {
}
''');
    assertLinkedGroup(
        change.linkedEditGroups[2],
        ['List<int> items) {'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['List<int>', 'Iterable<int>', 'Object']));
  }

  test_generic_typeParameter() async {
    await resolveTestUnit('''
class A<T> {
  Map<int, T> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A<T> {
  Map<int, T> items;
  main() {
    process(items);
  }
}

void process(Map items) {
}
''');
  }

  test_importType() async {
    addSource('/home/test/lib/lib.dart', r'''
library lib;
import 'dart:async';
Future getFuture() => null;
''');
    await resolveTestUnit('''
import 'lib.dart';
main() {
  test(getFuture());
}
''');
    await assertHasFix('''
import 'lib.dart';
main() {
  test(getFuture());
}

void test(Future future) {
}
''');
  }

  test_nullArgument() async {
    await resolveTestUnit('''
main() {
  test(null);
}
''');
    await assertHasFix('''
main() {
  test(null);
}

void test(param0) {
}
''');
  }

  test_returnType_bool_and_left() async {
    await assert_returnType_bool("test() && b;");
  }

  test_returnType_bool_and_right() async {
    await assert_returnType_bool("b && test();");
  }

  test_returnType_bool_assert() async {
    await assert_returnType_bool("assert ( test() );");
  }

  test_returnType_bool_do() async {
    await assert_returnType_bool("do {} while ( test() );");
  }

  test_returnType_bool_if() async {
    await assert_returnType_bool("if ( test() ) {}");
  }

  test_returnType_bool_or_left() async {
    await assert_returnType_bool("test() || b;");
  }

  test_returnType_bool_or_right() async {
    await assert_returnType_bool("b || test();");
  }

  test_returnType_bool_unaryNegation() async {
    await assert_returnType_bool("!test();");
  }

  test_returnType_bool_while() async {
    await assert_returnType_bool("while ( test() ) {}");
  }

  test_returnType_fromAssignment_eq() async {
    await resolveTestUnit('''
main() {
  int v;
  v = myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
main() {
  int v;
  v = myUndefinedFunction();
  print(v);
}

int myUndefinedFunction() {
}
''');
  }

  test_returnType_fromAssignment_plusEq() async {
    await resolveTestUnit('''
main() {
  int v;
  v += myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
main() {
  int v;
  v += myUndefinedFunction();
  print(v);
}

num myUndefinedFunction() {
}
''');
  }

  test_returnType_fromBinary_right() async {
    await resolveTestUnit('''
main() {
  0 + myUndefinedFunction();
}
''');
    await assertHasFix('''
main() {
  0 + myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  test_returnType_fromInitializer() async {
    await resolveTestUnit('''
main() {
  int v = myUndefinedFunction();
  print(v);
}
''');
    await assertHasFix('''
main() {
  int v = myUndefinedFunction();
  print(v);
}

int myUndefinedFunction() {
}
''');
  }

  test_returnType_fromInvocationArgument() async {
    await resolveTestUnit('''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}
''');
    await assertHasFix('''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}

int myUndefinedFunction() {
}
''');
  }

  test_returnType_fromReturn() async {
    await resolveTestUnit('''
int main() {
  return myUndefinedFunction();
}
''');
    await assertHasFix('''
int main() {
  return myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  test_returnType_void() async {
    await resolveTestUnit('''
main() {
  myUndefinedFunction();
}
''');
    await assertHasFix('''
main() {
  myUndefinedFunction();
}

void myUndefinedFunction() {
}
''');
  }
}
