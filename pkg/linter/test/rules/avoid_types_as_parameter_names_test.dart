// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypesAsParameterNamesTest);
  });
}

@reflectiveTest
class AvoidTypesAsParameterNamesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_types_as_parameter_names;

  test_catchClauseParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C {}

void f() {
  try {} catch ([!C!]) {}
}
''');
  }

  test_classTypeParameter_instanceMethodTypeParameter() async {
    await assertNoDiagnostics(r'''
class A<X> {
  X instanceMethod<X>(X x) => x;
}
''');
  }

  test_classTypeParameter_staticMethodTypeParameter() async {
    await assertNoDiagnostics(r'''
class A<X> {
  static X staticMethod<X>(X x) => x;
}
''');
  }

  test_constructor_factory() async {
    await assertDiagnosticsFromMarkup(r'''
class A {}
class B {
  factory ([!A!]) => B._();
  B._();
}
''');
  }

  test_constructor_new() async {
    await assertDiagnosticsFromMarkup(r'''
class A {}
class B {
  new ([!A!]);
}
''');
  }

  test_constructor_primary_declaring() async {
    // There is no diagnostic because the name of the parameter is also the name
    // of a field.
    await assertNoDiagnostics(r'''
class A {}
class B(final A);
''');
  }

  test_constructor_primary_requiredPositional() async {
    await assertDiagnosticsFromMarkup(r'''
class A {}
class B([!A!]);
''');
  }

  test_extensionType() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(int i) { }

void f([!E!]) { }
''');
  }

  test_factoryParameter_shadowingTypeParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C<X> {
  factory C([!X!]) => C.name();
  C.name();
}
''');
  }

  test_fieldFormalParameter_missingType() async {
    await assertNoDiagnostics(r'''
class C {
  final int num;
  C(this.num);
}
''');
  }

  test_functionTypedParameter_missingName() async {
    await assertDiagnosticsFromMarkup(r'''
void f(void g([!int!])) {}
''');
  }

  test_functionTypedParameter_missingType_named() async {
    await assertDiagnosticsFromMarkup(r'''
void f(void g({[!int!]})) {}
''');
  }

  test_functionTypedParameter_missingType_optionalPositional() async {
    await assertDiagnosticsFromMarkup(r'''
void f(void g([[!int!]])) {}
''');
  }

  test_functionTypedParameter_noShadowing() async {
    await assertNoDiagnostics(r'''
void f(void g(int a)) {}
''');
  }

  test_functionTypeParameter_missingName() async {
    await assertNoDiagnostics(r'''
void f(int Function(int) g) {}
''');
  }

  test_functionTypeParameter_withParameter_noShadowing() async {
    await assertNoDiagnostics(r'''
class C<X> {
  void m(void Function(X) g) {}
}
''');
  }

  test_functionTypeParameter_withParameter_shadowingTypeParameter() async {
    await assertNoDiagnostics(r'''
void f(int Function<T>(T) g) {}
''');
  }

  test_parameter_shadowingTypeParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f<X>([!X!]) {}
''');
  }

  test_parameterIsFunctionName() async {
    await assertNoDiagnostics(r'''
void f(g) {}
void g() {}
''');
  }

  test_parameterIsTypedefName() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!T!]) {}
typedef T = int;
''');
  }

  test_super() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  String a;
  A(this.a);
}
class B extends A {
  B(super.[!String!]);
}
''');
  }

  test_typedefParameter_legacy_missingType() async {
    await assertDiagnosticsFromMarkup(r'''
typedef void T([!int!]);
''');
  }

  test_typedefParameter_legacy_missingType_named() async {
    await assertDiagnosticsFromMarkup(r'''
typedef void T({[!int!]});
''');
  }

  test_typedefParameter_legacy_missingType_optionalPositional() async {
    await assertDiagnosticsFromMarkup(r'''
typedef void f([[!int!]]);
''');
  }

  test_typedefParameter_legacy_noShadowing() async {
    await assertNoDiagnostics(r'''
typedef void T(int a);
''');
  }

  test_typedefParameter_legacy_undefinedName() async {
    await assertNoDiagnostics(r'''
typedef void f(Undefined);
''');
  }

  test_typedefParameter_missingName() async {
    await assertNoDiagnostics(r'''
typedef T = int Function(int);
''');
  }

  test_typeParameter_class() async {
    await assertDiagnosticsFromMarkup(r'''
class A<[!Object!]> {}
''');
  }

  test_typeParameter_function() async {
    await assertDiagnosticsFromMarkup(r'''
void f<[!int!]>() {}
''');
  }

  test_typeParameter_instanceMethod_class() async {
    await assertDiagnosticsFromMarkup(r'''
class A<X> {
  C instanceMethod<[!C!]>(C c) => c;
}

class C {}
''');
  }

  test_typeParameter_wildcard() async {
    await assertNoDiagnostics(r'''
class C<_> {
  var _;
  C.c(this._, _);
}
''');
  }
}
