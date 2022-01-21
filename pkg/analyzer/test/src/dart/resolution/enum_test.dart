// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDriverResolutionTest);
  });
}

@reflectiveTest
class EnumDriverResolutionTest extends PubPackageResolutionTest {
  test_field() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  final foo = 42;
}
''');

    assertElement(
      findNode.variableDeclaration('foo ='),
      findElement.field('foo', of: 'E'),
    );
  }

  test_inference_listLiteral() async {
    await assertNoErrorsInCode(r'''
enum E1 {a, b}
enum E2 {a, b}

var v = [E1.a, E2.b];
''');

    var v = findElement.topVar('v');
    assertType(v.type, 'List<Enum>');
  }

  test_isEnumConstant() async {
    await assertNoErrorsInCode(r'''
enum E {
  a, b
}
''');

    expect(findElement.field('a').isEnumConstant, isTrue);
    expect(findElement.field('b').isEnumConstant, isTrue);

    expect(findElement.field('index').isEnumConstant, isFalse);
    expect(findElement.field('values').isEnumConstant, isFalse);
  }

  test_method() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  int foo<U>(T t, U u) => 0;
}
''');

    assertNamedType(
      findNode.namedType('T t'),
      findElement.typeParameter('T'),
      'T',
    );

    assertNamedType(
      findNode.namedType('U u'),
      findElement.typeParameter('U'),
      'U',
    );

    assertSimpleFormalParameter(
      findNode.simpleFormalParameter('T t'),
      element: findElement.parameter('t'),
    );

    assertSimpleFormalParameter(
      findNode.simpleFormalParameter('U u'),
      element: findElement.parameter('u'),
    );
  }

  test_method_toString() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  String toString() => 'E';
}
''');

    assertElement(
      findNode.methodDeclaration('toString'),
      findElement.method('toString', of: 'E'),
    );
  }

  test_value_underscore() async {
    await assertNoErrorsInCode(r'''
enum E { _ }

void f() {
  E._.index;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('index'),
      element: findElement.getter('index', of: 'E'),
      type: 'int',
    );
  }
}
