// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.keyword;

import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/src/completion/keyword_computer.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(KeywordComputerTest);
}

@ReflectiveTestCase()
class KeywordComputerTest extends AbstractCompletionTest {

  void assertSuggestKeywords(List<String> names) {
    Keyword.values.forEach((Keyword keyword) {
      if (names.contains(keyword.syntax)) {
        assertSuggest(CompletionSuggestionKind.KEYWORD, keyword.syntax);
      } else {
        assertNotSuggested(keyword.syntax);
      }
    });
  }

  @override
  void setUp() {
    super.setUp();
    computer = new KeywordComputer();
  }

  test_class_extends() {
    addTestSource('class A ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(['extends', 'implements', 'with']);
  }

  test_class_extends_name() {
    addTestSource('class A extends ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_name() {
    addTestSource('class ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_empty() {
    addTestSource('^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            'abstract',
            'class',
            'const',
            'export',
            'final',
            'import',
            'library',
            'part',
            'typedef',
            'var']);
  }
}
