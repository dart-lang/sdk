// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.strong_mode_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(InstanceMemberInferrerTest);
  runReflectiveTests(SetFieldTypeTest);
  runReflectiveTests(VariableGathererTest);
}

@reflectiveTest
class InstanceMemberInferrerTest extends AbstractContextTest {
  InstanceMemberInferrer createInferrer(LibraryElement library) {
    return new InstanceMemberInferrer(
        context.typeProvider, new InheritanceManager(library),
        typeSystem: context.typeSystem);
  }

  /**
   * Add a source with the given [content] and return the result of resolving
   * the source.
   */
  CompilationUnitElement resolve(String content) {
    Source source = addSource('/test.dart', content);
    return context.resolveCompilationUnit2(source, source).element;
  }

  void test_creation() {
    InstanceMemberInferrer inferrer = createInferrer(null);
    expect(inferrer, isNotNull);
    expect(inferrer.typeSystem, isNotNull);
  }

  void test_inferCompilationUnit_field_multiple_different() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  int $fieldName;
}
class B {
  double $fieldName;
}
class C implements A, B {
  var $fieldName;
}
''');
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(fieldName);
    PropertyAccessorElement getterC = classC.getGetter(fieldName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_multiple_different_generic() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A<E> {
  E $fieldName;
}
class B<E> {
  E $fieldName;
}
class C implements A<int>, B<double> {
  var $fieldName;
}
''');
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(fieldName);
    PropertyAccessorElement getterC = classC.getGetter(fieldName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_multiple_dynamic() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  int $fieldName;
}
class B {
  var $fieldName;
}
class C implements A, B {
  var $fieldName;
}
''');
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(fieldName);
    PropertyAccessorElement getterC = classC.getGetter(fieldName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_multiple_same() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  int $fieldName;
}
class B {
  int $fieldName;
}
class C implements A, B {
  var $fieldName;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    DartType expectedType = fieldA.type;
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(fieldName);
    PropertyAccessorElement getterC = classC.getGetter(fieldName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type, expectedType);
    expect(getterC.returnType, expectedType);
  }

  void test_inferCompilationUnit_field_noOverride() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  final $fieldName = 0;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    PropertyAccessorElement getterA = classA.getGetter(fieldName);
    expect(fieldA.type.isDynamic, isTrue);
    expect(getterA.returnType.isDynamic, isTrue);

    InstanceMemberInferrer inferrer = _runInferrer(unit);

    DartType intType = inferrer.typeProvider.intType;
    expect(fieldA.type, intType);
    expect(getterA.returnType, intType);
  }

  void test_inferCompilationUnit_field_noOverride_bottom() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  var $fieldName = null;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    PropertyAccessorElement getterA = classA.getGetter(fieldName);
    expect(fieldA.type.isDynamic, isTrue);
    expect(getterA.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldA.type.isDynamic, isTrue);
    expect(getterA.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_single_explicitlyDynamic() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  dynamic $fieldName;
}
class B extends A {
  var $fieldName = 0;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    PropertyAccessorElement getterA = classA.getGetter(fieldName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(fieldName);
    PropertyAccessorElement getterB = classB.getGetter(fieldName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_field_single_final() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  final int $fieldName;
}
class B extends A {
  final $fieldName;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    PropertyAccessorElement getterA = classA.getGetter(fieldName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(fieldName);
    PropertyAccessorElement getterB = classB.getGetter(fieldName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_field_single_final_narrowType() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  final $fieldName;
}
class B extends A {
  final $fieldName = 0;
}
''');
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(fieldName);
    PropertyAccessorElement getterB = classB.getGetter(fieldName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    InstanceMemberInferrer inferrer = _runInferrer(unit);

    expect(fieldB.type, inferrer.typeProvider.intType);
    expect(getterB.returnType, fieldB.type);
  }

  void test_inferCompilationUnit_field_single_generic() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A<E> {
  E $fieldName;
}
class B<E> extends A<E> {
  var $fieldName;
}
''');
    ClassElement classB = unit.getType('B');
    DartType typeBE = classB.typeParameters[0].type;
    FieldElement fieldB = classB.getField(fieldName);
    PropertyAccessorElement getterB = classB.getGetter(fieldName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, typeBE);
    expect(getterB.returnType, typeBE);
  }

  void test_inferCompilationUnit_field_single_inconsistentAccessors() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  int get $fieldName => 0;
  set $fieldName(String value) {}
}
class B extends A {
  var $fieldName;
}
''');
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(fieldName);
    PropertyAccessorElement getterB = classB.getGetter(fieldName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_single_noModifiers() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  int $fieldName;
}
class B extends A {
  var $fieldName;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    PropertyAccessorElement getterA = classA.getGetter(fieldName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(fieldName);
    PropertyAccessorElement getterB = classB.getGetter(fieldName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_fieldFormal() {
    String fieldName = 'f';
    CompilationUnitElement unit = resolve('''
class A {
  final $fieldName = 0;
  A([this.$fieldName = 'hello']);
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(fieldName);
    FieldFormalParameterElement paramA =
        classA.unnamedConstructor.parameters[0];
    expect(fieldA.type.isDynamic, isTrue);
    expect(paramA.type.isDynamic, isTrue);

    InstanceMemberInferrer inferrer = _runInferrer(unit);

    DartType intType = inferrer.typeProvider.intType;
    expect(fieldA.type, intType);
    expect(paramA.type, intType);
  }

  void test_inferCompilationUnit_getter_multiple_different() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  int get $getterName => 0;
}
class B {
  double get $getterName => 0.0;
}
class C implements A, B {
  get $getterName => 0;
}
''');
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(getterName);
    PropertyAccessorElement getterC = classC.getGetter(getterName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_getter_multiple_dynamic() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  int get $getterName => 0;
}
class B {
  get $getterName => 0;
}
class C implements A, B {
  get $getterName => 0;
}
''');
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(getterName);
    PropertyAccessorElement getterC = classC.getGetter(getterName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_getter_multiple_same() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  String get $getterName => '';
}
class B {
  String get $getterName => '';
}
class C implements A, B {
  get $getterName => '';
}
''');
    ClassElement classA = unit.getType('A');
    PropertyAccessorElement getterA = classA.getGetter(getterName);
    DartType expectedType = getterA.returnType;
    ClassElement classC = unit.getType('C');
    FieldElement fieldC = classC.getField(getterName);
    PropertyAccessorElement getterC = classC.getGetter(getterName);
    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldC.type, expectedType);
    expect(getterC.returnType, expectedType);
  }

