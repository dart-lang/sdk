// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryConstTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryConstTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_const;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C { const C(); }
class D { const D(C c); }
const c = const C();
const list = const [];
var d = const D(const C());
''');
    await assertHasFix('''
class C { const C(); }
class D { const D(C c); }
const c = C();
const list = [];
var d = const D(C());
''');
  }
}
