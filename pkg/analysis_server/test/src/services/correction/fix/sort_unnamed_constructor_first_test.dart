// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortUnnamedConstructorFirstBulkTest);
    defineReflectiveTests(SortUnnamedConstructorFirstTest);
  });
}

@reflectiveTest
class SortUnnamedConstructorFirstBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.sort_unnamed_constructors_first;

  Future<void> test_one_fix() async {
    await resolveTestCode('''
class A {
  A.a();
  A();
}

class B {
  B.b();
  B();
}
''');
    await assertHasFix('''
class A {
  A();
  A.a();
}

class B {
  B();
  B.b();
}
''');
  }
}

@reflectiveTest
class SortUnnamedConstructorFirstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.SORT_UNNAMED_CONSTRUCTOR_FIRST;

  @override
  String get lintCode => LintNames.sort_unnamed_constructors_first;

  Future<void> test_one_fix() async {
    await resolveTestCode('''
class A {
  A.a();
  A();
}
''');
    await assertHasFix('''
class A {
  A();
  A.a();
}
''');
  }

  Future<void> test_with_non_constructors() async {
    await resolveTestCode('''
class A {
  static const int i = 0;

  A.a();

  A();
}
''');
    await assertHasFix('''
class A {
  static const int i = 0;

  A();

  A.a();
}
''');
  }

  Future<void> test_with_non_constructors_2() async {
    await resolveTestCode('''
class A {
  A.a();

  static const int i = 0;

  A();
}
''');
    await assertHasFix('''
class A {

  A();
  A.a();

  static const int i = 0;
}
''');
  }
}
