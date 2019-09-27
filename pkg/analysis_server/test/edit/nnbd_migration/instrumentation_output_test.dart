// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
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
  test_outputContainsEachPath() async {
    LibraryInfo info = LibraryInfo([
      unit('/lib/a.dart', 'int? a = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
      unit('/lib/part1.dart', 'int? b = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
      unit('/lib/part2.dart', 'int? c = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
    ]);
    String output = InstrumentationRenderer(info).render();
    expect(output, contains('<h2>/lib/a.dart</h2>'));
    expect(output, contains('<h2>/lib/part1.dart</h2>'));
    expect(output, contains('<h2>/lib/part2.dart</h2>'));
  }

  test_outputContainsEscapedHtml() async {
    LibraryInfo info = LibraryInfo([
      unit('/lib/a.dart', 'List<String>? a = null;',
          regions: [RegionInfo(12, 1, 'null was assigned', [])]),
    ]);
    String output = InstrumentationRenderer(info).render();
    expect(
        output,
        contains('List&lt;String&gt;<span class="region">?'
            '<span class="tooltip">null was assigned</span></span> a = null;'));
  }

  test_outputContainsEscapedHtml_ampersand() async {
    LibraryInfo info = LibraryInfo([
      unit('/lib/a.dart', 'bool a = true && false;', regions: []),
    ]);
    String output = InstrumentationRenderer(info).render();
    expect(output, contains('bool a = true &amp;&amp; false;'));
  }

  test_outputContainsModifiedAndUnmodifiedRegions() async {
    LibraryInfo info = LibraryInfo([
      unit('/lib/a.dart', 'int? a = null;',
          regions: [RegionInfo(3, 1, 'null was assigned', [])]),
    ]);
    String output = InstrumentationRenderer(info).render();
    expect(
        output,
        contains('int<span class="region">?'
            '<span class="tooltip">null was assigned</span></span> a = null;'));
  }

  UnitInfo unit(String path, String content, {List<RegionInfo> regions}) {
    return UnitInfo(path)
      ..content = content
      ..regions.addAll(regions);
  }
}
