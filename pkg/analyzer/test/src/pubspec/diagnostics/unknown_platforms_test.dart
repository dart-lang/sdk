// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownPlatformsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnknownPlatformsTest extends PubspecDiagnosticTest {
  test_subset_of_supported_platforms_is_allowed() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web:
''');
  }

  test_supported_platforms_are_allowed() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  linux:
  macos:
  web:
  windows:
''');
  }

  test_unknown_platform_bool() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  True:
//^^^^
// [diag.unknownPlatform] The platform 'true' is not a recognized platform.
''');
  }

  test_unknown_platform_browser() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  browser: # the correct platform is "web"
//^^^^^^^
// [diag.unknownPlatform] The platform 'browser' is not a recognized platform.
''');
  }

  test_unknown_platform_int() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  33:
//^^
// [diag.unknownPlatform] The platform '33' is not a recognized platform.
''');
  }

  test_unknown_platform_list() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  [1, 2]:
//^^^^^^
// [diag.unknownPlatform] The platform '[1, 2]' is not a recognized platform.
''');
  }

  test_unknown_platform_null() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  null:
//^^^^
// [diag.unknownPlatform] The platform 'null' is not a recognized platform.
''');
  }

  test_unknown_platform_win32() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  win32: # the correct platform is "windows"
//^^^^^
// [diag.unknownPlatform] The platform 'win32' is not a recognized platform.
''');
  }
}
