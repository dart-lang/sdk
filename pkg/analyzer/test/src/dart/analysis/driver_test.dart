// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as driver_events;
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, SourceFactory;
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../../../util/tree_string_sink.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';
import '../resolution/resolution.dart';
import 'result_printer.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverSchedulerTest);
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
      var innerLibrary = result.libraryElement.importedLibraries
          .where((e) => e.source.fullName == innerFile.path)
          .single;
      expect(innerLibrary.source.uri, innerUri);
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

    final buffer = StringBuffer();
    final sink = TreeStringSink(sink: buffer, indent: '');

    final elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
      selfUriStr: null,
    );

    final events = collector.take();
    DriverEventsPrinter(
      configuration: configuration,
      sink: sink,
      elementPrinter: elementPrinter,
      idProvider: collector.idProvider,
    ).write(events);

    final actual = buffer.toString();
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
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');

    final driver = driverFor(testFile);

    driver.addFile2(a);
    driver.addFile2(b);
    await driver.applyPendingFileChanges();
    expect(driver.addedFiles2, unorderedEquals([a, b]));

    driver.removeFile2(a);
    await driver.applyPendingFileChanges();
    expect(driver.addedFiles2, unorderedEquals([b]));
  }

  test_addFile() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(b);
    driver.addFile2(a);

    // The results are reported in the order of adding.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_addFile_afterRemove() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);
    driver.addFile2(a);
    driver.addFile2(b);

    // Initial analysis, `b` does not use `a`, so there is a hint.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
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
[status] analyzing
[stream]
  ErrorsResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[status] idle
''');
  }

  test_addFile_notAbsolutePath() async {
    final driver = driverFor(testFile);
    expect(() {
      driver.addFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_addFile_priorityFiles() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');
    final c = newFile('$testPackageLibPath/c.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.priorityFiles2 = [b];

    // 1. The priority file is produced first.
    // 2. We get full `ResolvedUnitResult`.
    // 3. For other files we get only `ErrorsResult`.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #2
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: isLibrary
[status] idle
''');
  }

  test_addFile_removeFile() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Add, and immediately remove.
    driver.addFile2(a);
    driver.removeFile2(a);

    // No files to analyze.
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
''');
  }

  test_addFile_thenRemove() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // Now remove `a`.
    driver.removeFile2(a);

    // We remove `a` before analysis started.
    // So, only `b` was analyzed.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[status] idle
''');
  }

  test_cachedPriorityResults() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Get the result, not cached.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
[future] getResolvedUnit
  name: A2
  ResolvedUnitResult #0
''');

    // Get the (cached) result, reported to the stream.
    collector.getResolvedUnit('A3', a, sendCachedToStream: true);
    await assertEventsText(collector, r'''
[stream]
  ResolvedUnitResult #0
[future] getResolvedUnit
  name: A3
  ResolvedUnitResult #0
''');
  }

  test_cachedPriorityResults_flush_onAnyFileChange() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
[status] analyzing
[future] getResolvedUnit
  name: A2
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
[status] analyzing
[future] getResolvedUnit
  name: A3
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #2
[stream]
  ErrorsResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[status] idle
''');

    // Remove `b`.
    // The cache is flushed, so we get a new result.
    driver.removeFile2(b);
    collector.getResolvedUnit('A4', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A4
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
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Get the result for `a`, new.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
[status] analyzing
[future] getResolvedUnit
  name: A2
  ResolvedUnitResult #0
[status] idle
''');

    // Get the result for `b`, new.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B1
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
[future] getResolvedUnit
  name: B2
  ResolvedUnitResult #1
''');

    // Only `b` is priority.
    // The result for `a` is flushed, so analyzed when asked.
    driver.priorityFiles2 = [b];
    collector.getResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A3
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
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Always analyzed the first time.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
[status] analyzing
[future] getResolvedUnit
  name: A2
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
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Ask the result for `a`, should cache for both `a` and `b`.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no status analyzing.
    collector.getResolvedUnit('A2', a);
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit
  name: A2
  ResolvedUnitResult #0
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
''');

    // Ask for resolved library.
    // Note, the units are cached.
    collector.getResolvedLibrary('L1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: L1
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #0
      ResolvedUnitResult #1
''');
  }

  test_cachedPriorityResults_wholeLibrary_priorityLibrary_askPart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    // Ask the result for `b`, should cache for both `a` and `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no status analyzing.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit
  name: B2
  ResolvedUnitResult #0
''');

    // Ask for resolved library.
    // Note, the units are cached.
    collector.getResolvedLibrary('L1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: L1
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
      ResolvedUnitResult #0
''');
  }

  test_cachedPriorityResults_wholeLibrary_priorityPart_askPart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [b];

    // Ask the result for `b`, should cache for both `a` and `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Verify that the results for `a` and `b` are cached.
    // Note, no status analyzing.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit
  name: B2
  ResolvedUnitResult #0
''');

    // Ask for resolved library.
    // Note, the units are cached.
    collector.getResolvedLibrary('L1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: L1
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
      ResolvedUnitResult #0
''');
  }

  test_changeFile_implicitlyAnalyzed() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
var A = B;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
var B = 0;
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];
    driver.addFile2(a);

    configuration.libraryConfiguration.unitConfiguration.nodeSelector =
        (result) {
      return result.findNode.simple('B;');
    };

    // We have a result only for "a".
    // The type of `B` is `int`.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedNode: SimpleIdentifier
      token: B
      staticElement: package:test/b.dart::@getter::B
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
[status] analyzing
[stream]
  ResolvedUnitResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedNode: SimpleIdentifier
      token: B
      staticElement: package:test/b.dart::@getter::B
      staticType: double
[status] idle
''');
  }

  test_changeFile_notAbsolutePath() async {
    final driver = driverFor(testFile);
    expect(() {
      driver.changeFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_changeFile_notExisting_toEmpty() async {
    final b = newFile('$testPackageLibPath/b.dart', '''
// ignore:unused_import
import 'a.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(b);

    // `b` is analyzed, has an error.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
    errors
      31 +8 URI_DOES_NOT_EXIST
[status] idle
''');

    // Create `a`, empty.
    final a = newFile('$testPackageLibPath/a.dart', '');
    driver.addFile2(a);

    // Both `a` and `b` are analyzed.
    // No errors anymore.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[status] idle
''');
  }

  test_changeFile_notUsed() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final b = newFile('$testPackageLibPath/b.dart', 'class B1 {}');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Nothing interesting, "a" is analyzed.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');

    // Change "b" and notify.
    modifyFile2(b, 'class B2 {}');
    driver.changeFile2(b);

    // Nothing depends on "b", so nothing is analyzed.
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
''');
  }

  test_changeFile_potentiallyAffected_imported() async {
    newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', '''
