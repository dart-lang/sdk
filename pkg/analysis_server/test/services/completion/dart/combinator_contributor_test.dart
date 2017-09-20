// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/combinator_contributor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CombinatorContributorTest);
  });
}

@reflectiveTest
class CombinatorContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new CombinatorContributor();
  }

  test_Block_inherited_local() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
      class F { var f1; f2() { } }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }
      class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_Combinator_hide() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('/testAB.dart', '''
      library libAB;
      part '/partAB.dart';
      class A { }
      class B { }''');
    addSource('/partAB.dart', '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      class PB { }''');
    addSource('/testCD.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" hide ^;
      import "/testCD.dart";
      class X {}''');

    await computeSuggestions();
    assertSuggestClass('A',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('B',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('PB',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestTopLevelVar('T1', null,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestFunction('F1', 'PB',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('C');
    assertNotSuggested('D');
    assertNotSuggested('X');
    assertNotSuggested('Object');
  }

  test_Combinator_show() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('/testAB.dart', '''
      library libAB;
      part '/partAB.dart';
      class A { }
      class B { }
      class _AB''');
    addSource('/partAB.dart', '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      typedef PB2 F2(int blat);
      class Clz = Object with Object;
      class PB { }''');
    addSource('/testCD.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" show ^;
      import "/testCD.dart";
      class X {}''');

    await computeSuggestions();
    assertSuggestClass('A',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('B',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('_AB');
    assertSuggestClass('PB',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestTopLevelVar('T1', null,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestFunction('F1', 'PB',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('Clz',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestFunctionTypeAlias('F2', null,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('C');
    assertNotSuggested('D');
    assertNotSuggested('X');
    assertNotSuggested('Object');
  }

  test_Combinator_show_PI() async {
    addTestSource('import "dart:math" show ^;');
    await computeSuggestions();
    assertSuggestTopLevelVar('PI', 'double',
        kind: CompletionSuggestionKind.IDENTIFIER);
  }

  test_Combinator_show_recursive() async {
    addSource('/testA.dart', '''
class A {}
''');
    addSource('/testB.dart', '''
export 'testA.dart';
export 'testB.dart';
class B {}
''');
    addTestSource('''
import "/testB.dart" show ^;
''');
    await computeSuggestions();
    assertSuggestClass('A',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('B',
        relevance: DART_RELEVANCE_DEFAULT,
        kind: CompletionSuggestionKind.IDENTIFIER);
  }
}
