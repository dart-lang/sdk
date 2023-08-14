// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementTest);
    defineReflectiveTests(IfElementTest);
    defineReflectiveTests(SpreadElementTest);
  });
}

@reflectiveTest
class ForElementTest extends PubPackageResolutionTest {
  test_list_awaitForIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() async {
  <int>[await for (var e in a()) e];
}

T a<T>() => throw '';
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<Object?> Function()
  staticType: Stream<Object?>
  typeArgumentTypes
    Stream<Object?>
''');
  }

  test_list_awaitForIn_int_downward() async {
    await assertNoErrorsInCode('''
void f() async {
  <int>[await for (int e in a()) e];
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<int> Function()
  staticType: Stream<int>
  typeArgumentTypes
    Stream<int>
''');
  }

  test_list_for_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>[for (int i = 0; a(); i++) i];
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_list_forIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() {
  <int>[for (var e in a()) e];
}

T a<T>() => throw '';
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 38, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<Object?> Function()
  staticType: Iterable<Object?>
  typeArgumentTypes
    Iterable<Object?>
''');
  }

  test_list_forIn_int_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>[for (int e in a()) e];
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<int> Function()
  staticType: Iterable<int>
  typeArgumentTypes
    Iterable<int>
''');
  }

  test_map_awaitForIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() async {
  <int, int>{await for (var e in a()) e : e};
}

T a<T>() => throw '';
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 55, 1),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 59, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<Object?> Function()
  staticType: Stream<Object?>
  typeArgumentTypes
    Stream<Object?>
''');
  }

  test_map_awaitForIn_int_downward() async {
    await assertNoErrorsInCode('''
void f() async {
  <int, int>{await for (int e in a()) e : e};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<int> Function()
  staticType: Stream<int>
  typeArgumentTypes
    Stream<int>
''');
  }

  test_map_for_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int, int>{for (int i = 0; a(); i++) i : i};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_map_forIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() {
  <int, int>{for (var e in a()) e : e};
}

T a<T>() => throw '';
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 43, 1),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 47, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<Object?> Function()
  staticType: Iterable<Object?>
  typeArgumentTypes
    Iterable<Object?>
''');
  }

  test_map_forIn_int_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int, int>{for (int e in a()) e : e};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<int> Function()
  staticType: Iterable<int>
  typeArgumentTypes
    Iterable<int>
''');
  }

  test_set_awaitForIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() async {
  <int>{await for (var e in a()) e};
}

T a<T>() => throw '';
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<Object?> Function()
  staticType: Stream<Object?>
  typeArgumentTypes
    Stream<Object?>
''');
  }

  test_set_awaitForIn_int_downward() async {
    await assertNoErrorsInCode('''
void f() async {
  <int>{await for (int e in a()) e};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<int> Function()
  staticType: Stream<int>
  typeArgumentTypes
    Stream<int>
''');
  }

  test_set_for_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>{for (int i = 0; a(); i++) i};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_set_forIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() {
  <int>{for (var e in a()) e};
}

T a<T>() => throw '';
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 38, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<Object?> Function()
  staticType: Iterable<Object?>
  typeArgumentTypes
    Iterable<Object?>
''');
  }

  test_set_forIn_int_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>{for (int e in a()) e};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<int> Function()
  staticType: Iterable<int>
  typeArgumentTypes
    Iterable<int>
''');
  }
}

@reflectiveTest
class IfElementTest extends PubPackageResolutionTest {
  test_list_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>[if (a()) 1];
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_map_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <String, int>{if (a()) 'a' : 1};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_set_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>{if (a()) 1};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }
}

@reflectiveTest
class SpreadElementTest extends PubPackageResolutionTest {
  test_list_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>[...a()];
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<int> Function()
  staticType: Iterable<int>
  typeArgumentTypes
    Iterable<int>
''');
  }

  test_map_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <String, int>{...a()};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Map<String, int> Function()
  staticType: Map<String, int>
  typeArgumentTypes
    Map<String, int>
''');
  }

  test_set_downward() async {
    await assertNoErrorsInCode('''
void f() {
  <int>{...a()};
}

T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<int> Function()
  staticType: Iterable<int>
  typeArgumentTypes
    Iterable<int>
''');
  }
}
