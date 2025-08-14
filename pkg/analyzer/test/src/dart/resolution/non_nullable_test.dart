// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonNullableTest extends PubPackageResolutionTest {
  test_class_hierarchy() async {
    await assertNoErrorsInCode('''
mixin class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');

    assertType(findNode.namedType('A {} // 1'), 'A');
    assertType(findNode.namedType('A {} // 2'), 'A');
    assertType(findNode.namedType('A {} // 3'), 'A');
  }

  test_classTypeAlias_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}
mixin B {}
class C {}

class X = A with B implements C;
''');

    assertType(findNode.namedType('A with'), 'A');
    assertType(findNode.namedType('B implements'), 'B');
    assertType(findNode.namedType('C;'), 'C');
  }

  test_field_functionTypeAlias() async {
    await assertNoErrorsInCode('''
typedef F = T Function<T>(int, T);

class C {
  F? f;
}
''');

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: NamedType
      name: F
      question: ?
      element2: <testLibrary>::@typeAlias::F
      type: T Function<T>(int, T)?
        alias: <testLibrary>::@typeAlias::F
    variables
      VariableDeclaration
        name: f
        declaredElement: <testLibraryFragment> f@51
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_local_getterNullAwareAccess_interfaceType() async {
    await assertNoErrorsInCode(r'''
f(int? x) {
  return x?.isEven;
}
''');

    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_local_interfaceType() async {
    await assertErrorsInCode(
      '''
main() {
  int? a = 0;
  int b = 0;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 16, 1),
        error(WarningCode.unusedLocalVariable, 29, 1),
      ],
    );

    assertType(findNode.namedType('int? a'), 'int?');
    assertType(findNode.namedType('int b'), 'int');
  }

  test_local_interfaceType_generic() async {
    await assertErrorsInCode(
      '''
main() {
  List<int?>? a = [];
  List<int>? b = [];
  List<int?> c = [];
  List<int> d = [];
}
''',
      [
        error(WarningCode.unusedLocalVariable, 23, 1),
        error(WarningCode.unusedLocalVariable, 44, 1),
        error(WarningCode.unusedLocalVariable, 65, 1),
        error(WarningCode.unusedLocalVariable, 85, 1),
      ],
    );

    assertType(findNode.namedType('List<int?>? a'), 'List<int?>?');
    assertType(findNode.namedType('List<int>? b'), 'List<int>?');
    assertType(findNode.namedType('List<int?> c'), 'List<int?>');
    assertType(findNode.namedType('List<int> d'), 'List<int>');
  }

  test_local_methodNullAwareCall_interfaceType() async {
    await assertNoErrorsInCode(r'''
class C {
  bool x() => true;
}

f(C? c) {
  return c?.x();
}
''');

    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_local_nullCoalesceAssign_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
main() {
  int? x;
  int y = 0;
  x ??= y;
}
''');
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_local_nullCoalesceAssign_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
main() {
  int? x;
  x ??= x;
}
''');
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_local_typeParameter() async {
    await assertErrorsInCode(
      '''
void f<T>(T a) {
  T x = a;
  T? y;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 21, 1),
        error(WarningCode.unusedLocalVariable, 33, 1),
      ],
    );

    assertType(findNode.namedType('T x'), 'T');
    assertType(findNode.namedType('T? y'), 'T?');
  }

  test_local_variable_genericFunctionType() async {
    await assertErrorsInCode(
      '''
main() {
  int? Function(bool, String?)? a;
}
''',
      [error(WarningCode.unusedLocalVariable, 41, 1)],
    );

    assertType(
      findNode.genericFunctionType('Function('),
      'int? Function(bool, String?)?',
    );
  }

  test_localFunction_parameter_interfaceType() async {
    await assertErrorsInCode(
      '''
main() {
  f(int? a, int b) {}
}
''',
      [error(WarningCode.unusedElement, 11, 1)],
    );

    assertType(findNode.namedType('int? a'), 'int?');
    assertType(findNode.namedType('int b'), 'int');
  }

  test_localFunction_returnType_interfaceType() async {
    await assertErrorsInCode(
      '''
main() {
  int? f() => 0;
  int g() => 0;
}
''',
      [
        error(WarningCode.unusedElement, 16, 1),
        error(WarningCode.unusedElement, 32, 1),
      ],
    );

    assertType(findNode.namedType('int? f'), 'int?');
    assertType(findNode.namedType('int g'), 'int');
  }

  test_member_potentiallyNullable_called() async {
    await resolveTestCode(r'''
m<T extends Function>() {
  List<T?> x;
  x.first();
}
''');
    // Do not assert no test errors. Deliberately invokes nullable type.
    var invocation = findNode.functionExpressionInvocation('first()');
    assertType(invocation.function, 'T?');
  }

  test_mixin_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');

    assertType(findNode.namedType('A {} // 1'), 'A');
    assertType(findNode.namedType('A {} // 2'), 'A');
  }

  test_parameter_functionTyped() async {
    await assertNoErrorsInCode('''
void f1(void p1()) {}
void f2(void p2()?) {}
void f3({void p3()?}) {}
''');

    var p1 = findNode.formalParameterList('p1');
    assertResolvedNodeText(p1, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FunctionTypedFormalParameter
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: p1
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    declaredElement: <testLibraryFragment> p1@13
      element: isPublic
        type: void Function()
  rightParenthesis: )
''');

    var p2 = findNode.formalParameterList('p2');
    assertResolvedNodeText(p2, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FunctionTypedFormalParameter
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: p2
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    question: ?
    declaredElement: <testLibraryFragment> p2@35
      element: isPublic
        type: void Function()?
  rightParenthesis: )
''');

    var p3 = findNode.formalParameterList('p3');
    assertResolvedNodeText(p3, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FunctionTypedFormalParameter
      returnType: NamedType
        name: void
        element2: <null>
        type: void
      name: p3
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
      declaredElement: <testLibraryFragment> p3@59
        element: isPublic
          type: void Function()?
    declaredElement: <testLibraryFragment> p3@59
      element: isPublic
        type: void Function()?
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_parameter_functionTyped_fieldFormal() async {
    await assertNoErrorsInCode('''
class A {
  var f1;
  var f2;
  var f3;
  A.f1(void this.f1());
  A.f2(void this.f2()?);
  A.f3({void this.f3()?});
}
''');

    var f1 = findNode.formalParameterList('f1()');
    assertResolvedNodeText(f1, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    type: NamedType
      name: void
      element2: <null>
      type: void
    thisKeyword: this
    period: .
    name: f1
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    declaredElement: <testLibraryFragment> f1@57
      element: isFinal isPublic
        type: void Function()
  rightParenthesis: )
''');

    var f2 = findNode.formalParameterList('f2()');
    assertResolvedNodeText(f2, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    type: NamedType
      name: void
      element2: <null>
      type: void
    thisKeyword: this
    period: .
    name: f2
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    question: ?
    declaredElement: <testLibraryFragment> f2@81
      element: isFinal isPublic
        type: void Function()?
  rightParenthesis: )
''');

    var f3 = findNode.formalParameterList('f3()');
    assertResolvedNodeText(f3, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FieldFormalParameter
      type: NamedType
        name: void
        element2: <null>
        type: void
      thisKeyword: this
      period: .
      name: f3
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
      declaredElement: <testLibraryFragment> f3@107
        element: isFinal isPublic
          type: void Function()?
    declaredElement: <testLibraryFragment> f3@107
      element: isFinal isPublic
        type: void Function()?
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_parameter_functionTyped_local() async {
    await assertErrorsInCode(
      '''
f() {
  void f1(void p1()) {}
  void f2(void p2()?) {}
  void f3({void p3()?}) {}
}
''',
      [
        error(WarningCode.unusedElement, 13, 2),
        error(WarningCode.unusedElement, 37, 2),
        error(WarningCode.unusedElement, 62, 2),
      ],
    );

    var p1 = findNode.formalParameterList('p1');
    assertResolvedNodeText(p1, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FunctionTypedFormalParameter
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: p1
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    declaredElement: <testLibraryFragment> p1@21
      element: isPublic
        type: void Function()
  rightParenthesis: )
''');

    var p2 = findNode.formalParameterList('p2');
    assertResolvedNodeText(p2, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FunctionTypedFormalParameter
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: p2
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    question: ?
    declaredElement: <testLibraryFragment> p2@45
      element: isPublic
        type: void Function()?
  rightParenthesis: )
''');

    var p3 = findNode.formalParameterList('p3');
    assertResolvedNodeText(p3, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: FunctionTypedFormalParameter
      returnType: NamedType
        name: void
        element2: <null>
        type: void
      name: p3
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
      declaredElement: <testLibraryFragment> p3@71
        element: isPublic
          type: void Function()?
    declaredElement: <testLibraryFragment> p3@71
      element: isPublic
        type: void Function()?
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_parameter_genericFunctionType() async {
    await assertNoErrorsInCode('''
void f(int? Function(bool, String?)? a) {
}
''');

    assertType(
      findNode.genericFunctionType('Function('),
      'int? Function(bool, String?)?',
    );
  }

  test_parameter_getterNullAwareAccess_interfaceType() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x?.isEven;
}
''');

    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_parameter_interfaceType() async {
    await assertNoErrorsInCode('''
void f(int? a, int b) {
}
''');

    assertType(findNode.namedType('int? a'), 'int?');
    assertType(findNode.namedType('int b'), 'int');
  }

  test_parameter_interfaceType_generic() async {
    await assertNoErrorsInCode('''
void f(List<int?>? a, List<int>? b, List<int?> c, List<int> d) {
}
''');

    assertType(findNode.namedType('List<int?>? a'), 'List<int?>?');
    assertType(findNode.namedType('List<int>? b'), 'List<int>?');
    assertType(findNode.namedType('List<int?> c'), 'List<int?>');
    assertType(findNode.namedType('List<int> d'), 'List<int>');
  }

  test_parameter_methodNullAwareCall_interfaceType() async {
    await assertNoErrorsInCode(r'''
class C {
  bool x() => true;
}

void f(C? c) {
  c?.x();
}
''');

    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_parameter_nullCoalesceAssign_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
void f(int? x, int y) {
  x ??= y;
}
''');
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_parameter_nullCoalesceAssign_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x ??= x;
}
''');
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_parameter_typeParameter() async {
    await assertNoErrorsInCode('''
