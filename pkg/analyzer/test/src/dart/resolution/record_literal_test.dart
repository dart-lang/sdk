// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralResolutionTest);
  });
}

@reflectiveTest
class RecordLiteralResolutionTest extends PubPackageResolutionTest {
  test_field_rewrite_named() async {
    await assertNoErrorsInCode(r'''
void f((int, String) r) {
  (f1: r.$1, );
}
''');

    var node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: PropertyAccess
        target: SimpleIdentifier
          token: r
          staticElement: <testLibraryFragment>::@function::f::@parameter::r
          element: <testLibraryFragment>::@function::f::@parameter::r#element
          staticType: (int, String)
        operator: .
        propertyName: SimpleIdentifier
          token: $1
          staticElement: <null>
          element: <null>
          staticType: int
        staticType: int
  rightParenthesis: )
  staticType: ({int f1})
''');
  }

  test_field_rewrite_positional() async {
    await assertNoErrorsInCode(r'''
void f((int, String) r) {
  (r.$1, );
}
''');

    var node = findNode.recordLiteral('(r');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    PropertyAccess
      target: SimpleIdentifier
        token: r
        staticElement: <testLibraryFragment>::@function::f::@parameter::r
        element: <testLibraryFragment>::@function::f::@parameter::r#element
        staticType: (int, String)
      operator: .
      propertyName: SimpleIdentifier
        token: $1
        staticElement: <null>
        element: <null>
        staticType: int
      staticType: int
  rightParenthesis: )
  staticType: (int,)
''');
  }

  test_hasContext_greatestClosure() async {
    await assertNoErrorsInCode(r'''
void f<T>((List<T>, List<T>) x) {}

test(dynamic d) => f((d, d));
''');

    var node = findNode.recordLiteral('(d,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: d
      staticElement: <testLibraryFragment>::@function::test::@parameter::d
      element: <testLibraryFragment>::@function::test::@parameter::d#element
      staticType: dynamic
    SimpleIdentifier
      token: d
      staticElement: <testLibraryFragment>::@function::test::@parameter::d
      element: <testLibraryFragment>::@function::test::@parameter::d#element
      staticType: dynamic
  rightParenthesis: )
  staticType: (List<Object?>, List<Object?>)
''');
  }

  test_hasContext_implicitCallReference_named() async {
    await assertNoErrorsInCode(r'''
class A {
  void call() {}
}

final a = A();
final ({void Function() f1}) x = (f1: a);
''');

    var node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: ImplicitCallReference
        expression: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
          staticType: A
        staticElement: <testLibraryFragment>::@class::A::@method::call
        element: <testLibraryFragment>::@class::A::@method::call#element
        staticType: void Function()
  rightParenthesis: )
  staticType: ({void Function() f1})
''');
  }

  test_hasContext_implicitCallReference_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  void call() {}
}

final a = A();
final (void Function(), ) x = (a, );
''');

    var node = findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    ImplicitCallReference
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@getter::a
        element: <testLibraryFragment>::@getter::a#element
        staticType: A
      staticElement: <testLibraryFragment>::@class::A::@method::call
      element: <testLibraryFragment>::@class::A::@method::call#element
      staticType: void Function()
  rightParenthesis: )
  staticType: (void Function(),)
''');
  }

  test_hasContext_implicitCast_fromDynamic_named() async {
    await assertNoErrorsInCode(r'''
final dynamic a = 0;
final ({int f1}) x = (f1: a);
''');

    var node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@getter::a
        element: <testLibraryFragment>::@getter::a#element
        staticType: dynamic
  rightParenthesis: )
  staticType: ({int f1})
''');
  }

  test_hasContext_implicitCast_fromDynamic_positional() async {
    await assertNoErrorsInCode(r'''
