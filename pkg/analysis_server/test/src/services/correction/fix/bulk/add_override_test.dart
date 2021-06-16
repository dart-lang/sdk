// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddOverrideTest);
  });
}

@reflectiveTest
class AddOverrideTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.annotate_overrides;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  void a() {}
  void aa() {}
}

class B extends A {
  void a() {}
  void aa() {}
}
''');
    await assertHasFix('''
class A {
  void a() {}
  void aa() {}
}

class B extends A {
  @override
  void a() {}
  @override
  void aa() {}
}
''');
  }
}