import 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', '''
import 'b.dart';
''');

    final d = newFile('$testPackageLibPath/d.dart', '''
import 'c.dart';
''');

    newFile('$testPackageLibPath/e.dart', '');

    final driver = driverFor(testFile);

    Future<LibraryElementImpl> getLibrary(String shortName) async {
      final uriStr = 'package:test/$shortName';
      final result = await driver.getLibraryByUriValid(uriStr);
      return result.element as LibraryElementImpl;
    }

    final a_element = await getLibrary('a.dart');
    final b_element = await getLibrary('b.dart');
    final c_element = await getLibrary('c.dart');
    final d_element = await getLibrary('d.dart');
    final e_element = await getLibrary('e.dart');

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
    final session1 = driver.currentSession;
    expect(a_element.session, session1);
    expect(b_element.session, session1);
    expect(c_element.session, session1);
    expect(d_element.session, session1);
    expect(e_element.session, session1);

    // Change `b.dart`, also removes `c.dart` and `d.dart` that import it.
    // But `a.dart` and `d.dart` is not affected.
    driver.changeFile2(b);
    final affectedPathList = await driver.applyPendingFileChanges();
    expect(affectedPathList, unorderedEquals([b.path, c.path, d.path]));

    // We have a new session.
    final session2 = driver.currentSession;
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
    final a = newFile('$testPackageLibPath/a.dart', '''
part of 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', '''
part 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', '''
import 'b.dart';
''');

    newFile('$testPackageLibPath/d.dart', '');

    final driver = driverFor(testFile);

    Future<LibraryElementImpl> getLibrary(String shortName) async {
      final uriStr = 'package:test/$shortName';
      final result = await driver.getLibraryByUriValid(uriStr);
      return result.element as LibraryElementImpl;
    }

    final b_element = await getLibrary('b.dart');
    final c_element = await getLibrary('c.dart');
    final d_element = await getLibrary('d.dart');

    // We have all libraries loaded after analysis.
    driver.assertLoadedLibraryUriSet(
      included: [
        'package:test/b.dart',
        'package:test/c.dart',
        'package:test/d.dart',
      ],
    );

    // All libraries have the current session.
    final session1 = driver.currentSession;
    expect(b_element.session, session1);
    expect(c_element.session, session1);
    expect(d_element.session, session1);

    // Change `a.dart`, remove `b.dart` that part it.
    // Removes `c.dart` that imports `b.dart`.
    // But `d.dart` is not affected.
    driver.changeFile2(a);
    final affectedPathList = await driver.applyPendingFileChanges();
    expect(affectedPathList, unorderedEquals([a.path, b.path, c.path]));

    // We have a new session.
    final session2 = driver.currentSession;
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
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
final A1 = 1;
final A2 = B1;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
final B1 = A1;
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

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
[status] analyzing
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A1: int
      A2: int
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
[status] analyzing
[stream]
  ResolvedUnitResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A1: double
      A2: double
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
    final a = newFile('$testPackageLibPath/a.dart', 'var V = 1;');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

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
[status] analyzing
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
[status] analyzing
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
    final a = newFile('$testPackageLibPath/a.dart', r'''
final v = 0;
''');

    final driver = driverFor(testFile);

    await driver.getResolvedUnit2(a);

    final session1 = driver.currentSession;
    expect(session1, isNotNull);

    modifyFile2(a, r'''
final v = 2;
''');
    driver.changeFile2(a);
    await driver.getResolvedUnit2(a);

    final session2 = driver.currentSession;
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

    final t1 = newFile('$testPackageLibPath/t1.dart', '');
    final a1 = newFile('$packagesRootPath/aaa/lib/a1.dart', '');
    final a2 = newFile('$packagesRootPath/aaa/lib/src/a2.dart', '');
    final a3 = newFile('$packagesRootPath/aaa/lib/a3.txt', '');
    final b1 = newFile('$packagesRootPath/bbb/lib/b1.dart', '');
    final c1 = newFile('$packagesRootPath/ccc/lib/c1.dart', '');

    final driver = driverFor(testFile);
    driver.addFile2(t1);

    // Don't add `a1`, `a2`, or `b1` - they should be discovered.
    // And `c` is not in the package config, so should not be discovered.
    await driver.discoverAvailableFiles();

    expect(driver.knownFiles2, contains(t1));
    expect(driver.knownFiles2, contains(a1));
    expect(driver.knownFiles2, contains(a2));
    expect(driver.knownFiles2, isNot(contains(a3)));
    expect(driver.knownFiles2, contains(b1));
    expect(driver.knownFiles2, isNot(contains(c1)));

    // We can wait for discovery more than once.
    await driver.discoverAvailableFiles();
  }

  test_discoverAvailableFiles_sdk() async {
    final driver = driverFor(testFile);
    await driver.discoverAvailableFiles();
    expect(
      driver.knownFiles2,
      containsAll([
        sdkRoot.getChildAssumingFile('lib/async/async.dart'),
        sdkRoot.getChildAssumingFile('lib/collection/collection.dart'),
        sdkRoot.getChildAssumingFile('lib/core/core.dart'),
        sdkRoot.getChildAssumingFile('lib/math/math.dart'),
      ]),
    );
  }

  test_getCachedResolvedUnit() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    // Not cached.
    // Note, no status analyzing.
    collector.getCachedResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[future] getCachedResolvedUnit
  name: A1
  null
''');

    driver.priorityFiles2 = [a];
    collector.getResolvedUnit('A2', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A2
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // Has cached.
    // Note, no status analyzing.
    collector.getCachedResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[future] getCachedResolvedUnit
  name: A3
  ResolvedUnitResult #0
''');
  }

  test_getErrors() async {
    final a = newFile('$testPackageLibPath/a.dart', '''
var v = 0
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    collector.getErrors('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getErrors
  name: A1
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      8 +1 EXPECTED_TOKEN
''');
  }

  test_getErrors_notAbsolutePath() async {
    final driver = driverFor(testFile);
    final result = await driver.getErrors('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getFilesDefiningClassMemberName_class() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {
  void m1() {}
}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
class B {
  void m2() {}
}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
class C {
  void m2() {}
}
''');

    final d = newFile('$testPackageLibPath/d.dart', r'''
class D {
  void m3() {}
}
''');

    final driver = driverFor(testFile);
    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);

    expect(
      await driver.getFilesDefiningClassMemberName2('m1'),
      unorderedEquals([a]),
    );

    expect(
      await driver.getFilesDefiningClassMemberName2('m2'),
      unorderedEquals([b, c]),
    );

    expect(
      await driver.getFilesDefiningClassMemberName2('m3'),
      unorderedEquals([d]),
    );
  }

  test_getFilesDefiningClassMemberName_mixin() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void m1() {}
}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
mixin B {
  void m2() {}
}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
mixin C {
  void m2() {}
}
''');

    final d = newFile('$testPackageLibPath/d.dart', r'''
