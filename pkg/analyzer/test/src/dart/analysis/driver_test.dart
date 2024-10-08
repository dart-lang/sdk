// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as driver_events;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
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
class AnalysisDriver_PubPackageTest extends PubPackageResolutionTest {
  final DriverEventsPrinterConfiguration configuration =
      DriverEventsPrinterConfiguration();

  @override
  bool get retainDataForTesting => true;

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

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    useEmptyByteStore();
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

  test_addFile_library_producesMacroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);
    await collector.nextStatusIdle();

    // We produced both the library, and its macro-generated file.
    configuration.withMacroFileContent();
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
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/a.dart';

class B {}
---
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
[stream]
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
  ResolvedUnitResult #1
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no analysis.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A1
  ResolvedUnitResult #0
[future] getResolvedUnit B2
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
[stream]
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
  ResolvedUnitResult #1
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no analysis.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A1
  ResolvedUnitResult #0
[future] getResolvedUnit B2
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
      staticElement: package:test/b.dart::<fragment>::@getter::B
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
      staticElement: package:test/b.dart::<fragment>::@getter::B
      element: package:test/b.dart::<fragment>::@getter::B#element
      staticType: double
[status] idle
''');
  }

  test_changeFile_library_producesMacroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Discard results so far.
    await collector.nextStatusIdle();
    collector.take();

    modifyFile2(a, r'''
import 'append.dart';

@DeclareTypesPhase('B2', 'class B2 {}')
class A {}
''');
    driver.changeFile2(a);
    await collector.nextStatusIdle();

    // We produced both the library, and its macro-generated file.
    configuration.withMacroFileContent();
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
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/a.dart';

class B2 {}
---
[status] idle
''');
  }

  test_changeFile_macroImpl_macroGenerated_ifPriority() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    File addMacroFile(String className) {
      return newFile('$testPackageLibPath/a.dart', '''
import 'package:macros/macros.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      '$className',
      DeclarationCode.fromString('class $className {}'),
    );
  }
}
''');
    }

    // The macro declares `A1`.
    var a = addMacroFile('A1');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@MyMacro()
class B {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Subscribe for errors in `b`.
    driver.addFile2(b);

    // As if the user opened `b.macro.dart` in the editor.
    driver.priorityFiles2 = [b.macroForLibrary!];

    // Discard results so far.
    await collector.nextStatusIdle();
    collector.take();

    // Declares `A2` instead of `A1`.
    addMacroFile('A2');
    driver.changeFile2(a);
    await collector.nextStatusIdle();

    // There are no cached errors for `MyMacro` with `A2`.
    // So, we analyze the whole library.
    // We produce both the library, and its macro-generated file.
    // Note, the macro-generated file has `A2`.
    configuration.withMacroFileContent();
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
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.macro.dart
    uri: package:test/b.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/b.dart';

class A2 {}
---
[status] idle
''');

    // Declares again `A1`, was `A2`.
    addMacroFile('A1');
    driver.changeFile2(a);
    await collector.nextStatusIdle();

    // The macro-generated file is priority, so we need the resolved unit.
    // We analyze the whole library.
    // Note, the macro-generated file has `A1`.
    configuration.withMacroFileContent();
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
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/b.macro.dart
    uri: package:test/b.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/b.dart';

class A1 {}
---
[status] idle
''');
  }

  test_changeFile_macroImpl_macroGenerated_notPriority() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    File addMacroFile(String className) {
      return newFile('$testPackageLibPath/a.dart', '''
import 'package:macros/macros.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      '$className',
      DeclarationCode.fromString('class $className {}'),
    );
  }
}
''');
    }

    // The macro declares `A1`.
    var a = addMacroFile('A1');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@MyMacro()
class B {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    // Subscribe for errors in `b`.
    driver.addFile2(b);

    // Discard results so far.
    await collector.nextStatusIdle();
    collector.take();

    // Declares `A2` instead of `A1`.
    addMacroFile('A2');
    driver.changeFile2(a);
    await collector.nextStatusIdle();

    // There are no cached errors for `MyMacro` with `A2`.
    // So, we analyze the whole library.
    // We produce both the library, and its macro-generated file.
    // Note, the macro-generated file has `A2`.
    configuration.withMacroFileContent();
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
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/b.macro.dart
    uri: package:test/b.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/b.dart';

class A2 {}
---
[status] idle
''');

    // Declares again `A1`, was `A2`.
    addMacroFile('A1');
    driver.changeFile2(a);
    await collector.nextStatusIdle();

    // There are cached errors for `MyMacro` with `A1`.
    // So, we don't have to analyze anything, we can produce from bytes.
    // We produce both the library, and its macro-generated file.
    // Note, the macro-generated file has `A1`.
    configuration.withMacroFileContent();
    await assertEventsText(collector, r'''
[status] working
[operation] getErrorsFromBytes
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ErrorsResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[operation] getErrorsFromBytes
  file: /home/test/lib/b.macro.dart
  library: /home/test/lib/b.dart
[stream]
  ErrorsResult #3
    path: /home/test/lib/b.macro.dart
    uri: package:test/b.macro.dart
    flags: isMacroPart isPart
    content
---
part of 'package:test/b.dart';

class A1 {}
---
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

