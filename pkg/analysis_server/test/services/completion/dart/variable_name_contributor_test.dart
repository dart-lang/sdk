// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.variableName;

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/variable_name_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableNameContributorTest);
    defineReflectiveTests(VariableNameContributorTest_Driver);
  });
}

@reflectiveTest
class VariableNameContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new VariableNameContributor();
  }

  test_ExpressionStatement_dont_suggest_type() async {
    addTestSource('''
    f() { a ^ }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
  }

  test_ExpressionStatement_dont_suggest_type_semicolon() async {
    addTestSource('''
    f() { a ^; }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
  }

  test_ExpressionStatement_long() async {
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
  }

  test_ExpressionStatement_long_semicolon() async {
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
  }

  test_ExpressionStatement_prefixed() async {
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
  }

  test_ExpressionStatement_prefixed_semicolon() async {
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
  }

  test_ExpressionStatement_short() async {
    addTestSource('''
    f() { A ^ }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
  }

  test_ExpressionStatement_short_semicolon() async {
    addTestSource('''
    f() { A ^; }
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
  }

  test_TopLevelVariableDeclaration_dont_suggest_type() async {
    addTestSource('''
    a ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
  }

  test_TopLevelVariableDeclaration_dont_suggest_type_semicolon() async {
    addTestSource('''
    a ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
  }

  test_TopLevelVariableDeclaration_long() async {
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
  }

  test_TopLevelVariableDeclaration_long_semicolon() async {
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
  }

  test_TopLevelVariableDeclaration_partial() async {
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
  }

  test_TopLevelVariableDeclaration_partial_semicolon() async {
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
  }

  test_TopLevelVariableDeclaration_prefixed() async {
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
  }

  test_TopLevelVariableDeclaration_prefixed_semicolon() async {
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
  }

  test_TopLevelVariableDeclaration_short() async {
    addTestSource('''
    A ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
  }

  test_TopLevelVariableDeclaration_short_semicolon() async {
    addTestSource('''
    A ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
  }
}

@reflectiveTest
class VariableNameContributorTest_Driver extends VariableNameContributorTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
