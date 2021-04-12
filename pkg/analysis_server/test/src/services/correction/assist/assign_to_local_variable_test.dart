// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
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
  AssistKind get kind => DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE;

  Future<void> test_alreadyAssignment() async {
    await resolveTestCode('''
main() {
  var vvv;
  vvv = 42;
}
''');
    await assertNoAssistAt('vvv =');
  }

  Future<void> test_inClosure() async {
    await resolveTestCode(r'''
main() {
  print(() {
    12345;
  });
}
''');
    await assertHasAssistAt('345', '''
main() {
  print(() {
    var i = 12345;
  });
}
''');
  }

  Future<void> test_invocation() async {
    await resolveTestCode('''
main() {
  List<int> bytes;
  readBytes();
}
List<int> readBytes() => <int>[];
''');
    await assertHasAssistAt('readBytes();', '''
main() {
  List<int> bytes;
  var readBytes = readBytes();
}
List<int> readBytes() => <int>[];
''');
    assertLinkedGroup(
        0,
        ['readBytes = '],
        expectedSuggestions(LinkedEditSuggestionKind.VARIABLE,
            ['list', 'bytes2', 'readBytes']));
  }

  Future<void> test_invocationArgument() async {
    await resolveTestCode(r'''
main() {
  f(12345);
}
void f(p) {}
''');
    await assertNoAssistAt('345');
  }

  Future<void> test_recovery_splitExpression() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
Future<void> _extractDataForSite() async {
  final Map<String, Object> data = {};
  final data['table'][] //marker
}
''');
    assertNoAssistAt('] //marker');
  }

  Future<void> test_throw() async {
    await resolveTestCode('''
main() {
  throw 42;
}
''');
    await assertNoAssistAt('throw ');
  }

  Future<void> test_void() async {
    await resolveTestCode('''
main() {
  f();
}
void f() {}
''');
    await assertNoAssistAt('f();');
  }
}
