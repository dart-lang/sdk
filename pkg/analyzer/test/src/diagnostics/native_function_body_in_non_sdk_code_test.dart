// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NativeFunctionBodyInNonSdkCodeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NativeFunctionBodyInNonSdkCodeTest extends PubPackageResolutionTest {
  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
int m(a) native 'string';
//       ^^^^^^^^^^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int m(a) native 'string';
//                ^^^^^^^^^^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }

  test_mixinMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  static int m(a) native 'string';
//                ^^^^^^^^^^^^^^^^
// [diag.nativeFunctionBodyInNonSdkCode] Native functions can only be declared in the SDK and code that is loaded through native extensions.
}
''');
  }
}
