// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToListLiteralTest);
  });
}

@reflectiveTest
class ConvertToListLiteralTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_collection_literals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
List l = List();
var l2 = List<int>();
''');
    await assertHasFix('''
List l = [];
var l2 = <int>[];
''');
  }
}
