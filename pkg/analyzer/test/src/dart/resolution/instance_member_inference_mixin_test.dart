// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferenceMixinDriverResolutionTest);
  });
}

@reflectiveTest
class InstanceMemberInferenceMixinDriverResolutionTest
    extends DriverResolutionTest {
  test_invalid_inheritanceCycle() async {
    await resolveTestCode('''
mixin A on C {}
mixin B on A {}
mixin C on B {}
''');
  }

  test_method_parameter_multiple_different() async {
    await resolveTestCode('''
class A {
  foo(int p) => 0;
}
class B {
  foo(double p) => 0;
}
mixin M on A, B {
  foo(p) => 0;
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertElementTypeDynamic(p.type);
  }

  test_method_parameter_multiple_named_different() async {
    await resolveTestCode('''
class A {
  foo({int p}) => 0;
}
class B {
  foo({int q}) => 0;
}
mixin M on A, B {
  foo({p}) => 0;
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertElementTypeDynamic(p.type);
  }

  test_method_parameter_multiple_named_same() async {
    await resolveTestCode('''
class A {
  foo({int p}) => 0;
}
class B {
  foo({int p}) => 0;
}
mixin M on A, B {
  foo({p}) => 0;
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertElementTypeString(p.type, 'int');
  }

  test_method_parameter_multiple_namedAndRequired() async {
    await resolveTestCode('''
class A {
  foo({int p}) => 0;
}
class B {
  foo(int p) => 0;
}
mixin M on A, B {
  foo(p) => 0;
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertElementTypeDynamic(p.type);
  }

  test_method_parameter_multiple_optionalAndRequired() async {
    await resolveTestCode('''
class A {
  foo(int p) => 0;
}
class B {
  foo([int p]) => 0;
}
mixin M on A, B {
  foo(p) => 0;
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertElementTypeString(p.type, 'int');
  }

  test_method_parameter_single_generic() async {
    await resolveTestCode('''
class A<E> {
  foo(E p) => 0;
}
mixin M<T> on A<T> {
  foo(p) => 0;
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertElementTypeString(p.type, 'T');
  }

  test_method_return_multiple_different() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  double foo() => 0.0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => null;
}
class B<E> {
  E foo() => null;
}
mixin M on A<int>, B<double> {
  foo() => null;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_void() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  void foo() => 0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_dynamic() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  foo() => 0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_same_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => 0;
}
class B<E> {
  E foo() => 0;
}
mixin M<T> on A<T>, B<T> {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeString(foo.returnType, 'T');
  }

  test_method_return_multiple_same_nonVoid() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  int foo() => 0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeString(foo.returnType, 'int');
  }

  test_method_return_multiple_same_void() async {
    await resolveTestCode('''
class A {
  void foo() {};
}
class B {
  void foo() {};
}
mixin M on A, B {
  foo() {};
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeString(foo.returnType, 'void');
  }

  test_method_return_single() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
mixin M on A {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeString(foo.returnType, 'int');
  }

  test_method_return_single_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => 0;
}
mixin M<T> on A<T> {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertElementTypeString(foo.returnType, 'T');
  }
}
