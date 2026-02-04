// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceBooleanWithBoolMultiTest);
    defineReflectiveTests(ReplaceBooleanWithBoolTest);
  });
}

@reflectiveTest
class ReplaceBooleanWithBoolMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.replaceBooleanWithBoolMulti;

  Future<void> test_all() async {
    await resolveTestCode('''
void f() {
  boolean v;
  boolean w;
}
''');
    await assertHasFixAllFix(diag.undefinedClassBoolean, '''
void f() {
  bool v;
  bool w;
}
''');
  }
}

@reflectiveTest
class ReplaceBooleanWithBoolTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.replaceBooleanWithBool;

  Future<void> test_single() async {
    await resolveTestCode('''
void f() {
  boolean v;
  print(v);
}
''');
    await assertHasFix('''
void f() {
  bool v;
  print(v);
}
''');
  }
}
