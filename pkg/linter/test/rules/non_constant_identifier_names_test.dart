// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantIdentifierNamesPatternsTest);
    defineReflectiveTests(NonConstantIdentifierNamesRecordsTest);
    defineReflectiveTests(NonConstantIdentifierNamesTest);
  });
}

@reflectiveTest
class NonConstantIdentifierNamesPatternsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.non_constant_identifier_names;

  test_extensionType_representationConstructorName() async {
    await assertDiagnostics(r'''
extension type e.Efg(int i) {}
''', [
      lint(17, 3),
    ]);
  }

  test_patternForStatement() async {
    await assertDiagnostics(r'''
void f() {
  for (var (AB, c) = (0, 1); AB <= 13; (AB, c) = (c, AB + c)) { }
}
''', [
      lint(23, 2),
    ]);
  }

  test_patternIfStatement() async {
    await assertDiagnostics(r'''
void f() {
  if ([1,2] case [int AB, int c]) { }
}
''', [
      lint(33, 2),
    ]);
  }

  test_patternIfStatement_recordField() async {
    await assertDiagnostics(r'''
void f(Object o) {
  if (o case (a: int AB, BC: int CD)) { }
}
''', [
      lint(40, 2),
      lint(52, 2),
    ]);
  }

  test_patternIfStatement_recordField_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  if (o case (:int AB, var b)) { }
}
''');
  }

  test_patternIfStatement_underscores() async {
    await assertNoDiagnostics(r'''
void f() {
  if ([1,2] case [int _, int _]) { }
}
''');
  }

  test_patternList_declaration() async {
    await assertDiagnostics(r'''
f() {
  var [__, foo_bar] = [1,2];
}
''', [
      lint(13, 2),
      lint(17, 7),
    ]);
  }

  test_patternList_declaration_underscore_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [_, a] = [1,2];
}
''');
  }

  test_patternList_wildCardPattern() async {
    await assertNoDiagnostics(r'''
f() {
  var a = 0;
  [_, a] = [1,2];
}
''');
  }

  test_patternRecordField() async {
    await assertDiagnostics(r'''
void f() {
  var (AB, ) = (1, );
}
''', [
      lint(18, 2),
    ]);
  }

  test_patternRecordField_shortcut_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  switch(o) {
    case (:int AB, var b):
  }
  switch(o) {
    case (:int AB?, var b):
    case (:int AB!, var b):
  }
}
''');
  }

  test_patternRecordField_underscores() async {
    await assertDiagnostics(r'''
void f() {
  var (___, ) = (1, );
}
''', [
      lint(18, 3),
    ]);
  }
}

@reflectiveTest
class NonConstantIdentifierNamesRecordsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.non_constant_identifier_names;

  test_recordFields() async {
    await assertDiagnostics(r'''
var a = (x: 1);
var b = (XX: 1);
''', [
      lint(25, 2),
    ]);
  }

  test_recordFields_fieldNameDuplicated() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var r = (a: 1, a: 2);
''', [
      // No Lint.
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 15, 1),
    ]);
  }

  test_recordFields_fieldNameFromObject() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var a = (hashCode: 1);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 9, 8),
    ]);
  }

  test_recordFields_fieldNamePositional() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var r = (0, $1: 2);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 12, 2),
    ]);
  }

  test_recordFields_privateFieldName() async {
    // This will produce a compile-time error and we don't want to over-report.
    await assertDiagnostics(r'''
var a = (_x: 1);
''', [
      // No Lint.
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 9, 2),
    ]);
  }

  test_recordTypeAnnotation_named() async {
    await assertDiagnostics(r'''
(int, {String SS, bool b})? triple;
''', [
      lint(14, 2),
    ]);
  }

  test_recordTypeAnnotation_positional() async {
    await assertDiagnostics(r'''
(int, String SS, bool) triple = (1,'', false);
''', [
      lint(13, 2),
    ]);
  }

  test_recordTypeDeclarations() async {
    await assertDiagnostics(r'''
var AA = (x: 1);
const BB = (x: 1);
''', [
      lint(4, 2),
    ]);
  }
}

