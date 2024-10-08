// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
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

  test_localVariable() async {
    await assertNoDiagnostics(r'''
void f() {
  Null _;
}
''');
  }

  test_topLevelVariable() async {
    await assertNoDiagnostics(r'''
Null a;
''');
  }
}
