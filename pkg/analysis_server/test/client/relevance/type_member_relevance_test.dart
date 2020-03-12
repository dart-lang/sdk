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

  Future<void> test_type_member_relevance() async {
    await addTestFile('''
class A {
  void a() { }
}

class B extends A {
  void b() { }
}

void main() {
  var b = B();
  b.^
}
''');

    expect(
        suggestionWith(
                completion: 'b',
                element: ElementKind.METHOD,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance,
        greaterThan(suggestionWith(
                completion: 'a',
                element: ElementKind.METHOD,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance));
  }
}
