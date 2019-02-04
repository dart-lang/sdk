// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoIsNotEmptyTest);
  });
}

@reflectiveTest
class ConvertIntoIsNotEmptyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY;

  test_noBang() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
main(String str) {
  ~str.isEmpty;
}
''');
    await assertNoAssistAt('isEmpty;');
  }

  test_noIsNotEmpty() async {
    await resolveTestUnit('''
class A {
  bool get isEmpty => false;
}
main(A a) {
  !a.isEmpty;
}
''');
    await assertNoAssistAt('isEmpty;');
  }

  test_notInPrefixExpression() async {
    await resolveTestUnit('''
main(String str) {
  str.isEmpty;
}
''');
    await assertNoAssistAt('isEmpty;');
  }

  test_notIsEmpty() async {
    await resolveTestUnit('''
main(int p) {
  !p.isEven;
}
''');
    await assertNoAssistAt('isEven;');
  }

  test_on_isEmpty() async {
    await resolveTestUnit('''
main(String str) {
  !str.isEmpty;
}
''');
    await assertHasAssistAt('isEmpty', '''
main(String str) {
  str.isNotEmpty;
}
''');
  }

  test_on_str() async {
    await resolveTestUnit('''
main(String str) {
  !str.isEmpty;
}
''');
    await assertHasAssistAt('str.', '''
main(String str) {
  str.isNotEmpty;
}
''');
  }

  test_propertyAccess() async {
    await resolveTestUnit('''
main(String str) {
  !'text'.isEmpty;
}
''');
    await assertHasAssistAt('isEmpty', '''
main(String str) {
  'text'.isNotEmpty;
}
''');
  }
}
