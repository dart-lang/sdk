// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveReturnTypeTest);
    defineReflectiveTests(RemoveReturnTypeBulkTest);
  });
}

@reflectiveTest
class RemoveReturnTypeBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  dynamic set foo(int a) {
  }
}

dynamic set foo(int a) {
}
''');
    await assertHasFix('''
class A {
  set foo(int a) {
  }
}

set foo(int a) {
}
''');
  }
}

@reflectiveTest
class RemoveReturnTypeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_RETURN_TYPE;

  Future<void> test_method_setter_with_return() async {
    await resolveTestCode('''
class A {
  dynamic set foo(int a) {
  }
}
''');
    await assertHasFix('''
class A {
  set foo(int a) {
  }
}
''');
  }

  Future<void> test_topLevelFunction_setter_with_return() async {
    await resolveTestCode('''
dynamic set foo(int a) {
}
''');
    await assertHasFix('''
set foo(int a) {
}
''');
  }
}
