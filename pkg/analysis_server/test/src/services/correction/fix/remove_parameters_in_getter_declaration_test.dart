// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveParametersInGetterDeclarationTest);
  });
}

@reflectiveTest
class RemoveParametersInGetterDeclarationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION;

  test_emptyList() async {
    await resolveTestUnit('''
class A {
  int get foo() => 0;
}
''');
    await assertHasFix('''
class A {
  int get foo => 0;
}
''');
  }

  test_nonEmptyList() async {
    await resolveTestUnit('''
class A {
  int get foo(int a) => 0;
}
''');
    await assertHasFix('''
class A {
  int get foo => 0;
}
''');
  }
}
