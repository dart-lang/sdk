// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionExpressionTest extends PubPackageResolutionTest {
  test_contextFunctionType_returnType_async_blockBody_futureOrVoid() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';

FutureOr<void> Function() v = () async {
  return 0;
//       ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'Future<void>' function, as required by the closure's context.
};
''');
    _assertReturnType(result, '() async {', 'Future<void>');
  }

  test_contextFunctionType_returnType_async_blockBody_futureVoid() async {
    var result = await resolveTestCodeWithDiagnostics('''
Future<void> Function() v = () async {
  return 0;
//       ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'Future<void>' function, as required by the closure's context.
};
''');
    _assertReturnType(result, '() async {', 'Future<void>');
  }

  test_contextFunctionType_returnType_async_blockBody_objectQ() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Object? Function() v = () async {
  return foo();
};
''');

    var node = result.findNode.functionExpression('() async');
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
              element: <testLibrary>::@function::foo
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
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Future<Object?> Function()
  staticType: Future<Object?> Function()
''');
  }

  test_contextFunctionType_returnType_async_blockBody_objectQ2() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Object? Function() v = () async {
  return;
};
''');
    _assertReturnType(result, '() async', 'Future<Null>');
  }

  test_contextFunctionType_returnType_async_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
Future<num> Function() v = () async => 0;
''');
    _assertReturnType(result, '() async =>', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody2() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Future<int> Function() v = () async => foo();
''');

    var node = result.findNode.functionExpression('() async');
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
        element: <testLibrary>::@function::foo
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: FutureOr<int> Function()
      staticType: FutureOr<int>
      typeArgumentTypes
        FutureOr<int>
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Future<int> Function()
  staticType: Future<int> Function()
''');
  }

  test_contextFunctionType_returnType_async_expressionBody3() async {
    var result = await resolveTestCodeWithDiagnostics('''
Future<int> Function() v = () async => Future.value(0);
''');
    _assertReturnType(result, '() async =>', 'Future<int>');
  }

  test_contextFunctionType_returnType_async_expressionBody_object() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Object Function() v = () async => foo();
''');

    var node = result.findNode.functionExpression('() async');
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
        element: <testLibrary>::@function::foo
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: FutureOr<Object?> Function()
      staticType: FutureOr<Object?>
      typeArgumentTypes
        FutureOr<Object?>
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Future<Object?> Function()
  staticType: Future<Object?> Function()
''');
  }

  test_contextFunctionType_returnType_async_expressionBody_objectQ() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Object? Function() v = () async => foo();
''');

    var node = result.findNode.functionExpression('() async');
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
        element: <testLibrary>::@function::foo
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: FutureOr<Object?> Function()
      staticType: FutureOr<Object?>
      typeArgumentTypes
        FutureOr<Object?>
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Future<Object?> Function()
  staticType: Future<Object?> Function()
''');
  }

  test_contextFunctionType_returnType_asyncStar_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
Stream<num> Function() v = () async* {
  yield 0;
};
''');
    _assertReturnType(result, '() async*', 'Stream<int>');
  }

  test_contextFunctionType_returnType_asyncStar_blockBody2() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Stream<int> Function() v = () async* {
  yield foo();
};
''');

    var node = result.findNode.functionExpression('() async');
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
              element: <testLibrary>::@function::foo
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
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Stream<int> Function()
  staticType: Stream<int> Function()
''');
  }

  test_contextFunctionType_returnType_sync_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
num Function() v = () {
  return 0;
};
''');
    _assertReturnType(result, '() {', 'int');
  }

  test_contextFunctionType_returnType_sync_blockBody2() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

int Function() v = () {
  return foo();
};
''');

    var node = result.findNode.functionExpression('() {');
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
              element: <testLibrary>::@function::foo
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
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: int Function()
  staticType: int Function()
''');
  }

  test_contextFunctionType_returnType_sync_blockBody_void() async {
    var result = await resolveTestCodeWithDiagnostics('''
void Function() v = () {
  return 0;
//       ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'void' function, as required by the closure's context.
};
''');
    _assertReturnType(result, '() {', 'void');
  }

  test_contextFunctionType_returnType_sync_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
num Function() v = () => 0;
''');
    _assertReturnType(result, '() =>', 'int');
  }

  test_contextFunctionType_returnType_sync_expressionBody2() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

int Function() v = () => foo();
''');

    var node = result.findNode.functionExpression('() => foo()');
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
        element: <testLibrary>::@function::foo
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: int Function()
  staticType: int Function()
''');
  }

  test_contextFunctionType_returnType_syncStar_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
