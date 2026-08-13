// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithVarTest);
  });
}

@reflectiveTest
class ReplaceWithVarTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.replaceWithVar;

  Future<void> test_for() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (^int i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
    await assertHasAssist('''
void f(List<int> list) {
  for (var i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_forEach() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (^int i in list) {
    print(i);
  }
}
''');
    await assertHasAssist('''
void f(List<int> list) {
  for (var i in list) {
    print(i);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_functionType() async {
    await resolveTestCode('''
enum E { a, b, c }
void f() {
  for (E Fun^ction() e in [() => .a]) {
    print(e);
  }
}
''');
    await assertHasAssist('''
enum E { a, b, c }
void f() {
  for (var e in <E Function()>[() => .a]) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_generic_nested() async {
    await resolveTestCode('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

void f() {
  for (^E e in [ff(ff(.b, .b), .b)]) {
    print(e);
  }
}
''');
    await assertHasAssist('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

void f() {
  for (var e in <E>[ff(ff(.b, .b), .b)]) {
    print(e);
  }
}
''');
  }

  Future<void>
  test_forEach_dotShorthands_generic_nested_explicitTypeArguments() async {
    await resolveTestCode('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

X fun<U, X>(U u, X x) => x;

void f() {
  for (^int e in [fun(ff<E>(.a, E.a), 2)]) {
    print(e);
  }
}
''');
    await assertHasAssist('''
enum E { a, b, c }

T ff<T>(T t, E e) => t;

X fun<U, X>(U u, X x) => x;

void f() {
  for (var e in [fun(ff<E>(.a, E.a), 2)]) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_list() async {
    await resolveTestCode('''
enum E { a }
void f() {
  for (^E e in [.a]) {
    print(e);
  }
}
''');
    await assertHasAssist('''
enum E { a }
void f() {
  for (var e in <E>[.a]) {
    print(e);
  }
}
''');
  }

  Future<void> test_forEach_dotShorthands_set() async {
    await resolveTestCode('''
enum E { a }
void f() {
  for (^E e in {.a}) {
    print(e);
  }
}
''');
    await assertHasAssist('''
enum E { a }
void f() {
  for (var e in <E>{.a}) {
    print(e);
  }
}
''');
  }

  Future<void> test_generic_instanceCreation_cascade_dotShorthand() async {
    await resolveTestCode('''
enum E { a }
Set f() {
  Se^t<E> s = { .a }..addAll([]);
  return s;
}
''');
    await assertHasAssist('''
enum E { a }
Set f() {
  var s = <E>{ .a }..addAll([]);
  return s;
}
''');
  }

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
C<int> f() {
  ^C<int> c = C<int>();
  return c;
}
class C<T> {}
''');
    await assertHasAssist('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_instanceCreation_withoutArguments() async {
    await resolveTestCode('''
C<int> f() {
  ^C<int> c = C();
  return c;
}
class C<T> {}
''');
    await assertHasAssist('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List f() {
  ^List<int> l = [];
  return l;
}
''');
    await assertHasAssist('''
List f() {
  var l = <int>[];
  return l;
}
''');
  }

  Future<void> test_generic_listLiteral_dotShorthand() async {
    await resolveTestCode('''
enum E { a, b }
List f() {
  Li^st<E> l = [.a, .b];
  return l;
}
''');
    await assertHasAssist('''
enum E { a, b }
List f() {
  var l = <E>[.a, .b];
  return l;
}
''');
  }

  Future<void> test_generic_mapLiteral() async {
    await resolveTestCode('''
Map f() {
  ^Map<String, int> m = {};
  return m;
}
''');
    await assertHasAssist('''
Map f() {
  var m = <String, int>{};
  return m;
}
''');
  }

  Future<void> test_generic_setLiteral() async {
    await resolveTestCode('''
Set f() {
  ^Set<int> s = {};
  return s;
}
''');
    await assertHasAssist('''
Set f() {
  var s = <int>{};
  return s;
}
''');
  }

  Future<void> test_generic_setLiteral_ambiguous() async {
    await resolveTestCode('''
Set f() {
  ^Set s = {};
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_moreGeneral() async {
    await resolveTestCode('''
num f() {
  ^num n = 0;
  return n;
}
''');
    await assertNoAssist();
  }

  Future<void> test_noInitializer() async {
    await resolveTestCode('''
String f() {
  ^String s;
  s = '';
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
String f() {
  ^var s = '';
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
String f() {
  ^String s = '';
  return s;
}
''');
    await assertHasAssist('''
String f() {
  var s = '';
  return s;
}
''');
  }

  Future<void> test_simple_dotShorthand_constructorInvocation() async {
    await resolveTestCode('''
class E {}
E f() {
  ^E e = .new();
  return e;
}
''');
    await assertHasAssist('''
class E {}
E f() {
  var e = E.new();
  return e;
}
''');
  }

  Future<void> test_simple_dotShorthand_methodInvocation() async {
    await resolveTestCode('''
class E {
  static E method() => E();
}
E f() {
  ^E e = .method();
  return e;
}
''');
    await assertHasAssist('''
class E {
  static E method() => E();
}
E f() {
  var e = E.method();
  return e;
}
''');
  }

  Future<void> test_simple_dotShorthand_propertyAccess() async {
    await resolveTestCode('''
enum E { a }
E f() {
  ^E e = .a;
  return e;
}
''');
    await assertHasAssist('''
enum E { a }
E f() {
  var e = E.a;
  return e;
}
''');
  }
}
