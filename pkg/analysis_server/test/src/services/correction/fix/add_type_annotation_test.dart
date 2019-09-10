// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTypeAnnotationTest);
  });
}

@reflectiveTest
class AddTypeAnnotationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_TYPE_ANNOTATION;

  @override
  String get lintCode => LintNames.always_specify_types;

  // More coverage in the `add_type_annotation_test.dart` assist test.
  test_do_block() async {
    await resolveTestUnit('''
class A {
  /*LINT*/final f = 0;
}
''');
    await assertHasFix('''
class A {
  /*LINT*/final int f = 0;
}
''');
  }
}
