// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotATypeTest);
  });
}

@reflectiveTest
class NotATypeTest extends PubPackageResolutionTest {
  test_class_constructor() async {
    await assertErrorsInCode(
      '''
class A {
  A.foo();
}

A.foo bar() {}
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          24,
          5,
          contextMessages: [message(testFile, 14, 3)],
        ),
      ],
    );
  }

  test_class_method() async {
    await assertErrorsInCode(
      '''
class A {
  static void foo() {}
}

A.foo bar() {}
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          36,
          5,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_extension() async {
    await assertErrorsInCode(
      '''
extension E on int {}
E a;
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          22,
          1,
          contextMessages: [message(testFile, 10, 1)],
        ),
      ],
    );

    var node = findNode.namedType('E a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: E
  element2: <testLibrary>::@extension::E
  type: InvalidType
''');
  }

  test_function() async {
    await assertErrorsInCode(
      '''
f() {}
main() {
  f v = null;
}''',
      [
        error(
          CompileTimeErrorCode.notAType,
          18,
          1,
          contextMessages: [message(testFile, 0, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 20, 1),
      ],
    );
  }
}
