// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics('''
mixin class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');

    assertType(result.findNode.namedType('A {} // 1'), 'A');
    assertType(result.findNode.namedType('A {} // 2'), 'A');
    assertType(result.findNode.namedType('A {} // 3'), 'A');
  }

  test_classTypeAlias_hierarchy() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
class C {}

class X = A with B implements C;
''');

    assertType(result.findNode.namedType('A with'), 'A');
    assertType(result.findNode.namedType('B implements'), 'B');
    assertType(result.findNode.namedType('C;'), 'C');
  }

  test_field_functionTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef F = T Function<T>(int, T);

class C {
  F? f;
}
''');

    var node = result.findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    type: NamedType
      name: F
      question: ?
      element: <testLibrary>::@typeAlias::F
      type: T Function<T>(int, T)?
        alias: <testLibrary>::@typeAlias::F
          nullabilitySuffix: NullabilitySuffix.question
    variables
      VariableDeclaration
        name: f
        declaredFragment: <testLibraryFragment> f@51
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_local_getterNullAwareAccess_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  return x?.isEven;
}
''');

    assertType(result.findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_local_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  int? a = 0;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  int b = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');

    assertType(result.findNode.namedType('int? a'), 'int?');
    assertType(result.findNode.namedType('int b'), 'int');
  }

  test_local_interfaceType_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  List<int?>? a = [];
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  List<int>? b = [];
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  List<int?> c = [];
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
  List<int> d = [];
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
}
''');

    assertType(result.findNode.namedType('List<int?>? a'), 'List<int?>?');
    assertType(result.findNode.namedType('List<int>? b'), 'List<int>?');
    assertType(result.findNode.namedType('List<int?> c'), 'List<int?>');
    assertType(result.findNode.namedType('List<int> d'), 'List<int>');
  }

  test_local_methodNullAwareCall_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool x() => true;
}

f(C? c) {
  return c?.x();
}
''');

    assertType(result.findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_local_nullCoalesceAssign_nullableInt_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  int? x;
  int y = 0;
  x ??= y;
}
''');
    assertType(result.findNode.assignment('x ??= y'), 'int');
  }

  test_local_nullCoalesceAssign_nullableInt_nullableInt() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  int? x;
  x ??= x;
}
''');
    assertType(result.findNode.assignment('x ??= x'), 'int?');
  }

  test_local_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T>(T a) {
  T x = a;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  T? y;
//   ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');

    assertType(result.findNode.namedType('T x'), 'T');
    assertType(result.findNode.namedType('T? y'), 'T?');
  }

  test_local_variable_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  int? Function(bool, String?)? a;
//                              ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');

    assertType(
      result.findNode.genericFunctionType('Function('),
      'int? Function(bool, String?)?',
    );
  }

  test_localFunction_parameter_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  f(int? a, int b) {}
//^
// [diag.unusedElement] The declaration 'f' isn't referenced.
}
''');

    assertType(result.findNode.namedType('int? a'), 'int?');
    assertType(result.findNode.namedType('int b'), 'int');
  }

  test_localFunction_returnType_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  int? f() => 0;
//     ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
  int g() => 0;
//    ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');

    assertType(result.findNode.namedType('int? f'), 'int?');
    assertType(result.findNode.namedType('int g'), 'int');
  }

  test_member_potentiallyNullable_called() async {
    var result = await resolveTestCode(r'''
m<T extends Function>() {
  List<T?> x;
  x.first();
}
''');
    // Do not assert no test errors. Deliberately invokes nullable type.
    var invocation = result.findNode.functionExpressionInvocation('first()');
    assertType(invocation.function, 'T?');
  }

  test_mixin_hierarchy() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');

    assertType(result.findNode.namedType('A {} // 1'), 'A');
    assertType(result.findNode.namedType('A {} // 2'), 'A');
  }

  test_parameter_functionTyped() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f1(void p1()) {}
void f2(void p2()?) {}
void f3({void p3()?}) {}
''');

    var node1 = result.findNode.formalParameterList('p1');
    assertResolvedNodeText(node1, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    name: p1
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
    declaredFragment: <testLibraryFragment> p1@13
      element: isPublic
        type: void Function()
  rightParenthesis: )
''');

    var node2 = result.findNode.formalParameterList('p2');
    assertResolvedNodeText(node2, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    name: p2
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    declaredFragment: <testLibraryFragment> p2@35
      element: isPublic
        type: void Function()?
  rightParenthesis: )
''');

    var node3 = result.findNode.formalParameterList('p3');
    assertResolvedNodeText(node3, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    name: p3
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    declaredFragment: <testLibraryFragment> p3@59
      element: isPublic
        type: void Function()?
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_parameter_functionTyped_fieldFormal() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  var f1;
  var f2;
  var f3;
  A.f1(void this.f1());
  A.f2(void this.f2()?);
  A.f3({void this.f3()?});
}
''');

    var node1 = result.findNode.formalParameterList('f1()');
    assertResolvedNodeText(node1, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    thisKeyword: this
    period: .
    name: f1
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
    declaredFragment: <testLibraryFragment> f1@57
      element: isFinal isPublic
        type: void Function()
        field: <testLibrary>::@class::A::@field::f1
  rightParenthesis: )
