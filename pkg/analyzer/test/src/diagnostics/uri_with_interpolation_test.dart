// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriWithInterpolationTest);
  });
}

@reflectiveTest
class UriWithInterpolationTest extends PubPackageResolutionTest {
  test_library_docImport() async {
    await assertErrorsInCode(r'''
/// @docImport '${'foo'}.dart';
library;
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 15, 15),
    ]);
  }

  test_library_export() async {
    await assertErrorsInCode(r'''
export '${'foo'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 7, 15),
    ]);
  }

  test_library_import() async {
    await assertErrorsInCode(r'''
import '${'foo'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 7, 15),
    ]);
  }

  test_part() async {
    await assertErrorsInCode(r'''
part '${'foo'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 5, 15),
    ]);
  }
}
