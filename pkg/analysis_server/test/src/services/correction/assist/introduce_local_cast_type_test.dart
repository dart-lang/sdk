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
    defineReflectiveTests(IntroduceLocalCastTypeTest);
  });
}

@reflectiveTest
class IntroduceLocalCastTypeTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE;

  Future<void> test_introduceLocalTestedType_if_is() async {
    await resolveTestCode('''
class MyTypeName {}
main(p) {
  if (p is MyTypeName) {
  }
  p = null;
}
''');
    var expected = '''
class MyTypeName {}
main(p) {
  if (p is MyTypeName) {
    MyTypeName myTypeName = p;
  }
  p = null;
}
''';
    await assertHasAssistAt('is MyType', expected);
    assertLinkedGroup(
        0,
        ['myTypeName = '],
        expectedSuggestions(LinkedEditSuggestionKind.VARIABLE,
            ['myTypeName', 'typeName', 'name']));
    // another good location
    await assertHasAssistAt('if (p', expected);
  }

  Future<void> test_introduceLocalTestedType_if_isNot() async {
    await resolveTestCode('''
class MyTypeName {}
main(p) {
  if (p is! MyTypeName) {
    return;
  }
}
''');
    var expected = '''
class MyTypeName {}
main(p) {
  if (p is! MyTypeName) {
    return;
  }
  MyTypeName myTypeName = p;
}
''';
    await assertHasAssistAt('is! MyType', expected);
    assertLinkedGroup(
        0,
        ['myTypeName = '],
        expectedSuggestions(LinkedEditSuggestionKind.VARIABLE,
            ['myTypeName', 'typeName', 'name']));
    // another good location
    await assertHasAssistAt('if (p', expected);
  }

  Future<void> test_introduceLocalTestedType_notBlock() async {
    await resolveTestCode('''
main(p) {
  if (p is String)
    print('not a block');
}
''');
    await assertNoAssistAt('if (p');
  }

  Future<void> test_introduceLocalTestedType_notIsExpression() async {
    await resolveTestCode('''
main(p) {
  if (p == null) {
  }
}
''');
    await assertNoAssistAt('if (p');
  }

  Future<void> test_introduceLocalTestedType_notStatement() async {
    await resolveTestCode('''
class C {
  bool b;
  C(v) : b = v is int;
}''');
    await assertNoAssistAt('is int');
  }

  Future<void> test_introduceLocalTestedType_while() async {
    await resolveTestCode('''
main(p) {
  while (p is String) {
  }
  p = null;
}
''');
    var expected = '''
main(p) {
  while (p is String) {
    String s = p;
  }
  p = null;
}
''';
    await assertHasAssistAt('is String', expected);
    await assertHasAssistAt('while (p', expected);
  }
}
