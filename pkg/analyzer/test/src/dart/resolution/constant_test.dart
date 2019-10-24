// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantDriverTest);
  });
}

@reflectiveTest
class ConstantDriverTest extends DriverResolutionTest {
  test_constantValue_defaultParameter_noDefaultValue() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  const A({int p});
}
''');
    await resolveTestCode(r'''
import 'a.dart';
const a = const A();
''');
    assertNoTestErrors();

    var aLib = findElement.import('package:test/a.dart').importedLibrary;
    var aConstructor = aLib.getType('A').constructors.single;
    DefaultParameterElementImpl p = aConstructor.parameters.single;

    // To evaluate `const A()` we have to evaluate `{int p}`.
    // Even if its value is `null`.
    expect(p.isConstantEvaluated, isTrue);
    expect(p.constantValue.isNull, isTrue);
  }

  test_constFactoryRedirection_super() async {
    await resolveTestCode(r'''
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
    assertNoTestErrors();

    var node = findNode.annotation('@I');
    var value = node.elementAnnotation.constantValue;
    expect(value.getField('(super)').getField('f').toIntValue(), 42);
  }

  test_constNotInitialized() async {
    await resolveTestCode(r'''
class B {
  const B(_);
}

class C extends B {
  static const a;
  const C() : super(a);
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.CONST_NOT_INITIALIZED,
      CompileTimeErrorCode.CONST_NOT_INITIALIZED,
    ]);
  }

  test_functionType_element_typeArguments() async {
    newFile('/test/lib/a.dart', content: r'''
typedef F<T> = T Function(int);
const a = C<F<double>>();

class C<T> {
  const C();
}
''');
    await resolveTestCode(r'''
import 'a.dart';

const v = a;
''');
    assertNoTestErrors();

    var v = findElement.topVar('v') as ConstVariableElement;
    var value = v.computeConstantValue();

    var type = value.type as InterfaceType;
    assertElementTypeString(type, 'C<double Function(int)>');

    expect(type.typeArguments, hasLength(1));
    var typeArgument = type.typeArguments[0] as FunctionType;
    assertElementTypeString(typeArgument, 'double Function(int)');

    // The element and type arguments are available for the function type.
    var importFind = findElement.importFind('package:test/a.dart');
    var elementF = importFind.functionTypeAlias('F');
    expect(typeArgument.element, elementF.function);
    expect(typeArgument.element.enclosingElement, elementF);
    assertElementTypeStrings(typeArgument.typeArguments, ['double']);
  }
}