mixin D {
  void m3() {}
}
''');

    final driver = driverFor(testFile);
    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);

    expect(
      await driver.getFilesDefiningClassMemberName2('m1'),
      unorderedEquals([a]),
    );

    expect(
      await driver.getFilesDefiningClassMemberName2('m2'),
      unorderedEquals([b, c]),
    );

    expect(
      await driver.getFilesDefiningClassMemberName2('m3'),
      unorderedEquals([d]),
    );
  }

  test_getFilesReferencingName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
void f(A a) {}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
void f(A a) {}
''');

    final d = newFile('$testPackageLibPath/d.dart', r'''
class A {}
void f(A a) {}
''');

    final e = newFile('$testPackageLibPath/e.dart', r'''
import 'a.dart';
void main() {}
''');

    final driver = driverFor(testFile);
    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);
    driver.addFile2(e);

    // `b` references an external `A`.
    // `c` references an external `A`.
    // `d` references the local `A`.
    // `e` does not reference `A` at all.
    expect(
      await driver.getFilesReferencingName2('A'),
      unorderedEquals([b, c]),
    );

    // We get the same results second time.
    expect(
      await driver.getFilesReferencingName2('A'),
      unorderedEquals([b, c]),
    );
  }

  test_getFilesReferencingName_discover() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$packagesRootPath/aaa')
        ..add(name: 'bbb', rootPath: '$packagesRootPath/bbb'),
    );

    final t = newFile('$testPackageLibPath/t.dart', '''
int t = 0;
''');

    final a = newFile('$packagesRootPath/aaa/lib/a.dart', '''
int a = 0;
''');

    final b = newFile('$packagesRootPath/bbb/lib/b.dart', '''
int b = 0;
''');

    final c = newFile('$packagesRootPath/ccc/lib/c.dart', '''
int c = 0
''');

    final driver = driverFor(testFile);
    driver.addFile2(t);

    final files = await driver.getFilesReferencingName2('int');
    expect(files, contains(t));
    expect(files, contains(a));
    expect(files, contains(b));
    expect(files, isNot(contains(c)));
  }

  test_getFileSync_changedFile() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

