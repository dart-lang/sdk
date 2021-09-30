// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeFieldPublicTest);
  });
}

@reflectiveTest
class MakeFieldPublicTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FIELD_PUBLIC;

  @override
  String get lintCode => LintNames.unnecessary_getters_setters;

  Future<void> test_class() async {
    await resolveTestCode('''
class C {
  int _f = 0;

  int get f => _f;

  void set f(int p) => _f = p;
}
''');
    await assertHasFix('''
class C {
  int f = 0;
}
''');
  }
}
