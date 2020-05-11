// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessResolutionTest);
    defineReflectiveTests(PropertyAccessResolutionWithNnbdTest);
  });
}

@reflectiveTest
class PropertyAccessResolutionTest extends DriverResolutionTest {
  test_tearOff_method() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int a) {}
}

bar() {
  A().foo;
}
''');

    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.method('foo'));
    assertType(identifier, 'void Function(int)');
  }
}

@reflectiveTest
class PropertyAccessResolutionWithNnbdTest
    extends PropertyAccessResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;

  test_implicitCall_tearOff_nullable() async {
    await assertErrorsInCode('''
class A {
  int call() => 0;
}

class B {
  A? a;
}

int Function() foo() {
  return B().a; // ref
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 85, 5),
    ]);

    var identifier = findNode.simple('a; // ref');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'A?');
  }

  test_nullShorting_cascade() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
  int get bar => 0;
}

main(A? a) {
  a?..foo..bar;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('..foo'),
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('..bar'),
      element: findElement.getter('bar'),
      type: 'int',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_nullShorting_cascade2() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get foo => 0;
}

main() {
  A a = A()..foo?.isEven;
  a;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('..foo?'),
      element: findElement.getter('foo'),
      type: 'int?',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('.isEven'),
      element: intElement.getGetter('isEven'),
      type: 'bool',
    );

    assertType(findNode.cascade('A()'), 'A');
  }

  test_nullShorting_cascade3() async {
    await assertNoErrorsInCode(r'''
class A {
  A? get foo => this;
  A? get bar => this;
  A? get baz => this;
}

main() {
  A a = A()..foo?.bar?.baz;
  a;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('.foo'),
      element: findElement.getter('foo'),
      type: 'A?',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('.bar'),
      element: findElement.getter('bar'),
      type: 'A?',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('.baz'),
      element: findElement.getter('baz'),
      type: 'A?',
    );

    assertType(findNode.cascade('A()'), 'A');
  }

  test_nullShorting_cascade4() async {
    await assertNoErrorsInCode(r'''
A? get foo => A();

class A {
  A get bar => this;
  A? get baz => this;
  A get baq => this;
}

main() {
  foo?.bar?..baz?.baq;
}
''');

    assertSimpleIdentifier(
      findNode.simple('foo?'),
      element: findElement.topGet('foo'),
      type: 'A?',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('.bar'),
      element: findElement.getter('bar'),
      type: 'A?',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('.baz'),
      element: findElement.getter('baz'),
      type: 'A?',
    );

    assertPropertyAccess2(
      findNode.propertyAccess('.baq'),
      element: findElement.getter('baq'),
      type: 'A',
    );

    assertType(findNode.cascade('foo?'), 'A?');
  }
}
