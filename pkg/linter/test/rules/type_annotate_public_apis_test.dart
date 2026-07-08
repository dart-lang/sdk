// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  // TODO(srawlins): Add tests with enums, unnamed extensions.
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAnnotatePublicApisTest);
  });
}

@reflectiveTest
class TypeAnnotatePublicApisTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.type_annotate_public_apis;

  test_augmentationClass_field() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A { }
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment class A {
  var [!i!];
}
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentationClass_method() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A { }
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment class A {
  void f([!x!]) { }
}
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentationTopLevelFunction() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

void f([!x!]) { }
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  test_augmentationTopLevelVariable() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

var [!x!];
''');
    await assertNoDiagnosticsInFile(a.path);
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There is a diagnostic in b.dart.',
  )
  // TODO(scheglov): implement augmentation
  test_augmentedField() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment var x;
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class A {
  var [!x!];
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedMethod() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {
  augment void f(x);
}
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

class A {
  void f([!x!]) { }
}
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_augmentedTopLevelFunction() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment void f(x);
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

void f([!x!]) { }
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There is a diagnostic in b.dart.',
  )
  // TODO(scheglov): implement augmentation
  test_augmentedTopLevelVariable() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment var x;
''');

    await assertDiagnosticsFromMarkup(r'''
part 'b.dart';

var [!x!];
''');
    await assertNoDiagnosticsInFile(b.path);
  }

  test_enumConstructor_parameterMissingType() async {
    await assertNoDiagnostics(r'''
enum E {
  one(0);

  const E(p);
}
''');
  }

  test_enumConstructor_primary_parameterHasType() async {
    await assertNoDiagnostics(r'''
enum E(int p) {
  one(0)
}
''');
  }

  test_enumConstructor_primary_parameterMissingType() async {
    await assertNoDiagnostics(r'''
enum E(p) {
  one(0)
}
''');
  }

  test_enumConstructor_primary_parameterMissingType_declaring() async {
    await assertNoDiagnostics(r'''
enum E(final p) {
  one(0)
}
''');
  }

  test_instanceConstructor_namedParameterHasType() async {
    await assertNoDiagnostics(r'''
class A {
  A({int? p});
}
''');
  }

  test_instanceConstructor_namedParameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A({[!p!]});
}
''');
  }

  test_instanceConstructor_optionalPositionalParameterHasType() async {
    await assertNoDiagnostics(r'''
class A {
  A([int? p]);
}
''');
  }

  test_instanceConstructor_optionalPositionalParameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A([[!p!]]);
}
''');
  }

  test_instanceConstructor_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A([!p!]);
}
''');
  }

  test_instanceConstructor_positionalParameterHasType() async {
    await assertNoDiagnostics(r'''
class A {
  A(int p);
}
''');
  }

  test_instanceConstructor_primary_parameterHasType() async {
    await assertNoDiagnostics(r'''
class A({int? p});
''');
  }

  test_instanceConstructor_primary_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A({[!p!]});
''');
  }

  test_instanceConstructor_primary_private_parameterMissingType() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element_parameter
class A._({p});
''');
  }

  test_instanceConstructor_privateClass_publicUnnamed_parameterMissingType() async {
    await assertNoDiagnostics(r'''
class _A {
  _A(p);
}
''');
  }

  test_instanceConstructor_privateNamed_parameterMissingType() async {
    await assertNoDiagnostics(r'''
class A {
  A._(p);
}
''');
  }

  test_instanceConstructor_requiredNamedParameterHasType() async {
    await assertNoDiagnostics(r'''
class A {
  A({required int p});
}
''');
  }

  test_instanceConstructor_requiredNamedParameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A({[!required p!]});
}
''');
  }

  test_instanceField_onClass_hasInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  final x = 0;
}
''');
  }

  test_instanceField_onClass_hasVar_noInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  var [!x!];
}
''');
  }

  test_instanceField_onClass_inDeclarationList() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  // ignore: unused_field
  var [!x!], _y;
}
''');
  }

  test_instanceField_onClass_noInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  final x = 0;
}
''');
  }

  test_instanceField_onClass_nullInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  final [!n!] = null;
}
''');
  }

  test_instanceField_onClass_originPrimaryConstructor_typed() async {
    await assertNoDiagnostics(r'''
class A(var int x);
''');
  }

  test_instanceField_onClass_originPrimaryConstructor_untyped() async {
    await assertDiagnosticsFromMarkup(r'''
