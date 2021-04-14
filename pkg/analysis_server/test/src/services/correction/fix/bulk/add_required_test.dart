// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    // Note that this lint does not fire w/ NNBD.
    defineReflectiveTests(AddRequiredTest);
  });
}

@reflectiveTest
class AddRequiredTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.always_require_non_null_named_parameters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void function({String p1, int p2}) {
  assert(p1 != null);
  assert(p2 != null);
}
''');
    await assertHasFix('''
void function({@required String p1, @required int p2}) {
  assert(p1 != null);
  assert(p2 != null);
}
''');
  }
}
