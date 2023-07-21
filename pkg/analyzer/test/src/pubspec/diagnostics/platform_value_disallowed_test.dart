// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PlatformValueDisallowedTest);
  });
}

@reflectiveTest
class PlatformValueDisallowedTest extends PubspecDiagnosticTest {
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

  test_value_for_platform_key_disallowed() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: "chrome" # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_empty_list() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: []  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_empty_map() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: {}  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_false() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: False  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_int() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: 42  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_list_int() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: [1,2,3]  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_list_string() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web:
   - foo
   - bar  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_map() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web:
    foo: bar  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }

  test_value_for_platform_key_disallowed_true() {
    assertErrors('''
name: foo
version: 1.0.0
platforms:
  android:
  ios:
  web: True  # <-- this is not allowed
''', [PubspecWarningCode.PLATFORM_VALUE_DISALLOWED]);
  }
}