    Future<LibraryElementImpl> getLibrary(String shortName) async {
      var uriStr = 'package:test/$shortName';
      var result = await driver.getLibraryByUriValid(uriStr);
      return result.element as LibraryElementImpl;
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

    Future<LibraryElementImpl> getLibrary(String shortName) async {
      var uriStr = 'package:test/$shortName';
      var result = await driver.getLibraryByUriValid(uriStr);
      return result.element as LibraryElementImpl;
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
      switch (result.uriStr) {
        case 'package:test/a.dart':
          return [
            result.findElement.topVar('A1'),
            result.findElement.topVar('A2'),
          ];
        case 'package:test/b.dart':
          return [
            result.findElement.topVar('B1'),
          ];
        default:
          return [];
      }
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
            result.findElement.topVar('V'),
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
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      8 +1 EXPECTED_TOKEN
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
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getErrors B1
  ErrorsResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[stream]
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_getErrors_macroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var a_macro = getFile('$testPackageLibPath/a.macro.dart');
    collector.getErrors('AM1', a_macro);
    await collector.nextStatusIdle();

    // The library was analyzed.
    // The future for the macro generated file completed.
    configuration.withMacroFileContent();
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
[future] getErrors AM1
  ErrorsResult #1
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: isMacroPart isPart
    content
---
part of 'package:test/a.dart';

class B {}
---
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/a.dart';

class B {}
---
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

  test_getFilesDefiningClassMemberName_macroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareInType('  void foo() {}')
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'append.dart';

@DeclareInType('  void bar() {}')
class B {}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
import 'append.dart';

@DeclareInType('  void foo() {}')
class C {}
''');

    // Run twice: when linking, and when reading.
    for (var i = 0; i < 2; i++) {
      var driver = driverFor(testFile);
      driver.addFile2(a);
      driver.addFile2(b);
      driver.addFile2(c);

      await driver.assertFilesDefiningClassMemberName('foo', [
        a.macroForLibrary,
        c.macroForLibrary,
      ]);

      await driver.assertFilesDefiningClassMemberName('bar', [
        b.macroForLibrary,
      ]);

      await disposeAnalysisContextCollection();
    }
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

  test_getFilesReferencingName_macroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareInLibrary('{{dart:core@int}} get foo => 0;')
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'append.dart';

@DeclareInLibrary('{{dart:core@double}} get foo => 1.2;')
class B {}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
import 'append.dart';

@DeclareInLibrary('{{dart:core@int}} get foo => 0;')
class C {}
''');

    // Run twice: when linking, and when reading.
    for (var i = 0; i < 2; i++) {
      var driver = driverFor(testFile);
      driver.addFile2(a);
      driver.addFile2(b);
      driver.addFile2(c);

      await driver.assertFilesReferencingName(
        'int',
        includesAll: [a.macroForLibrary, c.macroForLibrary],
        excludesAll: [b.macroForLibrary],
      );

      await driver.assertFilesReferencingName(
        'double',
        includesAll: [b.macroForLibrary],
        excludesAll: [a.macroForLibrary, c.macroForLibrary],
      );

      await disposeAnalysisContextCollection();
    }
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

  test_getIndex_macroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareInLibrary('void f() { foo(); }')
@DeclareInLibrary('void foo() {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var a_macro = getFile('$testPackageLibPath/a.macro.dart');
    collector.getIndex('AM1', a_macro);
    await collector.nextStatusIdle();

    // The library, and the macro generated file were analyzed.
    configuration.withMacroFileContent();
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
[future] getIndex AM1
  strings
    --nullString--
    foo
    package:test/a.dart
    package:test/a.macro.dart
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/a.dart';

void foo() {}
void f() { foo(); }
---
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
    expect(result.element.getClass('A'), isNotNull);
    expect(result.element.getClass('B'), isNotNull);

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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedLibrary A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedLibrary A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
      ResolvedUnitResult #2
        path: /home/test/lib/b.dart
        uri: package:test/b.dart
        flags: exists isPart
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
  ResolvedLibraryResult #1
''');

    // Ask `a`, returns cached.
    // Note, no analysis.
    collector.getResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[future] getResolvedUnit A3
  ResolvedUnitResult #0
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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedLibrary A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
[status] idle
''');
  }

  test_getResolvedLibrary_withMacroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('A1', a);
    await collector.nextStatusIdle();

    // We produced both the library, and its macro-generated file.
    configuration.withMacroFileContent();
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
[future] getResolvedLibrary A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
      ResolvedUnitResult #2
        path: /home/test/lib/a.macro.dart
        uri: package:test/a.macro.dart
        flags: exists isMacroPart isPart
        content
---
part of 'package:test/a.dart';

class B {}
---
[stream]
  ResolvedUnitResult #2
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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedLibraryByUri A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
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
[stream]
  ResolvedUnitResult #0
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

