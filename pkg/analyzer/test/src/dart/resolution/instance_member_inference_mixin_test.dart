// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferenceClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InstanceMemberInferenceClassTest extends PubPackageResolutionTest {
  test_invalid_inheritanceCycle() async {
    await resolveTestCodeWithDiagnostics('''
class A extends C {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, C, A.
class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, C, A.
class C extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: B, C, A.
''');
  }

  test_method_parameter_named_multiple_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo({int p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class B {
  void foo({num p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
mixin M on A, B {
  void foo({p}) {}
//          ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'num');
  }

  test_method_parameter_named_multiple_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo({int p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class B {
  void foo({int q}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'q' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
mixin M on A, B {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (void Function({int p})), B.foo (void Function({int q})).
  void foo({p}) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'M' from overridden methods: A.foo (void Function({int p})), B.foo (void Function({int q})).
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_named_multiple_same() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo({int p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class B {
  void foo({int p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
mixin M on A, B {
  void foo({p}) {}
//          ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_namedAndRequired() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo({int p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class B {
  void foo(int p) {}
}
mixin M on A, B {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (void Function({int p})), B.foo (void Function(int)).
  void foo(p) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'M' from overridden methods: A.foo (void Function({int p})), B.foo (void Function(int)).
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_required_multiple_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int p) {}
}
class B {
  void foo(num p) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'num');
  }

  test_method_parameter_required_multiple_different_merge() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(Object? p) {}
}

class B {
  void foo(dynamic p) {}
}

mixin M on A, B {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'Object?');
  }

  test_method_parameter_required_multiple_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int p) {}
}
class B {
  void foo(double p) {}
}
mixin M on A, B {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (void Function(int)), B.foo (void Function(double)).
  void foo(p) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'M' from overridden methods: A.foo (void Function(int)), B.foo (void Function(double)).
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_required_multiple_same() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int p) {}
}
class B {
  void foo(int p) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_required_single_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E> {
  void foo(E p) {}
}
mixin M<T> on A<T> {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'T');
  }

  test_method_parameter_requiredAndPositional() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int p) {}
}
class B {
  void foo([int p]) {}
//     ^^^
// [context 1] The member being overridden.
//              ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
mixin M on A, B {
  void foo(p) {}
//     ^^^
// [diag.invalidOverride][context 1] 'M.foo' ('void Function(int)') isn't a valid override of 'B.foo' ('void Function([int])').
}
''');
    var p = result.findElement.method('foo', of: 'M').formalParameters[0];
    assertType(p.type, 'int');
  }

  test_method_return_multiple_different_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo() => 0;
}
class B {
  num foo() => 0.0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_different_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_different_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E> {
  E foo() => throw 0;
}
class B<E> {
  E foo() => throw 0;
}
mixin M on A<int>, B<double> {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (int Function()), B.foo (double Function()).
  foo() => throw 0;
//^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'M' from overridden methods: A.foo (int Function()), B.foo (double Function()).
}
''');
    var foo = result.findElement.method('foo', of: 'M');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo() => 0;
}
class B {
  double foo() => 0.0;
}
mixin M on A, B {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (int Function()), B.foo (double Function()).
  foo() => 0;
//^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'M' from overridden methods: A.foo (int Function()), B.foo (double Function()).
}
''');
    var foo = result.findElement.method('foo', of: 'M');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_merge() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  Object? foo() => throw 0;
}

class B {
  dynamic foo() => throw 0;
}

mixin M on A, B {
  foo() => throw 0;
}
''');
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'Object?');
  }

  test_method_return_multiple_different_void() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E> {
  E foo() => 0;
//           ^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'int' can't be returned from the method 'foo' because it has a return type of 'E'.
}
class B<E> {
  E foo() => 0;
//           ^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'int' can't be returned from the method 'foo' because it has a return type of 'E'.
}
mixin M<T> on A<T>, B<T> {
  foo() => 0;
//         ^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'int' can't be returned from the method 'foo' because it has a return type of 'T'.
}
''');
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'T');
  }

  test_method_return_multiple_same_nonVoid() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_void() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {};
//             ^
// [diag.expectedClassMember] Expected a class member.
}
class B {
  void foo() {};
//             ^
// [diag.expectedClassMember] Expected a class member.
}
mixin M on A, B {
  foo() {};
//        ^
// [diag.expectedClassMember] Expected a class member.
}
''');
    var foo = result.findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'void');
  }

  test_method_return_single() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 0;
}
''');
    var foo = result.findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'int');
  }

  test_method_return_single_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E> {
  E foo() => throw 0;
}
class B<T> extends A<T> {
  foo() => throw 0;
}
''');
    var foo = result.findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'T');
  }
}
