// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/combinator_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CombinatorContributorTest);
  });
}

@reflectiveTest
class CombinatorContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return CombinatorContributor(request, builder);
  }

  Future<void> test_Block_inherited_local() async {
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

  Future<void> test_Combinator_hide() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('$testPackageLibPath/ab.dart', '''
      library libAB;
      part "ab_part.dart";
      class A { }
      class B { }''');
    addSource('$testPackageLibPath/ab_part.dart', '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      class PB { }''');
    addSource('$testPackageLibPath/cd.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "ab.dart" hide ^;
      import "cd.dart";
      class X {}''');

    await computeSuggestions();
    assertSuggestClass('A', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('PB', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestTopLevelVar('T1', null);
    assertSuggestFunction('F1', 'PB',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('C');
    assertNotSuggested('D');
    assertNotSuggested('X');
    assertNotSuggested('Object');
  }

  Future<void> test_Combinator_hide_duplicate() async {
    addTestSource('import "dart:math" hide PI, ^;');
    await computeSuggestions();
    assertNotSuggested('PI');
  }

  Future<void> test_Combinator_show() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('$testPackageLibPath/ab.dart', '''
      library libAB;
      part "ab_part.dart";
      class A { }
      class B { }
      class _AB''');
    addSource('$testPackageLibPath/ab_part.dart', '''
      part of libAB;
      var T1;
      PB F1() => new PB();
      typedef PB2 F2(int blat);
      class Clz = Object with Object;
      class PB { }''');
    addSource('$testPackageLibPath/cd.dart', '''
      class C { }
      class D { }''');
    addTestSource('''
      import "ab.dart" show ^;
      import "cd.dart";
      class X {}''');

    await computeSuggestions();
    assertSuggestClass('A', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('_AB');
    assertSuggestClass('PB', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestTopLevelVar('T1', null);
    assertSuggestFunction('F1', 'PB',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('Clz', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestTypeAlias('F2',
        kind: CompletionSuggestionKind.IDENTIFIER,
        aliasedType: 'dynamic Function(int)',
        returnType: 'dynamic');
    assertNotSuggested('C');
    assertNotSuggested('D');
    assertNotSuggested('X');
    assertNotSuggested('Object');
  }

  Future<void> test_Combinator_show_duplicate() async {
    addTestSource('import "dart:math" show PI, ^;');
    await computeSuggestions();
    assertNotSuggested('PI');
  }

  Future<void> test_Combinator_show_export_withShow() async {
    addSource('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
''');
    addSource('$testPackageLibPath/b.dart', r'''
export 'a.dart' show A;
''');
    addTestSource(r'''
import 'b.dart' show ^;
''');
    await computeSuggestions();
    assertSuggestClass('A', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('B');
  }

  Future<void> test_Combinator_show_pi() async {
    addTestSource('import "dart:math" show ^;');
    await computeSuggestions();
    assertSuggestTopLevelVar('pi', 'double');
  }

  Future<void> test_Combinator_show_recursive() async {
    addSource('$testPackageLibPath/a.dart', '''
class A {}
''');
    addSource('$testPackageLibPath/b.dart', '''
export 'a.dart';
export 'b.dart';
class B {}
''');
    addTestSource('''
import "b.dart" show ^;
''');
    await computeSuggestions();
    assertSuggestClass('A', kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
  }
}
