// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalLanguageVersionOverrideTest);
  });
}

@reflectiveTest
class IllegalLanguageVersionOverrideTest extends PubPackageResolutionTest {
  test_hasOverride_equal() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.12
void f() {}
''');
  }

  test_hasOverride_greater() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.14
void f() {}
''');
  }

  test_hasOverride_less() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.9
// [diag.illegalLanguageVersionOverride][column 1][length 14] The language version must be >=2.12.0.
int a = 0;
''');
  }

  test_hasPackageLanguage_less_hasOverride_greater() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.14
void f() {}
''');
  }

  test_noOverride() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {}
''');
  }
}
