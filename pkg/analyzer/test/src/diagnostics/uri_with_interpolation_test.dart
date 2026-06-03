// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriWithInterpolationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UriWithInterpolationTest extends PubPackageResolutionTest {
  test_library_docImport() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport '${'foo'}.dart';
//             ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
library;
''');
  }

  test_library_export() async {
    await resolveTestCodeWithDiagnostics(r'''
export '${'foo'}.dart';
//     ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''');
  }

  test_library_import() async {
    await resolveTestCodeWithDiagnostics(r'''
import '${'foo'}.dart';
//     ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''');
  }

  test_part() async {
    await resolveTestCodeWithDiagnostics(r'''
part '${'foo'}.dart';
//   ^^^^^^^^^^^^^^^
// [diag.uriWithInterpolation] URIs can't use string interpolation.
''');
  }
}
