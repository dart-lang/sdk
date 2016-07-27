// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.manager;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/imported_reference_contributor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../../utils.dart';
import 'completion_contributor_util.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(CompletionManagerTest);
}

@reflectiveTest
class CompletionManagerTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new ImportedReferenceContributor();
  }

  test_resolveDirectives() async {
    addSource(
        '/libA.dart',
        '''
library libA;
/// My class.
/// Short description.
///
/// Longer description.
class A {}
''');
    var libSource = addSource(
        '/libB.dart',
        '''
library libB;
import "/libA.dart" as foo;
part '$testFile';
''');
    addTestSource('part of libB; main() {^}');

    // Associate part with library
    context.computeResult(libSource, LIBRARY_CYCLE_UNITS);

    // Build the request
    CompletionRequestImpl baseRequest = new CompletionRequestImpl(
        context,
        provider,
        searchEngine,
        testSource,
        completionOffset,
        new CompletionPerformance());
    Completer<DartCompletionRequest> requestCompleter =
        new Completer<DartCompletionRequest>();
    DartCompletionRequestImpl
        .from(baseRequest, resultDescriptor: RESOLVED_UNIT1)
        .then((DartCompletionRequest request) {
      requestCompleter.complete(request);
    });
    request = await performAnalysis(200, requestCompleter);

    // Get the unresolved directives
    var directives = request.target.unit.directives;

    // Assert that the import does not have an export namespace
    expect(directives[0].element?.library?.exportNamespace, isNull);

    // Resolve directives
    var importCompleter = new Completer<List<ImportElement>>();
    request.resolveImports().then((List<ImportElement> elements) {
      importCompleter.complete(elements);
    });
    List<ImportElement> imports = await performAnalysis(200, importCompleter);
    expect(imports, hasLength(directives.length + 1));

    ImportElement importNamed(String expectedUri) {
      return imports.firstWhere((elem) => elem.uri == expectedUri, orElse: () {
        var importedNames = imports.map((elem) => elem.uri);
        fail('Failed to find $expectedUri in $importedNames');
      });
    }
    void assertImportedLib(String expectedUri) {
      ImportElement importElem = importNamed(expectedUri);
      expect(importElem.importedLibrary.exportNamespace, isNotNull);
    }

    // Assert that the new imports each have an export namespace
    assertImportedLib(null /* dart:core */);
    assertImportedLib('/libA.dart');
  }
}
