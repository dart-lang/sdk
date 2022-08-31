// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordTypeTest1);
    defineReflectiveTests(RecordTypeTest2);
  });
}

@reflectiveTest
class RecordTypeTest1 extends AbstractCompletionDriverTest
    with RecordTypeTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class RecordTypeTest2 extends AbstractCompletionDriverTest
    with RecordTypeTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin RecordTypeTestCases on AbstractCompletionDriverTest {
  Future<void> test_mixin() async {
    var response = await getTestCodeSuggestions('''
void f((int, {String foo02}) r) {
  r.^
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo(r'$0')
          ..isRecordField
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo(r'foo02')
          ..isRecordField
          ..returnType.isEqualTo('String'),
      ]);
  }

  Future<void> test_named() async {
    var response = await getTestCodeSuggestions('''
void f(({int foo01, String foo02}) r) {
  r.^
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo(r'foo01')
          ..isRecordField
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo(r'foo02')
          ..isRecordField
          ..returnType.isEqualTo('String'),
      ]);
  }

  Future<void> test_positional() async {
    var response = await getTestCodeSuggestions('''
void f((int, String) r) {
  r.^
}
''');

    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo(r'$0')
          ..isRecordField
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo(r'$1')
          ..isRecordField
          ..returnType.isEqualTo('String'),
      ]);
  }
}
