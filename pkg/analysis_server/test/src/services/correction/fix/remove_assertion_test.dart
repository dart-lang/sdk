// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveAssertionTest);
  });
}

@reflectiveTest
class RemoveAssertionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ASSERTION;

  Future<void> test_class() async {
    await resolveTestCode('''
class A {
  A(int x) : assert(x > 0), this.name();
  A.name() {}
}
''');
    await assertHasFix('''
class A {
  A(int x) : this.name();
  A.name() {}
}
''');
  }

  Future<void> test_enum() async {
    await resolveTestCode('''
enum E {
  v(42);
  const E(int x) : this.name(), assert(x > 0);
  const E.name();
}
''');
    await assertHasFix('''
enum E {
  v(42);
  const E(int x) : this.name();
  const E.name();
}
''');
  }
}
