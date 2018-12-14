// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessResolutionTest);
  });
}

@reflectiveTest
class PropertyAccessResolutionTest extends DriverResolutionTest {
  test_get_error_abstractSuperMemberReference_mixinHasNoSuchMethod() async {
    addTestFile('''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends Object with A {
  get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var access = findNode.propertyAccess('foo; // ref');
    assertPropertyAccess(access, findElement.getter('foo', of: 'A'), 'int');
    assertSuperExpression(access.target);
  }

  test_get_error_abstractSuperMemberReference_OK_superHasNoSuchMethod() async {
    addTestFile(r'''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends A {
  get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var access = findNode.propertyAccess('super.foo; // ref');
    assertPropertyAccess(access, findElement.getter('foo', of: 'A'), 'int');
    assertSuperExpression(access.target);
  }

  test_set_error_abstractSuperMemberReference_mixinHasNoSuchMethod() async {
    addTestFile('''
class A {
  set foo(int a);
  noSuchMethod(im) {}
}

class B extends Object with A {
  set foo(v) => super.foo = v; // ref
  noSuchMethod(im) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);

    var access = findNode.propertyAccess('foo = v; // ref');
    assertPropertyAccess(
      access,
      findElement.setter('foo', of: 'A'),
      'int',
    );
    assertSuperExpression(access.target);
  }

  test_set_error_abstractSuperMemberReference_OK_superHasNoSuchMethod() async {
    addTestFile(r'''
class A {
  set foo(int a);
  noSuchMethod(im) => 1;
}

class B extends A {
  set foo(v) => super.foo = v; // ref
  noSuchMethod(im) => 2;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var access = findNode.propertyAccess('foo = v; // ref');
    assertPropertyAccess(
      access,
      findElement.setter('foo', of: 'A'),
      'int',
    );
    assertSuperExpression(access.target);
  }
}
