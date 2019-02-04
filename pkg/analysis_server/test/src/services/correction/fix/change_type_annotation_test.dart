// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeTypeAnnotationTest);
  });
}

@reflectiveTest
class ChangeTypeAnnotationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TYPE_ANNOTATION;

  test_generic() async {
    await resolveTestUnit('''
main() {
  String v = <int>[];
  print(v);
}
''');
    await assertHasFix('''
main() {
  List<int> v = <int>[];
  print(v);
}
''');
  }

  test_multipleVariables() async {
    await resolveTestUnit('''
main() {
  String a, b = 42;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  test_notVariableDeclaration() async {
    await resolveTestUnit('''
main() {
  String v;
  v = 42;
  print(v);
}
''');
    await assertNoFix();
  }

  test_simple() async {
    await resolveTestUnit('''
main() {
  String v = 'abc'.length;
  print(v);
}
''');
    await assertHasFix('''
main() {
  int v = 'abc'.length;
  print(v);
}
''');
  }
}
