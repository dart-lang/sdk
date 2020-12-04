// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessResolutionTest);
    defineReflectiveTests(PropertyAccessResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class PropertyAccessResolutionTest extends PubPackageResolutionTest {
  test_extensionOverride_read() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

void f(A a) {
  E(a).foo;
}
''');

    var propertyAccess = findNode.propertyAccess('foo;');
    assertPropertyAccess2(
      propertyAccess,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSimpleIdentifier(
      propertyAccess.propertyName,
      readElement: findElement.getter('foo'),
      writeElement: null,
      type: 'int',
    );
  }

  test_extensionOverride_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
  set foo(num _) {}
}

void f(A a) {
  E(a).foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    assertAssignment(
      assignment,
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'num',
      );
    }
  }

  test_extensionOverride_write() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  set foo(int _) {}
}

void f(A a) {
  E(a).foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'int',
      );

      assertSimpleIdentifier(
        propertyAccess.propertyName,
        readElement: null,
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  (a).call;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('call;'),
      element: null,
      type: 'int Function(String)',
    );
  }

  test_instanceCreation_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f() {
  A().foo;
}
''');

    var propertyAccess = findNode.propertyAccess('foo;');
    assertPropertyAccess2(
      propertyAccess,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSimpleIdentifier(
      propertyAccess.propertyName,
      readElement: findElement.getter('foo'),
      writeElement: null,
      type: 'int',
    );
  }

  test_instanceCreation_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f() {
  A().foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    assertAssignment(
      assignment,
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_instanceCreation_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f() {
  A().foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'int',
      );

      assertSimpleIdentifier(
        propertyAccess.propertyName,
        readElement: null,
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_ofExtension_read() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

void f(A a) {
  A().foo;
}
''');

    var propertyAccess = findNode.propertyAccess('foo;');
    assertPropertyAccess2(
      propertyAccess,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSimpleIdentifier(
      propertyAccess.propertyName,
      readElement: findElement.getter('foo'),
      writeElement: null,
      type: 'int',
    );
  }

  test_ofExtension_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
  set foo(num _) {}
}

void f() {
  A().foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    assertAssignment(
      assignment,
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'num',
      );
    }
  }

  test_ofExtension_write() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  set foo(int _) {}
}

void f() {
  A().foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'int',
      );

      assertSimpleIdentifier(
        propertyAccess.propertyName,
        readElement: null,
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_super_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo;
  }
}
''');

    var propertyAccess = findNode.propertyAccess('super.foo');
    assertPropertyAccess2(
      propertyAccess,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSuperExpression(
      propertyAccess.target,
    );

    assertSimpleIdentifier(
      propertyAccess.propertyName,
      readElement: findElement.getter('foo'),
      writeElement: null,
      type: 'int',
    );
  }

  test_super_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo += 1;
  }
}
''');

    var assignment = findNode.assignment('foo += 1');
    assertAssignment(
      assignment,
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'int',
      );
    }

    assertSuperExpression(
      propertyAccess.target,
    );

    if (hasAssignmentLeftResolution) {
      assertSimpleIdentifier(
        propertyAccess.propertyName,
        readElement: findElement.getter('foo'),
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_super_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo = 1;
  }
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    if (hasAssignmentLeftResolution) {
      assertPropertyAccess2(
        propertyAccess,
        element: findElement.setter('foo'),
        type: 'int',
      );
    }

    assertSuperExpression(
      propertyAccess.target,
    );

    if (hasAssignmentLeftResolution) {
      assertSimpleIdentifier(
        propertyAccess.propertyName,
        readElement: null,
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_targetTypeParameter_dynamicBounded() async {
    await assertNoErrorsInCode('''
class A<T extends dynamic> {
  void f(T t) {
    (t).foo;
  }
}
''');

    var propertyAccess = findNode.propertyAccess('.foo');
    assertPropertyAccess2(
      propertyAccess,
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      propertyAccess.propertyName,
      readElement: null,
      writeElement: null,
      type: 'dynamic',
    );
  }

  test_targetTypeParameter_noBound() async {
    await resolveTestCode('''
class C<T> {
  void f(T t) {
    (t).foo;
  }
}
''');
    assertErrorsInResult(expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 33, 3),
      ],
      legacy: [
        error(CompileTimeErrorCode.UNDEFINED_GETTER, 37, 3),
      ],
    ));

    var propertyAccess = findNode.propertyAccess('.foo');
    assertPropertyAccess2(
      propertyAccess,
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      propertyAccess.propertyName,
      readElement: null,
      writeElement: null,
      type: 'dynamic',
    );
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
class PropertyAccessResolutionWithNullSafetyTest
    extends PropertyAccessResolutionTest with WithNullSafetyMixin {
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
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 85, 5),
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

void f(A? a) {
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
      readElement: findElement.topGet('foo'),
      writeElement: null,
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
