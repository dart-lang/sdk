// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypeToStringTest);
  });
}

@reflectiveTest
class AvoidTypeToStringTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_type_to_string;

  test_extensionOnType_implicitThis() async {
    await assertDiagnostics(
      r'''
extension E on Type {
  void f() {
    toString();
  }
}
''',
      [lint(39, 8)],
    );
  }

  test_extensionType_implicitThis() async {
    await assertDiagnostics(
      r'''
extension type E(int i) {
  m() {
    runtimeType.toString();
  }
}
''',
      [lint(50, 8)],
    );
  }

  test_extensionType_instance() async {
    await assertDiagnostics(
      r'''
extension type E(int i) {
  m() {
    E(i).runtimeType.toString();
  }
}
''',
      [lint(55, 8)],
    );
  }

  test_mixinOnType_explicitThis() async {
    await assertDiagnostics(
      r'''
mixin M on Type {
  late var x = this.toString();
}
''',
      [lint(38, 8)],
    );
  }

  test_mixinOnType_implicitThis() async {
    await assertDiagnostics(
      r'''
mixin M on Type {
  late var x = toString();
}
''',
      [lint(33, 8)],
    );
  }

  test_runtimeType() async {
    await assertDiagnostics(
      r'''
var x = 7.runtimeType.toString();
''',
      [lint(22, 8)],
    );
  }

  test_type_tearoff() async {
    await assertDiagnostics(
      r'''
void f() {
  foo(7.runtimeType.toString);
}
void foo(String Function() p) {}
''',
      [lint(31, 8)],
    );
  }

  test_typeImplementsType_withToStringOverride() async {
    await assertNoDiagnostics(r'''
mixin M {
  @override
  String toString() => '';
}
class Type2 with M implements Type {
  String get x => toString();
}
''');
  }

  test_typeThatExtendsTypeThatImplementsType() async {
    await assertDiagnostics(
      r'''
var x = Type3().toString();
class Type2 implements Type {}
class Type3 extends Type2 {}
''',
      [lint(16, 8)],
    );
  }

  test_typeThatImplementsType() async {
    await assertDiagnostics(
      r'''
var x = Type2().toString();
class Type2 implements Type {}
''',
      [lint(16, 8)],
    );
  }

  test_typeThatImplementsType_explicitThis() async {
    await assertDiagnostics(
      r'''
class Type2 implements Type {
  late var x = this.toString();
}
''',
      [lint(50, 8)],
    );
  }

  test_typeThatImplementsType_implicitThis() async {
    await assertDiagnostics(
      r'''
class Type2 implements Type {
  late var x = toString();
}
''',
      [lint(45, 8)],
    );
  }

  test_typeThatImplementsType_super() async {
    await assertDiagnostics(
      r'''
class Type2 implements Type {
  late var x = super.toString();
}
''',
      [lint(51, 8)],
    );
  }

  test_typeThatImplementsType_tearoff() async {
    await assertDiagnostics(
      r'''
class Type2 implements Type {}
void f(Type2 t) {
  foo(t.toString);
}
void foo(String Function() p) {}
''',
      [lint(57, 8)],
    );
  }

  test_typeThatImplementsType_tearoff_explicitThis() async {
    await assertDiagnostics(
      r'''
class Type2 implements Type {
  void f() {
    foo(this.toString);
  }
  void foo(String Function() p) {}
}
''',
      [lint(56, 8)],
    );
  }

  test_typeThatImplementsType_tearoff_implicitThis() async {
    await assertDiagnostics(
      r'''
class Type2 implements Type {
  void f() {
    foo(toString);
  }
  void foo(String Function() p) {}
}
''',
      [lint(51, 8)],
    );
  }
}
