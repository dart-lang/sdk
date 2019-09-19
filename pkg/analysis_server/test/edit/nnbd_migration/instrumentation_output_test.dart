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
  test_outputContainsModifiedAndUnmodifiedRegions() async {
    LibraryInfo info = LibraryInfo([
      UnitInfo('/lib/a.dart', 'int? a = null;',
          [RegionInfo(3, 1, 'null was assigned')]),
    ]);
    String output = InstrumentationRenderer(info).render();
    expect(
        output,
        contains('int<span class="region">?'
            '<span class="tooltip">null was assigned</span></span> a = null;'));
  }

  test_outputContainsEachPath() async {
    LibraryInfo info = LibraryInfo([
      UnitInfo('/lib/a.dart', 'int? a = null;',
          [RegionInfo(3, 1, 'null was assigned')]),
      UnitInfo('/lib/part1.dart', 'int? b = null;',
          [RegionInfo(3, 1, 'null was assigned')]),
      UnitInfo('/lib/part2.dart', 'int? c = null;',
          [RegionInfo(3, 1, 'null was assigned')]),
    ]);
    String output = InstrumentationRenderer(info).render();
    expect(output, contains('<h2>&#x2F;lib&#x2F;a.dart</h2>'));
    expect(output, contains('<h2>&#x2F;lib&#x2F;part1.dart</h2>'));
    expect(output, contains('<h2>&#x2F;lib&#x2F;part2.dart</h2>'));
  }
}