void f<T>(T a, T? b) {
}
''');

    assertType(findNode.namedType('T a'), 'T');
    assertType(findNode.namedType('T? b'), 'T?');
  }

  test_typedef_classic() async {
    await assertErrorsInCode(
      '''
typedef int? F(bool a, String? b);

main() {
  F? a;
}
''',
      [error(WarningCode.unusedLocalVariable, 50, 1)],
    );

    assertType(findNode.namedType('F? a'), 'int? Function(bool, String?)?');
  }

  test_typedef_function() async {
    await assertErrorsInCode(
      '''
typedef F<T> = int? Function(bool, T, T?);

main() {
  F<String>? a;
}
''',
      [error(WarningCode.unusedLocalVariable, 66, 1)],
    );

    assertType(
      findNode.namedType('F<String>'),
      'int? Function(bool, String, String?)?',
    );
  }

  test_typedef_function_nullable_element() async {
    await assertNoErrorsInCode('''
typedef F<T> = int Function(T)?;

void f(F<int> a, F<double>? b) {}
''');

    assertType(findNode.namedType('F<int>'), 'int Function(int)?');
    assertType(findNode.namedType('F<double>?'), 'int Function(double)?');
  }

  test_typedef_function_nullable_local() async {
    await assertErrorsInCode(
      '''
typedef F<T> = int Function(T)?;

main() {
  F<int> a;
  F<double>? b;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 52, 1),
        error(WarningCode.unusedLocalVariable, 68, 1),
      ],
    );

    assertType(findNode.namedType('F<int>'), 'int Function(int)?');
    assertType(findNode.namedType('F<double>?'), 'int Function(double)?');
  }
}
