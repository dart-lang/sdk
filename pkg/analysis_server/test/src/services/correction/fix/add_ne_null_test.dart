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
    defineReflectiveTests(AddNeNullMultiTest);
    defineReflectiveTests(AddNeNullTest);
  });
}

@reflectiveTest
class AddNeNullMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_NE_NULL_MULTI;

  Future<void> test_nonBoolCondition_all_nonNullable() async {
    await resolveTestCode('''
f(String p, String q) {
  if (p) {
    print(p);
  }
  if (q) {
    print(q);
  }
}
''');
    await assertNoFixAllFix(CompileTimeErrorCode.NON_BOOL_CONDITION);
  }

  Future<void> test_nonBoolCondition_all_nullable() async {
    await resolveTestCode('''
f(String? p, String? q) {
  if (p) {
    print(p);
  }
  if (q) {
    print(q);
  }
}
''');
    await assertHasFixAllFix(CompileTimeErrorCode.NON_BOOL_CONDITION, '''
f(String? p, String? q) {
  if (p != null) {
    print(p);
  }
  if (q != null) {
    print(q);
  }
}
''');
  }
}

@reflectiveTest
class AddNeNullTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_NE_NULL;

  Future<void> test_nonBoolCondition_nonNullable() async {
    await resolveTestCode('''
f(String p) {
  if (p) {
    print(p);
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_nonBoolCondition_nullable() async {
    await resolveTestCode('''
f(String? p) {
  if (p) {
    print(p);
  }
}
''');
    await assertHasFix('''
f(String? p) {
  if (p != null) {
    print(p);
  }
}
''');
  }
}
