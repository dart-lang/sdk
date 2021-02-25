// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveQuestionMarkTest);
  });
}

@reflectiveTest
class RemoveQuestionMarkTest extends FixProcessorTest with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.REMOVE_QUESTION_MARK;

  Future<void> test_catchClause() async {
    await resolveTestCode('''
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
    await resolveTestCode('''
class A {}
class B extends A? {}
''');
    await assertHasFix('''
class A {}
class B extends A {}
''');
  }

  Future<void> test_implementsClause() async {
    await resolveTestCode('''
class A {}
class B implements A? {}
''');
    await assertHasFix('''
class A {}
class B implements A {}
''');
  }

  Future<void> test_onClause_class() async {
    await resolveTestCode('''
class A {}
mixin B on A? {}
''');
    await assertHasFix('''
class A {}
mixin B on A {}
''');
  }

  Future<void> test_withClause_class() async {
    await resolveTestCode('''
class A {}
class B with A? {}
''');
    await assertHasFix('''
class A {}
class B with A {}
''');
  }

  Future<void> test_withClause_mixin() async {
    await resolveTestCode('''
mixin A {}
class B with A? {}
''');
    await assertHasFix('''
mixin A {}
class B with A {}
''');
  }
}
