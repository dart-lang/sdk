// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PublicMemberApiDocsTest);
    defineReflectiveTests(PublicMemberApiDocsTestDirTest);
    defineReflectiveTests(PublicMemberApiDocsExtensionTypesTest);
  });
}

@reflectiveTest
class PublicMemberApiDocsExtensionTypesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'public_member_api_docs';

  test_extensionTypeDeclaration() async {
    await assertDiagnostics(r'''
extension type E(int i) { }
''', [
      lint(15, 1),
    ]);
  }

  test_field_instance() async {
    await assertDiagnostics(r'''
/// Doc.
extension type E(int i) {
  int? f;
}
''', [
      // No lint.
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD, 42, 1),
    ]);
  }

  test_field_static() async {
    await assertDiagnostics(r'''
/// Doc.
extension type E(int i) {
  static int? f;
}
''', [
      lint(49, 1),
    ]);
  }

  test_method() async {
    await assertDiagnostics(r'''
/// Doc.
extension type E(int i) {
  void m() { }
}
''', [
      lint(42, 1),
    ]);
  }

  test_method_private() async {
    await assertDiagnostics(r'''
/// Doc.
extension type E(int i) {
  void _m() { }
}
''', [
      // No lint
      error(WarningCode.UNUSED_ELEMENT, 42, 2),
    ]);
  }
}

@reflectiveTest
class PublicMemberApiDocsTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'public_member_api_docs';

  /// https://github.com/dart-lang/linter/issues/4526
  test_abstractFinalConstructor() async {
    await assertDiagnostics(r'''
abstract final class S {
  S();
}

final class A extends S {}
''', [
      lint(21, 1),
      // No lint on `S()` declaration
      lint(47, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4526
  test_abstractInterfaceConstructor() async {
    await assertDiagnostics(r'''
abstract interface class S {
  S();
}

final class A extends S {}
''', [
      lint(25, 1),
      // No lint on `S()` declaration
      lint(51, 1),
    ]);
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

  test_enum_privateConstant() async {
    await assertDiagnostics(r'''
/// Documented.
enum A {
  _a;
}
''', [
      // No lint.
      error(WarningCode.UNUSED_FIELD, 27, 2),
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

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalClass() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@internal
class C {
  int? f;
  int get i => 0;
  C();
  void m() {}
}
''', [
      // Technically not in the private API but we can ignore that for testing.
      error(WarningCode.INVALID_INTERNAL_ANNOTATION, 34, 9),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalEnum() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@internal
enum E {
  a, b, c;
  int get i => 0;
  void m() {}

  const E();
}
''', [
      // Technically not in the private API but we can ignore that for testing.
      error(WarningCode.INVALID_INTERNAL_ANNOTATION, 34, 9),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalExtension() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@internal
extension X on Object {
  static int? f;
  static int get i => 0;
  void e() {}
}
''', [
      // Technically not in the private API but we can ignore that for testing.
      error(WarningCode.INVALID_INTERNAL_ANNOTATION, 34, 9),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4521
  test_internalMixin() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@internal
mixin M {
  int? f;
  int get i => 0;
  void m() {}
}
''', [
      // Technically not in the private API but we can ignore that for testing.
      error(WarningCode.INVALID_INTERNAL_ANNOTATION, 34, 9),
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

  /// https://github.com/dart-lang/linter/issues/4526
  test_sealedConstructor() async {
    await assertDiagnostics(r'''
sealed class S {
  S();
}

final class A extends S {}
''', [
      lint(13, 1),
      // No lint on `S()` declaration
      lint(39, 1),
    ]);
  }

  test_topLevelMembers() async {
    await assertDiagnostics(r'''
int g = 1;
typedef T = void Function();
int get z => 0;
''', [
      lint(4, 1),
      lint(19, 1),
      lint(48, 1),
    ]);
  }

  test_topLevelMembers_private() async {
    await assertDiagnostics(r'''
int _h = 1;
typedef _T = void Function();
int get _z => 0;
''', [
      // No lint
      error(WarningCode.UNUSED_ELEMENT, 4, 2),
      error(WarningCode.UNUSED_ELEMENT, 20, 2),
      error(WarningCode.UNUSED_ELEMENT, 50, 2),
    ]);
  }
}

@reflectiveTest
class PublicMemberApiDocsTestDirTest extends LintRuleTest {
  @override
  String get lintRule => 'public_member_api_docs';

  @override
  String get testPackageLibPath => '$testPackageRootPath/test';

  test_inTestDir() async {
    await assertNoDiagnostics(r'''
String? b;
typedef T = void Function();
''');
  }
}
