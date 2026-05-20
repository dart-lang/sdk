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
    await assertDiagnosticsFromMarkdown(r'''
extension E on Type {
  void f() {
    [!toString!]();
  }
}
''');
  }

  test_extensionType_implicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
extension type E(int i) {
  m() {
    runtimeType.[!toString!]();
  }
}
''');
  }

  test_extensionType_instance() async {
    await assertDiagnosticsFromMarkdown(r'''
extension type E(int i) {
  m() {
    E(i).runtimeType.[!toString!]();
  }
}
''');
  }

  test_mixinOnType_explicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
mixin M on Type {
  late var x = this.[!toString!]();
}
''');
  }

  test_mixinOnType_implicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
mixin M on Type {
  late var x = [!toString!]();
}
''');
  }

  test_runtimeType() async {
    await assertDiagnosticsFromMarkdown(r'''
var x = 7.runtimeType.[!toString!]();
''');
  }

  test_type_tearoff() async {
    await assertDiagnosticsFromMarkdown(r'''
void f() {
  foo(7.runtimeType.[!toString!]);
}
void foo(String Function() p) {}
''');
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
    await assertDiagnosticsFromMarkdown(r'''
var x = Type3().[!toString!]();
class Type2 implements Type {}
class Type3 extends Type2 {}
''');
  }

  test_typeThatImplementsType() async {
    await assertDiagnosticsFromMarkdown(r'''
var x = Type2().[!toString!]();
class Type2 implements Type {}
''');
  }

  test_typeThatImplementsType_explicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
class Type2 implements Type {
  late var x = this.[!toString!]();
}
''');
  }

  test_typeThatImplementsType_implicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
class Type2 implements Type {
  late var x = [!toString!]();
}
''');
  }

  test_typeThatImplementsType_super() async {
    await assertDiagnosticsFromMarkdown(r'''
class Type2 implements Type {
  late var x = super.[!toString!]();
}
''');
  }

  test_typeThatImplementsType_tearoff() async {
    await assertDiagnosticsFromMarkdown(r'''
class Type2 implements Type {}
void f(Type2 t) {
  foo(t.[!toString!]);
}
void foo(String Function() p) {}
''');
  }

  test_typeThatImplementsType_tearoff_explicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
class Type2 implements Type {
  void f() {
    foo(this.[!toString!]);
  }
  void foo(String Function() p) {}
}
''');
  }

  test_typeThatImplementsType_tearoff_implicitThis() async {
    await assertDiagnosticsFromMarkdown(r'''
class Type2 implements Type {
  void f() {
    foo([!toString!]);
  }
  void foo(String Function() p) {}
}
''');
  }
}
