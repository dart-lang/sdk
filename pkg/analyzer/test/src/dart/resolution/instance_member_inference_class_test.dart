// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferenceClassTest);
    defineReflectiveTests(InstanceMemberInferenceClassWithNullSafetyTest);
  });
}

@reflectiveTest
class InstanceMemberInferenceClassTest extends DriverResolutionTest {
  test_invalid_inheritanceCycle() async {
    await resolveTestCode('''
class A extends C {}
class B extends A {}
class C extends B {}
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
class C implements A, B {
  foo(p) => 0;
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_multiple_named_different() async {
    await resolveTestCode('''
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
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_multiple_named_same() async {
    await resolveTestCode('''
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
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_multiple_namedAndRequired() async {
    await resolveTestCode('''
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
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_multiple_optionalAndRequired() async {
    await resolveTestCode('''
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
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_single_generic() async {
    await resolveTestCode('''
class A<E> {
  foo(E p) => 0;
}
class C<T> implements A<T> {
  foo(p) => 0;
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'T');
  }

  test_method_return_multiple_different() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_generic() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_void() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_dynamic() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_same_generic() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'T');
  }

  test_method_return_multiple_same_nonVoid() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_void() async {
    await resolveTestCode('''
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
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'void');
  }

  test_method_return_single() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'int');
  }

  test_method_return_single_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => 0;
}
class B<T> extends A<T> {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'T');
  }
}

@reflectiveTest
class InstanceMemberInferenceClassWithNullSafetyTest
    extends InstanceMemberInferenceClassTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;

  test_method_parameter_multiple_different_merge() async {
    await resolveTestCode('''
class A {
  void foo(Object? p) {}
}

class B {
  void foo(dynamic p) {}
}

class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'Object?');
  }

  test_method_return_multiple_different_merge() async {
    await resolveTestCode('''
class A {
  Object? foo() => throw 0;
}

class B {
  dynamic foo() => throw 0;
}

class C implements A, B {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'Object?');
  }
}
