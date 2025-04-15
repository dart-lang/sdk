// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as driver_events;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer/src/utilities/extensions/async.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';
import '../resolution/resolution.dart';
import 'result_printer.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriver_PubPackageTest);
    defineReflectiveTests(AnalysisDriver_BlazeWorkspaceTest);
    defineReflectiveTests(AnalysisDriver_LintTest);
    defineReflectiveTests(FineAnalysisDriverTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnalysisDriver_BlazeWorkspaceTest extends BlazeWorkspaceResolutionTest {
  void test_nestedLib_notCanonicalUri() async {
    var outerLibPath = '$workspaceRootPath/my/outer/lib';

    var innerFile = newFile('$outerLibPath/inner/lib/b.dart', 'class B {}');
    var innerUri = Uri.parse('package:my.outer.lib.inner/b.dart');

    var analysisSession = contextFor(innerFile).currentSession;

    void assertInnerUri(ResolvedUnitResult result) {
      var innerSource = result.libraryFragment.libraryImports2
          .map((import) => import.importedLibrary2?.firstFragment.source)
          .nonNulls
          .where((importedSource) => importedSource.fullName == innerFile.path)
          .single;
      expect(innerSource.uri, innerUri);
    }

    // Reference "inner" using a non-canonical URI.
    {
      var a = newFile(convertPath('$outerLibPath/a.dart'), r'''
import 'inner/lib/b.dart';
''');
      var result = await analysisSession.getResolvedUnit(a.path);
      result as ResolvedUnitResult;
      assertInnerUri(result);
    }

    // Reference "inner" using the canonical URI, via relative.
    {
      var c = newFile('$outerLibPath/inner/lib/c.dart', r'''
import 'b.dart';
''');
      var result = await analysisSession.getResolvedUnit(c.path);
      result as ResolvedUnitResult;
      assertInnerUri(result);
    }

    // Reference "inner" using the canonical URI, via absolute.
    {
      var d = newFile('$outerLibPath/inner/lib/d.dart', '''
import '$innerUri';
''');
      var result = await analysisSession.getResolvedUnit(d.path);
      result as ResolvedUnitResult;
      assertInnerUri(result);
    }
  }
}

@reflectiveTest
class AnalysisDriver_LintTest extends PubPackageResolutionTest
    with LintRegistrationMixin {
  @override
  void setUp() {
    super.setUp();

    useEmptyByteStore();
    registerLintRule(_AlwaysReportedLint.instance);
    writeTestPackageAnalysisOptionsFile(analysisOptionsContent(
      rules: [_AlwaysReportedLint.code.name],
    ));
  }

  @override
  Future<void> tearDown() {
    unregisterLintRules();
    return super.tearDown();
  }

  test_getResolvedUnit_lint_existingFile() async {
    addTestFile('');
    await resolveTestFile();

    // Existing/empty file triggers the lint.
    _assertHasLintReported(result.errors, _AlwaysReportedLint.code.name);
  }

  test_getResolvedUnit_lint_notExistingFile() async {
    await resolveTestFile();

    // No errors for a file that doesn't exist.
    assertErrorsInResult([]);
  }

  void _assertHasLintReported(List<AnalysisError> errors, String name) {
    var matching = errors.where((element) {
      var errorCode = element.errorCode;
      return errorCode is LintCode && errorCode.name == name;
    }).toList();
    expect(matching, hasLength(1));
  }
}

@reflectiveTest
class AnalysisDriver_PubPackageTest extends PubPackageResolutionTest
    with _EventsMixin {
  @override
  bool get retainDataForTesting => true;

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    useEmptyByteStore();
  }

  @override
  Future<void> tearDown() async {
    withFineDependencies = false;
    return super.tearDown();
  }

  test_addedFiles() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');

    var driver = driverFor(testFile);

    driver.addFile2(a);
    driver.addFile2(b);
    await driver.applyPendingFileChanges();
    expect(driver.addedFiles2, unorderedEquals([a, b]));

    driver.removeFile2(a);
    await driver.applyPendingFileChanges();
    expect(driver.addedFiles2, unorderedEquals([b]));
  }

  test_addFile() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(b);
    driver.addFile2(a);

    // The files are analyzed in the order of adding.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_addFile_afterRemove() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);
    driver.addFile2(a);
    driver.addFile2(b);

    // Initial analysis, `b` does not use `a`, so there is a hint.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      7 +8 UNUSED_IMPORT
[status] idle
''');

    // Update `b` to use `a`, no more hints.
    modifyFile2(b, r'''
import 'a.dart';
void f() {
  A;
}
''');

    // Remove and add `b`.
    driver.removeFile2(b);
    driver.addFile2(b);

    // `b` was analyzed, no more hints.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_addFile_notAbsolutePath() async {
    var driver = driverFor(testFile);
    expect(() {
      driver.addFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_addFile_priorityFiles() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');
    var c = newFile('$testPackageLibPath/c.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.priorityFiles2 = [b];

    // 1. The priority file is produced first.
    // 2. Each analyzed file produces `ResolvedUnitResult`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/c.dart
  library: /home/test/lib/c.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_addFile_removeFile() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Add, and immediately remove.
    driver.addFile2(a);
    driver.removeFile2(a);

    // No files to analyze.
    await assertEventsText(collector, r'''
[status] working
[status] idle
''');
  }

  test_addFile_thenRemove() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // Now remove `a`.
    driver.removeFile2(a);

    // We remove `a` before analysis started.
    // So, only `b` was analyzed.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_cachedPriorityResults() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Get the result, not cached.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Get the (cached) result, not reported to the stream.
    collector.getResolvedUnit('A2', a);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A2
  ResolvedUnitResult #0
''');

    // Get the (cached) result, reported to the stream.
    collector.getResolvedUnit('A3', a, sendCachedToStream: true);
    await assertEventsText(collector, r'''
[stream]
  ResolvedUnitResult #0
[future] getResolvedUnit A3
  ResolvedUnitResult #0
''');
  }

  test_cachedPriorityResults_flush_onAnyFileChange() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Change a file.
    // The cache is flushed, so we get a new result.
    driver.changeFile2(a);
    collector.getResolvedUnit('A2', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A2
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');

    // Add `b`.
    // The cache is flushed, so we get a new result.
    driver.addFile2(b);
    collector.getResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A3
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[status] idle
''');

    // Remove `b`.
    // The cache is flushed, so we get a new result.
    driver.removeFile2(b);
    collector.getResolvedUnit('A4', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A4
  ResolvedUnitResult #4
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #4
[status] idle
''');
  }

  test_cachedPriorityResults_flush_onPrioritySetChange() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Get the result for `a`, new.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Make `a` and `b` priority.
    // We still have the result for `a` cached.
    driver.priorityFiles2 = [a, b];
    collector.getResolvedUnit('A2', a);
    await assertEventsText(collector, r'''
[status] working
[future] getResolvedUnit A2
  ResolvedUnitResult #0
[status] idle
''');

    // Get the result for `b`, new.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');

    // Get the result for `b`, cached.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit B2
  ResolvedUnitResult #1
''');

    // Only `b` is priority.
    // The result for `a` is flushed, so analyzed when asked.
    driver.priorityFiles2 = [b];
    collector.getResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A3
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[status] idle
''');
  }

  test_cachedPriorityResults_notPriority() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Always analyzed the first time.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Analyzed again, because `a` is not priority.
    collector.getResolvedUnit('A2', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A2
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_cachedPriorityResults_wholeLibrary_priorityLibrary_askLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Ask the result for `a`, should cache for both `a` and `b`.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no analysis.
    collector.getResolvedUnit('A2', a);
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A2
  ResolvedUnitResult #0
[future] getResolvedUnit B1
  ResolvedUnitResult #1
''');

    // Ask for resolved library.
    // Note, no analysis.
    // Note, the units are cached.
    collector.getResolvedLibrary('L1', a);
    await assertEventsText(collector, r'''
[future] getResolvedLibrary L1
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
      ResolvedUnitResult #1
''');
  }

  test_cachedPriorityResults_wholeLibrary_priorityLibrary_askPart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Ask the result for `b`, should cache for both `a` and `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no analysis.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A1
  ResolvedUnitResult #1
[future] getResolvedUnit B2
  ResolvedUnitResult #0
''');

    // Ask for resolved library.
    // Note, no analysis.
    // Note, the units are cached.
    collector.getResolvedLibrary('L1', a);
    await assertEventsText(collector, r'''
[future] getResolvedLibrary L1
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
      ResolvedUnitResult #0
''');
  }

  test_cachedPriorityResults_wholeLibrary_priorityPart_askPart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [b];

    // Ask the result for `b`, should cache for both `a` and `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no analysis.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A1
  ResolvedUnitResult #1
[future] getResolvedUnit B2
  ResolvedUnitResult #0
''');

    // Ask for resolved library.
    // Note, no analysis.
    // Note, the units are cached.
    collector.getResolvedLibrary('L1', a);
    await assertEventsText(collector, r'''
[future] getResolvedLibrary L1
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
      ResolvedUnitResult #0
''');
  }

  test_changeFile_implicitlyAnalyzed() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
var A = B;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
var B = 0;
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];
    driver.addFile2(a);

    configuration.libraryConfiguration.unitConfiguration.nodeSelector =
        (result) {
      return result.findNode.simple('B;');
    };

    // We have a result only for "a".
    // The type of `B` is `int`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedNode: SimpleIdentifier
      token: B
      element: package:test/b.dart::<fragment>::@getter::B#element
      staticType: int
[status] idle
''');

    // Change "b" and notify.
    modifyFile2(b, r'''
var B = 1.2;
''');
    driver.changeFile2(b);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // The change causes "a" to be reanalyzed.
    // The type of `B` is now `double`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedNode: SimpleIdentifier
      token: B
      element: package:test/b.dart::<fragment>::@getter::B#element
      staticType: double
[status] idle
''');
  }

  test_changeFile_notAbsolutePath() async {
    var driver = driverFor(testFile);
    expect(() {
      driver.changeFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_changeFile_notExisting_toEmpty() async {
    var b = newFile('$testPackageLibPath/b.dart', '''
// ignore:unused_import
import 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(b);

    // `b` is analyzed, has an error.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      31 +8 URI_DOES_NOT_EXIST
[status] idle
''');

    // Create `a`, empty.
    var a = newFile('$testPackageLibPath/a.dart', '');
    driver.addFile2(a);

    // Both `a` and `b` are analyzed.
    // No errors anymore.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_changeFile_notPriority_errorsFromBytes() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Initial analysis, no errors.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');

    // Update the file, has an error.
    // Note, we analyze the file.
    modifyFile2(a, ';');
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    errors
      0 +1 UNEXPECTED_TOKEN
[status] idle
''');

    // Update the file, no errors.
    // Note, we return errors from bytes.
    // We must update latest signatures, not reflected in the text.
    // If we don't, the next assert will fail.
    modifyFile2(a, '');
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] getErrorsFromBytes
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ErrorsResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');

    // Update the file, has an error.
    // Note, we return errors from bytes.
    modifyFile2(a, ';');
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] getErrorsFromBytes
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ErrorsResult #3
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      0 +1 UNEXPECTED_TOKEN
[status] idle
''');
  }

  test_changeFile_notUsed() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', 'class B1 {}');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Nothing interesting, "a" is analyzed.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');

    // Change "b" and notify.
    modifyFile2(b, 'class B2 {}');
    driver.changeFile2(b);

    // Nothing depends on "b", so nothing is analyzed.
    await assertEventsText(collector, r'''
[status] working
[status] idle
''');
  }

  test_changeFile_potentiallyAffected_imported() async {
    newFile('$testPackageLibPath/a.dart', '');

    var b = newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', '''
import 'b.dart';
''');

    var d = newFile('$testPackageLibPath/d.dart', '''
import 'c.dart';
''');

    newFile('$testPackageLibPath/e.dart', '');

    var driver = driverFor(testFile);

    Future<LibraryElement2> getLibrary(String shortName) async {
      var uriStr = 'package:test/$shortName';
      var result = await driver.getLibraryByUriValid(uriStr);
      return result.element2;
    }

    var a_element = await getLibrary('a.dart');
    var b_element = await getLibrary('b.dart');
    var c_element = await getLibrary('c.dart');
    var d_element = await getLibrary('d.dart');
    var e_element = await getLibrary('e.dart');

    // We have all libraries loaded after analysis.
    driver.assertLoadedLibraryUriSet(
      included: [
        'package:test/a.dart',
        'package:test/b.dart',
        'package:test/c.dart',
        'package:test/d.dart',
        'package:test/e.dart',
      ],
    );

    // All libraries have the current session.
    var session1 = driver.currentSession;
    expect(a_element.session, session1);
    expect(b_element.session, session1);
    expect(c_element.session, session1);
    expect(d_element.session, session1);
    expect(e_element.session, session1);

    // Change `b.dart`, also removes `c.dart` and `d.dart` that import it.
    // But `a.dart` and `d.dart` is not affected.
    driver.changeFile2(b);
    var affectedPathList = await driver.applyPendingFileChanges();
    expect(affectedPathList, unorderedEquals([b.path, c.path, d.path]));

    // We have a new session.
    var session2 = driver.currentSession;
    expect(session2, isNot(session1));

    driver.assertLoadedLibraryUriSet(
      excluded: [
        'package:test/b.dart',
        'package:test/c.dart',
        'package:test/d.dart',
      ],
      included: [
        'package:test/a.dart',
        'package:test/e.dart',
      ],
    );

    // `a.dart` and `e.dart` moved to the new session.
    // Invalidated libraries stuck with the old session.
    expect(a_element.session, session2);
    expect(b_element.session, session1);
    expect(c_element.session, session1);
    expect(d_element.session, session1);
    expect(e_element.session, session2);
  }

  test_changeFile_potentiallyAffected_part() async {
    var a = newFile('$testPackageLibPath/a.dart', '''
part of 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', '''
part 'a.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', '''
import 'b.dart';
''');

    newFile('$testPackageLibPath/d.dart', '');

    var driver = driverFor(testFile);

    Future<LibraryElement2> getLibrary(String shortName) async {
      var uriStr = 'package:test/$shortName';
      var result = await driver.getLibraryByUriValid(uriStr);
      return result.element2;
    }

    var b_element = await getLibrary('b.dart');
    var c_element = await getLibrary('c.dart');
    var d_element = await getLibrary('d.dart');

    // We have all libraries loaded after analysis.
    driver.assertLoadedLibraryUriSet(
      included: [
        'package:test/b.dart',
        'package:test/c.dart',
        'package:test/d.dart',
      ],
    );

    // All libraries have the current session.
    var session1 = driver.currentSession;
    expect(b_element.session, session1);
    expect(c_element.session, session1);
    expect(d_element.session, session1);

    // Change `a.dart`, remove `b.dart` that part it.
    // Removes `c.dart` that imports `b.dart`.
    // But `d.dart` is not affected.
    driver.changeFile2(a);
    var affectedPathList = await driver.applyPendingFileChanges();
    expect(affectedPathList, unorderedEquals([a.path, b.path, c.path]));

    // We have a new session.
    var session2 = driver.currentSession;
    expect(session2, isNot(session1));

    driver.assertLoadedLibraryUriSet(
      excluded: [
        'package:test/b.dart',
        'package:test/c.dart',
      ],
      included: [
        'package:test/d.dart',
      ],
    );

    // `d.dart` moved to the new session.
    // Invalidated libraries stuck with the old session.
    expect(b_element.session, session1);
    expect(c_element.session, session1);
    expect(d_element.session, session2);
  }

  test_changeFile_selfConsistent() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
final A1 = 1;
final A2 = B1;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
final B1 = A1;
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a, b];
    driver.addFile2(a);
    driver.addFile2(b);

    configuration.libraryConfiguration.unitConfiguration.variableTypesSelector =
        (result) {
      return switch (result.uriStr) {
        'package:test/a.dart' => [
            result.findElement2.topVar('A1'),
            result.findElement2.topVar('A2'),
          ],
        'package:test/b.dart' => [
            result.findElement2.topVar('B1'),
          ],
        _ => []
      };
    };

    // We have results for both "a" and "b".
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A1: int
      A2: int
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    selectedVariableTypes
      B1: int
[status] idle
''');

    // Update "a".
    modifyFile2(a, r'''
import 'b.dart';
final A1 = 1.2;
final A2 = B1;
''');
    driver.changeFile2(a);

    // We again get results for both "a" and "b".
    // The results are consistent.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A1: double
      A2: double
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    selectedVariableTypes
      B1: double
[status] idle
''');
  }

  test_changeFile_single() async {
    var a = newFile('$testPackageLibPath/a.dart', 'var V = 1;');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.priorityFiles2 = [a];

    configuration.libraryConfiguration.unitConfiguration.variableTypesSelector =
        (result) {
      switch (result.uriStr) {
        case 'package:test/a.dart':
          return [
            result.findElement2.topVar('V'),
          ];
        default:
          return [];
      }
    };

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      V: int
[status] idle
''');

    // Update the file, but don't notify the driver.
    // No new results.
    modifyFile2(a, 'var V = 1.2;');
    await assertEventsText(collector, r'''
''');

    // Notify the driver about the change.
    // We get a new result.
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      V: double
[status] idle
''');
  }

  test_currentSession() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final v = 0;
''');

    var driver = driverFor(testFile);

    await driver.getResolvedUnit2(a);

    var session1 = driver.currentSession;
    expect(session1, isNotNull);

    modifyFile2(a, r'''
