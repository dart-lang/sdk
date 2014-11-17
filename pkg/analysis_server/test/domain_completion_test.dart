// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.completion;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart' show Index;
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';
import 'reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionTest);
}

@ReflectiveTestCase()
class CompletionTest extends AbstractAnalysisTest {
  String completionId;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;

  String addTestFile(String content) {
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    return super.addTestFile(
        content.substring(0, completionOffset) +
            content.substring(completionOffset + 1));
  }

  void assertHasResult(CompletionSuggestionKind kind, String completion,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT, bool isDeprecated
      = false, bool isPotential = false]) {
    var cs;
    suggestions.forEach((s) {
      if (s.completion == completion) {
        if (cs == null) {
          cs = s;
        } else {
          fail('expected exactly one $completion but found > 1');
        }
      }
    });
    if (cs == null) {
      var completions = suggestions.map((s) => s.completion).toList();
      fail('expected "$completion" but found\n $completions');
    }
    expect(cs.kind, equals(kind));
    expect(cs.relevance, equals(relevance));
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
  }

  void assertNoResult(String completion) {
    if (suggestions.any((cs) => cs.completion == completion)) {
      fail('did not expect completion: $completion');
    }
  }

  void assertValidId(String id) {
    expect(id, isNotNull);
    expect(id.isNotEmpty, isTrue);
  }

  @override
  Index createIndex() {
    return createLocalMemoryIndex();
  }

  Future getSuggestions() {
    return waitForTasksFinished().then((_) {
      Request request =
          new CompletionGetSuggestionsParams(testFile, completionOffset).toRequest('0');
      Response response = handleSuccessfulRequest(request);
      completionId = response.id;
      assertValidId(completionId);
      return pumpEventQueue().then((_) {
        expect(suggestionsDone, isTrue);
      });
    });
  }

  void processNotification(Notification notification) {
    if (notification.event == COMPLETION_RESULTS) {
      var params = new CompletionResultsParams.fromNotification(notification);
      String id = params.id;
      assertValidId(id);
      if (id == completionId) {
        expect(suggestionsDone, isFalse);
        replacementOffset = params.replacementOffset;
        replacementLength = params.replacementLength;
        suggestionsDone = params.isLast;
        expect(suggestionsDone, isNotNull);
        suggestions = params.results;
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new CompletionDomainHandler(server);
  }

  test_html() {
    testFile = '/project/web/test.html';
    addTestFile('''
      <html>^</html>
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      expect(suggestions, hasLength(0));
    });
  }

  test_imports() {
    addTestFile('''
      import 'dart:html';
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'HtmlElement');
      assertNoResult('test');
    });
  }

  test_imports_prefixed() {
    addTestFile('''
      import 'dart:html' as foo;
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
      assertNoResult('HtmlElement');
      assertNoResult('test');
    });
  }

  test_invocation() {
    addTestFile('class A {b() {}} main() {A a; a.^}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  test_keyword() {
    addTestFile('library A; cl^');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 2));
      expect(replacementLength, equals(2));
      assertHasResult(
          CompletionSuggestionKind.KEYWORD,
          'import',
          CompletionRelevance.HIGH);
      assertHasResult(
          CompletionSuggestionKind.KEYWORD,
          'class',
          CompletionRelevance.HIGH);
    });
  }

  test_locals() {
    addTestFile('class A {var a; x() {var b;^}}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'A');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'a');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'x');
    });
  }

  test_topLevel() {
    addTestFile('''
      typedef foo();
      var test = '';
      main() {tes^t}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 3));
      expect(replacementLength, equals(4));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'test');
      assertNoResult('HtmlElement');
    });
  }
}
