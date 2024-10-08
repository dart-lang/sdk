// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferCollectionLiteralsTest);
  });
}

@reflectiveTest
class PreferCollectionLiteralsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_collection_literals;

  test_assignment() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f(LinkedHashSet<int> s) {
  s = LinkedHashSet();
}
''');
  }

  test_assignment_withCascade() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f(LinkedHashSet<int> s) {
  s = LinkedHashSet()..addAll([1, 2, 3]);
}
''');
  }

  test_assignment_withParentheses() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f(LinkedHashSet<int> s) {
  s = ((LinkedHashSet()));
}
''');
  }

  test_closure_returns_linkedHashSet() async {
    await assertDiagnostics(r'''
import 'dart:collection';

void a(Set<int> Function() f) {}

void c() {
  a(() => LinkedHashSet<int>());
}
''', [
      lint(82, 20),
    ]);
  }

  test_conditionalLeft() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f(LinkedHashMap<int, int> a, LinkedHashMap<int, int> b) {
  a = (1 == 2) ? LinkedHashMap() : b;
}
''');
  }

  test_conditionalRight() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f(LinkedHashMap<int, int> a, LinkedHashMap<int, int> b) {
  a = (1 == 2) ? b : LinkedHashMap();
}
''');
  }

  test_constructorInitializer() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

class Foo {
  LinkedHashMap<int, double> a;
  Foo() : a = LinkedHashMap();
}
''');
  }

  test_functionExpression_functionDeclaration() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

LinkedHashMap<int, int> f() => LinkedHashMap();
''');
  }

  test_functionExpression_methodDeclaration() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

class C {
  LinkedHashMap<int, int> f() => LinkedHashMap();
}
''');
  }

  test_functionExpression_omittedReturnType() async {
    await assertDiagnostics(r'''
import 'dart:collection';

f() => LinkedHashMap();
''', [
      lint(34, 15),
    ]);
  }

  test_iterable_emptyConstructor_iterableDeclaration() async {
    await assertNoDiagnostics(r'''
void f() {
  Iterable x = Iterable.empty();
}
''');
  }

  test_linkedHashMap_unnamedConstructor() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashMap();
}
''', [
      lint(39, 15),
    ]);
  }

  test_linkedHashMap_unnamedConstructor_linkedHashMapParameterType() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
void f() {
  g(LinkedHashMap<int, int>());
}
void g(LinkedHashMap<int, int> p) {}
''');
  }

  test_linkedHashMap_unnamedConstructor_mapParameterType() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  g(LinkedHashMap<int, int>());
}
void g(Map<int, int> p) {}
''', [
      lint(41, 25),
    ]);
  }

  test_linkedHashSet_fromConstructor() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashSet.from(['foo', 'bar', 'baz']);
}
''', [
      lint(39, 41),
    ]);
  }

  test_linkedHashSet_fromConstructor_linkedHashSetDeclaration() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashSet<int> x = LinkedHashSet.from([1, 2, 3]);
}
''');
  }

  test_linkedHashSet_fromConstructor_setDeclaration() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  Set<int> x = LinkedHashSet.from([1, 2, 3]);
}
''', [
      lint(52, 29),
    ]);
  }

  test_linkedHashSet_ofConstructor() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashSet.of(['foo', 'bar', 'baz']);
}
''', [
      lint(39, 39),
    ]);
  }

  test_linkedHashSet_unnamedConstructor() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashSet();
}
''', [
      lint(39, 15),
    ]);
  }

  test_linkedHashSet_unnamedConstructor_hashSetParameterType() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
void f() {
  g(LinkedHashSet<int>());
}
void g(LinkedHashSet<int> p) {}
''');
  }

  test_linkedHashSet_unnamedConstructor_linkedHashSetDeclaration() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashSet<int> x = LinkedHashSet<int>();
}
''');
  }

  test_linkedHashSet_unnamedConstructor_moreArgs() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
void f() {
  LinkedHashSet(equals: (a, b) => false, hashCode: (o) => 13)
    ..addAll({});
}
''');
  }

  test_linkedHashSet_unnamedConstructor_setDeclaration() async {
    await assertDiagnostics(r'''
