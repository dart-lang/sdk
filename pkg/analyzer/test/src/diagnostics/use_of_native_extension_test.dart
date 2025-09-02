// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfNativeExtensionTest);
  });
}

@reflectiveTest
class UseOfNativeExtensionTest extends PubPackageResolutionTest {
  test_docImport() async {
    await assertErrorsInCode(
      r'''
/// @docImport 'dart-ext:x';
library;
''',
      [error(CompileTimeErrorCode.useOfNativeExtension, 15, 12)],
    );
  }

  test_export() async {
    await assertErrorsInCode(
      r'''
export 'dart-ext:x';
''',
      [error(CompileTimeErrorCode.useOfNativeExtension, 7, 12)],
    );
  }

  test_import() async {
    await assertErrorsInCode(
      r'''
import 'dart-ext:x';
''',
      [error(CompileTimeErrorCode.useOfNativeExtension, 7, 12)],
    );
  }
}
