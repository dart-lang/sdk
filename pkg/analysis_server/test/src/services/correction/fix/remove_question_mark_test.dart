// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveQuestionMarkBulkTest);
    defineReflectiveTests(RemoveQuestionMarkTest);
    defineReflectiveTests(UnnecessaryNullableForFinalVariableDeclarationsTest);
  });
}

@reflectiveTest
class RemoveQuestionMarkBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode =>
      LintNames.unnecessary_nullable_for_final_variable_declarations;

  @override
  String get testPackageLanguageVersion => latestLanguageVersion;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  static final int? x = 0;
  static final int? y = 0;
}
''');
    await assertHasFix('''
class C {
  static final int x = 0;
  static final int y = 0;
}
''');
  }
}

@reflectiveTest
class RemoveQuestionMarkTest extends FixProcessorTest {
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

@reflectiveTest
class UnnecessaryNullableForFinalVariableDeclarationsTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_QUESTION_MARK;

  @override
  String get lintCode => 'unnecessary_nullable_for_final_variable_declarations';

  Future<void> test_const_field_static() async {
    await resolveTestCode('''
class C {
  static const int? zero = 0;
}
''');
    await assertHasFix('''
class C {
  static const int zero = 0;
}
''');
  }

  Future<void> test_const_topLevelVariable() async {
    await resolveTestCode('''
const int? zero = 0;
''');
    await assertHasFix('''
const int zero = 0;
''');
  }

  Future<void> test_final_field_static() async {
    await resolveTestCode('''
class C {
  static final int? zero = 0;
}
''');
    await assertHasFix('''
class C {
  static final int zero = 0;
}
''');
  }

  Future<void> test_final_localVariable() async {
    await resolveTestCode('''
void f() {
  final int? zero = 0;
  zero;
}
''');
    await assertHasFix('''
void f() {
  final int zero = 0;
  zero;
}
''');
  }

  Future<void> test_final_topLevelVariable() async {
    await resolveTestCode('''
final int? zero = 0;
''');
    await assertHasFix('''
final int zero = 0;
''');
  }
}