import 'dart:collection';
void f() {
  Set<int> x = LinkedHashSet<int>();
}
''', [
      lint(52, 20),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/2985
  test_linkedHashSetParameter_named_type_required() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

class Foo {}

void a({required LinkedHashSet<Foo> some}) {}

void c() {
  a(some: LinkedHashSet<Foo>());
}
''');
  }

  test_linkedHashSetParameter_named_type_unrequired() async {
    await assertDiagnostics(r'''
import 'dart:collection';

class Foo {}

void a({required Set<Foo> some}) {}

void c() {
  a(some: LinkedHashSet<Foo>());
}
''', [
      lint(99, 20),
    ]);
  }

  test_linkedHashSetParameter_type_required() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

class Foo {}

void b(LinkedHashSet<Foo> some) {}

void c() {
  b(LinkedHashSet());
}
''');
  }

  test_linkedHashSetParameter_type_unrequired() async {
    await assertDiagnostics(r'''
import 'dart:collection';

class Foo {}

void b(Set<Foo> some) {}

void c() {
  b(LinkedHashSet<Foo>());
}
''', [
      lint(82, 20),
    ]);
  }

  test_list_filledConstructor() async {
    await assertNoDiagnostics(r'''
void f() {
  List.filled(5, true);
}
''');
  }

  test_listLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  [];
}
''');
  }

  test_listLiteral_toSet() async {
    await assertDiagnostics(r'''
void f() {
  ['foo', 'bar', 'baz'].toSet();
}
''', [
      lint(13, 29),
    ]);
  }

  test_map_identityConstructor() async {
    await assertNoDiagnostics(r'''
void f() {
  Map.identity();
}
''');
  }

  test_map_unmodifiableConstructor() async {
    await assertNoDiagnostics(r'''
void f() {
  Map.unmodifiable({});
}
''');
  }

  test_map_unnamedConstructor() async {
    await assertDiagnostics(r'''
void f() {
  Map();
}
''', [
      lint(13, 5),
    ]);
  }

  test_mapLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = {};
}
''');
  }

  test_returnStatement_async() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

Future<LinkedHashSet<int>> f() async {
  return LinkedHashSet();
}
''');
  }

  test_returnStatement_asyncStar() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

Stream<LinkedHashSet<int>> f() async* {
  yield LinkedHashSet();
}
''');
  }

  test_returnStatement_functionDeclaration() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

LinkedHashSet<int> f() {
  return LinkedHashSet();
}
''');
  }

  test_returnStatement_functionExpression() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

void f() {
  g(() {
    return LinkedHashSet();
  });
}

void g(LinkedHashSet<int> Function()) {}
''');
  }

  test_returnStatement_methodDeclaration() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

class C {
  LinkedHashSet<int> f() {
    return LinkedHashSet();
  }
}
''');
  }

  test_returnStatement_syncStar() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';

Iterable<LinkedHashSet<int>> f() sync* {
  yield LinkedHashSet();
}
''');
  }

  test_set_fromConstructor() async {
    await assertDiagnostics(r'''
void f() {
  Set.from(['foo', 'bar', 'baz']);
}
''', [
      lint(13, 31),
    ]);
  }

  test_set_fromConstructor_withTypeArgs() async {
    await assertDiagnostics(r'''
void f() {
  Set<int>.from([]);
}
''', [
      lint(13, 17),
    ]);
  }

  test_set_identityConstructor() async {
    await assertNoDiagnostics(r'''
void f() {
  Set.identity();
}
''');
  }

  test_set_ofConstructor() async {
    await assertDiagnostics(r'''
void f() {
  Set.of(['foo', 'bar', 'baz']);
}
''', [
      lint(13, 29),
    ]);
  }

  test_set_unnamedConstructor() async {
    await assertDiagnostics(r'''
void f() {
  Set();
}
''', [
      lint(13, 5),
    ]);
  }

  test_set_unnamedConstructor_objectParameterType() async {
    await assertDiagnostics(r'''
void f() {
  g(Set());
}
void g(Object p) {}
''', [
      lint(15, 5),
    ]);
  }

  test_set_unnamedContsructor_explicitTypeArgs() async {
    await assertDiagnostics(r'''
void f() {
  Set<int>();
}
''', [
      lint(13, 10),
    ]);
  }

  test_typedefConstruction() async {
    await assertNoDiagnostics(r'''
typedef MyMap = Map<int, int>;

var x = MyMap();
''');
  }

  test_undefinedFunction() async {
    await assertDiagnostics(r'''
import 'dart:collection';

void f() {
  printUnresolved(LinkedHashSet<int>());
}
''', [
      // No lints.
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 40, 15),
    ]);
  }
}
