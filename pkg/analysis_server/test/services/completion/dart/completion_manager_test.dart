// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/imported_reference_contributor.dart';
import 'package:analyzer/dart/element/element.dart';
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
    addSource('/home/test/lib/a.dart', '''
library libA;
/// My class.
/// Short description.
///
/// Longer description.
class A {}
''');
    addSource('/home/test/lib/b.dart', '''
library libB;
import "a.dart" as foo;
part 'test.dart';
''');
    addTestSource('part of libB; main() {^}');

    // Build the request
    CompletionRequestImpl baseRequest = new CompletionRequestImpl(
        await session.getResolvedUnit(testFile),
        completionOffset,
        new CompletionPerformance());
    Completer<DartCompletionRequest> requestCompleter =
        new Completer<DartCompletionRequest>();
    DartCompletionRequestImpl.from(baseRequest)
        .then((DartCompletionRequest request) {
      requestCompleter.complete(request);
    });
    request = await performAnalysis(200, requestCompleter);

    var directives = request.target.unit.directives;

    List<ImportElement> imports = request.libraryElement.imports;
    expect(imports, hasLength(directives.length + 1));

    ImportElement importNamed(String expectedUri) {
      List<String> uriList = <String>[];
      for (ImportElement importElement in imports) {
        String uri = importElement.importedLibrary.source.uri.toString();
        uriList.add(uri);
        if (uri.endsWith(expectedUri)) {
          return importElement;
        }
      }
      fail('Failed to find $expectedUri in $uriList');
    }

    void assertImportedLib(String expectedUri) {
      ImportElement importElem = importNamed(expectedUri);
      expect(importElem.importedLibrary.exportNamespace, isNotNull);
    }

    // Assert that the new imports each have an export namespace
    assertImportedLib('dart:core');
    assertImportedLib('a.dart');
  }
}
