// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassElementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassElementTest extends PubPackageResolutionTest {
  test_lookUpInheritedConcreteGetter_declared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

class B extends A {
  int get foo => 0;
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  int get _foo => 0;
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('_foo'));
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends_private_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  // ignore:unused_element
  int get _foo => 0;
}

class B extends A {
  // ignore:unused_element
  int get _foo => 0;
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('_foo'),
      declaration: result.findElement.getter('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_declared_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

class B extends A {
  int get foo => 0;
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_abstract() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  int get foo;
}

abstract class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M {
  int get foo => 0;
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'M'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith2() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith3() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M1 {
  int get foo => 0;
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith4() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M {}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith5() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

mixin M1 {
  int get foo => 0;
}

mixin M2 {
  int get foo;
}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_hasWith_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M {
  static int get foo => 0;
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_hasExtends_withImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

class B {
  int get foo => 0;
}

class C extends A implements B {}
''');
    var C = result.findElement.class_('C');
    assertElement(
      C._lookUpInheritedConcreteGetter('foo'),
      declaration: result.findElement.getter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteGetter_hasImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_recursive() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteGetter_undeclared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedConcreteGetter('foo'));
  }

  test_lookUpInheritedConcreteMethod_declared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('_foo'));
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends_private_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  // ignore:unused_element
  void _foo() {}
}

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('_foo'),
      declaration: result.findElement.method('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_declared_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_abstract() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  void foo();
}

abstract class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith2() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith3() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith4() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M {}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith5() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo();
}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_hasWith_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M {
  static void foo() {}
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_hasExtends_withImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

class B {
  void foo() {}
}

class C extends A implements B {}
''');
    var C = result.findElement.class_('C');
    assertElement(
      C._lookUpInheritedConcreteMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteMethod_hasImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_recursive() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteMethod_undeclared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedConcreteMethod('foo'));
  }

  test_lookUpInheritedConcreteSetter_declared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  set _foo(int _) {}
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('_foo'));
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends_private_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  // ignore:unused_element
  set _foo(int _) {}
}

class B extends A {
  // ignore:unused_element
  set _foo(int _) {}
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('_foo'),
      declaration: result.findElement.setter('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_declared_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static set foo(int _) {}
}

class B extends A {
  set foo(int _) {}
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_abstract() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  set foo(int _);
}

abstract class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

mixin M {
  set foo(int _) {}
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'M'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith2() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith3() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

mixin M1 {
  set foo(int _) {}
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith4() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

mixin M {}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith5() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

mixin M1 {
  set foo(int _) {}
}

mixin M2 {
  set foo(int _);
}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_hasWith_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

mixin M {
  static set foo(int _) {}
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static set foo(int _) {}
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_hasExtends_withImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

class B {
  set foo(int _) {}
}

class C extends A implements B {}
''');
    var C = result.findElement.class_('C');
    assertElement(
      C._lookUpInheritedConcreteSetter('foo'),
      declaration: result.findElement.setter('foo', of: 'A'),
    );
  }

  test_lookUpInheritedConcreteSetter_hasImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

abstract class B implements A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_recursive() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedConcreteSetter_undeclared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedConcreteSetter('foo'));
  }

  test_lookUpInheritedMethod_declared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}
''');
    var A = result.findElement.class_('A');
    assertElementNull(A._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_declared_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedMethod('_foo'));
  }

  test_lookUpInheritedMethod_declared_hasExtends_private_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  // ignore:unused_element
  void _foo() {}
}

class B extends A {
  // ignore:unused_element
  void _foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('_foo'),
      declaration: result.findElement.method('_foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_declared_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_hasExtends() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith2() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M2'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith3() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {}

class B extends A with M1, M2 {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'M1'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith4() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M {}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_hasWith_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

mixin M {
  static void foo() {}
}

class B extends A with M {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

class B extends A {}
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_hasExtends_withImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

class B {
  void foo() {}
}

class C extends A implements B {}
''');
    var C = result.findElement.class_('C');
    assertElement(
      C._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasImplements() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    var B = result.findElement.class_('B');
    assertElement(
      B._lookUpInheritedMethod('foo'),
      declaration: result.findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_recursive() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
    var B = result.findElement.class_('B');
    assertElementNull(B._lookUpInheritedMethod('foo'));
  }

  test_lookUpInheritedMethod_undeclared() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
''');
    var A = result.findElement.class_('A');
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
