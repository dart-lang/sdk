// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToForElementTest);
  });
}

@reflectiveTest
class ConvertToForElementTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_FOR_ELEMENT;

  @override
  String get lintCode => LintNames.prefer_for_elements_to_map_fromIterable;

  /// More coverage in the `convert_to_for_element_line_test.dart` assist test.
  Future<void>
      test_mapFromIterable_differentParameterNames_usedInKey_conflictInValue() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  var k = 3;
  return Map.fromIterable(i, key: (k) => k * 2, value: (v) => k);
}
''');
    await assertHasFix('''
f(Iterable<int> i) {
  var k = 3;
  return { for (var e in i) e * 2 : k };
}
''');
  }
}
