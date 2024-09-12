// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveReturnTypeTest);
  });
}

@reflectiveTest
class RemoveReturnTypeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_RETURN_TYPE;

  Future<void> test_method_setter_with_return() async {
    await resolveTestCode('''
class A {
  dynamic set foo(int a) {
    if (a == 0) return;
  }
}
''');
    await assertHasFix('''
class A {
  set foo(int a) {
    if (a == 0) return;
  }
}
''');
  }

  Future<void> test_topLevelFunction_setter_with_return() async {
    await resolveTestCode('''
dynamic set foo(int a) {
  if (a == 0) return;
}
''');
    await assertHasFix('''
set foo(int a) {
  if (a == 0) return;
}
''');
  }
}
