// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberTest);
  });
}

@reflectiveTest
class InstanceMemberTest extends CompletionRelevanceTest
    with InstanceMemberTestCases {}

mixin InstanceMemberTestCases on CompletionRelevanceTest {
  Future<void> test_contextType_interfaceType_method() async {
    await addTestFile(r'''
class A {}
class B extends A {}
class C extends B {}
class D {}

class E {
  A a() {}
  B b() {}
  C c() {}
  D d() {}
}

void f(B b) {}
void g(E e) {
  f(e.^);
}
''');
    assertOrder([
      suggestionWith(completion: 'b'), // same
      suggestionWith(completion: 'c'), // subtype
      suggestionWith(completion: 'd'), // unrelated
      suggestionWith(completion: 'a'), // supertype
    ]);
  }

  Future<void> test_contextType_recordType_named() async {
    await addTestFile(r'''
class A {}
class B extends A {}
class C extends B {}
class D {}

void f(B _) {}

void g(({A foo01, B foo02, C foo03, D foo04}) r) {
  f(r.^);
}
''');
    assertOrder([
      suggestionWith(completion: r'foo02'), // same
      suggestionWith(completion: r'foo03'), // subtype
      suggestionWith(completion: r'foo04'), // unrelated
      suggestionWith(completion: r'foo01'), // supertype
    ]);
  }

  Future<void> test_contextType_recordType_positional() async {
    await addTestFile(r'''
class A {}
class B extends A {}
class C extends B {}
class D {}

void f(B _) {}

void g((A, B, C, D) r) {
  f(r.^);
}
''');
    assertOrder([
      suggestionWith(completion: r'$2'), // same
      suggestionWith(completion: r'$3'), // subtype
      suggestionWith(completion: r'$4'), // unrelated
      suggestionWith(completion: r'$1'), // supertype
    ]);
  }

  Future<void> test_elementKind() async {
    await addTestFile('''
class A {
  int get g => 0;
  void m() { }
  set s(int x) {}
}

void f(A a) {
  a.^
}
''');
    // The order below is dependent on generated data, so it can validly change
    // when the data is re-generated.
    // Getters, setters and fields now all have the same relevance.
    assertOrder([
      suggestionWith(completion: 'g'),
      //      suggestionWith(completion: 's'),
      suggestionWith(completion: 'm'),
    ]);
  }

  Future<void> test_hasDeprecated() async {
    await addTestFile('''
class C {
  void a() {}
  @deprecated
  void b() {}
}

void f(C c) {
  c.^
}
''');
    assertOrder([
      suggestionWith(completion: 'a'),
      suggestionWith(completion: 'b'),
    ]);
  }

  Future<void> test_inheritanceDepth() async {
    await addTestFile('''
class A {
  void a() { }
}

class B extends A {
  void b() { }
}

void f(B b) {
  b.^
}
''');
    assertOrder([
      suggestionWith(completion: 'b'),
      suggestionWith(completion: 'a'),
      suggestionWith(completion: 'toString'),
    ]);
  }

  Future<void> test_startsWithDollar() async {
    await addTestFile(r'''
class A {
  void a() { }
  void $b() { }
}

void f(A a) {
  a.^
}
''');
    assertOrder([
      suggestionWith(completion: 'a'),
      suggestionWith(completion: r'$b'),
    ]);
  }

  Future<void> test_superMatches() async {
    await addTestFile('''
class A {
  void a() { }
  void b() { }
}

class B extends A {
  void b() {
    super.^
  }
}
''');
    assertOrder([
      suggestionWith(completion: 'b'),
      suggestionWith(completion: 'a'),
    ]);
  }
}
