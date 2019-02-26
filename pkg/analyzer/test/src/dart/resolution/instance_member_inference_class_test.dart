// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferenceClassDriverResolutionTest);
  });
}

@reflectiveTest
class InstanceMemberInferenceClassDriverResolutionTest
    extends DriverResolutionTest with InstanceMemberInferenceClassMixin {}

mixin InstanceMemberInferenceClassMixin implements ResolutionTest {
  test_invalid_inheritanceCycle() async {
    addTestFile('''
class A extends C {}
class B extends A {}
class C extends B {}
''');
    await resolveTestFile();
  }

  test_method_parameter_multiple_different() async {
    addTestFile('''
class A {
  foo(int p) => 0;
}
class B {
  foo(double p) => 0;
}
class C implements A, B {
  foo(p) => 0;
}
''');
    await resolveTestFile();

    var p = findElement.method('foo', of: 'C').parameters[0];
    assertElementTypeDynamic(p.type);
  }

  test_method_parameter_multiple_named_different() async {
    addTestFile('''
class A {
  foo({int p}) => 0;
}
class B {
  foo({int q}) => 0;
}
class C implements A, B {
  foo({p}) => 0;
}
''');
    await resolveTestFile();

    var p = findElement.method('foo', of: 'C').parameters[0];
    assertElementTypeDynamic(p.type);
  }

  test_method_parameter_multiple_named_same() async {
    addTestFile('''
class A {
  foo({int p}) => 0;
}
class B {
  foo({int p}) => 0;
}
class C implements A, B {
  foo({p}) => 0;
}
''');
    await resolveTestFile();

    var p = findElement.method('foo', of: 'C').parameters[0];
    assertElementTypeString(p.type, 'int');
  }

  test_method_parameter_multiple_namedAndRequired() async {
    addTestFile('''
class A {
  foo({int p}) => 0;
}
class B {
  foo(int p) => 0;
}
class C implements A, B {
  foo(p) => 0;
}
''');
    await resolveTestFile();

    var p = findElement.method('foo', of: 'C').parameters[0];
    assertElementTypeDynamic(p.type);
  }

  test_method_parameter_multiple_optionalAndRequired() async {
    addTestFile('''
class A {
  foo(int p) => 0;
}
class B {
  foo([int p]) => 0;
}
class C implements A, B {
  foo(p) => 0;
}
''');
    await resolveTestFile();

    var p = findElement.method('foo', of: 'C').parameters[0];
    assertElementTypeString(p.type, 'int');
  }

  test_method_parameter_single_generic() async {
    addTestFile('''
class A<E> {
  foo(E p) => 0;
}
class C<T> implements A<T> {
  foo(p) => 0;
}
''');
    await resolveTestFile();

    var p = findElement.method('foo', of: 'C').parameters[0];
    assertElementTypeString(p.type, 'T');
  }

  test_method_return_multiple_different() async {
    addTestFile('''
class A {
  int foo() => 0;
}
class B {
  double foo() => 0.0;
}
class C implements A, B {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_generic() async {
    addTestFile('''
class A<E> {
  E foo() => null;
}
class B<E> {
  E foo() => null;
}
class C implements A<int>, B<double> {
  foo() => null;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_void() async {
    addTestFile('''
class A {
  int foo() => 0;
}
class B {
  void foo() => 0;
}
class C implements A, B {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_dynamic() async {
    addTestFile('''
class A {
  int foo() => 0;
}
class B {
  foo() => 0;
}
class C implements A, B {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_same_generic() async {
    addTestFile('''
class A<E> {
  E foo() => 0;
}
class B<E> {
  E foo() => 0;
}
class C<T> implements A<T>, B<T> {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeString(foo.returnType, 'T');
  }

  test_method_return_multiple_same_nonVoid() async {
    addTestFile('''
class A {
  int foo() => 0;
}
class B {
  int foo() => 0;
}
class C implements A, B {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeString(foo.returnType, 'int');
  }

  test_method_return_multiple_same_void() async {
    addTestFile('''
class A {
  void foo() {};
}
class B {
  void foo() {};
}
class C implements A, B {
  foo() {};
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'C');
    assertElementTypeString(foo.returnType, 'void');
  }

  test_method_return_single() async {
    addTestFile('''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'B');
    assertElementTypeString(foo.returnType, 'int');
  }

  test_method_return_single_generic() async {
    addTestFile('''
class A<E> {
  E foo() => 0;
}
class B<T> extends A<T> {
  foo() => 0;
}
''');
    await resolveTestFile();

    var foo = findElement.method('foo', of: 'B');
    assertElementTypeString(foo.returnType, 'T');
  }
}
