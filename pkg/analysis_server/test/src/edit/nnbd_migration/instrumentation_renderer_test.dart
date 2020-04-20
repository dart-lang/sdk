// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstrumentationRendererTest);
  });
}

@reflectiveTest
class InstrumentationRendererTest extends NnbdMigrationTestBase {
  /// Render the instrumentation view for [files].
  Future<String> renderViewForTestFiles(Map<String, String> files,
      {bool applied = false, bool needsRerun = false}) async {
    var packageRoot = convertPath('/project');
    await buildInfoForTestFiles(files, includedRoot: packageRoot);
    var migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    var instrumentationRenderer = InstrumentationRenderer(
        migrationInfo, PathMapper(resourceProvider), applied, needsRerun);
    return instrumentationRenderer.render();
  }

  Future<void> test_appliedStyle() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/lib/a.dart'): 'int a = null;'},
        applied: true);
    // harmless space in class list due to other potential classes here.
    expect(renderedView, contains('<body class="applied ">'));
  }

  Future<void> test_navigation_containsRoot() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/lib/a.dart'): 'int a = null;'});
    var expectedPath = convertPath('/project');
    // harmless space in class list due to other potential classes here.
    expect(renderedView, contains('<p class="root">$expectedPath</p>'));
  }

  Future<void> test_needsRerunStyle() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/lib/a.dart'): 'int a = null;'},
        needsRerun: true);
    expect(renderedView, contains('<body class="proposed needs-rerun">'));
  }

  Future<void> test_notAppliedStyle() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/lib/a.dart'): 'int a = null;'},
        applied: false);
    // harmless space in class list due to other potential classes here.
    expect(renderedView, contains('<body class="proposed ">'));
  }
}
