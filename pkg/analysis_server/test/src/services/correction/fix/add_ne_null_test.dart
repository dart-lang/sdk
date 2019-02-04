// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddNeNullTest);
  });
}

@reflectiveTest
class AddNeNullTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_NE_NULL;

  test_nonBoolCondition() async {
    await resolveTestUnit('''
main(String p) {
  if (p) {
    print(p);
  }
}
''');
    await assertHasFix('''
main(String p) {
  if (p != null) {
    print(p);
  }
}
''');
  }

  test_nonBoolCondition_all() async {
    await resolveTestUnit('''
main(String p, String q) {
  if (p) {
    print(p);
  }
  if (q) {
    print(q);
  }
}
''');
    await assertHasFixAllFix(StaticTypeWarningCode.NON_BOOL_CONDITION, '''
main(String p, String q) {
  if (p != null) {
    print(p);
  }
  if (q != null) {
    print(q);
  }
}
''');
  }
}
