// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.keyword;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_contributor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(KeywordContributorTest);
    defineReflectiveTests(KeywordContributorTest_Driver);
  });
}

@reflectiveTest
class KeywordContributorTest extends DartCompletionContributorTest {
  static const List<Keyword> CLASS_BODY_KEYWORDS = const [
    Keyword.CONST,
    Keyword.DYNAMIC,
    Keyword.FACTORY,
    Keyword.FINAL,
    Keyword.GET,
    Keyword.OPERATOR,
    Keyword.SET,
    Keyword.STATIC,
    Keyword.VAR,
    Keyword.VOID
  ];

  static const List<Keyword> DECLARATION_KEYWORDS = const [
    Keyword.ABSTRACT,
    Keyword.CLASS,
    Keyword.CONST,
    Keyword.DYNAMIC,
    Keyword.FINAL,
    Keyword.TYPEDEF,
    Keyword.VAR,
    Keyword.VOID
  ];

  static const List<Keyword> DIRECTIVE_AND_DECLARATION_KEYWORDS = const [
    Keyword.ABSTRACT,
    Keyword.CLASS,
    Keyword.CONST,
    Keyword.DYNAMIC,
    Keyword.EXPORT,
    Keyword.FINAL,
    Keyword.IMPORT,
    Keyword.PART,
    Keyword.TYPEDEF,
    Keyword.VAR,
    Keyword.VOID
  ];

  static const List<Keyword> DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS =
      const [
    Keyword.ABSTRACT,
    Keyword.CLASS,
    Keyword.CONST,
    Keyword.DYNAMIC,
    Keyword.EXPORT,
    Keyword.FINAL,
    Keyword.IMPORT,
    Keyword.LIBRARY,
    Keyword.PART,
    Keyword.TYPEDEF,
    Keyword.VAR,
    Keyword.VOID
  ];

  static const List<String> NO_PSEUDO_KEYWORDS = const [];

