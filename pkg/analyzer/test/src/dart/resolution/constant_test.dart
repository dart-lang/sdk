// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantResolutionTest);
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
    await assertErrorsInCode(r'''
import 'a.dart';
const a = const A();
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 27, 9),
    ]);

    var aLib = findElement.import('package:test/a.dart').importedLibrary!;
    var aConstructor = aLib.getClass('A')!.constructors.single;
    var p = aConstructor.parameters.single as DefaultParameterElementImpl;

    // To evaluate `const A()` we have to evaluate `{int p}`.
    // Even if its value is `null`.
    expect(p.isConstantEvaluated, isTrue);
    expect(p.computeConstantValue()!.isNull, isTrue);
  }

  test_constFactoryRedirection_super() async {
    await assertNoErrorsInCode(r'''
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

    var node = findNode.annotation('@I');
    var value = node.elementAnnotation!.computeConstantValue()!;
    expect(value.getField('(super)')!.getField('f')!.toIntValue(), 42);
  }

  test_constNotInitialized() async {
    await assertErrorsInCode(r'''
class B {
  const B(_);
}

class C extends B {
  static const a;
  const C() : super(a);
}
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 62, 1),
    ]);
  }

  test_context_eliminateTypeVariables() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A({List<T> a = const []});
}
''');
    assertType(findNode.listLiteral('const []'), 'List<Never>');
  }

  test_context_eliminateTypeVariables_functionType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  const A({List<T Function(U)> a = const []});
}
''');
    assertType(
      findNode.listLiteral('const []'),
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
    await assertNoErrorsInCode(r'''
import 'a.dart';

const v = a;
''');

    var v = findElement.topVar('v') as ConstVariableElement;
    var value = v.computeConstantValue()!;

    dartObjectPrinterConfiguration.withTypeArguments = true;

    assertDartObjectText(value, r'''
C<double Function(int)>
  typeArguments
    double Function(int)
      alias: package:test/a.dart::<fragment>::@typeAlias::F
        typeArguments
          double
  variable: <testLibraryFragment>::@topLevelVariable::v
''');
  }

  test_imported_prefixedIdentifier_staticField_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = C.f;

class C {
  static const int f = 42;
}
''');
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  test_imported_prefixedIdentifier_staticField_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = E.f;

extension E on int {
  static const int f = 42;
}
''');
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  test_imported_prefixedIdentifier_staticField_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = M.f;

class C {}

mixin M on C {
  static const int f = 42;
}
''');
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement.importFind('package:test/a.dart');
    var a = import_.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }

  test_imported_super_defaultFieldFormalParameter() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'test.dart';

class A {
  static const B b = const B();

  final bool f1;
  final bool f2;

  const A({this.f1 = false}) : this.f2 = f1 && true;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

class B extends A {
  const B() : super();
}
''');

    result = await resolveFile(a);
    assertErrorsInResolvedUnit(result, []);

    var bElement = FindElement(result.unit).field('b') as ConstVariableElement;
    var bValue = bElement.evaluationResult as DartObjectImpl;
    var superFields = bValue.getField(GenericState.SUPERCLASS_FIELD);
    expect(superFields!.getField('f1')!.toBoolValue(), false);
  }

  test_local_prefixedIdentifier_staticField_extension() async {
    await assertNoErrorsInCode(r'''
const a = E.f;

extension E on int {
  static const int f = 42;
}
''');
    var a = findElement.topVar('a') as ConstVariableElement;
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }
}
