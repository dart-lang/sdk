// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/imported_reference_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionManagerTest);
  });
}

@reflectiveTest
class CompletionManagerTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return ImportedReferenceContributor(request, builder);
  }

  Future<void> test_resolveDirectives() async {
    newFile('$testPackageLibPath/a.dart', '''
library libA;
/// My class.
/// Short description.
///
/// Longer description.
class A {}
''');
    newFile('$testPackageLibPath/b.dart', '''
library libB;
import "a.dart" as foo;
part 'test.dart';
''');
    addTestSource('part of libB; void f() {^}');

    await resolveFile('$testPackageLibPath/b.dart');

    // Build the request
    var resolvedUnit = await getResolvedUnit(testFile.path);
    request = DartCompletionRequest.forResolvedUnit(
      resolvedUnit: resolvedUnit,
      offset: completionOffset,
    );

    var directives = resolvedUnit.unit.directives;

    var imports = request.libraryElement.libraryImports;
    expect(imports, hasLength(directives.length + 1));

    LibraryImportElement importNamed(String expectedUri) {
      var uriList = <String>[];
      for (var importElement in imports) {
        var uri = importElement.importedLibrary!.source.uri.toString();
        uriList.add(uri);
        if (uri.endsWith(expectedUri)) {
          return importElement;
        }
      }
      fail('Failed to find $expectedUri in $uriList');
    }

    void assertImportedLib(String expectedUri) {
      var importElem = importNamed(expectedUri);
      expect(importElem.importedLibrary!.exportNamespace, isNotNull);
    }

    // Assert that the new imports each have an export namespace
    assertImportedLib('dart:core');
    assertImportedLib('a.dart');
  }
}
