// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveInterpolationBracesTest);
  });
}

@reflectiveTest
class RemoveInterpolationBracesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_INTERPOLATION_BRACES;

  @override
  String get lintCode => LintNames.unnecessary_brace_in_string_interp;

  test_withSpace() async {
    await resolveTestUnit(r'''
main() {
  var v = 42;
  print('v: /*LINT*/${ v}');
}
''');
    await assertHasFix(r'''
main() {
  var v = 42;
  print('v: /*LINT*/$v');
}
''', length: 4);
  }
}
