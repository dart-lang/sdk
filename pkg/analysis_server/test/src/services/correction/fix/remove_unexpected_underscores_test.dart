// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnexpectedUnderscoresInFileTest);
    defineReflectiveTests(RemoveUnexpectedUnderscoresTest);
  });
}

@reflectiveTest
class RemoveUnexpectedUnderscoresInFileTest extends FixInFileProcessorTest {
  Future<void> test_file() async {
    await resolveTestCode('''
var a = 100_;
var b = 1_000_000___;
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
var a = 100;
var b = 1_000_000;
''');
  }
}

@reflectiveTest
class RemoveUnexpectedUnderscoresTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNEXPECTED_UNDERSCORES;

  Future<void> test_double_afterE() async {
    await resolveTestCode('''
var a = 100e_2;
''');
    await assertHasFix('''
var a = 100e2;
''');
  }

  Future<void> test_double_afterE_multiple() async {
    await resolveTestCode('''
var a = 100e___2;
''');
    await assertHasFix('''
var a = 100e2;
''');
  }

  Future<void> test_double_beforeE() async {
    await resolveTestCode('''
var a = 100_e2;
''');
    await assertHasFix('''
var a = 100e2;
''');
  }

  Future<void> test_double_beforeE_multiple() async {
    await resolveTestCode('''
var a = 100___e2;
''');
    await assertHasFix('''
var a = 100e2;
''');
  }

  Future<void> test_double_beforeE_withLegalSeparators() async {
    await resolveTestCode('''
var a = 10_e2_000;
''');
    await assertHasFix('''
var a = 10e2_000;
''');
  }

  Future<void> test_double_beforePoint_withLegalSeparators() async {
    await resolveTestCode('''
var a = 1_000_.5;
''');
    await assertHasFix('''
var a = 1_000.5;
''');
  }

  Future<void> test_double_betweenPointAndMinus_withLegalSeparators() async {
    await resolveTestCode('''
var a = 2e_-3_000;
''');
    await assertHasFix('''
var a = 2e-3_000;
''');
  }

  Future<void> test_hex_after0x() async {
    await resolveTestCode('''
var a = 0x_123;
''');
    await assertHasFix('''
var a = 0x123;
''');
  }

  Future<void> test_hex_after0x_multiple() async {
    await resolveTestCode('''
var a = 0x___123;
''');
    await assertHasFix('''
var a = 0x123;
''');
  }

  Future<void> test_hex_after0x_withLegalSeparators() async {
    await resolveTestCode('''
var a = 0x_ff_ff_FF_FF;
''');
    await assertHasFix('''
var a = 0xff_ff_FF_FF;
''');
  }

  Future<void> test_int_endOfToken() async {
    await resolveTestCode('''
var a = 100_;
''');
    await assertHasFix('''
var a = 100;
''');
  }

  Future<void> test_int_endOfToken_multiple() async {
    await resolveTestCode('''
var a = 100___;
''');
    await assertHasFix('''
var a = 100;
''');
  }

  Future<void> test_int_endOfToken_withLegalSeparators() async {
    await resolveTestCode('''
var a = 1_000_000_;
''');
    await assertHasFix('''
var a = 1_000_000;
''');
  }
}
