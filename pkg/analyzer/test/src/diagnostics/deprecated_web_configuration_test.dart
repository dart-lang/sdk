// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedWebConfigurationTest);
  });
}

@reflectiveTest
class DeprecatedWebConfigurationTest extends PubPackageResolutionTest {
  test_deprecatedConfiguration_export() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: uri_does_not_exist
export 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
//      ^^^^^^^^^^^^^^^^^
// [diag.deprecatedWebConfiguration] 'dart:html' is deprecated and shouldn't be used as an import/export configuration.
''');
  }

  test_deprecatedConfiguration_import() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
//      ^^^^^^^^^^^^^^^^^
// [diag.deprecatedWebConfiguration] 'dart:html' is deprecated and shouldn't be used as an import/export configuration.
''');
  }

  test_notDeprecatedConfiguration_import() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
''');
  }
}
