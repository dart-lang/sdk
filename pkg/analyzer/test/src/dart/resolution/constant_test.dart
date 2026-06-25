// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstantResolutionTest extends PubPackageResolutionTest {
  test_constantValue_defaultParameter_noDefaultValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A({int p});
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
const a = const A();
//        ^^^^^^^^^
// [diag.constConstructorParamTypeMismatch] A value of type 'Null' can't be assigned to a parameter of type 'int' in a const constructor.
''');

    var aLib = result.findElement
        .import('package:test/a.dart')
        .importedLibrary!;
    var aConstructor = aLib.getClass('A')!.constructors.single;
    var p = aConstructor.formalParameters.single;

    // To evaluate `const A()` we have to evaluate `{int p}`.
    // Even if its value is `null`.
    expect(p.isConstantEvaluated, isTrue);
    assertDartObjectText(p.computeConstantValue(), r'''
Null null
''');
  }

  test_constFactoryRedirection_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class I {
  const factory I(int f) = B;
}

class A implements I {
  final int f;

  const A(this.f);
}

class B extends A {
  const B(int f) : super(f);
}

@I(42)
main() {}
''');

    var node = result.findNode.annotation('@I');
    var value = node.elementAnnotation!.computeConstantValue()!;
    assertDartObjectText(value, r'''
B
  (super): A
    f: int 42
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::I::@constructor::new
    positionalArguments
      0: int 42
''');
  }

  test_constList_withNullAwareElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
  foo() {
    return const [?A()];
//                ^
// [diag.invalidNullAwareElement] The element can't be null, so the null-aware operator '?' is unnecessary.
  }
}
''');
    assertType(result.findNode.listLiteral('const ['), 'List<A>');
  }

  test_constMap_withNullAwareKey() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
  foo() {
    return const {?A(): 0};
//                ^
// [diag.invalidNullAwareMapEntryKey] The map entry key can't be null, so the null-aware operator '?' is unnecessary.
  }
}
''');
    assertType(result.findNode.setOrMapLiteral('const {'), 'Map<A, int>');
  }

  test_constMap_withNullAwareValue() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
  foo() {
    return const {0: ?A()};
//                   ^
// [diag.invalidNullAwareMapEntryValue] The map entry value can't be null, so the null-aware operator '?' is unnecessary.
  }
}
''');
    assertType(result.findNode.setOrMapLiteral('const {'), 'Map<int, A>');
  }

  test_constNotInitialized() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  const B(_);
}

class C extends B {
  static const a;
//             ^
// [diag.constNotInitialized] The constant 'a' must be initialized.
  const C() : super(a);
}
''');
  }

  test_constSet_withNullAwareElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
  foo() {
    return const {?A()};
//                ^
// [diag.invalidNullAwareElement] The element can't be null, so the null-aware operator '?' is unnecessary.
  }
}
''');
    assertType(result.findNode.setOrMapLiteral('const {'), 'Set<A>');
  }

  test_context_eliminateTypeVariables() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A({List<T> a = const []});
}
''');
    assertType(result.findNode.listLiteral('const []'), 'List<Never>');
  }

  test_context_eliminateTypeVariables_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {
  const A({List<T Function(U)> a = const []});
}
''');
    assertType(
      result.findNode.listLiteral('const []'),
      'List<Never Function(Object?)>',
    );
  }

  test_functionType_element_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = T Function(int);
const a = C<F<double>>();

class C<T> {
  const C();
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

const v = a;
''');

    var v = result.findElement.topVar('v');
    var value = v.computeConstantValue()!;

    dartObjectPrinterConfiguration.withTypeArguments = true;

    assertDartObjectText(value, r'''
C<double Function(int)>
  typeArguments
    double Function(int)
      alias: package:test/a.dart::@typeAlias::F
        typeArguments
          double
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::C::@constructor::new
      substitution: {T: double Function(int)}
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_imported_prefixedIdentifier_staticField_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = C.f;

class C {
  static const int f = 42;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
''');

    var import_ = result.findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a');
    assertDartObjectText(a.computeConstantValue(), r'''
int 42
  variable: package:test/a.dart::@topLevelVariable::a
''');
  }

  test_imported_prefixedIdentifier_staticField_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = E.f;

extension E on int {
  static const int f = 42;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
''');

    var import_ = result.findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a');
    assertDartObjectText(a.computeConstantValue(), r'''
int 42
  variable: package:test/a.dart::@topLevelVariable::a
''');
  }

  test_imported_prefixedIdentifier_staticField_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = M.f;

class C {}

mixin M on C {
  static const int f = 42;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
''');

    var import_ = result.findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a');
    assertDartObjectText(a.computeConstantValue(), r'''
int 42
  variable: package:test/a.dart::@topLevelVariable::a
''');
  }

  test_imported_super_defaultFieldFormalParameter() async {
    var a = getFile('$testPackageLibPath/a.dart');

    var results = await resolveFilesWithDiagnostics({
      a: r'''
import 'test.dart';

class A {
  static const B b = const B();

  final bool f1;
  final bool f2;

  const A({this.f1 = false}) : this.f2 = f1 && true;
}
''',
      testFile: r'''
import 'a.dart';

class B extends A {
  const B() : super();
}
''',
    });
    var aResult = results[a]!;

    var bElement = aResult.findElement.field('b');
    assertDartObjectText(bElement.computeConstantValue(), r'''
B
  (super): A
    f1: bool false
    f2: bool false
    constructorInvocation
      constructor: package:test/a.dart::@class::A::@constructor::new
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: package:test/a.dart::@class::A::@field::b
''');
  }

  test_local_prefixedIdentifier_staticField_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = E.f;

extension E on int {
  static const int f = 42;
}
''');
    var a = result.findElement.topVar('a');
    assertDartObjectText(a.computeConstantValue(), r'''
int 42
  variable: <testLibrary>::@topLevelVariable::a
''');
  }
}
