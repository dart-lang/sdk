// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedTypeTest1);
    defineReflectiveTests(NamedTypeTest2);
  });
}

@reflectiveTest
class NamedTypeTest1 extends AbstractCompletionDriverTest
    with NamedTypeTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class NamedTypeTest2 extends AbstractCompletionDriverTest
    with NamedTypeTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin NamedTypeTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComment_beforeFunctionName_partial() async {
    await computeSuggestions('''
/// comment
 d^ foo() {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  dynamic
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftBrace_beforeIdentifier_syncStar_partial() async {
    await computeSuggestions('''
void f() sync* {n^ foo}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  assert
    kind: keyword
  await
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  late
    kind: keyword
  return
    kind: keyword
  switch
    kind: keyword
  throw
    kind: keyword
  try
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
  yield
    kind: keyword
  yield*
    kind: keyword
''');
    }
  }

  Future<void>
      test_afterLeftParen_beforeFunction_inConstructor_partial() async {
    await computeSuggestions('''
class A { A(v^ Function(){}) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftParen_beforeFunction_inMethod_partial() async {
    await computeSuggestions('''
class A { foo(v^ Function(){}) {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  void
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  void
    kind: keyword
''');
    }
  }
}