''');

    var node2 = result.findNode.formalParameterList('f2()');
    assertResolvedNodeText(node2, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    thisKeyword: this
    period: .
    name: f2
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    declaredFragment: <testLibraryFragment> f2@81
      element: isFinal isPublic
        type: void Function()?
        field: <testLibrary>::@class::A::@field::f2
  rightParenthesis: )
''');

    var node3 = result.findNode.formalParameterList('f3()');
    assertResolvedNodeText(node3, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: FieldFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    thisKeyword: this
    period: .
    name: f3
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    declaredFragment: <testLibraryFragment> f3@107
      element: isFinal isPublic
        type: void Function()?
        field: <testLibrary>::@class::A::@field::f3
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_parameter_functionTyped_local() async {
    var result = await resolveTestCodeWithDiagnostics('''
f() {
  void f1(void p1()) {}
//     ^^
// [diag.unusedElement] The declaration 'f1' isn't referenced.
  void f2(void p2()?) {}
//     ^^
// [diag.unusedElement] The declaration 'f2' isn't referenced.
  void f3({void p3()?}) {}
//     ^^
// [diag.unusedElement] The declaration 'f3' isn't referenced.
}
''');

    var node1 = result.findNode.formalParameterList('p1');
    assertResolvedNodeText(node1, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    name: p1
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
    declaredFragment: <testLibraryFragment> p1@21
      element: isPublic
        type: void Function()
  rightParenthesis: )
''');

    var node2 = result.findNode.formalParameterList('p2');
    assertResolvedNodeText(node2, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    name: p2
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    declaredFragment: <testLibraryFragment> p2@45
      element: isPublic
        type: void Function()?
  rightParenthesis: )
''');

    var node3 = result.findNode.formalParameterList('p3');
    assertResolvedNodeText(node3, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: void
      element: <null>
      type: void
    name: p3
    functionTypedSuffix: FunctionTypedFormalParameterSuffix
      formalParameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      question: ?
    declaredFragment: <testLibraryFragment> p3@71
      element: isPublic
        type: void Function()?
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_parameter_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int? Function(bool, String?)? a) {
}
''');

    assertType(
      result.findNode.genericFunctionType('Function('),
      'int? Function(bool, String?)?',
    );
  }

  test_parameter_getterNullAwareAccess_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  x?.isEven;
}
''');

    assertType(result.findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_parameter_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int? a, int b) {
}
''');

    assertType(result.findNode.namedType('int? a'), 'int?');
    assertType(result.findNode.namedType('int b'), 'int');
  }

  test_parameter_interfaceType_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(List<int?>? a, List<int>? b, List<int?> c, List<int> d) {
}
''');

    assertType(result.findNode.namedType('List<int?>? a'), 'List<int?>?');
    assertType(result.findNode.namedType('List<int>? b'), 'List<int>?');
    assertType(result.findNode.namedType('List<int?> c'), 'List<int?>');
    assertType(result.findNode.namedType('List<int> d'), 'List<int>');
  }

  test_parameter_methodNullAwareCall_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool x() => true;
}

void f(C? c) {
  c?.x();
}
''');

    assertType(result.findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_parameter_nullCoalesceAssign_nullableInt_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x, int y) {
  x ??= y;
}
''');
    assertType(result.findNode.assignment('x ??= y'), 'int');
  }

  test_parameter_nullCoalesceAssign_nullableInt_nullableInt() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  x ??= x;
}
''');
    assertType(result.findNode.assignment('x ??= x'), 'int?');
  }

  test_parameter_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T>(T a, T? b) {
}
''');

    assertType(result.findNode.namedType('T a'), 'T');
    assertType(result.findNode.namedType('T? b'), 'T?');
  }

  test_typedef_classic() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef int? F(bool a, String? b);

main() {
  F? a;
//   ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');

    assertType(
      result.findNode.namedType('F? a'),
      'int? Function(bool, String?)?',
    );
  }

  test_typedef_function() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef F<T> = int? Function(bool, T, T?);

main() {
  F<String>? a;
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');

    assertType(
      result.findNode.namedType('F<String>'),
      'int? Function(bool, String, String?)?',
    );
  }

  test_typedef_function_nullable_element() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef F<T> = int Function(T)?;

void f(F<int> a, F<double>? b) {}
''');

    assertType(result.findNode.namedType('F<int>'), 'int Function(int)?');
    assertType(
      result.findNode.namedType('F<double>?'),
      'int Function(double)?',
    );
  }

  test_typedef_function_nullable_local() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef F<T> = int Function(T)?;

main() {
  F<int> a;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  F<double>? b;
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');

    assertType(result.findNode.namedType('F<int>'), 'int Function(int)?');
    assertType(
      result.findNode.namedType('F<double>?'),
      'int Function(double)?',
    );
  }
}
