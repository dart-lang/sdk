// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSpreadTest);
  });
}

@reflectiveTest
class ConvertToSpreadTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_spread_collections;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  var ints = [1, 2, 3];
  print(['a']..addAll(ints.map((i) => i.toString()))..addAll(['c']));
}

f2() {
  bool condition;
  var things;
  var l = ['a']..addAll(condition ? things : []);
}
''');
    await assertHasFix('''
f() {
  var ints = [1, 2, 3];
  print(['a', ...ints.map((i) => i.toString())]..addAll(['c']));
}

f2() {
  bool condition;
  var things;
  var l = ['a', if (condition) ...things];
}
''');
  }
}
