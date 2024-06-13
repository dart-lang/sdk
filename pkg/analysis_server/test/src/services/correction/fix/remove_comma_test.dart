// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveCommaBulkTest);
    defineReflectiveTests(RemoveCommaTest);
  });
}

@reflectiveTest
class RemoveCommaBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  (,);
  (,);
}
''');
    await assertHasFix('''
f() {
  ();
  ();
}
''');
  }
}

@reflectiveTest
class RemoveCommaTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_COMMA;

  Future<void> test_emptyRecordLiteral() async {
    await resolveTestCode('''
f() {
  (,);
}
''');
    await assertHasFix('''
f() {
  ();
}
''');
  }

  Future<void> test_emptyRecordType() async {
    await resolveTestCode('''
(,)? f() => null;
''');
    await assertHasFix('''
()? f() => null;
''');
  }
}
