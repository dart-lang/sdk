// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeMemberRelevanceTest);
  });
}

@reflectiveTest
class TypeMemberRelevanceTest extends AbstractCompletionDriverTest {
  @override
  AnalysisServerOptions get serverOptions =>
      AnalysisServerOptions()..useNewRelevance = true;

  @override
  bool get supportsAvailableSuggestions => true;

  /// Assert that all of the given completions were produces and that the
  /// suggestions are ordered in decreasing order based on relevance scores.
  void assertOrder(List<CompletionSuggestion> suggestions) {
    var length = suggestions.length;
    expect(length, greaterThan(1),
        reason: 'Test must specify more than one suggestion');
    var previous = suggestions[0];
    for (int i = 1; i < length; i++) {
      var current = suggestions[i];
      expect(current.relevance, lessThan(previous.relevance));
      previous = current;
    }
  }

  Future<void> test_contextType() async {
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
      suggestionWith(completion: 'hashCode'),
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