final v = 2;
''');
    driver.changeFile2(a);
    await driver.getResolvedUnit2(a);

    var session2 = driver.currentSession;
    expect(session2, isNotNull);

    // We get a new session.
    expect(session2, isNot(session1));
  }

  test_discoverAvailableFiles_packages() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$packagesRootPath/aaa')
        ..add(name: 'bbb', rootPath: '$packagesRootPath/bbb'),
    );

    var t1 = newFile('$testPackageLibPath/t1.dart', '');
    var a1 = newFile('$packagesRootPath/aaa/lib/a1.dart', '');
    var a2 = newFile('$packagesRootPath/aaa/lib/src/a2.dart', '');
    var a3 = newFile('$packagesRootPath/aaa/lib/a3.txt', '');
    var b1 = newFile('$packagesRootPath/bbb/lib/b1.dart', '');
    var c1 = newFile('$packagesRootPath/ccc/lib/c1.dart', '');

    var driver = driverFor(testFile);
    driver.addFile2(t1);

    // Don't add `a1`, `a2`, or `b1` - they should be discovered.
    // And `c` is not in the package config, so should not be discovered.
    await driver.discoverAvailableFiles();

    var knownFiles = driver.knownFiles.resources;
    expect(knownFiles, contains(t1));
    expect(knownFiles, contains(a1));
    expect(knownFiles, contains(a2));
    expect(knownFiles, isNot(contains(a3)));
    expect(knownFiles, contains(b1));
    expect(knownFiles, isNot(contains(c1)));

    // We can wait for discovery more than once.
    await driver.discoverAvailableFiles();
  }

  test_discoverAvailableFiles_sdk() async {
    var driver = driverFor(testFile);
    await driver.discoverAvailableFiles();
    expect(
      driver.knownFiles.resources,
      containsAll([
        sdkRoot.getChildAssumingFile('lib/async/async.dart'),
        sdkRoot.getChildAssumingFile('lib/collection/collection.dart'),
        sdkRoot.getChildAssumingFile('lib/core/core.dart'),
        sdkRoot.getChildAssumingFile('lib/math/math.dart'),
      ]),
    );
  }

  test_getCachedResolvedUnit() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    // Not cached.
    // Note, no analysis.
    collector.getCachedResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[future] getCachedResolvedUnit A1
  null
''');

    driver.priorityFiles2 = [a];
    collector.getResolvedUnit('A2', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A2
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Has cached.
    // Note, no analysis.
    collector.getCachedResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[future] getCachedResolvedUnit A3
  ResolvedUnitResult #0
''');
  }

  test_getErrors() async {
    var a = newFile('$testPackageLibPath/a.dart', '''
var v = 0
''');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    collector.getErrors('A1', a);
    await assertEventsText(collector, r'''
[status] working
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      8 +1 EXPECTED_TOKEN
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    errors
      8 +1 EXPECTED_TOKEN
[status] idle
''');

    // The result is produced from bytes.
    collector.getErrors('A2', a);
    await assertEventsText(collector, r'''
[status] working
[operation] getErrorsFromBytes
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getErrors A2
  ErrorsResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      8 +1 EXPECTED_TOKEN
[status] idle
''');
  }

  test_getErrors_library_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getErrors('A1', a);
    collector.getErrors('B1', b);

    // Note, both `getErrors()` returned during the library analysis.
    await assertEventsText(collector, r'''
[status] working
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[future] getErrors B1
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_getErrors_notAbsolutePath() async {
    var driver = driverFor(testFile);
    var result = await driver.getErrors('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getFilesDefiningClassMemberName_class() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {
  void m1() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
class B {
  void m2() {}
}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
class C {
  void m2() {}
}
''');

    var d = newFile('$testPackageLibPath/d.dart', r'''
class D {
  void m3() {}
}
''');

    var driver = driverFor(testFile);
    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);

    await driver.assertFilesDefiningClassMemberName('m1', [a]);
    await driver.assertFilesDefiningClassMemberName('m2', [b, c]);
    await driver.assertFilesDefiningClassMemberName('m3', [d]);
  }

  test_getFilesDefiningClassMemberName_mixin() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void m1() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
mixin B {
  void m2() {}
}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
mixin C {
  void m2() {}
}
''');

    var d = newFile('$testPackageLibPath/d.dart', r'''
mixin D {
  void m3() {}
}
''');

    var driver = driverFor(testFile);
    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);

    await driver.assertFilesDefiningClassMemberName('m1', [a]);
    await driver.assertFilesDefiningClassMemberName('m2', [b, c]);
    await driver.assertFilesDefiningClassMemberName('m3', [d]);
  }

  test_getFilesReferencingName() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
void f(A a) {}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
void f(A a) {}
''');

    var d = newFile('$testPackageLibPath/d.dart', r'''
class A {}
void f(A a) {}
''');

    var e = newFile('$testPackageLibPath/e.dart', r'''
import 'a.dart';
void main() {}
''');

    var driver = driverFor(testFile);
    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);
    driver.addFile2(e);

    // `b` references an external `A`.
    // `c` references an external `A`.
    // `d` references the local `A`.
    // `e` does not reference `A` at all.
    await driver.assertFilesReferencingName(
      'A',
      includesAll: [b, c],
      excludesAll: [d, e],
    );

    // We get the same results second time.
    await driver.assertFilesReferencingName(
      'A',
      includesAll: [b, c],
      excludesAll: [d, e],
    );
  }

  test_getFilesReferencingName_discover() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$packagesRootPath/aaa')
        ..add(name: 'bbb', rootPath: '$packagesRootPath/bbb'),
    );

    var t = newFile('$testPackageLibPath/t.dart', '''
int t = 0;
''');

    var a = newFile('$packagesRootPath/aaa/lib/a.dart', '''
int a = 0;
''');

    var b = newFile('$packagesRootPath/bbb/lib/b.dart', '''
int b = 0;
''');

    var c = newFile('$packagesRootPath/ccc/lib/c.dart', '''
int c = 0;
''');

    var driver = driverFor(testFile);
    driver.addFile2(t);

    await driver.assertFilesReferencingName(
      'int',
      includesAll: [t, a, b],
      excludesAll: [c],
    );
  }

  test_getFileSync_changedFile() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void f(A a) {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Ensure that `a` library cycle is loaded.
    // So, `a` is in the library context.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Update the file, changing its API signature.
    // Note that we don't call `changeFile`.
    modifyFile2(a, 'class A {}\n');

    // Get the file.
    // We have not called `changeFile(a)`, so we should not read the file.
    // Moreover, doing this will create a new library cycle [a.dart].
    // Library cycles are compared by their identity, so we would try to
    // reload linked summary for [a.dart], and crash.
    expect(driver.getFileSyncValid(a).lineInfo.lineCount, 1);

    // We have not read `a.dart`, so `A` is still not declared.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      25 +1 UNDEFINED_CLASS
[stream]
  ResolvedUnitResult #1
[status] idle
''');

    // Notify the driver that the file was changed.
    driver.changeFile2(a);

    // ...and apply this change.
    await driver.applyPendingFileChanges();
    await assertEventsText(collector, r'''
[status] working
[status] idle
''');

    // So, `class A {}` is declared now.
    expect(driver.getFileSyncValid(a).lineInfo.lineCount, 2);

    // ...and `b` has no errors.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B2
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[status] idle
''');
  }

  test_getFileSync_library() async {
    var content = 'class A {}';
    var a = newFile('$testPackageLibPath/a.dart', content);
    var driver = driverFor(testFile);
    var result = driver.getFileSyncValid(a);
    expect(result.path, a.path);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.content, content);
    expect(result.isLibrary, isTrue);
    expect(result.isPart, isFalse);
  }

  test_getFileSync_notAbsolutePath() async {
    var driver = driverFor(testFile);
    var result = driver.getFileSync('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getFileSync_part() async {
    var content = 'part of lib;';
    var a = newFile('$testPackageLibPath/a.dart', content);
    var driver = driverFor(testFile);
    var result = driver.getFileSyncValid(a);
    expect(result.path, a.path);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.content, content);
    expect(result.isLibrary, isFalse);
    expect(result.isPart, isTrue);
  }

  test_getIndex() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
void foo() {}

void f() {
  foo();
}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getIndex('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getIndex A1
  strings
    --nullString--
    foo
    package:test/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_getIndex_notAbsolutePath() async {
    var driver = driverFor(testFile);
    expect(() async {
      await driver.getIndex('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_getLibraryByUri() async {
    var aUriStr = 'package:test/a.dart';
    var bUriStr = 'package:test/b.dart';

    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

class B {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var result = await driver.getLibraryByUri(aUriStr);
    result as LibraryElementResult;
    expect(result.element2.getClass2('A'), isNotNull);
    expect(result.element2.getClass2('B'), isNotNull);

    // It is an error to ask for a library when we know that it is a part.
    expect(
      await driver.getLibraryByUri(bUriStr),
      isA<NotLibraryButPartResult>(),
    );

    // No analysis.
    await assertEventsText(collector, r'''
[status] working
[status] idle
''');
  }

  test_getLibraryByUri_cannotResolveUri() async {
    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getLibraryByUri('X', 'foo:bar');

    await assertEventsText(collector, r'''
[future] getLibraryByUri X
  CannotResolveUriResult
''');
  }

  test_getLibraryByUri_notLibrary_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    var uriStr = 'package:test/a.dart';
    collector.getLibraryByUri('X', uriStr);

    await assertEventsText(collector, r'''
[future] getLibraryByUri X
  NotLibraryButPartResult
''');
  }

  test_getLibraryByUri_subsequentCallsDoesNoWork() async {
    var aUriStr = 'package:test/a.dart';
    var bUriStr = 'package:test/b.dart';

    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

class B {}
''');

    for (var run = 0; run < 5; run++) {
      var driver = driverFor(testFile);
      var collector = DriverEventCollector(driver);

      var result = await driver.getLibraryByUri(aUriStr);
      result as LibraryElementResult;
      expect(result.element2.getClass2('A'), isNotNull);
      expect(result.element2.getClass2('B'), isNotNull);

      // It is an error to ask for a library when we know that it is a part.
      expect(
        await driver.getLibraryByUri(bUriStr),
        isA<NotLibraryButPartResult>(),
      );

      if (run == 0) {
        // First `getLibraryByUri` call does actual work.
        await assertEventsText(collector, r'''
[status] working
[status] idle
''');
      } else {
        // Subsequent `getLibraryByUri` just grabs the result via rootReference
        // and thus does no actual work.
        await assertEventsText(collector, '');
      }
    }
  }

  test_getLibraryByUri_unresolvedUri() async {
    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var result = await driver.getLibraryByUri('package:foo/foo.dart');
    expect(result, isA<CannotResolveUriResult>());

    // No analysis.
    await assertEventsText(collector, '');
  }

  test_getParsedLibrary() async {
    var content = 'class A {}';
    var a = newFile('$testPackageLibPath/a.dart', content);

    var driver = driverFor(testFile);
    var result = driver.getParsedLibrary2(a);
    result as ParsedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].path, a.path);
    expect(result.units[0].content, content);
    expect(result.units[0].unit, isNotNull);
    expect(result.units[0].errors, isEmpty);
  }

  test_getParsedLibrary_invalidPath_notAbsolute() async {
    var driver = driverFor(testFile);
    var result = driver.getParsedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getParsedLibrary_notLibraryButPart() async {
    var driver = driverFor(testFile);
    var a = newFile('$testPackageLibPath/a.dart', 'part of my;');
    var result = driver.getParsedLibrary2(a);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getParsedLibraryByUri() async {
    var content = 'class A {}';
    var a = newFile('$testPackageLibPath/a.dart', content);

    var driver = driverFor(testFile);

    var uri = Uri.parse('package:test/a.dart');
    var result = driver.getParsedLibraryByUri(uri);
    result as ParsedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].uri, uri);
    expect(result.units[0].path, a.path);
    expect(result.units[0].content, content);
  }

  test_getParsedLibraryByUri_cannotResolveUri() async {
    var driver = driverFor(testFile);
    var uri = Uri.parse('foo:bar');
    expect(
      driver.getParsedLibraryByUri(uri),
      isA<CannotResolveUriResult>(),
    );
  }

  test_getParsedLibraryByUri_notLibrary_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    var driver = driverFor(a);
    var uri = Uri.parse('package:test/a.dart');
    expect(
      driver.getParsedLibraryByUri(uri),
      isA<NotLibraryButPartResult>(),
    );
  }

  test_getParsedLibraryByUri_notLibraryButPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of my;');
    var driver = driverFor(testFile);
    var uri = Uri.parse('package:test/a.dart');
    var result = driver.getParsedLibraryByUri(uri);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getParsedLibraryByUri_unresolvedUri() async {
    var driver = driverFor(testFile);
    var uri = Uri.parse('package:unknown/a.dart');
    var result = driver.getParsedLibraryByUri(uri);
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getResolvedLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedLibrary A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedLibrary_cachePriority() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    collector.getResolvedLibrary('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedLibrary A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
      ResolvedUnitResult #2
        path: /home/test/lib/b.dart
        uri: package:test/b.dart
        flags: exists isPart
[stream]
  ResolvedUnitResult #1
[stream]
  ResolvedUnitResult #2
[status] idle
''');

    // Ask again, the same cached instance should be returned.
    // Note, no analysis.
    // Note, the result is cached.
    collector.getResolvedLibrary('A2', a);
    await assertEventsText(collector, r'''
[future] getResolvedLibrary A2
  ResolvedLibraryResult #0
''');

    // Ask `a`, returns cached.
    // Note, no analysis.
    collector.getResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A3
  ResolvedUnitResult #1
''');

    // Ask `b`, returns cached.
    // Note, no analysis.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit B1
  ResolvedUnitResult #2
''');
  }

  test_getResolvedLibrary_notAbsolutePath() async {
    var driver = driverFor(testFile);
    var result = await driver.getResolvedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary_notLibrary_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('X', a);

    await assertEventsText(collector, r'''
[status] working
[future] getResolvedLibrary X
  NotLibraryButPartResult
[status] idle
''');
  }

  test_getResolvedLibrary_pending_changeFile() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Ask the resolved library.
    // We used to record the request with the `LibraryFileKind`.
    collector.getResolvedLibrary('A1', a);

    // ...the request is pending, notify that the file changed.
    // This forces its reading, and rebuilding its `kind`.
    // So, the old `kind` is not valid anymore.
    // This used to cause infinite processing of the request.
    // https://github.com/dart-lang/sdk/issues/54708
    driver.changeFile2(a);

    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedLibrary A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedLibraryByUri() async {
    newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);

    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedLibraryByUri A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedLibraryByUri_cannotResolveUri() async {
    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var uri = Uri.parse('foo:bar');
    collector.getResolvedLibraryByUri('X', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri X
  CannotResolveUriResult
''');
  }

  test_getResolvedLibraryByUri_library_pending_getResolvedUnit() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(a);

    var collector = DriverEventCollector(driver);
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B1', b);

    var uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A2', uri);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[future] getResolvedLibraryByUri A2
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
      ResolvedUnitResult #1
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedLibraryByUri_notLibrary_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    var uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('X', uri);

    await assertEventsText(collector, r'''
[status] working
[future] getResolvedLibraryByUri X
  NotLibraryButPartResult
[status] idle
''');
  }

  test_getResolvedLibraryByUri_notLibraryButPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of my;');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);

    await assertEventsText(collector, r'''
[status] working
[future] getResolvedLibraryByUri A1
  NotLibraryButPartResult
[status] idle
''');
  }

  test_getResolvedLibraryByUri_unresolvedUri() async {
    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var uri = Uri.parse('package:unknown/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri A1
  CannotResolveUriResult
''');
  }

  test_getResolvedUnit() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_added() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    collector.getResolvedUnit('A1', a);

    // Note, no separate `ErrorsResult`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_importLibrary_thenRemoveIt() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
class B extends A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // No errors in `a` or `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');

    // Remove `a` and reanalyze.
    deleteFile(a.path);
    driver.removeFile2(a);

    // The unresolved URI error must be reported.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B2
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      7 +8 URI_DOES_NOT_EXIST
      33 +1 EXTENDS_NON_CLASS
[stream]
  ResolvedUnitResult #2
[status] idle
''');

    // Restore `a`.
    newFile(a.path, 'class A {}');
    driver.addFile2(a);

    // No errors in `b` again.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B2
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #3
[operation] getErrorsFromBytes
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ErrorsResult #4
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_getResolvedUnit_library_added_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    collector.getResolvedUnit('A1', a);

    // Note, the library is resolved only once.
    // Note, no separate `ErrorsResult` for `a` or `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_getResolvedUnit_library_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B1', b);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedUnit_library_pending_getErrors_part() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getErrors('B1', b);
    collector.getResolvedUnit('A1', a);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getErrors B1
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_getResolvedUnit_notDartFile() async {
    var a = newFile('$testPackageLibPath/a.txt', r'''
final foo = 0;
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    configuration.libraryConfiguration.unitConfiguration.variableTypesSelector =
        (result) {
      return [
        result.findElement2.topVar('foo'),
      ];
    };

    // The extension of the file does not matter.
    // If asked, we analyze it as Dart.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.txt
  library: /home/test/lib/a.txt
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.txt
    uri: package:test/a.txt
    flags: exists isLibrary
    selectedVariableTypes
      foo: int
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_part_doesNotExist_lints() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
linter:
  rules:
    - omit_local_variable_types
''');

    await assertErrorsInCode(r'''
library my.lib;
part 'a.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 21, 8),
    ]);
  }

  test_getResolvedUnit_part_empty_lints() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
linter:
  rules:
    - omit_local_variable_types
''');

    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode(r'''
library my.lib;
part 'a.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 21, 8),
    ]);
  }

  test_getResolvedUnit_part_hasPartOfName_notThisLibrary_lints() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
linter:
  rules:
    - omit_local_variable_types
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of other.lib;
''');

    await assertErrorsInCode(r'''
library my.lib;
part 'a.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY, 21, 8),
    ]);
  }

  test_getResolvedUnit_part_hasPartOfUri_notThisLibrary_lints() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
linter:
  rules:
    - omit_local_variable_types
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'not_test.dart';
''');

    await assertErrorsInCode(r'''
library my.lib;
part 'a.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY, 21, 8),
    ]);
  }

  test_getResolvedUnit_part_library() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedUnit('B1', b);
    collector.getResolvedUnit('A1', a);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedUnit_part_pending_getErrors_library() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getErrors('A1', a);
    collector.getResolvedUnit('B1', b);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedUnit_pending_getErrors() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedUnit('A1', a);
    collector.getErrors('A2', a);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getErrors A2
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_pending_getErrors2() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getErrors('A1', a);
    collector.getResolvedUnit('A2', a);

    // Note, the library is resolved only once.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A2
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getErrors A1
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_pending_getIndex() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getIndex('A1', a);
    collector.getResolvedUnit('A2', a);

    // Note, no separate `getIndex` result.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A2
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getIndex A1
  strings
    --nullString--
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_thenRemove() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Schedule resolved unit computation.
    collector.getResolvedUnit('A1', a);

    // ...and remove the file.
    driver.removeFile2(a);

    // The future with the result still completes.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedUnit_twoPendingFutures() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Ask the same file twice.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('A2', a);

    // Both futures complete.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit A2
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getUnitElement() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
void bar() {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    configuration.unitElementConfiguration.elementSelector = (unitFragment) {
      return unitFragment.functions2
          .map((fragment) => fragment.element)
          .toList();
    };

    collector.getUnitElement('A1', a);
    await assertEventsText(collector, r'''
[status] working
[future] getUnitElement A1
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  flags: isLibrary
  enclosing: <null>
  selectedElements
    package:test/a.dart::@function::foo
    package:test/a.dart::@function::bar
[status] idle
''');
  }

  test_getUnitElement_doesNotExist_afterResynthesized() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:test/b.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedLibrary A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
        errors
          7 +21 URI_DOES_NOT_EXIST
[stream]
  ResolvedUnitResult #1
[status] idle
''');

    collector.getUnitElement('A2', a);
    await assertEventsText(collector, r'''
[status] working
[future] getUnitElement A2
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  flags: isLibrary
  enclosing: <null>
[status] idle
''');
  }

  test_getUnitElement_invalidPath_notAbsolute() async {
    var driver = driverFor(testFile);
    var result = await driver.getUnitElement('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_hermetic_modifyLibraryFile_resolvePart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
final A = 0;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
final B = A;
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    configuration.libraryConfiguration.unitConfiguration.variableTypesSelector =
        (result) {
      switch (result.uriStr) {
        case 'package:test/b.dart':
          return [
            result.findElement2.topVar('B'),
          ];
        default:
          return [];
      }
    };

    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    selectedVariableTypes
      B: int
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Modify the library, but don't notify the driver.
    // The driver should use the previous library content and elements.
    modifyFile2(a, r'''
part 'b.dart';
final A = 1.2;
''');

    // Note, still `B: int`, not `B: double` yet.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit B2
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    selectedVariableTypes
      B: int
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[status] idle
''');
  }

  test_importOfNonLibrary_part_afterLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', '''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', '''
part of 'a.dart';
class B {}
''');

    var c = newFile('$testPackageLibPath/c.dart', '''
import 'b.dart';
''');

    var driver = driverFor(testFile);

    // This ensures that `a` linked library is cached.
    await driver.getResolvedUnit2(a);

    // Should not fail because of considering `b` part as `a` library.
    await driver.getResolvedUnit2(c);
  }

  test_knownFiles() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// ignore:unused_import
import 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
''');

    var driver = driverFor(testFile);

    driver.addFile2(a);
    driver.addFile2(c);
    await pumpEventQueue(times: 5000);
    expect(driver.knownFiles.resources, contains(a));
    expect(driver.knownFiles.resources, contains(b));
    expect(driver.knownFiles.resources, contains(c));

    // Remove `a` and analyze.
    // Both `a` and `b` are not known now.
    driver.removeFile2(a);
    await pumpEventQueue(times: 5000);
    expect(driver.knownFiles.resources, isNot(contains(a)));
    expect(driver.knownFiles.resources, isNot(contains(b)));
    expect(driver.knownFiles.resources, contains(c));
  }

  test_knownFiles_beforeAnalysis() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var driver = driverFor(testFile);

    // `a` is added, but not processed yet.
    // So, the set of known files is empty yet.
    driver.addFile2(a);
    expect(driver.knownFiles, isEmpty);
  }

  test_linkedBundleProvider_changeFile() async {
    var a = newFile('$testPackageLibPath/a.dart', 'var V = 1;');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.priorityFiles2 = [a];

    configuration.libraryConfiguration.unitConfiguration.variableTypesSelector =
        (result) {
      switch (result.uriStr) {
        case 'package:test/a.dart':
          return [
            result.findElement2.topVar('V'),
          ];
        default:
          return [];
      }
    };

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      V: int
[status] idle
''');

    // When no fine-grained dependencies, we don't cache bundles.
    // So, [LinkedBundleProvider] is empty, and not printed.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k01
    get: []
    put: [k01]
elementFactory
  hasElement
    package:test/a.dart
''');

    // Update the file, but don't notify the driver.
    // No new results.
    modifyFile2(a, 'var V = 1.2;');
    await assertEventsText(collector, r'''
''');

    // Notify the driver about the change.
    // We get a new result.
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      V: double
[status] idle
''');

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_6
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_6
        cycle_2
          dependencies: dart:core
          libraries: library_6
          apiSignature_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/a.dart
    current: cycle_2
      key: k03
    get: []
    put: [k01, k03]
elementFactory
  hasElement
    package:test/a.dart
''');
  }

  test_missingDartLibrary_async() async {
    var driver = driverFor(testFile);

    sdkRoot.getChildAssumingFile('lib/async/async.dart').delete();

    var a = newFile('$testPackageLibPath/a.dart', '');
    var result = await driver.getErrors(a.path);
    result as ErrorsResult;
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.MISSING_DART_LIBRARY, 0, 0),
    ]);
  }

  test_missingDartLibrary_core() async {
    var driver = driverFor(testFile);

    sdkRoot.getChildAssumingFile('lib/core/core.dart').delete();

    var a = newFile('$testPackageLibPath/a.dart', '');
    var result = await driver.getErrors(a.path);
    result as ErrorsResult;
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.MISSING_DART_LIBRARY, 0, 0),
    ]);
  }

  test_parseFileSync_appliesPendingFileChanges() async {
    var initialContent = 'initial content';
    var updatedContent = 'updated content';
    var a = newFile('$testPackageLibPath/a.dart', initialContent);

    // Check initial content.
    var driver = driverFor(testFile);
    var parsed = driver.parseFileSync(a.path) as ParsedUnitResult;
    expect(parsed.content, initialContent);

    // Update the file.
    newFile(a.path, updatedContent);
    driver.changeFile(a.path);

    // Expect parseFileSync to return the updated content.
    parsed = driver.parseFileSync(a.path) as ParsedUnitResult;
    expect(parsed.content, updatedContent);
  }

  test_parseFileSync_changedFile() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// ignore:unused_import
