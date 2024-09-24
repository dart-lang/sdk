// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest);
  });
}

@reflectiveTest
class FunctionExpressionTest extends PubPackageResolutionTest {
  test_contextFunctionType_returnType_async_blockBody_futureOrVoid() async {
    await assertErrorsInCode('''
import 'dart:async';

FutureOr<void> Function() v = () async {
  return 0;
};
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 72, 1),
    ]);
    _assertReturnType('() async {', 'Future<void>');
  }

  test_contextFunctionType_returnType_async_blockBody_futureVoid() async {
    await assertErrorsInCode('''
Future<void> Function() v = () async {
  return 0;
};
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 48, 1),
    ]);
    _assertReturnType('() async {', 'Future<void>');
  }

  test_contextFunctionType_returnType_async_blockBody_objectQ() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object? Function() v = () async {
  return foo();
};
''');

    var node = findNode.functionExpression('() async');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: async
    block: Block
      leftBracket: {
      statements
        ReturnStatement
          returnKeyword: return
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: foo
              staticElement: <testLibraryFragment>::@function::foo
              element: <testLibraryFragment>::@function::foo#element
              staticType: T Function<T>()
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticInvokeType: FutureOr<Object?> Function()
            staticType: FutureOr<Object?>
            typeArgumentTypes
              FutureOr<Object?>
          semicolon: ;
      rightBracket: }
  declaredElement: @47
    type: Future<Object?> Function()
  staticType: Future<Object?> Function()
''');
  }

  test_contextFunctionType_returnType_async_blockBody_objectQ2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object? Function() v = () async {
  return;
};
''');
    _assertReturnType('() async', 'Future<Null>');
  }

  test_contextFunctionType_returnType_async_expressionBody() async {
    await assertNoErrorsInCode('''
Future<num> Function() v = () async => 0;
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Future<int> Function() v = () async => foo();
''');

    var node = findNode.functionExpression('() async');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    keyword: async
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@function::foo
        element: <testLibraryFragment>::@function::foo#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: FutureOr<int> Function()
      staticType: FutureOr<int>
      typeArgumentTypes
        FutureOr<int>
  declaredElement: @51
    type: Future<int> Function()
  staticType: Future<int> Function()
''');
  }

  test_contextFunctionType_returnType_async_expressionBody3() async {
    await assertNoErrorsInCode('''
Future<int> Function() v = () async => Future.value(0);
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody_object() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object Function() v = () async => foo();
''');

    var node = findNode.functionExpression('() async');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    keyword: async
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@function::foo
        element: <testLibraryFragment>::@function::foo#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: FutureOr<Object?> Function()
      staticType: FutureOr<Object?>
      typeArgumentTypes
        FutureOr<Object?>
  declaredElement: @46
    type: Future<Object?> Function()
  staticType: Future<Object?> Function()
''');
  }

  test_contextFunctionType_returnType_async_expressionBody_objectQ() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Object? Function() v = () async => foo();
''');

    var node = findNode.functionExpression('() async');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    keyword: async
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@function::foo
        element: <testLibraryFragment>::@function::foo#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: FutureOr<Object?> Function()
      staticType: FutureOr<Object?>
      typeArgumentTypes
        FutureOr<Object?>
  declaredElement: @47
    type: Future<Object?> Function()
  staticType: Future<Object?> Function()
''');
  }

  test_contextFunctionType_returnType_asyncStar_blockBody() async {
    await assertNoErrorsInCode('''
Stream<num> Function() v = () async* {
  yield 0;
};
''');
    _assertReturnType('() async*', 'Stream<int>');
  }

  test_contextFunctionType_returnType_asyncStar_blockBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Stream<int> Function() v = () async* {
  yield foo();
};
''');

    var node = findNode.functionExpression('() async');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: async
    star: *
    block: Block
      leftBracket: {
      statements
        YieldStatement
          yieldKeyword: yield
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: foo
              staticElement: <testLibraryFragment>::@function::foo
              element: <testLibraryFragment>::@function::foo#element
              staticType: T Function<T>()
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticInvokeType: int Function()
            staticType: int
            typeArgumentTypes
              int
          semicolon: ;
      rightBracket: }
  declaredElement: @51
    type: Stream<int> Function()
  staticType: Stream<int> Function()
''');
  }

  test_contextFunctionType_returnType_sync_blockBody() async {
    await assertNoErrorsInCode('''
num Function() v = () {
  return 0;
};
''');
    _assertReturnType('() {', 'int');
  }

  test_contextFunctionType_returnType_sync_blockBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

int Function() v = () {
  return foo();
};
''');

    var node = findNode.functionExpression('() {');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ReturnStatement
          returnKeyword: return
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: foo
              staticElement: <testLibraryFragment>::@function::foo
              element: <testLibraryFragment>::@function::foo#element
              staticType: T Function<T>()
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticInvokeType: int Function()
            staticType: int
            typeArgumentTypes
              int
          semicolon: ;
      rightBracket: }
  declaredElement: @43
    type: int Function()
  staticType: int Function()
