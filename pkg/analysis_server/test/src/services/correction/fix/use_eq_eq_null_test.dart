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
    defineReflectiveTests(UseEqEqNullMultiTest);
    defineReflectiveTests(UseEqEqNullTest);
  });
}

@reflectiveTest
class UseEqEqNullMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.USE_EQ_EQ_NULL_MULTI;

  Future<void> test_isNull_all() async {
    await resolveTestCode('''
void f(p, q) {
  p is Null;
  q is Null;
}
''');
    await assertHasFixAllFix(HintCode.TYPE_CHECK_IS_NULL, '''
void f(p, q) {
  p == null;
  q == null;
}
''');
  }
}

@reflectiveTest
class UseEqEqNullTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.USE_EQ_EQ_NULL;

  Future<void> test_isNull() async {
    await resolveTestCode('''
void f(p) {
  p is Null;
}
''');
    await assertHasFix('''
void f(p) {
  p == null;
}
''');
  }
}
