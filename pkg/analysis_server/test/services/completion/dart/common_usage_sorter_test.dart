// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/common_usage_sorter.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../domain_completion_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommonUsageSorterTest);
  });
}

@reflectiveTest
class CommonUsageSorterTest extends AbstractCompletionDomainTest {
  Future getSuggestionsWith(Map<String, List<String>> selectorRelevance) async {
    var originalSorter = DartCompletionManager.contributionSorter;
    DartCompletionManager.contributionSorter =
        new CommonUsageSorter(selectorRelevance);
    try {
      return await getSuggestions();
    } finally {
      DartCompletionManager.contributionSorter = originalSorter;
    }
  }

  test_ConstructorName() async {
    // SimpleIdentifier  ConstructorName  InstanceCreationExpression
    addTestFile('import "dart:async"; class A {x() {new Future.^}}');
    await getSuggestionsWith({
      'dart.async.Future': ['value', 'wait']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'delayed');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'value',
        relevance: DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_field() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('class A {static int s1; static int s2; x() {A.^}}');
    await getSuggestionsWith({
      '.A': ['s2']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's1');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's2',
        relevance: DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_field_inPart() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addFile('/project/bin/myLib.dart',
        'library L; part "$testFile"; class A {static int s2;}');
    addTestFile('part of L; foo() {A.^}');
    await getSuggestionsWith({
      'L.A': ['s2']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's2',
        relevance: DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_getter() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('class A {int get g1 => 1; int get g2 => 2; x() {new A().^}}');
    await getSuggestionsWith({
      '.A': ['g2']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'g1');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'g2',
        relevance: DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_setter() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('class A {set s1(v) {}; set s2(v) {}; x() {new A().^}}');
    await getSuggestionsWith({
      '.A': ['s2']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's1');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 's2',
        relevance: DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PrefixedIdentifier_static_method() async {
    // SimpleIdentifier  PrefixedIdentifeir  ExpressionStatement
    addTestFile('import "dart:async"; class A {x() {Future.^}}');
    await getSuggestionsWith({
      'dart.async.Future': ['value', 'wait']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'wait',
        relevance: DART_RELEVANCE_COMMON_USAGE - 1);
    assertNoResult('Future');
    assertNoResult('Object');
    assertNoResult('A');
  }

  test_PropertyAccess() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestFile('import "dart:math"; class A {x() {new Random().^}}');
    await getSuggestionsWith({
      'dart.math.Random': ['nextInt', 'nextDouble']
    });
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'nextBool');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'nextDouble',
        relevance: DART_RELEVANCE_COMMON_USAGE - 1);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'nextInt',
        relevance: DART_RELEVANCE_COMMON_USAGE);
    assertNoResult('Random');
    assertNoResult('Object');
    assertNoResult('A');
  }
}