void f(A a) {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Ensure that `a` library cycle is loaded.
    // So, `a` is in the library context.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
[status] analyzing
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
    errors
      25 +1 UNDEFINED_CLASS
      7 +8 UNUSED_IMPORT
[stream]
  ResolvedUnitResult #1
[status] idle
''');

    // Notify the driver that the file was changed.
    driver.changeFile2(a);

    // ...and apply this change.
    await driver.applyPendingFileChanges();
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
''');

    // So, `class A {}` is declared now.
    expect(driver.getFileSyncValid(a).lineInfo.lineCount, 2);

    // ...and `b` has no errors.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B2
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
    final a = newFile('$testPackageLibPath/a.dart', '');
    final driver = driverFor(testFile);
    final result = driver.getFileSyncValid(a);
    expect(result.path, a.path);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.isPart, isFalse);
  }

  test_getFileSync_notAbsolutePath() async {
    final driver = driverFor(testFile);
    final result = driver.getFileSync('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getFileSync_part() async {
    final a = newFile('$testPackageLibPath/a.dart', 'part of lib;');
    final driver = driverFor(testFile);
    final result = driver.getFileSyncValid(a);
    expect(result.path, a.path);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.isPart, isTrue);
  }

  test_getIndex() async {
    newFile(testFile.path, r'''
void foo() {}

void f() {
  foo();
}
''');

    final driver = driverFor(testFile);
    driver.addFile2(testFile);

    final index = await driver.getIndex2(testFile);
    index!;

    final unitId = index.strings.indexOf('package:test/test.dart');
    expect(unitId, isNonNegative);

    final fooId = index.strings.indexOf('foo');
    expect(fooId, isNonNegative);
  }

  test_getIndex_notAbsolutePath() async {
    final driver = driverFor(testFile);
    expect(() async {
      await driver.getIndex('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_getLibraryByUri() async {
    final aUriStr = 'package:test/a.dart';
    final bUriStr = 'package:test/b.dart';

    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

class B {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    final result = await driver.getLibraryByUri(aUriStr);
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
[status] analyzing
[status] idle
''');
  }

  test_getLibraryByUri_cannotResolveUri() async {
    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    collector.getLibraryByUri('X', 'foo:bar');

    await assertEventsText(collector, r'''
[future] getLibraryByUri
  name: X
  CannotResolveUriResult
''');
  }

  test_getLibraryByUri_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    final uriStr = 'package:test/a.dart';
    collector.getLibraryByUri('X', uriStr);

    await assertEventsText(collector, r'''
[future] getLibraryByUri
  name: X
  NotLibraryButAugmentationResult
''');
  }

  test_getLibraryByUri_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    final uriStr = 'package:test/a.dart';
    collector.getLibraryByUri('X', uriStr);

    await assertEventsText(collector, r'''
[future] getLibraryByUri
  name: X
  NotLibraryButPartResult
''');
  }

  test_getLibraryByUri_unresolvedUri() async {
    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    final result = await driver.getLibraryByUri('package:foo/foo.dart');
    expect(result, isA<CannotResolveUriResult>());

    // No analysis.
    await assertEventsText(collector, '');
  }

  test_getParsedLibrary() async {
    final content = 'class A {}';
    final a = newFile('$testPackageLibPath/a.dart', content);

    final driver = driverFor(testFile);
    final result = driver.getParsedLibrary2(a);
    result as ParsedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].path, a.path);
    expect(result.units[0].content, content);
    expect(result.units[0].unit, isNotNull);
    expect(result.units[0].errors, isEmpty);
  }

  test_getParsedLibrary_invalidPath_notAbsolute() async {
    final driver = driverFor(testFile);
    final result = driver.getParsedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getParsedLibrary_notLibraryButPart() async {
    final driver = driverFor(testFile);
    final a = newFile('$testPackageLibPath/a.dart', 'part of my;');
    final result = driver.getParsedLibrary2(a);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getParsedLibraryByUri() async {
    final content = 'class A {}';
    final a = newFile('$testPackageLibPath/a.dart', content);

    final driver = driverFor(testFile);

    final uri = Uri.parse('package:test/a.dart');
    final result = driver.getParsedLibraryByUri(uri);
    result as ParsedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].uri, uri);
    expect(result.units[0].path, a.path);
    expect(result.units[0].content, content);
  }

  test_getParsedLibraryByUri_cannotResolveUri() async {
    final driver = driverFor(testFile);
    final uri = Uri.parse('foo:bar');
    expect(
      driver.getParsedLibraryByUri(uri),
      isA<CannotResolveUriResult>(),
    );
  }

  test_getParsedLibraryByUri_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    final uri = Uri.parse('package:test/a.dart');
    expect(
      driver.getParsedLibraryByUri(uri),
      isA<NotLibraryButAugmentationResult>(),
    );
  }

  test_getParsedLibraryByUri_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    final uri = Uri.parse('package:test/a.dart');
    expect(
      driver.getParsedLibraryByUri(uri),
      isA<NotLibraryButPartResult>(),
    );
  }

  test_getParsedLibraryByUri_notLibraryButPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of my;');
    final driver = driverFor(testFile);
    final uri = Uri.parse('package:test/a.dart');
    final result = driver.getParsedLibraryByUri(uri);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getParsedLibraryByUri_unresolvedUri() async {
    final driver = driverFor(testFile);
    final uri = Uri.parse('package:unknown/a.dart');
    final result = driver.getParsedLibraryByUri(uri);
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getResolvedLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.libraryConfiguration.unitConfiguration.withContentPredicate =
        (_) => true;

    collector.getResolvedLibrary('X', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: X
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
        content
---
class A {}
---
''');
  }

  test_getResolvedLibrary_cachePriority() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.priorityFiles2 = [a];

    collector.getResolvedLibrary('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: A1
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
''');

    // Ask again, the same cached instance should be returned.
    // Note, the result is cached.
    collector.getResolvedLibrary('A2', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: A2
  ResolvedLibraryResult #0
''');

    // Ask `a`, returns cached.
    // Note, no status analyzing.
    collector.getResolvedUnit('A3', a);
    await assertEventsText(collector, r'''
[future] getResolvedUnit
  name: A3
  ResolvedUnitResult #1
''');

    // Ask `b`, returns cached.
    // Note, no status analyzing.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #2
''');
  }

  test_getResolvedLibrary_notAbsolutePath() async {
    final driver = driverFor(testFile);
    final result = await driver.getResolvedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('X', a);

    await assertEventsText(collector, r'''
[future] getResolvedLibrary
  name: X
  NotLibraryButAugmentationResult
''');
  }

  test_getResolvedLibrary_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('X', a);

    await assertEventsText(collector, r'''
[future] getResolvedLibrary
  name: X
  NotLibraryButPartResult
''');
  }

  test_getResolvedLibraryByUri() async {
    newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    final uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);

    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibraryByUri
  name: A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
''');
  }

  test_getResolvedLibraryByUri_cannotResolveUri() async {
    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    final uri = Uri.parse('foo:bar');
    collector.getResolvedLibraryByUri('X', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri
  name: X
  CannotResolveUriResult
''');
  }

  test_getResolvedLibraryByUri_library_pending_getResolvedUnit() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final driver = driverFor(a);

    final collector = DriverEventCollector(driver);
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('B2', b);

    final uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A2', uri);

    configuration.withOperations = true;

    // Note, that the `get` events are reported before `stream` events.
    // TODO(scheglov): The current state is not optimal.
    // We resolve `a.dart` separately as `analysisId: 0`.
    // And then again `b.dart` as `analysisId: 1`.
    // But actually we always resolve the whole library `a.dart`.
    // So, we resolved it twice.
    // Even worse, for `getResolvedLibraryByUri` we resolve it again.
    // Theoretically we could have just one resolution overall.
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/a.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit
  name: B2
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
[status] idle
[operation] computeResolvedLibrary
  library: /home/test/lib/a.dart
[future] getResolvedLibraryByUri
  name: A2
  ResolvedLibraryResult #2
    element: package:test/a.dart
    units
      ResolvedUnitResult #3
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
      ResolvedUnitResult #4
        path: /home/test/lib/b.dart
        uri: package:test/b.dart
        flags: exists isPart
''');
  }

  test_getResolvedLibraryByUri_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    final uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('X', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri
  name: X
  NotLibraryButAugmentationResult
''');
  }

  test_getResolvedLibraryByUri_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    final collector = DriverEventCollector(driver);

    final uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('X', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri
  name: X
  NotLibraryButPartResult
''');
  }

  test_getResolvedLibraryByUri_notLibraryButPart() async {
    newFile('$testPackageLibPath/a.dart', 'part of my;');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    final uri = Uri.parse('package:test/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri
  name: A1
  NotLibraryButPartResult
''');
  }

  test_getResolvedLibraryByUri_unresolvedUri() async {
    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    final uri = Uri.parse('package:unknown/a.dart');
    collector.getResolvedLibraryByUri('A1', uri);

    await assertEventsText(collector, r'''
[future] getResolvedLibraryByUri
  name: A1
  CannotResolveUriResult
''');
  }

  test_getResolvedUnit() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
class B extends A {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // No errors in `a` or `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');

    // Remove `a` and reanalyze.
    deleteFile(a.path);
    driver.removeFile2(a);

    // The unresolved URI error must be reported.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B2
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
[status] analyzing
[future] getResolvedUnit
  name: B2
  ResolvedUnitResult #3
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #3
[stream]
  ErrorsResult #4
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_getResolvedUnit_notDartFile() async {
    final a = newFile('$testPackageLibPath/a.txt', r'''
final foo = 0;
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

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
[status] analyzing
[future] getResolvedUnit
  name: A1
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

  test_getResolvedUnit_thenRemove() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Schedule resolved unit computation.
    collector.getResolvedUnit('A1', a);

    // ...and remove the file.
    driver.removeFile2(a);

    // The future with the result still completes.
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Ask the same file twice.
    collector.getResolvedUnit('A1', a);
    collector.getResolvedUnit('A2', a);

    // Both futures complete.
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
[future] getResolvedUnit
  name: A2
  ResolvedUnitResult #0
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_getUnitElement() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
void bar() {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.unitElementConfiguration.elementSelector = (unitElement) {
      return unitElement.functions;
    };

    collector.getUnitElement('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getUnitElement
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  flags: isLibrary
  enclosing: package:test/a.dart
  selectedElements
    package:test/a.dart::@function::foo
    package:test/a.dart::@function::bar
''');
  }

  test_getUnitElement_doesNotExist_afterResynthesized() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:test/b.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    collector.getResolvedLibrary('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getResolvedLibrary
  name: A1
  ResolvedLibraryResult #0
    element: package:test/a.dart
    units
      ResolvedUnitResult #1
        path: /home/test/lib/a.dart
        uri: package:test/a.dart
        flags: exists isLibrary
        errors
          7 +21 URI_DOES_NOT_EXIST
''');

    collector.getUnitElement('A2', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getUnitElement
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  flags: isLibrary
  enclosing: package:test/a.dart
''');
  }

  test_getUnitElement_invalidPath_notAbsolute() async {
    final driver = driverFor(testFile);
    final result = await driver.getUnitElement('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_hermetic_modifyLibraryFile_resolvePart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
final A = 0;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
final B = A;
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.withOperations = true;
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
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    selectedVariableTypes
      B: int
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
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getResolvedUnit
  name: B2
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
  }

  test_importOfNonLibrary_part_afterLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', '''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', '''
part of 'a.dart';
class B {}
''');

    final c = newFile('$testPackageLibPath/c.dart', '''
import 'b.dart';
''');

    final driver = driverFor(testFile);

    // This ensures that `a` linked library is cached.
    await driver.getResolvedUnit2(a);

    // Should not fail because of considering `b` part as `a` library.
    await driver.getResolvedUnit2(c);
  }

  test_knownFiles() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
// ignore:unused_import
import 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
''');

    final driver = driverFor(testFile);

    driver.addFile2(a);
    driver.addFile2(c);
    await pumpEventQueue(times: 5000);
    expect(driver.knownFiles, contains(a.path));
    expect(driver.knownFiles, contains(b.path));
    expect(driver.knownFiles, contains(c.path));

    // Remove `a` and analyze.
    // Both `a` and `b` are not known now.
    driver.removeFile2(a);
    await pumpEventQueue(times: 5000);
    expect(driver.knownFiles, isNot(contains(a.path)));
    expect(driver.knownFiles, isNot(contains(b.path)));
    expect(driver.knownFiles, contains(c.path));
  }

  test_knownFiles_beforeAnalysis() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final driver = driverFor(testFile);

    // `a` is added, but not processed yet.
    // So, the set of known files is empty yet.
    driver.addFile2(a);
    expect(driver.knownFiles, isEmpty);
  }

  test_missingDartLibrary_async() async {
    final driver = driverFor(testFile);

    sdkRoot.getChildAssumingFile('lib/async/async.dart').delete();

    final a = newFile('$testPackageLibPath/a.dart', '');
    final result = await driver.getErrors(a.path);
    result as ErrorsResult;
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.MISSING_DART_LIBRARY, 0, 0),
    ]);
  }

  test_missingDartLibrary_core() async {
    final driver = driverFor(testFile);

    sdkRoot.getChildAssumingFile('lib/core/core.dart').delete();

    final a = newFile('$testPackageLibPath/a.dart', '');
    final result = await driver.getErrors(a.path);
    result as ErrorsResult;
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.MISSING_DART_LIBRARY, 0, 0),
    ]);
  }

  test_parseFileSync_changedFile() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