Iterable<num> Function() v = () sync* {
  yield 0;
};
''');
    _assertReturnType(result, '() sync*', 'Iterable<int>');
  }

  test_contextFunctionType_returnType_syncStar_blockBody2() async {
    var result = await resolveTestCodeWithDiagnostics('''
T foo<T>() => throw 0;

Iterable<int> Function() v = () sync* {
  yield foo();
};
''');

    var node = result.findNode.functionExpression('() sync*');
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
              element: <testLibrary>::@function::foo
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
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Iterable<int> Function()
  staticType: Iterable<int> Function()
''');
  }

  test_downward_argumentType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> items) {
  items.forEach((item) {
    item;
  });
}
''');

    var node = result.findNode.functionExpression('(item)');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: item
      declaredFragment: <testLibraryFragment> item@43
        element: hasImplicitType isPublic
          type: int
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: item
            element: item@43
            staticType: int
          semicolon: ;
      rightBracket: }
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: void Function(int)
  correspondingParameter: action@null
  staticType: void Function(int)
''');
  }

  test_downward_argumentType_Never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(void Function(Never) a) {}

main() {
  foo((x) {});
}
''');

    var node = result.findNode.functionExpression('(x) {}');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: x
      declaredFragment: <testLibraryFragment> x@53
        element: hasImplicitType isPublic
          type: Object?
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: void Function(Object?)
  correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
  staticType: void Function(Object?)
''');
  }

  test_downward_argumentType_Null() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(void Function(Null) a) {}

main() {
  foo((x) {});
}
''');

    var node = result.findNode.functionExpression('(x) {}');
    assertResolvedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      name: x
      declaredFragment: <testLibraryFragment> x@52
        element: hasImplicitType isPublic
          type: Object?
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: void Function(Object?)
  correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
  staticType: void Function(Object?)
''');
  }

  test_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  final v = <T>(T a) => <T>[a];
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.functionExpression('<T>(');
    assertResolvedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@24
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: T
        element: #E0 T
        type: T
      name: a
      declaredFragment: <testLibraryFragment> a@29
        element: isPublic
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
            element: #E0 T
            type: T
        rightBracket: >
      leftBracket: [
      elements
        SimpleIdentifier
          token: a
          element: a@29
          staticType: T
      rightBracket: ]
      staticType: List<T>
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: List<T> Function<T>(T)
  staticType: List<T> Function<T>(T)
''');
  }

  test_location_field() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  final v = () => 42;
}
''');

    var node = result.findNode.functionExpression('() =>');
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
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: int Function()
  staticType: int Function()
''');
  }

  test_location_topLevelVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
final v = () => 42;
''');

    var node = result.findNode.functionExpression('() =>');
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
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: int Function()
  staticType: int Function()
''');
  }

  test_noContext_returnType_async_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () async {
  return 0;
};
''');
    _assertReturnType(result, '() async {', 'Future<int>');
  }

  test_noContext_returnType_async_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () async => 0;
''');
    _assertReturnType(result, '() async =>', 'Future<int>');
  }

  test_noContext_returnType_asyncStar_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () async* {
  yield 0;
};
''');
    _assertReturnType(result, '() async* {', 'Stream<int>');
  }

  test_noContext_returnType_asyncStar_blockBody_hasReturn_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () async* {
  yield 0;
  return;
};
''');
    _assertReturnType(result, '() async* {', 'Stream<int>');
  }

  test_noContext_returnType_asyncStar_blockBody_hasReturn_noYield() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () async* {
  return;
};
''');
    _assertReturnType(result, '() async* {', 'Stream<dynamic>');
  }

  test_noContext_returnType_asyncStar_blockBody_lubNum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () async* {
  yield 0;
  yield 1.1;
};
''');
    _assertReturnType(result, '() async* {', 'Stream<num>');
  }

  test_noContext_returnType_asyncStar_blockBody_lubObject() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () async* {
  yield 0;
  yield '';
};
''');
    _assertReturnType(result, '() async* {', 'Stream<Object>');
  }

  test_noContext_returnType_asyncStar_blockBody_lubWithNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () async* {
  yield 0;
  yield null;
};
''');
    _assertReturnType(result, '() async* {', 'Stream<int?>');
  }

  test_noContext_returnType_sync_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () {
  return 0;
};
''');
    _assertReturnType(result, '() {', 'int');
  }

  test_noContext_returnType_sync_blockBody_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = (dynamic a) {
  return a;
};
''');
    _assertReturnType(result, '(dynamic a) {', 'dynamic');
  }

  test_noContext_returnType_sync_blockBody_Never() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () {
  throw 42;
};
''');
    _assertReturnType(result, '() {', 'Never');
  }

  test_noContext_returnType_sync_blockBody_notNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = (bool b) {
  if (b) return 0;
  return 1.2;
};
''');
    _assertReturnType(result, '(bool b) {', 'num');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    _assertReturnType(result, '(E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E { a, b }
''');

    var result = await resolveTestCodeWithDiagnostics('''
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
    _assertReturnType(result, '(p.E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_imported_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.19
enum E { a, b }
''');

    var result = await resolveTestCodeWithDiagnostics('''
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
    _assertReturnType(result, '(p.E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_notNullable_switch_onEnum_language219() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    _assertReturnType(result, '(E e) {', 'int');
  }

  test_noContext_returnType_sync_blockBody_null_hasReturn() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = (bool b) {
  if (b) return;
};
''');
    _assertReturnType(result, '(bool b) {', 'Null');
  }

  test_noContext_returnType_sync_blockBody_null_noReturn() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () {};
