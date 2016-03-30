// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.in_summary_source_test;

import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(InSummarySourceTest);
}

@reflectiveTest
class InSummarySourceTest extends ReflectiveTest {
  test_fallbackPath() {
    String fooFallbackPath = absolute('path', 'to', 'foo.dart');
    var sourceFactory = new SourceFactory([
      new InSummaryPackageUriResolver(new MockSummaryDataStore.fake(
          {'package:foo/foo.dart': 'foo.sum',},
          uriToFallbackModePath: {'package:foo/foo.dart': fooFallbackPath}))
    ]);

    InSummarySource source = sourceFactory.forUri('package:foo/foo.dart');
    expect(source, new isInstanceOf<FileBasedSource>());
    expect(source.fullName, fooFallbackPath);
  }

  test_InSummarySource() {
    var sourceFactory = new SourceFactory([
      new InSummaryPackageUriResolver(new MockSummaryDataStore.fake({
        'package:foo/foo.dart': 'foo.sum',
        'package:foo/src/foo_impl.dart': 'foo.sum',
        'package:bar/baz.dart': 'bar.sum',
      }))
    ]);

    InSummarySource source = sourceFactory.forUri('package:foo/foo.dart');
    expect(source, isNot(new isInstanceOf<FileBasedSource>()));
    expect(source.summaryPath, 'foo.sum');

    source = sourceFactory.forUri('package:foo/src/foo_impl.dart');
    expect(source, isNot(new isInstanceOf<FileBasedSource>()));
    expect(source.summaryPath, 'foo.sum');

    source = sourceFactory.forUri('package:bar/baz.dart');
    expect(source, isNot(new isInstanceOf<FileBasedSource>()));
    expect(source.summaryPath, 'bar.sum');
  }
}

class MockSummaryDataStore implements SummaryDataStore {
  final Map<String, LinkedLibrary> linkedMap;
  final Map<String, UnlinkedUnit> unlinkedMap;
  final Map<String, String> uriToSummaryPath;

  MockSummaryDataStore(this.linkedMap, this.unlinkedMap, this.uriToSummaryPath);

  factory MockSummaryDataStore.fake(Map<String, String> uriToSummary,
      {Map<String, String> uriToFallbackModePath: const {}}) {
    // Create fake unlinked map.
    // We don't populate the values as it is not needed for the test.
    var unlinkedMap = new Map<String, UnlinkedUnit>.fromIterable(
        uriToSummary.keys,
        value: (uri) => new UnlinkedUnitBuilder(
            fallbackModePath: uriToFallbackModePath[uri]));
    return new MockSummaryDataStore(null, unlinkedMap, uriToSummary);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