// ignore:unused_import
import 'a.dart';
void f(A a) {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Ensure that [a] library cycle is loaded.
    // So, `a` is in the library context.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
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
      final parseResult = driver.parseFileSync2(a) as ParsedUnitResult;
      expect(parseResult.unit.declarations, isEmpty);
    }

    // We have not read `a`, so `A` is still not declared.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B1
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
      final result = driver.parseFileSync2(a) as ParsedUnitResult;
      assertParsedNodeText(result.unit, r'''
CompilationUnit
''');
    }

    // The pending change to `a` declares `A`.
    // So, `b` does not have errors anymore.
    collector.getResolvedUnit('B2', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B2
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
      final result = driver.parseFileSync2(a) as ParsedUnitResult;
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

    final b = newFile('$testPackageLibPath/b.dart', r'''
// ignore:unused_import
import 'a.dart';
''');

    final driver = driverFor(testFile);
    expect(driver.fsState.knownFiles, isEmpty);

    // Don't read `a` when parse.
    driver.parseFileSync2(b);
    expect(driver.knownFiles2, unorderedEquals([b]));

    // Still don't read `a.dart` when parse the second time.
    driver.parseFileSync2(b);
    expect(driver.knownFiles2, unorderedEquals([b]));
  }

  test_parseFileSync_notAbsolutePath() async {
    final driver = driverFor(testFile);
    final result = driver.parseFileSync('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_parseFileSync_notDart() async {
    final a = newFile('$testPackageLibPath/a.txt', r'''
class A {}
''');

    final driver = driverFor(testFile);

    final result = driver.parseFileSync2(a) as ParsedUnitResult;
    assertParsedNodeText(result.unit, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      name: A
      leftBracket: {
      rightBracket: }
''');

    expect(driver.knownFiles2, unorderedEquals([a]));
  }

  test_partOfName_getErrors_afterLibrary() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Process `a` so that we know that it's a library for `b`.
    collector.getErrors('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getErrors
  name: A1
  ErrorsResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
''');

    // `b` does not have errors in the context of `a`.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getErrors
  name: B1
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
''');
  }

  test_partOfName_getErrors_beforeLibrary_addedFiles() async {
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // We discover all added files are maybe libraries.
    driver.addFile2(a);
    driver.addFile2(b);

    configuration.withOperations = true;

    // Because `a` is added, we know how to analyze `b`.
    // So, it has no errors.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[future] getErrors
  name: B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[stream]
  ErrorsResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[status] idle
''');
  }

  test_partOfName_getErrors_beforeLibrary_discovered() async {
    newFile('$testPackageLibPath/a.dart', r'''
library a;
part 'b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.withOperations = true;

    // We discover sibling files as libraries.
    // So, we know that `a` is the library of `b`.
    // So, no errors.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/a.dart
[future] getErrors
  name: B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
''');
  }

  test_partOfName_getErrors_beforeLibrary_notDiscovered() async {
    newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.withOperations = true;

    // We don't know that `a` is the library of `b`.
    // So, we treat it as its own library, has errors.
    collector.getErrors('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getErrors
  name: B1
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
    errors
      25 +1 CREATION_WITH_NON_TYPE
''');
  }

  test_partOfName_getResolvedUnit_afterLibrary() async {
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Process `a` so that we know that it's a library for `b`.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    configuration.withOperations = true;

    // We know that `b` is analyzed as part of `a`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_beforeLibrary_addedFiles() async {
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // We discover all added files are maybe libraries.
    driver.addFile2(a);
    driver.addFile2(b);

    configuration.withOperations = true;

    // Because `a` is added, we know how to analyze `b`.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #0
[stream]
  ErrorsResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_beforeLibrary_notDiscovered() async {
    newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.withOperations = true;

    // We don't know that `a` is the library of `b`.
    // So, we treat it as its own library.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      25 +1 CREATION_WITH_NON_TYPE
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_changePart_invalidatesLibraryCycle() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
part 'b.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Analyze the library without the part.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      26 +8 URI_DOES_NOT_EXIST
      7 +12 UNUSED_IMPORT
[status] idle
''');

    // Create the part file.
    // This should invalidate library file state (specifically the library
    // cycle), so that we can re-link the library, and get new dependencies.
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
Future<int>? f;
''');
    driver.changeFile2(b);

    // This should not crash.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ResolvedUnitResult #1
[stream]
  ErrorsResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_hasLibrary_noPart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Discover the library.
    driver.getFileSync2(a);

    configuration.withOperations = true;

    // There is no library which `b` is a part of, so `A` is unresolved.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      30 +1 CREATION_WITH_NON_TYPE
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getResolvedUnit_noLibrary() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
var a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.withOperations = true;

    // There is no library which `b` is a part of, so `A` is unresolved.
    collector.getResolvedUnit('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[future] getResolvedUnit
  name: B1
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      28 +1 CREATION_WITH_NON_TYPE
[stream]
  ResolvedUnitResult #0
[status] idle
''');
  }

  test_partOfName_getUnitElement_afterLibrary() async {
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // Process `a` so that we know that it's a library for `b`.
    collector.getResolvedUnit('A1', a);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getResolvedUnit
  name: A1
  ResolvedUnitResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: exists isLibrary
[stream]
  ResolvedUnitResult #0
[status] idle
''');

    // We know that `a` is the library for `b`.
    collector.getUnitElement('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getUnitElement
  path: /home/test/lib/b.dart
  uri: package:test/b.dart
  flags: isPart
  enclosing: package:test/hidden/a.dart
''');
  }

  test_partOfName_getUnitElement_beforeLibrary_addedFiles() async {
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // We discover all added files are maybe libraries.
    driver.addFile2(a);
    driver.addFile2(b);

    configuration.withOperations = true;

    // Because `a` is added, we know how to analyze `b`.
    collector.getUnitElement('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[future] getUnitElement
  path: /home/test/lib/b.dart
  uri: package:test/b.dart
  flags: isPart
  enclosing: package:test/hidden/a.dart
[operation] computeAnalysisResult
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ErrorsResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[status] idle
''');
  }

  test_partOfName_getUnitElement_noLibrary() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    configuration.withOperations = true;

    // We don't know the library for `b`.
    // So, we treat it as its own library.
    collector.getUnitElement('B1', b);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
[future] getUnitElement
  path: /home/test/lib/b.dart
  uri: package:test/b.dart
  flags: isPart
  enclosing: package:test/b.dart
''');
  }

  test_partOfName_results_afterLibrary() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // The order does not matter.
    // It used to matter, but not anymore.
    driver.addFile2(a);
    driver.addFile2(b);

    configuration.withOperations = true;

    // We discover all added libraries.
    // So, we know that `a` is the library of `b`.
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/hidden/a.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ErrorsResult #0
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[status] idle
''');
  }

  test_partOfName_results_beforeLibrary() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // The order does not matter.
    // It used to matter, but not anymore.
    driver.addFile2(b);
    driver.addFile2(a);

    configuration.withOperations = true;

    // We discover all added libraries.
    // So, we know that `a` is the library of `b`.
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
[stream]
  ErrorsResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_partOfName_results_beforeLibrary_priority() async {
    // Note, we put the library into a different directory.
    // Otherwise we will discover it.
    final a = newFile('$testPackageLibPath/hidden/a.dart', r'''
