// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FindElementReferencesTest);
  });
}

@reflectiveTest
class FindElementReferencesTest extends AbstractAnalysisServerIntegrationTest {
  String pathname;

  test_badTarget() async {
    String text = r'''
main() {
  if /* target */ (true) {
    print('Hello');
  }
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    List<SearchResult> results = await _findElementReferences(text);
    expect(results, isNull);
  }

  test_findReferences() async {
    String text = r'''
main() {
  print /* target */ ('Hello');
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    List<SearchResult> results = await _findElementReferences(text);
    expect(results, hasLength(1));
    SearchResult result = results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.INVOCATION.name);
    expect(result.path.first.name, 'main');
  }

  Future<List<SearchResult>> _findElementReferences(String text) async {
    int offset = text.indexOf(' /* target */') - 1;
    SearchFindElementReferencesResult result =
        await sendSearchFindElementReferences(pathname, offset, false);
    if (result.id == null) return null;
    SearchResultsParams searchParams = await onSearchResults.first;
    expect(searchParams.id, result.id);
    expect(searchParams.isLast, isTrue);
    return searchParams.results;
  }
}
