// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassElementTest);
  });
}

@reflectiveTest
class ClassElementTest extends PubPackageResolutionTest {
  test_lookUpInheritedMethod_declared() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}
''');
    var A = findElement.class_('A');
    assertElementNull(
      A._lookUpInheritedMethod('foo'),
    );
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_declared_hasExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    var B = findElement.class_('B');
    assertElementNull(
      B._lookUpInheritedMethod('_foo'),
    );
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('_foo'),
      declaration: findElement.method('_foo', of: 'A'),
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
    var B = findElement.class_('B');
    assertElementNull(
      B._lookUpInheritedMethod('foo'),
    );
  }

  test_lookUpInheritedMethod_hasExtends() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'A'),
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'M'),
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'M2'),
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'M1'),
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'A'),
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
    var B = findElement.class_('B');
    assertElement2(
      B._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasExtends_static() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

class B extends A {}
''');
    var B = findElement.class_('B');
    assertElementNull(
      B._lookUpInheritedMethod('foo'),
    );
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
    var C = findElement.class_('C');
    assertElement2(
      C._lookUpInheritedMethod('foo'),
      declaration: findElement.method('foo', of: 'A'),
    );
  }

  test_lookUpInheritedMethod_hasImplements() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    var B = findElement.class_('B');
    assertElementNull(
      B._lookUpInheritedMethod('foo'),
    );
  }

  test_lookUpInheritedMethod_undeclared() async {
    await assertNoErrorsInCode('''
class A {}
''');
    var A = findElement.class_('A');
    assertElementNull(
      A._lookUpInheritedMethod('foo'),
    );
  }
}

extension on ClassElement {
  MethodElement? _lookUpInheritedMethod(String name) {
    return lookUpInheritedMethod(name, library);
  }
}
