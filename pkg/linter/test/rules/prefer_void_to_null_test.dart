// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferVoidToNullTest);
  });
}

@reflectiveTest
class PreferVoidToNullTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_void_to_null;

  test_augmentedField() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  Future<Null>? f;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment abstract Future<Null>? f;
}
''');
  }

  test_augmentedFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

Future<Null>? f() => null;
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment Future<Null>? f();
''');
  }

  test_augmentedGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  Future<Null>? get v => null;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment Future<Null>? get v;
}
''');
  }

  test_augmentedMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  Future<Null>? f() => null;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment Future<Null>? f();
}
''');
  }

  test_augmentedTopLevelGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

Future<Null>? get v => null;
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment Future<Null>? get v;
''');
  }

  test_augmentedTopLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

Future<Null>? v;
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment abstract Future<Null>? v;
''');
  }

  /// https://github.com/dart-lang/linter/issues/4201
  test_castAsExpression() async {
    await assertNoDiagnostics(r'''
void f(int a) {
  a as Null;
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4201
  test_castPattern() async {
    await assertDiagnostics(
      r'''
void f(int a) {
  switch (a) {
    case var _ as Null:
  }
}
''',
      [error(diag.patternNeverMatchesValueType, 49, 4)],
    );
  }

  test_extension() async {
    await assertNoDiagnostics(r'''
extension _ on Null {}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4759
  test_extensionTypeRepresentation() async {
    await assertNoDiagnostics(r'''
extension type B<T>(T? _) {}
extension type N(Null _) implements B<Never> {}
''');
  }

  test_instanceField_futureOfNull() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  Future<[!Null!]>? x;
}
''');
  }

  test_instanceField_null() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!Null!] x;
}
''');
  }

  test_instanceField_null_prefixed() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:core' as core;
class C {
  core.[!Null!] x;
}
''');
  }

  test_instanceGetter_overrideChangingType() async {
    // https://github.com/dart-lang/linter/issues/1523
    await assertNoDiagnostics(r'''
abstract class C {
  Object? get foo;
}

class D extends C {
  @override
  Null get foo => null;
}
''');
  }

  test_listLiteralTypeArg_null_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  <Null>[];
}
''');
  }

  test_listLiteralTypeArg_null_nonEmpty() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  <[!Null!]>[null];
}
''');
  }

  test_localVariable() async {
    await assertNoDiagnostics(r'''
void f() {
  Null _;
}
''');
  }

  test_localVariable_futureOfNull() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  Future<[!Null!]> x;
}
''');
  }

  test_mapLiteralTypeArg_nullKey_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  <Null, String>{};
}
''');
  }

  test_mapLiteralTypeArg_nullKey_nonEmpty() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  <[!Null!], String>{null: "foo"};
}
''');
  }

  test_mapLiteralTypeArg_nullValue_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  <String, Null>{};
}
''');
  }

  test_mapLiteralTypeArg_nullValue_nonEmpty() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  <String, [!Null!]>{"foo": null};
}
''');
  }

  test_methodInvocation_typeArgument() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Future<void> p) {
  p.then<[!Null!]>((_) {});
}
''');
  }

  test_methodParameter_null() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m([!Null!] x) {}
}
''');
  }

  test_methodReturnType_customNullClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class Null {}
''');
    await assertNoDiagnostics(r'''
import 'a.dart' as a;
class C {
  a.Null? x;
}
''');
  }

  test_methodReturnType_null() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!Null!] m() {}
}
''');
  }

  test_methodReturnType_null_prefixed() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:core' as core;
class C {
  core.[!Null!] m() {}
}
''');
  }

  test_methodReturnType_overrideChangingType() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:async';
abstract class C {
  FutureOr<void>? m();
}

class D implements C {
  @override
  [!Null!] m() {}
}
''');
  }

  test_methodReturnType_overrideChangingType_generic() async {
    // https://github.com/dart-lang/linter/issues/2792
    await assertNoDiagnostics(r'''
abstract class C<T> {
  Future<T>? m();
}

class D<T> implements C<T> {
  @override
  Null m() {}
}
''');
  }

  test_methodReturnType_void() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {}
}
''');
  }

  test_topLevelFunction_parameterType_null() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!Null!] x) {}
''');
  }

  test_topLevelFunction_parameterType_null_prefixed() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:core' as core;
void f(core.[!Null!] x) {}
''');
  }

  test_topLevelFunction_returnType_null() async {
    await assertDiagnosticsFromMarkup(r'''
[!Null!] f() {}
''');
  }

  test_topLevelFunction_returnType_null_prefixed() async {
    await assertDiagnosticsFromMarkup(r'''
import 'dart:core' as core;
core.[!Null!] f() {}
''');
  }

  test_topLevelVariable() async {
    await assertNoDiagnostics(r'''
Null a;
''');
  }

  test_topLevelVariable_functionReturnType_functionParameterType_futureOfNull() async {
    await assertDiagnosticsFromMarkup(r'''
void Function(Future<[!Null!]>)? f;
''');
  }

  test_topLevelVariable_functionReturnType_functionParameterType_null() async {
    await assertNoDiagnostics(r'''
void Function(Null)? f;
''');
  }

  test_topLevelVariable_functionReturnType_functionReturnType_futureOfNull() async {
    await assertDiagnosticsFromMarkup(r'''
Future<[!Null!]> Function()? f;
''');
  }

  test_topLevelVariable_functionReturnType_functionReturnType_null() async {
    await assertNoDiagnostics(r'''
Null Function()? f;
''');
  }

  test_topLevelVariable_futureOfNull() async {
    await assertDiagnosticsFromMarkup(r'''
Future<[!Null!]>? x;
''');
  }

  test_topLevelVariable_null() async {
    await assertNoDiagnostics(r'''
Null x;
''');
  }

  test_typeLiteral_binaryExpression() async {
    await assertNoDiagnostics(r'''
void f() {
  0 == Null;
}
''');
  }

  test_typeLiteral_binaryExpression_prefixed() async {
    await assertNoDiagnostics(r'''
import 'dart:core' as core;
void f() {
  0 == core.Null;
}
''');
  }

  test_typeLiteral_expressionStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  Null;
}
''');
  }

  test_typeLiteral_expressionStatement_prefixed() async {
    await assertNoDiagnostics(r'''
import 'dart:core' as core;
void f() {
  core.Null;
}
''');
  }
}
