// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocImportCannotHaveConfigurationsTest);
  });
}

@reflectiveTest
class DocImportCannotHaveConfigurationsTest extends PubPackageResolutionTest {
  test_configurations() async {
    await assertErrorsInCode('''
/// @docImport 'dart:math' if (dart.library.html) 'dart:html';
class C {}
''', [
      error(WarningCode.DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS, 27, 34),
    ]);
  }

  test_noConfigurations() async {
    await assertNoErrorsInCode('''
/// @docImport 'dart:math';
class C {}
''');
  }
}
