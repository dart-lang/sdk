// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:math' deferred as math;
//                         ^^^^^^^^
// [diag.docImportCannotBeDeferred] Doc imports can't be deferred.
//                                     ^^^^
// [diag.docImportCannotHavePrefix] Doc imports can't have prefixes.
class C {}
''');
  }

  test_notDeferred() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:math';
class C {}
''');
  }
}
