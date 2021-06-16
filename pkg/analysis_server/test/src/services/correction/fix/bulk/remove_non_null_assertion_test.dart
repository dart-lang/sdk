// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../../abstract_context.dart';
import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveNonNullAssertionWithNullSafetyTest);
  });
}

@reflectiveTest
class RemoveNonNullAssertionWithNullSafetyTest extends BulkFixProcessorTest
    with WithNullSafetyMixin {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(String a) {
  print(a!!);
}
''');
    await assertHasFix('''
void f(String a) {
  print(a);
}
''');
  }
}
