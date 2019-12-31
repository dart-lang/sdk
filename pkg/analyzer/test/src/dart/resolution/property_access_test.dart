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
  test_get_error_abstractSuperMemberReference_mixinHasNoSuchMethod() async {
    await assertErrorsInCode('''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends Object with A {
  get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 104, 3),
    ]);

    var access = findNode.propertyAccess('foo; // ref');
    assertPropertyAccess(access, findElement.getter('foo', of: 'A'), 'int');
    assertSuperExpression(access.target);
  }

  test_get_error_abstractSuperMemberReference_OK_superHasNoSuchMethod() async {
    await resolveTestCode(r'''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends A {
  get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''');
    assertNoTestErrors();

    var access = findNode.propertyAccess('super.foo; // ref');
    assertPropertyAccess(access, findElement.getter('foo', of: 'A'), 'int');
    assertSuperExpression(access.target);
  }

  test_set_error_abstractSuperMemberReference_mixinHasNoSuchMethod() async {
    await assertErrorsInCode('''
class A {
  set foo(int a);
  noSuchMethod(im) {}
}

class B extends Object with A {
  set foo(v) => super.foo = v; // ref
  noSuchMethod(im) {}
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 107, 3),
    ]);

    var access = findNode.propertyAccess('foo = v; // ref');
    assertPropertyAccess(
      access,
      findElement.setter('foo', of: 'A'),
      'int',
    );
    assertSuperExpression(access.target);
  }

  test_set_error_abstractSuperMemberReference_OK_superHasNoSuchMethod() async {
    await resolveTestCode(r'''
class A {
  set foo(int a);
  noSuchMethod(im) => 1;
}

class B extends A {
  set foo(v) => super.foo = v; // ref
  noSuchMethod(im) => 2;
}
''');
    assertNoTestErrors();

    var access = findNode.propertyAccess('foo = v; // ref');
    assertPropertyAccess(
      access,
      findElement.setter('foo', of: 'A'),
      'int',
    );
    assertSuperExpression(access.target);
  }

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
}
