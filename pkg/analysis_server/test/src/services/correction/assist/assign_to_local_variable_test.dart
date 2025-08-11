// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignToLocalVariableTest);
  });
}

@reflectiveTest
class AssignToLocalVariableTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.assignToLocalVariable;

  Future<void> test_alreadyAssignment() async {
    await resolveTestCode('''
void f() {
  var vvv;
  ^vvv = 42;
}
''');
    await assertNoAssist();
  }

  Future<void> test_inClosure() async {
    await resolveTestCode(r'''
void f() {
  print(() {
    12^345;
  });
}
''');
    await assertHasAssist('''
void f() {
  print(() {
    var i = 12345;
  });
}
''');
  }

  Future<void> test_invocation() async {
    await resolveTestCode('''
void f() {
  List<int> bytes;
  ^readBytes();
}
List<int> readBytes() => <int>[];
''');
    await assertHasAssist('''
void f() {
  List<int> bytes;
  var readBytes = readBytes();
}
List<int> readBytes() => <int>[];
''');
    assertLinkedGroup(
      0,
      ['readBytes = '],
      expectedSuggestions(LinkedEditSuggestionKind.VARIABLE, [
        'list',
        'bytes2',
        'readBytes',
      ]),
    );
  }

  Future<void> test_invocationArgument() async {
    await resolveTestCode(r'''
void f() {
  g(12^345);
}
void g(p) {}
''');
    await assertNoAssist();
  }

  Future<void> test_lint_prefer_final_locals() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_final_locals]);
    await resolveTestCode(r'''
void f() {
  12^345;
}
''');
    await assertHasAssist('''
void f() {
  final i = 12345;
}
''');
  }

  Future<void> test_recovery_splitExpression() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
Future<void> _extractDataForSite() async {
  final Map<String, Object> data = {};
  final data['table'][^]
}
''');
    await assertNoAssist();
  }

  Future<void> test_throw() async {
    await resolveTestCode('''
void f() {
  ^throw 42;
}
''');
    await assertNoAssist();
  }

  Future<void> test_void() async {
    await resolveTestCode('''
void f() {
  ^f();
}
void g() {}
''');
    await assertNoAssist();
  }
}
