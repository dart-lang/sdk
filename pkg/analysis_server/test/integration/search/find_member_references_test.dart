// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FindMemberReferencesTest);
  });
}

@reflectiveTest
class FindMemberReferencesTest extends AbstractAnalysisServerIntegrationTest {
  String pathname;

  test_findMemberReferences() async {
    String text = r'''
String qux() => 'qux';

class Foo {
  //int bar() => 1;
  baz() => bar() * bar();
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    SearchFindMemberReferencesResult referencesResult =
        await sendSearchFindMemberReferences('bar');
    expect(referencesResult.id, isNotNull);

    SearchResultsParams searchParams = await onSearchResults.first;
    expect(searchParams.id, referencesResult.id);
    expect(searchParams.isLast, isTrue);
    expect(searchParams.results, isNotEmpty);
    expect(searchParams.results, hasLength(2));

    SearchResult result = searchParams.results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isTrue);
    expect(result.kind.name, SearchResultKind.INVOCATION.name);
    expect(result.path.first.name, 'baz');
  }
}
