// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceColonWithInTest);
  });
}

@reflectiveTest
class ReplaceColonWithInTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_COLON_WITH_IN;

  Future<void> test_colonInPlaceOfIn() async {
    await resolveTestCode('''
void f() {
  for (var _ : []) {}
}
''');
    await assertHasFix('''
void f() {
  for (var _ in []) {}
}
''');
  }
}
