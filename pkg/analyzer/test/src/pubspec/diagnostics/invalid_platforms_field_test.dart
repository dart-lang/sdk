// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PlatformsFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PlatformsFieldTest extends PubspecDiagnosticTest {
  test_empty_platforms_is_allowed() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms: {} # I don't think you should ever do this!
''');
  }

  test_invalid_platforms_field() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  - android
// [diag.invalidPlatformsField][column 3][length 25] The 'platforms' field must be a map with platforms as keys.
  - ios
  - web
''');
  }

  test_invalid_platforms_field_bool() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms: true
//         ^^^^
// [diag.invalidPlatformsField] The 'platforms' field must be a map with platforms as keys.
''');
  }

  test_invalid_platforms_field_empty_list() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms: []
//         ^^
// [diag.invalidPlatformsField] The 'platforms' field must be a map with platforms as keys.
''');
  }

  test_invalid_platforms_field_num() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms: 42
//         ^^
// [diag.invalidPlatformsField] The 'platforms' field must be a map with platforms as keys.
''');
  }

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

  test_unknown_platform() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  windåse:
//^^^^^^^
// [diag.unknownPlatform] The platform 'windåse' is not a recognized platform.
''');
  }

  test_unknown_platform_capitalization() {
    assertDiagnostics('''
name: foo
version: 1.0.0
platforms:
  Windows:
//^^^^^^^
// [diag.unknownPlatform] The platform 'Windows' is not a recognized platform.
''');
  }
}
