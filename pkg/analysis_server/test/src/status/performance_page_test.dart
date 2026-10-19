// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart' as pages;
import 'package:analysis_server/src/status/pages/exceptions_page.dart';
import 'package:analysis_server/src/status/pages/performance_page.dart';
import 'package:analyzer/src/file_system/timing_resource_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import 'test_socket_server.dart';

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
    site = DiagnosticsSite(TestSocketServer(server), []);
    page = PerformancePage(site);
  }

  Future<void> test_fileIoTimingsNotAffected() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile(
      '$testPackageRootPath/web/node_modules/pkg/index.js',
      'console.log();',
    );
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    Map<ResourceProviderOperation, int> callCounts() {
      var timings = server.timingResourceProvider.timings;
      return {
        for (var MapEntry(:key, :value) in timings.entries) key: value.count,
      };
    }

    var countsBefore = callCounts();
    expect(page.navDetail, '1');
    await _generate();
    await _generateNavDetail();
    expect(callCounts(), countsBefore);
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
    expect(html, contains('<h3>Symlinks</h3>'));
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
    expect(await _generateNavDetail(), {
      'detail': '2',
      'detailClass': 'counter-red',
    });

    var html = await _generate();
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
    expect(html, contains('Potential Problems'));
    expect(html, contains('Detected <strong>22</strong> large library cycles'));
    expect(
      html,
      contains('plus 2 more potentially problematic library cycles.'),
    );
  }

  Future<void> test_navDetail_json() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/node_modules/pkg/index.js', 'console.log();');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    var params = {DiagnosticPageWithNav.navDetailParameter: ''};
    expect(page.contentType(params).mimeType, 'application/json');
    expect(page.contentType({}).mimeType, 'text/html');
    expect(await _generateNavDetail(), {
      'detail': '1',
      'detailClass': 'counter-red',
    });
  }

  Future<void> test_navDetail_json_noProblems() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(await _generateNavDetail(), {
      'detail': null,
      'detailClass': 'counter-red',
    });
  }

  Future<void> test_navDetail_otherPage() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/node_modules/pkg/index.js', 'console.log();');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();
    var performancePage = _useCountingPerformancePage();

    // The navigation of another page links to the Performance page without
    // computing its detail, so that rendering the page does not wait for it...
    var html = await ExceptionsPage(site).generate({});
    expect(performancePage.navDetailCount, 0);
    expect(
      html,
      contains(
        '<a class="menu-item" href="performance" '
        'data-nav-detail-url="performance?navDetail">Performance</a>',
      ),
    );
    expect(
      html,
      contains("document.querySelectorAll('a[data-nav-detail-url]')"),
    );
    expect(html, isNot(contains('<span class="counter counter-red">')));

    // ...whereas the detail of a page which is cheap to compute is rendered
    // directly.
    expect(
      html,
      contains('href="exceptions">Exceptions<span class="counter">0</span>'),
    );
  }

  Future<void> test_navDetail_performancePage() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/node_modules/pkg/index.js', 'console.log();');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();
    var performancePage = _useCountingPerformancePage();

    // The Performance page does not include its own detail in its navigation
    // either. The browser loads it.
    expect(performancePage.loadsNavDetailAsynchronously, isTrue);
    var html = await performancePage.generate({});
    expect(performancePage.navDetailCount, 0);
    expect(
      html,
      contains(
        '<a class="menu-item selected" href="performance" '
        'data-nav-detail-url="performance?navDetail">Performance</a>',
      ),
    );
    expect(
      html,
      contains("document.querySelectorAll('a[data-nav-detail-url]')"),
    );
    expect(html, isNot(contains('<span class="counter counter-red">')));
    expect(html, contains('Potential Problems'));
  }

  Future<void> test_nodeModules_excluded() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/node_modules/pkg/index.js', 'console.log();');
    writeTestPackageAnalysisOptionsFile('''
analyzer:
  exclude:
    - 'node_modules/**'
''');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(
      html,
      contains(
        'No unexcluded <code>node_modules</code> directories were detected',
      ),
    );
  }

  Future<void> test_nodeModules_nested() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile(
      '$testPackageRootPath/web/node_modules/pkg/index.js',
      'console.log();',
    );
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');

    var html = await _generate();
    var expectedPath = pages.escape(convertPath('web/node_modules'));
    expect(html, contains('Potential Problems'));
    expect(html, contains('<code>$expectedPath</code> in context'));
  }

  Future<void> test_nodeModules_notExcluded() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/node_modules/pkg/index.js', 'console.log();');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    expect(html, contains('Potential Problems'));
    expect(html, contains('node_modules Directories'));
    expect(
      html,
      contains(
        'Detected <strong>1</strong> unexcluded <code>node_modules</code> directory',
      ),
    );
    expect(html, contains('<code>node_modules</code> in context'));
    expect(html, contains('**/node_modules/**'));
  }

  Future<void> test_symlinks_belowThreshold() async {
    // Exactly 100 Dart files are analyzed through the symlink, which is not
    // *more than* 100.
    _newDartFiles('$testPackageLibPath/real', 100);
    newLink('$testPackageLibPath/alias', '$testPackageLibPath/real');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(
      html,
      contains(
        'Detected <strong>1</strong> symlinked directory through which '
        '<strong>100</strong> Dart files are analyzed, which is unlikely to '
        'affect performance.',
      ),
    );
  }

  Future<void> test_symlinks_createsContext() async {
    // `lib/up` points to the package root, which has a package configuration,
    // so the analysis server creates an additional analysis context for it.
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newLink('$testPackageLibPath/up', testPackageRootPath);
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(server.driverMap, hasLength(2));
    expect(page.navDetail, '1');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    var linkPath = pages.escape(convertPath('lib/up'));
    var targetPath = pages.escape(convertPath(testPackageRootPath));
    expect(html, contains('Potential Problems'));
    expect(html, contains('<h3>Symlinks</h3>'));
    expect(
      html,
      contains('<code>$linkPath</code> &rarr; <code>$targetPath</code>: '),
    );
    expect(
      html,
      contains(
        '(creates an additional analysis context, '
        'points to a parent directory, points into this context)',
      ),
    );
    expect(html, contains("- '${pages.escape('lib/up/**')}'"));
  }

  Future<void> test_symlinks_createsContext_excluded() async {
    // Excluding the symlink prevents the additional analysis context from being
    // created.
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newLink('$testPackageLibPath/up', testPackageRootPath);
    writeTestPackageAnalysisOptionsFile('''
analyzer:
  exclude:
    - 'lib/up/**'
''');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(server.driverMap, hasLength(1));
    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(html, contains('No symlinks to directories were detected'));
  }

  Future<void> test_symlinks_createsContext_otherPackage() async {
    // `lib/other` points to another package, outside of this package.
    newFile('$workspaceRootPath/other/lib/b.dart', 'class B {}');
    newSinglePackageConfigJsonFile(
      packagePath: '$workspaceRootPath/other',
      name: 'other',
    );
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newLink('$testPackageLibPath/other', '$workspaceRootPath/other');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(server.driverMap, hasLength(2));
    expect(page.navDetail, '1');

    var html = await _generate();
    var linkPath = pages.escape(convertPath('lib/other'));
    var targetPath = pages.escape(convertPath('$workspaceRootPath/other'));
    expect(
      html,
      contains('<code>$linkPath</code> &rarr; <code>$targetPath</code>: '),
    );
    expect(html, contains('(creates an additional analysis context)'));
    expect(html, isNot(contains('points into this context')));
    expect(html, isNot(contains('points to a parent directory')));
  }

  Future<void> test_symlinks_excluded() async {
    _newDartFiles('$testPackageLibPath/real', 101);
    newLink('$testPackageLibPath/alias', '$testPackageLibPath/real');
    writeTestPackageAnalysisOptionsFile('''
analyzer:
  exclude:
    - 'lib/alias/**'
''');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(html, contains('No symlinks to directories were detected'));
  }

  Future<void> test_symlinks_hidden() async {
    // Hidden directories are not walked, so a symlink in one is never followed.
    _newDartFiles('$testPackageLibPath/real', 101);
    newFolder('$testPackageRootPath/.symlinks');
    newLink('$testPackageRootPath/.symlinks/real', '$testPackageLibPath/real');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(html, contains('No symlinks to directories were detected'));
  }

  Future<void> test_symlinks_manyFiles() async {
    _newDartFiles('$testPackageLibPath/real', 101);
    newLink('$testPackageLibPath/alias', '$testPackageLibPath/real');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');
    expect(page.navDetailClass, 'counter-red');

    var html = await _generate();
    var linkPath = pages.escape(convertPath('lib/alias'));
    var targetPath = pages.escape(convertPath('$testPackageLibPath/real'));
    expect(html, contains('Potential Problems'));
    expect(html, contains('<h3>Symlinks</h3>'));
    expect(
      html,
      contains(
        'Detected <strong>1</strong> symlinked directory through which '
        '<strong>101</strong> Dart files',
      ),
    );
    expect(html, contains('of the Dart files being analyzed'));
    expect(
      html,
      contains(
        '<code>$linkPath</code> &rarr; <code>$targetPath</code>: '
        '<strong>101 Dart files</strong> in context',
      ),
    );
    expect(html, contains('points into this context'));
    expect(html, isNot(contains('points to a parent directory')));
    expect(html, contains("- '${pages.escape('lib/alias/**')}'"));
  }

  Future<void> test_symlinks_moreThan20() async {
    // 22 symlinks to a directory with 5 Dart files: 110 files in total.
    _newDartFiles('$testPackageLibPath/real', 5);
    for (var i = 0; i < 22; i++) {
      newLink('$testPackageLibPath/alias$i', '$testPackageLibPath/real');
    }
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');

    var html = await _generate();
    expect(html, contains('Potential Problems'));
    expect(
      html,
      contains(
        'Detected <strong>22</strong> symlinked directories through which '
        '<strong>110</strong> Dart files',
      ),
    );
    expect(html, contains('plus 2 more symlinks.'));
  }

  Future<void> test_symlinks_nested() async {
    // `lib/real/inner` is a symlink to `other`, and `lib/alias` is a symlink to
    // `lib/real`. The files behind `lib/alias/inner` are reached through
    // `lib/alias`, the outermost symlink, and are not reported separately.
    _newDartFiles('$testPackageLibPath/real', 50);
    _newDartFiles('$workspaceRootPath/other', 51);
    newLink('$testPackageLibPath/real/inner', '$workspaceRootPath/other');
    newLink('$testPackageLibPath/alias', '$testPackageLibPath/real');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');

    var html = await _generate();
    expect(
      html,
      contains(
        'Detected <strong>2</strong> symlinked directories through which '
        '<strong>152</strong> Dart files',
      ),
    );
    // 50 files in `lib/real`, and 51 files behind `lib/alias/inner`.
    expect(html, contains('<strong>101 Dart files</strong>'));
    expect(html, contains('<strong>51 Dart files</strong>'));
    expect(html, isNot(contains(pages.escape(convertPath('lib/alias/inner')))));
  }

  Future<void> test_symlinks_nestedContext() async {
    // A nested package that is not behind a symlink also gets its own analysis
    // context, but that is not a concern of the symlinks.
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageRootPath/example/lib/b.dart', 'class B {}');
    newFile('$testPackageRootPath/example/pubspec.yaml', 'name: example\n');
    newSinglePackageConfigJsonFile(
      packagePath: '$testPackageRootPath/example',
      name: 'example',
    );
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(server.driverMap, hasLength(2));
    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('All Clear:'));
    expect(html, contains('No symlinks to directories were detected'));
  }

  Future<void> test_symlinks_none() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, isNull);

    var html = await _generate();
    expect(html, contains('<h3>Symlinks</h3>'));
    expect(html, contains('No symlinks to directories were detected'));
  }

  Future<void> test_symlinks_outsideContext() async {
    _newDartFiles('$workspaceRootPath/shared', 101);
    newFolder(testPackageLibPath);
    newLink('$testPackageLibPath/shared', '$workspaceRootPath/shared');
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(page.navDetail, '1');

    var html = await _generate();
    var targetPath = pages.escape(convertPath('$workspaceRootPath/shared'));
    expect(
      html,
      contains(
        '&rarr; <code>$targetPath</code>: <strong>101 Dart files</strong>',
      ),
    );
    expect(html, isNot(contains('points into this context')));
    expect(html, isNot(contains('points to a parent directory')));
  }

  Future<void> test_symlinks_parentDirectory() async {
    // `lib/up` points to the package root. The analysis server does not follow
    // it back into `lib` (which is already being walked), but it does analyze
    // the other directories again, through the symlink.
    //
    // Without a package configuration at the package root, the symlink does
    // not create an additional analysis context.
    deleteTestPackageConfigJsonFile();
    _newDartFiles('$testPackageRootPath/bin', 101);
    newFolder(testPackageLibPath);
    newLink('$testPackageLibPath/up', testPackageRootPath);
    await setRoots(included: [testPackageRootPath], excluded: []);
    await waitForTasksFinished();

    expect(server.driverMap, hasLength(1));
    expect(page.navDetail, '1');

    var html = await _generate();
    expect(
      html,
      contains('points to a parent directory, points into this context'),
    );
    expect(html, isNot(contains('<em>(creates')));
    expect(html, contains('<strong>101 Dart files</strong>'));
  }

  Future<String> _generate([Map<String, String> params = const {}]) async {
    return await page.generate(params);
  }

  /// Requests the navigation detail of [page], like the browser does, and
  /// returns the decoded JSON response.
  Future<Object?> _generateNavDetail() async {
    var response = await _generate({
      DiagnosticPageWithNav.navDetailParameter: '',
    });
    return jsonDecode(response);
  }

  /// Creates [count] Dart files in the directory at [directoryPath].
  void _newDartFiles(String directoryPath, int count) {
    for (var i = 0; i < count; i++) {
      newFile('$directoryPath/f$i.dart', 'class C$i {}');
    }
  }

  /// Replaces the Performance page of [site], which is what other pages link to
  /// in their navigation, with one that counts how often its navigation detail
  /// is computed.
  _CountingPerformancePage _useCountingPerformancePage() {
    var countingPage = _CountingPerformancePage(site);
    var index = site.pages.indexWhere((page) => page is PerformancePage);
    site.pages[index] = countingPage;
    return countingPage;
  }
}

/// A [PerformancePage] that counts how often its [navDetail] is computed.
class _CountingPerformancePage extends PerformancePage {
  int navDetailCount = 0;

  new(super.site);

  @override
  String? get navDetail {
    navDetailCount++;
    return super.navDetail;
  }
}
