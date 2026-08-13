// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnWithoutValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnWithoutValueTest extends PubPackageResolutionTest {
  test_async_futureInt() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> f() async {
  return;
//^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
}
''');
  }

  test_async_futureObject() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<Object> f() async {
  return;
//^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
}
''');
  }

  test_catchError_futureOfVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((e) {
    return;
  });
}
''');
  }

  test_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() {
    return;
//  ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
  }
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() {
  return;
//^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
}
''');
  }

  test_function_async_block_empty__to_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f() async {
  return;
}
''');
  }

  test_function_Null() async {
    // Test that block bodied functions with return type Null and an empty
    // return cause a static warning.
    await resolveTestCodeWithDiagnostics(r'''
Null f() {
  return;
}
''');
  }

  test_function_sync_block_empty__to_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f() {
  return;
}
''');
  }

  test_function_sync_block_empty__to_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
Null f() {
  return;
}
''');
  }

  test_function_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  return;
}
''');
  }

  test_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  return (int y) {
    if (y < 0) {
      return;
//    ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
    }
    return 0;
  };
}
''');
  }

  test_functionExpression_async_block_empty__to_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
Object Function() f = () async {
  return;
};
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int m() {
    return;
//  ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
  }
}
''');
  }

  test_multipleInconsistentReturns() async {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no
    // MIXED_RETURN_TYPES are created.
    await resolveTestCodeWithDiagnostics(r'''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
//^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
}
''');
  }
}
