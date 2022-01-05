// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentDriverResolution_PrefixedIdentifierTest);
    defineReflectiveTests(CommentDriverResolution_PropertyAccessTest);
    defineReflectiveTests(CommentDriverResolution_SimpleIdentifierTest);
  });
}

@reflectiveTest
class CommentDriverResolution_PrefixedIdentifierTest
    extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    // TODO(srawlins): improve coverage regarding constructors, operators, the
    // 'new' keyword, and members on an extension on a type variable
    // (`extension <T> on T`).
    await assertNoErrorsInCode('''
class A {
  A.named();
}

/// [A.named]
void f() {}
''');

    assertElement(findNode.simple('A.named]'), findElement.class_('A'));
    assertElement(findNode.simple('named]'), findElement.constructor('named'));
  }

  test_class_constructor_unnamedViaNew() async {
    await assertNoErrorsInCode('''
class A {
  A();
}

/// [A.new]
void f() {}
''');

    assertElement(findNode.simple('A.new'), findElement.class_('A'));
    assertElement(findNode.simple('new]'), findElement.unnamedConstructor('A'));
  }

  test_class_instanceGetter() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_class_instanceMethod() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_class_instanceSetter() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_class_staticGetter() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_class_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

/// [A.foo]
void f() {}
''');

    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_class_staticSetter() async {
    await assertNoErrorsInCode('''
class A {
  static set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_extension_instanceGetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_extension_instanceMethod() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {}
}

/// [E.foo]
void f() {}
''');

    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_extension_instanceSetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_extension_staticGetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  static int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_extension_staticMethod() async {
    await assertNoErrorsInCode('''
extension E on int {
  static void foo() {}
}

/// [E.foo]
void f() {}
''');

    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_extension_staticSetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  static set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }
}

@reflectiveTest
class CommentDriverResolution_PropertyAccessTest
    extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  A.named();
}

/// [self.A.named]
void f() {}
''');

    assertElement(findNode.simple('self.A.named'), findElement.prefix('self'));
    assertElement(findNode.simple('A.named]'), findElement.class_('A'));
    // TODO(srawlins): Set the type of named, and test it, here and below.
    assertElement(findNode.simple('named]'), findElement.constructor('named'));
  }

  test_class_constructor_unnamedViaNew() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  A();
}

/// [self.A.new]
void f() {}
''');

    assertElement(findNode.simple('self.A.new'), findElement.prefix('self'));
    assertElement(findNode.simple('A.new'), findElement.class_('A'));
    assertElement(findNode.simple('new]'), findElement.unnamedConstructor('A'));
  }

  test_class_instanceGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    assertElement(findNode.simple('self.A.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_class_instanceMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    assertElement(findNode.simple('self.A.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_class_instanceSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    assertElement(findNode.simple('self.A.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_class_staticGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  static int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    assertElement(findNode.simple('self.A.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_class_staticMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  static void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    assertElement(findNode.simple('self.A.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_class_staticSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  static set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    assertElement(findNode.simple('self.A.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('A.foo'), findElement.class_('A'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_extension_instanceGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    assertElement(findNode.simple('self.E.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_extension_instanceMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    assertElement(findNode.simple('self.E.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_extension_instanceSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    assertElement(findNode.simple('self.E.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_extension_staticGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    assertElement(findNode.simple('self.E.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.getter('foo'));
  }

  test_extension_staticMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    assertElement(findNode.simple('self.E.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.method('foo'));
  }

  test_extension_staticSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    assertElement(findNode.simple('self.E.foo'), findElement.prefix('self'));
    assertElement(findNode.simple('E.foo'), findElement.extension_('E'));
    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }
}

@reflectiveTest
class CommentDriverResolution_SimpleIdentifierTest
    extends PubPackageResolutionTest {
  test_associatedSetterAndGetter() async {
    await assertNoErrorsInCode('''
int get foo => 0;

set foo(int value) {}

/// [foo]
void f() {}
''');

    assertElement(findNode.simple('foo]'), findElement.topGet('foo'));
  }

  test_associatedSetterAndGetter_setterInScope() async {
    await assertNoErrorsInCode('''
extension E1 on int {
  int get foo => 0;
}

/// [foo]
extension E2 on int {
  set foo(int value) {}
}
''');

    assertElement(findNode.simple('foo]'), findElement.setter('foo'));
  }

  test_beforeClass() async {
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

  test_beforeConstructor() async {
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

  test_beforeEnum() async {
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

  test_beforeFunction_blockBody() async {
    await assertNoErrorsInCode(r'''
/// [p]
foo(int p) {}
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_beforeFunction_expressionBody() async {
    await assertNoErrorsInCode(r'''
/// [p]
foo(int p) => null;
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_beforeFunctionTypeAlias() async {
    await assertNoErrorsInCode(r'''
/// [p]
typedef Foo(int p);
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_beforeGenericTypeAlias() async {
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

  test_beforeGetter() async {
    await assertNoErrorsInCode(r'''
/// [int]
get g => null;
''');

    assertElement(findNode.simple('int]'), intElement);
  }

  test_beforeMethod() async {
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

  test_newKeyword() async {
    await assertErrorsInCode('''
class A {
  A();
  A.named();
}

/// [new A] or [new A.named]
main() {}
''', [
      error(HintCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, 38, 3),
      error(HintCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, 49, 3),
    ]);

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

  test_parameter_functionTyped() async {
    await assertNoErrorsInCode(r'''
/// [bar]
foo(int bar()) {}
''');

    assertElement(
      findNode.simple('bar]'),
      findElement.parameter('bar'),
    );
  }

  test_setter() async {
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

  test_unqualifiedReferenceToNonLocalStaticMember() async {
    await assertNoErrorsInCode('''
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
}
