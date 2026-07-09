// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonVoidReturnForSetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonVoidReturnForSetterTest extends PubPackageResolutionTest {
  test_function() async {
    await resolveTestCodeWithDiagnostics('''
int set x(int v) {
// [diag.nonVoidReturnForSetter][column 1][length 3] The return type of the setter must be 'void' or absent.
  return 42;
}''');
  }

  test_function_no_return() async {
    await resolveTestCodeWithDiagnostics('''
set x(v) {}
''');
  }

  test_function_void() async {
    await resolveTestCodeWithDiagnostics('''
void set x(v) {}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int set x(int v) {
//^^^
// [diag.nonVoidReturnForSetter] The return type of the setter must be 'void' or absent.
    return 42;
  }
}''');
  }

  test_method_no_return() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(v) {}
}
''');
  }

  test_method_void() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set x(v) {}
}
''');
  }
}
