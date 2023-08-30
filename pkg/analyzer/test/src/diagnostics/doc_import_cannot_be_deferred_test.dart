// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocImportCannotBeDeferredTest);
  });
}

@reflectiveTest
class DocImportCannotBeDeferredTest extends PubPackageResolutionTest {
  test_deferred() async {
    await assertErrorsInCode('''
/// @docImport 'dart:math' deferred as math;
class C {}
''', [
      error(WarningCode.DOC_IMPORT_CANNOT_BE_DEFERRED, 27, 8),
    ]);
  }

  test_notDeferred() async {
    await assertNoErrorsInCode('''
/// @docImport 'dart:math' as math;
class C {}
''');
  }
}
