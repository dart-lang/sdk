// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingParameterPositionalTest);
  });
}

@reflectiveTest
class AddMissingParameterPositionalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL;

  Future<void> test_function_hasNamed() async {
    await resolveTestCode('''
test({int a}) {}
main() {
  test(1);
}
''');
    await assertNoFix();
  }

  Future<void> test_function_hasZero() async {
    await resolveTestCode('''
test() {}
main() {
  test(1);
}
''');
    await assertHasFix('''
test([int i]) {}
main() {
  test(1);
}
''');
  }

  Future<void> test_method_hasOne() async {
    await resolveTestCode('''
class A {
  test(int a) {}
  main() {
    test(1, 2.0);
  }
}
''');
    await assertHasFix('''
class A {
  test(int a, [double d]) {}
  main() {
    test(1, 2.0);
  }
}
''');
  }
}
