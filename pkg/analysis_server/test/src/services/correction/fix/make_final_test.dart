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
    defineReflectiveTests(MakeFinalTest);
  });
}

@reflectiveTest
class MakeFinalTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_FINAL;

  @override
  String get lintCode => LintNames.prefer_final_fields;

  test_field_type() async {
    await resolveTestUnit('''
class C {
  int /*LINT*/f = 2;
}
''');
    await assertHasFix('''
class C {
  final int /*LINT*/f = 2;
}
''');
  }

  test_field_var() async {
    await resolveTestUnit('''
class C {
  var /*LINT*/f = 2;
}
''');
    await assertHasFix('''
class C {
  final /*LINT*/f = 2;
}
''');
  }

  test_local_type() async {
    await resolveTestUnit('''
bad() {
  int /*LINT*/x = 2;
}
''');
    await assertHasFix('''
bad() {
  final int /*LINT*/x = 2;
}
''');
  }

  test_local_var() async {
    await resolveTestUnit('''
bad() {
  var /*LINT*/x = 2;
}
''');
    await assertHasFix('''
bad() {
  final /*LINT*/x = 2;
}
''');
  }

  test_noKeyword() async {
    await resolveTestUnit('''
class C {
  /*LINT*/f = 2;
}
''');
    await assertHasFix('''
class C {
  /*LINT*/final f = 2;
}
''');
  }

  test_topLevel_type() async {
    await resolveTestUnit('''
int /*LINT*/x = 2;
''');
    await assertHasFix('''
final int /*LINT*/x = 2;
''');
  }

  test_topLevel_var() async {
    await resolveTestUnit('''
var /*LINT*/x = 2;
''');
    await assertHasFix('''
final /*LINT*/x = 2;
''');
  }
}
