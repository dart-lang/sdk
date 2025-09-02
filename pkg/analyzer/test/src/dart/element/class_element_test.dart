// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassElementTest);
  });
}

@reflectiveTest
class ClassElementTest extends PubPackageResolutionTest {
  test_lookUpInheritedConcreteGetter_declared() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

class B extends A {
  int get foo => 0;
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  int get _foo => 0;
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('_foo'));
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends_private_sameLibrary() async {
    await assertNoErrorsInCode('''
class A {
  // ignore:unused_element
  int get _foo => 0;
}

class B extends A {
  // ignore:unused_element
  int get _foo => 0;
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('_foo'),
      declaration: findElement2.getter('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
}

class B extends A {
  int get foo => 0;
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_abstract() async {
    await assertNoErrorsInCode('''
abstract class A {
  int get foo;
}

abstract class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

mixin M {
  int get foo => 0;
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'M'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith2() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

mixin M1 {
  int get foo => 0;
}

mixin M2 {
  int get foo => 0;
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith3() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

mixin M1 {
  int get foo => 0;
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith4() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

mixin M {}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith5() async {
    await assertNoErrorsInCode('''
class A {}

mixin M1 {
  int get foo => 0;
}

mixin M2 {
  int get foo;
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith_static() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

mixin M {
  static int get foo => 0;
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_hasExtends_withImplements() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

class B {
  int get foo => 0;
}

class C extends A implements B {}
''');
    var C = findElement2.class_('C');
    assertElement(
      C._lookUpInheritedConcreteGetter('foo'),
      declaration: findElement2.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasImplements() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_recursive() async {
    await assertErrorsInCode(
      '''
class A extends B {}
class B extends A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 27, 1),
      ],
    );
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_undeclared() async {
    await assertNoErrorsInCode('''
class A {}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteMethod_declared() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('_foo'));
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends_private_sameLibrary() async {
    await assertNoErrorsInCode('''
class A {
  // ignore:unused_element
  void _foo() {}
}

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('_foo'),
      declaration: findElement2.method('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_abstract() async {
    await assertNoErrorsInCode('''
abstract class A {
  void foo();
}

abstract class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'M'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith2() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo() {}
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith3() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith4() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M {}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith5() async {
    await assertNoErrorsInCode('''
class A {}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo();
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith_static() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M {
  static void foo() {}
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_hasExtends_withImplements() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B {
  void foo() {}
}

class C extends A implements B {}
''');
    var C = findElement2.class_('C');
    assertElement(
      C._lookUpInheritedConcreteMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasImplements() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_recursive() async {
    await assertErrorsInCode(
      '''
class A extends B {}
class B extends A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 27, 1),
      ],
    );
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_undeclared() async {
    await assertNoErrorsInCode('''
class A {}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteSetter_declared() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  set _foo(int _) {}
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('_foo'));
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends_private_sameLibrary() async {
    await assertNoErrorsInCode('''
class A {
  // ignore:unused_element
  set _foo(int _) {}
}

class B extends A {
  // ignore:unused_element
  set _foo(int _) {}
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('_foo'),
      declaration: findElement2.setter('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static set foo(int _) {}
}

class B extends A {
  set foo(int _) {}
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_abstract() async {
    await assertNoErrorsInCode('''
abstract class A {
  set foo(int _);
}

abstract class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

mixin M {
  set foo(int _) {}
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'M'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith2() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

mixin M1 {
  set foo(int _) {}
}

mixin M2 {
  set foo(int _) {}
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith3() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

mixin M1 {
  set foo(int _) {}
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith4() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

mixin M {}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith5() async {
    await assertNoErrorsInCode('''
class A {}

mixin M1 {
  set foo(int _) {}
}

mixin M2 {
  set foo(int _);
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith_static() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

mixin M {
  static set foo(int _) {}
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static set foo(int _) {}
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_hasExtends_withImplements() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

class B {
  set foo(int _) {}
}

class C extends A implements B {}
''');
    var C = findElement2.class_('C');
    assertElement(
      C._lookUpInheritedConcreteSetter('foo'),
      declaration: findElement2.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasImplements() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

abstract class B implements A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_recursive() async {
    await assertErrorsInCode(
      '''
class A extends B {}
class B extends A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 27, 1),
      ],
    );
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_undeclared() async {
    await assertNoErrorsInCode('''
class A {}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedMethod_declared() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_declared_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedMethod('_foo'));
  }

  test_lookUpInheritedMethod_declared_hasExtends_private_sameLibrary() async {
    await assertNoErrorsInCode('''
class A {
  // ignore:unused_element
  void _foo() {}
}

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('_foo'),
      declaration: findElement2.method('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_declared_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'M'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith2() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo() {}
}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith3() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith4() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M {}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith_static() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

mixin M {
  static void foo() {}
}

class B extends A with M {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

class B extends A {}
''');
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_hasExtends_withImplements() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B {
  void foo() {}
}

class C extends A implements B {}
''');
    var C = findElement2.class_('C');
    assertElement(
      C._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasImplements() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    var B = findElement2.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement2.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_recursive() async {
    await assertErrorsInCode(
      '''
class A extends B {}
class B extends A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 27, 1),
      ],
    );
    var B = findElement2.class_('B');
    assertElementNull(B._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_undeclared() async {
    await assertNoErrorsInCode('''
class A {}
''');
    var A = findElement2.class_('A');
    assertElementNull(A._lookUpInheritedMethod('foo'));
  }
}

extension on ClassElement {
  PropertyAccessorElement? _lookUpInheritedConcreteGetter(String name) {
    return (this as InterfaceElementImpl).lookUpInheritedConcreteGetter(
      name,
      library,
    );
  }

  MethodElement? _lookUpInheritedConcreteMethod(String name) {
    return (this as InterfaceElementImpl).lookUpInheritedConcreteMethod(
      name,
      library,
    );
  }

  PropertyAccessorElement? _lookUpInheritedConcreteSetter(String name) {
    return (this as InterfaceElementImpl).lookUpInheritedConcreteSetter(
      name,
      library,
    );
  }

  MethodElement? _lookUpInheritedMethod(String name) {
    return lookUpInheritedMethod(methodName: name, library: library);
  }
}
