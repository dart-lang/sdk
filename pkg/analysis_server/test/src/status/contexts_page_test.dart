// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/contexts_page.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextsPageTest);
  });
}

@reflectiveTest
class ContextsPageTest extends PubPackageAnalysisServerTest {
  late DiagnosticsSite site;
  late ContextsPage page;

  @override
  void setUp() {
    super.setUp();
    site = DiagnosticsSite(_TestSocketServer(server), []);
    page = ContextsPage(site);
  }

  Future<void> test_contextFilesFilteredToContext() async {
    var pkg1Path = '$workspaceRootPath/pkg1';
    var pkg2Path = '$workspaceRootPath/pkg2';

    newFile('$pkg1Path/pubspec.yaml', 'name: pkg1\n');
    var pkg1File = newFile('$pkg1Path/lib/pkg1.dart', 'class P1 {}');

    newFile('$pkg2Path/pubspec.yaml', 'name: pkg2\n');
    newFile('$pkg2Path/lib/pkg2.dart', 'class P2 {}');

    await setRoots(included: [pkg1Path, pkg2Path], excluded: []);
    await setPriorityFiles2([pkg1File]);
    await waitForTasksFinished();

    // Verify pkg1 view
    var htmlPkg1 = await _generate({'context': pkg1Path});
    expect(htmlPkg1, contains('pkg1.dart'));
    expect(htmlPkg1, isNot(contains('pkg2.dart')));

    // Verify pkg2 view
    var htmlPkg2 = await _generate({'context': pkg2Path});
    expect(htmlPkg2, contains('pkg2.dart'));
    expect(htmlPkg2, isNot(contains('pkg1.dart')));
  }

  Future<String> _generate(Map<String, String> params) async {
    return await page.generate(params);
  }
}

class _TestSocketServer implements AbstractSocketServer {
  @override
  final AnalysisServer analysisServer;

  new(this.analysisServer);

  @override
  AnalysisServerOptions get analysisServerOptions => analysisServer.options;

  @override
  DiagnosticServer? get diagnosticServer => null;
}
