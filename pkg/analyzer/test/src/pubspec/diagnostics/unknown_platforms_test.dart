// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownPlatformsTest);
  });
}

@reflectiveTest
class UnknownPlatformsTest extends PubspecDiagnosticTest {
  test_subset_of_supported_platforms_is_allowed() {
    assertNoErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web:
''');
  }

  test_supported_platforms_are_allowed() {
    assertNoErrors('''
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
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  True:
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }

  test_unknown_platform_browser() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  browser: # the correct platform is "web"
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }

  test_unknown_platform_int() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  33:
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }

  test_unknown_platform_list() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  [1, 2]:
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }

  test_unknown_platform_null() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  null:
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }

  test_unknown_platform_win32() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  win32: # the correct platform is "windows"
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }
}
