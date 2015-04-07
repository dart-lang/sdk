// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.keyword;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/keyword_contributor.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(KeywordContributorTest);
}

@reflectiveTest
class KeywordContributorTest extends AbstractCompletionTest {
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

  static const List<Keyword> IN_BLOCK_IN_CLASS = const [
    Keyword.ASSERT,
    Keyword.CASE,
    Keyword.CONTINUE,
    Keyword.DO,
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
    Keyword.WHILE
  ];

  static const List<Keyword> IN_BLOCK_NOT_IN_CLASS = const [
    Keyword.ASSERT,
    Keyword.CASE,
    Keyword.CONTINUE,
    Keyword.DO,
    Keyword.FINAL,
    Keyword.FOR,
    Keyword.IF,
    Keyword.NEW,
    Keyword.RETHROW,
    Keyword.RETURN,
    Keyword.SWITCH,
    Keyword.THROW,
    Keyword.TRY,
    Keyword.VAR,
    Keyword.VOID,
    Keyword.WHILE
  ];

  void assertSuggestKeywords(Iterable<Keyword> expectedKeywords,
      [int relevance = DART_RELEVANCE_KEYWORD]) {
    Set<Keyword> actualKeywords = new Set<Keyword>();
    for (CompletionSuggestion s in request.suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        Keyword k = Keyword.keywords[s.completion];
        if (k == null) {
          fail('Invalid keyword suggested: ${s.completion}');
        } else {
          if (!actualKeywords.add(k)) {
            fail('Duplicate keyword suggested: ${s.completion}');
          }
        }
      }
    }
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
    for (CompletionSuggestion s in request.suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        Keyword k = Keyword.keywords[s.completion];
        expect(s.relevance, equals(relevance), reason: k.toString());
        expect(s.selectionOffset, equals(s.completion.length));
        expect(s.selectionLength, equals(0));
        expect(s.isDeprecated, equals(false));
        expect(s.isPotential, equals(false));
      }
    }
  }

  @override
  void setUpContributor() {
    contributor = new KeywordContributor();
  }

  test_after_class() {
    addTestSource('class A {} ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_after_class2() {
    addTestSource('class A {} c^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_after_import() {
    addTestSource('import "foo"; ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        DIRECTIVE_AND_DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_after_import2() {
    addTestSource('import "foo"; c^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        DIRECTIVE_AND_DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_before_import() {
    addTestSource('^ import foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([
      Keyword.EXPORT,
      Keyword.IMPORT,
      Keyword.LIBRARY,
      Keyword.PART
    ], DART_RELEVANCE_HIGH);
  }

  test_class() {
    addTestSource('class A e^ { }');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_body() {
    addTestSource('class A {^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_body_beginning() {
    addTestSource('class A {^ var foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_body_between() {
    addTestSource('class A {var bar; ^ var foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_body_end() {
    addTestSource('class A {var foo; ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS);
  }

  test_class_extends() {
    addTestSource('class A extends foo ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.IMPLEMENTS, Keyword.WITH], DART_RELEVANCE_HIGH);
  }

  test_class_extends2() {
    addTestSource('class A extends foo i^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.IMPLEMENTS, Keyword.WITH], DART_RELEVANCE_HIGH);
  }

  test_class_extends3() {
    addTestSource('class A extends foo i^ { }');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.IMPLEMENTS, Keyword.WITH], DART_RELEVANCE_HIGH);
  }

  test_class_extends_name() {
    addTestSource('class A extends ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_implements() {
    addTestSource('class A ^ implements foo');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.EXTENDS], DART_RELEVANCE_HIGH);
  }

  test_class_implements2() {
    addTestSource('class A e^ implements foo');
    expect(computeFast(), isTrue);
    // TODO (danrubel) refinement: don't suggest implements
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_implements3() {
    addTestSource('class A e^ implements foo { }');
    expect(computeFast(), isTrue);
    // TODO (danrubel) refinement: don't suggest implements
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
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

  test_class_noBody() {
    addTestSource('class A ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_noBody2() {
    addTestSource('class A e^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_noBody3() {
    addTestSource('class A e^ String foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXTENDS, Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_with() {
    addTestSource('class A extends foo with bar ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_with2() {
    addTestSource('class A extends foo with bar i^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
  }

  test_class_with3() {
    addTestSource('class A extends foo with bar i^ { }');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS], DART_RELEVANCE_HIGH);
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
        DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_function_body_inClass_constructorInitializer() {
    addTestSource(r'''
foo(p) {}
class A {
  final f;
  A() : f = foo(() {^});
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_NOT_IN_CLASS);
  }

  test_function_body_inClass_field() {
    addTestSource(r'''
class A {
  var f = () {^};
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_NOT_IN_CLASS);
  }

  test_function_body_inClass_methodBody() {
    addTestSource(r'''
class A {
  m() {
    f() {^};
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_IN_CLASS);
  }

  test_function_body_inClass_methodBody_inFunction() {
    addTestSource(r'''
class A {
  m() {
    f() {
      f2() {^};
    };
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_IN_CLASS);
  }

  test_function_body_inUnit() {
    addTestSource('main() {^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_NOT_IN_CLASS);
  }

  test_function_body_inUnit_afterBlock() {
    addTestSource('main() {{}^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_NOT_IN_CLASS);
  }

  test_import() {
    addTestSource('import "foo" deferred as foo ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([], DART_RELEVANCE_HIGH);
  }

  test_import_as() {
    addTestSource('import "foo" deferred ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS], DART_RELEVANCE_HIGH);
  }

  test_import_as2() {
    addTestSource('import "foo" deferred a^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS], DART_RELEVANCE_HIGH);
  }

  test_import_as3() {
    addTestSource('import "foo" deferred a^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS], DART_RELEVANCE_HIGH);
  }

  test_import_deferred() {
    addTestSource('import "foo" ^ as foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.DEFERRED], DART_RELEVANCE_HIGH);
  }

  test_import_deferred_not() {
    addTestSource('import "foo" as foo ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([], DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as() {
    addTestSource('import "foo" ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED], DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as2() {
    addTestSource('import "foo" d^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED], DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as3() {
    addTestSource('import "foo" ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED], DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as4() {
    addTestSource('import "foo" d^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED], DART_RELEVANCE_HIGH);
  }

  test_library() {
    addTestSource('library foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        DIRECTIVE_AND_DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_library_name() {
    addTestSource('library ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_method_body() {
    addTestSource('class A { foo() {^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(IN_BLOCK_IN_CLASS);
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
        DIRECTIVE_AND_DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_partial_class() {
    addTestSource('cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS, DART_RELEVANCE_HIGH);
  }

  test_partial_class2() {
    addTestSource('library a; cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        DIRECTIVE_AND_DECLARATION_KEYWORDS, DART_RELEVANCE_HIGH);
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
