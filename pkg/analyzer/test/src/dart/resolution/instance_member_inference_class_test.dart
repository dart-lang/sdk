// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
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
  test_field_covariant_fromField() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  covariant num foo = 0;
}

class B implements A {
  int foo = 0;
}
''');
    var foo = result.findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int', isCovariant: true);
  }

  test_field_covariant_fromSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(covariant num _) {}
}

class B implements A {
  int foo = 0;
}
''');
    var foo = result.findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int', isCovariant: true);
  }

  test_field_fromInitializer_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  var foo = 0;
}

class B implements A {
  var foo;
//    ^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'foo' must be initialized.
}
''');
    var foo = result.findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int');
  }

  test_field_fromInitializer_preferSuper() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num foo;
//    ^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'foo' must be initialized.
}

class B implements A {
  var foo = 0;
}
''');
    var foo = result.findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'num');
  }

  test_field_multiple_fields_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = throw 0;
//    ^^^
// [context 1] The member being overridden.
}
class B {
  String foo = throw 0;
//       ^^^
// [context 2] The member being overridden.
}
class C implements A, B {
  var foo;
//    ^^^
// [diag.invalidOverride][context 1] 'C.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('int Function()').
// [diag.invalidOverride][context 2] 'C.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('String Function()').
}
''');
    var foo = result.findElement.field('foo', of: 'C');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_getters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  var foo;
//    ^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'foo' must be initialized.
}
''');
    var foo = result.findElement.field('foo', of: 'C');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_getters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  String get foo => throw 0;
//           ^^^
// [context 1] The member being overridden.
}
class B {
  int get foo => throw 0;
//        ^^^
// [context 2] The member being overridden.
}
class C implements A, B {
  var foo;
//    ^^^
// [diag.invalidOverride][context 1] 'C.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverride][context 2] 'C.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('int Function()').
}
''');
    var foo = result.findElement.field('foo', of: 'C');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_final_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter C.foo'.
  final foo;
//      ^^^
// [diag.finalNotInitialized] The final variable 'foo' must be initialized.
}
''');
    var foo = result.findElement.field('foo', of: 'X');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_gettersSetters_final_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  String get foo => throw 0;
//           ^^^
// [context 1] The member being overridden.
}
class B {
  int get foo => throw 0;
//        ^^^
// [context 2] The member being overridden.
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter C.foo'.
  final foo;
//      ^^^
// [diag.invalidOverride][context 1] 'X.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverride][context 2] 'X.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('int Function()').
// [diag.finalNotInitialized] The final variable 'foo' must be initialized.
}
''');
    var foo = result.findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_notFinal_combined_notSame() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
//        ^^^
// [context 1] The member being overridden.
}
class B {
  int get foo => throw 0;
//        ^^^
// [context 2] The member being overridden.
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
  var foo;
//    ^^^
// [diag.invalidOverride][context 1] 'X.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('num Function()').
// [diag.invalidOverride][context 2] 'X.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('int Function()').
}
''');
    var foo = result.findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
    // TODO(scheglov): error?
  }

  test_field_multiple_gettersSetters_notFinal_combined_same() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(int _) {}
}
class X implements A, B, C {
  var foo;
//    ^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'foo' must be initialized.
}
''');
    var foo = result.findElement.field('foo', of: 'X');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_gettersSetters_notFinal_incompatible_getters() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  String get foo => throw 0;
//           ^^^
// [context 1] The member being overridden.
}
class B {
  int get foo => throw 0;
//        ^^^
// [context 2] The member being overridden.
}
class C {
  set foo(int _) {}
}
class X implements A, B, C {
  var foo;
//    ^^^
// [diag.invalidOverride][context 1] 'X.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverride][context 2] 'X.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('int Function()').
}
''');
    var foo = result.findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_notFinal_incompatible_setters() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => throw 0;