import 'a.dart';
void f(A a) {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Ensure that [a] library cycle is loaded.
    // So, `a` is in the library context.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Update the file, changing its API signature.
    // Note that we don't call `changeFile`.
    modifyFile2(a, r'''
class A {}
''');

    // Parse the file.
    // We have not called `changeFile(a)`, so we should not read the file.
    // Moreover, doing this will create a new library cycle [a].
    // Library cycles are compared by their identity, so we would try to
    // reload linked summary for [a], and crash.
    {
      var parseResult = driver.parseFileSync2(a) as ParsedUnitResult;
      expect(parseResult.unit.declarations, isEmpty);
    }

    // We have not read `a`, so `A` is still not declared.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      48 +1 UNDEFINED_CLASS
[stream]
  ResolvedUnitResult #1
[status] idle
''');

    // Notify the driver that `a` was changed.
    driver.changeFile2(a);

    // The pending change to `a` declares `A`.
    // So, `b` does not have errors anymore.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B2
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[status] idle
''');

    // We apply pending changes while handling request.
    // So, now `class A {}` is declared.
    {
      var result = driver.parseFileSync2(a) as ParsedUnitResult;
      assertParsedNodeText(result.unit, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      name: A
      leftBracket: {
      rightBracket: }
''');
    }
  }

  test_parseFileSync_doesNotReadImportedFiles() async {
    newFile('$testPackageLibPath/a.dart', r'''
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// ignore:unused_import
import 'a.dart';
''');

    var driver = driverFor(testFile);
    expect(driver.knownFiles, isEmpty);

    // Don't read `a` when parse.
    driver.parseFileSync2(b);
    expect(driver.knownFiles.resources, unorderedEquals([b]));

    // Still don't read `a.dart` when parse the second time.
    driver.parseFileSync2(b);
    expect(driver.knownFiles.resources, unorderedEquals([b]));
  }

  test_parseFileSync_notAbsolutePath() async {
    var driver = driverFor(testFile);
    var result = driver.parseFileSync('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_parseFileSync_notDart() async {
    var a = newFile('$testPackageLibPath/a.txt', r'''
class A {}
''');

    var driver = driverFor(testFile);

    var result = driver.parseFileSync2(a) as ParsedUnitResult;
    assertParsedNodeText(result.unit, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      name: A
      leftBracket: {
      rightBracket: }
''');

    expect(driver.knownFiles.resources, unorderedEquals([a]));
  }

  test_partOfName_getErrors_afterLibrary() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Process `a` so that we know that it's a library for `b`.
    collector.getErrors('A1', a);
    await assertEventsText(collector, r'''
[status] working
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[operation] analyzeFile
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');

    // We return cached errors.
    // TODO(scheglov): don't switch to analysis?
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] getErrorsFromBytes
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[future] getErrors B1
  ErrorsResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[status] idle
''');
  }

  test_partOfName_getErrors_beforeLibrary_addedFiles() async {
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// preEnhancedParts
// @dart = 3.4
part of a;
final a = A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We discover all added files are maybe libraries.
    driver.addFile2(a);
    driver.addFile2(b);

    // Because `a` is added, we know how to analyze `b`.
    // So, it has no errors.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] working
[future] getErrors B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_partOfName_getErrors_beforeLibrary_discovered() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part 'b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We discover sibling files as libraries.
    // So, we know that `a` is the library of `b`.
    // So, no errors.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] working
[future] getErrors B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_partOfName_getErrors_beforeLibrary_notDiscovered() async {
    newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We don't know that `a` is the library of `b`.
    // So, we treat it as its own library, has errors.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] working
[future] getErrors B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
    errors
      60 +1 CREATION_WITH_NON_TYPE
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      60 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_afterLibrary() async {
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Process `a` so that we know that it's a library for `b`.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');

    // We know that `b` is analyzed as part of `a`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_beforeLibrary_addedFiles() async {
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We discover all added files are maybe libraries.
    driver.addFile2(a);
    driver.addFile2(b);

    // Because `a` is added, we know how to analyze `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_beforeLibrary_notDiscovered() async {
    newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We don't know that `a` is the library of `b`.
    // So, we treat it as its own library.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      60 +1 CREATION_WITH_NON_TYPE
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_changePart_invalidatesLibraryCycle() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
import 'dart:async';
part 'b.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Analyze the library without the part.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    errors
      61 +8 URI_DOES_NOT_EXIST
      42 +12 UNUSED_IMPORT
[status] idle
''');

    // Create the part file.
    // This should invalidate library file state (specifically the library
    // cycle), so that we can re-link the library, and get new dependencies.
    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of 'a.dart';
Future<int>? f;
''');
    driver.changeFile2(b);

    // This should not crash.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_hasLibrary_noPart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library my.lib;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of my.lib;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Discover the library.
    driver.getFileSync2(a);

    // There is no library which `b` is a part of, so `A` is unresolved.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      65 +1 CREATION_WITH_NON_TYPE
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_noLibrary() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of my.lib;
var a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // There is no library which `b` is a part of, so `A` is unresolved.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      63 +1 CREATION_WITH_NON_TYPE
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getUnitElement_afterLibrary() async {
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Process `a` so that we know that it's a library for `b`.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[future] getResolvedUnit A1
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');

    // We know that `a` is the library for `b`.
    collector.getUnitElement('B1', b);
    await assertEventsText(collector, r'''
[status] working
[future] getUnitElement B1
  path: /home/test/lib/b.dart
  uri: package:test/b.dart
  flags: isPart
  enclosing: package:test/hidden/a.dart::<fragment>
[status] idle
''');
  }

  test_partOfName_getUnitElement_beforeLibrary_addedFiles() async {
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We discover all added files are maybe libraries.
    driver.addFile2(a);
    driver.addFile2(b);

    // Because `a` is added, we know how to analyze `b`.
    collector.getUnitElement('B1', b);
    await assertEventsText(collector, r'''
[status] working
[future] getUnitElement B1
  path: /home/test/lib/b.dart
  uri: package:test/b.dart
  flags: isPart
  enclosing: package:test/hidden/a.dart::<fragment>
[operation] analyzeFile
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_partOfName_getUnitElement_noLibrary() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We don't know the library for `b`.
    // So, we treat it as its own library.
    collector.getUnitElement('B1', b);
    await assertEventsText(collector, r'''
[status] working
[future] getUnitElement B1
  path: /home/test/lib/b.dart
  uri: package:test/b.dart
  flags: isPart
  enclosing: <null>
[status] idle
''');
  }

  test_partOfName_results_afterLibrary() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // The order does not matter.
    // It used to matter, but not anymore.
    driver.addFile2(a);
    driver.addFile2(b);

    // We discover all added libraries.
    // So, we know that `a` is the library of `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_partOfName_results_beforeLibrary() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // The order does not matter.
    // It used to matter, but not anymore.
    driver.addFile2(b);
    driver.addFile2(a);

    // We discover all added libraries.
    // So, we know that `a` is the library of `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_partOfName_results_beforeLibrary_priority() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    var a = newFile('$testPackageLibPath/hidden/a.dart', r'''
// @dart = 3.4
// preEnhancedParts
library a;
part '../b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // The order does not matter.
    // It used to matter, but not anymore.
    driver.addFile2(b);
    driver.addFile2(a);
    driver.priorityFiles2 = [b];

    // We discover all added libraries.
    // So, we know that `a` is the library of `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_partOfName_results_noLibrary() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(b);

    // There is no library for `b`.
    // So, we analyze `b` as its own library.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      60 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_partOfName_results_noLibrary_priority() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.4
// preEnhancedParts
part of a;
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(b);
    driver.priorityFiles2 = [b];

    // There is no library for `b`.
    // So, we analyze `b` as its own library.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      60 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_priorities_changed_importing_rest() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'c.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
import 'b.dart';
''');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);

    // Discard results so far.
    await collector.nextStatusIdle();
    collector.take();

    modifyFile2(b, r'''
class B2 {}
''');
    driver.changeFile2(b);

    // We analyze `b` first, because it was changed.
    // Then we analyze `c`, because it imports `b`.
    // Then we analyze `a`, because it also affected.
    // Note, there is no specific rule that says when `a` is analyzed.
    configuration.withStreamResolvedUnitResults = false;
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[operation] analyzeFile
  file: /home/test/lib/c.dart
  library: /home/test/lib/c.dart
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[status] idle
''');
  }

  test_priorities_changed_importing_withErrors_rest() async {
    // Note, is affected by `b`, but does not import it.
    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'b.dart';
''');

    // We will change this file.
    var b = newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    // Note, does not import `b` directly.
    var c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
class C extends X {}
''');

    // Note, does import `b`.
    var d = newFile('$testPackageLibPath/d.dart', r'''
import 'b.dart';
''');

    var driver = driverFor(a);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);

    // Discard results so far.
    await collector.nextStatusIdle();
    collector.take();

    modifyFile2(b, r'''
class B2 {}
''');
    driver.changeFile2(b);

    // We analyze `b` first, because it was changed.
    // The we analyze `d` because it import `b`.
    // Then we analyze `c` because it has errors.
    // Then we analyze `a` because it is affected.
    // For `a` because it just exports, there are no special rules.
    configuration.withStreamResolvedUnitResults = false;
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[operation] analyzeFile
  file: /home/test/lib/d.dart
  library: /home/test/lib/d.dart
[operation] analyzeFile
  file: /home/test/lib/c.dart
  library: /home/test/lib/c.dart
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[status] idle
''');
  }

  test_priorities_changedAll() async {
    // Make sure that `test2` is its own analysis context.
    var test1Path = '$workspaceRootPath/test1';
    writePackageConfig(
      test1Path,
      PackageConfigFileBuilder()..add(name: 'test1', rootPath: test1Path),
    );

    // Make sure that `test2` is its own analysis context.
    var test2Path = '$workspaceRootPath/test2';
    writePackageConfig(
      test2Path,
      PackageConfigFileBuilder()..add(name: 'test2', rootPath: test2Path),
    );

    // `b` imports `a`, so `b` is reanalyzed when `a` API changes.
    var a = newFile('$test1Path/lib/a.dart', 'class A {}');
    var b = newFile('$test1Path/lib/b.dart', "import 'a.dart';");

    // `d` imports `c`, so `d` is reanalyzed when `b` API changes.
    var c = newFile('$test2Path/lib/c.dart', 'class C {}');
    var d = newFile('$test2Path/lib/d.dart', "import 'c.dart';");

    var collector = DriverEventCollector.forCollection(
      analysisContextCollection,
    );

    var driver1 = driverFor(a);
    var driver2 = driverFor(c);

    // Ensure that we actually have two separate analysis contexts.
    expect(driver1, isNot(same(driver2)));

    // Subscribe for analysis.
    driver1.addFile2(a);
    driver1.addFile2(b);
    driver2.addFile2(c);
    driver2.addFile2(d);

    // Discard results so far.
    await collector.nextStatusIdle();
    collector.take();

    // Change `a` and `c` in a way that changed their API signatures.
    modifyFile2(a, 'class A2 {}');
    modifyFile2(c, 'class C2 {}');
    driver1.changeFile2(a);
    driver2.changeFile2(c);

    // Note, `a` and `c` analyzed first, because they were changed.
    // Even though they are in different drivers.
    configuration.withStreamResolvedUnitResults = false;
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test1/lib/a.dart
  library: /home/test1/lib/a.dart
[operation] analyzeFile
  file: /home/test2/lib/c.dart
  library: /home/test2/lib/c.dart
[operation] analyzeFile
  file: /home/test1/lib/b.dart
  library: /home/test1/lib/b.dart
[operation] analyzeFile
  file: /home/test2/lib/d.dart
  library: /home/test2/lib/d.dart
[status] idle
''');
  }

  test_priorities_getResolvedUnit_beforePriority() async {
    // Make sure that `test1` is its own analysis context.
    var test1Path = '$workspaceRootPath/test1';
    writePackageConfig(
      test1Path,
      PackageConfigFileBuilder()..add(name: 'test1', rootPath: test1Path),
    );

    // Make sure that `test2` is its own analysis context.
    var test2Path = '$workspaceRootPath/test2';
    writePackageConfig(
      test2Path,
      PackageConfigFileBuilder()..add(name: 'test2', rootPath: test2Path),
    );

    var a = newFile('$test1Path/lib/a.dart', '');
    var b = newFile('$test2Path/lib/b.dart', '');
    var c = newFile('$test2Path/lib/c.dart', '');

    var collector = DriverEventCollector.forCollection(
      analysisContextCollection,
    );

    var driver1 = driverFor(a);
    var driver2 = driverFor(c);

    // Ensure that we actually have two separate analysis contexts.
    expect(driver1, isNot(same(driver2)));

    // Subscribe for analysis.
    driver1.addFile2(a);
    driver2.addFile2(b);
    driver2.addFile2(c);

    driver1.priorityFiles2 = [a];
    driver2.priorityFiles2 = [c];

    collector.driver = driver2;
    collector.getResolvedUnit('B1', b);

    // We asked for `b`, so it is analyzed.
    // Even if it is not a priority file.
    // Even if it is in the `driver2`.
    configuration.withStreamResolvedUnitResults = false;
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test2/lib/b.dart
  library: /home/test2/lib/b.dart
[future] getResolvedUnit B1
  ResolvedUnitResult #0
    path: /home/test2/lib/b.dart
    uri: package:test2/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test1/lib/a.dart
  library: /home/test1/lib/a.dart
[operation] analyzeFile
  file: /home/test2/lib/c.dart
  library: /home/test2/lib/c.dart
[status] idle
''');
  }

  test_priorities_priority_rest() async {
    // Make sure that `test1` is its own analysis context.
    var test1Path = '$workspaceRootPath/test1';
    writePackageConfig(
      test1Path,
      PackageConfigFileBuilder()..add(name: 'test1', rootPath: test1Path),
    );

    // Make sure that `test2` is its own analysis context.
    var test2Path = '$workspaceRootPath/test2';
    writePackageConfig(
      test2Path,
      PackageConfigFileBuilder()..add(name: 'test2', rootPath: test2Path),
    );

    var a = newFile('$test1Path/lib/a.dart', '');
    var b = newFile('$test1Path/lib/b.dart', '');
    var c = newFile('$test2Path/lib/c.dart', '');
    var d = newFile('$test2Path/lib/d.dart', '');

    var collector = DriverEventCollector.forCollection(
      analysisContextCollection,
    );

    var driver1 = driverFor(a);
    var driver2 = driverFor(c);

    // Ensure that we actually have two separate analysis contexts.
    expect(driver1, isNot(same(driver2)));

    driver1.addFile2(a);
    driver1.addFile2(b);
    driver1.priorityFiles2 = [a];

    driver2.addFile2(c);
    driver2.addFile2(d);
    driver2.priorityFiles2 = [c];

    configuration.withStreamResolvedUnitResults = false;
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test1/lib/a.dart
  library: /home/test1/lib/a.dart
[operation] analyzeFile
  file: /home/test2/lib/c.dart
  library: /home/test2/lib/c.dart
[operation] analyzeFile
  file: /home/test1/lib/b.dart
  library: /home/test1/lib/b.dart
[operation] analyzeFile
  file: /home/test2/lib/d.dart
  library: /home/test2/lib/d.dart
[status] idle
''');
  }

  test_removeFile_addFile() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');

    driver.removeFile2(a);
    driver.addFile2(a);

    // The cache key for `a` errors is the same, return from bytes.
    // Note, no analysis.
    await assertEventsText(collector, r'''
[status] working
[operation] getErrorsFromBytes
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
final A = B;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
final B = 0;
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a, b];
    driver.addFile2(a);
    driver.addFile2(b);

    configuration.libraryConfiguration.unitConfiguration.variableTypesSelector =
        (result) {
      switch (result.uriStr) {
        case 'package:test/a.dart':
          return [
            result.findElement2.topVar('A'),
          ];
        case 'package:test/b.dart':
          return [
            result.findElement2.topVar('B'),
          ];
        default:
          return [];
      }
    };

    // We have results for both `a` and `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A: int
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    selectedVariableTypes
      B: int
[status] idle
''');

    // Remove `b` and send the change notification.
    modifyFile2(b, r'''
final B = 1.2;
''');
    driver.removeFile2(b);
    driver.changeFile2(b);

    // While `b` is not analyzed explicitly, it is analyzed implicitly.
    // We don't get a result for `b`.
    // But the change causes `a` to be reanalyzed.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A: double
