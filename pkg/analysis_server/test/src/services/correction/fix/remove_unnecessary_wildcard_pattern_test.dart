// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryWildcardPatternBulkTest);
    defineReflectiveTests(RemoveUnnecessaryWildcardPatternTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryWildcardPatternBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile_samePattern() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case _ && 0 && _ && _) {}
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case 0) {}
}
''');
  }

  Future<void> test_singleFile_separate() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case _ && 0) {}
  if (x case _ && 1) {}
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case 0) {}
  if (x case 1) {}
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryWildcardPatternTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_WILDCARD_PATTERN;

  Future<void> test_logicalAnd_left() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case _ && 0) {}
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case 0) {}
}
''');
  }

  Future<void> test_logicalAnd_right() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case 0 && _) {}
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case 0) {}
}
''');
  }

  Future<void> test_parenthesizedPattern_logicalAnd() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case (_) && 0) {}
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case 0) {}
}
''');
  }

  Future<void> test_typed_sameMatchedType() async {
    await resolveTestCode('''
void f(int x) {
  if (x case int _ && > 0) {}
}
''');
    await assertHasFix('''
void f(int x) {
  if (x case > 0) {}
}
''');
  }
}
