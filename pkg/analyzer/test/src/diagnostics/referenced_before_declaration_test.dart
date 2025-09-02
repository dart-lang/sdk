// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferencedBeforeDeclarationTest);
  });
}

@reflectiveTest
class ReferencedBeforeDeclarationTest extends PubPackageResolutionTest {
  test_block_patternVariable_after() async {
    await assertErrorsInCode(
      r'''
var v = 0;
void f() {
  v;
  var [v] = [0];
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          24,
          1,
          contextMessages: [message(testFile, 34, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@34
  staticType: InvalidType
''');
  }

  test_block_patternVariable_before() async {
    await assertNoErrorsInCode(r'''
var v = 0;
void f() {
  var [v] = [0];
  v;
}
''');
  }

  test_cascade_after_declaration() async {
    await assertNoErrorsInCode(r'''
testRequestHandler() {}

main() {
  var s1 = null;
  testRequestHandler()
    ..stream(s1);
  var stream = 123;
  print(stream);
}
''');
  }

  test_hideInBlock_comment() async {
    await assertErrorsInCode(
      r'''
main() {
  /// [v] is a variable.
  var v = 2;
}
print(x) {}
''',
      [error(WarningCode.unusedLocalVariable, 40, 1)],
    );
  }

  test_hideInBlock_function() async {
    await assertErrorsInCode(
      r'''
var v = 1;
main() {
  print(v);
  v() {}
}
print(x) {}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          28,
          1,
          contextMessages: [message(testFile, 34, 1)],
        ),
      ],
    );
  }

  test_hideInBlock_local() async {
    await assertErrorsInCode(
      r'''
var v = 1;
main() {
  print(v);
  var v = 2;
}
print(x) {}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          28,
          1,
          contextMessages: [message(testFile, 38, 1)],
        ),
      ],
    );
  }

  test_hideInBlock_local_subBlock() async {
    await assertErrorsInCode(
      r'''
var v = 1;
main() {
  {
    print(v);
  }
  var v = 2;
}
print(x) {}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          34,
          1,
          contextMessages: [message(testFile, 48, 1)],
        ),
      ],
    );
  }

  test_hideInSwitchCase_function() async {
    await assertErrorsInCode(
      r'''
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
      void v() {}
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          61,
          1,
          contextMessages: [message(testFile, 75, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@75
  staticType: void Function()
''');
  }

  test_hideInSwitchCase_function_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
      void v() {}
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          77,
          1,
          contextMessages: [message(testFile, 91, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@91
  staticType: void Function()
''');
  }

  test_hideInSwitchCase_local() async {
    await assertErrorsInCode(
      r'''
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
      var v = 1;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          61,
          1,
          contextMessages: [message(testFile, 74, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@74
  staticType: dynamic
''');
  }

  test_hideInSwitchCase_local_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
      var v = 1;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          77,
          1,
          contextMessages: [message(testFile, 90, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@90
  staticType: dynamic
''');
  }

  test_hideInSwitchDefault_function() async {
    await assertErrorsInCode(
      r'''
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
      void v() {}
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          62,
          1,
          contextMessages: [message(testFile, 76, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@76
  staticType: void Function()
''');
  }

  test_hideInSwitchDefault_function_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
      void v() {}
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          78,
          1,
          contextMessages: [message(testFile, 92, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@92
  staticType: void Function()
''');
  }

  test_hideInSwitchDefault_local() async {
    await assertErrorsInCode(
      r'''
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
      var v = 1;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          62,
          1,
          contextMessages: [message(testFile, 75, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@75
  staticType: dynamic
''');
  }

  test_hideInSwitchDefault_local_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
      var v = 1;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          78,
          1,
          contextMessages: [message(testFile, 91, 1)],
        ),
      ],
    );

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@91
  staticType: dynamic
''');
  }

  test_inInitializer_closure() async {
    await assertErrorsInCode(
      r'''
main() {
  var v = () => v;
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          25,
          1,
          contextMessages: [message(testFile, 15, 1)],
        ),
      ],
    );
  }

  test_inInitializer_directly() async {
    await assertErrorsInCode(
      r'''
main() {
  var v = v;
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          19,
          1,
          contextMessages: [message(testFile, 15, 1)],
        ),
      ],
    );
  }

  test_labeledStatement_function() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_label
  label: void v() {}
  v;
}
''');

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@50
  staticType: void Function()
''');
  }

  test_labeledStatement_local() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_label
  label: var v = 0;
  v;
}
''');

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@49
  staticType: int
''');
  }

  test_type_localFunction() async {
    await assertErrorsInCode(
      r'''
void testTypeRef() {
  String s = '';
  int String(int x) => x + 1;
  print(s + String);
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          23,
          6,
          contextMessages: [message(testFile, 44, 6)],
        ),
      ],
    );
  }

  test_type_localVariable() async {
    await assertErrorsInCode(
      r'''
void testTypeRef() {
  String s = '';
  var String = '';
  print(s + String);
}
''',
      [
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          23,
          6,
          contextMessages: [message(testFile, 44, 6)],
        ),
      ],
    );
  }
}
