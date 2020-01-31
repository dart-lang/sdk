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
  Future<String> renderViewForTestFiles(Map<String, String> files) async {
    var packageRoot = convertPath('/project');
    await buildInfoForTestFiles(files, includedRoot: packageRoot);
    var migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    var instrumentationRenderer =
        InstrumentationRenderer(migrationInfo, PathMapper(resourceProvider));
    return instrumentationRenderer.render();
  }

  Future<void> test_navigation_containsMultipleLinks_multipleDepths() async {
    var renderedView = await renderViewForTestFiles({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;'
    });
    renderedView = _stripAttributes(renderedView);
    expect(renderedView, contains('''
<ul>
  <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;lib
    <ul>
      <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;src
        <ul>
          <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">b.dart</a> (1 modification)</li>
        </ul>
      </li>
      <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">a.dart</a> (1 modification)</li>
    </ul>
  </li>
  <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">tool.dart</a> (1 modification)</li>
</ul>'''));
  }

  Future<void> test_navigation_containsMultipleLinks_multipleRoots() async {
    var renderedView = await renderViewForTestFiles({
      convertPath('/project/bin/bin.dart'): 'int c = null;',
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/test/test.dart'): 'int d = null;',
    });
    renderedView = _stripAttributes(renderedView);
    expect(renderedView, contains('''
<ul>
  <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;bin
    <ul>
      <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">bin.dart</a> (1 modification)</li>
    </ul>
  </li>
  <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;lib
    <ul>
      <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;src
        <ul>
          <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">b.dart</a> (1 modification)</li>
        </ul>
      </li>
      <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">a.dart</a> (1 modification)</li>
    </ul>
  </li>
  <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;test
    <ul>
      <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">test.dart</a> (1 modification)</li>
    </ul>
  </li>
</ul>'''));
  }

  Future<void> test_navigation_containsMultipleLinks_sameDepth() async {
    var renderedView = await renderViewForTestFiles({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/b.dart'): 'int b = null;'
    });
    renderedView = _stripAttributes(renderedView);
    expect(renderedView, contains('''
<ul>
  <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;lib
    <ul>
      <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">a.dart</a> (1 modification)</li>
      <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">b.dart</a> (1 modification)</li>
    </ul>
  </li>
</ul>'''));
  }

  Future<void> test_navigation_containsRoot() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/lib/a.dart'): 'int a = null;'});
    var expectedPath = convertPath('/project');
    expect(renderedView, contains('<p class="root">$expectedPath</p>'));
  }

  Future<void> test_navigation_containsSingleLink_deep() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/lib/src/a.dart'): 'int a = null;'});
    renderedView = _stripAttributes(renderedView);
    expect(renderedView, contains('''
<ul>
  <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;lib
    <ul>
      <li class="dir"><span class="arrow">&#x25BC;</span>&#x1F4C1;src
        <ul>
          <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">a.dart</a> (1 modification)</li>
        </ul>
      </li>
    </ul>
  </li>
</ul>'''));
  }

  Future<void> test_navigation_containsSingleLink_shallow() async {
    var renderedView = await renderViewForTestFiles(
        {convertPath('/project/a.dart'): 'int a = null;'});
    renderedView = _stripAttributes(renderedView);
    expect(renderedView, contains('''
<ul>
  <li>&#x1F4C4;<a href="..." class="nav-link" data-name="...">a.dart</a> (1 modification)</li>
</ul>'''));
  }

  /// Strips out attributes which are not being tested.
  String _stripAttributes(String html) => html
      .replaceAll(RegExp('href=".*?"'), 'href="..."')
      .replaceAll(RegExp('data-name=".*?"'), 'data-name="..."');
}
