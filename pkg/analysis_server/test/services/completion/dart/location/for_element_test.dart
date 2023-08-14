// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementTest1);
    defineReflectiveTests(ForElementTest2);
  });
}

mixin ForElementInListTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterRightParen() async {
    await computeSuggestions('''
f() => [for (var e in c) ^];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }
}

@reflectiveTest
class ForElementTest1 extends AbstractCompletionDriverTest
    with ForElementInListTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ForElementTest2 extends AbstractCompletionDriverTest
    with ForElementInListTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}
