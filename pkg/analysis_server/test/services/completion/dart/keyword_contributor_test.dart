// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_contributor.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';
import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(KeywordContributorTest);
    defineReflectiveTests(KeywordContributorWithNullSafetyTest);
  });
}

@reflectiveTest
class KeywordContributorTest extends DartCompletionContributorTest {
  static const List<Keyword> COLLECTION_ELEMENT_START = [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NULL,
    Keyword.TRUE,
  ];

  static const List<String> NO_PSEUDO_KEYWORDS = [];

  static const List<Keyword> EXPRESSION_START_INSTANCE = [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.NULL,
    Keyword.SUPER,
    Keyword.THIS,
    Keyword.TRUE,
  ];

  static const List<Keyword> EXPRESSION_START_NO_INSTANCE = [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.NULL,
    Keyword.TRUE,
  ];

  List<Keyword> get classBodyKeywords {
    var keywords = <Keyword>[
      Keyword.CONST,
      Keyword.COVARIANT,
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
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get constructorParameter {
    var keywords = <Keyword>[
      Keyword.COVARIANT,
      Keyword.DYNAMIC,
      Keyword.THIS,
      Keyword.DYNAMIC,
      Keyword.VOID
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.REQUIRED);
    }
    return keywords;
  }

  List<Keyword> get declarationKeywords {
    var keywords = <Keyword>[
      Keyword.ABSTRACT,
      Keyword.CLASS,
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.DYNAMIC,
      Keyword.EXTENSION,
      Keyword.FINAL,
      Keyword.TYPEDEF,
      Keyword.VAR,
      Keyword.VOID
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get directiveAndDeclarationKeywords {
    var keywords = <Keyword>[
      Keyword.ABSTRACT,
      Keyword.CLASS,
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.DYNAMIC,
      Keyword.EXPORT,
      Keyword.EXTENSION,
      Keyword.FINAL,
      Keyword.IMPORT,
      Keyword.PART,
      Keyword.TYPEDEF,
      Keyword.VAR,
      Keyword.VOID
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get directiveDeclarationAndLibraryKeywords {
    var keywords = directiveDeclarationKeywords..add(Keyword.LIBRARY);
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get directiveDeclarationKeywords {
    var keywords = <Keyword>[
      Keyword.ABSTRACT,
      Keyword.CLASS,
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.DYNAMIC,
      Keyword.EXPORT,
      Keyword.EXTENSION,
      Keyword.FINAL,
      Keyword.IMPORT,
      Keyword.PART,
      Keyword.TYPEDEF,
      Keyword.VAR,
      Keyword.VOID
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get extensionBodyKeywords {
    var keywords = [
      Keyword.CONST,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.GET,
      Keyword.OPERATOR,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.VAR,
      Keyword.VOID
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get methodParameter {
    var keywords = <Keyword>[Keyword.COVARIANT, Keyword.DYNAMIC, Keyword.VOID];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.REQUIRED);
    }
    return keywords;
  }

  List<Keyword> get statementStartInClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.CONST,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
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
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartInLoopInClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.BREAK,
      Keyword.CONST,
      Keyword.CONTINUE,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
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
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartInLoopOutsideClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.BREAK,
      Keyword.CONST,
      Keyword.CONTINUE,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartInSwitchCaseInClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.BREAK,
      Keyword.CONST,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.RETURN,
      Keyword.SUPER,
      Keyword.THIS,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartInSwitchCaseOutsideClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.BREAK,
      Keyword.CONST,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartInSwitchInClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.BREAK,
      Keyword.CASE,
      Keyword.CONST,
      Keyword.DEFAULT,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
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
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartInSwitchOutsideClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.BREAK,
      Keyword.CASE,
      Keyword.CONST,
      Keyword.DEFAULT,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get statementStartOutsideClass {
    var keywords = <Keyword>[
      Keyword.ASSERT,
      Keyword.CONST,
      Keyword.DO,
      Keyword.DYNAMIC,
      Keyword.FINAL,
      Keyword.FOR,
      Keyword.IF,
      Keyword.RETURN,
      Keyword.SWITCH,
      Keyword.THROW,
      Keyword.TRY,
      Keyword.VAR,
      Keyword.VOID,
      Keyword.WHILE
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  List<Keyword> get staticMember {
    var keywords = <Keyword>[
      Keyword.ABSTRACT,
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.EXTERNAL,
      Keyword.FINAL
    ];
    if (isEnabled(ExperimentalFeatures.non_nullable)) {
      keywords.add(Keyword.LATE);
    }
    return keywords;
  }

  void assertSuggestKeywords(Iterable<Keyword> expectedKeywords,
      {List<String> pseudoKeywords = NO_PSEUDO_KEYWORDS}) {
    var expectedCompletions = <String>{};
    var expectedOffsets = <String, int>{};
    var actualCompletions = <String>{};
    expectedCompletions.addAll(expectedKeywords.map((keyword) {
      var text = keyword.lexeme;
      if (['import', 'export', 'part'].contains(text)) {
        return '$text \'\';';
      } else if (text == 'default') {
        return '$text:';
      }
      return text;
    }));

    expectedCompletions.addAll(pseudoKeywords);
    for (var s in suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        var k = Keyword.keywords[s.completion];
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
      var msg = StringBuffer();
      msg.writeln('Expected:');
      _appendCompletions(msg, expectedCompletions, actualCompletions);
      msg.writeln('but found:');
      _appendCompletions(msg, actualCompletions, expectedCompletions);
      fail(msg.toString());
    }
    for (var s in suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        var expectedOffset = expectedOffsets[s.completion];
        expectedOffset ??= s.completion.length;
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
    return KeywordContributor();
  }

  /// Return `true` if the given [feature] is enabled.
  bool isEnabled(Feature feature) =>
      result.libraryElement.featureSet.isEnabled(feature);

  Future<void> test_after_class_noPrefix() async {
    addTestSource('class A {} ^');
    await computeSuggestions();
    assertSuggestKeywords(declarationKeywords);
  }

  Future<void> test_after_class_prefix() async {
    addTestSource('class A {} c^');
    await computeSuggestions();
    assertSuggestKeywords(declarationKeywords);
  }

  Future<void> test_after_import_noPrefix() async {
    addTestSource('import "foo"; ^');
    await computeSuggestions();
    assertSuggestKeywords(directiveAndDeclarationKeywords);
  }

  Future<void> test_after_import_prefix() async {
    addTestSource('import "foo"; c^');
    await computeSuggestions();
    assertSuggestKeywords(directiveAndDeclarationKeywords);
  }

  Future<void> test_anonymous_function_async() async {
    addTestSource('main() {foo(() ^ {}}}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_anonymous_function_async2() async {
    addTestSource('main() {foo(() a^ {}}}');
    await computeSuggestions();
    // Fasta adds a closing paren after the first `}`
    // and reports a single function expression argument
    // while analyzer adds the closing paren before the `a`
    // and adds synthetic `;`s making `a` a statement.
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_anonymous_function_async3() async {
    addTestSource('main() {foo(() async ^ {}}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_anonymous_function_async4() async {
    addTestSource('main() {foo(() ^ => 2}}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async']);
  }

  Future<void> test_anonymous_function_async5() async {
    addTestSource('main() {foo(() ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_anonymous_function_async6() async {
    addTestSource('main() {foo("bar", () as^{}}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_anonymous_function_async7() async {
    addTestSource('main() {foo("bar", () as^ => null');
    await computeSuggestions();
    assertSuggestKeywords([],
        pseudoKeywords:
            usingFastaParser ? ['async'] : ['async', 'async*', 'sync*']);
  }

  Future<void> test_anonymous_function_async8() async {
    addTestSource('main() {foo(() ^ {})}}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_anonymous_function_async9() async {
    addTestSource('main() {foo(() a^ {})}}');
    await computeSuggestions();
    // Fasta interprets the argument as a function expression
    // while analyzer adds synthetic `;`s making `a` a statement.
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_argument() async {
    addTestSource('main() {foo(^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_argument2() async {
    addTestSource('main() {foo(n^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_argument_literal() async {
    addTestSource('main() {foo("^");}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_argument_named() async {
    addTestSource('main() {foo(bar: ^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_argument_named2() async {
    addTestSource('main() {foo(bar: n^);}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_argument_named_literal() async {
    addTestSource('main() {foo(bar: "^");}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_assignment_field() async {
    addTestSource('class A {var foo = ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_assignment_field2() async {
    addTestSource('class A {var foo = n^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_assignment_local() async {
    addTestSource('main() {var foo = ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_assignment_local2() async {
    addTestSource('main() {var foo = n^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_assignment_local2_async() async {
    addTestSource('main() async {var foo = n^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['await']);
  }

  Future<void> test_assignment_local_async() async {
    addTestSource('main() async {var foo = ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['await']);
  }

  Future<void> test_before_import() async {
    addTestSource('^ import foo;');
    await computeSuggestions();
    assertSuggestKeywords(
        [Keyword.EXPORT, Keyword.IMPORT, Keyword.LIBRARY, Keyword.PART]);
  }

  Future<void> test_catch_1a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} ^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_1b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} c^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_1c() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} ^;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_1d() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} ^ Foo foo;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_2a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} on SomeException {} ^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_2b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} on SomeException {} c^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_2c() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} on SomeException {} ^;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_2d() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} on SomeException {} ^ Foo foo;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_3a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch (e) {} ^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_3b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch (e) {} c^}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_3c() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} catch (e) {} ^;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_3d() async {
    // [EmptyStatement] Block BlockFunction FunctionExpression
    addTestSource('main() {try {} catch (e) {} ^ Foo foo;}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    keywords.add(Keyword.FINALLY);
    keywords.addAll(statementStartOutsideClass);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_4a1() async {
    // [CatchClause]  TryStatement  Block
    addTestSource('main() {try {} ^ on SomeException {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_4a2() async {
    // ['c' VariableDeclarationStatement]  Block  BlockFunctionBody
    addTestSource('main() {try {} c^ on SomeException {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    // TODO(danrubel) finally should not be suggested here
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_4b1() async {
    // [CatchClause]  TryStatement  Block
    addTestSource('main() {try {} ^ catch (e) {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_4b2() async {
    // ['c' ExpressionStatement]  Block  BlockFunctionBody
    addTestSource('main() {try {} c^ catch (e) {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    // TODO(danrubel) finally should not be suggested here
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_4c1() async {
    // ['finally']  TryStatement  Block
    addTestSource('main() {try {} ^ finally {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_4c2() async {
    // ['c' ExpressionStatement]  Block  BlockFunctionBody
    addTestSource('main() {try {} c^ finally {}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.add(Keyword.CATCH);
    // TODO(danrubel) finally should not be suggested here
    keywords.add(Keyword.FINALLY);
    assertSuggestKeywords(keywords, pseudoKeywords: ['on']);
  }

  Future<void> test_catch_block() async {
    // '}'  Block  CatchClause  TryStatement  Block
    addTestSource('main() {try {} catch (e) {^}}}');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.addAll(statementStartOutsideClass);
    keywords.add(Keyword.RETHROW);
    assertSuggestKeywords(keywords);
  }

  Future<void> test_class() async {
    addTestSource('class A e^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_body() async {
    addTestSource('class A {^}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_body_beginning() async {
    addTestSource('class A {^ var foo;}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_body_between() async {
    addTestSource('class A {var bar; ^ var foo;}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_body_empty() async {
    addTestSource('extension E on int {^}');
    await computeSuggestions();
    assertSuggestKeywords(extensionBodyKeywords);
  }

  Future<void> test_class_body_end() async {
    addTestSource('class A {var foo; ^}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_body_return_no_whitespace() async {
    addTestSource('class A { ^foo() {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_body_return_prefix() async {
    addTestSource('class A { d^ foo() {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_body_return_whitespace() async {
    addTestSource('class A { ^ foo() {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_class_extends() async {
    addTestSource('class A extends foo ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH]);
  }

  Future<void> test_class_extends2() async {
    addTestSource('class A extends foo i^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH]);
  }

  Future<void> test_class_extends3() async {
    addTestSource('class A extends foo i^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH]);
  }

  Future<void> test_class_extends_name() async {
    addTestSource('class A extends ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_class_implements() async {
    addTestSource('class A ^ implements foo');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS]);
  }

  Future<void> test_class_implements2() async {
    addTestSource('class A e^ implements foo');
    await computeSuggestions();
    assertSuggestKeywords(usingFastaParser
        ? [Keyword.EXTENDS]
        : [Keyword.EXTENDS, Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_implements3() async {
    addTestSource('class A e^ implements foo { }');
    await computeSuggestions();
    assertSuggestKeywords(usingFastaParser
        ? [Keyword.EXTENDS]
        : [Keyword.EXTENDS, Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_implements_name() async {
    addTestSource('class A implements ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_class_member_const_afterStatic() async {
    addTestSource('''
class C {
  static c^
}
''');
    await computeSuggestions();
    assertSuggestKeywords(staticMember);
  }

  Future<void> test_class_member_final_afterStatic() async {
    addTestSource('''
class C {
  static f^
}
''');
    await computeSuggestions();
    assertSuggestKeywords(staticMember);
  }

  Future<void> test_class_name() async {
    addTestSource('class ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_class_noBody() async {
    addTestSource('class A ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_noBody2() async {
    addTestSource('class A e^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_noBody3() async {
    addTestSource('class A e^ String foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_with() async {
    addTestSource('class A extends foo with bar ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_with2() async {
    addTestSource('class A extends foo with bar i^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_with3() async {
    addTestSource('class A extends foo with bar i^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS]);
  }

  Future<void> test_class_with_name() async {
    addTestSource('class A extends foo with ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_constructor_initializers_first() async {
    addTestSource('class A { int f; A() : ^, f = 1; }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.ASSERT]);
  }

  Future<void> test_constructor_initializers_last() async {
    addTestSource('class A { A() : ^; }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.ASSERT, Keyword.SUPER, Keyword.THIS]);
  }

  Future<void> test_constructor_param_noPrefix() async {
    addTestSource('class A { A(^) {}}');
    await computeSuggestions();
    assertSuggestKeywords(constructorParameter);
  }

  Future<void> test_constructor_param_noPrefix_func_parameter() async {
    addTestSource('class A { A(^ Function(){}) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(constructorParameter);
  }

  Future<void> test_constructor_param_prefix() async {
    addTestSource('class A { A(t^) {}}');
    await computeSuggestions();
    assertSuggestKeywords(constructorParameter);
  }

  Future<void> test_constructor_param_prefix_func_parameter() async {
    addTestSource('class A { A(v^ Function(){}) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(constructorParameter);
  }

  Future<void> test_do_break_continue_insideClass() async {
    addTestSource('class A {foo() {do {^} while (true);}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInLoopInClass);
  }

  Future<void> test_do_break_continue_outsideClass() async {
    addTestSource('main() {do {^} while (true);}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInLoopOutsideClass);
  }

  Future<void> test_empty() async {
    addTestSource('^');
    await computeSuggestions();
    assertSuggestKeywords(directiveDeclarationAndLibraryKeywords);
  }

  Future<void> test_extension_body_beginning() async {
    addTestSource('extension E on int {^ foo() {}}');
    await computeSuggestions();
    assertSuggestKeywords(extensionBodyKeywords);
  }

  Future<void> test_extension_body_between() async {
    addTestSource('extension E on int {foo() {} ^ void bar() {}}');
    await computeSuggestions();
    assertSuggestKeywords(extensionBodyKeywords);
  }

  Future<void> test_extension_body_end() async {
    addTestSource('extension E on int {foo() {} ^}');
    await computeSuggestions();
    assertSuggestKeywords(extensionBodyKeywords);
  }

  Future<void> test_extension_member_const_afterStatic() async {
    addTestSource('''
extension E on int {
  static c^
}
''');
    await computeSuggestions();
    assertSuggestKeywords(staticMember);
  }

  Future<void> test_extension_member_final_afterStatic() async {
    addTestSource('''
extension E on int {
  static f^
}
''');
    await computeSuggestions();
    assertSuggestKeywords(staticMember);
  }

  Future<void> test_extension_noBody_named() async {
    addTestSource('extension E ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.ON]);
  }

  Future<void> test_extension_noBody_unnamed() async {
    addTestSource('extension ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.ON]);
  }

  Future<void> test_for_break_continue_insideClass() async {
    addTestSource('class A {foo() {for (int x in myList) {^}}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInLoopInClass);
  }

  Future<void> test_for_break_continue_outsideClass() async {
    addTestSource('main() {for (int x in myList) {^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInLoopOutsideClass);
  }

  Future<void> test_for_expression_in() async {
    addTestSource('main() {for (int x i^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IN]);
  }

  Future<void> test_for_expression_in2() async {
    addTestSource('main() {for (int x in^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IN]);
  }

  Future<void> test_for_expression_in_inInitializer() async {
    addTestSource('main() {for (int i^)}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_for_expression_init() async {
    addTestSource('main() {for (int x = i^)}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_for_expression_init2() async {
    addTestSource('main() {for (int x = in^)}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_for_initialization_var() async {
    addTestSource('main() {for (^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.VAR]);
  }

  Future<void> test_function_async() async {
    addTestSource('main()^');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_function_async2() async {
    addTestSource('main()^{}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_function_async3() async {
    addTestSource('main()a^');
    await computeSuggestions();
    assertSuggestKeywords(declarationKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_function_async4() async {
    addTestSource('main()a^{}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_function_async5() async {
    addTestSource('main()a^ Foo foo;');
    await computeSuggestions();
    assertSuggestKeywords(declarationKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_function_body_inClass_constructorInitializer() async {
    addTestSource(r'''
foo(p) {}
class A {
  final f;
  A() : f = foo(() {^});
}
''');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_function_body_inClass_constructorInitializer_async() async {
    addTestSource(r'''
foo(p) {}
class A {
  final f;
  A() : f = foo(() async {^});
}
''');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await']);
  }

  Future<void>
      test_function_body_inClass_constructorInitializer_async_star() async {
    addTestSource(r'''
  foo(p) {}
  class A {
    final f;
    A() : f = foo(() async* {^});
  }
  ''');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_function_body_inClass_field() async {
    addTestSource(r'''
class A {
  var f = () {^};
}
''');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_function_body_inClass_methodBody() async {
    addTestSource(r'''
class A {
  m() {
    f() {^};
  }
}
''');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_function_body_inClass_methodBody_inFunction() async {
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
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_function_body_inClass_methodBody_inFunction_async() async {
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
    assertSuggestKeywords(statementStartInClass, pseudoKeywords: ['await']);
  }

  Future<void>
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
    assertSuggestKeywords(statementStartInClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_function_body_inUnit() async {
    addTestSource('main() {^}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_function_body_inUnit_afterBlock() async {
    addTestSource('main() {{}^}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_function_body_inUnit_async() async {
    addTestSource('main() async {^}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await']);
  }

  Future<void> test_function_body_inUnit_async_star() async {
    addTestSource('main() async* {n^}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_function_body_inUnit_async_star2() async {
    addTestSource('main() async* {n^ foo}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_function_body_inUnit_return_with_header() async {
    addTestSource('/// comment\n ^ foo() {}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DYNAMIC, Keyword.VOID]);
  }

  Future<void> test_function_body_inUnit_return_with_header_prefix() async {
    addTestSource('/// comment\n d^ foo() {}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DYNAMIC, Keyword.VOID]);
  }

  Future<void> test_function_body_inUnit_sync_star() async {
    addTestSource('main() sync* {n^}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_function_body_inUnit_sync_star2() async {
    addTestSource('main() sync* {n^ foo}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_if_after_else() async {
    addTestSource('main() { if (true) {} else ^ }');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_if_afterThen_nextCloseCurlyBrace0() async {
    addTestSource('main() { if (true) {} ^ }');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.addAll(statementStartOutsideClass);
    keywords.add(Keyword.ELSE);
    assertSuggestKeywords(keywords);
  }

  Future<void> test_if_afterThen_nextCloseCurlyBrace1() async {
    addTestSource('main() { if (true) {} e^ }');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.addAll(statementStartOutsideClass);
    keywords.add(Keyword.ELSE);
    assertSuggestKeywords(keywords);
  }

  Future<void> test_if_afterThen_nextStatement0() async {
    addTestSource('main() { if (true) {} ^ print(0); }');
    await computeSuggestions();
    var keywords = <Keyword>[];
    keywords.addAll(statementStartOutsideClass);
    keywords.add(Keyword.ELSE);
    assertSuggestKeywords(keywords);
  }

  Future<void> test_if_condition_isKeyword() async {
    addTestSource('main() { if (v i^) {} }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS]);
  }

  Future<void> test_if_condition_isKeyword2() async {
    addTestSource('main() { if (v i^ && false) {} }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS]);
  }

  Future<void> test_if_expression_in_class() async {
    addTestSource('class A {foo() {if (^) }}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_if_expression_in_class2() async {
    addTestSource('class A {foo() {if (n^) }}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_if_expression_in_function() async {
    addTestSource('foo() {if (^) }');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_if_expression_in_function2() async {
    addTestSource('foo() {if (n^) }');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_if_in_class() async {
    addTestSource('class A {foo() {if (true) ^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_if_in_class2() async {
    addTestSource('class A {foo() {if (true) ^;}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_if_in_class3() async {
    addTestSource('class A {foo() {if (true) r^;}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_if_in_class4() async {
    addTestSource('class A {foo() {if (true) ^ go();}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_if_outside_class() async {
    addTestSource('foo() {if (true) ^}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_if_outside_class2() async {
    addTestSource('foo() {if (true) ^;}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_if_outside_class3() async {
    addTestSource('foo() {if (true) r^;}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_if_outside_class4() async {
    addTestSource('foo() {if (true) ^ go();}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartOutsideClass);
  }

  Future<void> test_ifOrForElement_forElement() async {
    addTestSource('''
f() => [for (var e in c) ^];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_ifElement_else() async {
    addTestSource('''
f() => [if (true) 1 else ^];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_ifElement_then() async {
    addTestSource('''
f() => [if (true) ^];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_list_empty() async {
    addTestSource('''
f() => [^];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_list_first() async {
    addTestSource('''
f() => [^1, 2];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_list_last() async {
    addTestSource('''
f() => [1, 2, ^];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_list_middle() async {
    addTestSource('''
f() => [1, ^, 2];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_map_empty() async {
    addTestSource('''
f() => <String, int>{^};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_map_first() async {
    addTestSource('''
f() => <String, int>{^'a' : 1};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_map_last() async {
    addTestSource('''
f() => <String, int>{'a' : 1, 'b' : 2, ^};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_map_middle() async {
    addTestSource('''
f() => <String, int>{'a' : 1, ^, 'b' : 2];
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_set_empty() async {
    addTestSource('''
f() => <int>{^};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_set_first() async {
    addTestSource('''
f() => <int>{^1, 2};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_set_last() async {
    addTestSource('''
f() => <int>{1, 2, ^};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_ifOrForElement_set_middle() async {
    addTestSource('''
f() => <int>{1, ^, 2};
''');
    await computeSuggestions();
    assertSuggestKeywords(COLLECTION_ELEMENT_START);
  }

  Future<void> test_import() async {
    addTestSource('import "foo" deferred as foo ^;');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['show', 'hide']);
  }

  Future<void> test_import_as() async {
    addTestSource('import "foo" deferred ^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS]);
  }

  Future<void> test_import_as2() async {
    addTestSource('import "foo" deferred a^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS]);
  }

  Future<void> test_import_as3() async {
    addTestSource('import "foo" deferred a^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS]);
  }

  Future<void> test_import_deferred() async {
    addTestSource('import "foo" ^ as foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DEFERRED]);
  }

  Future<void> test_import_deferred2() async {
    addTestSource('import "foo" d^ as foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DEFERRED]);
  }

  Future<void> test_import_deferred3() async {
    addTestSource('import "foo" d^ show foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS], pseudoKeywords: ['deferred as']);
  }

  Future<void> test_import_deferred4() async {
    addTestSource('import "foo" d^ hide foo;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS], pseudoKeywords: ['deferred as']);
  }

  Future<void> test_import_deferred5() async {
    addTestSource('import "foo" d^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred6() async {
    addTestSource('import "foo" d^ import');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred_as() async {
    addTestSource('import "foo" ^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred_as2() async {
    addTestSource('import "foo" d^;');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred_as3() async {
    addTestSource('import "foo" ^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred_as4() async {
    addTestSource('import "foo" d^');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred_as5() async {
    addTestSource('import "foo" sh^ import "bar"; import "baz";');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.AS],
        pseudoKeywords: ['deferred as', 'show', 'hide']);
  }

  Future<void> test_import_deferred_not() async {
    addTestSource('import "foo" as foo ^;');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['show', 'hide']);
  }

  Future<void> test_import_deferred_partial() async {
    addTestSource('import "package:foo/foo.dart" def^ as foo;');
    await computeSuggestions();
    expect(replacementOffset, 30);
    expect(replacementLength, 3);
    assertSuggestKeywords([Keyword.DEFERRED]);
    expect(suggestions[0].selectionOffset, 8);
    expect(suggestions[0].selectionLength, 0);
  }

  Future<void> test_import_incomplete() async {
    addTestSource('import "^"');
    await computeSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_import_partial() async {
    addTestSource('imp^ import "package:foo/foo.dart"; import "bar.dart";');
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(directiveDeclarationAndLibraryKeywords);
  }

  Future<void> test_import_partial2() async {
    addTestSource('^imp import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(directiveDeclarationAndLibraryKeywords);
  }

  Future<void> test_import_partial3() async {
    addTestSource(' ^imp import "package:foo/foo.dart"; import "bar.dart";');
    await computeSuggestions();
    expect(replacementOffset, 1);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(directiveDeclarationAndLibraryKeywords);
  }

  Future<void> test_import_partial4() async {
    addTestSource('^ imp import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, 0);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(directiveDeclarationAndLibraryKeywords);
  }

  Future<void> test_import_partial5() async {
    addTestSource('library libA; imp^ import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 14);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(directiveDeclarationKeywords);
  }

  Future<void> test_import_partial6() async {
    addTestSource(
        'library bar; import "zoo.dart"; imp^ import "package:foo/foo.dart";');
    await computeSuggestions();
    expect(replacementOffset, 32);
    expect(replacementLength, 3);
    // TODO(danrubel) should not suggest declaration keywords
    assertSuggestKeywords(directiveDeclarationKeywords);
  }

  Future<void> test_integerLiteral_inArgumentList() async {
    addTestSource('main() { print(42^); }');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_integerLiteral_inListLiteral() async {
    addTestSource('main() { var items = [42^]; }');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_is_expression() async {
    addTestSource('main() {if (x is^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS]);
  }

  Future<void> test_is_expression_partial() async {
    addTestSource('main() {if (x i^)}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IS]);
  }

  Future<void> test_library() async {
    addTestSource('library foo;^');
    await computeSuggestions();
    assertSuggestKeywords(directiveAndDeclarationKeywords);
  }

  Future<void> test_library_declaration() async {
    addTestSource('library ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_library_declaration2() async {
    addTestSource('library a^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_library_declaration3() async {
    addTestSource('library a.^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_library_name() async {
    addTestSource('library ^');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_method_async() async {
    addTestSource('class A { foo() ^}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_async2() async {
    addTestSource('class A { foo() ^{}}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_async3() async {
    addTestSource('class A { foo() a^}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_async4() async {
    addTestSource('class A { foo() a^{}}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_async5() async {
    addTestSource('class A { foo() ^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_async6() async {
    addTestSource('class A { foo() a^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_async7() async {
    addTestSource('class A { foo() ^ => Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords([], pseudoKeywords: ['async']);
  }

  Future<void> test_method_async8() async {
    addTestSource('class A { foo() a^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(classBodyKeywords,
        pseudoKeywords: ['async', 'async*', 'sync*']);
  }

  Future<void> test_method_body() async {
    addTestSource('class A { foo() {^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass);
  }

  Future<void> test_method_body2() async {
    addTestSource('class A { foo() => ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_method_body3() async {
    addTestSource('class A { foo() => ^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_method_body4() async {
    addTestSource('class A { foo() => ^;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_method_body_async() async {
    addTestSource('class A { foo() async {^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass, pseudoKeywords: ['await']);
  }

  Future<void> test_method_body_async2() async {
    addTestSource('class A { foo() async => ^}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  Future<void> test_method_body_async3() async {
    addTestSource('class A { foo() async => ^ Foo foo;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  Future<void> test_method_body_async4() async {
    addTestSource('class A { foo() async => ^;}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  Future<void> test_method_body_async_star() async {
    addTestSource('class A { foo() async* {^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInClass,
        pseudoKeywords: ['await', 'yield', 'yield*']);
  }

  Future<void> test_method_body_expression1() async {
    addTestSource('class A { foo() {return b == true ? ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_method_body_expression2() async {
    addTestSource('class A { foo() {return b == true ? 1 : ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_method_body_return() async {
    addTestSource('class A { foo() {return ^}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  Future<void> test_method_body_return_with_header() async {
    addTestSource('class A { @override ^ foo() {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_method_body_return_with_header_prefix() async {
    addTestSource('class A { @override d^ foo() {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(classBodyKeywords);
  }

  Future<void> test_method_invocation() async {
    addTestSource('class A { foo() {bar.^}}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_method_invocation2() async {
    addTestSource('class A { foo() {bar.as^}}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_method_param_named_init() async {
    addTestSource('class A { foo({bool bar: ^}) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_method_param_named_init2() async {
    addTestSource('class A { foo({bool bar: f^}) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_method_param_noPrefix() async {
    addTestSource('class A { foo(^) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(methodParameter);
  }

  Future<void> test_method_param_noPrefix_func_parameter() async {
    addTestSource('class A { foo(^ Function(){}) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(methodParameter);
  }

  Future<void> test_method_param_positional_init() async {
    addTestSource('class A { foo([bool bar = ^]) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_method_param_positional_init2() async {
    addTestSource('class A { foo([bool bar = f^]) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_method_param_prefix() async {
    addTestSource('class A { foo(t^) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(methodParameter);
  }

  Future<void> test_method_param_prefix_func_parameter() async {
    addTestSource('class A { foo(v^ Function(){}) {}}');
    await computeSuggestions();
    expect(suggestions, isNotEmpty);
    assertSuggestKeywords(methodParameter);
  }

  Future<void> test_method_type_params() async {
    addTestSource('''
void f<T>() {}

void m() {
  f<^>();
}
''');

    await computeSuggestions();
    assertSuggestKeywords([Keyword.DYNAMIC, Keyword.VOID]);
  }

  Future<void> test_mixin() async {
    addTestSource('mixin M o^ { }');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.ON, Keyword.IMPLEMENTS]);
  }

  Future<void> test_mixin_afterOnClause() async {
    addTestSource('mixin M on A i^ { } class A {}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.IMPLEMENTS]);
  }

  Future<void> test_named_constructor_invocation() async {
    addTestSource('void main() {new Future.^}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_newInstance() async {
    addTestSource('class A { foo() {new ^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_newInstance2() async {
    addTestSource('class A { foo() {new ^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_newInstance_prefixed() async {
    addTestSource('class A { foo() {new A.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_newInstance_prefixed2() async {
    addTestSource('class A { foo() {new A.^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_part_of() async {
    addTestSource('part of foo;^');
    await computeSuggestions();
    assertSuggestKeywords(directiveAndDeclarationKeywords);
  }

  Future<void> test_partial_class() async {
    addTestSource('cl^');
    await computeSuggestions();
    assertSuggestKeywords(directiveDeclarationAndLibraryKeywords);
  }

  Future<void> test_partial_class2() async {
    addTestSource('library a; cl^');
    await computeSuggestions();
    assertSuggestKeywords(directiveAndDeclarationKeywords);
  }

  Future<void> test_prefixed_field() async {
    addTestSource('class A { int x; foo() {x.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_prefixed_field2() async {
    addTestSource('class A { int x; foo() {x.^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_prefixed_library() async {
    addTestSource('import "b" as b; class A { foo() {b.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_prefixed_local() async {
    addTestSource('class A { foo() {int x; x.^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_prefixed_local2() async {
    addTestSource('class A { foo() {int x; x.^ print("foo");}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_property_access() async {
    addTestSource('class A { get x => 7; foo() {new A().^}}');
    await computeSuggestions();
    assertSuggestKeywords([]);
  }

  Future<void> test_spreadElement() async {
    addTestSource('''
f() => [...^];
''');
    await computeSuggestions();
    assertSuggestKeywords(KeywordContributorTest.EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_switch_expression() async {
    addTestSource('main() {switch(^) {}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_switch_expression2() async {
    addTestSource('main() {switch(n^) {}}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_switch_expression3() async {
    addTestSource('main() {switch(n^)}');
    await computeSuggestions();
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  Future<void> test_switch_start() async {
    addTestSource('main() {switch(1) {^}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_start2() async {
    addTestSource('main() {switch(1) {^ case 1:}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_start3() async {
    addTestSource('main() {switch(1) {^default:}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_start4() async {
    addTestSource('main() {switch(1) {^ default:}}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_start5() async {
    addTestSource('main() {switch(1) {c^ default:}}');
    await computeSuggestions();
    expect(replacementOffset, 19);
    expect(replacementLength, 1);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_start6() async {
    addTestSource('main() {switch(1) {c^}}');
    await computeSuggestions();
    expect(replacementOffset, 19);
    expect(replacementLength, 1);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_start7() async {
    addTestSource('main() {switch(1) { c^ }}');
    await computeSuggestions();
    expect(replacementOffset, 20);
    expect(replacementLength, 1);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT]);
  }

  Future<void> test_switch_statement_case_break_insideClass() async {
    addTestSource('class A{foo() {switch(1) {case 1: b^}}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInSwitchCaseInClass);
  }

  Future<void> test_switch_statement_case_break_outsideClass() async {
    addTestSource('foo() {switch(1) {case 1: b^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInSwitchCaseOutsideClass);
  }

  Future<void> test_switch_statement_insideClass() async {
    addTestSource('class A{foo() {switch(1) {case 1:^}}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInSwitchInClass);
  }

  Future<void> test_switch_statement_outsideClass() async {
    addTestSource('main() {switch(1) {case 1:^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInSwitchOutsideClass);
  }

  Future<void> test_variable_decl_type_args() async {
    addTestSource('void m() {List<^> list;}');
    await computeSuggestions();
    assertSuggestKeywords([Keyword.DYNAMIC, Keyword.VOID]);
  }

  Future<void> test_while_break_continue() async {
    addTestSource('main() {while (true) {^}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInLoopOutsideClass);
  }

  Future<void> test_while_break_continue2() async {
    addTestSource('class A {foo() {while (true) {^}}}');
    await computeSuggestions();
    assertSuggestKeywords(statementStartInLoopInClass);
  }

  void _appendCompletions(
      StringBuffer msg, Iterable<String> completions, Iterable<String> other) {
    var sorted = completions.toList();
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
class KeywordContributorWithNullSafetyTest extends KeywordContributorTest
    with WithNullSafetyMixin {}
