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
    String packageRoot = convertPath('/package');
    String outputDir = convertPath('/output');
    MigrationInfo migrationInfo = MigrationInfo(
        libraryInfo.units, {}, resourceProvider.pathContext, packageRoot);
    List<String> contents = [];
    for (UnitInfo unitInfo in libraryInfo.units) {
      contents.add(InstrumentationRenderer(unitInfo, migrationInfo,
              PathMapper(resourceProvider, outputDir, packageRoot))
          .render());
    }
    return contents;
  }

  test_outputContainsEachPath() async {
    String convert(String path) => path.replaceAll('/', '&#x2F;');

    LibraryInfo info = LibraryInfo({
      unit('/package/lib/a.dart', 'int? a = null;',
          regions: [RegionInfo(RegionType.fix, 3, 1, 'null was assigned', [])]),
      unit('/package/lib/part1.dart', 'int? b = null;',
          regions: [RegionInfo(RegionType.fix, 3, 1, 'null was assigned', [])]),
      unit('/package/lib/part2.dart', 'int? c = null;',
          regions: [RegionInfo(RegionType.fix, 3, 1, 'null was assigned', [])]),
    });
    List<String> contents = renderLibrary(info);
    expect(contents[0], contains(convert('lib/a.dart')));
    expect(contents[1], contains(convert('lib/part1.dart')));
    expect(contents[2], contains(convert('lib/part2.dart')));
  }

  test_outputContainsEscapedHtml() async {
    LibraryInfo info = LibraryInfo({
      unit('/package/lib/a.dart', 'List<String>? a = null;', regions: [
        RegionInfo(RegionType.fix, 12, 1, 'null was assigned', [])
      ]),
    });
    String output = renderLibrary(info)[0];
    expect(
        output,
        contains('List&lt;String&gt;<span class="region fix-region">?'
            '<span class="tooltip"><p>null was assigned</p>'
            '</span></span> a = null;'));
  }

  test_outputContainsEscapedHtml_ampersand() async {
    LibraryInfo info = LibraryInfo({
      unit('/package/lib/a.dart', 'bool a = true && false;', regions: []),
    });
    String output = renderLibrary(info)[0];
    expect(output, contains('bool a = true &amp;&amp; false;'));
  }

  test_outputContainsModifiedAndUnmodifiedRegions() async {
    LibraryInfo info = LibraryInfo({
      unit('/package/lib/a.dart', 'int? a = null;',
          regions: [RegionInfo(RegionType.fix, 3, 1, 'null was assigned', [])]),
    });
    String output = renderLibrary(info)[0];
    expect(
        output,
        contains('int<span class="region fix-region">?'
            '<span class="tooltip"><p>null was assigned</p>'
            '</span></span> a = null;'));
  }

  UnitInfo unit(String path, String content, {List<RegionInfo> regions}) {
    return UnitInfo(convertPath(path))
      ..content = content
      ..regions.addAll(regions);
  }
}
