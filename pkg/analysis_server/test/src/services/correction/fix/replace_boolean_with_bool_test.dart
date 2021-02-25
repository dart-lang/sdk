// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceBooleanWithBoolTest);
  });
}

@reflectiveTest
class ReplaceBooleanWithBoolTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_BOOLEAN_WITH_BOOL;

  Future<void> test_all() async {
    await resolveTestCode('''
main() {
  boolean v;
  boolean w;
}
''');
    await assertHasFixAllFix(CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN, '''
main() {
  bool v;
  bool w;
}
''');
  }

  Future<void> test_single() async {
    await resolveTestCode('''
main() {
  boolean v;
  print(v);
}
''');
    await assertHasFix('''
main() {
  bool v;
  print(v);
}
''');
  }
}
