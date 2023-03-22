// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PublicMemberApiDocsTest);
  });
}

@reflectiveTest
class PublicMemberApiDocsTest extends LintRuleTest {
  @override
  String get lintRule => 'public_member_api_docs';

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int x() => 0;
  int get y => 1;
}
''', [
      lint(5, 1),
      lint(11, 1),
      lint(13, 1),
      lint(15, 1),
      lint(24, 1),
      lint(44, 1),
    ]);
  }

  test_enumConstructor() async {
    await assertNoDiagnostics(r'''
/// Documented.
enum A {
  /// This represents 'a'.
  a(),

  /// This represents 'b'.
  b();

  const A();
}
''');
  }

  test_annotatedEnumValue() async {
    await assertNoDiagnostics(r'''
/// Documented.
enum A {
  /// This represents 'a'.
  @Deprecated("Use 'b'")
  a,

  /// This represents 'b'.
  b;
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3525
  test_extension() async {
    await assertDiagnostics(r'''
extension E on Object {
  void f() { }
}
''', [
      lint(10, 1),
      lint(31, 1),
    ]);
  }

  test_mixin_method() async {
    await assertDiagnostics(r'''
/// A mixin M.
mixin M {
  String m() => '';
}''', [
      lint(34, 1),
    ]);
  }

  test_mixin_overridingMethod_OK() async {
    await assertNoDiagnostics(r'''
/// A mixin M.
mixin M {
  @override
  String toString() => '';
}''');
  }
}
