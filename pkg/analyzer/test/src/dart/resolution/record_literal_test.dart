// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecordLiteralResolutionTest extends PubPackageResolutionTest {
  test_field_rewrite_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  (f1: r.$1, );
}
''');

    var node = result.findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: PropertyAccess
        target: SimpleIdentifier
          token: r
          element: <testLibrary>::@function::f::@formalParameter::r
          staticType: (int, String)
        operator: .
        propertyName: SimpleIdentifier
          token: $1
          element: <null>
          staticType: int
        staticType: int
  rightParenthesis: )
  staticType: ({int f1})
''');
  }

  test_field_rewrite_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  (r.$1, );
}
''');

    var node = result.findNode.recordLiteral('(r');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    PropertyAccess
      target: SimpleIdentifier
        token: r
        element: <testLibrary>::@function::f::@formalParameter::r
        staticType: (int, String)
      operator: .
      propertyName: SimpleIdentifier
        token: $1
        element: <null>
        staticType: int
      staticType: int
  rightParenthesis: )
  staticType: (int,)
''');
  }

  test_hasContext_functionReference_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>() {}
final ({void Function() f1}) x = (f1: f);
''');

    var node = result.findNode.singleRecordLiteral;
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: FunctionReference
        function: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::f
          staticType: void Function<T>()
        staticType: void Function()
        typeArgumentTypes
          dynamic
  rightParenthesis: )
  staticType: ({void Function() f1})
''');
  }

  test_hasContext_functionReference_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>() {}
final (void Function(), ) x = (f, );
''');

    var node = result.findNode.singleRecordLiteral;
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    FunctionReference
      function: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::f
        staticType: void Function<T>()
      staticType: void Function()
      typeArgumentTypes
        dynamic
  rightParenthesis: )
  staticType: (void Function(),)
''');
  }

  test_hasContext_greatestClosure() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>((List<T>, List<T>) x) {}

test(dynamic d) => f((d, d));
''');

    var node = result.findNode.recordLiteral('(d,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: d
      element: <testLibrary>::@function::test::@formalParameter::d
      staticType: dynamic
    SimpleIdentifier
      token: d
      element: <testLibrary>::@function::test::@formalParameter::d
      staticType: dynamic
  rightParenthesis: )
  staticType: (List<Object?>, List<Object?>)
''');
  }

  test_hasContext_implicitCallReference_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void call() {}
}

final a = A();
final ({void Function() f1}) x = (f1: a);
''');

    var node = result.findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: ImplicitCallReference
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@getter::a
          staticType: A
        element: <testLibrary>::@class::A::@method::call
        staticType: void Function()
  rightParenthesis: )
  staticType: ({void Function() f1})
''');
  }

  test_hasContext_implicitCallReference_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void call() {}
}

final a = A();
final (void Function(), ) x = (a, );
''');

    var node = result.findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    ImplicitCallReference
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@getter::a
        staticType: A
      element: <testLibrary>::@class::A::@method::call
      staticType: void Function()
  rightParenthesis: )
  staticType: (void Function(),)
''');
  }

  test_hasContext_implicitCast_fromDynamic_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
final ({int f1}) x = (f1: a);
''');

    var node = result.findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: SimpleIdentifier
        token: a
        element: <testLibrary>::@getter::a
        staticType: dynamic
  rightParenthesis: )
  staticType: ({int f1})
''');
  }

  test_hasContext_implicitCast_fromDynamic_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
final (int, ) x = (a, );
''');

    var node = result.findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: a
      element: <testLibrary>::@getter::a
      staticType: dynamic
  rightParenthesis: )
  staticType: (int,)
''');
  }

  test_hasContext_mismatchedTypes() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  if (o is (int,)) {
    o = ('',);
  }
}
''');

    var node = result.findNode.recordLiteral("('',");
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleStringLiteral
      literal: ''
  rightParenthesis: )
  staticType: (String,)
''');
  }

  test_hasContext_mixed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A1 {}
class A2 {}
class A3 {}
class A4 {}
class A5 {}

