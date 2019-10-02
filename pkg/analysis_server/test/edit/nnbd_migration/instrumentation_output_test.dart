// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstrumentationRendererTest);
  });
}

@reflectiveTest
class InstrumentationRendererTest extends AbstractAnalysisTest {
  /// Render [libraryInfo], using a [MigrationInfo] which knows only about this
  /// library.
  // TODO(srawlins): Add tests for navigation links, which use multiple
  // libraries.
  List<String> renderLibrary(LibraryInfo libraryInfo) {
    String packageRoot = resourceProvider.convertPath('/package');
    String outputDir = resourceProvider.convertPath('/output');
    MigrationInfo migrationInfo = MigrationInfo(
        libraryInfo.units, resourceProvider.pathContext, packageRoot);
    List<String> contents = [];
    for (UnitInfo unitInfo in libraryInfo.units) {
      contents.add(InstrumentationRenderer(unitInfo, migrationInfo,
              PathMapper(resourceProvider, outputDir, packageRoot))
          .render());
    }
    return contents;
  }

  test_outputContainsEachPath() async {
    LibraryInfo info = LibraryInfo([
      unit('/package/lib/a.dart', 'int? a = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
      unit('/package/lib/part1.dart', 'int? b = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
      unit('/package/lib/part2.dart', 'int? c = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
    ]);
    expect(renderLibrary(info)[0], contains('lib/a.dart'));
    expect(renderLibrary(info)[1], contains('lib/part1.dart'));
    expect(renderLibrary(info)[2], contains('lib/part2.dart'));
  }

  test_outputContainsEscapedHtml() async {
    LibraryInfo info = LibraryInfo([
      unit('/package/lib/a.dart', 'List<String>? a = null;',
          regions: [RegionInfo(12, 1, 'null was assigned', [])]),
    ]);
    String output = renderLibrary(info)[0];
    expect(
        output,
        contains('List&lt;String&gt;<span class="region">?'
            '<span class="tooltip">null was assigned<ul></ul></span></span> '
            'a = null;'));
  }

  test_outputContainsEscapedHtml_ampersand() async {
    LibraryInfo info = LibraryInfo([
      unit('/package/lib/a.dart', 'bool a = true && false;', regions: []),
    ]);
    String output = renderLibrary(info)[0];
    expect(output, contains('bool a = true &amp;&amp; false;'));
  }

  test_outputContainsModifiedAndUnmodifiedRegions() async {
    LibraryInfo info = LibraryInfo([
      unit('/package/lib/a.dart', 'int? a = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
    ]);
    String output = renderLibrary(info)[0];
    expect(
        output,
        contains('int<span class="region">?'
            '<span class="tooltip">null was assigned<ul></ul></span></span> '
            'a = null;'));
  }

  UnitInfo unit(String path, String content, {List<RegionInfo> regions}) {
    return UnitInfo(resourceProvider.convertPath(path))
      ..content = content
      ..regions.addAll(regions);
  }
}
