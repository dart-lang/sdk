// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CanBeConstConstructorTest);
    defineReflectiveTests(CanBeConstTest);
  });
}

@reflectiveTest
abstract class AbstractLinterContextTest extends DriverResolutionTest {
  LinterContextImpl context;

  Future<void> resolve(String content) async {
    await resolveTestCode(content);
    var contextUnit = LinterContextUnit(result.content, result.unit);
    context = new LinterContextImpl(
      [contextUnit],
      contextUnit,
      result.session.declaredVariables,
      result.typeProvider,
      result.typeSystem,
      InheritanceManager3(result.typeSystem),
      analysisOptions,
    );
  }
}

@reflectiveTest
class CanBeConstConstructorTest extends AbstractLinterContextTest {
  LinterContextImpl context;

  void assertCanBeConstConstructor(String search, bool expectedResult) {
    var constructor = findNode.constructor(search);
    expect(context.canBeConstConstructor(constructor), expectedResult);
  }

  test_assertInitializer_parameter() async {
    await resolve(r'''
class C {
  C(int a) : assert(a >= 0, 'error');
}
''');
    assertCanBeConstConstructor('C(int a)', true);
  }

  test_empty() async {
    await resolve(r'''
class C {
  C();
}
''');
    assertCanBeConstConstructor('C()', true);
  }

  test_field_notConstInitializer() async {
    await resolve(r'''
class C {
  final int f = a;
  C();
}

var a = 0;
''');
    assertCanBeConstConstructor('C()', false);
  }

  test_field_notFinal() async {
    await resolve(r'''
class C {
  int f = 0;
  C();
}
''');
    assertCanBeConstConstructor('C()', false);
  }

  test_field_notFinal_inherited() async {
    await resolve(r'''
class A {
  int f = 0;
}

class B extends A {
  B();
}
''');
    assertCanBeConstConstructor('B()', false);
  }

  test_fieldInitializer_literal() async {
    await resolve(r'''
class C {
  final int f;
  C() : f = 0;
}
''');
    assertCanBeConstConstructor('C()', true);
  }

  test_fieldInitializer_notConst() async {
    await resolve(r'''
class C {
  final int f;
  C() : f = a;
}

var a = 0;
''');
    assertCanBeConstConstructor('C()', false);
  }

  test_fieldInitializer_parameter() async {
    await resolve(r'''
class C {
  final int f;
  C(int a) : f = a;
}
''');
    assertCanBeConstConstructor('C(int a)', true);
  }
}

@reflectiveTest
class CanBeConstTest extends AbstractLinterContextTest {
  void assertCanBeConst(String snippet, bool expectedResult) {
    var node = findNode.instanceCreation(snippet);
    expect(context.canBeConst(node), expectedResult);
  }

  void test_false_argument_invocation() async {
    await resolve('''
class A {}
class B {
  const B(A a);
}
A f() => A();
B g() => B(f());
''');
    assertCanBeConst("B(f", false);
  }

  void test_false_argument_invocationInList() async {
    await resolve('''
class A {}
class B {
  const B(a);
}
A f() => A();
B g() => B([f()]);
''');
    assertCanBeConst("B([", false);
  }

  void test_false_argument_nonConstConstructor() async {
    await resolve('''
class A {}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", false);
  }

  void test_false_nonConstConstructor() async {
    await resolve('''
class A {}
A f() => A();
''');
    assertCanBeConst("A(", false);
  }

  void test_false_typeParameter() async {
    await resolve('''
class A<T> {
  const A();
}
f<U>() => A<U>();
''');
    assertCanBeConst("A<U>", false);
  }

  void test_true_constConstructorArg() async {
    await resolve('''
class A {
  const A();
}
class B {
  const B(A a);
}
B f() => B(A());
''');
    assertCanBeConst("B(A(", true);
  }

  void test_true_constListArg() async {
    await resolve('''
class A {
  const A(List<int> l);
}
A f() => A([1, 2, 3]);
''');
    assertCanBeConst("A([", true);
  }

  void test_true_importedClass_defaultValue() async {
    var aPath = convertPath('/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  final int a;
  const A({int b = 1}) : a = b * 2;
}
''');
    await resolve('''
import 'a.dart';

A f() => A();
''');
    assertCanBeConst("A();", true);
  }
}
