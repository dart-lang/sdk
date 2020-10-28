// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveNonNullAssertionWithNullSafetyTest);
  });
}

@reflectiveTest
class RemoveNonNullAssertionWithNullSafetyTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.REMOVE_NON_NULL_ASSERTION;

  Future<void> test_nonNullable() async {
    await resolveTestCode('''
void f(String a) {
  print(a!);
}
''');
    await assertHasFix('''
void f(String a) {
  print(a);
}
''');
  }
}
