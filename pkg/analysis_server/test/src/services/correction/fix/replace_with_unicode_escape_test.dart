// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithUnicodeEscapeTest);
  });
}

@reflectiveTest
class ReplaceWithUnicodeEscapeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_UNICODE_ESCAPE;

  Future<void> test_comment() async {
    await resolveTestCode('''
// some\u2066thing
''');
    await assertHasFix(r'''
// some\u2066thing
''');
  }

  Future<void> test_literal() async {
    await resolveTestCode('''
var ch = '\u202A';
''');
    await assertHasFix(r'''
var ch = '\u202A';
''');
  }
}
