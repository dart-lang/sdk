// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PlatformsFieldTest);
  });
}

@reflectiveTest
class PlatformsFieldTest extends PubspecDiagnosticTest {
  test_empty_platforms_is_allowed() {
    assertNoErrors('''
name: foo
version: 1.0.0
platforms: {} # I don't think you should ever do this!
''');
  }

  test_invalid_platforms_field() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  - android
  - ios
  - web
''', [PubspecWarningCode.INVALID_PLATFORMS_FIELD]);
  }

  test_invalid_platforms_field_bool() {
    assertErrors('''
name: foo
version: 1.0.0
platforms: true
''', [PubspecWarningCode.INVALID_PLATFORMS_FIELD]);
  }

  test_invalid_platforms_field_empty_list() {
    assertErrors('''
name: foo
version: 1.0.0
platforms: []
''', [PubspecWarningCode.INVALID_PLATFORMS_FIELD]);
  }

  test_invalid_platforms_field_num() {
    assertErrors('''
name: foo
version: 1.0.0
platforms: 42
''', [PubspecWarningCode.INVALID_PLATFORMS_FIELD]);
  }

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

  test_unknown_platform() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  windåse:
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }

  test_unknown_platform_capitalization() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  Windows:
''', [PubspecWarningCode.UNKNOWN_PLATFORM]);
  }
}
