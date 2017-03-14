// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FindMemberDeclarationsTest);
  });
}

@reflectiveTest
class FindMemberDeclarationsTest extends AbstractAnalysisServerIntegrationTest {
  String pathname;

  test_findMemberDeclarations() async {
    String text = r'''
String qux() => 'qux';

class Foo {
  void bar() { };
  int baz() => 0;
}
''';

    pathname = sourcePath('foo.dart');
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    SearchFindMemberDeclarationsResult declarationsResult =
        await sendSearchFindMemberDeclarations('bar');
    expect(declarationsResult.id, isNotNull);

    SearchResultsParams searchParams = await onSearchResults.first;
    expect(searchParams.id, declarationsResult.id);
    expect(searchParams.isLast, isTrue);
    expect(searchParams.results, isNotEmpty);

    SearchResult result = searchParams.results.first;
    expect(result.location.file, pathname);
    expect(result.isPotential, isFalse);
    expect(result.kind.name, SearchResultKind.DECLARATION.name);
    expect(result.path.first.name, 'bar');
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
