// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveQuestionMarkTest);
  });
}

@reflectiveTest
class RemoveQuestionMarkTest extends FixProcessorTest {
  @override
  List<String> get experiments => [EnableString.non_nullable];

  @override
  FixKind get kind => DartFixKind.REMOVE_QUESTION_MARK;

  Future<void> test_catchClause() async {
    await resolveTestUnit('''
class A {}
void f() {
  try {
  } on A? {
  }
}
''');
    await assertHasFix('''
class A {}
void f() {
  try {
  } on A {
  }
}
''');
  }

  Future<void> test_extendsClause() async {
    await resolveTestUnit('''
class A {}
class B extends A? {}
''');
    await assertHasFix('''
class A {}
class B extends A {}
''');
  }

  Future<void> test_implementsClause() async {
    await resolveTestUnit('''
class A {}
class B implements A? {}
''');
    await assertHasFix('''
class A {}
class B implements A {}
''');
  }

  Future<void> test_onClause_class() async {
    await resolveTestUnit('''
class A {}
mixin B on A? {}
''');
    await assertHasFix('''
class A {}
mixin B on A {}
''');
  }

  Future<void> test_withClause_class() async {
    await resolveTestUnit('''
class A {}
class B with A? {}
''');
    await assertHasFix('''
class A {}
class B with A {}
''');
  }

  Future<void> test_withClause_mixin() async {
    await resolveTestUnit('''
mixin A {}
class B with A? {}
''');
    await assertHasFix('''
mixin A {}
class B with A {}
''');
  }
}
