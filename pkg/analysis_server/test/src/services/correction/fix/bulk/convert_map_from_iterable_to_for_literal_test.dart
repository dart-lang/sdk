// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToForElementTest);
  });
}

@reflectiveTest
class ConvertToForElementTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_for_elements_to_map_fromIterable;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  var k = 3;
  return Map.fromIterable(i, key: (k) => k * 2, value: (v) => k);
}

f2(Iterable<int> i) {
  return Map.fromIterable(i, key: (k) => k * 2, value: (v) => 0);
}
''');
    await assertHasFix('''
f(Iterable<int> i) {
  var k = 3;
  return { for (var e in i) e * 2 : k };
}

f2(Iterable<int> i) {
  return { for (var k in i) k * 2 : 0 };
}
''');
  }
}
