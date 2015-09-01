// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.combinator;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/combinator_contributor.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../utils.dart';
import 'completion_test_util.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(CombinatorContributorTest);
}

@reflectiveTest
class CombinatorContributorTest extends AbstractCompletionTest {
  @override
  void setUpContributor() {
    contributor = new CombinatorContributor();
  }

  test_Block_inherited_local() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
      class F { var f1; f2() { } }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }
      class A extends E implements I with M {a() {^}}''');
    computeFast();
    return computeFull((bool result) {
      assertNoSuggestions();
    });
  }

  test_Combinator_hide() {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource(
        '/testAB.dart',
        '''
      library libAB;
      part '/partAB.dart';
      class A { }
      class B { }''');
    addSource(
        '/partAB.dart',
        '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      class PB { }''');
    addSource(
        '/testCD.dart',
        '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" hide ^;
      import "/testCD.dart";
      class X {}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestClass('A',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass('B',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass('PB',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestTopLevelVar('T1', null, DART_RELEVANCE_DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestFunction('F1', 'PB',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('C');
      assertNotSuggested('D');
      assertNotSuggested('X');
      assertNotSuggested('Object');
    });
  }

  test_Combinator_show() {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource(
        '/testAB.dart',
        '''
      library libAB;
      part '/partAB.dart';
      class A { }
      class B { }''');
    addSource(
        '/partAB.dart',
        '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      typedef PB2 F2(int blat);
      class Clz = Object with Object;
      class PB { }''');
    addSource(
        '/testCD.dart',
        '''
      class C { }
      class D { }''');
    addTestSource('''
      import "/testAB.dart" show ^;
      import "/testCD.dart";
      class X {}''');
    computeFast();
    return computeFull((bool result) {
      assertSuggestClass('A',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass('B',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass('PB',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestTopLevelVar('T1', null, DART_RELEVANCE_DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestFunction('F1', 'PB',
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass('Clz',
          relevance: DART_RELEVANCE_DEFAULT,
          kind: CompletionSuggestionKind.IDENTIFIER);
      assertSuggestFunctionTypeAlias('F2', null, false, DART_RELEVANCE_DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('C');
      assertNotSuggested('D');
      assertNotSuggested('X');
      assertNotSuggested('Object');
    });
  }
}
