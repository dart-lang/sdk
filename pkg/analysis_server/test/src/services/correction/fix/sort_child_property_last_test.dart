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
    defineReflectiveTests(SortChildPropertyLastTest);
  });
}

@reflectiveTest
class SortChildPropertyLastTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.SORT_CHILD_PROPERTY_LAST;

  @override
  String get lintCode => LintNames.sort_child_properties_last;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  /// More coverage in the `sort_child_properties_last_test.dart` assist test.
  Future<void> test_sort() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';
main() {
  Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
  );
}
''');
  }
}
