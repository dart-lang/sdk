// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.variableName;

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/variable_name_contributor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../../utils.dart';
import 'completion_contributor_util.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(VariableNameContributorTest);
}

@reflectiveTest
class VariableNameContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new VariableNameContributor();
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

  test_ExpressionStatement_top_level_short() async {
    addTestSource('''
    A ^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
  }

  test_ExpressionStatement_top_level_short_semicolon() async {
    addTestSource('''
    A ^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestName('a');
  }

  test_ExpressionStatement_top_level_long() async {
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

  test_ExpressionStatement_top_level_long_semicolon() async {
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

  test_ExpressionStatement_top_level_prefixed() async {
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

  test_ExpressionStatement_top_level_prefixed_semicolon() async {
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

  test_VariableDeclaration_short() async {
    addTestSource('''
    AAA a^
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset-1);
    expect(replacementLength, 1);
    assertSuggestName('aaa');
  }

  test_VariableDeclaration_short_semicolon() async {
    addTestSource('''
    AAA a^;
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset-1);
    expect(replacementLength, 1);
    assertSuggestName('aaa');
  }

}
