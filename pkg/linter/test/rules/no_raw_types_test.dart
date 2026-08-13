// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoRawTypesTest);
  });
}

@reflectiveTest
class NoRawTypesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.no_raw_types;

  test_asExpression() async {
    await assertNoDiagnostics(r'''
void f(dynamic x) {
  print(x as List);
}
''');
  }

  test_asExpression_typeArgument() async {
    await assertNoDiagnostics(r'''
void f(dynamic x) {
  print(x as List<List>);
}
''');
  }

  test_castPattern() async {
    await assertNoDiagnostics(r'''
void f((Object, ) l) {
  var (_ as List, ) = l;
}
''');
  }

  test_castPattern_typeArgument() async {
    await assertNoDiagnostics(r'''
void f((Object, ) l) {
  var (_ as List<List>, ) = l;
}
''');
  }

  test_constantPattern() async {
    await assertNoDiagnostics(r'''
void f(C<int> c) {
  switch (c) {
    case const C():
  }
}

class C<T> {
  const C();
}
''');
  }

  test_functionParts_optionalTypeArg() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
C f(int a) => C();
void g(C a) {}
''');
  }

  test_genericTypeArgument_extensionType_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E<T>(int i) {}

void f() {
  <List<[!E!]>>[];
}
''');
  }

  test_genericTypeArgument_extensionType_withTypeArg() async {
    await assertNoDiagnostics(r'''
extension type E<T>(int i) {}

void f() {
  <List<E<int>>>[];
}
''');
  }

  test_genericTypeArgument_extensionTypeImplements_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(List<int> i) implements [!Iterable!] {}
''');
  }

  test_genericTypeArgument_extensionTypeImplementsExtensionType_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E<T>(Iterable<T> i) {}

extension type F(List<int> j) implements [!E!] {}
''');
  }

  test_genericTypeArgument_extensionTypeRepresentationType_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E([!List!] i) {}
''');
  }

  test_genericTypeArgument_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  var a = <[!List!]>[];
}
''');
  }

  test_genericTypeArgument_withTypeArg() async {
    await assertNoDiagnostics(r'''
void f() {
  var a = <List<int>>[];
}
''');
  }

  test_instanceCreation() async {
    await assertNoDiagnostics(r'''
var c = List.empty();
''');
  }

  test_isExpression() async {
    await assertNoDiagnostics(r'''
void f(dynamic x) {
  print(x is List);
  print(x is List<dynamic>);
  print(x is List<List>);
}
''');
  }

  test_localVariable_extensionType_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E<T>(int i) {}
    
void f() {
  [!E!] e = E(1);
}
''');
  }

  test_localVariable_extensionType_withTypeArg() async {
    await assertNoDiagnostics(r'''
extension type E<T>(int i) {}
    
void f() {
  E<int> e = E<int>(1);
}
''');
  }

  test_localVariable_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!List!] a = [1, 2, 3];
}
''');
  }

  test_localVariable_withTypeArg() async {
    await assertNoDiagnostics(r'''
void f() {
  List<Object> a = [1, 2, 3];
  print(a);
}
''');
  }

  test_mixinApplication_missing() async {
    await assertDiagnosticsFromMarkup(r'''
mixin class C<T> {}
class D = Object with [!C!];
''');
  }

  test_mixinApplication_withTypeArg() async {
    await assertNoDiagnostics(r'''
mixin class C<T> {}
class D = Object with C<int>;
''');
  }

  test_nonFunctionTypeAlias_explicitTypeArg() async {
    await assertNoDiagnostics('''
typedef List2<T> = List<T>;
void f(List2<int> a) {}
''');
  }

  test_nonFunctionTypeAlias_missingTypeArg() async {
    await assertDiagnosticsFromMarkup('''
typedef List2<T> = List<T>;
void f([!List2!] a) {}
''');
  }

  test_nonFunctionTypeAlias_optionalTypeArgs() async {
    await assertNoDiagnostics('''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef List2<T> = List<T>;
void f(List2 a) {}
''');
  }

  test_objectPattern() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case List():
  }
}
''');
  }

  test_parameter_default_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void f({[!List!] a = const []}) {}
''');
  }

  test_parameter_fieldFormal_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  Object a;
  C([!List!] this.a);
}
''');
  }

  test_parameter_functionTyped_parameter_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void f(void a([!List!] p)) {}
''');
  }

  test_parameter_functionTyped_returnType_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!List!] a()) {}