  void test_inferCompilationUnit_getter_single() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  int get $getterName => 0;
}
class B extends A {
  get $getterName => 0;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(getterName);
    PropertyAccessorElement getterA = classA.getGetter(getterName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(getterName);
    PropertyAccessorElement getterB = classB.getGetter(getterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_getter_single_generic() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A<E> {
  E get $getterName => 0;
}
class B<E> extends A<E> {
  get $getterName => 0;
}
''');
    ClassElement classB = unit.getType('B');
    DartType typeBE = classB.typeParameters[0].type;
    FieldElement fieldB = classB.getField(getterName);
    PropertyAccessorElement getterB = classB.getGetter(getterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, typeBE);
    expect(getterB.returnType, typeBE);
  }

  void test_inferCompilationUnit_getter_single_inconsistentAccessors() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  int get $getterName => 0;
  set $getterName(String value) {}
}
class B extends A {
  var get $getterName => 1;
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(getterName);
    PropertyAccessorElement getterA = classA.getGetter(getterName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(getterName);
    PropertyAccessorElement getterB = classB.getGetter(getterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    // Expected behavior is that the getter is inferred: getters and setters
    // are treated as independent methods.
    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_invalid_inheritanceCycle() {
    CompilationUnitElement unit = resolve('''
class A extends C {}
class B extends A {}
class C extends B {}
''');
    _runInferrer(unit);
  }

  void test_inferCompilationUnit_method_parameter_multiple_different() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  $methodName(int p) => 0;
}
class B {
  $methodName(double p) => 0;
}
class C implements A, B {
  $methodName(p) => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    ParameterElement parameterC = methodC.parameters[0];
    expect(parameterC.type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(parameterC.type.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_parameter_multiple_named_different() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  $methodName({int p}) => 0;
}
class B {
  $methodName({int q}) => 0;
}
class C implements A, B {
  $methodName({p}) => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    ParameterElement parameterC = methodC.parameters[0];
    expect(parameterC.type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(parameterC.type.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_parameter_multiple_named_same() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  $methodName({int p}) => 0;
}
class B {
  $methodName({int p}) => 0;
}
class C implements A, B {
  $methodName({p}) => 0;
}
''');
    ClassElement classA = unit.getType('A');
    MethodElement methodA = classA.getMethod(methodName);
    ParameterElement parameterA = methodA.parameters[0];
    DartType expectedType = parameterA.type;
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    ParameterElement parameterC = methodC.parameters[0];
    expect(parameterC.type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(parameterC.type, expectedType);
  }

  void test_inferCompilationUnit_method_parameter_multiple_namedAndRequired() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  $methodName({int p}) => 0;
}
class B {
  $methodName(int p) => 0;
}
class C implements A, B {
  $methodName(p) => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    ParameterElement parameterC = methodC.parameters[0];
    expect(parameterC.type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(parameterC.type.isDynamic, isTrue);
  }

