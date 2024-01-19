// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchPatternCaseTest);
  });
}

@reflectiveTest
class SwitchPatternCaseTest extends AbstractCompletionDriverTest
    with SwitchPatternCaseTestCases {}

mixin SwitchPatternCaseTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCase() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case ^
  }
}

class A01 {}
''');
    // TODO(brianwilkerson): Decide whether we should suggest a constructor
    //  (with parens around it) or an object pattern, or both.
    assertResponse(r'''
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterCase_partial() async {
    await computeSuggestions('''
void f(Object x) {
  switch (x) {
    case tr^
  }
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  true
    kind: keyword
''');
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
    assertResponse(r'''
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  assert
    kind: keyword
  break
    kind: keyword
  case
    kind: keyword
  const
    kind: keyword
  default:
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  true
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

  Future<void> test_afterFinal() async {
    await computeSuggestions('''
void f(Object x) {
  switch (x) {
    case final ^
  }
}
class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterVar() async {
    await computeSuggestions('''
void f(Object x) {
  switch (x) {
    case var ^
  }
}
class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
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
class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
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
class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
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
    assertResponse(r'''
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
    assertResponse(r'''
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
    assertResponse(r'''
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
    assertResponse(r'''
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
    assertResponse(r'''
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
    assertResponse(r'''
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
    assertResponse(r'''
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
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
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
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
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
    assertResponse(r'''
suggestions
  as
    kind: keyword
  when
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
    assertResponse(r'''
suggestions
  as
    kind: keyword
  when
    kind: keyword
''');
  }
}
