// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDefaultValueTest);
  });
}

@reflectiveTest
class RemoveDefaultValueTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_DEFAULT_VALUE;

  Future<void> test_default_value_on_required_parameter() async {
    await resolveTestCode('''
class A {
  int i;
  A({required this.i = 1});
}
''');
    await assertHasFix('''
class A {
  int i;
  A({required this.i});
}
''');
  }
}
