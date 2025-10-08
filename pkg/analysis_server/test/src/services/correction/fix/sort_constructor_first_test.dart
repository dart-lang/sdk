// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortConstructorFirstBulkTest);
    defineReflectiveTests(SortConstructorFirstTest);
  });
}

@reflectiveTest
class SortConstructorFirstBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.sort_constructors_first;

  Future<void> test_multiple_classes() async {
    await resolveTestCode('''
class A {
  X() {}
  A();
}

class B {
  Y() {}
  B();
}
''');
    await assertHasFix('''
class A {
  A();
  X() {}
}

class B {
  B();
  Y() {}
}
''');
  }

  Future<void> test_single_class() async {
    await resolveTestCode('''
class A {
  X() {}

  A();

  Y() {}

  A._();
}
''');
    await assertHasFix('''
class A {

  A();

  A._();
  X() {}

  Y() {}
}
''');
  }
}

@reflectiveTest
class SortConstructorFirstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.sortConstructorFirst;

  @override
  String get lintCode => LintNames.sort_constructors_first;

  Future<void> test_hasComment() async {
    await resolveTestCode('''
class A {
  void foo() {}
  /// comment
  A();
}
''');
    await assertHasFix('''
class A {
  /// comment
  A();
  void foo() {}
}
''');
  }

  Future<void> test_hasComment_hasMetadata_afterComment() async {
    await resolveTestCode('''
const a = 0;

class A {
  void foo() {}
  /// comment
  @a
  A();
}
''');
    await assertHasFix('''
const a = 0;

class A {
  /// comment
  @a
  A();
  void foo() {}
}
''');
  }

  Future<void> test_hasComment_hasMetadata_beforeComment() async {
    await resolveTestCode('''
const a = 0;

class A {
  void foo() {}
  @a
  /// comment
  A();
}
''');
    await assertHasFix('''
const a = 0;

class A {
  @a
  /// comment
  A();
  void foo() {}
}
''');
  }

  Future<void> test_one_fix() async {
    await resolveTestCode('''
class A {
  X() {}
  A();
}
''');
    await assertHasFix('''
class A {
  A();
  X() {}
}
''');
  }
}