[status] idle
''');
  }

  test_removeFile_changeFile_notAnalyzed() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // We don't analyze `a`, so we get nothing.
    await assertEventsText(collector, r'''
''');

    // Remove `a`, and also change it.
    // Still nothing, we still don't analyze `a`.
    driver.removeFile2(a);
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[status] idle
''');
  }

  test_removeFile_invalidate_importers() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
final a = new A();
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // No errors in `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[status] idle
''');

    // Remove `a`, so `b` is reanalyzed and has an error.
    deleteFile2(a);
    driver.removeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      7 +8 URI_DOES_NOT_EXIST
      31 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_removeFile_notAbsolutePath() async {
    var driver = driverFor(testFile);
    expect(() {
      driver.removeFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_results_order() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// ignore:unused_import
import 'd.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', '');

    var c = newFile('$testPackageLibPath/c.dart', r'''
// ignore:unused_import
import 'd.dart';
''');

    var d = newFile('$testPackageLibPath/d.dart', r'''
// ignore:unused_import
import 'b.dart';
''');

    var e = newFile('$testPackageLibPath/e.dart', r'''
// ignore:unused_import
export 'b.dart';
''');

    // This file intentionally has an error.
    var f = newFile('$testPackageLibPath/f.dart', r'''
// ignore:unused_import
import 'e.dart';
class F extends X {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);
    driver.addFile2(e);
    driver.addFile2(f);

    // Initial analysis, all files analyzed in order of adding.
    // Note, `f` has an error.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/c.dart
  library: /home/test/lib/c.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/d.dart
  library: /home/test/lib/d.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/e.dart
  library: /home/test/lib/e.dart
[stream]
  ResolvedUnitResult #4
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/f.dart
  library: /home/test/lib/f.dart
[stream]
  ResolvedUnitResult #5
    path: /home/test/lib/f.dart
    uri: package:test/f.dart
    flags: exists isLibrary
    errors
      57 +1 EXTENDS_NON_CLASS
[status] idle
''');

    // Update `b` with changing its API signature.
    modifyFile2(b, r'''
class B {}
''');
    driver.changeFile2(b);

    // 1. The changed `b` is the first.
    // 2. Then `d` that imports the changed `b`.
    // 3. Then `f` that has an error (even if it is unrelated).
    // 4. Then the rest, in order of adding.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #6
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/d.dart
  library: /home/test/lib/d.dart
[stream]
  ResolvedUnitResult #7
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/f.dart
  library: /home/test/lib/f.dart
[stream]
  ResolvedUnitResult #8
    path: /home/test/lib/f.dart
    uri: package:test/f.dart
    flags: exists isLibrary
    errors
      57 +1 EXTENDS_NON_CLASS
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #9
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/c.dart
  library: /home/test/lib/c.dart
[stream]
  ResolvedUnitResult #10
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/e.dart
  library: /home/test/lib/e.dart
[stream]
  ResolvedUnitResult #11
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_results_order_allChangedFirst_thenImports() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
''');

    var d = newFile('$testPackageLibPath/d.dart', r'''
// ignore:unused_import
import 'a.dart';
''');

    var e = newFile('$testPackageLibPath/e.dart', r'''
// ignore:unused_import
import 'b.dart';
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);
    driver.addFile2(e);

    // Initial analysis, all files analyzed in order of adding.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/c.dart
  library: /home/test/lib/c.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/d.dart
  library: /home/test/lib/d.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/e.dart
  library: /home/test/lib/e.dart
[stream]
  ResolvedUnitResult #4
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: exists isLibrary
[status] idle
''');

    // Change b.dart and then a.dart files.
    modifyFile2(a, r'''
class A2 {}
''');
    modifyFile2(b, r'''
class B2 {}
''');
    driver.changeFile2(b);
    driver.changeFile2(a);

    // First `a` and `b`.
    // Then `d` and `e` because they import `a` and `b`.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #5
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #6
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/d.dart
  library: /home/test/lib/d.dart
[stream]
  ResolvedUnitResult #7
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/e.dart
  library: /home/test/lib/e.dart
[stream]
  ResolvedUnitResult #8
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_results_removeFile_changeFile() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final v = 0;
''');

    var b = getFile('$testPackageLibPath/b.dart');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');

    // Update `a` to have an error.
    modifyFile2(a, r'''
final v = 0
''');

    // It does not matter what we do with `b`, it is not analyzed anyway.
    // But we notify that `a` was changed, so it is analyzed.
    driver.removeFile2(b);
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    errors
      10 +1 EXPECTED_TOKEN
[status] idle
''');
  }

  test_results_skipNotAffected() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[status] idle
''');

    // Update `a` and notify.
    modifyFile2(a, r'''
class A2 {}
''');
    driver.changeFile2(a);

    // Only `a` is analyzed, `b` is not affected.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_schedulerStatus_hasAddedFile() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[status] idle
''');
  }

  test_schedulerStatus_noAddedFile() async {
    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // No files, so no status changes.
    await assertEventsText(collector, r'''
''');
  }

  test_status_anyWorkTransitionsToAnalyzing() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // Initial analysis.
    configuration.withStreamResolvedUnitResults = false;
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[status] idle
''');

    // Any work transitions to analyzing, and back to idle.
    await driver.getFilesReferencingName('X');
    await assertEventsText(collector, r'''
[status] working
[status] idle
''');
  }
}

/// Tracks events reported into the `results` stream, and results of `getXyz`
/// requests. We are interested in relative orders, identity of the objects,
/// absence of duplicate events, etc.
class DriverEventCollector {
  final IdProvider idProvider;
  late AnalysisDriver driver;
  List<DriverEvent> events = [];
  final List<Completer<void>> statusIdleCompleters = [];

  DriverEventCollector(
    this.driver, {
    IdProvider? idProvider,
  }) : idProvider = idProvider ?? IdProvider() {
    _listenSchedulerEvents(driver.scheduler);
  }

  DriverEventCollector.forCollection(
    AnalysisContextCollectionImpl collection, {
    IdProvider? idProvider,
  }) : idProvider = idProvider ?? IdProvider() {
    _listenSchedulerEvents(collection.scheduler);
  }

  void getCachedResolvedUnit(String name, File file) {
    var value = driver.getCachedResolvedUnit2(file);
    events.add(
      GetCachedResolvedUnitEvent(
        name: name,
        result: value,
      ),
    );
  }

  void getErrors(String name, File file) {
    var future = driver.getErrors(file.path);
    unawaited(future.then((value) {
      events.add(
        GetErrorsEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  void getIndex(String name, File file) async {
    var value = await driver.getIndex(file.path);
    events.add(
      GetIndexEvent(
        name: name,
        result: value,
      ),
    );
  }

  void getLibraryByUri(String name, String uriStr) {
    var future = driver.getLibraryByUri(uriStr);
    unawaited(future.then((value) {
      events.add(
        GetLibraryByUriEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  void getResolvedLibrary(String name, File file) {
    var future = driver.getResolvedLibrary(file.path);
    unawaited(future.then((value) {
      events.add(
        GetResolvedLibraryEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  void getResolvedLibraryByUri(String name, Uri uri) {
    var future = driver.getResolvedLibraryByUri(uri);
    unawaited(future.then((value) {
      events.add(
        GetResolvedLibraryByUriEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  void getResolvedUnit(
    String name,
    File file, {
    bool sendCachedToStream = false,
  }) {
    var future = driver.getResolvedUnit(
      file.path,
      sendCachedToStream: sendCachedToStream,
    );

    unawaited(future.then((value) {
      events.add(
        GetResolvedUnitEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  void getUnitElement(String name, File file) {
    var future = driver.getUnitElement2(file);
    unawaited(future.then((value) {
      events.add(
        GetUnitElementEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  Future<void> nextStatusIdle() {
    var completer = Completer<void>();
    statusIdleCompleters.add(completer);
    return completer.future;
  }

  List<DriverEvent> take() {
    var result = events;
    events = [];
    return result;
  }

  void _listenSchedulerEvents(AnalysisDriverScheduler scheduler) {
    scheduler.eventsBroadcast.listen((event) {
      switch (event) {
        case AnalysisStatus():
          events.add(
            SchedulerStatusEvent(event),
          );
          if (event.isIdle) {
            statusIdleCompleters.completeAll();
            statusIdleCompleters.clear();
          }
        case driver_events.AnalyzeFile():
        case driver_events.AnalyzedLibrary():
        case driver_events.CannotReuseLinkedBundle():
        case driver_events.GetErrorsCannotReuse():
        case driver_events.GetErrorsFromBytes():
        case driver_events.LinkLibraryCycle():
        case driver_events.ProduceErrorsCannotReuse():
        case driver_events.ReuseLinkLibraryCycleBundle():
        case ErrorsResult():
        case ResolvedUnitResult():
          events.add(
            ResultStreamEvent(
              object: event,
            ),
          );
      }
    });
  }
}

@reflectiveTest
class FineAnalysisDriverTest extends PubPackageResolutionTest
    with _EventsMixin {
  @override
  bool get retainDataForTesting => true;

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    useEmptyByteStore();
  }

  @override
  Future<void> tearDown() async {
    withFineDependencies = false;
    return super.tearDown();
  }

  test_dependency_class_constructor_named_invocation() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A.named(int _);
}
''',
      testCode: r'''
import 'a.dart';
void f() {
  A.named(0);
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          named: #M1
[status] idle
''',
      updatedA: r'''
class A {
  A.named(double _);
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          named: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: named
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          named: #M4
[status] idle
''',
    );
  }

  test_dependency_class_constructor_named_invocation_add() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A.c1();
}
''',
      testCode: r'''
import 'a.dart';
void f() {
  A.c2();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      32 +2 UNDEFINED_METHOD
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M2
  requirements
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          c2: <null>
[status] idle
''',
      updatedA: r'''
class A {
  A.c1();
  A.c2();
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M3
  requirements
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: c2
    expectedId: <null>
    actualId: #M3
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          c2: #M3
[status] idle
''',
    );
  }

  test_dependency_class_constructor_named_invocation_notUsed() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A.c1();
  A.c2(int _);
}
''',
      testCode: r'''
import 'a.dart';
void f() {
  A.c1();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          c1: #M1
[status] idle
''',
      updatedA: r'''
class A {
  A.c1();
  A.c2(double _);
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M5
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_class_constructor_named_invocation_remove() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A.c1();
  A.c2();
}
''',
      testCode: r'''
import 'a.dart';
void f() {
  A.c2();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          c2: #M2
[status] idle
''',
      updatedA: r'''
class A {
  A.c1();
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
  requirements
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      32 +2 UNDEFINED_METHOD
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: c2
    expectedId: #M2
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          c2: <null>
[status] idle
''',
    );
  }

  test_dependency_class_constructor_named_superInvocation() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A.named(int _);
}
''',
      testCode: r'''
import 'a.dart';
class B extends A {
  B.foo() : super.named(0);
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      B: #M3
        declaredMembers
          foo: #M4
  requirements
    topLevels
      dart:core
        A: <null>
        named: <null>
      package:test/a.dart
        A: #M0
        named: <null>
    interfaceMembers
      package:test/a.dart
        A
          named: #M1
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
        named: <null>
      package:test/a.dart
        A: #M0
        named: <null>
    interfaceMembers
      package:test/a.dart
        A
          named: #M1
[status] idle
''',
      updatedA: r'''
class A {
  A.named(double _);
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          named: #M5
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: named
    expectedId: #M1
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      B: #M3
        declaredMembers
          foo: #M4
  requirements
    topLevels
      dart:core
        A: <null>
        named: <null>
      package:test/a.dart
        A: #M0
        named: <null>
    interfaceMembers
      package:test/a.dart
        A
          named: #M5
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: named
    expectedId: #M1
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
        named: <null>
      package:test/a.dart
        A: #M0
        named: <null>
    interfaceMembers
      package:test/a.dart
        A
          named: #M5
[status] idle
''',
    );
  }

  test_dependency_class_constructor_unnamed() async {
    configuration
      ..includeDefaultConstructors()
      ..withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A(int _);
}
''',
      testCode: r'''
import 'a.dart';
void f() {
  A(0);
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          new: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          new: #M1
[status] idle
''',
      updatedA: r'''
class A {
  A(double _);
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          new: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: new
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          new: #M4
[status] idle
''',
    );
  }

  test_dependency_class_getter_inherited_fromGeneric_extends_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T get foo {}
}

class B extends A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T get foo {}
}

class B extends A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_getter_inherited_fromGeneric_implements_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T get foo {}
}

class B implements A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T get foo {}
}

class B implements A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_getter_inherited_fromGeneric_with_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T get foo {}
}

class B with A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T get foo {}
}

class B with A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_getter_returnType() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  int get foo => 0;
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {
  double get foo => 1.2;
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M4
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_getter_returnType_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  int get foo => 0;
  int get bar => 0;
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M2
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {
  int get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_class_it_add() async {
    await _runChangeScenarioTA(
      initialA: '',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] linkLibraryCycle
  package:test/a.dart
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[status] idle
''',
      updatedA: r'''
class A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M1
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: <null>
    actualId: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M1
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: <null>
    actualId: #M1
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M1
[status] idle
''',
    );
  }

  test_dependency_class_it_add_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
''',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
class A {}
class B {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M2
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_class_it_change() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
class B {}
''',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
class A extends B {}
class B {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M3
      B: #M1
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M4
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M3
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: #M3
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M3
[status] idle
''',
    );
  }

  test_dependency_class_it_change_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
class B {}
class C {}
''',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
class A {}
class B extends C {}
class C {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M4
      C: #M2
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_class_it_remove() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
''',
      testCode: r'''
import 'a.dart';
A foo() => throw 0;
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: '',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: <null>
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[status] idle
''',
    );
  }

  test_dependency_class_it_remove_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
class B {}
''',
      testCode: r'''
import 'a.dart';
A foo() => throw 0;
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
class A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_class_method_add() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_METHOD
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {
  int foo() {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: <null>
    actualId: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M2
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_inherited_fromGeneric_extends2_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T foo() {}
}

class B extends A<int> {}

class C extends B {}
''',
      testCode: r'''
import 'a.dart';
void f(C c) {
  c.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
      C: #M3
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M4
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M5
  requirements
    topLevels
      dart:core
        C: <null>
      package:test/a.dart
        C: #M3
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        C: <null>
      package:test/a.dart
        C: #M3
    interfaceMembers
      package:test/a.dart
        C
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T foo() {}
}

class B extends A<double> {}

class C extends B {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M6
        inheritedMembers
          foo: #M1
      C: #M7
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M8
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: C
    expectedId: #M3
    actualId: #M7
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M9
  requirements
    topLevels
      dart:core
        C: <null>
      package:test/a.dart
        C: #M7
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: C
    expectedId: #M3
    actualId: #M7
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        C: <null>
      package:test/a.dart
        C: #M7
    interfaceMembers
      package:test/a.dart
        C
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_inherited_fromGeneric_extends_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T foo() {}
}

class B extends A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T foo() {}
}

class B extends A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_inherited_fromGeneric_implements_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T foo() {}
}

class B implements A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T foo() {}
}

class B implements A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_inherited_fromGeneric_with_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  T foo() {}
}

class B with A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A<T> {
  T foo() {}
}

class B with A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_remove() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  void foo() {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_METHOD
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: #M1
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_returnType() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  int foo() {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {
  double foo() {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M4
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_method_returnType_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  int foo() {}
  int bar() {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M2
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {
  int foo() {}
  double bar() {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M5
          foo: #M2
  requirements
    topLevels
      dart:core
        double: #M6
        int: #M3
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_class_setter_add() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
      updatedA: r'''
class A {
  set foo(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo=
    expectedId: <null>
    actualId: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M2
[status] idle
''',
    );
  }

  test_dependency_class_setter_inherited_fromGeneric_extends_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  set foo(T _) {}
}

class B extends A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
class A<T> {
  set foo(T _) {}
}

class B extends A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M5
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
    );
  }

  test_dependency_class_setter_inherited_fromGeneric_implements_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  set foo(T _) {}
}

class B implements A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
class A<T> {
  set foo(T _) {}
}

class B implements A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M5
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
    );
  }

  test_dependency_class_setter_inherited_fromGeneric_with_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A<T> {
  set foo(T _) {}
}

class B with A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
class A<T> {
  set foo(T _) {}
}

