// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/unit_renderer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnitRendererTest);
  });
}

@reflectiveTest
class UnitRendererTest extends NnbdMigrationTestBase {
  /// Render [libraryInfo], using a [MigrationInfo] which knows only about this
  /// library.
  // TODO(srawlins): Add tests for navigation links, which use multiple
  //  libraries.
  List<String> renderUnits() {
    String packageRoot = convertPath('/package');
    MigrationInfo migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);

    List<String> contents = [];
    for (UnitInfo unitInfo in infos) {
      contents.add(
          UnitRenderer(unitInfo, migrationInfo, PathMapper(resourceProvider))
              .render());
    }
    return contents;
  }

  test_navContentContainsEscapedHtml() async {
    await buildInfoForSingleTestFile('List<String> a = null;',
        migratedContent: 'List<String>? a = null;');
    var outputJson = renderUnits()[0];

    var output = jsonDecode(outputJson);
    // Strip out URLs which will change; not being tested here.
    var navContent =
        output['navContent'].replaceAll(RegExp('href=".*?"'), 'href="..."');
    expect(
        navContent,
        contains(r'<a href="..." class="nav-link">List</a>'
            r'&lt;<a href="..." class="nav-link">String</a>&gt;? '
            r'<span id="o13">a</span> = <span id="o17">null</span>;'));
  }

  test_outputContainsModifiedAndUnmodifiedRegions() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var outputJson = renderUnits()[0];
    var output = jsonDecode(outputJson);
    // Strip out tooltips which are lengthy and are not being tested here.
    var regions = output['regions']
        .replaceAll(RegExp('<span class="tooltip">.*?</span>'), '');
    expect(regions,
        contains('int<span class="region fix-region">?</span> a = null;'));
  }

  test_regionsContainsEscapedHtml_tooltip() async {
    await buildInfoForSingleTestFile('List<String> a = null;',
        migratedContent: 'List<String>? a = null;');
    var outputJson = renderUnits()[0];
    var output = jsonDecode(outputJson);
    expect(
        output['regions'],
        contains('<span class="tooltip">'
            "<p>Changed type 'List&lt;String&gt;' to be nullable.</p>"
            "<ul><li>This variable is initialized to an explicit 'null' "
            '(<a href="test.dart?offset=17&line=1" '
            'class="nav-link">test.dart</a>)</li></ul></span>'));
  }

  test_regionsContainsEscapedHtml() async {
    await buildInfoForSingleTestFile('List<String> a = null;',
        migratedContent: 'List<String>? a = null;');
    var outputJson = renderUnits()[0];
    var output = jsonDecode(outputJson);
    // Strip out tooltips which are lengthy and are not being tested here.
    var regions = output['regions']
        .replaceAll(RegExp('<span class="tooltip">.*?</span>'), '');
    expect(
        regions,
        contains('List&lt;String&gt;'
            '<span class="region fix-region">?</span> a = null;'));
  }

  test_regionsContainsEscapedHtml_ampersand() async {
    await buildInfoForSingleTestFile('bool a = true && false;',
        migratedContent: 'bool a = true && false;');
    var outputJson = renderUnits()[0];
    var output = jsonDecode(outputJson);
    expect(output['regions'], contains('bool a = true &amp;&amp; false;'));
  }

  UnitInfo unit(String path, String content, {List<RegionInfo> regions}) {
    return UnitInfo(convertPath(path))
      ..content = content
      ..regions.addAll(regions);
  }
}
