// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternTest1);
    defineReflectiveTests(RecordPatternTest2);
  });
}

@reflectiveTest
class RecordPatternTest1 extends AbstractCompletionDriverTest
    with RecordPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class RecordPatternTest2 extends AbstractCompletionDriverTest
    with RecordPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin RecordPatternTestCases on AbstractCompletionDriverTest {
  Future<void> test_assignmentContext_namedField_name() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  (^: ) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_assignmentContext_namedField_withName_pattern() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  int v01;
  (f01: ^) = x0;
}
''');
    // TODO(scheglov) This is wrong.
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  v01
    kind: localVariable
  var
    kind: keyword
  x0
    kind: parameter
''');
  }

  Future<void> test_declarationContext_namedField_name() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (^: ) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_declarationContext_namedField_name_partial() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (f^: ) = x0;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
    }
  }

  Future<void> test_declarationContext_namedField_withoutName_pattern() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (: ^) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  final
    kind: keyword
  g01
    kind: identifier
  var
    kind: keyword
''');
  }

  Future<void> test_empty() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case (^)
  }
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  dynamic
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

  Future<void> test_matchingContext_namedField_name() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (^: )) {}
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_name_afterField() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (f01: 0, ^: )) {}
}
''');
    assertResponse(r'''
suggestions
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_name_beforeField() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (^: , f01: 0)) {}
}
''');
    assertResponse(r'''
suggestions
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_name_partial() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (f^: )) {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
    }
  }

  Future<void> test_matchingContext_namedField_withoutName_pattern() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: ^)) {}
}
''');
    assertResponse(r'''
suggestions
  final
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void>
      test_matchingContext_namedField_withoutName_pattern_afterVar() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: var ^)) {}
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void>
      test_matchingContext_namedField_withoutName_pattern_afterVar_partial() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: var f^)) {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
    }
  }
}
