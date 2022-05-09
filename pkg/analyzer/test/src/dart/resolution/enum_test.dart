// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
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
  test_constructor_argumentList_contextType() async {
    await assertNoErrorsInCode(r'''
enum E {
  v([]);
  const E(List<int> a);
}
''');

    assertType(findNode.listLiteral('[]'), 'List<int>');
  }

  test_constructor_argumentList_namedType() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(<void Function(double)>[]);
  const E(Object a);
}
''');

    assertNamedType(
      findNode.namedType('double'),
      doubleElement,
      'double',
    );

    assertType(
      findNode.genericFunctionType('void Function'),
      'void Function(double)',
    );
  }

  test_constructor_generic_noTypeArguments_named() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v.named(42);
  const E.named(T a);
}
''');

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: elementMatcher(
        findElement.constructor('named'),
        substitution: {'T': 'int'},
      ),
    );

    assertParameterElement(
      findNode.integerLiteral('42'),
      elementMatcher(
        findElement.parameter('a'),
        substitution: {'T': 'int'},
      ),
    );
  }

  test_constructor_generic_noTypeArguments_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v(42);
  const E(T a);
}
''');

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: elementMatcher(
        findElement.enum_('E').unnamedConstructor,
        substitution: {'T': 'int'},
      ),
    );

    assertParameterElement(
      findNode.integerLiteral('42'),
      elementMatcher(
        findElement.parameter('a'),
        substitution: {'T': 'int'},
      ),
    );
  }

  test_constructor_generic_typeArguments_named() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v<double>.named(42);
  const E.named(T a);
}
''');

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: elementMatcher(
        findElement.constructor('named'),
        substitution: {'T': 'double'},
      ),
    );

    assertNamedType(
      findNode.namedType('double'),
      doubleElement,
      'double',
    );

    assertParameterElement(
      findNode.integerLiteral('42'),
      elementMatcher(
        findElement.parameter('a'),
        substitution: {'T': 'double'},
      ),
    );
  }

  test_constructor_notGeneric_named() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.named(42);
  const E.named(int a);
}
''');

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: findElement.constructor('named'),
    );

    assertParameterElement(
      findNode.integerLiteral('42'),
      findElement.parameter('a'),
    );
  }

  test_constructor_notGeneric_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(42);
  const E(int a);
}
''');

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: findElement.enum_('E').unnamedConstructor,
    );

    assertParameterElement(
      findNode.integerLiteral('42'),
      findElement.parameter('a'),
    );
  }

  test_constructor_notGeneric_unnamed_implicit() async {
    await assertNoErrorsInCode(r'''
enum E {
  v
}
''');

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: findElement.enum_('E').unnamedConstructor,
    );
  }

  test_constructor_unresolved_named() async {
    await assertErrorsInCode(r'''
enum E {
  v.named(42);
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED, 13, 5),
    ]);

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: null,
    );

    assertParameterElement(findNode.integerLiteral('42'), null);
  }

  test_constructor_unresolved_unnamed() async {
    await assertErrorsInCode(r'''
enum E {
  v(42);
  const E.named(int a);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED, 11, 1),
    ]);

    assertEnumConstant(
      findNode.enumConstantDeclaration('v'),
      element: findElement.field('v'),
      constructorElement: null,
    );

    assertParameterElement(findNode.integerLiteral('42'), null);
  }

  test_field() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  final foo = 42;
}
''');

    assertElement(
      findNode.variableDeclaration('foo ='),
      findElement.field('foo', of: 'E'),
    );
  }

  test_getter() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  T get foo => throw 0;
}
''');

    assertElement(
      findNode.methodDeclaration('get foo'),
      findElement.getter('foo', of: 'E'),
    );

    assertNamedType(
      findNode.namedType('T get'),
      findElement.typeParameter('T'),
      'T',
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

  test_interfaces() async {
    await assertNoErrorsInCode(r'''
class I {}
enum E implements I { // ref
  v;
}
''');

    assertNamedType(
      findNode.namedType('I { // ref'),
      findElement.class_('I'),
      'I',
    );
  }

  test_isEnumConstant() async {
    await assertNoErrorsInCode(r'''
enum E {
  a, b
}
''');

    expect(findElement.field('a').isEnumConstant, isTrue);
    expect(findElement.field('b').isEnumConstant, isTrue);

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
enum E {
  v;
  String toString() => 'E';
}
''');

    assertElement(
      findNode.methodDeclaration('toString'),
      findElement.method('toString', of: 'E'),
    );
  }

  test_mixins() async {
    await assertNoErrorsInCode(r'''
mixin M {}
enum E with M { // ref
  v;
}
''');

    assertNamedType(
      findNode.namedType('M { // ref'),
      findElement.mixin('M'),
      'M',
    );
  }

  test_mixins_inference() async {
    await assertNoErrorsInCode(r'''
mixin M1<T> {}
mixin M2<T> on M1<T> {}
enum E with M1<int>, M2 {
  v;
}
''');

    assertNamedType(
      findNode.namedType('M1<int>'),
      findElement.mixin('M1'),
      'M1<int>',
    );

    assertNamedType(
      findNode.namedType('M2 {'),
      findElement.mixin('M2'),
      'M2<int>',
    );
  }

  test_setter() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  set foo(T a) {}
}
''');

    assertElement(
      findNode.methodDeclaration('set foo'),
      findElement.setter('foo'),
    );

    assertElement(
      findNode.simpleFormalParameter('a) {}'),
      findElement.setter('foo').parameter('a'),
    );

    assertNamedType(
      findNode.namedType('T a'),
      findElement.typeParameter('T'),
      'T',
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
      element: typeProvider.enumElement!.getGetter('index')!,
      type: 'int',
    );
  }
}
