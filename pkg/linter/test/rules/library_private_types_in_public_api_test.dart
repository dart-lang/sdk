// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrivateTypesInPublicApiEnumTest);
    defineReflectiveTests(LibraryPrivateTypesInPublicApiExtensionTypeTest);
    defineReflectiveTests(LibraryPrivateTypesInPublicApiSuperParamTest);
    defineReflectiveTests(LibraryPrivateTypesInPublicApiTest);
  });
}

@reflectiveTest
class LibraryPrivateTypesInPublicApiEnumTest extends LintRuleTest {
  @override
  List<ErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_LOCAL_VARIABLE,
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
      ];

  @override
  String get lintRule => LintNames.library_private_types_in_public_api;

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
  List<ErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_LOCAL_VARIABLE,
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
      ];

  @override
  String get lintRule => LintNames.library_private_types_in_public_api;

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
    await assertNoDiagnostics(r'''
class _C {}
extension type E(Object o) {
  _m(_C c){}
}
''');
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
    await assertNoDiagnostics(r'''
class _C {}
extension type E(Object o) {
  static _C? _m() => null;
}
''');
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
  List<ErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_LOCAL_VARIABLE,
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
      ];

  @override
  String get lintRule => LintNames.library_private_types_in_public_api;

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

@reflectiveTest
class LibraryPrivateTypesInPublicApiTest extends LintRuleTest {
  @override
  List<ErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_LOCAL_VARIABLE,
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
      ];

  @override
  String get lintRule => LintNames.library_private_types_in_public_api;

  test_class_extendsClassWithPrivateTypeArguments() async {
    await assertNoDiagnostics(r'''
class C extends D<_P> {}
class D<T> {}
class _P {}
''');
  }

  test_class_implementsPrivateClass() async {
    await assertNoDiagnostics(r'''
class C implements _P {}
class _P {}
''');
  }

  test_class_mixesInPrivateMixin() async {
    await assertNoDiagnostics(r'''
class C with _P {}
mixin _P {}
''');
  }

  test_constructor_private_privateParameterType() async {
    await assertNoDiagnostics(r'''
class C {
  C._named(_P p);
}
class _P {}
''');
  }

  test_constructor_privateParameterType() async {
    await assertDiagnostics(r'''
class C {
  C.named(_P p);
}
class _P {}
''', [
      lint(20, 2),
    ]);
  }

  test_constructor_unnamed_privateParameterType() async {
    await assertDiagnostics(r'''
class C {
  C(_P p);
}
class _P {}
''', [
      lint(14, 2),
    ]);
  }

  test_extension_onPrivateType() async {
    await assertDiagnostics(r'''
extension E on _P {}
class _P {}
''', [
      lint(15, 2),
    ]);
  }

  test_function_private_privateTypes() async {
    await assertNoDiagnostics(r'''
_P _f(_P p) => _P();
class _P {}
''');
  }

  test_function_privateParameterType() async {
    await assertDiagnostics(r'''
String f(_P p) => '';
class _P {}
''', [
      lint(9, 2),
    ]);
  }

  test_function_privateReturnType() async {
    await assertDiagnostics(r'''
_P f2(int i) => _P();
class _P {}
''', [
      lint(0, 2),
    ]);
  }

  test_function_publicTypes() async {
    await assertNoDiagnostics(r'''
String f(int i) => '';
''');
  }

  test_instanceField_private_privateReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  _P _f = _P();
}
class _P {}
''');
  }

  test_instanceField_privateClass_privateType() async {
    await assertNoDiagnostics(r'''
class _C {
  _P f = _P();
}
class _P {}
''');
  }

  test_instanceField_privateType() async {
    await assertDiagnostics(r'''
class C {
  _P f = _P();
}
class _P {}
''', [
      lint(12, 2),
    ]);
  }

  test_instanceField_privateTypeTypeArgument() async {
    await assertDiagnostics(r'''
class C {
  List<_P> f = [];
}
class _P {}
''', [
      lint(17, 2),
    ]);
  }

  test_instanceGetter_private_privateReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  _P get _g => _P();
}
class _P {}
''');
  }

  test_instanceGetter_privateReturnType() async {
    await assertDiagnostics(r'''
class C {
  _P get g2 => _P();
}
class _P {}
''', [
      lint(12, 2),
    ]);
  }

  test_instanceMethod_private_privateReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  _P _m() => _P();
}
class _P {}
''');
  }

  test_instanceMethod_privateClass_privateTypes() async {
    await assertNoDiagnostics(r'''
