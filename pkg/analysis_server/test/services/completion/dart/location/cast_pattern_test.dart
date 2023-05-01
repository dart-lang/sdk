// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternTest1);
    defineReflectiveTests(CastPatternTest2);
  });
}

@reflectiveTest
class CastPatternTest1 extends AbstractCompletionDriverTest
    with CastPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class CastPatternTest2 extends AbstractCompletionDriverTest
    with CastPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin CastPatternTestCases on AbstractCompletionDriverTest {
  Future<void> test_noType_afterDeclaration() async {
    await computeSuggestions('''
void f(Object x) {
  switch (x) {
    case var i as ^
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
''');
  }

  Future<void> test_noType_afterReference() async {
    await computeSuggestions('''
void f(Object x) {
  const i = 0;
  switch (x) {
    case i as ^
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
''');
  }

  Future<void> test_partialType_afterDeclaration() async {
    await computeSuggestions('''
void f(Object x) {
  switch (x) {
    case var i as A^
  }
}
class A01 {}
class A02 {}
class B01 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A02
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
''');
    }
  }

  Future<void> test_partialType_afterReference() async {
    await computeSuggestions('''
void f(Object x) {
  const i = 0;
  switch (x) {
    case i as A^
  }
}
class A01 {}
class A02 {}
class B01 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A02
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
''');
    }
  }
}
