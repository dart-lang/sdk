// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeRequiredNamedParametersFirstBulkTest);
    defineReflectiveTests(MakeRequiredNamedParametersFirstTest);
    defineReflectiveTests(MakeRequiredNamedParametersInFileTest);
  });
}

@reflectiveTest
class MakeRequiredNamedParametersFirstBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.always_put_required_named_parameters_first;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f({int? b, required int a}) {}
void g({int? b, required int a,}) {}
''');
    await assertHasFix('''
void f({required int a, int? b}) {}
void g({required int a, int? b,}) {}
''');
  }
}

@reflectiveTest
class MakeRequiredNamedParametersFirstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.MAKE_REQUIRED_NAMED_PARAMETERS_FIRST;

  @override
  String get lintCode => LintNames.always_put_required_named_parameters_first;

  Future<void> test_comma() async {
    await resolveTestCode('''
void f({int? b, required int a,}) {}
''');
    await assertHasFix('''
void f({required int a, int? b,}) {}
''');
  }

  Future<void> test_comment() async {
    await resolveTestCode('''
void f({int? b, /* aa */ required int a}) {}
''');
    await assertHasFix('''
void f({/* aa */ required int a, int? b}) {}
''');
  }

  Future<void> test_comment_both() async {
    await resolveTestCode('''
void f({/* bb */ int? b, /* aa */ required int a}) {}
''');
    await assertHasFix('''
void f({/* aa */ required int a, /* bb */ int? b}) {}
''');
  }

  Future<void> test_comment_both_multiple() async {
    await resolveTestCode('''
void f({/* b1 */ /* b2 */ int? b, /* a1 */ /* a2 */ required int a}) {}
''');
    await assertHasFix('''
void f({/* a1 */ /* a2 */ required int a, /* b1 */ /* b2 */ int? b}) {}
''');
  }

  Future<void> test_comment_first() async {
    await resolveTestCode('''
void f({/* bb */ int? b, required int a}) {}
''');
    await assertHasFix('''
void f({required int a, /* bb */ int? b}) {}
''');
  }

  Future<void> test_comments() async {
    await resolveTestCode('''
void f({int? a /* a */, required int b /* b1 */ /* b2 */}) {}
''');
    await assertHasFix('''
void f({required int b /* b1 */ /* b2 */, int? a /* a */}) {}
''');
  }

  Future<void> test_single() async {
    await resolveTestCode('''
void f({int? b, required int a}) {}
''');
    await assertHasFix('''
void f({required int a, int? b}) {}
''');
  }
}

@reflectiveTest
class MakeRequiredNamedParametersInFileTest extends FixInFileProcessorTest {
  Future<void> test_file() async {
    createAnalysisOptionsFile(
        lints: [LintNames.always_put_required_named_parameters_first]);
    await resolveTestCode(r'''
void f({int? c, required int a, required int b}) {}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
void f({required int a, required int b, int? c}) {}
''');
  }

  Future<void> test_multiple() async {
    createAnalysisOptionsFile(
        lints: [LintNames.always_put_required_named_parameters_first]);
    await resolveTestCode(r'''
void f({required int a, int? d, required num b, required String c,}) {}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
void f({required int a, required num b, required String c, int? d,}) {}
''');
  }
}
