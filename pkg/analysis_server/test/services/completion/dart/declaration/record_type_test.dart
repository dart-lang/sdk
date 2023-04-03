// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

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
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) => true,
      withReturnType: true,
    );
  }

  Future<void> test_mixed() async {
    await computeSuggestions('''
void f((int, {String foo02}) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  $1
    kind: identifier
    returnType: int
  foo02
    kind: identifier
    returnType: String
  hashCode
    kind: getter
    returnType: int
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
  runtimeType
    kind: getter
    returnType: Type
  toString
    kind: methodInvocation
    returnType: String
''');
  }

  Future<void> test_named() async {
    await computeSuggestions('''
void f(({int foo01, String foo02}) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  foo01
    kind: identifier
    returnType: int
  foo02
    kind: identifier
    returnType: String
  hashCode
    kind: getter
    returnType: int
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
  runtimeType
    kind: getter
    returnType: Type
  toString
    kind: methodInvocation
    returnType: String
''');
  }

  Future<void> test_positional() async {
    await computeSuggestions('''
void f((int, String) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  $1
    kind: identifier
    returnType: int
  $2
    kind: identifier
    returnType: String
  hashCode
    kind: getter
    returnType: int
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
  runtimeType
    kind: getter
    returnType: Type
  toString
    kind: methodInvocation
    returnType: String
''');
  }
}