class B with A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M5
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
    );
  }

  test_dependency_class_setter_remove() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  set foo(int _) {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
class A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo=
    expectedId: #M1
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_class_setter_valueType() async {
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  set foo(int _) {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
class A {
  set foo(double _) {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo=
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M4
[status] idle
''',
    );
  }

  test_dependency_classTypaAlias_constructor_named() async {
    configuration
      .withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
class A {
  A.named(int _);
}
mixin M {}
class B = A with M;
''',
      testCode: r'''
import 'a.dart';
void f() {
  B.named(0);
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
      B: #M2
        inheritedMembers
          named: #M1
      M: #M3
  requirements
    topLevels
      dart:core
        int: #M4
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M5
  requirements
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          named: #M1
[status] idle
''',
      updatedA: r'''
class A {
  A.named(double _);
}
mixin M {}
class B = A with M;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          named: #M6
      B: #M2
        inheritedMembers
          named: #M6
      M: #M3
  requirements
    topLevels
      dart:core
        double: #M7
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: B
    memberName: named
    expectedId: #M1
    actualId: #M6
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          named: #M6
[status] idle
''',
    );
  }

  test_dependency_export_noLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart';
export ':';
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 1;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart';
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::b
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      b: package:test/a.dart::<fragment>::@getter::b#element
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/test.dart
    exportedUri: package:test/a.dart
    name: b
    expectedId: <null>
    actualId: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      b: #M1
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
        b: #M1
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add_combinators_hide_false() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart' hide b;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          hide b
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add_combinators_hide_true() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart' hide c;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          hide c
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::b
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      b: package:test/a.dart::<fragment>::@getter::b#element
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/test.dart
    exportedUri: package:test/a.dart
    name: b
    expectedId: <null>
    actualId: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      b: #M1
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          hide c
        a: #M0
        b: #M1
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add_combinators_show_false() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart' show a;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          show a
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add_combinators_show_true() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart' show a, b;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          show a, b
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::b
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      b: package:test/a.dart::<fragment>::@getter::b#element
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/test.dart
    exportedUri: package:test/a.dart
    name: b
    expectedId: <null>
    actualId: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      b: #M1
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          show a, b
        a: #M0
        b: #M1
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add_combinators_showHide_true() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart' show a, b hide c;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          show a, b
          hide c
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::b
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      b: package:test/a.dart::<fragment>::@getter::b#element
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/test.dart
    exportedUri: package:test/a.dart
    name: b
    expectedId: <null>
    actualId: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      b: #M1
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          show a, b
          hide c
        a: #M0
        b: #M1
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_add_private() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart';
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final _b = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      _b: #M1
      a: #M0
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_remove() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
final b = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart';
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::b
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      b: package:test/a.dart::<fragment>::@getter::b#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      b: #M1
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
        b: #M1
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] cannotReuseLinkedBundle
  exportCountMismatch
    fragmentUri: package:test/test.dart
    exportedUri: package:test/a.dart
    actual: 1
    required: 2
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_remove_show_false() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
final b = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart' show a;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        combinators
          show a
        a: #M0
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_replace() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
final b = 0;
''');

    newFile('$testPackageLibPath/test.dart', r'''
export 'a.dart';
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::b
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      b: package:test/a.dart::<fragment>::@getter::b#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      b: #M1
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
        b: #M1
[status] idle
''',
      updateFiles: () {
        modifyFile2(a, r'''
final a = 0;
final c = 0;
''');
        return [a];
      },
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      c: #M2
  requirements
[future] getLibraryByUri T2
  library
    exportedReferences
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::a
      exported[(0, 0)] package:test/a.dart::<fragment>::@getter::c
    exportNamespace
      a: package:test/a.dart::<fragment>::@getter::a#element
      c: package:test/a.dart::<fragment>::@getter::c#element
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/test.dart
    exportedUri: package:test/a.dart
    name: c
    expectedId: <null>
    actualId: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    reExportMap
      a: #M0
      c: #M2
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
        c: #M2
[status] idle
''',
    );
  }

  test_dependency_export_topLevelVariable_type() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    // Uses exported `a`.
    newFile('$testPackageLibPath/test.dart', r'''
import 'b.dart';
final x = a;
''');

    configuration.elementTextConfiguration.withExportScope = true;
    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
    exportedReferences
      declared <testLibraryFragment>::@getter::x
    exportNamespace
      x: <testLibraryFragment>::@getter::x#element
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/b.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M1
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/b.dart
        a: #M0
[status] idle
''',
      // Change the initializer, now `double`.
      updateFiles: () {
        modifyFile2(a, r'''
final a = 1.2;
''');
        return [a];
      },
      // Linked, `x` has type `double`.
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M2
  requirements
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: double
    exportedReferences
      declared <testLibraryFragment>::@getter::x
    exportNamespace
      x: <testLibraryFragment>::@getter::x#element
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/b.dart
    exportedUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M2
[operation] linkLibraryCycle
  package:test/b.dart
    reExportMap
      a: #M2
  requirements
    exportRequirements
      package:test/a.dart
        a: #M2
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/b.dart
    name: a
    expectedId: #M0
    actualId: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M3
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/b.dart
        a: #M2
[status] idle
''',
    );
  }

  test_dependency_mixin_getter_inherited_fromGeneric_on_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
mixin A<T> {
  T get foo {}
}

mixin B on A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A<T> {
  T get foo {}
}

mixin B on A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_getter_returnType() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  int get foo => 0;
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {
  double get foo => 1.2;
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M4
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_getter_returnType_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  int get foo => 0;
  int get bar => 0;
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M2
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {
  int get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_mixin_it_add() async {
    await _runChangeScenarioTA(
      initialA: '',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] linkLibraryCycle
  package:test/a.dart
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[status] idle
''',
      updatedA: r'''
mixin A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M1
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: <null>
    actualId: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M1
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: <null>
    actualId: #M1
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M1
[status] idle
''',
    );
  }

  test_dependency_mixin_it_add_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
''',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
mixin A {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M2
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_mixin_it_change() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
mixin B {}
''',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
mixin A on B {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M3
      B: #M1
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M4
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M3
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: #M3
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M3
[status] idle
''',
    );
  }

  test_dependency_mixin_it_change_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
mixin B {}
mixin C {}
''',
      testCode: r'''
import 'a.dart';
A foo() {}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
mixin A {}
mixin B on C {}
mixin C {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M4
      C: #M2
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      19 +3 BODY_MIGHT_COMPLETE_NORMALLY
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_mixin_it_remove() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
''',
      testCode: r'''
import 'a.dart';
A foo() => throw 0;
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: '',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: <null>
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: A
    expectedId: #M0
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      17 +1 UNDEFINED_CLASS
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_it_remove_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
mixin B {}
''',
      testCode: r'''
import 'a.dart';
A foo() => throw 0;
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
      B: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[status] idle
''',
      updatedA: r'''
mixin A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_mixin_method_add() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_METHOD
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {
  int foo() {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: <null>
    actualId: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M2
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_method_inherited_fromGeneric_implements_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
mixin A<T> {
  T foo() {}
}

mixin B implements A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A<T> {
  T foo() {}
}

mixin B implements A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_method_inherited_fromGeneric_on_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
mixin A<T> {
  T foo() {}
}

mixin B on A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A<T> {
  T foo() {}
}

mixin B on A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M5
        inheritedMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: #M1
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_method_remove() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  void foo() {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M2
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_METHOD
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: #M1
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_method_returnType() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  int foo() {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M1
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {
  double foo() {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M4
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_method_returnType_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  int foo() {}
  int bar() {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo();
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: #M2
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {
  int foo() {}
  double bar() {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M5
          foo: #M2
  requirements
    topLevels
      dart:core
        double: #M6
        int: #M3
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_dependency_mixin_setter_add() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M1
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
      updatedA: r'''
mixin A {
  set foo(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
  requirements
    topLevels
      dart:core
        int: #M3
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo=
    expectedId: <null>
    actualId: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M2
[status] idle
''',
    );
  }

  test_dependency_mixin_setter_inherited_fromGeneric_on_changeTypeArgument() async {
    configuration.withStreamResolvedUnitResults = false;
    await _runChangeScenarioTA(
      initialA: r'''
mixin A<T> {
  set foo(T _) {}
}

mixin B on A<int> {}
''',
      testCode: r'''
import 'a.dart';
void f(B b) {
  b.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M4
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M2
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
mixin A<T> {
  set foo(T _) {}
}

mixin B on A<double> {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M5
        inheritedMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        double: #M6
[future] getErrors T2
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M7
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: B
    expectedId: #M2
    actualId: #M5
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        B: <null>
      package:test/a.dart
        B: #M5
    interfaceMembers
      package:test/a.dart
        B
          foo: <null>
          foo=: #M1
[status] idle
''',
    );
  }

  test_dependency_mixin_setter_remove() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  set foo(int _) {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
mixin A {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
  requirements
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo=
    expectedId: #M1
    actualId: <null>
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
    errors
      35 +3 UNDEFINED_SETTER
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      dart:core
        Object
          foo: <null>
          foo=: <null>
      package:test/a.dart
        A
          foo: <null>
          foo=: <null>
[status] idle
''',
    );
  }

  test_dependency_mixin_setter_valueType() async {
    await _runChangeScenarioTA(
      initialA: r'''
mixin A {
  set foo(int _) {}
}
''',
      testCode: r'''
import 'a.dart';
void f(A a) {
  a.foo = 0;
}
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      f: #M3
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M1
[status] idle
''',
      updatedA: r'''
mixin A {
  set foo(double _) {}
}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M4
  requirements
    topLevels
      dart:core
        double: #M5
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsCannotReuse
  instanceMemberIdMismatch
    libraryUri: package:test/a.dart
    interfaceName: A
    memberName: foo=
    expectedId: #M1
    actualId: #M4
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        A: <null>
      package:test/a.dart
        A: #M0
    interfaceMembers
      package:test/a.dart
        A
          foo: <null>
          foo=: #M4
[status] idle
''',
    );
  }

  test_dependency_topLevelFunction() async {
    await _runChangeScenarioTA(
      initialA: r'''
int foo() {}
''',
      testCode: r'''
import 'a.dart';
final x = foo();
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      foo: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        foo: <null>
      package:test/a.dart
        foo: #M0
[status] idle
''',
      updatedA: r'''
double foo() {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      foo: #M3
  requirements
    topLevels
      dart:core
        double: #M4
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: double
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: foo
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M5
  requirements
    topLevels
      dart:core
        foo: <null>
      package:test/a.dart
        foo: #M3
[status] idle
''',
    );
  }

  test_dependency_topLevelFunction_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
int foo() {}
int bar() {}
''',
      testCode: r'''
import 'a.dart';
final x = foo();
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      bar: #M0
      foo: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M3
  requirements
    topLevels
      dart:core
        foo: <null>
      package:test/a.dart
        foo: #M1
[status] idle
''',
      updatedA: r'''
int foo() {}
double bar() {}
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      bar: #M4
      foo: #M1
  requirements
    topLevels
      dart:core
        double: #M5
        int: #M2
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_topLevelGetter() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
double get a => 1.2;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M3
  requirements
    topLevels
      dart:core
        double: #M4
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: double
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M5
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M3
[status] idle
''',
    );
  }

  test_dependency_topLevelGetter_notUsed() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
int get b => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M1
  requirements
    topLevels
      dart:core
        int: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M3
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
int get a => 0;
double get b => 1.2;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M4
  requirements
    topLevels
      dart:core
        double: #M5
        int: #M2
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  test_dependency_topLevelVariable() async {
    await _runChangeScenarioTA(
      initialA: r'''
final a = 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M1
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      // Change the initializer, now `double`.
      updatedA: r'''
final a = 1.2;
''',
      // Linked, `x` has type `double`.
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M2
  requirements
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: double
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M3
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M2
[status] idle
''',
    );
  }

  test_dependency_topLevelVariable_exported() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    // Uses exported `a`.
    newFile('$testPackageLibPath/test.dart', r'''
import 'b.dart';
final x = a;
''');

    await _runChangeScenario(
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
[operation] linkLibraryCycle
  package:test/b.dart
    reExportMap
      a: #M0
  requirements
    exportRequirements
      package:test/a.dart
        a: #M0
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M1
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/b.dart
        a: #M0
[status] idle
''',
      // Change the initializer, now `double`.
      updateFiles: () {
        modifyFile2(a, r'''
final a = 1.2;
''');
        return [a];
      },
      // Linked, `x` has type `double`.
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M2
  requirements
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: double
[operation] cannotReuseLinkedBundle
  exportIdMismatch
    fragmentUri: package:test/b.dart
    exportedUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M2
[operation] linkLibraryCycle
  package:test/b.dart
    reExportMap
      a: #M2
  requirements
    exportRequirements
      package:test/a.dart
        a: #M2
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/b.dart
    name: a
    expectedId: #M0
    actualId: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M3
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/b.dart
        a: #M2
[status] idle
''',
    );
  }

  test_linkedBundleProvider_newBundleKey() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      // Here `k02` is for `dart:core`.
      expectedInitialDriverState: r'''
files
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
  /home/test/lib/test.dart
    current: cycle_0
      key: k01
    get: []
    put: [k01]
linkedBundleProvider: [k01, k02]
elementFactory
  hasElement
    package:test/test.dart
''',
      // Add a part, this changes the linked bundle key.
      updateFiles: () {
        var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
final b = 0;
''');
        return [a];
      },
      updatedCode: r'''
part 'a.dart';
final a = 0;
''',
      // So, we cannot find the existing library manifest.
      // So, we relink the library, and give new IDs.
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
      b: #M2
''',
      // Note a new bundle key is generated: k05
      // TODO(scheglov): Here is a memory leak: k01 is still present.
      expectedUpdatedDriverState: r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_6
      kind: partOfUriKnown_6
        uriFile: file_0
        library: library_7
      referencingFiles: file_0
      unlinkedKey: k03
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_1 dart:core synthetic
        partIncludes
          partOfUriKnown_6
        fileKinds: library_7 partOfUriKnown_6
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k04
libraryCycles
  /home/test/lib/test.dart
    current: cycle_2
      key: k05
    get: []
    put: [k01, k05]
linkedBundleProvider: [k01, k02, k05]
elementFactory
  hasElement
    package:test/test.dart
''',
    );
  }

  test_linkedBundleProvider_sameBundleKey() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      expectedInitialDriverState: r'''
files
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
  /home/test/lib/test.dart
    current: cycle_0
      key: k01
    get: []
    put: [k01]
linkedBundleProvider: [k01, k02]
elementFactory
  hasElement
    package:test/test.dart
''',
      updatedCode: r'''
final a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
      expectedUpdatedDriverState: r'''
files
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_0
      kind: library_6
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_6
        cycle_2
          dependencies: dart:core
          libraries: library_6
          apiSignature_1
      unlinkedKey: k03
libraryCycles
  /home/test/lib/test.dart
    current: cycle_2
      key: k01
    get: []
    put: [k01, k01]
linkedBundleProvider: [k01, k02]
elementFactory
  hasElement
    package:test/test.dart
''',
    );
  }

  test_manifest_class_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
''',
      updatedCode: r'''
class A {}
class B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
    );
  }

  test_manifest_class_constructor_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  A.foo();
  A.bar();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_constructor_formalParameter_requiredPositional() async {
    configuration.includeDefaultConstructors();
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.foo(int a);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  A.foo(int a);
  A.bar();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_constructor_formalParameter_requiredPositional_add() async {
    configuration.includeDefaultConstructors();
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A(int a);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          new: #M1
''',
      updatedCode: r'''
class A {
  A(int a, int b);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          new: #M2
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A.named(int x);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
''',
      updatedCode: r'''
class A {
  const A.named(int x) : assert(x > 0);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M2
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_assert() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A.named(int x) : assert(x > 0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
''',
      updatedCode: r'''
class A {
  const A.named(int x) : assert(x > 1);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M2
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_fieldInitializer_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int foo;
  const A.named() : bar = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
          named: #M2
''',
      updatedCode: r'''
class A {
  final int foo;
  const A.named() : foo = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
          named: #M3
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_fieldInitializer_value() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int foo;
  const A.named() : foo = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
          named: #M2
''',
      updatedCode: r'''
class A {
  final int foo;
  const A.named() : foo = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
          named: #M3
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_redirect_argument() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int f;
  const A.c1(int a) : f = a;
  const A.c2() : this.c1(0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          f: #M3
''',
      updatedCode: r'''
class A {
  final int f;
  const A.c1(int a) : f = a;
  const A.c2() : this.c1(1);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M4
          f: #M3
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_redirect_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int f;
  const A.c1() : f = 0;
  const A.c2() : f = 1;
  const A.c3() : this.c1();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          c3: #M3
          f: #M4
''',
      updatedCode: r'''
class A {
  final int f;
  const A.c1() : f = 0;
  const A.c2() : f = 1;
  const A.c3() : this.c2();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          c3: #M5
          f: #M4
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A.named(int x) : assert(x > 0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
''',
      updatedCode: r'''
class A {
  const A.named(int x);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M2
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_super_argument() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A.named(int _);
}

class B extends A {
  const A.named() : super.named(0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
      B: #M2
        declaredMembers
          named: #M3
''',
      updatedCode: r'''
class A {
  const A.named(int _);
}

class B extends A {
  const A.named() : super.named(1);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
      B: #M2
        declaredMembers
          named: #M4
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_super_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int f;
  const A.c1() : f = 0;
  const A.c2() : f = 1;
}

class B extends A {
  const A.named() : super.c1(0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          f: #M3
      B: #M4
        declaredMembers
          named: #M5
        inheritedMembers
          f: #M3
''',
      updatedCode: r'''
class A {
  final int f;
  const A.c1() : f = 0;
  const A.c2() : f = 1;
}

class B extends A {
  const A.named() : super.c2(0);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          f: #M3
      B: #M4
        declaredMembers
          named: #M6
        inheritedMembers
          f: #M3
''',
    );
  }

  test_manifest_class_constructor_initializers_isConst_super_transitive() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int f;
  const A.named() : f = 0;
}

class B extends A {
  const A.named() : super.named();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          f: #M1
          named: #M2
      B: #M3
        declaredMembers
          named: #M4
        inheritedMembers
          f: #M1
''',
      updatedCode: r'''
class A {
  final int f;
  const A.named() : f = 1;
}

class B extends A {
  const A.named() : super.named();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          f: #M1
          named: #M5
      B: #M3
        declaredMembers
          named: #M6
        inheritedMembers
          f: #M1
''',
    );
  }

  test_manifest_class_constructor_initializers_notConst_assert() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.named(int x) : assert(x > 0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
''',
      updatedCode: r'''
class A {
  A.named(int x) : assert(x > 1);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
''',
    );
  }

  test_manifest_class_constructor_initializers_notConst_fieldInitializer_value() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int foo;
  A.named() : foo = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
          named: #M2
''',
      updatedCode: r'''
class A {
  final int foo;
  A.named() : foo = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
          named: #M2
''',
    );
  }

  test_manifest_class_constructor_initializers_notConst_redirect_argument() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final int f;
  A.c1(int a) : f = a;
  A.c2() : this.c1(0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          f: #M3
''',
      updatedCode: r'''
class A {
  final int f;
  A.c1(int a) : f = a;
  A.c2() : this.c1(1);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
          f: #M3
''',
    );
  }

  test_manifest_class_constructor_initializers_notConst_super_argument() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A.named(int _);
}

class B extends A {
  A.named() : super.named(0);
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
      B: #M2
        declaredMembers
          named: #M3
''',
      updatedCode: r'''
class A {
  const A.named(int _);
}

class B extends A {
  A.named() : super.named(1);
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
      B: #M2
        declaredMembers
          named: #M3
''',
    );
  }

  test_manifest_class_constructor_isConst_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  const A.foo();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_constructor_isConst_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A.foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  A.foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_constructor_isFactory_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  factory A.foo();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_constructor_isFactory_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  factory A.foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  A.foo();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_constructor_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  @Deprected('0')
  A.foo();
  @Deprected('0')
  A.bar();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
class A {
  @Deprected('1')
  A.foo();
  @Deprected('0')
  A.bar();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M3
''',
    );
  }

  test_manifest_class_constructor_private() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A._foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
class A {
  A._foo();
  A.bar();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_class_constructor_private_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A._foo();
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
class A {
  const A._foo();
  A.bar();
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_class_extendsAdd_direct() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
class B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
class A extends B {}
class B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M2
      B: #M1
''',
    );
  }

  test_manifest_class_extendsAdd_indirect() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A extends B {}
class B {}
class C {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
''',
      updatedCode: r'''
class A extends B {}
class B extends C {}
class C {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M3
      B: #M4
      C: #M2
''',
    );
  }

  test_manifest_class_extendsChange() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A extends B {}
class B {}
class C {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
''',
      updatedCode: r'''
class A extends C {}
class B {}
class C {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M3
      B: #M1
      C: #M2
''',
    );
  }

  test_manifest_class_field_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
class A {
  final a = 0;
  final b = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          b: #M2
''',
    );
  }

  test_manifest_class_field_initializer_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
class A {
  final a = 1.2;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M2
''',
    );
  }

  test_manifest_class_field_initializer_value_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
class A {
  final a = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
    );
  }

  test_manifest_class_field_initializer_value_static_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static const a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
class A {
  static const a = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M2
''',
    );
  }

  test_manifest_class_field_initializer_value_static_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
class A {
  static final a = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
    );
  }

  test_manifest_class_field_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  @Deprecated('0')
  var a = 0;
  @Deprecated('0')
  var b = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          a=: #M2
          b: #M3
          b=: #M4
''',
      updatedCode: r'''
class A {
  @Deprecated('0')
  var a = 0;
  @Deprecated('1')
  var b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          a=: #M2
          b: #M5
          b=: #M6
''',
    );
  }

  test_manifest_class_field_private_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  final _a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
''',
      updatedCode: r'''
class A {
  final _a = 0;
  final b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          b: #M2
''',
    );
  }

  test_manifest_class_field_private_static_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static const _a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
''',
      updatedCode: r'''
class A {
  static const _a = 0;
  static const b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          b: #M2
''',
    );
  }

  test_manifest_class_field_private_var() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  var _a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          _a=: #M2
''',
      updatedCode: r'''
class A {
  var _a = 0;
  var b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          _a=: #M2
          b: #M3
          b=: #M4
''',
    );
  }

  test_manifest_class_field_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int? a;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          a=: #M2
''',
      updatedCode: r'''
class A {
  double? a;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M3
          a=: #M4
''',
    );
  }

  test_manifest_class_getter_add_extends() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get foo => 0;
}

class B extends A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  int get foo => 0;
  int get bar => 0;
}

class B extends A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_add_extends_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T get foo => 0;
}

class B extends A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T get foo => 0;
  T get bar => 0;
}

class B extends A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_add_implements() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get foo => 0;
}

class B implements A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  int get foo => 0;
  int get bar => 0;
}

class B implements A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_add_implements_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T get foo => 0;
}

class B implements A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T get foo => 0;
  T get bar => 0;
}

class B implements A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_add_with() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get foo => 0;
}

class B with A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  int get foo => 0;
  int get bar => 0;
}

class B with A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_add_with_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T get foo => 0;
}

class B with A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T get foo => 0;
  T get bar => 0;
}

class B with A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  @Deprecated('0')
  int get foo => 0;
  @Deprecated('0')
  int get bar => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
class A {
  @Deprecated('1')
  int get foo => 0;
  @Deprecated('0')
  int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M3
''',
    );
  }

  test_manifest_class_getter_private_instance() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get _foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
class A {
  int get _foo => 0;
  int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_class_getter_private_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static int get _foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
class A {
  static int get _foo => 0;
  int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_class_getter_returnType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo: #M1
            returnType: int @ dart:core
''',
      updatedCode: r'''
class A {
  double get foo => 1.2;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo: #M2
            returnType: double @ dart:core
''',
    );
  }

  test_manifest_class_getter_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  static int get foo => 0;
  static int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_getter_static_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  static int get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_getter_static_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  static double get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_getter_static_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  int get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_interfacesAdd() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
class B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
class A implements B {}
class B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M2
      B: #M1
''',
    );
  }

  test_manifest_class_interfacesRemove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A implements B {}
class B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
class A {}
class B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M2
      B: #M1
''',
    );
  }

  test_manifest_class_interfacesReplace() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A implements B {}
class B {}
class C {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
''',
      updatedCode: r'''
class A implements C {}
class B {}
class C {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M3
      B: #M1
      C: #M2
''',
    );
  }

  test_manifest_class_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@Deprecated('0')
class A {}
@Deprecated('0')
class B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
@Deprecated('0')
class A {}
@Deprecated('1')
class B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M2
''',
    );
  }

  test_manifest_class_method_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_extends() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo() {}
}