library a;
part '../b.dart';
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // The order does not matter.
    // It used to matter, but not anymore.
    driver.addFile2(b);
    driver.addFile2(a);
    driver.priorityFiles2 = [b];

    configuration.withOperations = true;

    // We discover all added libraries.
    // So, we know that `a` is the library of `b`.
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/hidden/a.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
[stream]
  ErrorsResult #1
    path: /home/test/lib/hidden/a.dart
    uri: package:test/hidden/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_partOfName_results_noLibrary() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(b);

    configuration.withOperations = true;

    // There is no library for `b`.
    // So, we analyze `b` as its own library.
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ErrorsResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isPart
    errors
      25 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_partOfName_results_noLibrary_priority() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of a;
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(b);
    driver.priorityFiles2 = [b];

    configuration.withOperations = true;

    // There is no library for `b`.
    // So, we analyze `b` as its own library.
    await assertEventsText(collector, r'''
[status] analyzing
[operation] computeAnalysisResult
  file: /home/test/lib/b.dart
  library: /home/test/lib/b.dart
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: exists isPart
    errors
      25 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_removeFile_addFile() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');

    driver.removeFile2(a);
    driver.addFile2(a);

    // We analyze `a` again.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
final A = B;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
final B = 0;
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

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
[status] analyzing
[stream]
  ResolvedUnitResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: exists isLibrary
    selectedVariableTypes
      A: int
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
[status] analyzing
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
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // We don't analyze `a`, so we get nothing.
    await assertEventsText(collector, r'''
''');

    // Remove `a`, and also change it.
    // Still nothing, we still don't analyze `a`.
    driver.removeFile2(a);
    driver.changeFile2(a);
    await assertEventsText(collector, r'''
[status] analyzing
[status] idle
''');
  }

  test_removeFile_invalidate_importers() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
final a = new A();
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // No errors in `b`.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[status] idle
''');

    // Remove `a`, so `b` is reanalyzed and has an error.
    deleteFile2(a);
    driver.removeFile2(a);
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #2
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
    errors
      7 +8 URI_DOES_NOT_EXIST
      31 +1 CREATION_WITH_NON_TYPE