  static const List<Keyword> STMT_START_IN_CLASS = const [
    Keyword.ASSERT,
    Keyword.CONST,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETURN,
    Keyword.SUPER,
    Keyword.SWITCH,
    Keyword.THIS,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  static const List<Keyword> STMT_START_IN_LOOP_IN_CLASS = const [
    Keyword.ASSERT,
    Keyword.BREAK,
    Keyword.CONST,
    Keyword.CONTINUE,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETURN,
    Keyword.SUPER,
    Keyword.SWITCH,
    Keyword.THIS,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  static const List<Keyword> STMT_START_IN_SWITCH_IN_CLASS = const [
    Keyword.ASSERT,
    Keyword.BREAK,
    Keyword.CASE,
    Keyword.CONST,
    Keyword.DEFAULT,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETURN,
    Keyword.SUPER,
    Keyword.SWITCH,
    Keyword.THIS,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  static const List<Keyword> STMT_START_IN_SWITCH_OUTSIDE_CLASS = const [
    Keyword.ASSERT,
    Keyword.BREAK,
    Keyword.CASE,
    Keyword.CONST,
    Keyword.DEFAULT,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETURN,
    Keyword.SWITCH,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  static const List<Keyword> STMT_START_OUTSIDE_CLASS = const [
    Keyword.ASSERT,
    Keyword.CONST,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETURN,
    Keyword.SWITCH,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  static const List<Keyword> STMT_START_IN_LOOP_OUTSIDE_CLASS = const [
    Keyword.ASSERT,
    Keyword.BREAK,
    Keyword.CONST,
    Keyword.CONTINUE,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETURN,
    Keyword.SWITCH,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  static const List<Keyword> EXPRESSION_START_INSTANCE = const [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.NEW,
    Keyword.NULL,
    Keyword.SUPER,
    Keyword.THIS,
    Keyword.TRUE,
  ];

  static const List<Keyword> EXPRESSION_START_NO_INSTANCE = const [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.NEW,
    Keyword.NULL,
    Keyword.TRUE,
  ];

  void assertSuggestKeywords(Iterable<Keyword> expectedKeywords,
      {List<String> pseudoKeywords: NO_PSEUDO_KEYWORDS,
      int relevance: DART_RELEVANCE_KEYWORD}) {
    Set<String> expectedCompletions = new Set<String>();
    Map<String, int> expectedOffsets = <String, int>{};
    Set<String> actualCompletions = new Set<String>();
    expectedCompletions.addAll(expectedKeywords.map((k) => k.syntax));
    ['import', 'export', 'part'].forEach((s) {
      if (expectedCompletions.contains(s)) {
        expectedCompletions.remove(s);
        expectedCompletions.add('$s \'\';');
      }
    });

    expectedCompletions.addAll(pseudoKeywords);
    for (CompletionSuggestion s in suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        Keyword k = Keyword.keywords[s.completion];
        if (k == null && !expectedCompletions.contains(s.completion)) {
          fail('Invalid keyword suggested: ${s.completion}');
        } else {
          if (!actualCompletions.add(s.completion)) {
            fail('Duplicate keyword suggested: ${s.completion}');
          }
        }
      }
    }
    if (!_equalSets(expectedCompletions, actualCompletions)) {
      StringBuffer msg = new StringBuffer();
      msg.writeln('Expected:');
      _appendCompletions(msg, expectedCompletions, actualCompletions);
      msg.writeln('but found:');
      _appendCompletions(msg, actualCompletions, expectedCompletions);
      fail(msg.toString());
    }
    for (CompletionSuggestion s in suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        if (s.completion.startsWith(Keyword.IMPORT.syntax)) {
          int importRelevance = relevance;
          expect(s.relevance, equals(importRelevance), reason: s.completion);
        } else {
          if (s.completion == Keyword.RETHROW.syntax) {
            expect(s.relevance, equals(relevance - 1), reason: s.completion);
          } else {
            expect(s.relevance, equals(relevance), reason: s.completion);
          }
        }
        int expectedOffset = expectedOffsets[s.completion];
        if (expectedOffset == null) {
          expectedOffset = s.completion.length;
        }
        expect(
            s.selectionOffset,
            equals(s.completion.endsWith('\'\';')
                ? expectedOffset - 2
                : expectedOffset));
        expect(s.selectionLength, equals(0));
        expect(s.isDeprecated, equals(false));
        expect(s.isPotential, equals(false));
      }
    }
  }

  @override
  DartCompletionContributor createContributor() {
    return new KeywordContributor();
  }

  fail_import_partial() async {
    addTestSource('imp^ import "package:foo/foo.dart"; import "bar.dart";');
    await computeSuggestions();
    // TODO(danrubel) should not suggest declaration keywords
    assertNotSuggested('class');
  }

  fail_import_partial4() async {
    addTestSource('^ imp import "package:foo/foo.dart";');
    await computeSuggestions();
    // TODO(danrubel) should not suggest declaration keywords
    assertNotSuggested('class');
  }

  fail_import_partial5() async {
    addTestSource('library libA; imp^ import "package:foo/foo.dart";');
    await computeSuggestions();
    // TODO(danrubel) should not suggest declaration keywords
    assertNotSuggested('class');
  }

  fail_import_partial6() async {
    addTestSource(
        'library bar; import "zoo.dart"; imp^ import "package:foo/foo.dart";');
    await computeSuggestions();
    // TODO(danrubel) should not suggest declaration keywords
    assertNotSuggested('class');
  }

  test_after_class() async {
    addTestSource('class A {} ^');
    await computeSuggestions();
    assertSuggestKeywords(DECLARATION_KEYWORDS, relevance: DART_RELEVANCE_HIGH);
  }

  test_after_class2() async {
    addTestSource('class A {} c^');
    await computeSuggestions();
    assertSuggestKeywords(DECLARATION_KEYWORDS, relevance: DART_RELEVANCE_HIGH);
  }

  test_after_import() async {
    addTestSource('import "foo"; ^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_after_import2() async {
    addTestSource('import "foo"; c^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_anonymous_function_async() async {
    addTestSource('main() {foo(() ^ {}}}');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_anonymous_function_async2() async {
    addTestSource('main() {foo(() a^ {}}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_anonymous_function_async3() async {
    addTestSource('main() {foo(() async ^ {}}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_anonymous_function_async4() async {
    addTestSource('main() {foo(() ^ => 2}}');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_anonymous_function_async5() async {
    addTestSource('main() {foo(() ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_anonymous_function_async6() async {
    addTestSource('main() {foo("bar", () as^{}}');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_anonymous_function_async7() async {
    addTestSource('main() {foo("bar", () as^ => null');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_argument() async {
    addTestSource('main() {foo(^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument2() async {
    addTestSource('main() {foo(n^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument_literal() async {
    addTestSource('main() {foo("^");}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_argument_named() async {
    addTestSource('main() {foo(bar: ^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument_named2() async {
    addTestSource('main() {foo(bar: n^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument_named_literal() async {
    addTestSource('main() {foo(bar: "^");}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_assignment_field() async {
    addTestSource('class A {var foo = ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_field2() async {
    addTestSource('class A {var foo = n^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_local() async {
    addTestSource('main() {var foo = ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_local2() async {
    addTestSource('main() {var foo = n^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_local2_async() async {
    addTestSource('main() async {var foo = n^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['await']);
  }

  test_assignment_local_async() async {
    addTestSource('main() async {var foo = ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['await']);
  }

  test_before_import() async {
    addTestSource('^ import foo;');
    await computeSuggestions();
    assertSuggestKeywords(
        [Keyword.EXPORT, Keyword.IMPORT, Keyword.LIBRARY, Keyword.PART],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_catch_1a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} ^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_1b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} c^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_1c() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} ^;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_1d() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} ^ Foo foo;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_2a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} on SomeException {} ^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_2b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} on SomeException {} c^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_2c() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} on SomeException {} ^;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_2d() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} on SomeException {} ^ Foo foo;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_3a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch (e) {} ^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_3b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch (e) {} c^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_3c() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} catch (e) {} ^;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_3d() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} catch (e) {} ^ Foo foo;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_4a1() async {
    // [CatchClause]  TryStatement  Block
    addTestSource('main() {try {} ^ on SomeException {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_4a2() async {
    // ['c' VariableDeclarationStatement]  Block  BlockFunctionBody
    addTestSource('main() {try {} c^ on SomeException {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    // TODO(danrubel) finally should not be suggested here
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_4b1() async {
    // [CatchClause]  TryStatement  Block
    addTestSource('main() {try {} ^ catch (e) {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_4b2() async {
    // ['c' ExpressionStatement]  Block  BlockFunctionBody
    addTestSource('main() {try {} c^ catch (e) {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    // TODO(danrubel) finally should not be suggested here
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_4c1() async {
    // ['finally']  TryStatement  Block
    addTestSource('main() {try {} ^ finally {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_4c2() async {
    // ['c' ExpressionStatement]  Block  BlockFunctionBody
    addTestSource('main() {try {} c^ finally {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    // TODO(danrubel) finally should not be suggested here
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  test_catch_block() async {
    // '}'  Block  CatchClause  TryStatement  Block
    addTestSource('main() {try {} catch (e) {^}}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.addAll(STMT_START_OUTSIDE_CLASS);
    keywords.add(Keyword.RETHROW);
    assertSuggestKeywords(keywords);
  }

  test_class() async {
    addTestSource('class A e^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_body() async {
    addTestSource('class A {^}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_body_beginning() async {
    addTestSource('class A {^ var foo;}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_body_between() async {
    addTestSource('class A {var bar; ^ var foo;}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_body_end() async {
    addTestSource('class A {var foo; ^}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_extends() async {
    addTestSource('class A extends foo ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_extends2() async {
    addTestSource('class A extends foo i^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_extends3() async {
    addTestSource('class A extends foo i^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_extends_name() async {
    addTestSource('class A extends ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_class_implements() async {
    addTestSource('class A ^ implements foo');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_implements2() async {
    addTestSource('class A e^ implements foo');
    await computeSuggestions();
    // TODO (danrubel) refinement: don't suggest implements
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_implements3() async {
    addTestSource('class A e^ implements foo { }');
    await computeSuggestions();
    // TODO (danrubel) refinement: don't suggest implements
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_implements_name() async {
    addTestSource('class A implements ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_class_name() async {
    addTestSource('class ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_class_noBody() async {
    addTestSource('class A ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_noBody2() async {
    addTestSource('class A e^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_noBody3() async {
    addTestSource('class A e^ String foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with() async {
    addTestSource('class A extends foo with bar ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with2() async {
    addTestSource('class A extends foo with bar i^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with3() async {
    addTestSource('class A extends foo with bar i^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with_name() async {
    addTestSource('class A extends foo with ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_constructor_param() async {
    addTestSource('class A { A(^) {});}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.THIS]);
  }

  test_constructor_param2() async {
    addTestSource('class A { A(t^) {});}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.THIS]);
  }

  test_do_break_continue() async {
    addTestSource('main() {do {^} while (true);}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_LOOP_OUTSIDE_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_do_break_continue2() async {
    addTestSource('class A {foo() {do {^} while (true);}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_LOOP_IN_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_empty() async {
    addTestSource('^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_for_break_continue() async {
    addTestSource('main() {for (int x in myList) {^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_LOOP_OUTSIDE_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_for_break_continue2() async {
    addTestSource('class A {foo() {for (int x in myList) {^}}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_LOOP_IN_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_for_expression_in() async {
    addTestSource('main() {for (int x i^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IN], relevance: DART_RELEVANCE_HIGH);
  }

  test_for_expression_in2() async {
    addTestSource('main() {for (int x in^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IN], relevance: DART_RELEVANCE_HIGH);
  }

  test_for_expression_in_inInitializer() async {
    addTestSource('main() {for (int i^)}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_for_expression_init() async {
    addTestSource('main() {for (int x = i^)}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_for_expression_init2() async {
    addTestSource('main() {for (int x = in^)}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_for_initialization_var() async {
    addTestSource('main() {for (^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.VAR], relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async() async {
    addTestSource('main()^');
    await computeSuggestions();
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async2() async {
    addTestSource('main()^{}');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async3() async {
    addTestSource('main()a^');
    await computeSuggestions();
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async4() async {
    addTestSource('main()a^{}');
    await computeSuggestions();
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async5() async {
    addTestSource('main()a^ Foo foo;');
    await computeSuggestions();
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_function_body_inClass_constructorInitializer() async {
    addTestSource(r'''
foo(p) {}
class A {
  final f;
  A() : f = foo(() {^});
}
''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inClass_constructorInitializer_async() async {
    addTestSource(r'''
foo(p) {}
class A {
  final f;
  A() : f = foo(() async {^});
}
''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS, pseudoKeywords: ['await']);
  }

  test_function_body_inClass_constructorInitializer_async_star() async {
    addTestSource(r'''
  foo(p) {}
  class A {
    final f;
    A() : f = foo(() async* {^});
  }
  ''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_function_body_inClass_field() async {
    addTestSource(r'''
class A {
  var f = () {^};
}
''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inClass_methodBody() async {
    addTestSource(r'''
class A {
  m() {
    f() {^};
  }
}
''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_function_body_inClass_methodBody_inFunction() async {
    addTestSource(r'''
class A {
  m() {
    f() {
      f2() {^};
    };
  }
}
''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_function_body_inClass_methodBody_inFunction_async() async {
    addTestSource(r'''
class A {
  m() {
    f() {
      f2() async {^};
    };
  }
}
''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS, pseudoKeywords: ['await']);
  }

  test_function_body_inClass_methodBody_inFunction_async_star() async {
    addTestSource(r'''
  class A {
    m() {
      f() {
        f2() async* {^};
      };
    }
  }
  ''');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_function_body_inUnit() async {
    addTestSource('main() {^}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inUnit_afterBlock() async {
    addTestSource('main() {{}^}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inUnit_async() async {
    addTestSource('main() async {^}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS, pseudoKeywords: ['await']);
  }

  test_function_body_inUnit_async_star() async {
    addTestSource('main() async* {n^}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_function_body_inUnit_async_star2() async {
    addTestSource('main() async* {n^ foo}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_function_body_inUnit_sync_star() async {
    addTestSource('main() sync* {n^}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_function_body_inUnit_sync_star2() async {
    addTestSource('main() sync* {n^ foo}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_if_after_else() async {
    addTestSource('main() { if (true) {} else ^ }');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_if_afterThen_nextCloseCurlyBrace0() async {
    addTestSource('main() { if (true) {} ^ }');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS.toList()..add(Keyword.ELSE),
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_if_afterThen_nextCloseCurlyBrace1() async {
    addTestSource('main() { if (true) {} e^ }');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS.toList()..add(Keyword.ELSE),
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_if_afterThen_nextStatement0() async {
    addTestSource('main() { if (true) {} ^ print(0); }');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS.toList()..add(Keyword.ELSE),
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_if_condition_isKeyword() async {
    addTestSource('main() { if (v i^) {} }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS], relevance: DART_RELEVANCE_HIGH);
  }

  test_if_condition_isKeyword2() async {
    addTestSource('main() { if (v i^ && false) {} }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS], relevance: DART_RELEVANCE_HIGH);
  }

  test_if_expression_in_class() async {
    addTestSource('class A {foo() {if (^) }}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_if_expression_in_class2() async {
    addTestSource('class A {foo() {if (n^) }}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_if_expression_in_function() async {
    addTestSource('foo() {if (^) }');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_if_expression_in_function2() async {
    addTestSource('foo() {if (n^) }');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_if_in_class() async {
    addTestSource('class A {foo() {if (true) ^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_in_class2() async {
    addTestSource('class A {foo() {if (true) ^;}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_in_class3() async {
    addTestSource('class A {foo() {if (true) r^;}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_in_class4() async {
    addTestSource('class A {foo() {if (true) ^ go();}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_outside_class() async {
    addTestSource('foo() {if (true) ^}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_if_outside_class2() async {
    addTestSource('foo() {if (true) ^;}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_if_outside_class3() async {
    addTestSource('foo() {if (true) r^;}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_if_outside_class4() async {
    addTestSource('foo() {if (true) ^ go();}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_import() async {
    addTestSource('import "foo" deferred as foo ^;');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['show', 'hide'], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_as() async {
    addTestSource('import "foo" deferred ^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_as2() async {
    addTestSource('import "foo" deferred a^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_as3() async {
    addTestSource('import "foo" deferred a^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred() async {
    addTestSource('import "foo" ^ as foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DEFERRED], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred2() async {
    addTestSource('import "foo" d^ as foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DEFERRED], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred3() async {
    addTestSource('import "foo" d^ show foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as'], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred4() async {
    addTestSource('import "foo" d^ hide foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as'], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred5() async {
    addTestSource('import "foo" d^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred6() async {
    addTestSource('import "foo" d^ import');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as() async {
    addTestSource('import "foo" ^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as2() async {
    addTestSource('import "foo" d^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as3() async {
    addTestSource('import "foo" ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as4() async {
    addTestSource('import "foo" d^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as5() async {
    addTestSource('import "foo" sh^ import "bar"; import "baz";');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_not() async {
    addTestSource('import "foo" as foo ^;');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['show', 'hide'], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_partial() async {
    addTestSource('import "package:foo/foo.dart" def^ as foo;');
    await computeSuggestions();
    expect(replacementOffset, 30);
    expect(replacementLength, 3);
    assertSuggestKeywords([Keyword.DEFERRED], relevance: DART_RELEVANCE_HIGH);
    expect(suggestions[0].selectionOffset, 8);
    expect(suggestions[0].selectionLength, 0);
  }

  test_import_incomplete() async {
    addTestSource('import "^"');
    await computeSuggestions();
    expect(suggestions, isEmpty);
  }

  test_import_partial() async {
    addTestSource('imp^ import "package:foo/foo.dart"; import "bar.dart";');
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_partial2() async {
    addTestSource('^imp import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_partial3() async {
    addTestSource(' ^imp import "package:foo/foo.dart"; import "bar.dart";');
    await computeSuggestions();
    expect(replacementOffset, 1);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_partial4() async {
    addTestSource('^ imp import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, 0);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_partial5() async {
    addTestSource('library libA; imp^ import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 14);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_partial6() async {
    addTestSource(
        'library bar; import "zoo.dart"; imp^ import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 32);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_is_expression() async {
    addTestSource('main() {if (x is^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS], relevance: DART_RELEVANCE_HIGH);
  }

  test_is_expression_partial() async {
    addTestSource('main() {if (x i^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS], relevance: DART_RELEVANCE_HIGH);
  }

  test_library() async {
    addTestSource('library foo;^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_library_declaration() async {
    addTestSource('library ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_library_declaration2() async {
    addTestSource('library a^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_library_declaration3() async {
    addTestSource('library a.^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_library_name() async {
    addTestSource('library ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_method_async() async {
    addTestSource('class A { foo() ^}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_method_async2() async {
    addTestSource('class A { foo() ^{}}');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async', 'async*', 'sync*'],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_method_async3() async {
    addTestSource('class A { foo() a^}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_method_async4() async {
    addTestSource('class A { foo() a^{}}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_method_async5() async {
    addTestSource('class A { foo() ^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_method_async6() async {
    addTestSource('class A { foo() a^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_method_async7() async {
    addTestSource('class A { foo() ^ => Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_method_async8() async {
    addTestSource('class A { foo() a^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(CLASS_BODY_KEYWORDS,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  test_method_body() async {
    addTestSource('class A { foo() {^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_method_body2() async {
    addTestSource('class A { foo() => ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body3() async {
    addTestSource('class A { foo() => ^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body4() async {
    addTestSource('class A { foo() => ^;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body_async() async {
    addTestSource('class A { foo() async {^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS, pseudoKeywords: ['await']);
  }

  test_method_body_async2() async {
    addTestSource('class A { foo() async => ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  test_method_body_async3() async {
    addTestSource('class A { foo() async => ^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  test_method_body_async4() async {
    addTestSource('class A { foo() async => ^;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  test_method_body_async_star() async {
    addTestSource('class A { foo() async* {^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_CLASS,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  test_method_body_expression1() async {
    addTestSource('class A { foo() {return b == true ? ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body_expression2() async {
    addTestSource('class A { foo() {return b == true ? 1 : ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body_return() async {
    addTestSource('class A { foo() {return ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_invocation() async {
    addTestSource('class A { foo() {bar.^}}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_method_invocation2() async {
    addTestSource('class A { foo() {bar.as^}}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_method_param() async {
    addTestSource('class A { foo(^) {});}');
    await computeSuggestions();
    expect(suggestions, isEmpty);
  }

  test_method_param2() async {
    addTestSource('class A { foo(t^) {});}');
    await computeSuggestions();
    expect(suggestions, isEmpty);
  }

  test_named_constructor_invocation() async {
    addTestSource('void main() {new Future.^}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_newInstance() async {
    addTestSource('class A { foo() {new ^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_newInstance2() async {
    addTestSource('class A { foo() {new ^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_newInstance_prefixed() async {
    addTestSource('class A { foo() {new A.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_newInstance_prefixed2() async {
    addTestSource('class A { foo() {new A.^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_part_of() async {
    addTestSource('part of foo;^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_partial_class() async {
    addTestSource('cl^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_partial_class2() async {
    addTestSource('library a; cl^');
    await computeSuggestions();
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_prefixed_field() async {
    addTestSource('class A { int x; foo() {x.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_prefixed_field2() async {
    addTestSource('class A { int x; foo() {x.^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_prefixed_library() async {
    addTestSource('import "b" as b; class A { foo() {b.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_prefixed_local() async {
    addTestSource('class A { foo() {int x; x.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_prefixed_local2() async {
    addTestSource('class A { foo() {int x; x.^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_property_access() async {
    addTestSource('class A { get x => 7; foo() {new A().^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  test_switch_expression() async {
    addTestSource('main() {switch(^) {}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_switch_expression2() async {
    addTestSource('main() {switch(n^) {}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_switch_expression3() async {
    addTestSource('main() {switch(n^)}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_switch_start() async {
    addTestSource('main() {switch(1) {^}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start2() async {
    addTestSource('main() {switch(1) {^ case 1:}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start3() async {
    addTestSource('main() {switch(1) {^default:}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start4() async {
    addTestSource('main() {switch(1) {^ default:}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start5() async {
    addTestSource('main() {switch(1) {c^ default:}}');
    await computeSuggestions();
    expect(replacementOffset, 19);
    expect(replacementLength, 1);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start6() async {
    addTestSource('main() {switch(1) {c^}}');
    await computeSuggestions();
    expect(replacementOffset, 19);
    expect(replacementLength, 1);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start7() async {
    addTestSource('main() {switch(1) { c^ }}');
    await computeSuggestions();
    expect(replacementOffset, 20);
    expect(replacementLength, 1);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_statement() async {
    addTestSource('main() {switch(1) {case 1:^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_SWITCH_OUTSIDE_CLASS);
  }

  test_switch_statement2() async {
    addTestSource('class A{foo() {switch(1) {case 1:^}}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_SWITCH_IN_CLASS);
  }

  test_while_break_continue() async {
    addTestSource('main() {while (true) {^}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_LOOP_OUTSIDE_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  test_while_break_continue2() async {
    addTestSource('class A {foo() {while (true) {^}}}');
    await computeSuggestions();
    assertSuggestKeywords(STMT_START_IN_LOOP_IN_CLASS,
        relevance: DART_RELEVANCE_KEYWORD);
  }

  void _appendCompletions(
      StringBuffer msg, Iterable<String> completions, Iterable<String> other) {
    List<String> sorted = completions.toList();
    sorted.sort((c1, c2) => c1.compareTo(c2));
    sorted.forEach(
        (c) => msg.writeln('  $c, ${other.contains(c) ? '' : '<<<<<<<<<<<'}'));
  }

  bool _equalSets(Iterable<String> iter1, Iterable<String> iter2) {
    if (iter1.length != iter2.length) return false;
    if (iter1.any((c) => !iter2.contains(c))) return false;
    if (iter2.any((c) => !iter1.contains(c))) return false;
    return true;
  }
}

@reflectiveTest
class KeywordContributorTest_Driver extends KeywordContributorTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