//        ^^^
// [context 1] The member being overridden.
}
class B {
  set foo(String _) {}
}
class C {
  set foo(int _) {}
}
class X implements A, B, C {
  var foo;
//    ^^^
// [diag.invalidOverride][context 1] 'X.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('int Function()').
}
''');
    var foo = result.findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_setters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  var foo;
//    ^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'foo' must be initialized.
}
''');
    var foo = result.findElement.field('foo', of: 'C');
    _assertFieldType(foo, 'num');
  }

  test_field_multiple_setters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  var foo;
}
''');
    var foo = result.findElement.field('foo', of: 'C');
    _assertFieldTypeDynamic(foo);
  }

  test_getter_multiple_getters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = result.findElement.getter('foo', of: 'C');
    _assertGetterType(foo, 'int');
  }

  test_getter_multiple_getters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  String get foo => throw 0;
//           ^^^
// [context 1] The member being overridden.
}
class B {
  int get foo => throw 0;
//        ^^^
// [context 2] The member being overridden.
}
class C implements A, B {
  get foo => throw 0;
//    ^^^
// [diag.invalidOverride][context 1] 'C.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverride][context 2] 'C.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('int Function()').
}
''');
    var foo = result.findElement.getter('foo', of: 'C');
    _assertGetterTypeDynamic(foo);
  }

  test_getter_multiple_getters_same() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = result.findElement.getter('foo', of: 'C');
    _assertGetterType(foo, 'int');
  }

  test_getter_multiple_gettersSetters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter C.foo'.
  get foo => throw 0;
}
''');
    var foo = result.findElement.getter('foo', of: 'X');
    _assertGetterType(foo, 'int');
  }

  test_getter_multiple_gettersSetters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  String get foo => throw 0;
//           ^^^
// [context 1] The member being overridden.
}
class B {
  int get foo => throw 0;
//        ^^^
// [context 2] The member being overridden.
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter C.foo'.
  get foo => throw 0;
//    ^^^
// [diag.invalidOverride][context 1] 'X.foo' ('dynamic Function()') isn't a valid override of 'A.foo' ('String Function()').
// [diag.invalidOverride][context 2] 'X.foo' ('dynamic Function()') isn't a valid override of 'B.foo' ('int Function()').
}
''');
    var foo = result.findElement.getter('foo', of: 'X');
    _assertGetterTypeDynamic(foo);
  }

  test_getter_multiple_setters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'setter A.foo'.
  get foo => throw 0;
}
''');
    var foo = result.findElement.getter('foo', of: 'C');
    _assertGetterType(foo, 'num');
  }

  test_getter_multiple_setters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo=': A.foo= (void Function(String)), B.foo= (void Function(int)).
  get foo => throw 0;
}
''');
    var foo = result.findElement.getter('foo', of: 'C');
    _assertGetterTypeDynamic(foo);
  }

  test_invalid_field_overrides_method() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  List<T> foo<T>() {}
//        ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'List<T>', is a potentially non-nullable type.
}

