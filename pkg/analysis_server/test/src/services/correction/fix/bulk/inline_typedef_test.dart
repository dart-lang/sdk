// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineTypedefTest);
  });
}

@reflectiveTest
class InlineTypedefTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_private_typedef_functions;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
typedef _F1 = void Function(int);
typedef _F2<T> = void Function(T);
void g(_F2<_F1> f) {}
''');
    // Eventually both fixes will be applied but for now we're satisfied that
    // the results are clean.
    await assertHasFix('''
typedef _F2<T> = void Function(T);
void g(_F2<void Function(int)> f) {}
''');
  }
}
