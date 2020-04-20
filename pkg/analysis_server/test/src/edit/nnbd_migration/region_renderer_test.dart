// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/region_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/web/edit_details.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RegionRendererTest);
  });
}

@reflectiveTest
class RegionRendererTest extends NnbdMigrationTestBase {
  /// Render the region at [offset], using a [MigrationInfo] which knows only
  /// about the library at `infos.single`.
  EditDetails renderRegion(int offset) {
    var packageRoot = convertPath('/package');
    var migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    var unitInfo = infos.single;
    var region = unitInfo.regionAt(offset);
    return RegionRenderer(
            region, unitInfo, migrationInfo, PathMapper(resourceProvider))
        .render();
  }

  Future<void> test_modifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = renderRegion(3);
    expect(response.explanation, equals("Changed type 'int' to be nullable"));
  }

  Future<void> test_modifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = renderRegion(3);
    expect(response.path, equals(convertPath('/project/bin/test.dart')));
    expect(response.line, equals(1));
  }

  Future<void> test_unmodifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.explanation, equals("Type 'int' was not made nullable"));
  }

  Future<void> test_unmodifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int  a) => a.isEven;');
    var response = renderRegion(5);
    expect(response.path, equals(convertPath('/project/bin/test.dart')));
    expect(response.line, equals(1));
  }
}
