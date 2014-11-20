// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_server/src/services/completion/imported_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ImportedTypeComputerTest);
}

@ReflectiveTestCase()
class ImportedTypeComputerTest extends AbstractSelectorSuggestionTest {

  @override
  void setUpComputer() {
    computer = new ImportedComputer();
  }

  /**
   * Assert that the ImportedComputer uses cached results to produce identical
   * suggestions to the original set of suggestions.
   */
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
        cache);
    expect(computeFast(), isTrue);
    expect(request.unit.element, isNull);
    List<CompletionSuggestion> newSuggestions = request.suggestions;
    expect(newSuggestions.length, oldSuggestions.length);
    oldSuggestions.forEach((CompletionSuggestion s) {
      expect(newSuggestions.contains(s), isTrue);
    });
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
      expect(request.cache.importKey, 'import "/testAB.dart";import "/testCD.dart" hide D;import "/testEEF.dart" show EE;import "/testG.dart" as g;');
    });
  }
}
