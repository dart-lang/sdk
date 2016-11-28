// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.in_summary_source_test;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InSummarySourceTest);
  });
}

@reflectiveTest
class InSummarySourceTest extends ReflectiveTest {
  test_InSummarySource() {
    var sourceFactory = new SourceFactory([
      new InSummaryUriResolver(
          PhysicalResourceProvider.INSTANCE,
          new MockSummaryDataStore.fake({
            'package:foo/foo.dart': 'foo.sum',
            'package:foo/src/foo_impl.dart': 'foo.sum',
            'package:bar/baz.dart': 'bar.sum',
          }))
    ]);

    InSummarySource source = sourceFactory.forUri('package:foo/foo.dart');
    expect(source, isNotNull);
    expect(source.summaryPath, 'foo.sum');

    source = sourceFactory.forUri('package:foo/src/foo_impl.dart');
    expect(source, isNotNull);
    expect(source.summaryPath, 'foo.sum');

    source = sourceFactory.forUri('package:bar/baz.dart');
    expect(source, isNotNull);
    expect(source.summaryPath, 'bar.sum');
  }
}

class MockSummaryDataStore implements SummaryDataStore {
  final Map<String, LinkedLibrary> linkedMap;
  final Map<String, UnlinkedUnit> unlinkedMap;
  final Map<String, String> uriToSummaryPath;

  MockSummaryDataStore(this.linkedMap, this.unlinkedMap, this.uriToSummaryPath);

  factory MockSummaryDataStore.fake(Map<String, String> uriToSummary) {
    // Create fake unlinked map.
    // We don't populate the values as it is not needed for the test.
    var unlinkedMap = new Map<String, UnlinkedUnit>.fromIterable(
        uriToSummary.keys,
        value: (uri) => new UnlinkedUnitBuilder());
    return new MockSummaryDataStore(null, unlinkedMap, uriToSummary);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
