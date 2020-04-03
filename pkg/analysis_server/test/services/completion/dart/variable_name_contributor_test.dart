// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/variable_name_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableNameContributorTest);
  });
}

@reflectiveTest
class VariableNameContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return VariableNameContributor();
  }

  Future<void> test_ExpressionStatement_dont_suggest_type() async {
    addTestSource('''
    f() { a ^ }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
  }

  Future<void> test_ExpressionStatement_dont_suggest_type_semicolon() async {
    addTestSource('''
    f() { a ^; }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
  }

  Future<void> test_ExpressionStatement_inConstructorBody() async {
    addTestSource('''
    class A { A() { AbstractCrazyNonsenseClassName ^ } }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions aren't provided as this completion is in a constructor
    // body
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ExpressionStatement_inFunctionBody() async {
    addTestSource('''
    f() { AbstractCrazyNonsenseClassName ^ }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions aren't provided as this completion is in a function body
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ExpressionStatement_inMethodBody() async {
    addTestSource('''
    class A { f() { AbstractCrazyNonsenseClassName ^ } }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions aren't provided as this completion is in a method body
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ExpressionStatement_long_semicolon() async {
    addTestSource('''
    f() { AbstractCrazyNonsenseClassName ^; }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ExpressionStatement_prefixed() async {
    addTestSource('''
    f() { prefix.AbstractCrazyNonsenseClassName ^ }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ExpressionStatement_prefixed_semicolon() async {
    addTestSource('''
    f() { prefix.AbstractCrazyNonsenseClassName ^; }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ExpressionStatement_short() async {
    addTestSource('''
    f() { A ^ }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
    // private version
    assertNotSuggested('_a');
  }

  Future<void> test_ExpressionStatement_short_semicolon() async {
    addTestSource('''
    f() { A ^; }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
    // private version
    assertNotSuggested('_a');
  }

  @failingTest
  Future<void> test_ForStatement() async {
    addTestSource('''
    f() { for(AbstractCrazyNonsenseClassName ^) {} }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ForStatement_partial() async {
    addTestSource('''
    f() { for(AbstractCrazyNonsenseClassName a^) {} }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  @failingTest
  Future<void> test_ForStatement_prefixed() async {
    addTestSource('''
    f() { for(prefix.AbstractCrazyNonsenseClassName ^) {} }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_ForStatement_prefixed_partial() async {
    addTestSource('''
    f() { for(prefix.AbstractCrazyNonsenseClassName a^) {} }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertNotSuggested('_abstractCrazyNonsenseClassName');
    assertNotSuggested('_crazyNonsenseClassName');
    assertNotSuggested('_nonsenseClassName');
    assertNotSuggested('_className');
    assertNotSuggested('_name');
  }

  Future<void> test_SimpleFormalParameter_FormalParameterList() async {
    addTestSource('''
f(A ^) {}
''');
    await computeSuggestions();
    expect(replacementOffset, 4);
    expect(replacementLength, 0);
    assertSuggestName('a');
    // private version
    assertNotSuggested('_a');
  }

  Future<void> test_SimpleFormalParameter_itself() async {
    addTestSource('''
f(A n^) {}
''');
    await computeSuggestions();
    expect(replacementOffset, 4);
    expect(replacementLength, 1);
    assertSuggestName('a');
    // private version
    assertNotSuggested('_a');
  }

  Future<void> test_TopLevelVariableDeclaration_dont_suggest_type() async {
    addTestSource('''
    a ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    // private version
    assertNotSuggested('_a');
  }

  Future<void>
      test_TopLevelVariableDeclaration_dont_suggest_type_semicolon() async {
    addTestSource('''
    a ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    // private version
    assertNotSuggested('_a');
  }

  Future<void> test_TopLevelVariableDeclaration_long() async {
    addTestSource('''
    AbstractCrazyNonsenseClassName ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertSuggestName('_abstractCrazyNonsenseClassName');
    assertSuggestName('_crazyNonsenseClassName');
    assertSuggestName('_nonsenseClassName');
    assertSuggestName('_className');
    assertSuggestName('_name');
  }

  Future<void> test_TopLevelVariableDeclaration_long_semicolon() async {
    addTestSource('''
    AbstractCrazyNonsenseClassName ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertSuggestName('_abstractCrazyNonsenseClassName');
    assertSuggestName('_crazyNonsenseClassName');
    assertSuggestName('_nonsenseClassName');
    assertSuggestName('_className');
    assertSuggestName('_name');
  }

  Future<void> test_TopLevelVariableDeclaration_partial() async {
    addTestSource('''
    AbstractCrazyNonsenseClassName abs^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertSuggestName('_abstractCrazyNonsenseClassName');
    assertSuggestName('_crazyNonsenseClassName');
    assertSuggestName('_nonsenseClassName');
    assertSuggestName('_className');
    assertSuggestName('_name');
  }

  Future<void> test_TopLevelVariableDeclaration_partial_semicolon() async {
    addTestSource('''
    AbstractCrazyNonsenseClassName abs^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertSuggestName('_abstractCrazyNonsenseClassName');
    assertSuggestName('_crazyNonsenseClassName');
    assertSuggestName('_nonsenseClassName');
    assertSuggestName('_className');
    assertSuggestName('_name');
  }

  Future<void> test_TopLevelVariableDeclaration_prefixed() async {
    addTestSource('''
    prefix.AbstractCrazyNonsenseClassName ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertSuggestName('_abstractCrazyNonsenseClassName');
    assertSuggestName('_crazyNonsenseClassName');
    assertSuggestName('_nonsenseClassName');
    assertSuggestName('_className');
    assertSuggestName('_name');
  }

  Future<void> test_TopLevelVariableDeclaration_prefixed_semicolon() async {
    addTestSource('''
    prefix.AbstractCrazyNonsenseClassName ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('abstractCrazyNonsenseClassName');
    assertSuggestName('crazyNonsenseClassName');
    assertSuggestName('nonsenseClassName');
    assertSuggestName('className');
    assertSuggestName('name');
    // private versions
    assertSuggestName('_abstractCrazyNonsenseClassName');
    assertSuggestName('_crazyNonsenseClassName');
    assertSuggestName('_nonsenseClassName');
    assertSuggestName('_className');
    assertSuggestName('_name');
  }

  Future<void> test_TopLevelVariableDeclaration_short() async {
    addTestSource('''
    A ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
    // private version
    assertSuggestName('_a');
  }

  Future<void> test_TopLevelVariableDeclaration_short_semicolon() async {
    addTestSource('''
    A ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
    // private version
    assertSuggestName('_a');
  }
}
