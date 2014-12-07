// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart_completion_cache.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ImportedComputerTest);
}

@ReflectiveTestCase()
class ImportedComputerTest extends AbstractSelectorSuggestionTest {

  void assertCached(String completion) {
    DartCompletionCache cache = request.cache;
    if (!isCached(cache.importedTypeSuggestions, completion) &&
        !isCached(cache.importedVoidReturnSuggestions, completion) &&
        !isCached(cache.libraryPrefixSuggestions, completion) &&
        !isCached(cache.otherImportedSuggestions, completion)) {
      fail('expected $completion to be cached');
    }
  }

  /**
   * Assert that the ImportedComputer uses cached results to produce identical
   * suggestions to the original set of suggestions.
   */
  @override
  void assertCachedCompute(_) {
    expect(request.unit.element, isNotNull);
    List<CompletionSuggestion> oldSuggestions = request.suggestions;
    /*
     * Simulate a source change to flush the cached compilation unit
     */
    ChangeSet changes = new ChangeSet();
    changes.addedSource(testSource);
    context.applyChanges(changes);
    /*
     * Calculate a new completion at the same location
     */
    setUpComputer();
    request = new DartCompletionRequest(
        context,
        searchEngine,
        testSource,
        completionOffset,
        cache,
        new CompletionPerformance());
    expect(computeFast(), isTrue);
    expect(request.unit.element, isNull);
    List<CompletionSuggestion> newSuggestions = request.suggestions;
    if (newSuggestions.length == oldSuggestions.length) {
      if (!oldSuggestions.any(
          (CompletionSuggestion s) => !newSuggestions.contains(s))) {
        return;
      }
    }
    StringBuffer sb = new StringBuffer(
        'suggestions based upon cached results do not match expectations');
    sb.write('\n  Expected:');
    oldSuggestions.toList()
        ..sort(suggestionComparator)
        ..forEach((CompletionSuggestion suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
    sb.write('\n  Actual:');
    newSuggestions.toList()
        ..sort(suggestionComparator)
        ..forEach((CompletionSuggestion suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
    fail(sb.toString());
  }

  void assertNotCached(String completion) {
    DartCompletionCache cache = request.cache;
    if (isCached(cache.importedTypeSuggestions, completion) ||
        isCached(cache.importedVoidReturnSuggestions, completion) ||
        isCached(cache.libraryPrefixSuggestions, completion) ||
        isCached(cache.otherImportedSuggestions, completion)) {
      fail('expected $completion NOT to be cached');
    }
  }

  bool isCached(List<CompletionSuggestion> suggestions, String completion) =>
      suggestions.any((CompletionSuggestion s) => s.completion == completion);

  @override
  void setUpComputer() {
    computer = new ImportedComputer();
  }

  @override
  test_ArgumentList() {
    return super.test_ArgumentList().then((_) {
      expect(request.cache.importKey, "import '/libA.dart';");
    });
  }

  @override
  test_ArgumentList_imported_function() {
    return super.test_ArgumentList_imported_function().then((_) {
      expect(request.cache.importKey, "import '/libA.dart';");
    });
  }

  @override
  test_AssignmentExpression_RHS() {
    return super.test_AssignmentExpression_RHS().then((_) {
      expect(request.cache.importKey, '');
    });
  }

  @override
  test_Block() {
    return super.test_Block().then((_) {
      expect(
          request.cache.importKey,
          'import "/testAB.dart";import "/testCD.dart" hide D;import "/testEEF.dart" show EE;import "/testG.dart" as g;');
      assertCached('A');
      assertCached('T3');
    });
  }

  @override
  test_Block_inherited_imported() {
    return super.test_Block_inherited_imported().then((_) {
      assertCached('E');
      assertCached('F');
      assertNotCached('e1');
      assertNotCached('i2');
      assertNotCached('m1');
    });
  }
}
