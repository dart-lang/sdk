// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains tests written in a deprecated way. Please do not add any
/// tests to this file. Instead, add tests to the files in `declaration`,
/// `location`, or `relevance`.
library;

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/closure_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosureContributorTest);
  });
}

@reflectiveTest
class ClosureContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return ClosureContributor(request, builder);
  }

  Future<void> test_argumentList_named() async {
    addTestSource(r'''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ,',
      selectionOffset: 10,
    );

    assertSuggest(
      '''
(a, b) {
${' ' * 4}
${' ' * 2}},''',
      selectionOffset: 13,
    );
  }

  Future<void> test_argumentList_named_hasComma() async {
    addTestSource(r'''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(
    closure: ^,
  );
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ',
      selectionOffset: 10,
    );

    assertSuggest(
      '''
(a, b) {
${' ' * 6}
${' ' * 4}}''',
      selectionOffset: 15,
    );
  }

  Future<void> test_argumentList_positional() async {
    addTestSource(r'''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ,',
      selectionOffset: 10,
    );
  }

  Future<void> test_argumentList_positional_hasComma() async {
    addTestSource(r'''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^,);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ',
      selectionOffset: 10,
    );
  }

  Future<void> test_parameters_optionalNamed() async {
    addTestSource(r'''
void f({void Function(int a, {int b, int c}) closure}) {}

void g() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, {b, c}) => ,',
      selectionOffset: 15,
    );
  }

  Future<void> test_parameters_optionalPositional() async {
    addTestSource(r'''
void f({void Function(int a, [int b, int c]) closure]) {}

void g() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, [b, c]) => ,',
      selectionOffset: 15,
    );
  }

  Future<void> test_variableInitializer() async {
    addTestSource(r'''
void Function(int a, int b) v = ^;
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ',
      selectionOffset: 10,
    );
  }
}