class B implements A {
  var foo = <String, int>{};
//    ^^^
// [diag.conflictingFieldAndMethod] Class 'B' can't define field 'foo' and have method 'A.foo' with the same name.
}
''');
    var foo = result.findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'Map<String, int>');
  }

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

  test_method_parameter_covariant_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo({num p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class B {
  void foo({covariant num p}) {}
//                        ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class C implements A, B {
  void foo({int p}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
    _assertFormalParameter(p, type: 'int', isCovariant: true);
  }

  test_method_parameter_covariant_positional() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo([num p]) {}
//              ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class B {
  void foo([covariant num p]) {}
//                        ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class C implements A, B {
  void foo([int p]) {}
//              ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
    _assertFormalParameter(p, type: 'int', isCovariant: true);
  }

  test_method_parameter_covariant_required() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(num p) {}
}
class B {
  void foo(covariant num p) {}
}
class C implements A, B {
  void foo(int p) {}
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
    _assertFormalParameter(p, type: 'int', isCovariant: true);
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
class C implements A, B {
  void foo({p}) {}
//          ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo({p}) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (void Function({int p})), B.foo (void Function({int q})).
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo({p}) {}
//          ^
// [diag.missingDefaultValueForParameter] The parameter 'p' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo(p) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (void Function({int p})), B.foo (void Function(int)).
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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

class C implements A, B {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo(p) {}
//     ^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (void Function(int)), B.foo (void Function(double)).
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_required_single_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<E> {
  void foo(E p) {}
}
class C<T> implements A<T> {
  void foo(p) {}
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  void foo(p) {}
//     ^^^
// [diag.invalidOverride][context 1] 'C.foo' ('void Function(int)') isn't a valid override of 'B.foo' ('void Function([int])').
}
''');
    var p = result.findElement.method('foo', of: 'C').formalParameters[0];
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
class C implements A, B {
  foo() => 0;
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C implements A, B {
  foo() => 0;
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C implements A<int>, B<double> {
  foo() => throw 0;
//^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (int Function()), B.foo (double Function()).
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C implements A, B {
  foo() => 0;
//^^^
// [diag.noCombinedSuperSignature] Can't infer missing types in 'C' from overridden methods: A.foo (int Function()), B.foo (double Function()).
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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

class C implements A, B {
  foo() => throw 0;
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C implements A, B {
  foo() => 0;
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C<T> implements A<T>, B<T> {
  foo() => 0;
//         ^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'int' can't be returned from the method 'foo' because it has a return type of 'T'.
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C implements A, B {
  foo() => 0;
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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
class C implements A, B {
  foo() {};
//        ^
// [diag.expectedClassMember] Expected a class member.
}
''');
    var foo = result.findElement.method('foo', of: 'C');
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

  test_setter_covariant_fromSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(num _) {}
}
class B {
  set foo(covariant num _) {}
}
class C implements A, B {
  set foo(int x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'C');
    _assertSetterType(foo, 'int', isCovariant: true);
  }

  test_setter_multiple_getters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter B.foo'.
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'C');
    _assertSetterType(foo, 'int');
  }

  test_setter_multiple_getters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (String Function()), B.foo (int Function()).
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'C');
    _assertSetterTypeDynamic(foo);
  }

  test_setter_multiple_gettersSetters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C {
  String get foo => throw 0;
}
class X implements A, B, C {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter C.foo'.
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'X');
    _assertSetterType(foo, 'num');
  }

  test_setter_multiple_gettersSetters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C {
  int get foo => throw 0;
}
class X implements A, B, C {
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'getter C.foo'.
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'X');
    _assertSetterTypeDynamic(foo);
  }

  test_setter_multiple_setters_combined() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'C');
    _assertSetterType(foo, 'num');
  }

  test_setter_multiple_setters_incompatible() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'C');
    _assertSetterTypeDynamic(foo);
  }

  test_setter_single_setter_withoutParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo() {}
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
class B implements A {
  set foo(x) {}
}
''');
    var foo = result.findElement.setter('foo', of: 'B');
    _assertSetterType(foo, 'dynamic');
  }

  void _assertFieldType(
    FieldElement field,
    String type, {
    bool isCovariant = false,
  }) {
    expect(field.isOriginDeclaration, isTrue);

    _assertGetterType(field.getter, type);

    var setter = field.setter;
    if (setter != null) {
      _assertSetterType(setter, type, isCovariant: isCovariant);
    }
  }

  void _assertFieldTypeDynamic(FieldElement field) {
    expect(field.isOriginDeclaration, isTrue);

    _assertGetterTypeDynamic(field.getter);

    if (!field.isFinal) {
      _assertSetterTypeDynamic(field.setter);
    }
  }

  void _assertFormalParameter(
    FormalParameterElement element, {
    String? type,
    bool isCovariant = false,
  }) {
    assertType(element.type, type);
    expect(element.isCovariant, isCovariant);
  }

  void _assertGetterType(GetterElement? accessor, String expected) {
    accessor!;
    assertType(accessor.returnType, expected);
  }

  void _assertGetterTypeDynamic(GetterElement? accessor) {
    accessor!;
    assertTypeDynamic(accessor.returnType);
  }

  void _assertSetterType(
    SetterElement accessor,
    String expected, {
    bool isCovariant = false,
  }) {
    var parameter = accessor.formalParameters.single;
    assertType(parameter.type, expected);
    expect(parameter.isCovariant, isCovariant);
  }

  void _assertSetterTypeDynamic(SetterElement? accessor) {
    accessor!;
    assertTypeDynamic(accessor.formalParameters.single.type);
  }
}
