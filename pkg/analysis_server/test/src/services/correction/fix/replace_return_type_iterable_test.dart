// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceReturnTypeIterableTest);
  });
}

@reflectiveTest
class ReplaceReturnTypeIterableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_RETURN_TYPE_ITERABLE;

  Future<void> test_complexTypeName() async {
    await resolveTestCode('''
List<int> f() sync* {}
''');
    await assertHasFix('''
Iterable<List<int>> f() sync* {}
''');
  }

  Future<void> test_importedWithPrefix() async {
    await resolveTestCode('''
import 'dart:core' as c;
c.int f() sync* {}
''');
    await assertHasFix('''
import 'dart:core' as c;
c.Iterable<c.int> f() sync* {}
''');
  }

  Future<void> test_simpleTypeName() async {
    await resolveTestCode('''
int f() sync* {}
''');
    await assertHasFix('''
Iterable<int> f() sync* {}
''');
  }
}
