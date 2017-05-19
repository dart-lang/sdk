// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/imported_reference_contributor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionManagerTest);
  });
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
    addSource(
        '/libB.dart',
        '''
library libB;
import "/libA.dart" as foo;
part '$testFile';
''');
    addTestSource('part of libB; main() {^}');

    // Build the request
    CompletionRequestImpl baseRequest = new CompletionRequestImpl(
        await driver.getResult(testFile),
        provider,
        testSource,
        completionOffset,
        new CompletionPerformance(),
        null);
    Completer<DartCompletionRequest> requestCompleter =
        new Completer<DartCompletionRequest>();
    DartCompletionRequestImpl
        .from(baseRequest, resultDescriptor: RESOLVED_UNIT1)
        .then((DartCompletionRequest request) {
      requestCompleter.complete(request);
    });
    request = await performAnalysis(200, requestCompleter);

    var directives = request.target.unit.directives;

    List<ImportElement> imports = request.libraryElement.imports;
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
