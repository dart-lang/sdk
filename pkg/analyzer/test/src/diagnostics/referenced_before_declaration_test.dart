// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferencedBeforeDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReferencedBeforeDeclarationTest extends PubPackageResolutionTest {
  test_block_patternVariable_after() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = 0;
void f() {
  v;
//^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
  var [v] = [0];
//     ^
// [context 1] The declaration of 'v' is here.
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@34
  staticType: InvalidType
''');
  }

  test_block_patternVariable_before() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = 0;
void f() {
  var [v] = [0];
  v;
}
''');
  }

  test_cascade_after_declaration() async {
    await resolveTestCodeWithDiagnostics(r'''
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

  test_forElement_forPartsWithDeclarations_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  [for (var x = x;;) x];
//          ^
// [context 1] The declaration of 'x' is here.
//              ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'x' can't be referenced before it is declared.
}
''');
  }

  test_forStatement_forPartsWithDeclarations_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var x = x;;) {
//         ^
// [context 1] The declaration of 'x' is here.
//             ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'x' can't be referenced before it is declared.
    x;
  }
}
''');
  }

  test_hideInBlock_comment() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  /// [v] is a variable.
  var v = 2;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
print(x) {}
''');
  }

  test_hideInBlock_function() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = 1;
main() {
  print(v);
//      ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
  v() {}
//^
// [context 1] The declaration of 'v' is here.
}
print(x) {}
''');
  }

  test_hideInBlock_local() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = 1;
main() {
  print(v);
//      ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
  var v = 2;
//    ^
// [context 1] The declaration of 'v' is here.
}
print(x) {}
''');
  }

  test_hideInBlock_local_subBlock() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = 1;
main() {
  {
    print(v);
//        ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
  }
  var v = 2;
//    ^
// [context 1] The declaration of 'v' is here.
}
print(x) {}
''');
  }

  test_hideInSwitchCase_function() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      void v() {}
//         ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@75
  staticType: void Function()
''');
  }

  test_hideInSwitchCase_function_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      void v() {}
//         ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@91
  staticType: void Function()
''');
  }

  test_hideInSwitchCase_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      var v = 1;
//        ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@74
  staticType: dynamic
''');
  }

  test_hideInSwitchCase_local_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    case 0:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      var v = 1;
//        ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@90
  staticType: dynamic
''');
  }

  test_hideInSwitchDefault_function() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      void v() {}
//         ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@76
  staticType: void Function()
''');
  }

  test_hideInSwitchDefault_function_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      void v() {}
//         ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@92
  staticType: void Function()
''');
  }

  test_hideInSwitchDefault_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      var v = 1;
//        ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@75
  staticType: dynamic
''');
  }

  test_hideInSwitchDefault_local_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
var v = 0;

void f(int a) {
  switch (a) {
    default:
      v;
//    ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
      var v = 1;
//        ^
// [context 1] The declaration of 'v' is here.
  }
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@91
  staticType: dynamic
''');
  }

  test_inInitializer_closure() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = () => v;
//    ^
// [context 1] The declaration of 'v' is here.
//              ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
}
''');
  }

  test_inInitializer_directly() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = v;
//    ^
// [context 1] The declaration of 'v' is here.
//        ^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'v' can't be referenced before it is declared.
}
''');
  }

  test_labeledStatement_function() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_label
  label: void v() {}
  v;
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@50
  staticType: void Function()
''');
  }

  test_labeledStatement_local() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_label
  label: var v = 0;
  v;
}
''');

    var node = result.findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@49
  staticType: int
''');
  }

  test_type_localFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
void testTypeRef() {
  String s = '';
//^^^^^^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'String' can't be referenced before it is declared.
  int String(int x) => x + 1;
//    ^^^^^^
// [context 1] The declaration of 'String' is here.
  print(s + String);
}
''');
  }

  test_type_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void testTypeRef() {
  String s = '';
//^^^^^^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'String' can't be referenced before it is declared.
  var String = '';
//    ^^^^^^
// [context 1] The declaration of 'String' is here.
  print(s + String);
}
''');
  }
}
