// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocImportCannotHavePrefixTest);
  });
}

@reflectiveTest
class DocImportCannotHavePrefixTest extends PubPackageResolutionTest {
  test_configurations() async {
    await assertErrorsInCode(
      '''
/// @docImport 'dart:math' as math;
class C {}
''',
      [error(WarningCode.docImportCannotHavePrefix, 30, 4)],
    );
  }

  test_noConfigurations() async {
    await assertNoErrorsInCode('''
/// @docImport 'dart:math';
class C {}
''');
  }
}
