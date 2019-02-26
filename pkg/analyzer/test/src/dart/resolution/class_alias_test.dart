// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassAliasDriverResolutionTest);
  });
}

@reflectiveTest
class ClassAliasDriverResolutionTest extends DriverResolutionTest
    with ClassAliasResolutionMixin {}

mixin ClassAliasResolutionMixin implements ResolutionTest {
  test_defaultConstructor() async {
    addTestFile(r'''
class A {}
class M {}
class X = A with M;
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertConstructors(findElement.class_('X'), ['X() → X']);
  }

  test_element() async {
    addTestFile(r'''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var x = findElement.class_('X');

    assertTypeName(findNode.typeName('A with'), findElement.class_('A'), 'A');
    assertTypeName(findNode.typeName('B impl'), findElement.class_('B'), 'B');
    assertTypeName(findNode.typeName('C;'), findElement.class_('C'), 'C');

    assertElementTypeString(x.supertype, 'A');
    assertElementTypeStrings(x.mixins, ['B']);
    assertElementTypeStrings(x.interfaces, ['C']);
  }

  @failingTest
  test_implicitConstructors_const() async {
    addTestFile(r'''
class A {
  const A();
}

class M {}

class C = A with M;

const x = const C();
''');
    await resolveTestFile();
    assertNoTestErrors();
    // TODO(scheglov) add also negative test with fields
  }

  test_implicitConstructors_dependencies() async {
    addTestFile(r'''
class A {
  A(int i);
}
class M1 {}
class M2 {}

class C2 = C1 with M2;
class C1 = A with M1;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertConstructors(findElement.class_('C1'), ['C1(int i) → C1']);
    assertConstructors(findElement.class_('C2'), ['C2(int i) → C2']);
  }

  test_implicitConstructors_optionalParameters() async {
    addTestFile(r'''
class A {
  A.c1(int a);
  A.c2(int a, [int b, int c]);
  A.c3(int a, {int b, int c});
}

class M {}

class C = A with M;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertConstructors(
      findElement.class_('C'),
      [
        'C.c1(int a) → C',
        'C.c2(int a, [int b, int c]) → C',
        'C.c3(int a, {int b, int c}) → C'
      ],
    );
  }

  test_implicitConstructors_requiredParameters() async {
    addTestFile(r'''
class A<T extends num> {
  A(T x, T y);
}

class M {}

class B<E extends num> = A<E> with M;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertConstructors(findElement.class_('B'), ['B(E x, E y) → B<E>']);
  }
}