  void
      test_inferCompilationUnit_method_parameter_multiple_optionalAndRequired() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  $methodName(int p) => 0;
}
class B {
  $methodName([int p]) => 0;
}
class C implements A, B {
  $methodName(p) => 0;
}
''');
    ClassElement classA = unit.getType('A');
    MethodElement methodA = classA.getMethod(methodName);
    ParameterElement parameterA = methodA.parameters[0];
    DartType expectedType = parameterA.type;
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    ParameterElement parameterC = methodC.parameters[0];
    expect(parameterC.type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(parameterC.type, expectedType);
  }

  void test_inferCompilationUnit_method_parameter_single_generic() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A<E> {
  $methodName(E p) => 0;
}
class C<E> implements A<E> {
  $methodName(p) => 0;
}
''');
    ClassElement classC = unit.getType('C');
    DartType typeCE = classC.typeParameters[0].type;
    MethodElement methodC = classC.getMethod(methodName);
    ParameterElement parameterC = methodC.parameters[0];
    expect(parameterC.type.isDynamic, isTrue);
    expect(methodC.type.typeArguments, [typeCE]);

    _runInferrer(unit);

    expect(parameterC.type, classC.typeParameters[0].type);
    expect(methodC.type.typeArguments, [typeCE],
        reason: 'function type should still have type arguments');
  }

  void test_inferCompilationUnit_method_return_multiple_different() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  int $methodName() => 0;
}
class B {
  double $methodName() => 0.0;
}
class C implements A, B {
  $methodName() => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_return_multiple_different_generic() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A<E> {
  E $methodName() => null;
}
class B<E> {
  E $methodName() => null;
}
class C implements A<int>, B<double> {
  $methodName() => null;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_return_multiple_dynamic() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  int $methodName() => 0;
}
class B {
  $methodName() => 0;
}
class C implements A, B {
  $methodName() => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_return_multiple_same_generic() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A<E> {
  E $methodName() => 0;
}
class B<E> {
  E $methodName() => 0;
}
class C<E> implements A<E>, B<E> {
  $methodName() => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType, classC.typeParameters[0].type);
  }

