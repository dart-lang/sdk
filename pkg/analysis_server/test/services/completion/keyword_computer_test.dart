// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.keyword;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/keyword_computer.dart';
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

  test_after_class() {
    addTestSource('class A {} ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        ['abstract', 'class', 'const', 'final', 'typedef', 'var']);
  }

  test_before_import() {
    addTestSource('^ import foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(['export', 'import', 'library', 'part']);
  }

  test_class() {
    addTestSource('class A ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(['extends', 'implements']);
  }

  test_class_extends() {
    addTestSource('class A extends foo ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(['implements', 'with']);
  }

  test_class_extends_name() {
    addTestSource('class A extends ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_implements() {
    addTestSource('class A ^ implements foo');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(['extends']);
  }

  test_class_implements_name() {
    addTestSource('class A implements ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_name() {
    addTestSource('class ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_with_name() {
    addTestSource('class A extends foo with ^');
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

  test_library() {
    addTestSource('library foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            'abstract',
            'class',
            'const',
            'export',
            'final',
            'import',
            'part',
            'typedef',
            'var']);
  }

  test_library_name() {
    addTestSource('library ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_part_of() {
    addTestSource('part of foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            'abstract',
            'class',
            'const',
            'export',
            'final',
            'import',
            'part',
            'typedef',
            'var']);
  }

  test_partial_class() {
    addTestSource('cl^');
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

  test_partial_class2() {
    addTestSource('library a; cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            'abstract',
            'class',
            'const',
            'export',
            'final',
            'import',
            'part',
            'typedef',
            'var']);
  }
}
