// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentDriverResolutionTest);
  });
}

@reflectiveTest
class CommentDriverResolutionTest extends DriverResolutionTest
    with ClassAliasResolutionMixin {}

mixin ClassAliasResolutionMixin implements ResolutionTest {
  test_error_unqualifiedReferenceToNonLocalStaticMember() async {
    addTestFile(r'''
class A {
  static void foo() {}
}

/// [foo]
class B extends A {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('foo]'),
      findElement.method('foo', of: 'A'),
    );
  }

  test_new() async {
    addTestFile(r'''
class A {
  A();
  A.named();
}

/// [new A] or [new A.named]
main() {}
''');
    await resolveTestFile();
    assertNoTestErrors();

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

  test_identifier_beforeConstructor() async {
    addTestFile(r'''
class A {
  /// [p]
  A(int p);
}''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeEnum() async {
    addTestFile(r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''');
    await resolveTestFile();
    assertNoTestErrors();

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
    addTestFile(r'''
/// [p]
foo(int p) {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_parameter_functionTyped() async {
    addTestFile(r'''
/// [bar]
foo(int bar()) {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('bar]'),
      findElement.parameter('bar'),
    );
  }

  test_identifier_beforeFunction_expressionBody() async {
    addTestFile(r'''
/// [p]
foo(int p) => null;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeFunctionTypeAlias() async {
    addTestFile(r'''
/// [p]
typedef Foo(int p);
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_identifier_beforeGenericTypeAlias() async {
    addTestFile(r'''
/// Can resolve [T], [S], and [p].
typedef Foo<T> = Function<S>(int p);
''');
    await resolveTestFile();
    assertNoTestErrors();

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
    addTestFile(r'''
/// [int]
get g => null;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(findNode.simple('int]'), intElement);
  }

  test_identifier_beforeMethod() async {
    addTestFile(r'''
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
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(findNode.simple('p1]'), findElement.parameter('p1'));
    assertElement(findNode.simple('p2]'), findElement.parameter('p2'));
    assertElement(findNode.simple('p3]'), findElement.parameter('p3'));
    assertElement(findNode.simple('p4]'), findElement.parameter('p4'));
    assertElement(findNode.simple('p5]'), findElement.parameter('p5'));
  }

  test_identifier_beforeClass() async {
    addTestFile(r'''
/// [foo]
class A {
  foo() {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertElement(
      findNode.simple('foo]'),
      findElement.method('foo'),
    );
  }

  test_identifier_setter() async {
    addTestFile(r'''
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
    await resolveTestFile();
    assertNoTestErrors();

    var x = findElement.setter('x', of: 'A');
    assertElement(findNode.simple('x] in A'), x);
    assertElement(findNode.simple('x] in B'), x);
  }
}
