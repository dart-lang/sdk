// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.keyword;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/keyword_contributor.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(KeywordContributorTest);
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

  static const List<String> NO_PSEUDO_KEYWORDS = const [];

  static const List<Keyword> STMT_START_IN_CLASS = const [
    Keyword.ASSERT,
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

  static const List<Keyword> STMT_START_IN_SWITCH_IN_CLASS = const [
    Keyword.ASSERT,
    Keyword.CASE,
    Keyword.CONTINUE,
    Keyword.DEFAULT,
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

  static const List<Keyword> STMT_START_IN_SWITCH_OUTSIDE_CLASS = const [
    Keyword.ASSERT,
    Keyword.CASE,
    Keyword.CONTINUE,
    Keyword.DEFAULT,
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

  static const List<Keyword> STMT_START_OUTSIDE_CLASS = const [
    Keyword.ASSERT,
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

  static const List<Keyword> EXPRESSION_START_INSTANCE = const [
    Keyword.FALSE,
    Keyword.NEW,
    Keyword.NULL,
    Keyword.SUPER,
    Keyword.THIS,
    Keyword.TRUE,
  ];

  static const List<Keyword> EXPRESSION_START_NO_INSTANCE = const [
    Keyword.FALSE,
    Keyword.NEW,
    Keyword.NULL,
    Keyword.TRUE,
  ];

  void assertSuggestKeywords(Iterable<Keyword> expectedKeywords,
      {List<String> pseudoKeywords: NO_PSEUDO_KEYWORDS,
      int relevance: DART_RELEVANCE_KEYWORD}) {
    Set<String> expectedCompletions = new Set<String>();
    Set<String> actualCompletions = new Set<String>();
    expectedCompletions.addAll(expectedKeywords.map((k) => k.syntax));
    expectedCompletions.addAll(pseudoKeywords);
    for (CompletionSuggestion s in request.suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        Keyword k = Keyword.keywords[s.completion];
        if (k == null && !pseudoKeywords.contains(s.completion)) {
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
    for (CompletionSuggestion s in request.suggestions) {
      if (s.kind == CompletionSuggestionKind.KEYWORD) {
        expect(s.relevance, equals(relevance), reason: s.completion);
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
    assertSuggestKeywords(DECLARATION_KEYWORDS, relevance: DART_RELEVANCE_HIGH);
  }

  test_after_class2() {
    addTestSource('class A {} c^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS, relevance: DART_RELEVANCE_HIGH);
  }

  test_after_import() {
    addTestSource('import "foo"; ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_after_import2() {
    addTestSource('import "foo"; c^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_argument() {
    addTestSource('main() {foo(^);}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument2() {
    addTestSource('main() {foo(n^);}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument_literal() {
    addTestSource('main() {foo("^");}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_argument_named() {
    addTestSource('main() {foo(bar: ^);}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument_named2() {
    addTestSource('main() {foo(bar: n^);}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_argument_named_literal() {
    addTestSource('main() {foo(bar: "^");}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_assignment_field() {
    addTestSource('class A {var foo = ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_field2() {
    addTestSource('class A {var foo = n^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_local() {
    addTestSource('main() {var foo = ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_local2() {
    addTestSource('main() {var foo = n^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_assignment_local2_async() {
    addTestSource('main() async {var foo = n^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['await']);
  }

  test_assignment_local_async() {
    addTestSource('main() async {var foo = ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE,
        pseudoKeywords: ['await']);
  }

  test_before_import() {
    addTestSource('^ import foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(
        [Keyword.EXPORT, Keyword.IMPORT, Keyword.LIBRARY, Keyword.PART],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class() {
    addTestSource('class A e^ { }');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
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
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_extends2() {
    addTestSource('class A extends foo i^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_extends3() {
    addTestSource('class A extends foo i^ { }');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS, Keyword.WITH],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_extends_name() {
    addTestSource('class A extends ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_class_implements() {
    addTestSource('class A ^ implements foo');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.EXTENDS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_implements2() {
    addTestSource('class A e^ implements foo');
    expect(computeFast(), isTrue);
    // TODO (danrubel) refinement: don't suggest implements
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_implements3() {
    addTestSource('class A e^ implements foo { }');
    expect(computeFast(), isTrue);
    // TODO (danrubel) refinement: don't suggest implements
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
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
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_noBody2() {
    addTestSource('class A e^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_noBody3() {
    addTestSource('class A e^ String foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.EXTENDS, Keyword.IMPLEMENTS],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with() {
    addTestSource('class A extends foo with bar ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with2() {
    addTestSource('class A extends foo with bar i^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with3() {
    addTestSource('class A extends foo with bar i^ { }');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.IMPLEMENTS], relevance: DART_RELEVANCE_HIGH);
  }

  test_class_with_name() {
    addTestSource('class A extends foo with ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_constructor_param() {
    addTestSource('class A { A(^) {});}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.THIS]);
  }

  test_constructor_param2() {
    addTestSource('class A { A(t^) {});}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.THIS]);
  }

  test_empty() {
    addTestSource('^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async() {
    addTestSource('main()^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async2() {
    addTestSource('main()^{}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([],
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async3() {
    addTestSource('main()a^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async4() {
    addTestSource('main()a^{}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_function_async5() {
    addTestSource('main()a^ Foo foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DECLARATION_KEYWORDS,
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
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
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inClass_constructorInitializer_async() {
    addTestSource(r'''
foo(p) {}
class A {
  final f;
  A() : f = foo(() async {^});
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS, pseudoKeywords: ['await']);
  }

  test_function_body_inClass_field() {
    addTestSource(r'''
class A {
  var f = () {^};
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
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
    assertSuggestKeywords(STMT_START_IN_CLASS);
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
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_function_body_inClass_methodBody_inFunction_async() {
    addTestSource(r'''
class A {
  m() {
    f() {
      f2() async {^};
    };
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS, pseudoKeywords: ['await']);
  }

  test_function_body_inUnit() {
    addTestSource('main() {^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inUnit_afterBlock() {
    addTestSource('main() {{}^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_function_body_inUnit_async() {
    addTestSource('main() async {^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS, pseudoKeywords: ['await']);
  }

  test_if_in_class() {
    addTestSource('class A {foo() {if (true) ^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_in_class2() {
    addTestSource('class A {foo() {if (true) ^;}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_in_class3() {
    addTestSource('class A {foo() {if (true) r^;}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_in_class4() {
    addTestSource('class A {foo() {if (true) ^ go();}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_if_outside_class() {
    addTestSource('foo() {if (true) ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_if_outside_class2() {
    addTestSource('foo() {if (true) ^;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_if_outside_class3() {
    addTestSource('foo() {if (true) r^;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_if_outside_class4() {
    addTestSource('foo() {if (true) ^ go();}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_OUTSIDE_CLASS);
  }

  test_import() {
    addTestSource('import "foo" deferred as foo ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_as() {
    addTestSource('import "foo" deferred ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_as2() {
    addTestSource('import "foo" deferred a^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_as3() {
    addTestSource('import "foo" deferred a^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred() {
    addTestSource('import "foo" ^ as foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.DEFERRED], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred2() {
    addTestSource('import "foo" d^ as foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.DEFERRED], relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred3() {
    addTestSource('import "foo" d^ show foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred4() {
    addTestSource('import "foo" d^ hide foo;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred5() {
    addTestSource('import "foo" d^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred6() {
    addTestSource('import "foo" d^ import');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as() {
    addTestSource('import "foo" ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as2() {
    addTestSource('import "foo" d^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as3() {
    addTestSource('import "foo" ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_as4() {
    addTestSource('import "foo" d^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.AS, Keyword.DEFERRED],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_import_deferred_not() {
    addTestSource('import "foo" as foo ^;');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([], relevance: DART_RELEVANCE_HIGH);
  }

  test_library() {
    addTestSource('library foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_library_name() {
    addTestSource('library ^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_method_async() {
    addTestSource('class A { foo() ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS, pseudoKeywords: ['async']);
  }

  test_method_async2() {
    addTestSource('class A { foo() ^{}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([],
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_method_async3() {
    addTestSource('class A { foo() a^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS, pseudoKeywords: ['async']);
  }

  test_method_async4() {
    addTestSource('class A { foo() a^{}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS, pseudoKeywords: ['async']);
  }

  test_method_async5() {
    addTestSource('class A { foo() ^ Foo foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS, pseudoKeywords: ['async']);
  }

  test_method_async6() {
    addTestSource('class A { foo() a^ Foo foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS, pseudoKeywords: ['async']);
  }

  test_method_async7() {
    addTestSource('class A { foo() ^ => Foo foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([],
        pseudoKeywords: ['async'], relevance: DART_RELEVANCE_HIGH);
  }

  test_method_async8() {
    addTestSource('class A { foo() a^ Foo foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(CLASS_BODY_KEYWORDS, pseudoKeywords: ['async']);
  }

  test_method_body() {
    addTestSource('class A { foo() {^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS);
  }

  test_method_body2() {
    addTestSource('class A { foo() => ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body3() {
    addTestSource('class A { foo() => ^ Foo foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body4() {
    addTestSource('class A { foo() => ^;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_INSTANCE);
  }

  test_method_body_async() {
    addTestSource('class A { foo() async {^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_CLASS, pseudoKeywords: ['await']);
  }

  test_method_body_async2() {
    addTestSource('class A { foo() async => ^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  test_method_body_async3() {
    addTestSource('class A { foo() async => ^ Foo foo;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  test_method_body_async4() {
    addTestSource('class A { foo() async => ^;}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_INSTANCE, pseudoKeywords: ['await']);
  }

  test_method_param() {
    addTestSource('class A { foo(^) {});}');
    expect(computeFast(), isTrue);
    assertNoSuggestions();
  }

  test_method_param2() {
    addTestSource('class A { foo(t^) {});}');
    expect(computeFast(), isTrue);
    assertNoSuggestions();
  }

  test_named_constructor_invocation() {
    addTestSource('void main() {new Future.^}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([]);
  }

  test_part_of() {
    addTestSource('part of foo;^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_partial_class() {
    addTestSource('cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_DECLARATION_AND_LIBRARY_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_partial_class2() {
    addTestSource('library a; cl^');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(DIRECTIVE_AND_DECLARATION_KEYWORDS,
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_expression() {
    addTestSource('main() {switch(^) {}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_switch_expression2() {
    addTestSource('main() {switch(n^) {}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_switch_expression3() {
    addTestSource('main() {switch(n^)}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(EXPRESSION_START_NO_INSTANCE);
  }

  test_switch_start() {
    addTestSource('main() {switch(1) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start2() {
    addTestSource('main() {switch(1) {^ case 1:}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start3() {
    addTestSource('main() {switch(1) {^default:}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_start4() {
    addTestSource('main() {switch(1) {^ default:}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords([Keyword.CASE, Keyword.DEFAULT],
        relevance: DART_RELEVANCE_HIGH);
  }

  test_switch_statement() {
    addTestSource('main() {switch(1) {case 1:^}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_SWITCH_OUTSIDE_CLASS);
  }

  test_switch_statement2() {
    addTestSource('class A{foo() {switch(1) {case 1:^}}}');
    expect(computeFast(), isTrue);
    assertSuggestKeywords(STMT_START_IN_SWITCH_IN_CLASS);
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
