// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFutureOrVoidTest);
  });
}

@reflectiveTest
class AvoidFutureOrVoidTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_futureor_void;

  test_asExpression() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

var x = 1 as [!FutureOr<void>!];
''');
  }

  test_castPattern() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

f() {
  // ignore: unnecessary_cast_pattern
  var [Object? x as [!FutureOr<void>!]] = [1];
  return x;
}
''');
  }

  test_class_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

class A<X extends [!FutureOr<void>!]> {}
''');
  }

  test_enum_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

enum E<X extends [!FutureOr<void>!]> {
  one;
}
''');
  }

  test_extension_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

extension E<X extends [!FutureOr<void>!]> on X {}
''');
  }

  test_extensionOnClause() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

extension E on [!FutureOr<void>!] {}
''');
  }

  test_extensionType_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

extension type E<X extends [!FutureOr<void>!]>(X x) {}
''');
  }

  test_extensionType_representation() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

extension type E([!FutureOr<void>!] _) {}
''');
  }

  test_function_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

void f<X extends [!FutureOr<void>!]>(List<X> x) {}
''');
  }

  test_functionTypedFormalParameter_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

void f(g<X extends [!FutureOr<void>!]>(X x)) {}
''');
  }

  test_functionTypedFormalParameter_parameter1() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

void f(g([!FutureOr<void>!] x)) {}
''');
  }

  test_functionTypedFormalParameter_parameter2() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

void f(g([[!FutureOr<void>!] x])) {}
''');
  }

  test_functionTypedFormalParameter_parameter3() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

void f(g({required [!FutureOr<void>!] name})) {}
''');
  }

  test_functionTypedFormalParameter_return() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(FutureOr<void> g()) {}
''');
  }

  test_isExpression() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

// ignore: unnecessary_type_check
var x = 1 is [!FutureOr<void>!];
''');
  }

  test_mixin_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

mixin A<X extends [!FutureOr<void>!]> {}
''');
  }

  test_objectPattern() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

f(Object? x) {
  if (x case [!FutureOr<void>!]()) return;
}
''');
  }

  test_oldTypeAlias_bound() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

typedef void F<X extends [!FutureOr<void>!]>(X arg);
''');
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
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';

typedef F<X extends [!FutureOr<void>!]> = int;
''');
  }
}