''');
    _assertReturnType(result, '() {}', 'Null');
  }

  test_noContext_returnType_sync_blockBody_nullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = (bool b) {
  if (b) return 0;
};
''');
    _assertReturnType(result, '(bool b) {', 'int?');
  }

  test_noContext_returnType_sync_blockBody_nullable_switch() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  (int a) {
    switch (a) {
      case 0:
        return 0;
    }
  };
}
''');
    _assertReturnType(result, '(int a) {', 'int?');
  }

  test_noContext_returnType_sync_blockBody_nullable_switch_language219() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    _assertReturnType(result, '(int a) {', 'int?');
  }

  test_noContext_returnType_sync_expressionBody_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = (dynamic a) => a;
''');
    _assertReturnType(result, '(dynamic a) =>', 'dynamic');
  }

  test_noContext_returnType_sync_expressionBody_Never() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () => throw 42;
''');
    _assertReturnType(result, '() =>', 'Never');
  }

  test_noContext_returnType_sync_expressionBody_notNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () => 42;
''');
    _assertReturnType(result, '() =>', 'int');
  }

  test_noContext_returnType_sync_expressionBody_Null() async {
    var result = await resolveTestCodeWithDiagnostics('''
main() {
  var v = () => null;
  v;
}
''');
    _assertReturnType(result, '() =>', 'Null');
  }

  test_noContext_returnType_syncStar_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () sync* {
  yield 0;
};
''');
    _assertReturnType(result, '() sync* {', 'Iterable<int>');
  }

  test_noContext_returnType_syncStar_blockBody_hasReturn_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () sync* {
  yield 0;
  return;
};
''');
    _assertReturnType(result, '() sync* {', 'Iterable<int>');
  }

  test_noContext_returnType_syncStar_blockBody_hasReturn_noYield() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () sync* {
  return;
};
''');
    _assertReturnType(result, '() sync* {', 'Iterable<dynamic>');
  }

  test_noContext_returnType_syncStar_blockBody_lubNum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () sync* {
  yield 0;
  yield 1.1;
};
''');
    _assertReturnType(result, '() sync* {', 'Iterable<num>');
  }

  test_noContext_returnType_syncStar_blockBody_lubObject() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () sync* {
  yield 0;
  yield '';
};
''');
    _assertReturnType(result, '() sync* {', 'Iterable<Object>');
  }

  test_noContext_returnType_syncStar_blockBody_lubWithNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = () sync* {
  yield 0;
  yield null;
};
''');
    _assertReturnType(result, '() sync* {', 'Iterable<int?>');
  }

  test_targetBoundedByFunctionType_argumentTypeMismatch() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int test<T extends int Function(int)>(T Function() createT) {
  return createT()('');
//                 ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
''');

    var node = result.findNode.functionExpressionInvocation("('')");
    assertResolvedNodeText(node, r'''FunctionExpressionInvocation
  function: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: createT
      element: <testLibrary>::@function::test::@formalParameter::createT
      staticType: T Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: T Function()
    staticType: T
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_targetBoundedByFunctionType_ok() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int test<T extends int Function(int)>(T Function() createT) {
  return createT()(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''FunctionExpressionInvocation
  function: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: createT
      element: <testLibrary>::@function::test::@formalParameter::createT
      staticType: T Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: T Function()
    staticType: T
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  void _assertReturnType(
    TestResolvedUnitResult result,
    String search,
    String expected,
  ) {
    var node = result.findNode.functionExpression(search);
    var element = node.declaredFragment!.element;
    assertType(element.returnType, expected);
  }
}
