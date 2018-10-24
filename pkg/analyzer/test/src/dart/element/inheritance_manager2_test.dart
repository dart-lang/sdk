// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManager2Test);
  });
}

@reflectiveTest
class InheritanceManager2Test extends DriverResolutionTest {
  InheritanceManager2 manager;

  @override
  Future<void> resolveTestFile() async {
    await super.resolveTestFile();
    manager = new InheritanceManager2(
      result.unit.declaredElement.context.typeSystem,
    );
  }

  test_getInherited_closestSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

class X extends B {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getInherited('X', 'foo'),
      same(findElement.method('foo', of: 'B')),
    );
  }

  test_getInherited_interfaces() async {
    addTestFile('''
abstract class I {
  void foo();
}

abstrac class J {
  void foo();
}

class X implements I, J {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getInherited('X', 'foo'),
      same(findElement.method('foo', of: 'J')),
    );
  }

  test_getInherited_mixin() async {
    addTestFile('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class X extends A with M {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getInherited('X', 'foo'),
      same(findElement.method('foo', of: 'M')),
    );
  }

  test_getInherited_preferImplemented() async {
    addTestFile('''
class A {
  void foo() {}
}

class I {
  void foo() {}
}

class X extends A implements I {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getInherited('X', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  void test_getMember_() async {
    addTestFile('''
abstract class I1 {
  void f(int i);
}

abstract class I2 {
  void f(Object o);
}

abstract class C implements I1, I2 {}
''');
    await resolveTestFile();

    var memberType = manager.getMember(
      findElement.class_('C').type,
      new Name(null, 'f'),
    );
    assertElementTypeString(memberType, '(Object) → void');
  }

  test_preferLatest_mixin() async {
    addTestFile('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends A with M1, M2 implements I {}
''');
    await resolveTestFile();

    var member = manager.getMember(
      findElement.class_('X').type,
      new Name(null, 'foo'),
    );
    expect(member.element, findElement.method('foo', of: 'M2'));
  }

  test_preferLatest_superclass() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends B implements I {}
''');
    await resolveTestFile();

    var member = manager.getMember(
      findElement.class_('X').type,
      new Name(null, 'foo'),
    );
    expect(member.element, findElement.method('foo', of: 'B'));
  }

  test_preferLatest_this() async {
    addTestFile('''
class A {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends A implements I {
  void foo() {}
}
''');
    await resolveTestFile();

    var member = manager.getMember(
      findElement.class_('X').type,
      new Name(null, 'foo'),
    );
    expect(member.element, findElement.method('foo', of: 'X'));
  }

  ExecutableElement _getInherited(String className, String name) {
    var type = findElement.class_(className).type;
    return manager.getInherited(type, new Name(null, name)).element;
  }
}
