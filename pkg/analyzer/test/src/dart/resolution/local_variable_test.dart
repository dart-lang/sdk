// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableResolutionTest);
  });
}

@reflectiveTest
class LocalVariableResolutionTest extends PubPackageResolutionTest {
  test_annotation_twoVariables() async {
    await assertNoErrorsInCode(r'''
const a = 0;

void f() {
  // ignore:unused_local_variable
  @a var x = 0, y = 0;
}
''');

    var x = findElement2.localVar('x');
    assertElement(
      x.metadata.annotations.single.element,
      declaration: findElement2.topGet('a'),
    );

    var y = findElement2.localVar('y');
    assertElement(
      y.metadata.annotations.single.element,
      declaration: findElement2.topGet('a'),
    );
  }

  test_demoteTypeParameterType() async {
    await assertNoErrorsInCode('''
void f<T>(T a, T b) {
  if (a is String) {
    var o = a;
    o = b;
    o; // ref
  }
}
''');

    assertType(findNode.simple('o; // ref'), 'T');
  }

  test_element_block() async {
    await assertErrorsInCode(
      r'''
void f() {
  int x = 0;
}
''',
      [error(WarningCode.unusedLocalVariable, 17, 1)],
    );

    var x = findElement2.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_const() async {
    await assertErrorsInCode(
      r'''
void f() {
  const int x = 0;
}
''',
      [error(WarningCode.unusedLocalVariable, 23, 1)],
    );

    var x = findElement2.localVar('x');
    expect(x.isConst, isTrue);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_final() async {
    await assertErrorsInCode(
      r'''
void f() {
  final int x = 0;
}
''',
      [error(WarningCode.unusedLocalVariable, 23, 1)],
    );

    var x = findElement2.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isTrue);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_ifStatement() async {
    await assertErrorsInCode(
      r'''
void f() {
  if (1 > 2)
    int x = 0;
}
''',
      [error(WarningCode.unusedLocalVariable, 32, 1)],
    );

    var x = findElement2.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_late() async {
    await assertErrorsInCode(
      r'''
void f() {
  late int x = 0;
}
''',
      [error(WarningCode.unusedLocalVariable, 22, 1)],
    );

    var x = findElement2.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isTrue);
    expect(x.isStatic, isFalse);
  }

  test_localVariable_wildcardFunction() async {
    await assertErrorsInCode(
      '''
f() {
  _() {}
  _();
}
''',
      [
        error(WarningCode.deadCode, 8, 6),
        error(CompileTimeErrorCode.undefinedFunction, 17, 1),
      ],
    );
  }

  test_localVariable_wildcardFunction_preWildcards() async {
    await assertNoErrorsInCode('''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  _() {}
  _();
}
''');

    var node = findNode.simple('_();');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: _@52
  staticType: Null Function()
''');
  }

  test_localVariable_wildcardVariable_field() async {
    await assertNoErrorsInCode('''
class C {
  var _ = 1;
  void m() {
    var _ = 0;
    _;
  }
}
''');

    var node = findNode.simple('_;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: <testLibrary>::@class::C::@getter::_
  staticType: int
''');
  }

  test_localVariable_wildcardVariable_topLevel() async {
    await assertNoErrorsInCode('''
var _ = 1;

void f() {
  var _ = 0;
  _;
}
''');

    var node = findNode.simple('_;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: <testLibrary>::@getter::_
  staticType: int
''');
  }
}
