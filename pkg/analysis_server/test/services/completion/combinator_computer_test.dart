// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.combinator;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/combinator_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CombinatorComputerTest);
}

@ReflectiveTestCase()
class CombinatorComputerTest extends AbstractCompletionTest {

  @override
  void setUpComputer() {
    computer = new CombinatorComputer();
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
    computeFast();
    return computeFull((bool result) {
      assertSuggestClass(
          'A',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass(
          'B',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass(
          'PB',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestTopLevelVar(
          'T1',
          null,
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestFunction(
          'F1',
          'PB',
          false,
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('C');
      assertNotSuggested('D');
      assertNotSuggested('X');
      assertNotSuggested('Object');
    });
  }

  test_Combinator_show() {
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
    computeFast();
    return computeFull((bool result) {
      assertSuggestClass(
          'A',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass(
          'B',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass(
          'PB',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestTopLevelVar(
          'T1',
          null,
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestFunction(
          'F1',
          'PB',
          false,
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestClass(
          'Clz',
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertSuggestFunctionTypeAlias(
          'F2',
          null,
          false,
          CompletionRelevance.DEFAULT,
          CompletionSuggestionKind.IDENTIFIER);
      assertNotSuggested('C');
      assertNotSuggested('D');
      assertNotSuggested('X');
      assertNotSuggested('Object');
    });
  }
}
