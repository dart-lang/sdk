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
  String get lintRule => 'prefer_collection_literals';

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
