// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeFieldPublicTest);
  });
}

@reflectiveTest
class MakeFieldPublicTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.makeFieldPublic;

  @override
  String get lintCode => LintNames.unnecessary_getters_setters;

  Future<void> test_class() async {
    await resolveTestCode('''
class C {
  int _f = 0;

  int get f => _f;

  void set f(int p) => _f = p;
}
''');
    await assertHasFix('''
class C {
  int f = 0;
}
''');
  }

  Future<void> test_class_removeFirstTwoMembers_avoidConflictingEdit() async {
    // The implementation of removing members picks between startStart and
    // endEnd depending on whether we're removing the first member or not. This
    // previously produced conflicting edits when removing the first two.
    //
    // This test is the same as `test_class` but with the field moved to the end
    // so that the first two members are removed.
    await resolveTestCode('''
class C {
  int get f => _f;

  void set f(int p) => _f = p;

  int _f = 0;
}
''');
    await assertHasFix('''
class C {
  int f = 0;
}
''');
  }

  Future<void> test_primaryConstructor_declaringParameter() async {
    await resolveTestCode('''
class C([var _f = 0]) {
  int get f => _f;

  void set f(int p) => _f = p;
}
''');
    await assertHasFix('''
class C([var f = 0]) {
}
''');
  }

  Future<void> test_primaryConstructor_nonDeclaringParameter() async {
    // The primary constructor parameter here is unrelated to the field.
    await resolveTestCode('''
class C([_f = 0]) {
  int _f = 0;

  int get f => _f;

  void set f(int p) => _f = p;
}
''');
    // The parameter is untouched.
    await assertHasFix('''
class C([_f = 0]) {
  int f = 0;
}
''');
  }
}