class A([!var x!]);
''');
  }

  test_instanceGetter_onClass() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 42;
}
''');
  }

  test_instanceGetter_onClass_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  get [!x!] => 42;
}
''');
  }

  test_instanceGetter_onExtension_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on int {
  get [!x!] => 0;
}
''');
  }

  test_instanceMethod_onClass_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  [!m!]() {}
}
''');
  }

  test_instanceMethod_onClass_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m([!x!]) {}
}
''');
  }

  test_instanceMethod_onExtension_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on int {
  [!f!]() {}
}
''');
  }

  test_instanceMethod_onExtension_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on int {
  void m([!p!]) {}
}
''');
  }

  test_instanceMethod_onExtensionType_noReturnType() async {
    // One test should be sufficient to verify extension type
    // support as the logic is implemented commonly for all members.
    await assertDiagnosticsFromMarkup(r'''
extension type E(int i) {
  [!m!]() {}
}
''');
  }

  test_instanceMethod_parameterNameIsMultipleUnderscores() async {
    await assertNoDiagnostics(r'''
class A {
  void m(__) {}
}
''');
  }

  test_instanceMethod_parameterNameIsUnderscore() async {
    await assertNoDiagnostics(r'''
class A {
  void m(_) {}
}
''');
  }

  test_instanceOperator_binary_hasTypes() async {
    await assertNoDiagnostics(r'''
class A {
  A operator +(A a) => a;
}
''');
  }

  test_instanceOperator_binary_noParameterType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A operator +([!a!]) => a;
}
''');
  }

  test_instanceOperator_binary_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  operator [!+!](A a) => a;
}
''');
  }

  test_instanceOperator_indexAssignment_hasTypes() async {
    await assertNoDiagnostics(r'''
class A {
  void operator []=(A a, A b) {}
}
''');
  }

  test_instanceOperator_indexAssignment_noParameterType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void operator []=([!a!], A b) {}
}
''');
  }

  test_instanceOperator_indexAssignment_noReturnType() async {
    await assertNoDiagnostics(r'''
class A {
  operator []=(A a, A b) {}
}
''');
  }

  test_instanceSetter_noReturnType() async {
    await assertNoDiagnostics(r'''
class A {
  set x(int p) {}
}
''');
  }

  test_instanceSetter_onClass_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  set x([!p!]) {}
}
''');
  }

  test_instanceSetter_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on int {
  set x([!p!]) {}
}
''');
  }

  test_instanceSetter_private_parameterMissingType() async {
    await assertNoDiagnostics(r'''
extension E on int {
  // ignore: unused_element
  set _x(p) {}
}
''');
  }

  test_localFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_element
  void g(x) {}
}
''');
  }

  test_newSyntax_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  new([!p!]);
}
''');
  }

  test_staticConstField_hasInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static const x = '';
}
''');
  }

  test_staticField_hasInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static final x = 3;
}
''');
  }

  test_staticField_noInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static final x = 0;
}
''');
  }

  test_staticField_nullInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  static final [!x!] = null;
}
''');
  }

  test_staticField_withInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  static final x = 0;
}
''');
  }

  test_staticMethod_onClass_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  static [!m!]() {}
}
''');
  }

  test_staticMethod_onClass_parameterHasVar() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
class A {
  static void m([!var p!]) {}
}
''');
  }

  test_staticMethod_onClass_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  static void m([!p!]) {}
}
''');
  }

  test_topLevelConst() async {
    await assertNoDiagnostics(r'''
const x = '';
''');
  }

  test_topLevelFunction_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
[!f!]() {}
''');
  }

  test_topLevelFunction_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
void f([!x!]) {}
''');
  }

  test_topLevelGetter_hasReturnType() async {
    await assertNoDiagnostics(r'''
int get x => 42;
''');
  }

  test_topLevelGetter_noReturnType() async {
    await assertDiagnosticsFromMarkup(r'''
get [!x!] => 42;
''');
  }

  test_topLevelSetter_parameterHasType() async {
    await assertNoDiagnostics(r'''
set x(int p) {}
''');
  }

  test_topLevelSetter_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
set x([!p!]) {}
''');
  }

  test_typedefLegacy_parameterMissingType() async {
    await assertDiagnosticsFromMarkup(r'''
typedef [!F!](x);
''');
  }

  test_typedefLegacy_private_parameterHasType() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
typedef _F(int value);
''');
  }

  test_typedefLegacy_private_parameterMissingType() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
typedef void _F(value);
''');
  }
}
