// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareSpreadTest);
  });
}

@reflectiveTest
class ConvertToNullAwareSpreadTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_NULL_AWARE_SPREAD;

  Future<void> test_spreadList() async {
    await resolveTestCode('''
void f (List<String>? args) {
  [...args];
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  [...?args];
}
''');
  }

  Future<void> test_spreadMap() async {
    await resolveTestCode('''
void f (Map<int, String>? args) {
  print({...args});
}
''');
    await assertHasFix('''
void f (Map<int, String>? args) {
  print({...?args});
}
''');
  }

  Future<void> test_spreadSet() async {
    await resolveTestCode('''
void f (List<String>? args) {
  print({...args});
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  print({...?args});
}
''');
  }
}