class B extends A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo() {}
  void bar() {}
}

class B extends A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_extends_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T foo() {}
}

class B extends A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T foo() {}
  void bar() {}
}

class B extends A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_extends_generic2() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T foo() {}
}

class B extends A<int> {}

class C extends B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
      C: #M3
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T foo() {}
  void bar() {}
}

class B extends A<int> {}

class C extends B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M4
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M4
          foo: #M1
      C: #M3
        inheritedMembers
          bar: #M4
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_implements() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo() {}
}

class B implements A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo() {}
  void bar() {}
}

class B implements A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_implements_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T foo() {}
}

class B implements A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T foo() {}
  void bar() {}
}

class B implements A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_with() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo() {}
}

class B with A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo() {}
  void bar() {}
}

class B with A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_method_add_with_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  T foo() {}
}

class B with A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
class A<T> {
  T foo() {}
  void bar() {}
}

class B with A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_class_method_formalParameter_optionalNamed() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo({int a}) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo({int a}) {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_method_formalParameter_optionalPositional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo([int a]) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo([int a]) {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_method_formalParameter_requiredNamed() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo({required int a}) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo({required int a}) {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_method_formalParameter_requiredNamed_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo({required int a}) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo({required int b}) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_formalParameter_requiredNamed_type() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo({required int a}) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo: #M1
            functionType: FunctionType
              named
                a: required int @ dart:core
              returnType: void
''',
      updatedCode: r'''
class A {
  void foo({required double a}) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo: #M2
            functionType: FunctionType
              named
                a: required double @ dart:core
              returnType: void
''',
    );
  }

  test_manifest_class_method_formalParameter_requiredPositional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo(int a) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo(int a) {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_class_method_formalParameter_requiredPositional_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo(int a) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo(int b) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
    );
  }

  test_manifest_class_method_formalParameter_requiredPositional_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo(int a) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo(double a) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  @Deprecated('0')
  void foo() {}
  @Deprecated('0')
  void bar() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
class A {
  @Deprecated('1')
  void foo() {}
  @Deprecated('0')
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M3
''',
    );
  }

  test_manifest_class_method_private_instance() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void _foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
class A {
  void _foo() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_class_method_private_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static void _foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
class A {
  static void _foo() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_class_method_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo() {}
  void bar() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
class A {
  void foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_returnType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo: #M1
            functionType: FunctionType
              returnType: int @ dart:core
''',
      updatedCode: r'''
class A {
  double foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo: #M2
            functionType: FunctionType
              returnType: double @ dart:core
''',
    );
  }

  test_manifest_class_method_static_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  static void foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_static_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static int foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  static double foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_static_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static void foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_typeParameter() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  Map<T, U> foo<U>() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        typeParameters
          bound: <null>
        supertype: Object @ dart:core
        declaredMembers
          foo: #M1
            functionType: FunctionType
              typeParameters
                bound: <null>
              returnType: Map @ dart:core
                typeParameter#1
                typeParameter#0
''',
      updatedCode: r'''
class A<T> {
  Map<T, U> foo<U>() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        typeParameters
          bound: <null>
        supertype: Object @ dart:core
        declaredMembers
          bar: #M2
            functionType: FunctionType
              returnType: void
          foo: #M1
            functionType: FunctionType
              typeParameters
                bound: <null>
              returnType: Map @ dart:core
                typeParameter#1
                typeParameter#0
''',
    );
  }

  test_manifest_class_method_typeParameter_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo<T>() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo<T, U>() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_method_typeParameter_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo<T, U>() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
class A {
  void foo<T>() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_class_private() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class _A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _A: #M0
''',
      updatedCode: r'''
class _A {}
class B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      B: #M1
      _A: #M0
''',
    );
  }

  test_manifest_class_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
''',
      updatedCode: '',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
''',
    );
  }

  test_manifest_class_setter_add_extends() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set foo(int _) {}
}

class B extends A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  set foo(int _) {}
  set bar(int _) {}
}

class B extends A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_add_extends_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  set foo(T _) {}
}

class B extends A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
class A<T> {
  set foo(T _) {}
  set bar(T _) {}
}

class B extends A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_add_implements() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set foo(int _) {}
}

class B implements A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  set foo(int _) {}
  set bar(int _) {}
}

class B implements A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_add_implements_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  set foo(T _) {}
}

class B implements A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
class A<T> {
  set foo(T _) {}
  set bar(T _) {}
}

class B implements A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_add_with() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set foo(int _) {}
}

class B with A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  set foo(int _) {}
  set bar(int _) {}
}

class B with A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_add_with_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A<T> {
  set foo(T _) {}
}

class B with A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
class A<T> {
  set foo(T _) {}
  set bar(T _) {}
}

class B with A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  @Deprecated('0')
  set foo(int _) {}
  @Deprecated('0')
  set bar(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M1
          foo=: #M2
''',
      updatedCode: r'''
class A {
  @Deprecated('1')
  set foo(int _) {}
  @Deprecated('0')
  set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M1
          foo=: #M3
''',
    );
  }

  test_manifest_class_setter_private_instance() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set _foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
''',
      updatedCode: r'''
class A {
  set _foo(int _) {}
  set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
          bar=: #M2
''',
    );
  }

  test_manifest_class_setter_private_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static set _foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
''',
      updatedCode: r'''
class A {
  static set _foo(int _) {}
  set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
          bar=: #M2
''',
    );
  }

  test_manifest_class_setter_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  static set foo(int _) {}
  static set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M2
          foo=: #M1
''',
    );
  }

  test_manifest_class_setter_static_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  static set foo(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
''',
    );
  }

  test_manifest_class_setter_static_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  set foo(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
''',
    );
  }

  test_manifest_class_setter_static_valueType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
class A {
  static set foo(double _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
''',
    );
  }

  test_manifest_class_setter_valueType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo=: #M1
            valueType: int @ dart:core
''',
      updatedCode: r'''
class A {
  set foo(double _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        supertype: Object @ dart:core
        declaredMembers
          foo=: #M2
            valueType: double @ dart:core
''',
    );
  }

  test_manifest_classTypeAlias_constructors_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.c1();
}
mixin M {}
class X = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
      M: #M2
      X: #M3
        inheritedMembers
          c1: #M1
''',
      updatedCode: r'''
class A {
  A.c1();
  A.c2();
}
mixin M {}
class X = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M4
      M: #M2
      X: #M3
        inheritedMembers
          c1: #M1
          c2: #M4
''',
    );
  }

  test_manifest_classTypeAlias_constructors_add_chain_backward() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.c1();
}
mixin M {}
class X1 = X2 with M;
class X2 = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
      M: #M2
      X1: #M3
        inheritedMembers
          c1: #M1
      X2: #M4
        inheritedMembers
          c1: #M1
''',
      updatedCode: r'''
class A {
  A.c1();
  A.c2();
}
mixin M {}
class X1 = X2 with M;
class X2 = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M5
      M: #M2
      X1: #M3
        inheritedMembers
          c1: #M1
          c2: #M5
      X2: #M4
        inheritedMembers
          c1: #M1
          c2: #M5
''',
    );
  }

  test_manifest_classTypeAlias_constructors_add_chain_forward() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.c1();
}
mixin M {}
class X1 = A with M;
class X2 = X1 with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
      M: #M2
      X1: #M3
        inheritedMembers
          c1: #M1
      X2: #M4
        inheritedMembers
          c1: #M1
''',
      updatedCode: r'''
class A {
  A.c1();
  A.c2();
}
mixin M {}
class X1 = A with M;
class X2 = X1 with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M5
      M: #M2
      X1: #M3
        inheritedMembers
          c1: #M1
          c2: #M5
      X2: #M4
        inheritedMembers
          c1: #M1
          c2: #M5
''',
    );
  }

  test_manifest_classTypeAlias_constructors_change() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.c1();
  A.c2(int _);
}
mixin M {}
class X = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
      M: #M3
      X: #M4
        inheritedMembers
          c1: #M1
          c2: #M2
''',
      updatedCode: r'''
class A {
  A.c1();
  A.c2(double _);
}
mixin M {}
class X = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M5
      M: #M3
      X: #M4
        inheritedMembers
          c1: #M1
          c2: #M5
''',
    );
  }

  test_manifest_classTypeAlias_constructors_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.c1();
  A.c2();
}
mixin M {}
class X = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
          c2: #M2
      M: #M3
      X: #M4
        inheritedMembers
          c1: #M1
          c2: #M2
''',
      updatedCode: r'''
class A {
  A.c1();
}
mixin M {}
class X = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          c1: #M1
      M: #M3
      X: #M4
        inheritedMembers
          c1: #M1
''',
    );
  }

  test_manifest_classTypeAlias_extends() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
class B {}
mixin M {}
class X = A with M;
class Y = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      M: #M2
      X: #M3
      Y: #M4
''',
      updatedCode: r'''
class A {}
class B {}
mixin M {}
class X = A with M;
class Y = B with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      M: #M2
      X: #M3
      Y: #M5
''',
    );
  }

  test_manifest_classTypeAlias_getter() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int get foo1 => 0;
  int get foo2 => 0;
}

mixin M {
  int get foo3 => 0;
  int get foo4 => 0;
}

class X = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo1: #M1
          foo2: #M2
      M: #M3
        declaredMembers
          foo3: #M4
          foo4: #M5
      X: #M6
        inheritedMembers
          foo1: #M1
          foo2: #M2
          foo3: #M4
          foo4: #M5
''',
      updatedCode: r'''
class A {
  int get foo1 => 0;
  double get foo2 => 0;
}

mixin M {
  int get foo3 => 0;
  double get foo4 => 0;
}

class X = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo1: #M1
          foo2: #M7
      M: #M3
        declaredMembers
          foo3: #M4
          foo4: #M8
      X: #M6
        inheritedMembers
          foo1: #M1
          foo2: #M7
          foo3: #M4
          foo4: #M8
''',
    );
  }

  test_manifest_classTypeAlias_interfaces() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
mixin M {}
class X1 = Object with M;
class X2 = Object with M implements A;
class X3 = Object with M;
class X4 = Object with M implements A;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      M: #M1
      X1: #M2
      X2: #M3
      X3: #M4
      X4: #M5
''',
      updatedCode: r'''
class A {}
mixin M {}
class X1 = Object with M;
class X2 = Object with M implements A;
class X3 = Object with M implements A;
class X4 = Object with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      M: #M1
      X1: #M2
      X2: #M3
      X3: #M6
      X4: #M7
''',
    );
  }

  test_manifest_classTypeAlias_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin M {}
@Deprecated('0')
class X = Object with M;
@Deprecated('0')
class Y = Object with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      M: #M0
      X: #M1
      Y: #M2
''',
      updatedCode: r'''
mixin M {}
@Deprecated('0')
class X = Object with M;
@Deprecated('1')
class Y = Object with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      M: #M0
      X: #M1
      Y: #M3
''',
    );
  }

  test_manifest_classTypeAlias_method() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  void foo1(int _) {}
  void foo2(int _) {}
}

mixin M {
  void foo3(int _) {}
  void foo4(int _) {}
}

class X = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo1: #M1
          foo2: #M2
      M: #M3
        declaredMembers
          foo3: #M4
          foo4: #M5
      X: #M6
        inheritedMembers
          foo1: #M1
          foo2: #M2
          foo3: #M4
          foo4: #M5
''',
      updatedCode: r'''
class A {
  void foo1(int _) {}
  void foo2(double _) {}
}

mixin M {
  void foo3(int _) {}
  void foo4(double _) {}
}

class X = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo1: #M1
          foo2: #M7
      M: #M3
        declaredMembers
          foo3: #M4
          foo4: #M8
      X: #M6
        inheritedMembers
          foo1: #M1
          foo2: #M7
          foo3: #M4
          foo4: #M8
''',
    );
  }

  test_manifest_classTypeAlias_setter() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  set foo1(int _) {}
  set foo2(int _) {}
}

mixin M {
  set foo3(int _) {}
  set foo4(int _) {}
}

class X = A with M;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo1=: #M1
          foo2=: #M2
      M: #M3
        declaredMembers
          foo3=: #M4
          foo4=: #M5
      X: #M6
        inheritedMembers
          foo1=: #M1
          foo2=: #M2
          foo3=: #M4
          foo4=: #M5
''',
      updatedCode: r'''
class A {
  set foo1(int _) {}
  set foo2(double _) {}
}

mixin M {
  set foo3(int _) {}
  set foo4(double _) {}
}

class X = A with M;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo1=: #M1
          foo2=: #M7
      M: #M3
        declaredMembers
          foo3=: #M4
          foo4=: #M8
      X: #M6
        inheritedMembers
          foo1=: #M1
          foo2=: #M7
          foo3=: #M4
          foo4=: #M8
''',
    );
  }

  test_manifest_constInitializer_adjacentStrings() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 0;
const c = '$a' 'x';
const d = 'x' '$a';
const e = '$b' 'x';
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
      e: #M4
''',
      updatedCode: r'''
const a = 1;
const b = 0;
const c = '$a' 'x';
const d = 'x' '$a';
const e = '$b' 'x';
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M5
      b: #M1
      c: #M6
      d: #M7
      e: #M4
''',
    );
  }

  test_manifest_constInitializer_asExpression() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 0;
const c = a as int;
const d = b as int;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
const a = 0;
const b = 1;
const c = a as int;
const d = b as int;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M4
      c: #M2
      d: #M5
''',
    );
  }

  test_manifest_constInitializer_binaryExpression() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0 + 1;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = 0 + 1;
