// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.keyword;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/keyword_computer.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(KeywordComputerTest);
}

@ReflectiveTestCase()
class KeywordComputerTest extends AbstractCompletionTest {

  void assertSuggestKeywords(Iterable<Keyword> expectedKeywords,
      [CompletionRelevance relevance = CompletionRelevance.DEFAULT]) {
    Set<Keyword> actualKeywords = new Set<Keyword>();
    request.suggestions.forEach((CompletionSuggestion s) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        Keyword k = Keyword.keywords[s.completion];
        if (k == null) {
          fail('Invalid keyword suggested: ${s.completion}');
        } else {
          if (!actualKeywords.add(k)) {
            fail('Duplicate keyword suggested: ${s.completion}');
          }
        }
        expect(s.relevance, equals(relevance));
        expect(s.selectionOffset, equals(s.completion.length));
        expect(s.selectionLength, equals(0));
        expect(s.isDeprecated, equals(false));
        expect(s.isPotential, equals(false));
      }
    });
    if (expectedKeywords.any((k) => k is String)) {
      StringBuffer msg = new StringBuffer();
      msg.writeln('Expected set should be:');
      expectedKeywords.forEach((n) {
        Keyword k = Keyword.keywords[n];
        msg.writeln('  Keyword.${k.name},');
      });
      fail(msg.toString());
    }
    if (!_equalSets(expectedKeywords, actualKeywords)) {
      StringBuffer msg = new StringBuffer();
      msg.writeln('Expected:');
      _appendKeywords(msg, expectedKeywords);
      msg.writeln('but found:');
      _appendKeywords(msg, actualKeywords);
      fail(msg.toString());
    }
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
        [
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.FINAL,
            Keyword.TYPEDEF,
            Keyword.VAR],
        CompletionRelevance.HIGH);
  }

  test_before_import() {
    addTestSource('^ import foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXPORT, Keyword.IMPORT, Keyword.LIBRARY, Keyword.PART],
        CompletionRelevance.HIGH);
  }

  test_class() {
    addTestSource('class A ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS],
        CompletionRelevance.HIGH);
  }

  test_class_extends() {
    addTestSource('class A extends foo ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.IMPLEMENTS, Keyword.WITH],
        CompletionRelevance.HIGH);
  }

  test_class_extends_name() {
    addTestSource('class A extends ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_implements() {
    addTestSource('class A ^ implements foo');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.EXTENDS], CompletionRelevance.HIGH);
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
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.EXPORT,
            Keyword.FINAL,
            Keyword.IMPORT,
            Keyword.LIBRARY,
            Keyword.PART,
            Keyword.TYPEDEF,
            Keyword.VAR],
        CompletionRelevance.HIGH);
  }

  test_function_body() {
    addTestSource('main() {^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.ASSERT,
            Keyword.CASE,
            Keyword.CONTINUE,
            Keyword.DO,
            Keyword.FACTORY,
            Keyword.FINAL,
            Keyword.FOR,
            Keyword.IF,
            Keyword.NEW,
            Keyword.RETHROW,
            Keyword.RETURN,
            Keyword.SUPER,
            Keyword.SWITCH,
            Keyword.THIS,
            Keyword.THROW,
            Keyword.TRY,
            Keyword.VAR,
            Keyword.VOID,
            Keyword.WHILE]);
  }

  test_in_class() {
    addTestSource('class A {^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.CONST,
            Keyword.DYNAMIC,
            Keyword.FACTORY,
            Keyword.FINAL,
            Keyword.GET,
            Keyword.OPERATOR,
            Keyword.SET,
            Keyword.STATIC,
            Keyword.VAR,
            Keyword.VOID]);
  }

  test_library() {
    addTestSource('library foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.EXPORT,
            Keyword.FINAL,
            Keyword.IMPORT,
            Keyword.PART,
            Keyword.TYPEDEF,
            Keyword.VAR],
        CompletionRelevance.HIGH);
  }

  test_library_name() {
    addTestSource('library ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_method_body() {
    addTestSource('class A { foo() {^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.ASSERT,
            Keyword.CASE,
            Keyword.CONTINUE,
            Keyword.DO,
            Keyword.FACTORY,
            Keyword.FINAL,
            Keyword.FOR,
            Keyword.IF,
            Keyword.NEW,
            Keyword.RETHROW,
            Keyword.RETURN,
            Keyword.SUPER,
            Keyword.SWITCH,
            Keyword.THIS,
            Keyword.THROW,
            Keyword.TRY,
            Keyword.VAR,
            Keyword.VOID,
            Keyword.WHILE]);
  }

  test_named_constructor_invocation() {
    addTestSource('void main() {new Future.^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_part_of() {
    addTestSource('part of foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.EXPORT,
            Keyword.FINAL,
            Keyword.IMPORT,
            Keyword.PART,
            Keyword.TYPEDEF,
            Keyword.VAR],
        CompletionRelevance.HIGH);
  }

  test_partial_class() {
    addTestSource('cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.EXPORT,
            Keyword.FINAL,
            Keyword.IMPORT,
            Keyword.LIBRARY,
            Keyword.PART,
            Keyword.TYPEDEF,
            Keyword.VAR],
        CompletionRelevance.HIGH);
  }

  test_partial_class2() {
    addTestSource('library a; cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [
            Keyword.ABSTRACT,
            Keyword.CLASS,
            Keyword.CONST,
            Keyword.EXPORT,
            Keyword.FINAL,
            Keyword.IMPORT,
            Keyword.PART,
            Keyword.TYPEDEF,
            Keyword.VAR],
        CompletionRelevance.HIGH);
  }

  void _appendKeywords(StringBuffer msg, Iterable<Keyword> keywords) {
    List<Keyword> sorted = keywords.toList();
    sorted.sort((k1, k2) => k1.name.compareTo(k2.name));
    sorted.forEach((k) => msg.writeln('  Keyword.${k.name},'));
  }

  bool _equalSets(Iterable<Keyword> iter1, Iterable<Keyword> iter2) {
    if (iter1.length != iter2.length) return false;
    if (iter1.any((k) => !iter2.contains(k))) return false;
    if (iter2.any((k) => !iter1.contains(k))) return false;
    return true;
  }
}
