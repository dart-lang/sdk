// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddReturnNullBulkTest);
    defineReflectiveTests(AddReturnNullTest);
  });
}

@reflectiveTest
class AddReturnNullBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
int? f() {
  // ignore: unused_element
  int? g() {
    if (1 == 2) return 5;
  }
  if (1 == 2) return 7;
}
''');
    await assertHasFix('''
int? f() {
  // ignore: unused_element
  int? g() {
    if (1 == 2) return 5;
    return null;
  }
  if (1 == 2) return 7;
  return null;
}
''');
  }
}

@reflectiveTest
class AddReturnNullTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_RETURN_NULL;

  Future<void> test_functionExpression() async {
    await resolveTestCode('''
int? Function() f = () {
  if (1 == 2) return 7;
};
''');
    await assertHasFix('''
int? Function() f = () {
  if (1 == 2) return 7;
  return null;
};
''');
  }

  Future<void> test_functionExpression_empty() async {
    await resolveTestCode('''
int? Function() f = () {};
''');
    await assertHasFix('''
int? Function() f = () {
  return null;
};
''');
  }

  Future<void> test_localFunction() async {
    await resolveTestCode('''
void m() {
  // ignore: unused_element
  int? f() {
    if (1 == 2) return 7;
  }
}
''');
    await assertHasFix('''
void m() {
  // ignore: unused_element
  int? f() {
    if (1 == 2) return 7;
    return null;
  }
}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class A {
  int? m() {
    if (1 == 2) return 7;
  }
}
''');
    await assertHasFix('''
class A {
  int? m() {
    if (1 == 2) return 7;
    return null;
  }
}
''');
  }

  Future<void> test_topLevelFunction_block() async {
    await resolveTestCode('''
int? f() {
  if (1 == 2) return 7;
}
''');
    await assertHasFix('''
int? f() {
  if (1 == 2) return 7;
  return null;
}
''');
  }
}