const b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_left_change() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = a + 2;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
      updatedCode: r'''
const a = 1;
const b = a + 2;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M2
      b: #M3
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_left_token() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0 + 1;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = 2 + 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_operator() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  const A();
  int operator+(_) {}
}
const a = A();
const x = a + 1;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          +: #M1
      a: #M2
      x: #M3
''',
      updatedCode: r'''
class A {
  const A();
  double operator+(_) {}
}
const a = A();
const x = a + 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          +: #M4
      a: #M2
      x: #M5
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_operator_token() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0 + 1;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = 0 - 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_right() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 2 + a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
      updatedCode: r'''
const a = 1;
const b = 2 + a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M2
      b: #M3
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_right_add() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
const b = 0 + a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      b: #M0
        returnType: double @ dart:core
        constInitializer
          tokenBuffer: 0+a
          tokenLengthList: [1, 1, 1]
          elements
            [2] (dart:core, num, +) #M1
          elementIndexList: [0, 3]
''',
      updatedCode: r'''
const a = 1;
const b = 0 + a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M2
        returnType: int @ dart:core
        constInitializer
          tokenBuffer: 1
          tokenLengthList: [1]
      b: #M3
        returnType: int @ dart:core
        constInitializer
          tokenBuffer: 0+a
          tokenLengthList: [1, 1, 1]
          elements
            [2] (package:test/test.dart, a) <null>
            [3] (dart:core, num, +) #M1
          elementIndexList: [3, 4]
''',
    );
  }

  test_manifest_constInitializer_binaryExpression_right_remove() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 1 + a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
        returnType: int @ dart:core
        constInitializer
          tokenBuffer: 0
          tokenLengthList: [1]
      b: #M1
        returnType: int @ dart:core
        constInitializer
          tokenBuffer: 1+a
          tokenLengthList: [1, 1, 1]
          elements
            [2] (package:test/test.dart, a) <null>
            [3] (dart:core, num, +) #M2
          elementIndexList: [3, 4]
''',
      updatedCode: r'''
const b = 1 + a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      b: #M3
        returnType: double @ dart:core
        constInitializer
          tokenBuffer: 1+a
          tokenLengthList: [1, 1, 1]
          elements
            [2] (dart:core, num, +) #M2
          elementIndexList: [0, 3]
''',
    );
  }

  test_manifest_constInitializer_boolLiteral() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = true;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = true;
const b = false;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_constInitializer_conditionalExpression() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = true;
const b = true;
const c = a ? 0 : 1;
const d = b ? 0 : 1;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
const a = true;
const b = false;
const c = a ? 0 : 1;
const d = b ? 0 : 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M4
      c: #M2
      d: #M5
''',
    );
  }

  test_manifest_constInitializer_constructorName_named() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A.named();
}
const a = A.named();
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M1
      a: #M2
''',
      updatedCode: r'''
class A {
  A.named(int _);
}
const a = A.named();
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          named: #M3
      a: #M4
''',
    );
  }

  test_manifest_constInitializer_constructorName_unnamed() async {
    configuration.ignoredManifestInstanceMemberNames.remove('new');
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A();
}
const a = A();
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          new: #M1
      a: #M2
''',
      updatedCode: r'''
class A {
  A(int _);
}
const a = A();
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          new: #M3
      a: #M4
''',
    );
  }

  test_manifest_constInitializer_constructorName_unnamed_notAffected() async {
    configuration.ignoredManifestInstanceMemberNames.remove('new');
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A();
}
const a = A();
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          new: #M1
      a: #M2
''',
      updatedCode: r'''
class A {
  A();
  void foo() {}
}
const a = A();
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M3
          new: #M1
      a: #M2
''',
    );
  }

  test_manifest_constInitializer_dynamicElement() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0 as dynamic;
const b = 0 as dynamic;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
      updatedCode: r'''
const a = 0 as dynamic;
const b = 0 as int;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M2
''',
    );
  }

  test_manifest_constInitializer_instanceCreation_argument() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  A(_);
}
const a = 0;
const b = 0;
const c = A(a);
const d = A(b);
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      a: #M1
      b: #M2
      c: #M3
      d: #M4
''',
      updatedCode: r'''
class A {
  A(_);
}
const a = 1;
const b = 0;
const c = A(a);
const d = A(b);
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      a: #M5
      b: #M2
      c: #M6
      d: #M4
''',
    );
  }

  test_manifest_constInitializer_integerLiteral() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = 0;
const b = 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_constInitializer_integerLiteral_value() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_constInitializer_listLiteral() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 0;
const c = [a];
const d = [b];
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
const a = 1;
const b = 0;
const c = [a];
const d = [b];
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M4
      b: #M1
      c: #M5
      d: #M3
''',
    );
  }

  test_manifest_constInitializer_mapLiteral_key() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 0;
const c = {a: 0};
const d = {b: 0};
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
const a = 1;
const b = 0;
const c = {a: 0};
const d = {b: 0};
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M4
      b: #M1
      c: #M5
      d: #M3
''',
    );
  }

  test_manifest_constInitializer_mapLiteral_value() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 0;
const c = {0: a};
const d = {0: b};
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
const a = 1;
const b = 0;
const c = {0: a};
const d = {0: b};
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M4
      b: #M1
      c: #M5
      d: #M3
''',
    );
  }

  test_manifest_constInitializer_namedType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {}
class B {}
const a = A;
const b = B;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      a: #M2
      b: #M3
''',
      updatedCode: r'''
class A {}
class B extends A {}
const a = A;
const b = B;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M4
      a: #M2
      b: #M5
''',
    );
  }

  test_manifest_constInitializer_prefixedIdentifier_className_fieldName() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  static const a = 0;
  static const b = 0;
}

const c = A.a;
const d = A.b;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          b: #M2
      c: #M3
      d: #M4
''',
      updatedCode: r'''
class A {
  static const a = 0;
  static const b = 1;
}

const c = A.a;
const d = A.b;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          b: #M5
      c: #M3
      d: #M6
''',
    );
  }

  test_manifest_constInitializer_prefixedIdentifier_importPrefix_className_fieldName() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
import '' as self;

class A {
  static const a = 0;
  static const b = 0;
}

const c = self.A.a;
const d = self.A.b;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          b: #M2
      c: #M3
      d: #M4
''',
      updatedCode: r'''
import '' as self;

class A {
  static const a = 0;
  static const b = 1;
}

const c = self.A.a;
const d = self.A.b;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          b: #M5
      c: #M3
      d: #M6
''',
    );
  }

  test_manifest_constInitializer_prefixedIdentifier_importPrefix_topVariable() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
import '' as self;
const a = 0;
const b = 0;
const c = self.a;
const d = self.b;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
import '' as self;
const a = 0;
const b = 1;
const c = self.a;
const d = self.b;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M4
      c: #M2
      d: #M5
''',
    );
  }

  test_manifest_constInitializer_prefixedIdentifier_importPrefix_topVariable_changePrefix() async {
    newFile('$testPackageLibPath/a.dart', '');

    await _runLibraryManifestScenario(
      initialCode: r'''
import 'a.dart' as x;
const z = x.x + y.y;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/a.dart
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      z: #M0
''',
      updatedCode: r'''
import 'a.dart' as y;
const z = x.x + y.y;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      z: #M1
''',
    );
  }

  test_manifest_constInitializer_prefixedIdentifier_importPrefix_topVariable_changeUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
const x = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
const x = 0;
''');

    await _runLibraryManifestScenario(
      initialCode: r'''
import 'a.dart' as p;
const z = p.x;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      x: #M0
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      z: #M1
''',
      updatedCode: r'''
import 'b.dart' as p;
const z = p.x;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/b.dart
    manifest
      x: #M2
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      z: #M3
''',
    );
  }

  test_manifest_constInitializer_prefixExpression() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int operator-() {}
}
const a = A();
const b = -a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          unary-: #M1
      a: #M2
      b: #M3
''',
      updatedCode: r'''
class A {
  double operator-() {}
}
const a = A();
const b = -a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          unary-: #M4
      a: #M2
      b: #M5
''',
    );
  }

  test_manifest_constInitializer_prefixExpression_notAffected() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
class A {
  int operator-() {}
}
const a = A();
const b = -a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          unary-: #M1
      a: #M2
      b: #M3
''',
      updatedCode: r'''
class A {
  int operator-() {}
  void foo() {}
}
const a = A();
const b = -a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M4
          unary-: #M1
      a: #M2
      b: #M3
''',
    );
  }

  test_manifest_constInitializer_propertyAccess_stringLength() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = '0'.length;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = '1'.length;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_constInitializer_setLiteral() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
const b = 0;
const c = {a};
const d = {b};
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
      c: #M2
      d: #M3
''',
      updatedCode: r'''
const a = 1;
const b = 0;
const c = {a};
const d = {b};
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M4
      b: #M1
      c: #M5
      d: #M3
''',
    );
  }

  test_manifest_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@deprecated
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
@deprecated
int get a => 0;
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_metadata_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
@deprecated
int get a => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_metadata_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@deprecated
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
int get a => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_metadata_simpleIdentifier_change() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
@a
int get foo => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      foo: #M1
''',
      updatedCode: r'''
const a = 1;
@a
int get foo => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M2
      foo: #M3
''',
    );
  }

  test_manifest_metadata_simpleIdentifier_replace() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@deprecated
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
@override
int get a => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_mixin_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
''',
      updatedCode: r'''
mixin A {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
    );
  }

  test_manifest_mixin_field_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
mixin A {
  final a = 0;
  final b = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          b: #M2
''',
    );
  }

  test_manifest_mixin_field_initializer_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
mixin A {
  final a = 1.2;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M2
''',
    );
  }

  test_manifest_mixin_field_initializer_value_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
mixin A {
  final a = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
    );
  }

  test_manifest_mixin_field_initializer_value_static_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static const a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
mixin A {
  static const a = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M2
''',
    );
  }

  test_manifest_mixin_field_initializer_value_static_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static final a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
      updatedCode: r'''
mixin A {
  static final a = 1;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
''',
    );
  }

  test_manifest_mixin_field_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  @Deprecated('0')
  var a = 0;
  @Deprecated('0')
  var b = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          a=: #M2
          b: #M3
          b=: #M4
''',
      updatedCode: r'''
mixin A {
  @Deprecated('0')
  var a = 0;
  @Deprecated('1')
  var b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          a=: #M2
          b: #M5
          b=: #M6
''',
    );
  }

  test_manifest_mixin_field_private_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  final _a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
''',
      updatedCode: r'''
mixin A {
  final _a = 0;
  final b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          b: #M2
''',
    );
  }

  test_manifest_mixin_field_private_static_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static const _a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
''',
      updatedCode: r'''
mixin A {
  static const _a = 0;
  static const b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          b: #M2
''',
    );
  }

  test_manifest_mixin_field_private_var() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  var _a = 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          _a=: #M2
''',
      updatedCode: r'''
mixin A {
  var _a = 0;
  var b = 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _a: #M1
          _a=: #M2
          b: #M3
          b=: #M4
''',
    );
  }

  test_manifest_mixin_field_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int? a;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M1
          a=: #M2
''',
      updatedCode: r'''
mixin A {
  double? a;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          a: #M3
          a=: #M4
''',
    );
  }

  test_manifest_mixin_getter_add_implements() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int get foo => 0;
}

mixin B implements A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  int get foo => 0;
  int get bar => 0;
}

mixin B implements A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_getter_add_implements_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  T get foo => 0;
}

mixin B implements A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A<T> {
  T get foo => 0;
  T get bar => 0;
}

mixin B implements A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_getter_add_on() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int get foo => 0;
}

mixin B on A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  int get foo => 0;
  int get bar => 0;
}

mixin B on A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_getter_add_on_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  T get foo => 0;
}

mixin B on A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A<T> {
  T get foo => 0;
  T get bar => 0;
}

mixin B on A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_getter_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  @Deprecated('0')
  int get foo => 0;
  @Deprecated('0')
  int get bar => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
mixin A {
  @Deprecated('1')
  int get foo => 0;
  @Deprecated('0')
  int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M3
''',
    );
  }

  test_manifest_mixin_getter_private_instance() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int get _foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
mixin A {
  int get _foo => 0;
  int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_mixin_getter_private_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static int get _foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
mixin A {
  static int get _foo => 0;
  int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_mixin_getter_returnType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo: #M1
            returnType: int @ dart:core
''',
      updatedCode: r'''
mixin A {
  double get foo => 1.2;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo: #M2
            returnType: double @ dart:core
''',
    );
  }

  test_manifest_mixin_getter_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  static int get foo => 0;
  static int get bar => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_mixin_getter_static_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  static int get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_getter_static_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  static double get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_getter_static_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static int get foo => 0;
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  int get foo => 0;
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_interfacesAdd() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {}
mixin B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
mixin A implements B {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M2
      B: #M1
''',
    );
  }

  test_manifest_mixin_interfacesRemove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A implements B {}
mixin B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
mixin A {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M2
      B: #M1
''',
    );
  }

  test_manifest_mixin_interfacesReplace() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A implements B {}
mixin B {}
mixin C {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
''',
      updatedCode: r'''
mixin A implements C {}
mixin B {}
mixin C {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M3
      B: #M1
      C: #M2
''',
    );
  }

  test_manifest_mixin_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@Deprecated('0')
mixin A {}
@Deprecated('0')
mixin B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
@Deprecated('0')
mixin A {}
@Deprecated('1')
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M2
''',
    );
  }

  test_manifest_mixin_method_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  void foo() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M2
          foo: #M1
''',
    );
  }

  test_manifest_mixin_method_add_implements() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo() {}
}

mixin B implements A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  void foo() {}
  void bar() {}
}

mixin B implements A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_method_add_implements_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  T foo() {}
}

mixin B implements A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A<T> {
  T foo() {}
  void bar() {}
}

mixin B implements A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_method_add_on() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo() {}
}

mixin B on A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  void foo() {}
  void bar() {}
}

mixin B extends A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_method_add_on_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  T foo() {}
}

mixin B extends A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
      B: #M2
        inheritedMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A<T> {
  T foo() {}
  void bar() {}
}

mixin B extends A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M3
          foo: #M1
      B: #M2
        inheritedMembers
          bar: #M3
          foo: #M1
''',
    );
  }

  test_manifest_mixin_method_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  @Deprecated('0')
  void foo() {}
  @Deprecated('0')
  void bar() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
mixin A {
  @Deprecated('1')
  void foo() {}
  @Deprecated('0')
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M3
''',
    );
  }

  test_manifest_mixin_method_private_instance() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void _foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
mixin A {
  void _foo() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_mixin_method_private_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static void _foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
''',
      updatedCode: r'''
mixin A {
  static void _foo() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo: #M1
          bar: #M2
''',
    );
  }

  test_manifest_mixin_method_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo() {}
  void bar() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar: #M1
          foo: #M2
''',
      updatedCode: r'''
mixin A {
  void foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_method_returnType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  int foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo: #M1
            functionType: FunctionType
              returnType: int @ dart:core
''',
      updatedCode: r'''
mixin A {
  double foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo: #M2
            functionType: FunctionType
              returnType: double @ dart:core
''',
    );
  }

  test_manifest_mixin_method_static_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  static void foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_method_static_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static int foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  static double foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_method_static_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static void foo() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  void foo() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_method_typeParameter() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  Map<T, U> foo<U>() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        typeParameters
          bound: <null>
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo: #M1
            functionType: FunctionType
              typeParameters
                bound: <null>
              returnType: Map @ dart:core
                typeParameter#1
                typeParameter#0
''',
      updatedCode: r'''
mixin A<T> {
  Map<T, U> foo<U>() {}
  void bar() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        typeParameters
          bound: <null>
        superclassConstraints
          Object @ dart:core
        declaredMembers
          bar: #M2
            functionType: FunctionType
              returnType: void
          foo: #M1
            functionType: FunctionType
              typeParameters
                bound: <null>
              returnType: Map @ dart:core
                typeParameter#1
                typeParameter#0
''',
    );
  }

  test_manifest_mixin_method_typeParameter_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo<T>() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  void foo<T, U>() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_method_typeParameter_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  void foo<T, U>() {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M1
''',
      updatedCode: r'''
mixin A {
  void foo<T>() {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo: #M2
''',
    );
  }

  test_manifest_mixin_onAdd_direct() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {}
mixin B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
mixin A on B {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M2
      B: #M1
''',
    );
  }

  test_manifest_mixin_onAdd_indirect() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A on B {}
mixin B {}
mixin C {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
''',
      updatedCode: r'''
mixin A on B {}
mixin B on C {}
mixin C {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M3
      B: #M4
      C: #M2
''',
    );
  }

  test_manifest_mixin_onChange() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A on B {}
mixin B {}
mixin C {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
      C: #M2
''',
      updatedCode: r'''
mixin A on C {}
mixin B {}
mixin C {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M3
      B: #M1
      C: #M2
''',
    );
  }

  test_manifest_mixin_private() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin _A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _A: #M0
''',
      updatedCode: r'''
mixin _A {}
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      B: #M1
      _A: #M0
''',
    );
  }

  test_manifest_mixin_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {}
mixin B {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
      B: #M1
''',
      updatedCode: r'''
mixin B {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      B: #M1
''',
    );
  }

  test_manifest_mixin_setter_add_implements() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  set foo(int _) {}
}

mixin B implements A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A {
  set foo(int _) {}
  set bar(int _) {}
}

mixin B implements A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_mixin_setter_add_implements_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  set foo(T _) {}
}

mixin B implements A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A<T> {
  set foo(T _) {}
  set bar(T _) {}
}

mixin B implements A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_mixin_setter_add_on() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  set foo(int _) {}
}

mixin B on A {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A {
  set foo(int _) {}
  set bar(int _) {}
}

mixin B on A {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_mixin_setter_add_on_generic() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A<T> {
  set foo(T _) {}
}

mixin B on A<int> {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
      B: #M2
        inheritedMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A<T> {
  set foo(T _) {}
  set bar(T _) {}
}

mixin B on A<int> {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M3
          foo=: #M1
      B: #M2
        inheritedMembers
          bar=: #M3
          foo=: #M1
''',
    );
  }

  test_manifest_mixin_setter_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  @Deprecated('0')
  set foo(int _) {}
  @Deprecated('0')
  set bar(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M1
          foo=: #M2
''',
      updatedCode: r'''
mixin A {
  @Deprecated('1')
  set foo(int _) {}
  @Deprecated('0')
  set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M1
          foo=: #M3
''',
    );
  }

  test_manifest_mixin_setter_private_instance() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  set _foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
''',
      updatedCode: r'''
mixin A {
  set _foo(int _) {}
  set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
          bar=: #M2
''',
    );
  }

  test_manifest_mixin_setter_private_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static set _foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
''',
      updatedCode: r'''