class _C {
  _P m(_P p) => _P();
}
class _P {}
''');
  }

  test_instanceMethod_privateParameterType() async {
    await assertDiagnostics(r'''
class C {
  String m(_P p) => '';
}
class _P {}
''', [
      lint(21, 2),
    ]);
  }

  test_instanceMethod_privateReturnType() async {
    await assertDiagnostics(r'''
class C {
  _P m(int i) => _P();
}
class _P {}
''', [
      lint(12, 2),
    ]);
  }

  test_instanceMethod_pulicTypes() async {
    await assertNoDiagnostics(r'''
class C {
  String m(int i) => '';
}
''');
  }

  test_instanceSetter_private_privateParameterType() async {
    await assertNoDiagnostics(r'''
class C {
  set _s(_P p) {}
}
class _P {}
''');
  }

  test_instanceSetter_privateParameterType() async {
    await assertDiagnostics(r'''
class C {
  set s(_P i) {}
}
class _P {}
''', [
      lint(18, 2),
    ]);
  }

  test_mixin_implementsPrivateType() async {
    await assertNoDiagnostics(r'''
mixin M implements _P {}
class _P {}
''');
  }

  test_mixin_onPrivateType() async {
    await assertDiagnostics(r'''
mixin M on _P {}
class _P {}
''', [
      lint(11, 2),
    ]);
  }

  test_mixin_private_onPrivateType() async {
    await assertNoDiagnostics(r'''
mixin _M on _P {}
class _P {}
''');
  }

  test_operator_privateParameterType() async {
    await assertDiagnostics(r'''
class C {
  int operator+(_P p) => 0;
}
class _P {}
''', [
      lint(26, 2),
    ]);
  }

  test_operator_privateReturnType() async {
    await assertDiagnostics(r'''
class C {
  _P operator-(int i) => _P();
}
class _P {}
''', [
      lint(12, 2),
    ]);
  }

  test_topLevelGetter_private_privateReturnType() async {
    await assertNoDiagnostics(r'''
_P get _g => _P();
class _P {}
''');
  }

  test_topLevelGetter_privateReturnType() async {
    await assertDiagnostics(r'''
_P get g => _P();
class _P {}
''', [
      lint(0, 2),
    ]);
  }

  test_topLevelSetter_private_privateParameterType() async {
    await assertNoDiagnostics(r'''
set _s(_P i) {}
class _P {}
''');
  }

  test_topLevelSetter_privateParameterType() async {
    await assertDiagnostics(r'''
set s(_P i) {}
class _P {}
''', [
      lint(6, 2),
    ]);
  }

  test_topLevelVariable_private_privateType() async {
    await assertNoDiagnostics(r'''
_P _v5 = _P();
class _P {}
''');
  }

  test_topLevelVariable_privateType() async {
    await assertDiagnostics(r'''
_P? v;
class _P {}
''', [
      lint(0, 2),
    ]);
  }

  test_topLevelVariable_privateTypeTypeArgument() async {
    await assertDiagnostics(r'''
List<_P> v = [];
class _P {}
''', [
      lint(5, 2),
    ]);
  }

  test_topLevelVariable_publicType() async {
    await assertNoDiagnostics(r'''
String v = '';
''');
  }

  test_typedef_legacy_privateParameterType() async {
    await assertDiagnostics(r'''
typedef void F(_P p);
class _P {}
''', [
      lint(15, 2),
    ]);
  }

  test_typedef_legacy_privateReturnType() async {
    await assertDiagnostics(r'''
typedef _P F();
class _P {}
''', [
      lint(8, 2),
    ]);
  }

  test_typedef_privateParameterType() async {
    await assertDiagnostics(r'''
typedef F = void Function(_P);
class _P {}
''', [
      lint(26, 2),
    ]);
  }

  test_typedef_privateReturnType() async {
    await assertDiagnostics(r'''
typedef F = _P Function();
class _P {}
''', [
      lint(12, 2),
    ]);
  }

  test_typedef_publicParameterType() async {
    await assertNoDiagnostics(r'''
typedef F = void Function(int);
''');
  }

  test_typedef_publicReturnType() async {
    await assertNoDiagnostics(r'''
typedef String F();
''');
  }
}
