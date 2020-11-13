// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortChildPropertyLastTest);
  });
}

@reflectiveTest
class SortChildPropertyLastTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.sort_child_properties_last;

  Future<void> test_singleFile() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Column(
        children: [
          Text('a'),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      Text('b'),
      Text('c'),
      Text('d'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
  );
}
''');
    // todo (pq): two diagnostics are produced but only the first is fixed.
    // see: linter/test/rules/sort_child_properties_last.dart:nestedChildren()
    await assertHasFix('''
import 'package:flutter/material.dart';
main() {
  Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Column(
        children: [
          Text('a'),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      Text('b'),
      Text('c'),
      Text('d'),
    ],
  );
}
''');
  }
}
