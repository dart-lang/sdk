// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperMethodTest);
  });
}

@reflectiveTest
class UndefinedSuperMethodTest extends PubPackageResolutionTest {
  test_error_undefinedSuperMethod() async {
    await assertErrorsInCode(r'''
class A {}

mixin M on A {
  void bar() {
    super.foo(42);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 52, 3),
    ]);

    var invocation = findNode.methodInvocation('foo(42)');
    assertElementNull(invocation.methodName);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);
  }
}
