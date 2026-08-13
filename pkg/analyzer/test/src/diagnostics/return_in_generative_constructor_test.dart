// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnInGenerativeConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnInGenerativeConstructorTest extends PubPackageResolutionTest {
  test_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() { return 0; }
//             ^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
}
''');
  }

  test_expressionFunctionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() => A();
//    ^^^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
}
''');
  }

  test_return_without_value() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() { return; }
}
''');
  }
}
