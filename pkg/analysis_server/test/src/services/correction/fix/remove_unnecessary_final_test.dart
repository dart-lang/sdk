// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryFinalBulkTest);
    defineReflectiveTests(RemoveUnnecessaryFinalMultiTest);
    defineReflectiveTests(RemoveUnnecessaryFinalTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryFinalBulkTest extends BulkFixProcessorTest {
  Future<void> test_assignment() async {
    await resolveTestCode('''
class A {
  A(final this.value);
  int value;
}
class B extends A {
  B(final super.value);
}
''');
    await assertHasFix('''
class A {
  A(this.value);
  int value;
}
class B extends A {
  B(super.value);
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryFinalMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_FINAL_MULTI;

  Future<void> test_multi() async {
    await resolveTestCode('''
class A {
  A(final this.v1, final this.v2);
  int v1;
  int v2;
}
''');
    await assertHasFixAllFix(WarningCode.UNNECESSARY_FINAL, '''
class A {
  A(this.v1, this.v2);
  int v1;
  int v2;
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryFinalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_FINAL;

  Future<void> test_positional() async {
    await resolveTestCode('''
class C {
  C([final this.value = 0]);
  int value;
}
''');
    await assertHasFix('''
class C {
  C([this.value = 0]);
  int value;
}
''');
  }

  Future<void> test_super() async {
    await resolveTestCode('''
class A {
  A(this.value);
  int value;
}
class B extends A {
  B(final super.value);
}
''');
    await assertHasFix('''
class A {
  A(this.value);
  int value;
}
class B extends A {
  B(super.value);
}
''');
  }

  Future<void> test_this() async {
    await resolveTestCode('''
class C {
  C(final this.value);
  int value;
}
''');
    await assertHasFix('''
class C {
  C(this.value);
  int value;
}
''');
  }
}