[status] idle
''');
  }

  test_removeFile_notAbsolutePath() async {
    final driver = driverFor(testFile);
    expect(() {
      driver.removeFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_results_order() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
// ignore:unused_import
import 'd.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', '');

    final c = newFile('$testPackageLibPath/c.dart', r'''
// ignore:unused_import
import 'd.dart';
''');

    final d = newFile('$testPackageLibPath/d.dart', r'''
// ignore:unused_import
import 'b.dart';
''');

    final e = newFile('$testPackageLibPath/e.dart', r'''
// ignore:unused_import
export 'b.dart';
''');

    // This file intentionally has an error.
    final f = newFile('$testPackageLibPath/f.dart', r'''
// ignore:unused_import
import 'e.dart';
class F extends X {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);
    driver.addFile2(e);
    driver.addFile2(f);

    // Initial analysis, all files analyzed in order of adding.
    // Note, `f` has an error.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[stream]
  ErrorsResult #2
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: isLibrary
[stream]
  ErrorsResult #3
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: isLibrary
[stream]
  ErrorsResult #4
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: isLibrary
[stream]
  ErrorsResult #5
    path: /home/test/lib/f.dart
    uri: package:test/f.dart
    flags: isLibrary
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
[status] analyzing
[stream]
  ErrorsResult #6
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[stream]
  ErrorsResult #7
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: isLibrary
[stream]
  ErrorsResult #8
    path: /home/test/lib/f.dart
    uri: package:test/f.dart
    flags: isLibrary
    errors
      57 +1 EXTENDS_NON_CLASS
[stream]
  ErrorsResult #9
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #10
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: isLibrary
[stream]
  ErrorsResult #11
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: isLibrary
[status] idle
''');
  }

  test_results_order_allChangedFirst_thenImports() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
''');

    final d = newFile('$testPackageLibPath/d.dart', r'''
// ignore:unused_import
import 'a.dart';
''');

    final e = newFile('$testPackageLibPath/e.dart', r'''
// ignore:unused_import
import 'b.dart';
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);
    driver.addFile2(c);
    driver.addFile2(d);
    driver.addFile2(e);

    // Initial analysis, all files analyzed in order of adding.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[stream]
  ErrorsResult #2
    path: /home/test/lib/c.dart
    uri: package:test/c.dart
    flags: isLibrary
[stream]
  ErrorsResult #3
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: isLibrary
[stream]
  ErrorsResult #4
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: isLibrary
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
[status] analyzing
[stream]
  ErrorsResult #5
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #6
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[stream]
  ErrorsResult #7
    path: /home/test/lib/d.dart
    uri: package:test/d.dart
    flags: isLibrary
[stream]
  ErrorsResult #8
    path: /home/test/lib/e.dart
    uri: package:test/e.dart
    flags: isLibrary
[status] idle
''');
  }

  test_results_removeFile_changeFile() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
final v = 0;
''');

    final b = getFile('$testPackageLibPath/b.dart');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
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
[status] analyzing
[stream]
  ErrorsResult #1
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
    errors
      10 +1 EXPECTED_TOKEN
[status] idle
''');
  }

  test_results_skipNotAffected() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);
    driver.addFile2(b);

    // Initial analysis.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[stream]
  ErrorsResult #1
    path: /home/test/lib/b.dart
    uri: package:test/b.dart
    flags: isLibrary
[status] idle
''');

    // Update `a` and notify.
    modifyFile2(a, r'''
class A2 {}
''');
    driver.changeFile2(a);

    // Only `a` is analyzed, `b` is not affected.
    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #2
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_schedulerStatus_hasAddedFile() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    driver.addFile2(a);

    await assertEventsText(collector, r'''
[status] analyzing
[stream]
  ErrorsResult #0
    path: /home/test/lib/a.dart
    uri: package:test/a.dart
    flags: isLibrary
[status] idle
''');
  }

  test_schedulerStatus_noAddedFile() async {
    final driver = driverFor(testFile);
    final collector = DriverEventCollector(driver);

    // No files, so no status changes.
    await assertEventsText(collector, r'''
