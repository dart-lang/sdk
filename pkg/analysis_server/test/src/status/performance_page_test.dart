// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/performance_page.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PerformancePageTest);
  });
}

@reflectiveTest
class PerformancePageTest extends PubPackageAnalysisServerTest {
  late DiagnosticsSite site;
  late PerformancePage page;

  @override
  void setUp() {
    super.setUp();
    site = DiagnosticsSite(_TestSocketServer(server), []);
    page = PerformancePage(site);
  }

  Future<void> test_healthyState() async {
    // Create a cycle of 15 libraries (which is <= 20, so healthy).
    for (var i = 0; i < 15; i++) {
      var next = (i + 1) % 15;
      newFile(
        '$testPackageLibPath/lib$i.dart',
        "import 'lib$next.dart'; class C$i {}",
      );
    }
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(html, contains('No obvious performance problems detected.'));
    expect(html, contains('Other Information'));
    expect(html, contains('Analysis Contexts'));
    expect(html, contains('Library Cycles'));
    expect(html, contains('pub workspaces'));
    expect(html, contains('href="contexts"'));
  }

  Future<void> test_largeLibraryCycle() async {
    // Create a cycle of 22 libraries: lib0 -> lib1 -> ... -> lib21 -> lib0.
    for (var i = 0; i < 22; i++) {
      var next = (i + 1) % 22;
      newFile(
        '$testPackageLibPath/lib$i.dart',
        "import 'lib$next.dart'; class C$i {}",
      );
    }
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    expect(html, contains('<span class="counter counter-red">1</span>'));
    expect(html, contains('Potential Problems'));
    expect(html, contains('Detected <strong>1</strong> large library cycle'));
    expect(html, contains('22 libraries</strong>'));
    expect(html, contains('lib0.dart'));
    expect(html, contains('14 more...'));
  }

  Future<void> test_manyContexts() async {
    // Create 11 separate packages/contexts.
    for (var i = 1; i <= 11; i++) {
      var packagePath = '$workspaceRootPath/pkg$i';
      newFile('$packagePath/pubspec.yaml', 'name: pkg$i\n');
      newFile('$packagePath/lib/pkg$i.dart', 'class P$i {}');
    }
    await setRoots(
      included: [for (var i = 1; i <= 11; i++) '$workspaceRootPath/pkg$i'],
      excluded: [],
    );

    expect(server.driverMap.length, greaterThan(10));
    expect(page.navDetail, '1');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    expect(html, contains('<span class="counter counter-red">1</span>'));
    expect(html, contains('Potential Problems'));
    expect(html, contains('There are <strong>11</strong> analysis contexts'));
    expect(html, contains('pub workspaces'));
  }

  Future<void> test_manyContextsAndLargeLibraryCycle() async {
    for (var i = 1; i <= 11; i++) {
      var packagePath = '$workspaceRootPath/pkg$i';
      newFile('$packagePath/pubspec.yaml', 'name: pkg$i\n');
      newFile('$packagePath/lib/pkg$i.dart', 'class P$i {}');
    }
    // In pkg1, create a 22-library cycle (> 20 libraries).
    for (var i = 0; i < 22; i++) {
      var next = (i + 1) % 22;
      newFile(
        '$workspaceRootPath/pkg1/lib/lib$i.dart',
        "import 'lib$next.dart'; class C$i {}",
      );
    }

    await setRoots(
      included: [for (var i = 1; i <= 11; i++) '$workspaceRootPath/pkg$i'],
      excluded: [],
    );
    await waitForTasksFinished();

    expect(server.driverMap.length, greaterThan(10));
    expect(page.navDetail, '2');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    expect(html, contains('<span class="counter counter-red">2</span>'));
    expect(html, contains('Potential Problems'));
    expect(html, contains('There are <strong>11</strong> analysis contexts'));
    expect(html, contains('Detected <strong>1</strong> large library cycle'));
    expect(html, contains('22 libraries</strong>'));
  }

  Future<void> test_moreThan20LargeLibraryCycles() async {
    // Create 22 cycles of 21 libraries each (> 20 libraries).
    for (var c = 0; c < 22; c++) {
      for (var i = 0; i < 21; i++) {
        var next = (i + 1) % 21;
        newFile(
          '$testPackageLibPath/c${c}_lib$i.dart',
          "import 'c${c}_lib$next.dart'; class C_${c}_$i {}",
        );
      }
    }
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    expect(html, contains('<span class="counter counter-red">1</span>'));
    expect(html, contains('Potential Problems'));
    expect(html, contains('Detected <strong>22</strong> large library cycles'));
    expect(
      html,
      contains('plus 2 more potentially problematic library cycles.'),
    );
  }

  Future<String> _generate() async {
    return await page.generate({});
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
