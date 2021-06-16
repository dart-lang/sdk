// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceNewWithConstTest);
  });
}

@reflectiveTest
class ReplaceNewWithConstTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_constructors;

  /// Disabled in BulkFixProcessor.
  @failingTest
  Future<void> test_singleFile() async {
    await resolveTestCode(r'''
class C {
  const C();
}
main() {
  print('${new C()} ${new C()}');
}
''');
    await assertHasFix(r'''
class C {
  const C();
}
main() {
  print('${const C()} ${const C()}');
}
''');
  }
}
