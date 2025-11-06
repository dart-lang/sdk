// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(
      r'''
import 'a.dart';
const a = const A();
''',
      [error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 27, 9)],
    );

    var aLib = findElement2.import('package:test/a.dart').importedLibrary!;
    var aConstructor = aLib.getClass('A')!.constructors.single;
    var p = aConstructor.formalParameters.single;

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

  test_constList_withNullAwareElement() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
  foo() {
    return const [?A()];
  }
}
''',
      [error(StaticWarningCode.invalidNullAwareElement, 51, 1)],
    );
    assertType(findNode.listLiteral('const ['), 'List<A>');
  }

  test_constMap_withNullAwareKey() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
  foo() {
    return const {?A(): 0};
  }
}
''',
      [error(StaticWarningCode.invalidNullAwareMapEntryKey, 51, 1)],
    );
    assertType(findNode.setOrMapLiteral('const {'), 'Map<A, int>');
  }

  test_constMap_withNullAwareValue() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
  foo() {
    return const {0: ?A()};
  }
}
''',
      [error(StaticWarningCode.invalidNullAwareMapEntryValue, 54, 1)],
    );
    assertType(findNode.setOrMapLiteral('const {'), 'Map<int, A>');
  }

  test_constNotInitialized() async {
    await assertErrorsInCode(
      r'''
class B {
  const B(_);
}

class C extends B {
  static const a;
  const C() : super(a);
}
''',
      [error(CompileTimeErrorCode.constNotInitialized, 62, 1)],
    );
  }

  test_constSet_withNullAwareElement() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
  foo() {
    return const {?A()};
  }
}
''',
      [error(StaticWarningCode.invalidNullAwareElement, 51, 1)],
    );
    assertType(findNode.setOrMapLiteral('const {'), 'Set<A>');
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

    var v = findElement2.topVar('v');
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
    constructor: ConstructorMember
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
    await resolveTestCode(r'''
import 'a.dart';
''');

    var import_ = findElement2.importFind('package:test/a.dart');
    var a = import_.topVar('a');
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

    var import_ = findElement2.importFind('package:test/a.dart');
    var a = import_.topVar('a');
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

    var import_ = findElement2.importFind('package:test/a.dart');
    var a = import_.topVar('a');
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

    await resolveFile2(a);
    assertErrorsInResolvedUnit(result, []);

    var bElement = findElement2.field('b') as FieldElementImpl;
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
    var a = findElement2.topVar('a');
    expect(a.computeConstantValue()!.toIntValue(), 42);
  }
}
