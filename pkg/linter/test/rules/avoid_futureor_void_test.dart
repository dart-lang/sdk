// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFutureOrVoidTest);
  });
}

@reflectiveTest
class AvoidFutureOrVoidTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_futureor_void;

  test_asExpression() async {
    await assertDiagnostics(r'''
import 'dart:async';

var x = 1 as FutureOr<void>;
''', [
      lint(35, 14),
    ]);
  }

  test_castPattern() async {
    await assertDiagnostics(r'''
import 'dart:async';

f() {
  // ignore: unnecessary_cast_pattern
  var [Object? x as FutureOr<void>] = [1];
  return x;
}
''', [
      lint(86, 14),
    ]);
  }

  test_class_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

class A<X extends FutureOr<void>> {}
''', [
      lint(40, 14),
    ]);
  }

  test_enum_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

enum E<X extends FutureOr<void>> {
  one;
}
''', [
      lint(39, 14),
    ]);
  }

  test_extension_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

extension E<X extends FutureOr<void>> on X {}
''', [
      lint(44, 14),
    ]);
  }

  test_extensionOnClause() async {
    await assertDiagnostics(r'''
import 'dart:async';

extension E on FutureOr<void> {}
''', [
      lint(37, 14),
    ]);
  }

  test_extensionType_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

extension type E<X extends FutureOr<void>>(X x) {}
''', [
      lint(49, 14),
    ]);
  }

  test_extensionType_representation() async {
    await assertDiagnostics(r'''
import 'dart:async';

extension type E(FutureOr<void> _) {}
''', [
      lint(39, 14),
    ]);
  }

  test_function_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

void f<X extends FutureOr<void>>(List<X> x) {}
''', [
      lint(39, 14),
    ]);
  }

  test_functionTypedFormalParameter_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

void f(g<X extends FutureOr<void>>(X x)) {}
''', [
      lint(41, 14),
    ]);
  }

  test_functionTypedFormalParameter_parameter1() async {
    await assertDiagnostics(r'''
import 'dart:async';

void f(g(FutureOr<void> x)) {}
''', [
      lint(31, 14),
    ]);
  }

  test_functionTypedFormalParameter_parameter2() async {
    await assertDiagnostics(r'''
import 'dart:async';

void f(g([FutureOr<void> x])) {}
''', [
      lint(32, 14),
    ]);
  }

  test_functionTypedFormalParameter_parameter3() async {
    await assertDiagnostics(r'''
import 'dart:async';

void f(g({required FutureOr<void> name})) {}
''', [
      lint(41, 14),
    ]);
  }

  test_functionTypedFormalParameter_return() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(FutureOr<void> g()) {}
''');
  }

  test_isExpression() async {
    await assertDiagnostics(r'''
import 'dart:async';

// ignore: unnecessary_type_check
var x = 1 is FutureOr<void>;
''', [
      lint(69, 14),
    ]);
  }

  test_mixin_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

mixin A<X extends FutureOr<void>> {}
''', [
      lint(40, 14),
    ]);
  }

  test_objectPattern() async {
    await assertDiagnostics(r'''
import 'dart:async';

f(Object? x) {
  if (x case FutureOr<void>()) return;
}
''', [
      lint(50, 14),
    ]);
  }

  test_oldTypeAlias_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

typedef void F<X extends FutureOr<void>>(X arg);
''', [
      lint(47, 14),
    ]);
  }

  test_oldTypeAlias_parameter() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

typedef void F(FutureOr<void> arg);
''');
  }

  test_oldTypeAlias_return() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

typedef FutureOr<void> F();
''');
  }

  test_typeAlias_body() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

typedef F = FutureOr<void>;
''');
  }

  test_typeAlias_body2() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

typedef F = void Function(FutureOr<void>);
''');
  }

  test_typeAlias_bound() async {
    await assertDiagnostics(r'''
import 'dart:async';

typedef F<X extends FutureOr<void>> = int;
''', [
      lint(42, 14),
    ]);
  }
}