  test_getResolvedLibraryByUri_withMacroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);
    await collector.nextStatusIdle();

    // We produced both the library, and its macro-generated file.
    configuration.withMacroFileContent();
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
[future] getResolvedLibraryByUri A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
      ResolvedUnitResult #2
        path: /home/test/lib/a.macro.dart
        uri: package:test/a.macro.dart
        flags: exists isMacroPart isPart
        content
---
part of 'package:test/a.dart';

class B {}
---
[stream]
  ResolvedUnitResult #2
[status] idle
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
[stream]
  ResolvedUnitResult #0
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
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
[stream]
  ResolvedUnitResult #0
[future] getErrors B1
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[status] idle
''');
  }

  test_getResolvedUnit_macroGenerated_hasLibrary() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var a_macro = getFile('$testPackageLibPath/a.macro.dart');
    collector.getResolvedUnit('AM1', a_macro);
    await collector.nextStatusIdle();

    // Even though we asked the macro-generated file, the library was analyzed
    // instead, and results for both produced.
    configuration.withMacroFileContent();
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
[future] getResolvedUnit AM1
  ResolvedUnitResult #1
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: exists isMacroPart isPart
    content
---
part of 'package:test/a.dart';

class B {}
---
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_getResolvedUnit_macroGenerated_noLibrary() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var a_macro = getFile('$testPackageLibPath/a.macro.dart');
    collector.getResolvedUnit('AM1', a_macro);
    await collector.nextStatusIdle();

    // We try to analyze `a.dart`, but it does not exist.
    // Then we separately analyze `a.macro.dart`, it also does not exist.
    await assertEventsText(collector, r'''
[status] working
[operation] analyzeFile
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[operation] analyzeFile
  file: /home/test/lib/a.macro.dart
  library: /home/test/lib/a.macro.dart
[future] getResolvedUnit AM1
  ResolvedUnitResult #1
    path: /home/test/lib/a.macro.dart
    uri: package:test/a.macro.dart
    flags: isLibrary
[stream]
  ResolvedUnitResult #1
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
        result.findElement.topVar('foo'),
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
[stream]
  ResolvedUnitResult #0
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
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
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #2
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

    configuration.unitElementConfiguration.elementSelector = (unitElement) {
      return unitElement.functions;
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
    package:test/a.dart::<fragment>::@function::foo
    package:test/a.dart::<fragment>::@function::bar
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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    errors
      7 +21 URI_DOES_NOT_EXIST
[future] getResolvedLibrary A1
  ResolvedLibraryResult #1
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
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

  test_getUnitElement_macroGenerated() async {
    if (!configureWithCommonMacros()) {
      return;
    }

    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    var driver = driverFor(testFile);
    var collector = DriverEventCollector(driver);

    var a_macro = getFile('$testPackageLibPath/a.macro.dart');
    collector.getUnitElement('AM1', a_macro);
    await collector.nextStatusIdle();

    configuration.unitElementConfiguration.elementSelector = (unitElement) {
      return unitElement.classes;
    };

    // The enclosing element is an augmentation library, in a library.
    // The macro generated file has `class B`.
    await assertEventsText(collector, r'''
[status] working
[future] getUnitElement AM1
  path: /home/test/lib/a.macro.dart
  uri: package:test/a.macro.dart
  flags: isMacroPart isPart
  enclosing: package:test/a.dart::<fragment>
  selectedElements
    package:test/a.dart::@fragment::package:test/a.macro.dart::@class::B
[status] idle
''');
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
            result.findElement.topVar('B'),
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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    selectedVariableTypes
      B: int
[stream]
  ResolvedUnitResult #1
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
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B2
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    selectedVariableTypes
      B: int
[stream]
  ResolvedUnitResult #3
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

    // Pending changes are no applied yes, so `a` is empty.
    {
      var result = driver.parseFileSync2(a) as ParsedUnitResult;
      assertParsedNodeText(result.unit, r'''
CompilationUnit
''');
    }

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
[operation] analyzeFile
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[future] getErrors A1
  ErrorsResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
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
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[future] getErrors B1
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
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
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[stream]
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
[operation] analyzeFile
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getErrors B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
    errors
      60 +1 CREATION_WITH_NON_TYPE
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
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #3
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
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
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
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit B1
  ResolvedUnitResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #2
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
            result.findElement.topVar('A'),
          ];
        case 'package:test/b.dart':
          return [
            result.findElement.topVar('B'),
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
  final idProvider = IdProvider();
  late AnalysisDriver driver;
  List<DriverEvent> events = [];
  final List<Completer<void>> statusIdleCompleters = [];

  DriverEventCollector(this.driver) {
    _listenSchedulerEvents(driver.scheduler);
  }

  DriverEventCollector.forCollection(
    AnalysisContextCollectionImpl collection,
  ) {
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
    scheduler.events.listen((event) {
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
        case driver_events.GetErrorsFromBytes():
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

extension on DriverEventsPrinterConfiguration {
  void withMacroFileContent() {
    errorsConfiguration.withContentPredicate = (result) {
      return result.isMacroPart;
    };
    libraryConfiguration.unitConfiguration.withContentPredicate = (result) {
      return result.isMacroPart;
    };
  }
}
