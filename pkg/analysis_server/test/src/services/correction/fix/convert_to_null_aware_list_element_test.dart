// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareListElementTest);
  });
}

@reflectiveTest
class ConvertToNullAwareListElementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.convertToNullAwareListElement;

  Future<void> test_const_list_withGeneralUnassignable() async {
    // Check that the fix isn't suggested when the assignability issue can't be
    // fixed by removing nullability.
    await resolveTestCode('''
void f () {
  const <String>[0];
}
''');
    await assertNoFix();
  }

  Future<void> test_const_list_withNullabilityUnassignable() async {
    await resolveTestCode('''
void f () {
  const String? s = null;
  const <String>[s];
}
''');
    await assertHasFix('''
void f () {
  const String? s = null;
  const <String>[?s];
}
''', errorFilter: (error) => error.message.contains('String?'));
  }

  Future<void> test_nonConst_list_withGeneralUnassignable() async {
    // Check that the fix isn't suggested when the assignability issue can't be
    // fixed by removing nullability.
    await resolveTestCode('''
void f (int arg) {
  <String>[arg];
}
''');
    await assertNoFix();
  }

  Future<void> test_nonConst_list_withNullabilityUnassignable() async {
    await resolveTestCode('''
void f (String? arg) {
  <String>[arg];
}
''');
    await assertHasFix('''
void f (String? arg) {
  <String>[?arg];
}
''');
  }
}
