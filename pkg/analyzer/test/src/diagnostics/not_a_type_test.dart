// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotATypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotATypeTest extends PubPackageResolutionTest {
  test_class_constructor() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.foo();
//  ^^^
// [context 1] The declaration of 'foo' is here.
}

A.foo bar() {}
// [diag.notAType][column 1][length 5][context 1] A.foo isn't a type.
''');
  }

  test_class_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
//            ^^^
// [context 1] The declaration of 'foo' is here.
}

A.foo bar() {}
// [diag.notAType][column 1][length 5][context 1] A.foo isn't a type.
''');
  }

  test_extension() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {}
//        ^
// [context 1] The declaration of 'E' is here.
E a;
// [diag.notAType][column 1][length 1][context 1] E isn't a type.
''');

    var node = result.findNode.namedType('E a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: E
  element: <testLibrary>::@extension::E
  type: InvalidType
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics('''
f() {}
// [context 1][column 1][length 1] The declaration of 'f' is here.
main() {
  f v = null;
//^
// [diag.notAType][context 1] f isn't a type.
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}''');
  }
}
