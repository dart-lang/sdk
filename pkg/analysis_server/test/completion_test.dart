// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.completion;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/index/index.dart' show Index;
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';

main() {
  group('completion', () {
    runReflectiveTests(CompletionTest);
  });
}

@ReflectiveTestCase()
class CompletionTest extends AbstractAnalysisTest {
  String completionId;
  List<CompletionSuggestion> suggestions = [];
  bool suggestionsDone = false;

  void assertHasResult(String completion) {
    var cs = suggestions.firstWhere((cs) => cs.completion == completion, orElse: () {
      var completions = suggestions.map((s) => s.completion).toList();
      fail('expected "$completion" but found\n $completions');
    });
  }

  void assertValidId(String id) {
    expect(id, isNotNull);
    expect(id.isNotEmpty, isTrue);
  }

  @override
  Index createIndex() {
    return createLocalMemoryIndex();
  }

  Future getSuggestions(String pattern, int offsetFromPatternStart) {
    return waitForTasksFinished().then((_) {
      int offset = testCode.indexOf(pattern) + offsetFromPatternStart;
      Request request = new Request('0', COMPLETION_GET_SUGGESTIONS);
      request.setParameter(FILE, testFile);
      request.setParameter(OFFSET, offset);
      Response response = handleSuccessfulRequest(request);
      completionId = response.getResult(ID);
      assertValidId(completionId);
      return waitForSuggestions();
    });
  }

  void processNotification(Notification notification) {
    if (notification.event == COMPLETION_RESULTS) {
      String id = notification.getParameter(ID);
      assertValidId(id);
      if (id == completionId) {
        expect(suggestionsDone, isFalse);
        suggestionsDone = notification.getParameter(LAST);
        expect(suggestionsDone, isNotNull);
        for (Map<String, Object> json in notification.getParameter(RESULTS)) {
          expect(json, isNotNull);
          suggestions.add(new CompletionSuggestion.fromJson(json));
        }
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new CompletionDomainHandler(server);
  }

  Future waitForSuggestions() {
    if (suggestionsDone) {
      return new Future.value();
    }
    return new Future.delayed(Duration.ZERO, waitForSuggestions);
  }

  test_suggestions() {
    addTestFile('''
      import 'dart:html';
      main() {}
    ''');
    return getSuggestions('}', 0).then((_) {
      assertHasResult('Object');
      assertHasResult('HtmlElement');
    });
  }
}
