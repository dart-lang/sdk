// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(mfairhurst): test void with a prefix, except that causes bugs.
    // TODO(mfairhurst): test defining a class named Null (requires a 2nd file).
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
  augment Future<Null>? f;
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

augment Future<Null>? f() => null;
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
  augment Future<Null>? get v => null;
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
  augment Future<Null>? f() => null;
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

augment Future<Null>? get v => null;
''');
  }

  test_augmentedTopLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

Future<Null>? v;
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment Future<Null>? v;
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
    await assertDiagnostics(r'''
void f(int a) {
  switch (a) {
    case var _ as Null:
  }
}
''', [
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 49, 4),
    ]);
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
    await assertDiagnostics(r'''
class C {
  Future<Null>? x;
}
''', [
      lint(19, 4),
    ]);
  }

  test_instanceField_null() async {
    await assertDiagnostics(r'''
class C {
  Null x;
}
''', [
      lint(12, 4),
    ]);
  }

  test_instanceField_null_prefixed() async {
    await assertDiagnostics(r'''
import 'dart:core' as core;
class C {
  core.Null x;
}
''', [
      lint(45, 4),
    ]);
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

  test_instanceMethod_returnType_overrideChangingType() async {
    await assertDiagnostics(r'''
import 'dart:async';
abstract class C {
  FutureOr<void>? m();
}

class D implements C {
  @override
  Null m() {}
}
''', [
      lint(103, 4),
    ]);
  }

  test_instanceMethod_returnType_overrideChangingType_generic() async {
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

  test_listLiteralTypeArg_null_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  <Null>[];
}
''');
  }

  test_listLiteralTypeArg_null_nonEmpty() async {
    await assertDiagnostics(r'''
void f() {
  <Null>[null];
}
''', [
      lint(14, 4),
    ]);
  }

  test_localVariable() async {
    await assertNoDiagnostics(r'''
void f() {
  Null _;
}
''');
  }

  test_localVariable_futureOfNull() async {
    await assertDiagnostics(r'''
void f() {
  Future<Null> x;
}
''', [
      lint(20, 4),
    ]);
  }

  test_mapLiteralTypeArg_nullKey_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  <Null, String>{};
}
''');
  }

  test_mapLiteralTypeArg_nullKey_nonEmpty() async {
    await assertDiagnostics(r'''
void f() {
  <Null, String>{null: "foo"};
}
''', [
      lint(14, 4),
    ]);
  }

  test_mapLiteralTypeArg_nullValue_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  <String, Null>{};
}
''');
  }

  test_mapLiteralTypeArg_nullValue_nonEmpty() async {
    await assertDiagnostics(r'''
void f() {
  <String, Null>{"foo": null};
}
''', [
      lint(22, 4),
    ]);
  }

  test_methodInvocation_typeArgument() async {
    await assertDiagnostics(r'''
void f(Future<void> p) {
  p.then<Null>((_) {});
}
''', [
      lint(34, 4),
    ]);
  }

  test_methodParameter_null() async {
    await assertDiagnostics(r'''
class C {
  void m(Null x) {}
}
''', [
      lint(19, 4),
    ]);
  }

  test_methodReturnType_null() async {
    await assertDiagnostics(r'''
class C {
  Null m() {}
}
''', [
      lint(12, 4),
    ]);
  }

  test_methodReturnType_null_prefixed() async {
    await assertDiagnostics(r'''
import 'dart:core' as core;
class C {
  core.Null m() {}
}
''', [
      lint(45, 4),
    ]);
  }

  test_topLevelFunction_parameterType_null() async {
    await assertDiagnostics(r'''
void f(Null x) {}
''', [
      lint(7, 4),
    ]);
  }

  test_topLevelFunction_parameterType_null_prefixed() async {
    await assertDiagnostics(r'''
import 'dart:core' as core;
void f(core.Null x) {}
''', [
      lint(40, 4),
    ]);
  }

  test_topLevelFunction_returnType_null() async {
    await assertDiagnostics(r'''
Null f() {}
''', [
      lint(0, 4),
    ]);
  }

  test_topLevelFunction_returnType_null_prefixed() async {
    await assertDiagnostics(r'''
import 'dart:core' as core;
core.Null f() {}
''', [
      lint(33, 4),
    ]);
  }

  test_topLevelVariable() async {
    await assertNoDiagnostics(r'''
Null a;
''');
  }

  test_topLevelVariable_functionReturnType_functionParameterType_futureOfNull() async {
    await assertDiagnostics(r'''
void Function(Future<Null>)? f;
''', [
      lint(21, 4),
    ]);
  }

  test_topLevelVariable_functionReturnType_functionParameterType_null() async {
    await assertNoDiagnostics(r'''
void Function(Null)? f;
''');
  }

  test_topLevelVariable_functionReturnType_functionReturnType_futureOfNull() async {
    await assertDiagnostics(r'''
Future<Null> Function()? f;
''', [
      lint(7, 4),
    ]);
  }

  test_topLevelVariable_functionReturnType_functionReturnType_null() async {
    await assertNoDiagnostics(r'''
Null Function()? f;
''');
  }

  test_topLevelVariable_futureOfNull() async {
    await assertDiagnostics(r'''
Future<Null>? x;
''', [
      lint(7, 4),
    ]);
  }

  test_topLevelVariable_null() async {
    await assertNoDiagnostics(r'''
Null x;
''');
  }
}
