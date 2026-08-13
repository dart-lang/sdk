// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfNativeExtensionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UseOfNativeExtensionTest extends PubPackageResolutionTest {
  test_docImport() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart-ext:x';
//             ^^^^^^^^^^^^
// [diag.useOfNativeExtension] Dart native extensions are deprecated and aren't available in Dart 2.15.
library;
''');
  }

  test_export() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart-ext:x';
//     ^^^^^^^^^^^^
// [diag.useOfNativeExtension] Dart native extensions are deprecated and aren't available in Dart 2.15.
''');
  }

  test_import() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart-ext:x';
//     ^^^^^^^^^^^^
// [diag.useOfNativeExtension] Dart native extensions are deprecated and aren't available in Dart 2.15.
''');
  }
}