@reflectiveTest
class NonConstantIdentifierNamesTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_LOCAL_VARIABLE,
        WarningCode.UNUSED_FIELD,
        WarningCode.UNUSED_ELEMENT,
      ];

  @override
  String get lintRule => LintNames.non_constant_identifier_names;

  test_42() async {
    // Generic function syntax is OK (#805).
    await assertNoDiagnostics(r'''
T scope<T>(T Function() run) {
  /* ... */
  return run();
}
''');
  }

  test_augmentedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A.Aa();
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment A.Aa();
}
''');
  }

  test_augmentedField() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int Xx = 1;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment int Xx = 2;
}
''');
  }

  test_augmentedFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void Ff() { }
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment void Ff() { }
''');
  }

  test_augmentedFunction_namedParam() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f({String? Ss}) { }
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment void f({String? Ss}) { }
''');
  }

  test_augmentedFunction_positionalParam() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f(String? Ss, [int? Xx]) { }
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment void f(String? Ss, [int? Xx]) { }
''', [
      lint(42, 2),
      lint(52, 2),
    ]);
  }

  test_augmentedGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int get Gg => 1;
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment int get Gg => 2;
}
''');
  }

  test_augmentedMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void Mm() { }
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment void Mm() { }
}
''');
  }

  test_augmentedMethod_namedParam() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void m({String? Ss}) { }
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment void m({String? Ss}) { }
}
''');
  }

  test_augmentedMethod_positionalParam() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void m(String? Ss, [int? Xx]) { }
}
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment void m(String? Ss, [int? Xx]) { }
}
''', [
      lint(62, 2),
      lint(72, 2),
    ]);
  }

  test_augmentedTopLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

int Xx = 1;
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment int Xx = 2;
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/5048')
  test_catch_underscores() async {
    await assertDiagnostics(r'''
f() {
  try {
  } catch(__, ___) {}
}
''', [
      lint(24, 2),
      error(WarningCode.UNUSED_CATCH_STACK, 28, 3),
      lint(28, 3),
    ]);
  }

  test_catch_underscores_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  try {
  } catch(__, ___) {}
}
''');
  }

  test_catch_wildcard() async {
    await assertNoDiagnostics(r'''
f() {
  try {
  } catch(_, _) {}
}
''');
  }

  test_catch_wildcard_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  try {
  } catch(_, __) {}
}
''');
  }

  test_catchVariable_allCaps() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (ZZZ) {}
}
''', [
      lint(27, 3),
    ]);
  }

  test_constructor_camelCase() async {
    await assertNoDiagnostics(r'''
class C {
  C.namedBar();
}
''');
  }

  test_constructor_factory() async {
    await assertDiagnostics(r'''
class C {
  C();
  factory C.Named() = C;
}
''', [
      lint(29, 5),
    ]);
  }

  test_constructor_multipleUnderscores() async {
    await assertNoDiagnostics(r'''
class C {
  C.__();
}
''');
  }

  test_constructor_private_lower() async {
    await assertNoDiagnostics(r'''
class C {
  C._named();
}
''');
  }

  test_constructor_private_title() async {
    await assertDiagnostics(r'''
class C {
  C._Named();
}
''', [
      lint(14, 6),
    ]);
  }

  test_constructor_private_upper() async {
    await assertDiagnostics(r'''
class C {
  C._N();
}
''', [
      lint(14, 2),
    ]);
  }

  test_constructor_singleUnderscore() async {
    await assertNoDiagnostics(r'''
class C {
  C._();
}
''');
  }

  test_constructor_snakeCase() async {
    await assertDiagnostics(r'''
class C {
  C.named_bar(); //LINT
}
''', [
      lint(14, 9),
    ]);
  }

  test_constructor_startsWithDollar() async {
    await assertNoDiagnostics(r'''
class C {
  C.$Named();
}
''');
  }

  test_constructor_title() async {
    await assertDiagnostics(r'''
class C {
  C.Named();
}
''', [
      lint(14, 5),
    ]);
  }

  test_constructor_underscores() async {
    await assertNoDiagnostics(r'''
class A {
  A._();
  A.__();
  A.___();
}
''');
  }

  test_constructor_underscores_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  A._();
  A.__();
  A.___();
}
''');
  }

  test_constructor_upper() async {
    await assertDiagnostics(r'''
