// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/region_renderer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RegionRendererTest);
  });
}

@reflectiveTest
class RegionRendererTest extends NnbdMigrationTestBase {
  /// Render [libraryInfo], using a [MigrationInfo] which knows only about this
  /// library.
  String renderRegion(int offset) {
    String packageRoot = convertPath('/package');
    MigrationInfo migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    var unitInfo = infos.single;
    var region = unitInfo.regionAt(offset);
    return RegionRenderer(
            region, unitInfo, migrationInfo, PathMapper(resourceProvider))
        .render();
  }

  test_modifiedOutput_containsDetail() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var output = renderRegion(3);
    expect(
        output,
        contains("<ul><li>This variable is initialized to an explicit 'null' "
            '(<a href="test.dart?offset=8&line=1" class="nav-link">'
            'test.dart</a>)</li></ul>'));
  }

  test_modifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var output = renderRegion(3);
    expect(output, contains("<p>Changed type 'int' to be nullable.</p>"));
  }

  test_modifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var output = renderRegion(3);
    var path = convertPath('/project/bin/test.dart');
    expect(output, contains('<p class="region-location">$path line 1</p>'));
  }

  test_unmodifiedOutput_containsDetail() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int a) => a.isEven;');
    var output = renderRegion(2);
    expect(
        output,
        contains('<ul><li>This value is unconditionally used in a '
            'non-nullable context '
            '(<a href="test.dart?offset=12&line=1" class="nav-link">test.dart'
            '</a>)</li></ul>'));
  }

  test_unmodifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int a) => a.isEven;');
    var output = renderRegion(2);
    expect(
        output,
        contains('<p>This type is not changed; it is determined to '
            'be non-nullable</p>'));
  }

  test_unmodifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int a) => a.isEven;');
    var output = renderRegion(2);
    var path = convertPath('/project/bin/test.dart');
    expect(output, contains('<p class="region-location">$path line 1</p>'));
  }
}