final (A1, A2, A3, {A4 f1, A5 f2}) x = (g(), f1: g(), g(), f2: g(), g());

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A1 Function()
      staticType: A1
      typeArgumentTypes
        A1
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: A4 Function()
        staticType: A4
        typeArgumentTypes
          A4
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A2 Function()
      staticType: A2
      typeArgumentTypes
        A2
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: A5 Function()
        staticType: A5
        typeArgumentTypes
          A5
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A3 Function()
      staticType: A3
      typeArgumentTypes
        A3
  rightParenthesis: )
  staticType: (A1, A2, A3, {A4 f1, A5 f2})
''');
  }

  test_hasContext_mixed_namedWherePositionalExpected() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  if (o is (int,)) {
    o = (f1: g());
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: dynamic Function()
        staticType: dynamic
        typeArgumentTypes
          dynamic
  rightParenthesis: )
  staticType: ({dynamic f1})
''');
  }

  test_hasContext_mixed_nameMismatch() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  if (o is (int, {String f1})) {
    o = (g(), f2: g());
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: dynamic Function()
        staticType: dynamic
        typeArgumentTypes
          dynamic
  rightParenthesis: )
  staticType: (dynamic, {dynamic f2})
''');
  }

  test_hasContext_mixed_positionalWhereNamedExpected() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  if (o is ({int f1})) {
    o = (g(),);
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
  rightParenthesis: )
  staticType: (dynamic,)
''');
  }

  test_hasContext_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final ({int f1, String f2}) x = (f1: g(), f2: g());

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int Function()
        staticType: int
        typeArgumentTypes
          int
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: String Function()
        staticType: String
        typeArgumentTypes
          String
  rightParenthesis: )
  staticType: ({int f1, String f2})
''');
  }

  test_hasContext_named_differentOrder() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final ({int f1, String f2}) x = (f2: g(), f1: g());

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(f2:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: String Function()
        staticType: String
        typeArgumentTypes
          String
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int Function()
        staticType: int
        typeArgumentTypes
          int
  rightParenthesis: )
  staticType: ({int f1, String f2})
''');
  }

  test_hasContext_named_extraInContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
f(Object o) {
  if (o is ({int f1, String f2})) {
    o = (f1: g());
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: dynamic Function()
        staticType: dynamic
        typeArgumentTypes
          dynamic
  rightParenthesis: )
  staticType: ({dynamic f1})
''');
  }

  test_hasContext_named_extraInLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
f(Object o) {
  if (o is ({int f1})) {
    o = (f1: g(), f2: g());
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: dynamic Function()
        staticType: dynamic
        typeArgumentTypes
          dynamic
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: dynamic Function()
        staticType: dynamic
        typeArgumentTypes
          dynamic
  rightParenthesis: )
  staticType: ({dynamic f1, dynamic f2})
''');
  }

  test_hasContext_noImplicitCast_fromDynamicToTop_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
final ({Object? f1}) x = (f1: a);
''');

    var node = result.findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: SimpleIdentifier
        token: a
        element: <testLibrary>::@getter::a
        staticType: dynamic
  rightParenthesis: )
  staticType: ({dynamic f1})
''');
  }

  test_hasContext_noImplicitCast_fromDynamicToTop_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
final (Object?, ) x = (a, );
''');

    var node = result.findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: a
      element: <testLibrary>::@getter::a
      staticType: dynamic
  rightParenthesis: )
  staticType: (dynamic,)
''');
  }

  test_hasContext_notRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final Object x = (g(), g());

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
  rightParenthesis: )
  staticType: (dynamic, dynamic)
''');
  }

  test_hasContext_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final (int, String) x = (g(), g());

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: String Function()
      staticType: String
      typeArgumentTypes
        String
  rightParenthesis: )
  staticType: (int, String)
''');
  }

  test_hasContext_positional_extraInContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