''');
  }

  test_contextFunctionType_returnType_sync_blockBody_void() async {
    await assertErrorsInCode('''
void Function() v = () {
  return 0;
};
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 34, 1),
    ]);
    _assertReturnType('() {', 'void');
  }

  test_contextFunctionType_returnType_sync_expressionBody() async {
    await assertNoErrorsInCode('''
num Function() v = () => 0;
''');
    _assertReturnType('() =>', 'int');
  }

  test_contextFunctionType_returnType_sync_expressionBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

int Function() v = () => foo();
''');

    var node = findNode.functionExpression('() => foo()');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@function::foo
        element: <testLibraryFragment>::@function::foo#element
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
  declaredElement: @43
    type: int Function()
  staticType: int Function()
''');
  }

  test_contextFunctionType_returnType_syncStar_blockBody() async {
    await assertNoErrorsInCode('''
Iterable<num> Function() v = () sync* {
  yield 0;
};
''');
    _assertReturnType('() sync*', 'Iterable<int>');
  }

  test_contextFunctionType_returnType_syncStar_blockBody2() async {
    await assertNoErrorsInCode('''
T foo<T>() => throw 0;

Iterable<int> Function() v = () sync* {
  yield foo();
};
''');

    var node = findNode.functionExpression('() sync*');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: sync
    star: *
    block: Block
      leftBracket: {
      statements
        YieldStatement
          yieldKeyword: yield
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: foo
              staticElement: <testLibraryFragment>::@function::foo
              element: <testLibraryFragment>::@function::foo#element
              staticType: T Function<T>()
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticInvokeType: int Function()
            staticType: int
            typeArgumentTypes
              int
          semicolon: ;
      rightBracket: }
  declaredElement: @53
    type: Iterable<int> Function()
  staticType: Iterable<int> Function()
''');
  }

  test_downward_argumentType() async {
    await assertNoErrorsInCode(r'''
void f(List<int> items) {
  items.forEach((item) {
    item;
  });
}
''');

    var node = findNode.functionExpression('(item)');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      name: item
      declaredElement: @42::@parameter::item
        type: int
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: item
            staticElement: @42::@parameter::item
            element: @42::@parameter::item#element
            staticType: int
          semicolon: ;
      rightBracket: }
  declaredElement: @42
    type: void Function(int)
  parameter: root::@parameter::f
  staticType: void Function(int)
''');
  }

  test_downward_argumentType_Never() async {
    await assertNoErrorsInCode(r'''
void foo(void Function(Never) a) {}

main() {
  foo((x) {});
}
''');

    var node = findNode.functionExpression('(x) {}');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      name: x
      declaredElement: @52::@parameter::x
        type: Object?
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: @52
    type: void Function(Object?)
  parameter: <testLibraryFragment>::@function::foo::@parameter::a
  staticType: void Function(Object?)
''');
  }

  test_downward_argumentType_Null() async {
    await resolveTestCode(r'''
void foo(void Function(Null) a) {}

main() {
  foo((x) {});
}
''');

    var node = findNode.functionExpression('(x) {}');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      name: x
      declaredElement: @51::@parameter::x
        type: Object?
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: @51
    type: void Function(Object?)
  parameter: <testLibraryFragment>::@function::foo::@parameter::a
  staticType: void Function(Object?)
''');
  }

  test_generic() async {
    await assertErrorsInCode('''
void f() {
  final v = <T>(T a) => <T>[a];
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);

    var node = findNode.functionExpression('<T>(');
    assertResolvedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: T@24
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element: T@24
        element2: <not-implemented>
        type: T
      name: a
      declaredElement: @23::@parameter::a
        type: T
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
            element: T@24
            element2: <not-implemented>
            type: T
        rightBracket: >
      leftBracket: [
      elements
        SimpleIdentifier
          token: a
          staticElement: @23::@parameter::a
          element: @23::@parameter::a#element
          staticType: T
      rightBracket: ]
      staticType: List<T>
  declaredElement: @23
    type: List<T> Function<T>(T)
  staticType: List<T> Function<T>(T)
''');
  }

  test_location_field() async {
    await assertNoErrorsInCode('''
class A {
  final v = () => 42;
}
''');

    var node = findNode.functionExpression('() =>');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 42
      staticType: int
  declaredElement: @22
    type: int Function()
  staticType: int Function()
''');
  }

  test_location_topLevelVariable() async {
    await assertNoErrorsInCode('''
final v = () => 42;
''');

    var node = findNode.functionExpression('() =>');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 42
      staticType: int
  declaredElement: @10
    type: int Function()
  staticType: int Function()
''');
  }

  test_noContext_returnType_async_blockBody() async {
    await resolveTestCode('''
var v = () async {
  return 0;
};
''');
    _assertReturnType('() async {', 'Future<int>');
  }

  test_noContext_returnType_async_expressionBody() async {
    await resolveTestCode('''
var v = () async => 0;
''');
    _assertReturnType('() async =>', 'Future<int>');
  }

  test_noContext_returnType_asyncStar_blockBody() async {
    await resolveTestCode('''
var v = () async* {
  yield 0;
};
''');
    _assertReturnType('() async* {', 'Stream<int>');
  }

  test_noContext_returnType_sync_blockBody() async {
    await resolveTestCode('''
var v = () {
  return 0;
};
''');
    _assertReturnType('() {', 'int');
  }

  test_noContext_returnType_sync_blockBody_dynamic() async {
    await resolveTestCode('''
var v = (dynamic a) {
  return a;
};
''');
    _assertReturnType('(dynamic a) {', 'dynamic');
  }

  test_noContext_returnType_sync_blockBody_Never() async {
    await resolveTestCode('''
var v = () {
  throw 42;
};
''');
    _assertReturnType('() {', 'Never');
  }

  test_noContext_returnType_sync_blockBody_notNullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
  return 1.2;
};
''');
    _assertReturnType('(bool b) {', 'num');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum() async {
    await assertNoErrorsInCode('''
