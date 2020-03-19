// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticMemberRelevanceTest);
  });
}

@reflectiveTest
class StaticMemberRelevanceTest extends CompletionRelevanceTest {
  Future<void> test_contextType() async {
    await addTestFile(r'''
class A {}
class B extends A {}
class C extends B {}
class D {}

class E {
  static A a() {}
  static B b() {}
  static C c() {}
  static D d() {}
}

void f(B b) {}
void g() {
  f(E.^);
}
''');
    assertOrder([
      suggestionWith(completion: 'b'), // same
      suggestionWith(completion: 'c'), // subtype
      suggestionWith(completion: 'd'), // unrelated
      suggestionWith(completion: 'a'), // supertype
    ]);
  }

  Future<void> test_hasDeprecated() async {
    await addTestFile('''
class C {
  static void a() {}
  @deprecated
  static void b() {}
}

void f() {
  C.^
}
''');
    assertOrder([
      suggestionWith(completion: 'a'),
      suggestionWith(completion: 'b'),
    ]);
  }
}