class C {
  C.ZZZ();
}
''', [
      lint(14, 3),
    ]);
  }

  test_field_private_lower() async {
    await assertNoDiagnostics(r'''
class C {
  int? _x;
}
''');
  }

  test_field_private_underscoreLower() async {
    await assertNoDiagnostics(r'''
class C {
  int? __x;
}
''');
  }

  test_field_staticConst_upper() async {
    await assertNoDiagnostics(r'''
class C {
  static const ZZZ = 3;
}
''');
  }

  test_field_upper() async {
    await assertNoDiagnostics(r'''
class C {
  int? X; //OK
}
''');
  }

  test_forEachVariable() async {
    await assertDiagnostics(r'''
void f() {
  for (var ZZZ in []) {}
}
''', [
      lint(22, 3),
    ]);
  }

  test_forLoopVariable() async {
    await assertDiagnostics(r'''
void f() {
  for (var ZZZ = 0; ZZZ < 7; ++ZZZ) {}
}
''', [
      lint(22, 3),
    ]);
  }

  test_formalParams_underscores() async {
    await assertNoDiagnostics(r'''
f(int _, int __, int ___) {}
''');
  }

  test_formalParams_underscores_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

f(int _, int __) {}
''');
  }

  /// https://github.com/dart-lang/linter/issues/193
  test_ignoreSyntheticNodes() async {
    await assertDiagnostics(r'''
class C <E>{ }
C<int>;
''', [
      // No lint
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 15, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 15, 1),
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 21, 1),
    ]);
  }

  test_localVariable_const_allCaps() async {
    await assertNoDiagnostics(r'''
void f() {
  const ZZZ = 3;
}
''');
  }

  test_localVariable_multiple_upper() async {
    await assertDiagnostics(r'''
void f() {
  var ZZZ = 1,
      zzz = 1;
}
''', [
      lint(17, 3),
    ]);
  }

  test_localVariable_upper() async {
    await assertDiagnostics(r'''
void f() {
  var ZZZ = 1;
}
''', [
      lint(17, 3),
    ]);
  }

  test_method_instance_private_lower() async {
    await assertNoDiagnostics(r'''
class _F {
  void _m() {}
}
''');
  }

  test_method_snakeCase() async {
    await assertDiagnostics(r'''
class C {
  int foo_bar() => 7;
}
''', [
      lint(16, 7),
    ]);
  }

  test_method_static() async {
    await assertDiagnostics(r'''
class C {
  static Foo() {}
}
''', [
      lint(19, 3),
    ]);
  }

  test_parameter_fieldFormal_snakeCase() async {
    await assertDiagnostics(r'''
class C {
  final int bar_bar;
  C(this.bar_bar);
}
''', [
      lint(22, 7),
    ]);
  }

  test_parameter_named() async {
    await assertDiagnostics(r'''
class C {
  m({int? Foo}) {}
}
''', [
      lint(20, 3),
    ]);
  }

  test_parameter_optionalPositional() async {
    await assertDiagnostics(r'''
class C {
  m([int? Foo]) {}
}
''', [
      lint(20, 3),
    ]);
  }

  test_parameter_var() async {
    await assertDiagnostics(r'''
 class C {
  m(var Foo) {}
}
''', [
      lint(19, 3),
    ]);
  }

  test_topLevelFunction() async {
    await assertDiagnostics(r'''
void Main() {}
''', [
      lint(5, 4),
    ]);
  }

  test_topLevelFunction_private_camelCase() async {
    await assertNoDiagnostics(r'''
void _funBar() {}
''');
  }

  test_topLevelFunction_private_lower() async {
    await assertNoDiagnostics(r'''
void _fun() {} //OK
''');
  }

  test_topLevelFunction_private_snakeCase() async {
    await assertDiagnostics(r'''
void _fun_bar() {}
''', [
      lint(5, 8),
    ]);
  }

  test_topLevelVariable_constant_upper() async {
    await assertNoDiagnostics(r'''
const ZZZ = 4;
''');
  }

  test_topLevelVariable_snakeCase_withNumbers() async {
    await assertNoDiagnostics(r'''
var cell_0_0 = 7;
''');
  }

  test_topLevelVariable_upper() async {
    await assertDiagnostics(r'''
String ZZZ = '';
''', [
      lint(7, 3),
    ]);
  }
}
