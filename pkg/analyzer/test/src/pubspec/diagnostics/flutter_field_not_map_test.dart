// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterFieldNotMapTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FlutterFieldNotMapTest extends PubspecDiagnosticTest {
  test_flutterField_empty_noError() {
    assertDiagnostics('''
name: sample
flutter:
''');

    assertDiagnostics('''
name: sample
flutter:

''');
  }

  test_flutterFieldNotMap_error_bool() {
    assertDiagnostics('''
name: sample
flutter: true
//       ^^^^
// [diag.flutterFieldNotMap] The value of the 'flutter' field is expected to be a map.
''');
  }

  test_flutterFieldNotMap_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
