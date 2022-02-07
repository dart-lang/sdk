// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextTypeTest);
  });
}

@reflectiveTest
class ContextTypeTest extends AbstractSingleUnitTest {
  void assertSuggestion(CompletionSuggestion suggestion,
      {String? expectedDefaultArgumentList}) {
    if (expectedDefaultArgumentList != null) {
      var defaultArgumentList = suggestion.defaultArgumentListString!;
      expect(defaultArgumentList, expectedDefaultArgumentList);
    }
  }

  Future<CompletionSuggestion> forTopLevelFunction(String functionName) async {
    var request = DartCompletionRequest.forResolvedUnit(
      resolvedUnit: testAnalysisResult,
      offset: 0,
    );
    var builder = SuggestionBuilder(request);
    builder.suggestTopLevelFunction(findElement.topFunction('f'));
    var suggestions = builder.suggestions.map((e) => e.build()).toList();
    expect(suggestions, hasLength(1));
    return suggestions[0];
  }

  Future<void>
      test_topLevelFunction_functionTypedArgument_noParameterName() async {
    await resolveTestCode('''
void f(void Function(int) g) {}
''');
    var suggestion = await forTopLevelFunction('f');
    assertSuggestion(suggestion, expectedDefaultArgumentList: '(p0) { }');
  }

  Future<void>
      test_topLevelFunction_functionTypedArgument_potentialDuplication() async {
    await resolveTestCode('''
void f(void Function(int, int p0) g) {}
''');
    var suggestion = await forTopLevelFunction('f');
    assertSuggestion(suggestion, expectedDefaultArgumentList: '(p0_1, p0) { }');
  }
}
