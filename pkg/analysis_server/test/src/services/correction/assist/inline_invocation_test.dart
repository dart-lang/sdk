// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineInvocationTest);
  });
}

@reflectiveTest
class InlineInvocationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.INLINE_INVOCATION;

  Future<void> test_add_emptyTarget() async {
    await resolveTestCode('''
var l = []..ad/*caret*/d('a')..add('b');
''');
    await assertHasAssist('''
var l = ['a']..add('b');
''');
  }

  Future<void> test_add_emptyTarget_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_inlined_adds]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
var l = []..ad/*caret*/d('a')..add('b');
''');
    await assertNoAssist();
  }

  Future<void> test_add_nonEmptyTarget() async {
    await resolveTestCode('''
var l = ['a']..ad/*caret*/d('b')..add('c');
''');
    await assertHasAssist('''
var l = ['a', 'b']..add('c');
''');
  }

  Future<void> test_add_nonLiteralArgument() async {
    await resolveTestCode('''
var e = 'b';
var l = ['a']..add/*caret*/(e);
''');
    await assertHasAssist('''
var e = 'b';
var l = ['a', e];
''');
  }

  Future<void> test_add_nonLiteralTarget() async {
    await resolveTestCode('''
var l1 = [];
var l2 = l1..ad/*caret*/d('b')..add('c');
''');
    await assertNoAssist();
  }

  Future<void> test_add_notFirst() async {
    await resolveTestCode('''
var l = ['a']..add('b')../*caret*/add('c');
''');
    await assertNoAssist();
  }

  Future<void> test_addAll_emptyTarget() async {
    await resolveTestCode('''
var l = []..add/*caret*/All(['a'])..addAll(['b']);
''');
    await assertHasAssist('''
var l = ['a']..addAll(['b']);
''');
  }

  Future<void> test_addAll_emptyTarget_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_inlined_adds]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
var l = []..add/*caret*/All(['a'])..addAll(['b']);
''');
    await assertNoAssist();
  }

  Future<void> test_addAll_nonEmptyTarget() async {
    await resolveTestCode('''
var l = ['a']..add/*caret*/All(['b'])..addAll(['c']);
''');
    await assertHasAssist('''
var l = ['a', 'b']..addAll(['c']);
''');
  }

  Future<void> test_addAll_nonLiteralArgument() async {
    await resolveTestCode('''
var l1 = <String>[];
var l2 = ['a']..add/*caret*/All(l1);
''');
    await assertNoAssist();
  }

  Future<void> test_addAll_nonLiteralTarget() async {
    await resolveTestCode('''
var l1 = [];
var l2 = l1..addAl/*caret*/l(['b'])..addAll(['c']);
''');
    await assertNoAssist();
  }

  Future<void> test_addAll_notFirst() async {
    await resolveTestCode('''
var l = ['a']..addAll(['b'])../*caret*/addAll(['c']);
''');
    await assertNoAssist();
  }
}
