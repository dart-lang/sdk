// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLateBulkTest);
    defineReflectiveTests(RemoveLateTest);
  });
}

@reflectiveTest
class RemoveLateBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(Object? x) {
  late var (_) = x;
  late var (_) = x;
}
''');
    await assertHasFix('''
void f(Object? x) {
  var (_) = x;
  var (_) = x;
}
''');
  }
}

@reflectiveTest
class RemoveLateTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeLate;

  Future<void> test_deadLateWildcardVariableInitializer() async {
    await resolveTestCode('''
f() {
  late var _ = 0;
}
''');
    await assertHasFix('''
f() {
  var _ = 0;
}
''');
  }

  Future<void> test_it() async {
    await resolveTestCode('''
void f(Object? x) {
  late var (_) = x;
}
''');
    await assertHasFix('''
void f(Object? x) {
  var (_) = x;
}
''');
  }

  test_late_await() async {
    await resolveTestCode('''
main() async {
  late var v = await 42;
  print(v);
}
''');
    await assertHasFix('''
main() async {
  var v = await 42;
  print(v);
}
''');
  }
}
