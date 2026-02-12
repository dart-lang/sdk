// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithDeclaration);
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithIdentifier);
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(
      ForElementResolutionTest_ForEachPartsWithPattern_await,
    );
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithDeclarations);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithExpression);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithPattern);
  });
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest {
  test_async_loopVariable_var_stream() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> values) async {
  <int>[await for (var v in values) v];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@58
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: v
    element: v@58
    staticType: int
''');
  }

  test_sync_loopVariable_var_iterable() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i in [1]) i]; // 1
  <double>[for (var i in [1.1]) i]; // 2
}
''');

    var node_1 = findNode.simple('i]; // 1');
    assertResolvedNodeText(node_1, r'''
SimpleIdentifier
  token: i
  element: i@26
  staticType: int
''');

    var node_2 = findNode.simple('i]; // 2');
    assertResolvedNodeText(node_2, r'''
SimpleIdentifier
  token: i
  element: i@65
  staticType: double
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithIdentifier
    extends PubPackageResolutionTest {
  test_async_iterable_stream() async {
    await assertNoErrorsInCode(r'''
void f(v, Stream<int> values) async {
  <int>[await for (v in values) v];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: v
    element: <testLibrary>::@function::f::@formalParameter::v
    staticType: dynamic
''');
  }

  test_sync_iterable_contextType_fromInstanceSetter() async {
    await assertNoErrorsInCode(r'''
T g<T>() => throw 0;

class C {
  set x(int value) {}

  void f() {
    [for (x in g()) 0];
  }
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: x
      element: <testLibrary>::@class::C::@setter::x
      staticType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_sync_iterable_contextType_fromTopLevelSetter() async {
    await assertNoErrorsInCode(r'''
T g<T>() => throw 0;

set x(int value) {}

void f() {
  [for (x in g()) 0];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: x
      element: <testLibrary>::@setter::x
      staticType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_sync_iterable_list() async {
    await assertNoErrorsInCode(r'''
void f(v, List<int> values) {
  [for (v in values) v];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: v
    element: <testLibrary>::@function::f::@formalParameter::v
    staticType: dynamic
''');
  }

  test_sync_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f(v) {
    [for (v in super) 0];
  }
}
''',
      [error(diag.missingAssignableSelector, 73, 5)],
    );
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@class::A::@method::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SuperExpression
      superKeyword: super
      staticType: A
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_sync_iterable_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
int v = 0;
main() {
  <int>[for (v in [1, 2, 3]) v];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@setter::v
      staticType: int
    inKeyword: in
    iterable: ListLiteral
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
          staticType: int
        IntegerLiteral
          literal: 2
          staticType: int
        IntegerLiteral
          literal: 3
          staticType: int
      rightBracket: ]
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: v
    element: <testLibrary>::@getter::v
    staticType: int
''');
  }

  test_sync_scope_iterable_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(dynamic v) {
  [for (v in v) 0];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_sync_iterable_contextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var (int a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@28
          element: isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@28
    staticType: int
''');
  }

  test_sync_iterable_contextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var (a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@24
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<Object?> Function()
      staticType: Iterable<Object?>
      typeArgumentTypes
        Iterable<Object?>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@24
    staticType: Object?
''');
  }

  test_sync_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@25
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@25
    staticType: dynamic
''');
  }

  test_sync_iterable_list() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@35
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@35
    staticType: int
''');
  }

  test_sync_iterable_object() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  [for (var (a) in x) a];
}
''',
      [error(diag.forInOfInvalidType, 38, 1)],
    );
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@32
          element: hasImplicitType isPublic
            type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@32
    staticType: InvalidType
''');
  }

  test_sync_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (final (a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isFinal isPublic a@37
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@37
    staticType: int
''');
  }

  test_sync_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (num a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        name: a
        declaredFragment: isPublic a@39
          element: isPublic
            type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@39
    staticType: num
''');
  }

  test_sync_scope_topLevelVariableInitializer_uses_outer() async {
    await assertNoErrorsInCode(r'''
final x = [0, 1, 2];
final y = [ for (var (x) in x) x ];
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: x
        declaredFragment: isPublic x@43
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@getter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: x
    element: x@43
    staticType: int
''');
  }

  test_sync_topLevelVariableInitializer() async {
    await assertNoErrorsInCode(r'''
final x = [0, 1, 2];
final y = [ for (var (a) in x) a ];
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@43
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@getter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@43
    staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern_await
    extends PubPackageResolutionTest {
  test_async_iterable_contextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() async {
  [await for (var (int a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@40
          element: isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<int> Function()
      staticType: Stream<int>
      typeArgumentTypes
        Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@40
    staticType: int
''');
  }

  test_async_iterable_contextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() async {
  [await for (var (a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@36
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<Object?> Function()
      staticType: Stream<Object?>
      typeArgumentTypes
        Stream<Object?>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@36
    staticType: Object?
''');
  }

  test_async_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) async {
  [await for (var (a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@37
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@37
    staticType: dynamic
''');
  }

  test_async_iterable_object() async {
    await assertErrorsInCode(
      r'''
void f(Object x) async {
  [await for (var (a) in x) a];
}
''',
      [error(diag.forInOfInvalidType, 50, 1)],
    );
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@44
          element: hasImplicitType isPublic
            type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@44
    staticType: InvalidType
''');
  }

  test_async_iterable_stream() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (var (a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@49
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@49
    staticType: int
''');
  }

  test_async_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (final (a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isFinal isPublic a@51
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@51
    staticType: int
''');
  }

  test_async_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (var (num a) in x) a];
}
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        name: a
        declaredFragment: isPublic a@53
          element: isPublic
            type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@53
    staticType: num
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithDeclarations
    extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  <int>[for (; b(); ) 0];
}
''');

    var node = findNode.functionExpressionInvocation('b()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: bool Function()
  staticType: bool
''');
  }

  test_scope_initializerVariable_visibleInBody() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');

    var node_1 = findNode.simple('i]; // 1');
    assertResolvedNodeText(node_1, r'''
SimpleIdentifier
  token: i
  element: i@26
  staticType: int
''');

    var node_2 = findNode.simple('i]; // 2');
    assertResolvedNodeText(node_2, r'''
SimpleIdentifier
  token: i
  element: i@78
  staticType: double
''');
  }

  @failingTest
  test_scope_variables_initializer_uses_outer_sameName() async {
    await assertErrorsInCode(
      r'''
void f(int i) {
  [for (var i = i; i < 1; i++) i];
}
''',
      [
        error(
          diag.referencedBeforeDeclaration,
          32,
          1,
          contextMessages: [message(testFile, 28, 1)],
        ),
      ],
    );

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i
          equals: =
          initializer: SimpleIdentifier
            token: i
            element: i@28
            staticType: dynamic
          declaredFragment: isPublic i@28
            element: hasImplicitType isPublic
              type: dynamic
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i
        element: i@28
        staticType: dynamic
      operator: <
      rightOperand: IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
      element: <null>
      staticInvokeType: null
      staticType: dynamic
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: i
          element: i@28
          staticType: null
        operator: ++
        readElement: i@28
        readType: dynamic
        writeElement: i@28
        writeType: dynamic
        element: <null>
        staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: i
    element: i@28
    staticType: dynamic
''');
  }

  test_scope_variables_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(int i) {
  [for (var i2 = i; i2 < 10; ++i2) i2];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i2
          equals: =
          initializer: SimpleIdentifier
            token: i
            element: <testLibrary>::@function::f::@formalParameter::i
            staticType: int
          declaredFragment: isPublic i2@28
            element: hasImplicitType isPublic
              type: int
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i2
        element: i2@28
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 10
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PrefixExpression
        operator: ++
        operand: SimpleIdentifier
          token: i2
          element: i2@28
          staticType: null
        readElement: i2@28
        readType: int
        writeElement: i2@28
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: SimpleIdentifier
    token: i2
    element: i2@28
    staticType: int
''');
  }

  test_scope_variables_visibleInNextVariableInitializer() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var i = 0, j = i; j < 1; j++) j];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i
          equals: =
          initializer: IntegerLiteral
            literal: 0
            staticType: int
          declaredFragment: isPublic i@23
            element: hasImplicitType isPublic
              type: int
        VariableDeclaration
          name: j
          equals: =
          initializer: SimpleIdentifier
            token: i
            element: i@23
            staticType: int
          declaredFragment: isPublic j@30
            element: hasImplicitType isPublic
              type: int
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: j
        element: j@30
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 1
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: j
          element: j@30
          staticType: null
        operator: ++
        readElement: j@30
        readType: int
        writeElement: j@30
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: SimpleIdentifier
    token: j
    element: j@30
    staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithExpression
    extends PubPackageResolutionTest {
  test_initialization_patternAssignment() async {
    await assertNoErrorsInCode(r'''
void f() {
  int a;
  [for ((a) = 0;;) a];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    initialization: PatternAssignment
      pattern: ParenthesizedPattern
        leftParenthesis: (
        pattern: AssignedVariablePattern
          name: a
          element: a@17
          matchedValueType: int
        rightParenthesis: )
        matchedValueType: int
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
      patternTypeSchema: int
      staticType: int
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@17
    staticType: int
''');
  }

  test_update_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    [for (;; super) 0];
  }
}
''',
      [error(diag.missingAssignableSelector, 36, 5)],
    );

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    leftSeparator: ;
    rightSeparator: ;
    updaters
      SuperExpression
        superKeyword: super
        staticType: A
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithPattern
    extends PubPackageResolutionTest {
  test_scope_body_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  [for (var (a, b) = x; b; a--) x];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@37
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@40
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@40
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@37
          staticType: null
        operator: --
        readElement: a@37
        readType: int
        writeElement: a@37
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (int, bool)
''');
  }

  test_scope_patternVariables() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  [for (var (a, b) = x; b; a--) 0];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@37
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@40
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@40
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@37
          staticType: null
        operator: --
        readElement: a@37
        readType: int
        writeElement: a@37
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_scope_patternVariables_shadows_outer_in_expression() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) a) {
  [for (var (a, b) = a; b; a--) 0];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@37
                element: hasImplicitType isPublic
                  type: InvalidType
              matchedValueType: InvalidType
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@40
                element: hasImplicitType isPublic
                  type: InvalidType
              matchedValueType: InvalidType
            element: <null>
        rightParenthesis: )
        matchedValueType: InvalidType
      equals: =
      expression: SimpleIdentifier
        token: a
        element: a@37
        staticType: InvalidType
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@40
      staticType: InvalidType
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@37
          staticType: null
        operator: --
        readElement: a@37
        readType: InvalidType
        writeElement: a@37
        writeType: InvalidType
        element: <null>
        staticType: InvalidType
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_scope_variables_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) a) {
  [for (var (a2, b) = a; b; a2--) 0];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a2
              declaredFragment: isPublic a2@37
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@41
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@41
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a2
          element: a2@37
          staticType: null
        operator: --
        readElement: a2@37
        readType: int
        writeElement: a2@37
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}
