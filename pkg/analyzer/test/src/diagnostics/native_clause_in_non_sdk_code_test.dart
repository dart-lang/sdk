// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NativeClauseInNonSdkCodeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NativeClauseInNonSdkCodeTest extends PubPackageResolutionTest {
  test_nativeClauseInNonSDKCode() async {
    await resolveTestCodeWithDiagnostics(r'''
class A native 'string' {}
//      ^^^^^^^^^^^^^^^
// [diag.nativeClauseInNonSdkCode] Native clause can only be used in the SDK and code that is loaded through native extensions.
''');
  }
}
