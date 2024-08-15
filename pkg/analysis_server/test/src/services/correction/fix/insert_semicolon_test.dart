// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InsertSemicolonMultiTest);
    defineReflectiveTests(InsertSemicolonTest);
  });
}

@reflectiveTest
class InsertSemicolonMultiTest extends FixInFileProcessorTest {
  Future<void> test_expectedToken_semicolon_multi() async {
    await resolveTestCode('''
final v = "value"
void f() {
  print(0)
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
final v = "value";
void f() {
  print(0);
}
''');
  }
}

@reflectiveTest
class InsertSemicolonTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.INSERT_SEMICOLON;

  Future<void> test_expectedToken_semicolon() async {
    await resolveTestCode('''
void f() {
  print(0)
}
''');
    await assertHasFix('''
void f() {
  print(0);
}
''');
  }
}
