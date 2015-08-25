// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.strong_mode_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:analyzer/task/dart.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(InferrenceFinderTest);
  runReflectiveTests(InstanceMemberInferrerTest);
}

@reflectiveTest
class InferrenceFinderTest extends AbstractContextTest {
  void test_creation() {
    InferrenceFinder finder = new InferrenceFinder();
    expect(finder, isNotNull);
    expect(finder.classes, isEmpty);
    expect(finder.staticVariables, isEmpty);
  }

  void test_visit() {
    Source source = addSource(
        '/test.dart',
        r'''
const c = 1;
final f = '';
var v = const A();
class A {
  static final fa = 0;
  const A();
}
class B extends A {
  static const cb = 1;
  static vb = 0;
  const ci = 2;
  final fi = '';
  var vi;
}
class C = Object with A;
typedef int F(int x);
''');
    computeResult(source, PARSED_UNIT);
    CompilationUnit unit = outputs[PARSED_UNIT];
    InferrenceFinder finder = new InferrenceFinder();
    unit.accept(finder);
    expect(finder.classes, hasLength(3));
    expect(finder.staticVariables, hasLength(6));
  }
}

@reflectiveTest
class InstanceMemberInferrerTest extends AbstractContextTest {
  InstanceMemberInferrer get createInferrer =>
      new InstanceMemberInferrer(context.typeProvider);

  /**
   * Add a source with the given [content] and return the result of resolving
   * the source.
   */
  CompilationUnitElement resolve(String content) {
    Source source = addSource('/test.dart', content);
    return context.resolveCompilationUnit2(source, source).element;
  }

  void test_creation() {
    InstanceMemberInferrer inferrer = createInferrer;
    expect(inferrer, isNotNull);
    expect(inferrer.typeSystem, isNotNull);
  }

  void test_inferCompilationUnit_field_multiple_different() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_multiple_dynamic() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_multiple_same() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldC.type, expectedType);
    expect(getterC.returnType, expectedType);
  }

  void test_inferCompilationUnit_field_noOverride() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    DartType intType = inferrer.typeProvider.intType;
    expect(fieldA.type, intType);
    expect(getterA.returnType, intType);
  }

  void test_inferCompilationUnit_field_noOverride_bottom() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldA.type.isDynamic, isTrue);
    expect(getterA.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_single_explicitlyDynamic() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_field_single_final() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_field_single_inconsistentAccessors() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_field_single_noModifiers() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_getter_multiple_different() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_getter_multiple_dynamic() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldC.type.isDynamic, isTrue);
    expect(getterC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_getter_multiple_same() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldC.type, expectedType);
    expect(getterC.returnType, expectedType);
  }

  void test_inferCompilationUnit_getter_single() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(fieldB.type, fieldA.type);
    expect(getterB.returnType, getterA.returnType);
  }

  void test_inferCompilationUnit_getter_single_inconsistentAccessors() {
    InstanceMemberInferrer inferrer = createInferrer;
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
    ClassElement classB = unit.getType('B');
    FieldElement fieldB = classB.getField(getterName);
    PropertyAccessorElement getterB = classB.getGetter(getterName);
    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);

    inferrer.inferCompilationUnit(unit);

    expect(fieldB.type.isDynamic, isTrue);
    expect(getterB.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_invalid_inheritanceCycle() {
    InstanceMemberInferrer inferrer = createInferrer;
    CompilationUnitElement unit = resolve('''
class A extends C {}
class B extends A {}
class C extends B {}
''');
    inferrer.inferCompilationUnit(unit);
  }

  void test_inferCompilationUnit_method_multiple_different() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_multiple_dynamic() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_multiple_same_nonVoid() {
    InstanceMemberInferrer inferrer = createInferrer;
    String methodName = 'm';
    CompilationUnitElement unit = resolve('''
class A {
  int $methodName() => 0;
}
class B {
  int $methodName() => 0.0;
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

    inferrer.inferCompilationUnit(unit);

    expect(methodC.returnType, expectedType);
  }

  void test_inferCompilationUnit_method_multiple_same_void() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(methodC.returnType, expectedType);
  }

  void test_inferCompilationUnit_method_multiple_void() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(methodC.returnType.isDynamic, isTrue);
  }

  void test_inferCompilationUnit_method_single() {
    InstanceMemberInferrer inferrer = createInferrer;
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

    inferrer.inferCompilationUnit(unit);

    expect(methodB.returnType, methodA.returnType);
  }
}
