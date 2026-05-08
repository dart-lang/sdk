// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLexemeAvoidFinalParameters);
    defineReflectiveTests(RemoveLexemeMultiTest);
    defineReflectiveTests(RemoveLexemeTest);
    defineReflectiveTests(RemoveLexemeVarWithNoTypeAnnotationTest);
  });
}

@reflectiveTest
class RemoveLexemeAvoidFinalParameters extends FixProcessorLintTest {
  @override
  List<String> get experiments => super.experiments
      .where(
        (experiment) => experiment != Feature.primary_constructors.enableString,
      )
      .toList();

  @override
  FixKind get kind => DartFixKind.removeLexeme;

  @override
  String get lintCode => 'avoid_final_parameters';

  Future<void> test_constructor_fieldFormal_noType() async {
    await resolveTestCode('''
class C {
  final int f;
  C(final this.f);
}
''');
    await assertHasFix('''
class C {
  final int f;
  C(this.f);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_fieldFormal_noType_named() async {
    await resolveTestCode('''
class C {
  final int f;
  C({required final this.f});
}
''');
    await assertHasFix('''
class C {
  final int f;
  C({required this.f});
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_fieldFormal_noType_optional() async {
    await resolveTestCode('''
class C {
  final int? f;
  C([final this.f]);
}
''');
    await assertHasFix('''
class C {
  final int? f;
  C([this.f]);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_fieldFormal_withType() async {
    await resolveTestCode('''
class C {
  final int f;
  C(final int this.f);
}
''');
    await assertHasFix('''
class C {
  final int f;
  C(int this.f);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_fieldFormal_withType_named() async {
    await resolveTestCode('''
class C {
  final int f;
  C({required final int this.f});
}
''');
    await assertHasFix('''
class C {
  final int f;
  C({required int this.f});
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_fieldFormal_withType_optional() async {
    await resolveTestCode('''
class C {
  final int? f;
  C([final int? this.f]);
}
''');
    await assertHasFix('''
class C {
  final int? f;
  C([int? this.f]);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_superFormal_noType() async {
    await resolveTestCode('''
class A {
  A(a);
}
class B extends A {
  B(final super.a);
}
''');
    await assertHasFix('''
class A {
  A(a);
}
class B extends A {
  B(super.a);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_superFormal_noType_named() async {
    await resolveTestCode('''
class A {
  A({required a});
}
class B extends A {
  B({required final super.a});
}
''');
    await assertHasFix('''
class A {
  A({required a});
}
class B extends A {
  B({required super.a});
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_superFormal_noType_optional() async {
    await resolveTestCode('''
class A {
  A([a = 0]);
}
class B extends A {
  B([final super.a = 0]);
}
''');
    await assertHasFix('''
class A {
  A([a = 0]);
}
class B extends A {
  B([super.a = 0]);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_superFormal_withType() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B(final int super.a);
}
''');
    await assertHasFix('''
class A {
  A(int a);
}
class B extends A {
  B(int super.a);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_superFormal_withType_named() async {
    await resolveTestCode('''
class A {
  A({required int a});
}
class B extends A {
  B({required final int super.a});
}
''');
    await assertHasFix('''
class A {
  A({required int a});
}
class B extends A {
  B({required int super.a});
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_constructor_superFormal_withType_optional() async {
    await resolveTestCode('''
class A {
  A([int a = 0]);
}
class B extends A {
  B([final int super.a = 0]);
}
''');
    await assertHasFix('''
class A {
  A([int a = 0]);
}
class B extends A {
  B([int super.a = 0]);
}
''', filter: lintNameFilter('avoid_final_parameters'));
  }

  Future<void> test_function_noType() async {
    await resolveTestCode('''
void f(final p) {}
''');
    await assertHasFix('''
void f(p) {}
''');
  }

  Future<void> test_function_noType_named() async {
    await resolveTestCode('''
void f({final p = 0}) {}
''');
    await assertHasFix('''
void f({p = 0}) {}
''');
  }

  Future<void> test_function_noType_optional() async {
    await resolveTestCode('''
void f([final p = 0]) {}
''');
    await assertHasFix('''
void f([p = 0]) {}
''');
  }

  Future<void> test_function_noType_requiredNamed() async {
    await resolveTestCode('''
void f({required final p}) {}
''');
    await assertHasFix('''
void f({required p}) {}
''');
  }

  Future<void> test_function_withType() async {
    await resolveTestCode('''
void f(final int p) {}
''');
    await assertHasFix('''
void f(int p) {}
''');
  }

  Future<void> test_function_withType_named() async {
    await resolveTestCode('''
void f({final int p = 0}) {}
''');
    await assertHasFix('''
void f({int p = 0}) {}
''');
  }

  Future<void> test_function_withType_optional() async {
    await resolveTestCode('''
void f([final int p = 0]) {}
''');
    await assertHasFix('''
void f([int p = 0]) {}
''');
  }

  Future<void> test_function_withType_requiredNamed() async {
    await resolveTestCode('''
void f({required final int p}) {}
''');
    await assertHasFix('''
void f({required int p}) {}
''');
  }

  Future<void> test_method_noType_named() async {
    await resolveTestCode('''
class C {
  void m({final p = 0}) {}
}
''');
    await assertHasFix('''
class C {
  void m({p = 0}) {}
}
''');
  }

  Future<void> test_method_noType_optional() async {
    await resolveTestCode('''
class C {
  void m([final p = 0]) {}
}
''');
    await assertHasFix('''
class C {
  void m([p = 0]) {}
}
''');
  }

  Future<void> test_method_noType_requiredNamed() async {
    await resolveTestCode('''
class C {
  void m({required final p}) {}
}
''');
    await assertHasFix('''
class C {
  void m({required p}) {}
}
''');
  }

  Future<void> test_method_withType() async {
    await resolveTestCode('''
class C {
  void m(final int p) {}
}
''');
    await assertHasFix('''
class C {
  void m(int p) {}
}
''');
  }

  Future<void> test_method_withType_named() async {
    await resolveTestCode('''
class C {
  void m({final int p = 0}) {}
}
''');
    await assertHasFix('''
class C {
  void m({int p = 0}) {}
}
''');
  }

  Future<void> test_method_withType_optional() async {
    await resolveTestCode('''
class C {
  void m([final int p = 0]) {}
}
''');
    await assertHasFix('''
class C {
  void m([int p = 0]) {}
}
''');
  }

  Future<void> test_method_withType_requiredNamed() async {
    await resolveTestCode('''
class C {
  void m({required final int p}) {}
}
''');
    await assertHasFix('''
class C {
  void m({required int p}) {}
}
''');
  }
}

@reflectiveTest
class RemoveLexemeMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeLexemeMulti;

  @SkippedTest() // TODO(scheglov): implement augmentation
  Future<void> test_singleFile() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

class A { }
''');

    await resolveTestCode('''
part of 'a.dart';

augment abstract class A {}

augment final class A {}
''');
    await assertHasFixAllFix(diag.augmentationModifierExtra, '''
part of 'a.dart';

augment class A {}

augment class A {}
''');
  }
}

@reflectiveTest
class RemoveLexemeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeLexeme;

  Future<void> test_abstract_static_field() async {
    await resolveTestCode('''
abstract class A {
  abstract static int? i;
}
''');
    await assertHasFix('''
abstract class A {
  static int? i;
}
''');
  }

  Future<void> test_abstract_static_method() async {
    await resolveTestCode('''
abstract class A {
  abstract static void m;
}
''');
    await assertHasFix('''
abstract class A {
  static void m;
}
''');
  }

  Future<void> test_abstractEnum() async {
    await resolveTestCode(r'''
abstract enum E {ONE}
''');
    await assertHasFix('''
enum E {ONE}
''');
  }

  Future<void> test_abstractTopLevelFunction_function() async {
    await resolveTestCode(r'''
abstract f(v) {}
''');
    await assertHasFix('''
f(v) {}
''');
  }

  Future<void> test_abstractTopLevelFunction_getter() async {
    await resolveTestCode(r'''
abstract get m {}
''');
    await assertHasFix('''
get m {}
''');
  }

  Future<void> test_abstractTopLevelFunction_setter() async {
    await resolveTestCode(r'''
abstract set m(v) {}
''');
    await assertHasFix('''
set m(v) {}
''');
  }

  Future<void> test_abstractTopLevelVariable() async {
    await resolveTestCode(r'''
abstract Object? o;
''');
    await assertHasFix('''
Object? o;
''');
  }

  Future<void> test_abstractTypeDef() async {
    await resolveTestCode(r'''
abstract typedef F();
''');
    await assertHasFix('''
typedef F();
''');
  }

  Future<void> test_class_sealed_mixin() async {
    await resolveTestCode('''
sealed mixin class A {}
''');
    await assertHasFix('''
mixin class A {}
''');
  }

  Future<void> test_constMethod() async {
    await resolveTestCode('''
const void m() {}
''');
    await assertHasFix('''
void m() {}
''');
  }

  Future<void> test_covariantInExtension() async {
    await resolveTestCode(r'''
extension E on String {
  void f({covariant int a = 0}) {}
}
''');
    await assertHasFix('''
extension E on String {
  void f({int a = 0}) {}
}
''');
  }

  Future<void> test_covariantMember() async {
    await resolveTestCode(r'''
class C {
  covariant c() {}
}
''');
    await assertHasFix('''
class C {
  c() {}
}
''');
  }

  Future<void> test_covariantTopLevelDeclaration_class() async {
    await resolveTestCode(r'''
covariant class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_covariantTopLevelDeclaration_enum() async {
    await resolveTestCode(r'''
covariant enum E { v }
''');
    await assertHasFix('''
enum E { v }
''');
  }

  Future<void> test_duplicatedModifier() async {
    await resolveTestCode(r'''
f() {
  const const c = '';
  c;
}
''');
    await assertHasFix('''
f() {
  const c = '';
  c;
}
''');
  }

  Future<void> test_externalClass() async {
    await resolveTestCode(r'''
external class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_externalEnum() async {
    await resolveTestCode(r'''
external enum E { o }
''');
    await assertHasFix('''
enum E { o }
''');
  }

  Future<void> test_externalTypedef() async {
    await resolveTestCode('''
external typedef T();
''');
    await assertHasFix('''
typedef T();
''');
  }

  Future<void> test_final_constructor() async {
    await resolveTestCode('''
class C {
  final C();
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_final_method() async {
    await resolveTestCode('''
class C {
  final m() {}
}
''');
    await assertHasFix('''
class C {
  m() {}
}
''');
  }

  Future<void> test_finalEnum() async {
    await resolveTestCode(r'''
final enum E {e}
''');
    await assertHasFix('''
enum E {e}
''');
  }

  Future<void> test_finalMixin() async {
    await resolveTestCode('''
final mixin M {}
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_finalMixinClass() async {
    await resolveTestCode('''
final mixin class A {}
''');
    await assertHasFix('''
mixin class A {}
''');
  }

  Future<void> test_getterConstructor() async {
    await resolveTestCode('''
class C {
  get C.c();
}
''');
    await assertHasFix('''
class C {
  C.c();
}
''');
  }

  Future<void> test_interfaceMixin() async {
    await resolveTestCode('''
interface mixin M {}
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_interfaceMixinClass() async {
    await resolveTestCode('''
interface mixin class A {}
''');
    await assertHasFix('''
mixin class A {}
''');
  }

  Future<void> test_invalidAsyncConstructorModifier() async {
    await resolveTestCode(r'''
class A {
  A() async {}
}
''');
    await assertHasFix('''
class A {
  A() {}
}
''');
  }

  Future<void> test_invalidModifierOnSetter() async {
    await resolveTestCode('''
class C {
  set x(v) async {}
}
''');
    await assertHasFix('''
class C {
  set x(v) {}
}
''');
  }

  Future<void> test_invalidUseOfCovariant() async {
    await resolveTestCode('''
class C {
  void m(void p(covariant int)) {}
}
''');
    await assertHasFix('''
class C {
  void m(void p(int)) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  Future<void> test_it() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

class A { }
''');

    await resolveTestCode('''
part of 'a.dart';

augment abstract class A {}
''');
    await assertHasFix('''
part of 'a.dart';

augment class A {}
''');
  }

  Future<void> test_literalWithNew() async {
    await resolveTestCode('''
var f = new <int,int>{};
''');
    await assertHasFix('''
var f = <int,int>{};
''');
  }

  Future<void> test_localFunctionDeclarationModifier_abstract() async {
    await resolveTestCode(r'''
class C {
  m() {
    abstract f() {}
    f();
  }
}
''');
    await assertHasFix('''
class C {
  m() {
    f() {}
    f();
  }
}
''');
  }

  Future<void> test_sealed_mixin() async {
    await resolveTestCode('''
sealed mixin M {}
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_setterConstructor() async {
    await resolveTestCode('''
class C {
  set C.c();
}
''');
    await assertHasFix('''
class C {
  C.c();
}
''');
  }

  Future<void> test_staticConstructor() async {
    await resolveTestCode('''
class C {
  static C.c(){}
}
''');
    await assertHasFix('''
class C {
  C.c(){}
}
''');
  }

  Future<void> test_staticOperator() async {
    await resolveTestCode('''
class C {
  static operator +(int x) => 1;
}
''');
    await assertHasFix('''
class C {
  operator +(int x) => 1;
}
''');
  }

  Future<void> test_staticTopLevelDeclaration_enum() async {
    await resolveTestCode(r'''
static enum E { v }
''');
    await assertHasFix('''
enum E { v }
''');
  }

  Future<void> test_topLevel_factoryDeclaration() async {
    await resolveTestCode(r'''
factory class C {}
''');
    await assertHasFix('''
class C {}
''');
  }
}

@reflectiveTest
class RemoveLexemeVarWithNoTypeAnnotationTest extends FixProcessorLintTest {
  @override
  List<String> get experiments => super.experiments
      .where(
        (experiment) => experiment != Feature.primary_constructors.enableString,
      )
      .toList();

  @override
  FixKind get kind => DartFixKind.removeLexeme;

  @override
  String get lintCode => 'var_with_no_type_annotation';

  Future<void> test_constructor_fieldFormal() async {
    await resolveTestCode('''
class C {
  final int f;
  C(var this.f);
}
''');
    await assertHasFix('''
class C {
  final int f;
  C(this.f);
}
''');
  }

  Future<void> test_constructor_fieldFormal_named() async {
    await resolveTestCode('''
class C {
  final int f;
  C({required var this.f});
}
''');
    await assertHasFix('''
class C {
  final int f;
  C({required this.f});
}
''');
  }

  Future<void> test_constructor_fieldFormal_optional() async {
    await resolveTestCode('''
class C {
  final int? f;
  C([var this.f]);
}
''');
    await assertHasFix('''
class C {
  final int? f;
  C([this.f]);
}
''');
  }

  Future<void> test_constructor_simple() async {
    await resolveTestCode('''
class C {
  C(var p);
}
''');
    await assertHasFix('''
class C {
  C(p);
}
''');
  }

  Future<void> test_enum_constructor() async {
    await resolveTestCode('''
enum E {
  v(1);
  const E(var p);
}
''');
    await assertHasFix('''
enum E {
  v(1);
  const E(p);
}
''');
  }

  Future<void> test_enum_method() async {
    await resolveTestCode('''
enum E {
  v;
  void m(var p) {}
}
''');
    await assertHasFix('''
enum E {
  v;
  void m(p) {}
}
''');
  }

  Future<void> test_extension_method() async {
    await resolveTestCode('''
extension E on int {
  void f(var p) {}
}
''');
    await assertHasFix('''
extension E on int {
  void f(p) {}
}
''');
  }

  Future<void> test_extensionType_method() async {
    await resolveTestCode('''
extension type E(int i) {
  void f(var p) {}
}
''');
    await assertHasFix('''
extension type E(int i) {
  void f(p) {}
}
''');
  }

  Future<void> test_function() async {
    await resolveTestCode('''
void f(var p) {}
''');
    await assertHasFix('''
void f(p) {}
''');
  }

  Future<void> test_function_named() async {
    await resolveTestCode('''
void f({var p = 0}) {}
''');
    await assertHasFix('''
void f({p = 0}) {}
''');
  }

  Future<void> test_function_named_noDefault() async {
    await resolveTestCode('''
void f({var p}) {}
''');
    await assertHasFix('''
void f({p}) {}
''');
  }

  Future<void> test_function_optional() async {
    await resolveTestCode('''
void f([var p = 0]) {}
''');
    await assertHasFix('''
void f([p = 0]) {}
''');
  }

  Future<void> test_function_optional_noDefault() async {
    await resolveTestCode('''
void f([var p]) {}
''');
    await assertHasFix('''
void f([p]) {}
''');
  }

  Future<void> test_function_requiredNamed() async {
    await resolveTestCode('''
void f({required var p}) {}
''');
    await assertHasFix('''
void f({required p}) {}
''');
  }

  Future<void> test_functionExpression() async {
    await resolveTestCode('''
var f = (var value) {};
''');
    await assertHasFix('''
var f = (value) {};
''');
  }

  Future<void> test_functionTyped_fieldFormal() async {
    await resolveTestCode('''
class C {
  final void Function(int) f;
  C(void this.f(var p));
}
''');
    await assertHasFix('''
class C {
  final void Function(int) f;
  C(void this.f(p));
}
''');
  }

  Future<void> test_functionTyped_parameter() async {
    await resolveTestCode('''
void f(void g(var p)) {}
''');
    await assertHasFix('''
void f(void g(p)) {}
''');
  }

  Future<void> test_functionTyped_superFormal() async {
    await resolveTestCode('''
class A {
  A(void f(int p));
}
class B extends A {
  B(void super.f(var p));
}
''');
    await assertHasFix('''
class A {
  A(void f(int p));
}
class B extends A {
  B(void super.f(p));
}
''');
  }

  Future<void> test_localFunction() async {
    await resolveTestCode('''
void f() {
  void g(var p) {}
  g(1);
}
''');
    await assertHasFix('''
void f() {
  void g(p) {}
  g(1);
}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class C {
  void m(var p) {}
}
''');
    await assertHasFix('''
class C {
  void m(p) {}
}
''');
  }

  Future<void> test_method_named() async {
    await resolveTestCode('''
class C {
  void m({var p = 0}) {}
}
''');
    await assertHasFix('''
class C {
  void m({p = 0}) {}
}
''');
  }

  Future<void> test_method_named_noDefault() async {
    await resolveTestCode('''
class C {
  void m({var p}) {}
}
''');
    await assertHasFix('''
class C {
  void m({p}) {}
}
''');
  }

  Future<void> test_method_optional() async {
    await resolveTestCode('''
class C {
  void m([var p = 0]) {}
}
''');
    await assertHasFix('''
class C {
  void m([p = 0]) {}
}
''');
  }

  Future<void> test_method_optional_noDefault() async {
    await resolveTestCode('''
class C {
  void m([var p]) {}
}
''');
    await assertHasFix('''
class C {
  void m([p]) {}
}
''');
  }

  Future<void> test_method_requiredNamed() async {
    await resolveTestCode('''
class C {
  void m({required var p}) {}
}
''');
    await assertHasFix('''
class C {
  void m({required p}) {}
}
''');
  }

  Future<void> test_method_setter() async {
    await resolveTestCode('''
class C {
  set f(var value) {}
}
''');
    await assertHasFix('''
class C {
  set f(value) {}
}
''');
  }

  Future<void> test_mixin_method() async {
    await resolveTestCode('''
mixin M {
  void f(var p) {}
}
''');
    await assertHasFix('''
mixin M {
  void f(p) {}
}
''');
  }

  Future<void> test_operator() async {
    await resolveTestCode('''
class C {
  int operator +(var other) => 0;
}
''');
    await assertHasFix('''
class C {
  int operator +(other) => 0;
}
''');
  }

  Future<void> test_setter() async {
    await resolveTestCode('''
set f(var value) {}
''');
    await assertHasFix('''
set f(value) {}
''');
  }

  Future<void> test_typedef() async {
    await resolveTestCode('''
typedef String Type(var value);
''');
    await assertHasFix('''
typedef String Type(value);
''');
  }

  Future<void> test_wildcard() async {
    await resolveTestCode('''
void f(var _) {}
''');
    await assertHasFix('''
void f(_) {}
''');
  }
}
