// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateSdkConstraintsTest);
  });
}

@reflectiveTest
class UpdateSdkConstraintsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.UPDATE_SDK_CONSTRAINTS;

  test_any() async {
    await testUpdate(from: 'any', to: '^2.1.0');
  }

  test_caret() async {
    await testUpdate(from: '^2.0.0', to: '^2.1.0');
  }

  test_compound() async {
    await testUpdate(from: "'>=2.0.0 <3.0.0'", to: "'>=2.1.0 <3.0.0'");
  }

  test_gt() async {
    await testUpdate(from: "'>2.0.0'", to: "'>=2.1.0'");
  }

  test_gte() async {
    await testUpdate(from: "'>=2.0.0'", to: "'>=2.1.0'");
  }

  testUpdate({String from, String to}) async {
    updateTestPubspecFile('''
environment:
  sdk: $from
''');
    await resolveTestUnit('''
Future<int> zero() async => 0;
''');
    await assertHasFix('''
environment:
  sdk: $to
''', target: testPubspecPath);
  }
}
