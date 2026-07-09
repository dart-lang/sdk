// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:math' as math;
//                            ^^^^
// [diag.docImportCannotHavePrefix] Doc imports can't have prefixes.
class C {}
''');
  }

  test_noConfigurations() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:math';
class C {}
''');
  }
}
