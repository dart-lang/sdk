// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideWithoutAccessTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionOverrideWithoutAccessTest extends PubPackageResolutionTest {
  test_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  int operator +(int x) => x;
}
f(C c) {
  E(c) + 2;
}
''');
  }

  test_call() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  E(c)(2);
}
''');
  }

  test_expressionStatement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  void m() {}
}
f(C c) {
  E(c);
//^^^^
// [diag.extensionOverrideWithoutAccess] An extension override can only be used to access instance members.
}
''');
    var node = result.findNode.singleInvalidExtensionOverrideExpression;
    assertResolvedNodeText(node, r'''
InvalidExtensionOverrideExpression
  extensionOverride: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        UnqualifiedNameExpression
          name: c
          resolution: VariableReadResolution
            element: <testLibrary>::@function::f::@formalParameter::c
            type: C
          correspondingParameter: <null>
          staticType: C
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: C
  staticType: InvalidType
V1: ExtensionOverride
  name: E
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: c
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
    rightParenthesis: )
  element: <testLibrary>::@extension::E
  extendedType: C
  staticType: dynamic
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  int get g => 0;
}
f(C c) {
  E(c).g;
}
''');
  }

  test_indexExpression_get() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  int operator [](int i) => 4;
}
f(C c) {
  E(c)[2];
}
''');
  }

  test_indexExpression_set() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  void operator []=(int i, int v) {}
}
f(C c) {
  E(c)[2] = 5;
}
''');
  }

  test_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  void m() {}
}
f(C c) {
  E(c).m();
}
''');
  }

  test_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  int operator -() => 7;
}
f(C c) {
  -E(c);
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
extension E on C {
  set s(int x) {}
}
f(C c) {
  E(c).s = 3;
}
''');
  }
}