final dynamic a = 0;
final (int, ) x = (a, );
''');

    var node = findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@getter::a
      element: <testLibraryFragment>::@getter::a#element
      staticType: dynamic
  rightParenthesis: )
  staticType: (int,)
''');
  }

  test_hasContext_mismatchedTypes() async {
    await assertNoErrorsInCode(r'''
f(Object o) {
  if (o is (int,)) {
    o = ('',);
  }
}
''');

    var node = findNode.recordLiteral("('',");
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
    await assertNoErrorsInCode(r'''
class A1 {}
class A2 {}
class A3 {}
class A4 {}
class A5 {}

final (A1, A2, A3, {A4 f1, A5 f2}) x = (g(), f1: g(), g(), f2: g(), g());

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A1 Function()
      staticType: A1
      typeArgumentTypes
        A1
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: A2 Function()
      staticType: A2
      typeArgumentTypes
        A2
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
f(Object o) {
  if (o is (int,)) {
    o = (f1: g());
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
f(Object o) {
  if (o is (int, {String f1})) {
    o = (g(), f2: g());
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
      typeArgumentTypes
        dynamic
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
f(Object o) {
  if (o is ({int f1})) {
    o = (g(),);
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
final ({int f1, String f2}) x = (f1: g(), f2: g());

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int Function()
        staticType: int
        typeArgumentTypes
          int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
final ({int f1, String f2}) x = (f2: g(), f1: g());

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(f2:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: String Function()
        staticType: String
        typeArgumentTypes
          String
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode('''
f(Object o) {
  if (o is ({int f1, String f2})) {
    o = (f1: g());
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode('''
f(Object o) {
  if (o is ({int f1})) {
    o = (f1: g(), f2: g());
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: dynamic Function()
        staticType: dynamic
        typeArgumentTypes
          dynamic
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
final dynamic a = 0;
final ({Object? f1}) x = (f1: a);
''');

    var node = findNode.recordLiteral('(f1');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@getter::a
        element: <testLibraryFragment>::@getter::a#element
        staticType: dynamic
  rightParenthesis: )
  staticType: ({dynamic f1})
''');
  }

  test_hasContext_noImplicitCast_fromDynamicToTop_positional() async {
    await assertNoErrorsInCode(r'''
final dynamic a = 0;
final (Object?, ) x = (a, );
''');

    var node = findNode.recordLiteral('(a');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@getter::a
      element: <testLibraryFragment>::@getter::a#element
      staticType: dynamic
  rightParenthesis: )
  staticType: (dynamic,)
''');
  }

  test_hasContext_notRecordType() async {
    await assertNoErrorsInCode(r'''
final Object x = (g(), g());

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
final (int, String) x = (g(), g());

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode('''
f(Object o) {
  if (o is (int, String)) {
    o = (g(),);
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode('''
f(Object o) {
  if (o is (int,)) {
    o = (g(), g());
  }
}

T g<T>() => throw 0;
''');

    var node = findNode.recordLiteral('(g(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertNoErrorsInCode(r'''
void f<T>((T, T) x) {}

test(dynamic d) => f((d, d));
''');

    var node = findNode.recordLiteral('(d,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    SimpleIdentifier
      token: d
      staticElement: <testLibraryFragment>::@function::test::@parameter::d
      element: <testLibraryFragment>::@function::test::@parameter::d#element
      staticType: dynamic
    SimpleIdentifier
      token: d
      staticElement: <testLibraryFragment>::@function::test::@parameter::d
      element: <testLibraryFragment>::@function::test::@parameter::d#element
      staticType: dynamic
  rightParenthesis: )
  staticType: (dynamic, dynamic)
''');
  }

  test_language219_singleField_noComma() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
final x = (0);
''');

    var node = findNode.singleVariableDeclaration;
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
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  test_language219_singleField_noComma_const() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
final x = const (0);
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 32, 1),
      error(ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA, 34,
          1),
    ]);

    var node = findNode.singleVariableDeclaration;
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
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  test_language219_singleField_withComma() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
final x = (0,);
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);

    var node = findNode.singleVariableDeclaration;
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
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  test_language219_twoFields() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
final x = (0, 1);
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);

    var node = findNode.singleVariableDeclaration;
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
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  test_language219_zeroFields() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
final x = ();
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);

    var node = findNode.singleVariableDeclaration;
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: <empty> <synthetic>
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    rightParenthesis: )
    staticType: InvalidType
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  test_noContext_empty() async {
    await assertNoErrorsInCode(r'''
final x = ();
''');

    var node = findNode.recordLiteral('()');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  rightParenthesis: )
  staticType: ()
''');
  }

  test_noContext_mixed() async {
    await assertNoErrorsInCode(r'''
final x = (0, f1: 1, 2, f2: 3, 4);
''');

    var node = findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 1
        staticType: int
    IntegerLiteral
      literal: 2
      staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
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
    await assertNoErrorsInCode(r'''
final x = (f1: 0, f2: true);
''');

    var node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 0
        staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          element: <null>
          staticType: null
        colon: :
      expression: BooleanLiteral
        literal: true
        staticType: bool
  rightParenthesis: )
  staticType: ({int f1, bool f2})
''');
  }

  test_noContext_positional() async {
    await assertNoErrorsInCode(r'''
final x = (0, true);
''');

    var node = findNode.recordLiteral('(0,');
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
    await assertErrorsInCode(r'''
void f() {}

g() => (f(),);
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 21, 3),
    ]);

    var node = findNode.recordLiteral('(f(),');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    MethodInvocation
      methodName: SimpleIdentifier
        token: f
        staticElement: <testLibraryFragment>::@function::f
        element: <testLibraryFragment>::@function::f#element
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
