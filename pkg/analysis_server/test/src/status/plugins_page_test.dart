// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/plugins_page.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import 'test_socket_server.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginsPageTest);
  });
}

@reflectiveTest
class PluginsPageTest extends PubPackageAnalysisServerTest {
  late DiagnosticsSite site;
  late PluginsPage page;

  @override
  void setUp() {
    super.setUp();
    site = DiagnosticsSite(TestSocketServer(server), []);
    page = PluginsPage(site, server);
  }

  Future<void> test_configuredPlugins_escaped() async {
    writeTestPackageAnalysisOptionsFile('''
plugins:
  "<img src=x onerror=alert(1)>": ^1.0.0
''');
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();
    pluginManager.pluginIsolates.clear();

    var html = await page.generate({});
    expect(html, isNot(contains('<img src=x')));
    expect(
      html,
      contains('<strong>&lt;img src=x onerror=alert(1)&gt;</strong>'),
    );
  }

  Future<void> test_incompatiblePluginSources_escaped() async {
    writeTestPackageAnalysisOptionsFile('''
plugins:
  "<img src=x onerror=alert(1)>": ^1.0.0
''');
    newFile('$testPackageRootPath/sub/analysis_options.yaml', '''
plugins:
  "<img src=x onerror=alert(1)>": "<script>alert(2)</script>"
''');
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/sub/a.dart', 'class B {}');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();
    pluginManager.pluginIsolates.clear();

    var html = await page.generate({});
    expect(html, isNot(contains('<img src=x')));
    expect(html, isNot(contains('<script>alert(2)</script>')));
    expect(
      html,
      contains('<strong>&lt;img src=x onerror=alert(1)&gt;</strong>:'),
    );
    expect(html, contains('&lt;script&gt;alert(2)&lt;&#47;script&gt;'));
  }
}