enum E { a, b }

main() {
  (E e) {
    switch (e) {
      case E.a:
        return 0;
      case E.b:
        return 1;
    }
  };
}
''');
    _assertReturnType('(E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E { a, b }
''');

    await assertNoErrorsInCode('''
import 'a.dart' as p;

main() {
  (p.E e) {
    switch (e) {
      case p.E.a:
        return 0;
      case p.E.b:
        return 1;
    }
  };
}
''');
    _assertReturnType('(p.E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_imported_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.19
enum E { a, b }
''');

    await assertNoErrorsInCode('''
// @dart = 2.19
import 'a.dart' as p;

main() {
  (p.E e) {
    switch (e) {
      case p.E.a:
        return 0;
      case p.E.b:
        return 1;
    }
  };
}
''');
    _assertReturnType('(p.E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_language219() async {
    await assertNoErrorsInCode('''
// @dart = 2.19
enum E { a, b }

main() {
  (E e) {
    switch (e) {
      case E.a:
        return 0;
      case E.b:
        return 1;
    }
  };
}
''');
    _assertReturnType('(E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_null_hasReturn() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return;
};
''');
    _assertReturnType('(bool b) {', 'Null');
  }

  test_noContext_returnType_sync_blockBody_null_noReturn() async {
    await resolveTestCode('''
var v = () {};
''');
    _assertReturnType('() {}', 'Null');
  }

  test_noContext_returnType_sync_blockBody_nullable() async {
    await resolveTestCode('''
var v = (bool b) {
  if (b) return 0;
};
''');
    _assertReturnType('(bool b) {', 'int?');
  }

  test_noContext_returnType_sync_blockBody_nullable_switch() async {
    await assertNoErrorsInCode('''
main() {
  (int a) {
    switch (a) {
      case 0:
        return 0;
    }
  };
}
''');
    _assertReturnType('(int a) {', 'int?');
  }

  test_noContext_returnType_sync_blockBody_nullable_switch_language219() async {
    await assertNoErrorsInCode('''
// @dart = 2.19
main() {
  (int a) {
    switch (a) {
      case 0:
        return 0;
    }
  };
}
''');
    _assertReturnType('(int a) {', 'int?');
  }

  test_noContext_returnType_sync_expressionBody_dynamic() async {
    await resolveTestCode('''
var v = (dynamic a) => a;
''');
    _assertReturnType('(dynamic a) =>', 'dynamic');
  }

  test_noContext_returnType_sync_expressionBody_Never() async {
    await resolveTestCode('''
var v = () => throw 42;
''');
    _assertReturnType('() =>', 'Never');
  }

  test_noContext_returnType_sync_expressionBody_notNullable() async {
    await resolveTestCode('''
var v = () => 42;
''');
    _assertReturnType('() =>', 'int');
  }

  test_noContext_returnType_sync_expressionBody_Null() async {
    await resolveTestCode('''
main() {
  var v = () => null;
  v;
}
''');
    _assertReturnType('() =>', 'Null');
  }

  test_noContext_returnType_syncStar_blockBody() async {
    await resolveTestCode('''
var v = () sync* {
  yield 0;
};
''');
    _assertReturnType('() sync* {', 'Iterable<int>');
  }

  void _assertReturnType(String search, String expected) {
    var element = findNode.functionExpression(search).declaredElement!;
    assertType(element.returnType, expected);
  }
}
