// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaringParameterTest);
  });
}

@reflectiveTest
class DeclaringParameterTest extends AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_insideFunction() async {
    await computeSuggestions('''
class C(var int f1) {
}

void f(C c) {
  print(c.^);
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
''');
  }

  Future<void> test_insideMember_sameClass() async {
    await computeSuggestions('''
class C(var int f1) {
  void m() {
    print(^);
  }
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
''');
  }

  Future<void> test_insideMember_subclass() async {
    await computeSuggestions('''
class A(var int f1) {}

class B extends A {
  new() : super(2);

  void m() {
    print(^);
  }
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
''');
  }
}