mixin A {
  static set _foo(int _) {}
  set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          _foo=: #M1
          bar=: #M2
''',
    );
  }

  test_manifest_mixin_setter_static() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A {
  static set foo(int _) {}
  static set bar(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          bar=: #M2
          foo=: #M1
''',
    );
  }

  test_manifest_mixin_setter_static_falseToTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A {
  static set foo(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
''',
    );
  }

  test_manifest_mixin_setter_static_trueToFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A {
  set foo(int _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
''',
    );
  }

  test_manifest_mixin_setter_static_valueType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  static set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M1
''',
      updatedCode: r'''
mixin A {
  static set foo(double _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        declaredMembers
          foo=: #M2
''',
    );
  }

  test_manifest_mixin_setter_valueType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
mixin A {
  set foo(int _) {}
}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo=: #M1
            valueType: int @ dart:core
''',
      updatedCode: r'''
mixin A {
  set foo(double _) {}
}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      A: #M0
        superclassConstraints
          Object @ dart:core
        declaredMembers
          foo=: #M2
            valueType: double @ dart:core
''',
    );
  }

  test_manifest_topLevelFunction_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo() {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_optionalNamed() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({int a}) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_optionalNamed_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({int b}) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_optionalNamed_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({double a}) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_optionalPositional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo([int a]) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo([int a]) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_optionalPositional_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo([int a]) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo([int b]) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_optionalPositional_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo([int a]) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo([double a]) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredNamed() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({required int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({required int a}) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredNamed_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({required int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({required int b}) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredNamed_toRequiredPositional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({required int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo(int a) {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredNamed_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo({required int a}) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({required double a}) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredPositional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo(int a) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo(int a) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredPositional_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo(int a) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo(int b) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M0
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredPositional_toRequiredNamed() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo(int a) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo({required int a}) {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
''',
    );
  }

  test_manifest_topLevelFunction_formalParameter_requiredPositional_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo(int a) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo(double a) {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@Deprected('0')
void a() {}
@Deprected('0')
void b() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
      updatedCode: r'''
@Deprected('0')
void a() {}
@Deprected('1')
void b() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M2
''',
    );
  }

  test_manifest_topLevelFunction_private() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void _foo() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _foo: #M0
''',
      updatedCode: r'''
void _foo() {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _foo: #M0
      bar: #M1
''',
    );
  }

  test_manifest_topLevelFunction_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int foo() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
double foo() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
''',
    );
  }

  test_manifest_topLevelFunction_typeParameter() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
Map<T, U> foo<T extends num, U>() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
Map<T, U> foo<T, U>() {}
void bar() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      bar: #M1
      foo: #M2
''',
    );
  }

  test_manifest_topLevelFunction_typeParameter_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo<T>() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo<T, U>() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
''',
    );
  }

  test_manifest_topLevelFunction_typeParameter_bound() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo<T extends num>() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo<T extends int>() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
''',
    );
  }

  test_manifest_topLevelFunction_typeParameter_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
void foo<T, U>() {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M0
''',
      updatedCode: r'''
void foo<T>() {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      foo: #M1
''',
    );
  }

  test_manifest_topLevelGetter_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
int get a => 0;
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_topLevelGetter_body() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
int get a => 1;
''',
      expectedUpdatedEvents: r'''
[operation] readLibraryCycleBundle
  package:test/test.dart
''',
    );
  }

  test_manifest_topLevelGetter_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@Deprecated('0')
int get a => 0;
@Deprecated('0')
int get b => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
      updatedCode: r'''
@Deprecated('0')
int get a => 0;
@Deprecated('1')
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M2
''',
    );
  }

  test_manifest_topLevelGetter_private() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int get _a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
''',
      updatedCode: r'''
int get _a => 0;
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
      b: #M1
''',
    );
  }

  test_manifest_topLevelGetter_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int get a => 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
double get a => 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_topLevelSetter_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
set a(int _) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M0
''',
      updatedCode: r'''
set a(int _) {}
set b(int _) {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M0
      b=: #M1
''',
    );
  }

  test_manifest_topLevelSetter_body() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
set a(int _) { 0; }
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M0
''',
      updatedCode: r'''
set a(int _) { 1; }
''',
      expectedUpdatedEvents: r'''
[operation] readLibraryCycleBundle
  package:test/test.dart
''',
    );
  }

  test_manifest_topLevelSetter_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@Deprecated('0')
set a(int _) {}
@Deprecated('0')
set b(int _) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M0
      b=: #M1
''',
      updatedCode: r'''
@Deprecated('0')
set a(int _) {}
@Deprecated('1')
set b(int _) {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M0
      b=: #M2
''',
    );
  }

  test_manifest_topLevelSetter_valueType() async {
    configuration.withElementManifests = true;
    await _runLibraryManifestScenario(
      initialCode: r'''
set a(int _) {}
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M0
        valueType: int @ dart:core
''',
      updatedCode: r'''
set a(double _) {}
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a=: #M1
        valueType: double @ dart:core
''',
    );
  }

  test_manifest_topLevelVariable_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final a = 0;
final b = 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_topLevelVariable_initializer_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final a = 1.2;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_topLevelVariable_initializer_value_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
const a = 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_topLevelVariable_initializer_value_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final a = 1;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
    );
  }

  test_manifest_topLevelVariable_metadata() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
@Deprecated('0')
var a = 0;
@Deprecated('0')
var b = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      a=: #M1
      b: #M2
      b=: #M3
''',
      updatedCode: r'''
@Deprecated('0')
var a = 0;
@Deprecated('1')
var b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      a=: #M1
      b: #M4
      b=: #M5
''',
    );
  }

  test_manifest_topLevelVariable_private_const() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
const _a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
''',
      updatedCode: r'''
const _a = 0;
const b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
      b: #M1
''',
    );
  }

  test_manifest_topLevelVariable_private_final() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final _a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
''',
      updatedCode: r'''
final _a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
      b: #M1
''',
    );
  }

  test_manifest_topLevelVariable_private_var() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
var _a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
      _a=: #M1
''',
      updatedCode: r'''
var _a = 0;
var b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      _a: #M0
      _a=: #M1
      b: #M2
      b=: #M3
''',
    );
  }

  test_manifest_topLevelVariable_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
int? a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      a=: #M1
''',
      updatedCode: r'''
double? a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M2
      a=: #M3
''',
    );
  }

  test_manifest_type_dynamicType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final dynamic a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final dynamic a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_dynamicType_to_interfaceType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final dynamic a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final int a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final int Function() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final int Function() a;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_functionType_named() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({int p1}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({int p1}) a;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_functionType_named_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({int p1}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({int p1, double p2}) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_named_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({int p1, double p2}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({int p1}) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_named_toPositional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({int p}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function(int p) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_named_toRequiredFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({required int p1}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({int p1}) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_named_toRequiredTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({int p1}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({required int p1}) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_named_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function({int p1}) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({double p1}) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_nullabilitySuffix() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final int Function() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final int Function()? a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_positional() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function(int p1) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function(int p1) a;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_functionType_positional_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function(int p1) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function(int p1, double p2) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_positional_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function(int p1, double p2) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function(int p1) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_positional_toNamed() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function(int p) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function({int p}) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_positional_toRequiredFalse() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function(int p1) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function([int p1]) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_positional_toRequiredTrue() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function([int p1]) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function(int p1) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_positional_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function(int p1) a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function(double p1) a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_returnType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final int Function() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final double Function() a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_typeParameter() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final T Function<T>() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final T Function<T>() a;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_functionType_typeParameter_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function<E1>() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function<E1, E2>() a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_typeParameter_bound() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final T Function<T extends int>() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final T Function<T extends double>() a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_functionType_typeParameter_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void Function<E1, E2>() a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void Function<E1>() a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_interfaceType_element() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final int a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final double a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_interfaceType_nullabilitySuffix() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final int a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final int? a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_interfaceType_typeArguments() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final List<int> a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final List<double> a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_invalidType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final NotType a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final NotType a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_neverType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final Never a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final Never a;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_neverType_nullabilitySuffix() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final Never a;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final Never? a;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_namedFields() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final ({int f1}) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final ({int f1}) a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_recordType_namedFields_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final ({int f1}) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final ({int f1, double f2}) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_namedFields_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final ({int f1}) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final ({int f2}) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_namedFields_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final ({int f1, double f2}) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final ({int f1}) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_namedFields_reorder() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final ({int f1, double f2}) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final ({double f2, int f1}) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
    );
  }

  test_manifest_type_recordType_namedFields_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final ({int f1}) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final ({double f1}) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_nullabilitySuffix() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final (int,) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final (int,)? a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_positionalFields() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final (int,) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final (int,) a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_manifest_type_recordType_positionalFields_add() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final (int,) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final (int, double) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_positionalFields_name() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final (int x,) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final (int y,) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
    );
  }

  test_manifest_type_recordType_positionalFields_remove() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final (int, double) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final (int,) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_recordType_positionalFields_type() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final (int,) a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final (double,) a = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M1
''',
    );
  }

  test_manifest_type_voidType() async {
    await _runLibraryManifestScenario(
      initialCode: r'''
final void a = 0;
''',
      expectedInitialEvents: r'''
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
''',
      updatedCode: r'''
final void a = 0;
final b = 0;
''',
      expectedUpdatedEvents: r'''
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      a: #M0
      b: #M1
''',
    );
  }

  test_operation_addFile_affected() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationAddTestFile(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
double get a => 0;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M3
  requirements
    topLevels
      dart:core
        double: #M4
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M5
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M3
[operation] produceErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M3
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M3
[status] idle
''',
    );
  }

  test_operation_addFile_notAffected() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationAddTestFile(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
int get a => 0;
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M3
  requirements
    topLevels
      dart:core
        int: #M1
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ErrorsResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[status] idle
''',
    );
  }

  test_operation_getErrors_affected() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
double get a => 0;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M3
  requirements
    topLevels
      dart:core
        double: #M4
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M5
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M3
[operation] getErrorsCannotReuse
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M3
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M3
[status] idle
''',
    );
  }

  test_operation_getErrors_notAffected() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationTestFileGetErrors(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getErrors T1
  ErrorsResult #0
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[operation] analyzeFile
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: exists isLibrary
[operation] analyzedLibrary
  file: /home/test/lib/test.dart
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
int get a => 0;
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M3
  requirements
    topLevels
      dart:core
        int: #M1
[future] getErrors T2
  ErrorsResult #2
    path: /home/test/lib/test.dart
    uri: package:test/test.dart
    flags: isLibrary
[operation] readLibraryCycleBundle
  package:test/test.dart
[operation] getErrorsFromBytes
  file: /home/test/lib/test.dart
  library: /home/test/lib/test.dart
[status] idle
''',
    );
  }

  test_operation_getLibraryByUri_affected() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
double get a => 1.2;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M3
  requirements
    topLevels
      dart:core
        double: #M4
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: double
[operation] cannotReuseLinkedBundle
  topLevelIdMismatch
    libraryUri: package:test/a.dart
    name: a
    expectedId: #M0
    actualId: #M3
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M5
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M3
[status] idle
''',
    );
  }

  test_operation_getLibraryByUri_notAffected() async {
    await _runChangeScenarioTA(
      initialA: r'''
int get a => 0;
''',
      testCode: r'''
import 'a.dart';
final x = a;
''',
      operation: _FineOperationGetTestLibrary(),
      expectedInitialEvents: r'''
[status] working
[operation] linkLibraryCycle SDK
[future] getLibraryByUri T1
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
  requirements
    topLevels
      dart:core
        int: #M1
[operation] linkLibraryCycle
  package:test/test.dart
    manifest
      x: #M2
  requirements
    topLevels
      dart:core
        a: <null>
      package:test/a.dart
        a: #M0
[status] idle
''',
      updatedA: r'''
int get a => 0;
int get b => 0;
''',
      expectedUpdatedEvents: r'''
[status] working
[operation] linkLibraryCycle
  package:test/a.dart
    manifest
      a: #M0
      b: #M3
  requirements
    topLevels
      dart:core
        int: #M1
[future] getLibraryByUri T2
  library
    topLevelVariables
      final hasInitializer x
        type: int
[operation] readLibraryCycleBundle
  package:test/test.dart
[status] idle
''',
    );
  }

  Future<void> _runChangeScenario({
    required _FineOperation operation,
    String? expectedInitialEvents,
    required List<File> Function() updateFiles,
    required String expectedUpdatedEvents,
  }) async {
    void setId(String id) {
      NodeTextExpectationsCollector.intraInvocationId = id;
    }

    withFineDependencies = true;
    configuration
      ..withResultRequirements = true
      ..withLibraryManifest = true
      ..withLinkBundleEvents = true;

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(
      driver,
      idProvider: idProvider,
    );

    configuration.elementTextConfiguration
      ..withLibraryFragments = false
      ..withReferences = false
      ..withSyntheticGetters = false;

    switch (operation) {
      case _FineOperationAddTestFile():
        driver.addFile2(testFile);
      case _FineOperationTestFileGetErrors():
        collector.getErrors('T1', testFile);
      case _FineOperationGetTestLibrary():
        collector.getLibraryByUri('T1', 'package:test/test.dart');
    }

    if (expectedInitialEvents != null) {
      setId('expectedInitialEvents');
      await assertEventsText(collector, expectedInitialEvents);
    } else {
      await collector.nextStatusIdle();
      collector.take();
    }

    var updatedFiles = updateFiles();
    for (var updatedFile in updatedFiles) {
      driver.changeFile2(updatedFile);
    }

    switch (operation) {
      case _FineOperationAddTestFile():
        // Nothing to do here, wait for analysis of previous added files.
        break;
      case _FineOperationTestFileGetErrors():
        collector.getErrors('T2', testFile);
      case _FineOperationGetTestLibrary():
        collector.getLibraryByUri('T2', 'package:test/test.dart');
    }

    setId('expectedUpdatedEvents');
    await assertEventsText(collector, expectedUpdatedEvents);
  }

  Future<void> _runChangeScenarioTA({
    required String initialA,
    required String testCode,
    required _FineOperation operation,
    String? expectedInitialEvents,
    required String updatedA,
    required String expectedUpdatedEvents,
  }) async {
    var a = newFile('$testPackageLibPath/a.dart', initialA);
    newFile('$testPackageLibPath/test.dart', testCode);

    await _runChangeScenario(
      operation: operation,
      expectedInitialEvents: expectedInitialEvents,
      updateFiles: () {
        modifyFile2(a, updatedA);
        return [a];
      },
      expectedUpdatedEvents: expectedUpdatedEvents,
    );
  }

  Future<void> _runLibraryManifestScenario({
    required String initialCode,
    String? expectedInitialEvents,
    String? expectedInitialDriverState,
    List<File> Function()? updateFiles,
    required String updatedCode,
    required String expectedUpdatedEvents,
    String? expectedUpdatedDriverState,
  }) async {
    void setId(String id) {
      NodeTextExpectationsCollector.intraInvocationId = id;
    }

    newFile(testFile.path, initialCode);

    withFineDependencies = true;
    configuration
      ..withGetLibraryByUri = false
      ..withLibraryManifest = true
      ..withLinkBundleEvents = true
      ..withSchedulerStatus = false;

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(
      driver,
      idProvider: idProvider,
    );

    var libraryUri = Uri.parse('package:test/test.dart');
    collector.getLibraryByUri('T1', '$libraryUri');

    if (expectedInitialEvents != null) {
      setId('expectedInitialEvents');
      await assertEventsText(collector, expectedInitialEvents);
    } else {
      await collector.nextStatusIdle();
      collector.take();
    }

    if (expectedInitialDriverState != null) {
      assertDriverStateString(testFile, expectedInitialDriverState);
    }

    if (updateFiles != null) {
      var updatedFiles = updateFiles();
      for (var updatedFile in updatedFiles) {
        driver.changeFile2(updatedFile);
      }
    }

    modifyFile2(testFile, updatedCode);
    driver.changeFile2(testFile);

    collector.getLibraryByUri('T2', '$libraryUri');

    setId('expectedUpdatedEvents');
    await assertEventsText(collector, expectedUpdatedEvents);

    if (expectedUpdatedDriverState != null) {
      assertDriverStateString(testFile, expectedUpdatedDriverState);
    }
  }
}

/// A lint that is always reported for all linted files.
class _AlwaysReportedLint extends LintRule {
  static final instance = _AlwaysReportedLint();

  static const LintCode code = LintCode(
    'always_reported_lint',
    'This lint is reported for all files',
  );

  _AlwaysReportedLint()
      : super(
          name: 'always_reported_lint',
          description: '',
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _AlwaysReportedLintVisitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

/// A visitor for [_AlwaysReportedLint] that reports the lint for all files.
class _AlwaysReportedLintVisitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _AlwaysReportedLintVisitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportLintForOffset(0, 0);
  }
}

mixin _EventsMixin {
  final IdProvider idProvider = IdProvider();
  final DriverEventsPrinterConfiguration configuration =
      DriverEventsPrinterConfiguration();

  Future<void> assertEventsText(
    DriverEventCollector collector,
    String expected,
  ) async {
    await pumpEventQueue(times: 5000);

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    var events = collector.take();
    DriverEventsPrinter(
      configuration: configuration,
      sink: sink,
      elementPrinter: elementPrinter,
      idProvider: collector.idProvider,
    ).write(events);

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }
}

sealed class _FineOperation {
  const _FineOperation();
}

final class _FineOperationAddTestFile extends _FineOperation {
  const _FineOperationAddTestFile();
}

final class _FineOperationGetTestLibrary extends _FineOperation {
  const _FineOperationGetTestLibrary();
}

final class _FineOperationTestFileGetErrors extends _FineOperation {
  const _FineOperationTestFileGetErrors();
}

extension on AnalysisDriver {
  Future<void> assertFilesDefiningClassMemberName(
    String name,
    List<File?> expected,
  ) async {
    var fileStateList = await getFilesDefiningClassMemberName(name);
    var files = fileStateList.resources;
    expect(files, unorderedEquals(expected));
  }

  Future<void> assertFilesReferencingName(
    String name, {
    required List<File?> includesAll,
    required List<File?> excludesAll,
  }) async {
    var fileStateList = await getFilesReferencingName(name);
    var files = fileStateList.resources;
    for (var expected in includesAll) {
      expect(files, contains(expected));
    }
    for (var expected in excludesAll) {
      expect(files, isNot(contains(expected)));
    }
  }

  void assertLoadedLibraryUriSet({
    Iterable<String>? included,
    Iterable<String>? excluded,
  }) {
    var uriSet = testView!.loadedLibraryUriSet;
    if (included != null) {
      expect(uriSet, containsAll(included));
    }
    if (excluded != null) {
      for (var excludedUri in excluded) {
        expect(uriSet, isNot(contains(excludedUri)));
      }
    }
  }

  FileResult getFileSyncValid(File file) {
    return getFileSync2(file) as FileResult;
  }

  Future<LibraryElementResult> getLibraryByUriValid(String uriStr) async {
    return await getLibraryByUri(uriStr) as LibraryElementResult;
  }
}