''');
  }
}

@reflectiveTest
class AnalysisDriverSchedulerTest with ResourceProviderMixin {
  final ByteStore byteStore = MemoryByteStore();
  final InfoDeclarationStore infoDeclarationStore = InfoDeclarationStoreImpl();

  final StringBuffer logBuffer = StringBuffer();
  late final PerformanceLog logger;

  late final AnalysisDriverScheduler scheduler;

  final ListQueue<Object> allEvents = ListQueue<Object>();
  final List<AnalysisResultWithErrors> allResults = [];

  Folder get sdkRoot => newFolder('/sdk');

  AnalysisDriver newDriver(AnalysisDriverScheduler scheduler) {
    var sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);
    AnalysisDriver driver = AnalysisDriver(
      scheduler: scheduler,
      logger: logger,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      infoDeclarationStore: infoDeclarationStore,
      sourceFactory: SourceFactory(
        [DartUriResolver(sdk), ResourceUriResolver(resourceProvider)],
      ),
      analysisOptionsMap:
          AnalysisOptionsMap.forSharedOptions(AnalysisOptionsImpl()),
      packages: Packages.empty,
    );
    return driver;
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    logger = PerformanceLog(logBuffer);
    scheduler = AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_priorities_allChangedFirst() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    String d = convertPath('/d.dart');
    newFile(a, 'class A {}');
    newFile(b, "import 'a.dart';");
    newFile(c, 'class C {}');
    newFile(d, "import 'c.dart';");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver2.addFile(d);

    await scheduler.waitForIdle();
    allResults.clear();

    modifyFile(a, 'class A2 {}');
    modifyFile(c, 'class C2 {}');
    driver1.changeFile(a);
    driver1.changeFile(c);
    driver2.changeFile(a);
    driver2.changeFile(c);

    await scheduler.waitForIdle();
    expect(allResults, hasLength(greaterThanOrEqualTo(2)));
    expect(allResults[0].path, a);
    expect(allResults[1].path, c);
  }

  test_priorities_firstChanged_thenImporting() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, "import 'c.dart';");
    newFile(b, 'class B {}');
    newFile(c, "import 'b.dart';");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);

    await scheduler.waitForIdle();
    allResults.clear();

    modifyFile(b, 'class B2 {}');
    driver1.changeFile(b);
    driver2.changeFile(b);

    await scheduler.waitForIdle();
    expect(allResults, hasLength(greaterThanOrEqualTo(2)));
    expect(allResults[0].path, b);
    expect(allResults[1].path, c);
  }

  test_priorities_firstChanged_thenWithErrors() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    String d = convertPath('/d.dart');
    newFile(a, 'class A {}');
    newFile(b, "export 'a.dart';");
    newFile(c, "import 'b.dart';");
    newFile(d, "import 'b.dart'; class D extends X {}");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver2.addFile(d);

    await scheduler.waitForIdle();
    allResults.clear();

    modifyFile(a, 'class A2 {}');
    driver1.changeFile(a);
    driver2.changeFile(a);

    await scheduler.waitForIdle();
    expect(allResults, hasLength(greaterThanOrEqualTo(2)));
    expect(allResults[0].path, a);
    expect(allResults[1].path, d);
  }

  test_priorities_getResolvedUnit_beforePriority() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    var result = await driver2.getResolvedUnit(b) as ResolvedUnitResult;
    expect(result.path, b);

    await _waitForAnalysisStatusIdle();

    expect(allResults, hasLength(3));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
    expect(allResults[2].path, c);
  }

  test_priorities_priorityBeforeGeneral1() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    await _waitForAnalysisStatusIdle();

    expect(allResults, hasLength(2));
    expect(allResults[0].path, a);
    expect(allResults[1].path, b);
  }

  test_priorities_priorityBeforeGeneral2() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [b];
    driver2.priorityFiles = [b];

    await _waitForAnalysisStatusIdle();

    expect(allResults, hasLength(2));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
  }

  test_priorities_priorityBeforeGeneral3() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a, c];
    driver2.priorityFiles = [a, c];

    await _waitForAnalysisStatusIdle();

    expect(allResults, hasLength(3));
    expect(allResults[0].path, a);
    expect(allResults[1].path, c);
    expect(allResults[2].path, b);
  }

  test_status() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);

    // TODO(scheglov): use text expectations
    final idleStatusCompleter = Completer<void>();
    final allStatuses = <AnalysisStatus>[];
    while (true) {
      final status = allEvents.removeFirstOrNull();
      if (status is AnalysisStatus) {
        allStatuses.add(status);
        if (status.isIdle) {
          idleStatusCompleter.complete();
          break;
        }
      }
      await pumpEventQueue();
    }

    await idleStatusCompleter.future;
    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[1].isAnalyzing, isFalse);

    expect(allResults, hasLength(3));
  }

  test_status_anyWorkTransitionsToAnalyzing() async {
    final scheduler = _newScheduler();
    AnalysisDriver driver1 = newDriver(scheduler);
    AnalysisDriver driver2 = newDriver(scheduler);

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);

    // TODO(scheglov): use text expectations
    // The two added files were analyzed, and the schedule is idle.
    {
      final idleStatusCompleter = Completer<void>();
      final allStatuses = <AnalysisStatus>[];
      while (true) {
        final status = allEvents.removeFirstOrNull();
        if (status is AnalysisStatus) {
          allStatuses.add(status);
          if (status.isIdle) {
            idleStatusCompleter.complete();
            break;
          }
        }
        await pumpEventQueue();
      }
      expect(allStatuses, [AnalysisStatus.ANALYZING, AnalysisStatus.IDLE]);
    }

    // Any work transitions to analyzing, and back to idle.
    {
      await driver1.getFilesReferencingName('X');
      final idleStatusCompleter = Completer<void>();
      final allStatuses = <AnalysisStatus>[];
      while (true) {
        final status = allEvents.removeFirstOrNull();
        if (status is AnalysisStatus) {
          allStatuses.add(status);
          if (status.isIdle) {
            idleStatusCompleter.complete();
            break;
          }
        }
        await pumpEventQueue();
      }
      expect(allStatuses, [AnalysisStatus.ANALYZING, AnalysisStatus.IDLE]);
    }
  }

  AnalysisDriverScheduler _newScheduler() {
    final scheduler = AnalysisDriverScheduler(
      PerformanceLog(null),
    );

    scheduler.events.listen((event) {
      allEvents.add(event);
      if (event is AnalysisResultWithErrors) {
        allResults.add(event);
      }
    });

    scheduler.start();
    return scheduler;
  }

  // TODO(scheglov): use text expectations
  Future<void> _waitForAnalysisStatusIdle() async {
    while (true) {
      final first = allEvents.removeFirstOrNull();
      if (first is AnalysisStatus && first.isIdle) {
        break;
      }
      await pumpEventQueue();
    }
  }
}

/// Tracks events reported into the `results` stream, and results of `getXyz`
/// requests. We are interested in relative orders, identity of the objects,
/// absence of duplicate events, etc.
class DriverEventCollector {
  final idProvider = IdProvider();
  final AnalysisDriver driver;
  List<DriverEvent> events = [];

  DriverEventCollector(this.driver) {
    driver.scheduler.events.listen((event) {
      switch (event) {
        case AnalysisStatus():
          events.add(
            SchedulerStatusEvent(event),
          );
        case driver_events.ComputeAnalysis():
        case driver_events.ComputeResolvedLibrary():
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

  void getCachedResolvedUnit(String name, File file) {
    final value = driver.getCachedResolvedUnit2(file);
    events.add(
      GetCachedResolvedUnitEvent(
        name: name,
        result: value,
      ),
    );
  }

  void getErrors(String name, File file) {
    final future = driver.getErrors(file.path);

    unawaited(future.then((value) {
      events.add(
        GetErrorsEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  void getLibraryByUri(String name, String uriStr) {
    final future = driver.getLibraryByUri(uriStr);
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
    final future = driver.getResolvedLibrary(file.path);
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
    final future = driver.getResolvedLibraryByUri(uri);
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
    final future = driver.getResolvedUnit(
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
    final future = driver.getUnitElement2(file);
    unawaited(future.then((value) {
      events.add(
        GetUnitElementEvent(
          name: name,
          result: value,
        ),
      );
    }));
  }

  List<DriverEvent> take() {
    final result = events;
    events = [];
    return result;
  }
}

extension on AnalysisDriver {
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
