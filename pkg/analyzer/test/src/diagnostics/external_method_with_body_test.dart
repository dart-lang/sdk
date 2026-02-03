// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExternalMethodWithBodyTest);
  });
}

@reflectiveTest
class ExternalMethodWithBodyTest extends PubPackageResolutionTest {
  test_class_getter_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class A {
  external int get foo {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 29, 3),
        error(diag.externalMethodWithBody, 33, 1),
      ],
    );
  }

  test_class_getter_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
class A {
  external int get foo => 0;
}
''',
      [error(diag.externalMethodWithBody, 33, 2)],
    );
  }

  test_class_method_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class A {
  external void foo() {}
}
''',
      [error(diag.externalMethodWithBody, 32, 1)],
    );
  }

  test_class_method_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
class A {
  external void foo() => null;
}
''',
      [error(diag.externalMethodWithBody, 32, 2)],
    );
  }

  test_class_operator_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class A {
  external int operator +(int other) {}
}
''',
      [
        error(diag.bodyMightCompleteNormally, 34, 1),
        error(diag.externalMethodWithBody, 47, 1),
      ],
    );
  }

  test_class_setter_external_blockBody() async {
    await assertErrorsInCode(
      r'''
class A {
  external void set foo(int v) {}
}
''',
      [error(diag.externalMethodWithBody, 41, 1)],
    );
  }

  test_topLevelFunction_external_blockBody() async {
    await assertErrorsInCode(
      r'''
external void foo() {}
''',
      [error(diag.externalMethodWithBody, 0, 8)],
    );
  }

  test_topLevelFunction_external_expressionBody() async {
    await assertErrorsInCode(
      r'''
external void foo() => null;
''',
      [error(diag.externalMethodWithBody, 0, 8)],
    );
  }
}
