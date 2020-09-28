// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentDriverResolutionTest);
  });
}

@reflectiveTest
class CommentDriverResolutionTest extends PubPackageResolutionTest {
  test_error_unqualifiedReferenceToNonLocalStaticMember() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo() {}
}

/// [foo]
class B extends A {}
''');

    assertElement(
      findNode.simple('foo]'),
      findElement.method('foo', of: 'A'),
    );
  }

  test_identifier_beforeClass() async {
    await assertNoErrorsInCode(r'''
/// [foo]
class A {
  foo() {}
}
''');

    assertElement(
      findNode.simple('foo]'),
      findElement.method('foo'),
    );
  }

  test_identifier_beforeConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  /// [p]
  A(int p);
}''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeEnum() async {
    await assertNoErrorsInCode(r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''');

    assertElement(
      findNode.simple('Samurai]'),
      findElement.enum_('Samurai'),
    );
    assertElement(
      findNode.simple('int]'),
      intElement,
    );
    assertElement(
      findNode.simple('WITH_SWORD]'),
      findElement.getter('WITH_SWORD'),
    );
  }

  test_identifier_beforeFunction_blockBody() async {
    await assertNoErrorsInCode(r'''
/// [p]
foo(int p) {}
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeFunction_expressionBody() async {
    await assertNoErrorsInCode(r'''
/// [p]
foo(int p) => null;
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeFunctionTypeAlias() async {
    await assertNoErrorsInCode(r'''
/// [p]
typedef Foo(int p);
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeGenericTypeAlias() async {
    await assertNoErrorsInCode(r'''
/// Can resolve [T], [S], and [p].
typedef Foo<T> = Function<S>(int p);
''');

    assertElement(
      findNode.simple('T]'),
      findElement.typeParameter('T'),
    );
    assertElement(findNode.simple('S]'), findElement.typeParameter('S'));
    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeGetter() async {
    await assertNoErrorsInCode(r'''
/// [int]
get g => null;
''');

    assertElement(findNode.simple('int]'), intElement);
  }

  test_identifier_beforeMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  /// [p1]
  ma(int p1);
  
  /// [p2]
  mb(int p2);
  
  /// [p3] and [p4]
  mc(int p3, p4());
  
  /// [p5]
  md(int p5, {int p6});
}
''');

    assertElement(findNode.simple('p1]'), findElement.parameter('p1'));
    assertElement(findNode.simple('p2]'), findElement.parameter('p2'));
    assertElement(findNode.simple('p3]'), findElement.parameter('p3'));
    assertElement(findNode.simple('p4]'), findElement.parameter('p4'));
    assertElement(findNode.simple('p5]'), findElement.parameter('p5'));
  }

  test_identifier_parameter_functionTyped() async {
    await assertNoErrorsInCode(r'''
/// [bar]
foo(int bar()) {}
''');

    assertElement(
      findNode.simple('bar]'),
      findElement.parameter('bar'),
    );
  }

  test_identifier_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  /// [x] in A
  mA() {}
  set x(value) {}
}

class B extends A {
  /// [x] in B
  mB() {}
}
''');

    var x = findElement.setter('x', of: 'A');
    assertElement(findNode.simple('x] in A'), x);
    assertElement(findNode.simple('x] in B'), x);
  }

  test_new() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
  A.named();
}

/// [new A] or [new A.named]
main() {}
''');

    assertElement(
      findNode.simple('A]'),
      findElement.unnamedConstructor('A'),
    );
    assertElement(
      findNode.simple('A.named]'),
      findElement.class_('A'),
    );
    assertElement(
      findNode.simple('named]'),
      findElement.constructor('named', of: 'A'),
    );
  }
}
