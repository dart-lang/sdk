// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchPatternCaseTest1);
    defineReflectiveTests(SwitchPatternCaseTest2);
  });
}

@reflectiveTest
class SwitchPatternCaseTest1 extends AbstractCompletionDriverTest
    with SwitchPatternCaseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class SwitchPatternCaseTest2 extends AbstractCompletionDriverTest
    with SwitchPatternCaseTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SwitchPatternCaseTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    // TODO(brianwilkerson) Include more than keywords in these tests.
    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        final completion = suggestion.completion;
        return suggestion.kind == CompletionSuggestionKind.KEYWORD ||
            ['A0', 'B0'].any(completion.startsWith);
      },
    );
  }

  Future<void> test_afterColon() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case 'a' : ^
      return;
  }
}
class A01 {}
''');
    assertResponse('''
suggestions
  break
    kind: keyword
  return
    kind: keyword
  if
    kind: keyword
  A01
    kind: class
  final
    kind: keyword
  for
    kind: keyword
  throw
    kind: keyword
  A01
    kind: constructorInvocation
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  late
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterAs_afterDeclaration() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case var x as ^:
      return;
  }
}
''');
    // TODO(brianwilkerson) This should include `dynamic` and types.
    assertResponse('''
suggestions
''');
  }

  Future<void> test_beforeColon_afterAs_afterReference() async {
    await computeSuggestions('''
void f(Object o) {
  const x = 0;
  switch (o) {
    case x as ^:
      return;
  }
}
''');
    // TODO(brianwilkerson) This should include `dynamic` and types.
    assertResponse('''
suggestions
''');
  }

  Future<void> test_beforeColon_afterConstantPattern() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case 'a' ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterListPattern() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case [2, 3] ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterMapPattern() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case {'a' : 'b'} ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterObjectPattern() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case String(length: 2) ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterParenthesizedPattern() async {
    await computeSuggestions('''
void f(int o) {
  switch (o) {
    case (< 3 || > 7) ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterRecordPattern() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case (1, 2) ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterVariablePattern() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case var x ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_afterWhen_afterDeclaration() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case var x when ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_beforeColon_afterWhen_afterReference() async {
    await computeSuggestions('''
void f(Object o) {
  const x = 0;
  switch (o) {
    case x when ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_beforeColon_afterWildcard() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case var _ ^:
      return;
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }

  Future<void> test_beforeColon_empty() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case ^
  }
}
''');
    assertResponse('''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_beforeColon_noColonOrStatement() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case 'a' ^
  }
}
''');
    assertResponse('''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }
}
