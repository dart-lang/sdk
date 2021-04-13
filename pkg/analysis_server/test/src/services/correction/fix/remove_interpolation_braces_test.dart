// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveInterpolationBracesTest);
  });
}

@reflectiveTest
class RemoveInterpolationBracesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_INTERPOLATION_BRACES;

  @override
  String get lintCode => LintNames.unnecessary_brace_in_string_interps;

  Future<void> test_withSpace() async {
    await resolveTestCode(r'''
main() {
  var v = 42;
  print('v: ${ v}');
}
''');
    await assertHasFix(r'''
main() {
  var v = 42;
  print('v: $v');
}
''', length: 4);
  }
}
