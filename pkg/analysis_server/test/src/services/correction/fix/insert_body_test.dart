// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InsertBodyTest);
  });
}

@reflectiveTest
class InsertBodyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.INSERT_BODY;

  Future<void> test_expectedCatchClauseBody() async {
    await resolveTestCode('''
f() {
  try {} catch (_)
}
''');
    await assertHasFix('''
f() {
  try {} catch (_) {}
}
''');
  }

  Future<void> test_expectedClassBody() async {
    await resolveTestCode('''
class C
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_expectedExtensionBody() async {
    await resolveTestCode('''
extension E on Object
''');
    await assertHasFix('''
extension E on Object {}
''');
  }

  Future<void> test_expectedExtensionTypeBody() async {
    await resolveTestCode('''
extension type ET(int i)
''');
    await assertHasFix('''
extension type ET(int i) {}
''');
  }

  Future<void> test_expectedFinallyClauseBody() async {
    await resolveTestCode('''
f() {
  try {} finally
}
''');
    await assertHasFix('''
f() {
  try {} finally {}
}
''');
  }

  Future<void> test_expectedMixinBody() async {
    await resolveTestCode('''
mixin M
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_expectedSwitchExpressionBody() async {
    await resolveTestCode('''
f(Never n) => switch (n);
''');
    await assertHasFix('''
f(Never n) => switch (n) {};
''');
  }

  Future<void> test_expectedSwitchStatementBody() async {
    await resolveTestCode('''
f(Never n) {
  switch (n)
}
''');
    await assertHasFix('''
f(Never n) {
  switch (n) {}
}
''');
  }

  Future<void> test_expectedTryStatementBody() async {
    await resolveTestCode('''
f() {
  try finally {}
}
''');
    await assertHasFix('''
f() {
  try {} finally {}
}
''');
  }

  Future<void> test_missingEnumBody() async {
    await resolveTestCode('''
enum E
''');
    // TODO(pq): consider special casing enums to improve the insertion offset
    await assertHasFix('''
enum E
 {}''',
        errorFilter: (error) =>
            error.errorCode != CompileTimeErrorCode.ENUM_WITHOUT_CONSTANTS);
  }
}
