// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessTest1);
    defineReflectiveTests(PropertyAccessTest2);
  });
}

@reflectiveTest
class PropertyAccessTest1 extends AbstractCompletionDriverTest
    with PropertyAccessTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class PropertyAccessTest2 extends AbstractCompletionDriverTest
    with PropertyAccessTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin PropertyAccessTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterGetter() async {
    await computeSuggestions('''
class A { int x; foo() {x.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterIdentifier() async {
    await computeSuggestions('''
class A { foo() {bar.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterIdentifier_partial() async {
    await computeSuggestions('''
class A { foo() {bar.as^}}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void> test_afterInstanceCreation() async {
    await computeSuggestions('''
class A { get x => 7; foo() {new A().^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLibraryPrefix() async {
    await computeSuggestions('''
import "b" as b; class A { foo() {b.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLocalVariable() async {
    await computeSuggestions('''
class A { foo() {int x; x.^}}
''');
    assertResponse(r'''
suggestions
''');
  }
}
