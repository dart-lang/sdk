// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareMapEntryKeyTest);
    defineReflectiveTests(ConvertToNullAwareMapEntryValueTest);
  });
}

@reflectiveTest
class ConvertToNullAwareMapEntryKeyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.convertToNullAwareMapEntryKey;

  Future<void> test_const_mapKey_withGeneralUnassignable() async {
    // Check that the fix isn't suggested when the assignability issue can't be
    // fixed by removing nullability.
    await resolveTestCode('''
void f () {
  const <String, Symbol>{0: #value};
}
''');
    await assertNoFix();
  }

  Future<void> test_const_mapKey_withNullabilityUnassignable() async {
    await resolveTestCode('''
void f () {
  const String? s = null;
  const <String, double>{s: 0.1};
}
''');
    await assertHasFix('''
void f () {
  const String? s = null;
  const <String, double>{?s: 0.1};
}
''', errorFilter: (error) => error.message.contains('String?'));
  }

  Future<void> test_nonConst_mapKey_withGeneralUnassignable() async {
    // Check that the fix isn't suggested when the assignability issue can't be
    // fixed by removing nullability.
    await resolveTestCode('''
void f (int arg) {
  <String, bool>{arg: true};
}
''');
    await assertNoFix();
  }

  Future<void> test_nonConst_mapKey_withNullabilityUnassignable() async {
    await resolveTestCode('''
void f (String? arg) {
  <String, String>{arg: ""};
}
''');
    await assertHasFix('''
void f (String? arg) {
  <String, String>{?arg: ""};
}
''');
  }
}

@reflectiveTest
class ConvertToNullAwareMapEntryValueTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.convertToNullAwareMapEntryValue;

  Future<void> test_const_mapValue_withGeneralUnassignable() async {
    // Check that the fix isn't suggested when the assignability issue can't be
    // fixed by removing nullability.
    await resolveTestCode('''
void f () {
  const <bool, String>{false: 0};
}
''');
    await assertNoFix();
  }

  Future<void> test_const_mapValue_withNullabilityUnassignable() async {
    await resolveTestCode('''
void f () {
  const String? s = null;
  const <Symbol, String>{#key: s};
}
''');
    await assertHasFix('''
void f () {
  const String? s = null;
  const <Symbol, String>{#key: ?s};
}
''', errorFilter: (error) => error.message.contains('String?'));
  }

  Future<void> test_nonConst_mapValue_withGeneralUnassignable() async {
    // Check that the fix isn't suggested when the assignability issue can't be
    // fixed by removing nullability.
    await resolveTestCode('''
void f (int arg) {
  <int, String>{0: arg};
}
''');
    await assertNoFix();
  }

  Future<void> test_nonConst_mapValue_withNullabilityUnassignable() async {
    await resolveTestCode('''
void f (String? arg) {
  <bool, String>{true: arg};
}
''');
    await assertHasFix('''
void f (String? arg) {
  <bool, String>{true: ?arg};
}
''');
  }
}