  void test_inferCompilationUnit_method_return_multiple_same_nonVoid() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  int $methodName() => 0;
}
class B {
  int $methodName() => 0;
}
class C implements A, B {
  $methodName() => 0;
}
''');
    ClassElement classA = unit.getType('A');
    MethodElement methodA = classA.getMethod(methodName);
    DartType expectedType = methodA.returnType;
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType, expectedType);
  }

  void test_inferCompilationUnit_method_return_multiple_same_void() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  void $methodName() {};
}
class B {
  void $methodName() {};
}
class C implements A, B {
  $methodName() {};
}
''');
    ClassElement classA = unit.getType('A');
    MethodElement methodA = classA.getMethod(methodName);
    DartType expectedType = methodA.returnType;
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType, expectedType);
  }

  void test_inferCompilationUnit_method_return_multiple_void() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  int $methodName() => 0;
}
class B {
  void $methodName() => 0;
}
class C implements A, B {
  $methodName() => 0;
}
''');
    ClassElement classC = unit.getType('C');
    MethodElement methodC = classC.getMethod(methodName);
    expect(methodC.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_return_single() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  int $methodName() => 0;
}
class B extends A {
  $methodName() => 0;
}
''');
    ClassElement classA = unit.getType('A');
    MethodElement methodA = classA.getMethod(methodName);
    ClassElement classB = unit.getType('B');
    MethodElement methodB = classB.getMethod(methodName);
    expect(methodB.returnType.isDynamic, isTrue);

    _runInferrer(unit);

    expect(methodB.returnType, methodA.returnType);
  }

  void test_inferCompilationUnit_method_return_single_generic() {
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A<E> {
  E $methodName() => 0;
}
class B<E> extends A<E> {
  $methodName() => 0;
}
''');
    ClassElement classB = unit.getType('B');
    DartType typeBE = classB.typeParameters[0].type;
    MethodElement methodB = classB.getMethod(methodName);
    expect(methodB.returnType.isDynamic, isTrue);
    expect(methodB.type.typeArguments, [typeBE]);

    _runInferrer(unit);

    expect(methodB.returnType, classB.typeParameters[0].type);
    expect(methodB.type.typeArguments, [typeBE],
        reason: 'function type should still have type arguments');
  }

  void test_inferCompilationUnit_setter_single() {
    String setterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  set $setterName(int x) {}
}
class B extends A {
  set $setterName(x) {}
}
''');
    ClassElement classA = unit.getType('A');
    FieldElement fieldA = classA.getField(setterName);
    PropertyAccessorElement setterA = classA.getSetter(setterName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(setterName);
    PropertyAccessorElement setterB = classB.getSetter(setterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(setterB.parameters[0].type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, fieldA.type);
    expect(setterB.parameters[0].type, setterA.parameters[0].type);
  }

  void test_inferCompilationUnit_setter_single_generic() {
    String setterName = 'g';
    CompilationUnitElement unit = resolve('''
class A<E> {
  set $setterName(E x) {}
}
class B<E> extends A<E> {
  set $setterName(x) {}
}
''');
    ClassElement classB = unit.getType('B');
    DartType typeBE = classB.typeParameters[0].type;
    FieldElement fieldB = classB.getField(setterName);
    PropertyAccessorElement setterB = classB.getSetter(setterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(setterB.parameters[0].type.isDynamic, isTrue);

    _runInferrer(unit);

    expect(fieldB.type, typeBE);
    expect(setterB.parameters[0].type, typeBE);
  }

  void test_inferCompilationUnit_setter_single_inconsistentAccessors() {
    String getterName = 'g';
    CompilationUnitElement unit = resolve('''
class A {
  int get $getterName => 0;
  set $getterName(String value) {}
}
class B extends A {
  set $getterName(x) {}
}
''');
    ClassElement classA = unit.getType('A');
    PropertyAccessorElement setterA = classA.getSetter(getterName);
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(getterName);
    PropertyAccessorElement setterB = classB.getSetter(getterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(setterB.parameters[0].type.isDynamic, isTrue);

    _runInferrer(unit);

    // Expected behavior is that the getter is inferred: getters and setters
    // are treated as independent methods.
    expect(setterB.parameters[0].type, setterA.parameters[0].type);

    // Note that B's synthetic field type will be String. This matches what
    // resolver would do if we explicitly typed the parameter as 'String'
    expect(fieldB.type, setterB.parameters[0].type);
  }

  InstanceMemberInferrer _runInferrer(CompilationUnitElement unit) {
    InstanceMemberInferrer inferrer = createInferrer(unit.library);
    inferrer.inferCompilationUnit(unit);
    return inferrer;
  }
}

@reflectiveTest
class SetFieldTypeTest extends AbstractContextTest {
  void test_setter_withoutParameter() {
    CompilationUnitElement unit = _resolve('''
var x = 0;
set x() {}
''');
    TopLevelVariableElement variable = unit.topLevelVariables.single;
    setFieldType(variable, context.typeProvider.intType);
  }

  CompilationUnitElement _resolve(String content) {
    Source source = addSource('/test.dart', content);
    return context.resolveCompilationUnit2(source, source).element;
  }
}

@reflectiveTest
class VariableGathererTest extends AbstractContextTest {
  void test_creation_withFilter() {
    VariableFilter filter = (variable) => true;
    VariableGatherer gatherer = new VariableGatherer(filter);
    expect(gatherer, isNotNull);
    expect(gatherer.filter, filter);
  }

  void test_creation_withoutFilter() {
    VariableGatherer gatherer = new VariableGatherer();
    expect(gatherer, isNotNull);
    expect(gatherer.filter, isNull);
  }

  void test_visit_noReferences() {
    Source source = addSource(
        '/test.dart',
        '''
library lib;
import 'dart:math';
int zero = 0;
class C {
  void m() => null;
}
typedef void F();
''');
    CompilationUnit unit = context.resolveCompilationUnit2(source, source);
    VariableGatherer gatherer = new VariableGatherer();
    unit.accept(gatherer);
    expect(gatherer.results, hasLength(0));
  }

  void test_visit_withFilter() {
    VariableFilter filter = (VariableElement variable) => variable.isStatic;
    expect(_gather(filter), hasLength(1));
  }

  void test_visit_withoutFilter() {
    expect(_gather(), hasLength(4));
  }

  Set<VariableElement> _gather([VariableFilter filter = null]) {
    Source source = addSource(
        '/test.dart',
        '''
const int zero = 0;
class Counter {
  int value = zero;
  void inc() {
    value++;
  }
  void dec() {
    value = value - 1;
  }
  void fromZero(f(int index)) {
    for (int i = zero; i < value; i++) {
      f(i);
    }
  }
}
''');
    CompilationUnit unit = context.resolveCompilationUnit2(source, source);
    VariableGatherer gatherer = new VariableGatherer(filter);
    unit.accept(gatherer);
    return gatherer.results;
  }
}
