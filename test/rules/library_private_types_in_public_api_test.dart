// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrivateTypesInPublicApiEnumTest);
    defineReflectiveTests(LibraryPrivateTypesInPublicApiSuperParamTest);
  });
}

@reflectiveTest
class LibraryPrivateTypesInPublicApiEnumTest extends LintRuleTest {
  @override
  String get lintRule => 'library_private_types_in_public_api';

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
