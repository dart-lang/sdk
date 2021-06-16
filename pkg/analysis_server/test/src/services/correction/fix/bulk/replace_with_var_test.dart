// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithVarTest);
  });
}

@reflectiveTest
class ReplaceWithVarTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.omit_local_variable_types;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
List f() {
  List<int> l = [];
  return l;
}

void f2(List<int> list) {
  for (int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
List f() {
  var l = <int>[];
  return l;
}

void f2(List<int> list) {
  for (var i in list) {
    print(i);
  }
}
''');
  }
}
