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

  test_getMember() async {
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

  test_getMember_concrete() async {
    addTestFile('''
class A {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getConcrete('A', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_concrete_abstract() async {
    addTestFile('''
abstract class A {
  void foo();
}
''');
    await resolveTestFile();

    expect(_getConcrete('A', 'foo'), isNull);
  }

  test_getMember_concrete_fromMixedClass() async {
    addTestFile('''
class A {
  void foo() {}
}

class X with A {}
''');
    await resolveTestFile();

    expect(
      _getConcrete('X', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_concrete_fromMixedClass2() async {
    addTestFile('''
class A {
  void foo() {}
}

class B = Object with A;

class X with B {}
''');
    await resolveTestFile();

    expect(
      _getConcrete('X', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_concrete_fromMixedClass_skipObject() async {
    addTestFile('''
class A {
  String toString() => 'A';
}

class B {}

class X extends A with B {}
''');
    await resolveTestFile();

    expect(
      _getConcrete('X', 'toString'),
      same(findElement.method('toString', of: 'A')),
    );
  }

  test_getMember_concrete_fromMixin() async {
    addTestFile('''
mixin M {
  void foo() {}
}

class X with M {}
''');
    await resolveTestFile();

    expect(
      _getConcrete('X', 'foo'),
      same(findElement.method('foo', of: 'M')),
    );
  }

  test_getMember_concrete_fromSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {}

abstract class C extends B {}
''');
    await resolveTestFile();

    expect(
      _getConcrete('B', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );

    expect(
      _getConcrete('C', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_concrete_missing() async {
    addTestFile('''
abstract class A {}
''');
    await resolveTestFile();

    expect(_getConcrete('A', 'foo'), isNull);
  }

  test_getMember_concrete_noSuchMethod() async {
    addTestFile('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

abstract class C extends B {}
''');
    await resolveTestFile();

    expect(
      _getConcrete('B', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );

    expect(
      _getConcrete('C', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_concrete_noSuchMethod_mixin() async {
    addTestFile('''
class A {
  void foo();

  noSuchMethod(_) {}
}

abstract class B extends Object with A {}
''');
    await resolveTestFile();

    // noSuchMethod forwarders are not mixed-in.
    // https://github.com/dart-lang/sdk/issues/33553#issuecomment-424638320
    expect(_getConcrete('B', 'foo'), isNull);
  }

  test_getMember_concrete_noSuchMethod_moreSpecificSignature() async {
    addTestFile('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

class C extends B {
  void foo([a]);
}
''');
    await resolveTestFile();

    expect(
      _getConcrete('C', 'foo'),
      same(findElement.method('foo', of: 'C')),
    );
  }

  test_getMember_preferLatest_mixin() async {
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

  test_getMember_preferLatest_superclass() async {
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

  test_getMember_preferLatest_this() async {
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

  test_getMember_super_abstract() async {
    addTestFile('''
abstract class A {
  void foo();
}

class B extends A {
  noSuchMethod(_) {}
}
''');
    await resolveTestFile();

    expect(_getSuper('B', 'foo'), isNull);
  }

  test_getMember_super_forMixin_interface() async {
    addTestFile('''
abstract class A {
  void foo();
}

mixin M implements A {}
''');
    await resolveTestFile();

    expect(
      _getSuperForElement(findElement.mixin('M'), 'foo'),
      isNull,
    );
  }

  test_getMember_super_forMixin_superclassConstraint() async {
    addTestFile('''
abstract class A {
  void foo();
}

mixin M on A {}
''');
    await resolveTestFile();

    expect(
      _getSuperForElement(findElement.mixin('M'), 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_super_fromMixin() async {
    addTestFile('''
mixin M {
  void foo() {}
}

class X extends Object with M {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getSuper('X', 'foo'),
      same(findElement.method('foo', of: 'M')),
    );
  }

  test_getMember_super_fromSuper() async {
    addTestFile('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getSuper('B', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  test_getMember_super_missing() async {
    addTestFile('''
class A {}

class B extends A {}
''');
    await resolveTestFile();

    expect(_getSuper('B', 'foo'), isNull);
  }

  test_getMember_super_noSuchMember() async {
    addTestFile('''
class A {
  void foo();
  noSuchMethod(_) {}
}

class B extends A {
  void foo() {}
}
''');
    await resolveTestFile();

    expect(
      _getSuper('B', 'foo'),
      same(findElement.method('foo', of: 'A')),
    );
  }

  ExecutableElement _getConcrete(String className, String name) {
    var type = findElement.class_(className).type;
    return manager
        .getMember(type, new Name(null, name), concrete: true)
        ?.element;
  }

  ExecutableElement _getInherited(String className, String name) {
    var type = findElement.class_(className).type;
    return manager.getInherited(type, new Name(null, name)).element;
  }

  ExecutableElement _getSuper(String className, String name) {
    var element = findElement.class_(className);
    return _getSuperForElement(element, name);
  }

  ExecutableElement _getSuperForElement(ClassElement element, String name) {
    var type = element.type;
    return manager
        .getMember(type, new Name(null, name), forSuper: true)
        ?.element;
  }
}