f(Object o) {
  if (o is (int, String)) {
    o = (g(),);
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
  rightParenthesis: )
  staticType: (dynamic,)
''');
  }

  test_hasContext_positional_extraInLiteral() async {
    var result = await resolveTestCodeWithDiagnostics('''
f(Object o) {
  if (o is (int,)) {
    o = (g(), g());
  }
}

T g<T>() => throw 0;
''');

    var node = result.findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
  rightParenthesis: )
  staticType: (dynamic, dynamic)
''');
  }

  test_hasContext_unknownFieldType_noDowncast() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>((T, T) x) {}

test(dynamic d) => f((d, d));
''');

    var node = result.findNode.recordLiteral('(d,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: d
      element: <testLibrary>::@function::test::@formalParameter::d
      staticType: dynamic
    SimpleIdentifier
      token: d
      element: <testLibrary>::@function::test::@formalParameter::d
      staticType: dynamic
  rightParenthesis: )
  staticType: (dynamic, dynamic)
''');
  }

  test_language219_singleField_noComma() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
final x = (0);
''');

    var node = result.findNode.singleVariableDeclaration;
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  declaredFragment: <testLibraryFragment> x@22
''');
  }

  test_language219_singleField_noComma_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
final x = const (0);
//              ^
// [diag.experimentNotEnabled] This requires the 'records' language feature to be enabled.
//                ^
// [diag.recordLiteralOnePositionalNoTrailingComma] A record literal with exactly one positional field requires a trailing comma.
''');

    var node = result.findNode.singleVariableDeclaration;
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  declaredFragment: <testLibraryFragment> x@22
''');
  }

  test_language219_singleField_withComma() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
final x = (0,);
//        ^
// [diag.experimentNotEnabled] This requires the 'records' language feature to be enabled.
''');

    var node = result.findNode.singleVariableDeclaration;
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  declaredFragment: <testLibraryFragment> x@22
''');
  }

  test_language219_twoFields() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
final x = (0, 1);
//        ^
// [diag.experimentNotEnabled] This requires the 'records' language feature to be enabled.
''');

    var node = result.findNode.singleVariableDeclaration;
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 0
      staticType: int
    rightParenthesis: )
    staticType: int
  declaredFragment: <testLibraryFragment> x@22
''');
  }

  test_language219_zeroFields() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
final x = ();
//        ^
// [diag.experimentNotEnabled] This requires the 'records' language feature to be enabled.
''');

    var node = result.findNode.singleVariableDeclaration;
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: <empty> <synthetic>
      element: <null>
      staticType: InvalidType
    rightParenthesis: )
    staticType: InvalidType
  declaredFragment: <testLibraryFragment> x@22
''');
  }

  test_noContext_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final x = ();
''');

    var node = result.findNode.recordLiteral('()');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  rightParenthesis: )
  staticType: ()
''');
  }

  test_noContext_mixed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final x = (0, f1: 1, 2, f2: 3, 4);
''');

    var node = result.findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: IntegerLiteral
        literal: 1
        staticType: int
    IntegerLiteral
      literal: 2
      staticType: int
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: IntegerLiteral
        literal: 3
        staticType: int
    IntegerLiteral
      literal: 4
      staticType: int
  rightParenthesis: )
  staticType: (int, int, int, {int f1, int f2})
''');
  }

  test_noContext_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final x = (f1: 0, f2: true);
''');

    var node = result.findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    RecordLiteralNamedField
      name: f1
      colon: :
      fieldExpression: IntegerLiteral
        literal: 0
        staticType: int
    RecordLiteralNamedField
      name: f2
      colon: :
      fieldExpression: BooleanLiteral
        literal: true
        staticType: bool
  rightParenthesis: )
  staticType: ({int f1, bool f2})
''');
  }

  test_noContext_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final x = (0, true);
''');

    var node = result.findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    BooleanLiteral
      literal: true
      staticType: bool
  rightParenthesis: )
  staticType: (int, bool)
''');
  }

  test_void_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {}

g() => (f(),);
//      ^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
''');

    var node = result.findNode.recordLiteral('(f(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::f
        staticType: void Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: void Function()
      staticType: void
  rightParenthesis: )
  staticType: (void,)
''');
  }
}
