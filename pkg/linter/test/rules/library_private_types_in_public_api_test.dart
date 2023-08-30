// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrivateTypesInPublicApiEnumTest);
    defineReflectiveTests(LibraryPrivateTypesInPublicApiExtensionTypeTest);
    defineReflectiveTests(LibraryPrivateTypesInPublicApiSuperParamTest);
  });
}

@reflectiveTest
class LibraryPrivateTypesInPublicApiEnumTest extends LintRuleTest {
  @override
  String get lintRule => 'library_private_types_in_public_api';

  test_abstractFinal_constructorParams() async {
    await assertNoDiagnostics(r'''
class _O {
  const _O();
}

abstract final class E {
  E(_O o);
}
''');
  }

  test_abstractInterface_constructorParams() async {
    await assertNoDiagnostics(r'''
class _O {
  const _O();
}

abstract interface class E {
  E(_O o);
}
''');
  }

  test_enum() async {
    await assertDiagnostics(r'''
class _O {}
enum E {
  a, b, c;
  final _O o = _O();
  void oo(_O o) { }
  _O get ooo => o;
}
''', [
      lint(40, 2),
      lint(63, 2),
      lint(75, 2),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4470
  test_enum_constructorParams() async {
    await assertNoDiagnostics(r'''
class _O {
  const _O();
}
enum E {
  a(_O());
  const E(_O o);
}
''');
  }

  test_sealed_constructorParams() async {
    await assertNoDiagnostics(r'''
class _O {
  const _O();
}

sealed class E {
  E(_O o);
}
''');
  }
}

@reflectiveTest
class LibraryPrivateTypesInPublicApiExtensionTypeTest extends LintRuleTest {
  @override
  String get lintRule => 'library_private_types_in_public_api';

  test_constructorParam() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  E.e(_C c) : o = c;
}
''', [
      lint(47, 2),
    ]);
  }

  test_extensionTypeDeclaration_representation() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(_C c) {}
''', [
      lint(29, 2),
    ]);
  }

  test_extensionTypeDeclaration_representation_private() async {
    await assertNoDiagnostics(r'''
class _C {}
extension type E(_C _c) {}
''');
  }

  test_extensionTypeDeclaration_typeParam() async {
    await assertDiagnostics(r'''
class _C {}
extension type E<T extends _C>(Object o) {}
''', [
      lint(39, 2),
    ]);
  }

  test_field_instance() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  _C? c;
}
''', [
      // No lint.
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD, 47, 1),
    ]);
  }

  test_field_static() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  static _C? c;
}
''', [
      lint(50, 2),
    ]);
  }

  test_method_instance_param() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  m(_C c){}
}
''', [
      lint(45, 2),
    ]);
  }

  test_method_instance_private_param() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  _m(_C c){}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 43, 2),
    ]);
  }

  test_method_instance_returnType() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  _C? m() => null;
}
''', [
      lint(43, 2),
    ]);
  }

  test_method_static_param() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  static m(_C c){}
}
''', [
      lint(52, 2),
    ]);
  }

  test_method_static_private_returnType() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  static _C? _m() => null;
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 54, 2),
    ]);
  }

  test_method_static_returnType() async {
    await assertDiagnostics(r'''
class _C {}
extension type E(Object o) {
  static _C? m() => null;
}
''', [
      lint(50, 2),
    ]);
  }
}

@reflectiveTest
class LibraryPrivateTypesInPublicApiSuperParamTest extends LintRuleTest {
  @override
  String get lintRule => 'library_private_types_in_public_api';

  test_implicitTypeFieldFormalParam() async {
    await assertDiagnostics(r'''
class _O {}
class C {
  _O _x;

  C(this._x);

  Object get x => _x;
}
''', [
      lint(41, 2),
    ]);
  }

  test_implicitTypeSuperFormalParam() async {
    await assertDiagnostics(r'''
class _O extends Object {}
class _A {
  _A(_O o);
}
class B extends _A {
  B(super.o);
}
''', [
      lint(83, 1),
    ]);
  }

  test_recursiveInterfaceInheritance() async {
    await assertDiagnostics(r'''
class _O extends Object {}
class A {
  Object o;
  A(this.o);
}

class B extends A {
  B(_O super.o);
}
''', [
      lint(89, 2),
    ]);
  }
}
