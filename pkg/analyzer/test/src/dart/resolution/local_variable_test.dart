// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LocalVariableResolutionTest extends PubPackageResolutionTest {
  test_annotation_twoVariables() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = 0;

void f() {
  // ignore:unused_local_variable
  @a var x = 0, y = 0;
}
''');

    var x = result.findElement.localVar('x');
    assertElement(
      x.metadata.annotations.single.element,
      declaration: result.findElement.topGet('a'),
    );

    var y = result.findElement.localVar('y');
    assertElement(
      y.metadata.annotations.single.element,
      declaration: result.findElement.topGet('a'),
    );
  }

  test_demoteTypeParameterType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f<T>(T a, T b) {
  if (a is String) {
    var o = a;
    o = b;
    o; // ref
  }
}
''');

    assertType(result.findNode.simple('o; // ref'), 'T');
  }

  test_element_block() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int x = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  const int x = 0;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.isConst, isTrue);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_final() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  final int x = 0;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isTrue);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_ifStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  if (1 > 2)
    int x = 0;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_late() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  late int x = 0;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isTrue);
    expect(x.isStatic, isFalse);
  }

  test_initializerReference_ifStatement_nonBlock() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  if (c)
    // ignore: unused_local_variable
    var a = 0, b = a; // ref
}
''');

    var node = result.findNode.simple('a; // ref');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: a@71
  staticType: int
''');
  }

  test_localVariable_wildcardFunction() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  _() {}
//^^^^^^
// [diag.deadCode] Dead code.
  _();
//^
// [diag.undefinedFunction] The function '_' isn't defined.
}
''');
  }

  test_localVariable_wildcardFunction_preWildcards() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  _() {}
  _();
}
''');

    var node = result.findNode.simple('_();');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: _@52
  staticType: Null Function()
''');
  }

  test_localVariable_wildcardVariable_field() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  var _ = 1;
  void m() {
    var _ = 0;
    _;
  }
}
''');

    var node = result.findNode.simple('_;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: <testLibrary>::@class::C::@getter::_
  staticType: int
''');
  }

  test_localVariable_wildcardVariable_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics('''
var _ = 1;

void f() {
  var _ = 0;
  _;
}
''');

    var node = result.findNode.simple('_;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: <testLibrary>::@getter::_
  staticType: int
''');
  }
}