''');
  }

  test_parameter_primaryDeclaring_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
class C(final [!List!] a);
''');
  }

  test_parameter_simple_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!List!] a) {}
''');
  }

  test_parameter_super_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class C {
  Object a;
  C(this.a);
}
class D extends C {
  D([!List!] super.a);
}
''');
  }

  test_returnType_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
[!List!] f(int a) => [1, 2, 3];
''');
  }

  test_superclassWith_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
mixin class C<T> {}
class D extends Object with [!C!] {}
''');
  }

  test_superclassWith_withTypeArg() async {
    await assertNoDiagnostics(r'''
mixin class C<T> {}
class D extends Object with C<int> {}
''');
  }

  test_topLevelField_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
[!List!] a = [];
''');
  }

  test_topLevelField_optionalTypeArg() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
C a = C();
C get g => C();
void set s(C a) {}
''');
  }

  test_topLevelField_withTypeArg() async {
    await assertNoDiagnostics(r'''
List<int> a = [];
List<num> get g => [];
void set s(List<double> a) {}
''');
  }

  test_topLevelGetter_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
[!List!] get g => [];
''');
  }

  test_topLevelSetter_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
void set s([!List!] a) {}
''');
  }

  test_typeAlias_classic_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
typedef T F1<T>(T _);
[!F1!] func = (a) => a;
''');
  }

  test_typeAlias_modern_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
typedef F1<T> = T Function(T);
[!F1!] func = (a) => a;
''');
  }

  test_typeAlias_modern_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef T F1<T>(T _);
@optionalTypeArgs
typedef F2<T> = T Function(T);
F1 f1 = (a) => a;
F2 f2 = (a) => a;
''');
  }

  test_typeAlias_modern_withTypeArg() async {
    await assertNoDiagnostics(r'''
typedef T F1<T>(T _);
typedef F2<T> = T Function(T);
typedef F3 = T Function<T>(T);
F1<int> f1 = (a) => a;
F2<int> f2 = (a) => a;
F3 f3 = <T>(T a) => a;
''');
  }

  test_typeInClassDeclaration_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
mixin class C<T> {}
class D extends C {}
class E extends Object with C {}
class F = Object with C;
class G implements C {}
''');
  }

  test_typeInConstructorName() async {
    await assertNoDiagnostics(r'''
class C {
  C();
  C.named();
}

var c = C();
var d = C.named();
''');
  }

  test_typeInExtendedType_anonymous_missing() async {
    await assertDiagnosticsFromMarkup(r'''
extension on [!List!] {}
''');
  }

  test_typeInExtendedType_missing() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on [!List!] {}
''');
  }

  test_typeInExtendedType_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
extension E on C {}
extension on C {}
''');
  }

  test_typeInExtendedType_present() async {
    await assertNoDiagnostics(r'''
extension E<T> on List<T> {}
extension F on List<int> {}
''');
  }

  test_typeInInterface_missing() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {}
class D implements [!C!] {}
''');
  }

  test_typeInInterface_withTypeArg() async {
    await assertNoDiagnostics(r'''
class C<T> {}
class D implements C<int> {}
''');
  }

  test_typeInSuperclass_missing() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {}
class D extends [!C!] {}
''');
  }

  test_typeInSuperclass_withTypeArg() async {
    await assertNoDiagnostics(r'''
class C<T> {}
class D extends C<int> {}
''');
  }

  test_typeLiteral_raw() async {
    await assertNoDiagnostics(r'''
void f() {
  var t = List;
  print(t);
}
''');
  }

  test_typeParameterBound_missingTypeArg() async {
    await assertDiagnosticsFromMarkup(r'''
class C<T> {}
class D<T extends [!C!]> {}
''');
  }

  test_typeParameterBound_withTypeArg() async {
    await assertNoDiagnostics(r'''
class C<T> {}
class D<S, T extends C<S>> {}
''');
  }
}
