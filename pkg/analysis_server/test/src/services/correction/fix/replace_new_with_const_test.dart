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
    defineReflectiveTests(ReplaceNewWithConstTest);
  });
}

@reflectiveTest
class ReplaceNewWithConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_NEW_WITH_CONST;

  @override
  String get lintCode => LintNames.prefer_const_constructors;

  Future<void> test_new() async {
    await resolveTestCode('''
class C {
  const C();
}
main() {
  var c = new C();
  print(c);
}
''');
    await assertHasFix('''
class C {
  const C();
}
main() {
  var c = const C();
  print(c);
}
''');
  }

  Future<void> test_noKeyword() async {
    await resolveTestCode('''
class C {
  const C();
}
main() {
  var c = C();
  print(c);
}
''');
    // handled by ADD_CONST
    await assertNoFix();
  }
}
