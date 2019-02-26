// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show ResolverErrorCode;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_type_matchers.dart';
import '../../../utils.dart';
import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverSchedulerTest);
    defineReflectiveTests(AnalysisDriverTest);
    defineReflectiveTests(CacheAllAnalysisDriverTest);
  });
}

/**
 * Returns a [Future] that completes after pumping the event queue [times]
 * times. By default, this should pump the event queue enough times to allow
 * any code to run, as long as it's not waiting on some external event.
 */
Future pumpEventQueue([int times = 5000]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.zero, () => pumpEventQueue(times - 1));
}

@reflectiveTest
class AnalysisDriverSchedulerTest with ResourceProviderMixin {
  DartSdk sdk;
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  List<ResolvedUnitResult> allResults = [];

  AnalysisDriver newDriver() {
    sdk = new MockSdk(resourceProvider: resourceProvider);
    AnalysisDriver driver = new AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        byteStore,
        contentOverlay,
        null,
        new SourceFactory([
          new DartUriResolver(sdk),
          new ResourceUriResolver(resourceProvider)
        ], null, resourceProvider),
        new AnalysisOptionsImpl());
    driver.results.forEach(allResults.add);
    return driver;
  }

  void setUp() {
    sdk = new MockSdk(resourceProvider: resourceProvider);
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_priorities_allChangedFirst() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    String d = convertPath('/d.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: "import 'a.dart';");
    newFile(c, content: 'class C {}');
    newFile(d, content: "import 'c.dart';");
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
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, content: "import 'c.dart';");
    newFile(b, content: 'class B {}');
    newFile(c, content: "import 'b.dart';");
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
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    String d = convertPath('/d.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: "export 'a.dart';");
    newFile(c, content: "import 'b.dart';");
    newFile(d, content: "import 'b.dart'; class D extends X {}");
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

  test_priorities_getResult_beforePriority() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    ResolvedUnitResult result = await driver2.getResult(b);
    expect(result.path, b);

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(3));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
    expect(allResults[2].path, c);
  }

  test_priorities_priorityBeforeGeneral1() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(2));
    expect(allResults[0].path, a);
    expect(allResults[1].path, b);
  }

  test_priorities_priorityBeforeGeneral2() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [b];
    driver2.priorityFiles = [b];

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(2));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
  }

  test_priorities_priorityBeforeGeneral3() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a, c];
    driver2.priorityFiles = [a, c];

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(3));
    expect(allResults[0].path, a);
    expect(allResults[1].path, c);
    expect(allResults[2].path, b);
  }

  test_status() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    String c = convertPath('/c.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);

    Monitor idleStatusMonitor = new Monitor();
    List<AnalysisStatus> allStatuses = [];
    scheduler.status.forEach((status) {
      allStatuses.add(status);
      if (status.isIdle) {
        idleStatusMonitor.notify();
      }
    });

    await idleStatusMonitor.signal;

    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[1].isAnalyzing, isFalse);

    expect(allResults, hasLength(3));
  }

  test_status_analyzingOnlyWhenHasFilesToAnalyze() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);

    Monitor idleStatusMonitor = new Monitor();
    List<AnalysisStatus> allStatuses = [];
    scheduler.status.forEach((status) {
      allStatuses.add(status);
      if (status.isIdle) {
        idleStatusMonitor.notify();
      }
    });

    // The two added files were analyzed, and the schedule is idle.
    await idleStatusMonitor.signal;
    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[1].isAnalyzing, isFalse);
    allStatuses.clear();

    // We don't transition to analysis and back to idle.
    await driver1.getFilesReferencingName('X');
    expect(allStatuses, isEmpty);
  }
}

/// TODO(paulberry): migrate this test away from the task model.
/// See dartbug.com/35734.
@reflectiveTest
class AnalysisDriverTest extends BaseAnalysisDriverTest {
  void configurePreviewDart2() {
    driver.configure(
        analysisOptions: new AnalysisOptionsImpl.from(driver.analysisOptions));
  }

  test_addedFiles() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    driver.addFile(a);
    expect(driver.addedFiles, contains(a));
    expect(driver.addedFiles, isNot(contains(b)));

    driver.removeFile(a);
    expect(driver.addedFiles, isNot(contains(a)));
    expect(driver.addedFiles, isNot(contains(b)));
  }

  test_addFile_notAbsolutePath() async {
    try {
      driver.addFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_addFile_shouldRefresh() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, content: 'class A {}');
    newFile(b, content: r'''
import 'a.dart';
''');

    driver.addFile(a);
    driver.addFile(b);

    void assertNumberOfErrorsInB(int n) {
      var bResult = allResults.singleWhere((r) => r.path == b);
      expect(bResult.errors, hasLength(n));
      allResults.clear();
    }

    // Initial analysis, 'b' does not use 'a', so there is a hint.
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(1);

    // Update 'b' to use 'a', no more hints.
    newFile(b, content: r'''
import 'a.dart';
main() {
  print(A);
}
''');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(0);

    // Change 'b' content so that it has a hint.
    // Remove 'b' and add it again.
    // The file 'b' must be refreshed, and the hint must be reported.
    newFile(b, content: r'''
import 'a.dart';
''');
    driver.removeFile(b);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(1);
  }

  test_addFile_thenRemove() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    driver.addFile(a);
    driver.addFile(b);

    // Now remove 'a'.
    driver.removeFile(a);

    await waitForIdleWithoutExceptions();

    // Only 'b' has been analyzed, because 'a' was removed before we started.
    expect(allResults, hasLength(1));
    expect(allResults[0].path, b);
  }

  test_analyze_resolveDirectives() async {
    var lib = convertPath('/test/lib.dart');
    var part1 = convertPath('/test/part1.dart');
    var part2 = convertPath('/test/part2.dart');
    newFile(lib, content: '''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
    newFile(part1, content: '''
part of lib;
''');
    newFile(part2, content: '''
part of 'lib.dart';
''');

    ResolvedUnitResult libResult = await driver.getResult(lib);
    ResolvedUnitResult partResult1 = await driver.getResult(part1);
    ResolvedUnitResult partResult2 = await driver.getResult(part2);

    CompilationUnit libUnit = libResult.unit;
    CompilationUnit partUnit1 = partResult1.unit;
    CompilationUnit partUnit2 = partResult2.unit;

    CompilationUnitElement unitElement = libUnit.declaredElement;
    CompilationUnitElement partElement1 = partUnit1.declaredElement;
    CompilationUnitElement partElement2 = partUnit2.declaredElement;

    LibraryElement libraryElement = unitElement.library;
    {
      expect(libraryElement.entryPoint, isNull);
      expect(libraryElement.source, unitElement.source);
      expect(libraryElement.definingCompilationUnit, unitElement);
      expect(libraryElement.parts, hasLength(2));
    }

    expect((libUnit.directives[0] as LibraryDirective).element, libraryElement);
    expect((libUnit.directives[1] as PartDirective).element, partElement1);
    expect((libUnit.directives[2] as PartDirective).element, partElement2);

    {
      var partOf = partUnit1.directives.single as PartOfDirective;
      expect(partOf.element, libraryElement);
    }

    {
      var partOf = partUnit2.directives.single as PartOfDirective;
      expect(partOf.element, libraryElement);
    }
  }

  test_analyze_resolveDirectives_error_missingLibraryDirective() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, content: '''
part 'part.dart';
''');
    newFile(part, content: '''
part of lib;
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, ResolverErrorCode.PART_OF_UNNAMED_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byName() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, content: '''
library lib;
part 'part.dart';
''');
    newFile(part, content: '''
part of someOtherLib;
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byUri() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, content: '''
library lib;
part 'part.dart';
''');
    newFile(part, content: '''
part of 'other_lib.dart';
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfNonPart() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, content: '''
library lib;
part 'part.dart';
''');
    newFile(part, content: '''
// no part of directive
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_NON_PART);
  }

  test_cachedPriorityResults() async {
    var a = convertPath('/test/bin/a.dart');
    newFile(a, content: 'var a = 1;');

    driver.priorityFiles = [a];

    ResolvedUnitResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result1));

    await waitForIdleWithoutExceptions();
    allResults.clear();

    // Get the (cached) result, not reported to the stream.
    {
      ResolvedUnitResult result2 = await driver.getResult(a);
      expect(result2, same(result1));
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, reported to the stream.
    {
      ResolvedUnitResult result2 =
          await driver.getResult(a, sendCachedToStream: true);
      expect(result2, same(result1));

      expect(allResults, hasLength(1));
      expect(allResults.single, same(result1));
    }
  }

  test_cachedPriorityResults_flush_onAnyFileChange() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, content: 'var a = 1;');
    newFile(a, content: 'var b = 2;');

    driver.priorityFiles = [a];

    ResolvedUnitResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Change a file.
    // The cache is flushed.
    driver.changeFile(a);
    expect(driver.test.priorityResults, isEmpty);
    ResolvedUnitResult result2 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result2));

    // Add a file.
    // The cache is flushed.
    driver.addFile(b);
    expect(driver.test.priorityResults, isEmpty);
    ResolvedUnitResult result3 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result3));

    // Remove a file.
    // The cache is flushed.
    driver.removeFile(b);
    expect(driver.test.priorityResults, isEmpty);
  }

  test_cachedPriorityResults_flush_onPrioritySetChange() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, content: 'var a = 1;');
    newFile(b, content: 'var b = 2;');

    driver.priorityFiles = [a];

    ResolvedUnitResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Make "a" and "b" priority.
    // We still have the result for "a" cached.
    driver.priorityFiles = [a, b];
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Get the result for "b".
    ResolvedUnitResult result2 = await driver.getResult(b);
    expect(driver.test.priorityResults, hasLength(2));
    expect(driver.test.priorityResults, containsPair(a, result1));
    expect(driver.test.priorityResults, containsPair(b, result2));

    // Only "b" is priority.
    // The result for "a" is flushed.
    driver.priorityFiles = [b];
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(b, result2));
  }

  test_cachedPriorityResults_notPriority() async {
    var a = convertPath('/test/bin/a.dart');
    newFile(a, content: 'var a = 1;');

    ResolvedUnitResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, isEmpty);

    // The file is not priority, so its result is not cached.
    ResolvedUnitResult result2 = await driver.getResult(a);
    expect(result2, isNot(same(result1)));
  }

  test_changeFile_implicitlyAnalyzed() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: r'''
import 'b.dart';
var A = B;
''');
    newFile(b, content: 'var B = 1;');

    driver.priorityFiles = [a];
    driver.addFile(a);

    // We have a result only for "a".
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      ResolvedUnitResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    allResults.clear();

    // Change "b" and notify.
    modifyFile(b, 'var B = 1.2;');
    driver.changeFile(b);

    // "b" is not an added file, so it is not scheduled for analysis.
    expect(driver.test.fileTracker.hasPendingFiles, isFalse);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // The change causes "a" to be reanalyzed.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      ResolvedUnitResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_changeFile_notAbsolutePath() async {
    try {
      driver.changeFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_changeFile_notUsed() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/other/b.dart');
    newFile(a);
    newFile(b, content: 'class B1 {}');

    driver.addFile(a);

    await waitForIdleWithoutExceptions();
    allResults.clear();

    // Change "b" and notify.
    // Nothing depends on "b", so nothing is analyzed.
    modifyFile(b, 'class B2 {}');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();
    expect(allResults, isEmpty);

    // This should not add "b" to the file state.
    expect(driver.fsState.knownFilePaths, isNot(contains(b)));
  }

  test_changeFile_selfConsistent() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    newFile(b, content: r'''
import 'a.dart';
var B1 = A1;
''');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // We have results for both "a" and "b".
    expect(allResults, hasLength(2));
    {
      ResolvedUnitResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'int');
    }
    {
      ResolvedUnitResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'int');
    }

    // Clear the results and update "a".
    allResults.clear();
    modifyFile(a, r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    // We again get results for both "a" and "b".
    // The results are consistent.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(2));
    {
      ResolvedUnitResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'double');
    }
    {
      ResolvedUnitResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'double');
    }
  }

  test_changeFile_single() async {
    addTestFile('var V = 1;', priority: true);

    // Initial analysis.
    {
      await waitForIdleWithoutExceptions();
      expect(allResults, hasLength(1));
      ResolvedUnitResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'int');
    }

    // Update the file, but don't notify the driver.
    allResults.clear();
    modifyFile(testFile, 'var V = 1.2;');

    // No new results.
    await pumpEventQueue();
    expect(allResults, isEmpty);

    // Notify the driver about the change.
    driver.changeFile(testFile);

    // The file was changed, so it is scheduled for analysis.
    expect(driver.test.fileTracker.isFilePending(testFile), isTrue);

    // We get a new result.
    {
      await waitForIdleWithoutExceptions();
      expect(allResults, hasLength(1));
      ResolvedUnitResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'double');
    }
  }

  test_const_annotation_notConstConstructor() async {
    addTestFile('''
class A {
  final int i;
  A(this.i);
}

@A(5)
class C {}
''');
    var result = await driver.getResult(testFile);
    var atD = AstFinder.getClass(result.unit, 'C').metadata[0];
    var atDI = atD.elementAnnotation as ElementAnnotationImpl;
    var value = atDI.evaluationResult.value;
    // That is illegal.
    expect(value, isNull);
  }

  test_const_annotation_withArgs() async {
    addTestFile('''
const x = 1;
@D(x) class C {}
class D {
  const D(this.value);
  final value;
}
''');
    var result = await driver.getResult(testFile);
    var atD = AstFinder.getClass(result.unit, 'C').metadata[0];
    var atDI = atD.elementAnnotation as ElementAnnotationImpl;
    var value = atDI.evaluationResult.value;
    expect(value, isNotNull);
    expect(value.type, isNotNull);
    expect(value.type.name, 'D');
    expect(value.fields.keys, ['value']);
    expect(value.getField('value').toIntValue(), 1);
    expect(atDI.evaluationResult.errors, isEmpty);
  }

  test_const_annotation_withoutArgs() async {
    addTestFile('''
const x = 1;
@x class C {}
''');
    var result = await driver.getResult(testFile);
    Annotation at_x = AstFinder.getClass(result.unit, 'C').metadata[0];
    expect(at_x.elementAnnotation.constantValue.toIntValue(), 1);
  }

  test_const_circular_reference() async {
    addTestFile('''
const x = y + 1;
const y = x + 1;
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x')
        as TopLevelVariableElementImpl;
    _expectCircularityError(x.evaluationResult);
  }

  test_const_dependency_sameUnit() async {
    addTestFile('''
const x = y + 1;
const y = 1;
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    var y = AstFinder.getTopLevelVariableElement(result.unit, 'y');
    expect(x.constantValue.toIntValue(), 2);
    expect(y.constantValue.toIntValue(), 1);
  }

  test_const_externalConstFactory() async {
    addTestFile('''
const x = const C.foo();

class C extends B {
  external const factory C.foo();
}

class B {}
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.constantValue, isNotNull);
  }

  test_const_implicitCreation() async {
    configurePreviewDart2();

    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, content: r'''
class C {
  const C();
  static const C WARNING = C();
}
''');
    newFile(b, content: r'''
import 'a.dart';

class D {
  const D();
  static const D WARNING = D();
}

const c = C.WARNING;
const d = D.WARNING;
''');
    ResolvedUnitResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_const_implicitCreation_rewrite() async {
    configurePreviewDart2();

    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, content: r'''
class A {
  const A();
}

class B {
  final A a;
  const B(this.a);
}

class C {
  const b = B(A());
  const C();
}
''');
    newFile(b, content: r'''
import 'a.dart';

main() {
  const C();
}
''');
    ResolvedUnitResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_const_implicitSuperConstructorInvocation() async {
    addTestFile('''
class Base {}
class Derived extends Base {
  const Derived();
}
const x = const Derived();
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.constantValue, isNotNull);
  }

  test_const_simple_topLevelVariable() async {
    addTestFile('''
const x = 1;
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.constantValue.toIntValue(), 1);
  }

  test_currentSession() async {
    var a = convertPath('/a.dart');

    newFile(a, content: 'var V = 1;');
    await driver.getResult(a);

    var session1 = driver.currentSession;
    expect(session1, isNotNull);

    modifyFile(a, 'var V = 2;');
    driver.changeFile(a);
    await driver.getResult(a);

    var session2 = driver.currentSession;
    expect(session2, isNotNull);

    // We get a new session.
    expect(session2, isNot(session1));
  }

  test_discoverAvailableFiles_packages() async {
    var t = convertPath('/test/lib/test.dart');
    var a1 = convertPath('/aaa/lib/a1.dart');
    var a2 = convertPath('/aaa/lib/src/a2.dart');
    var a3 = convertPath('/aaa/lib/a3.txt');
    var b = convertPath('/bbb/lib/b.dart');
    var c = convertPath('/ccc/lib/c.dart');

    newFile(t, content: 'class T {}');
    newFile(a1, content: 'class A1 {}');
    newFile(a2, content: 'class A2 {}');
    newFile(a3, content: 'text');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');

    driver.addFile(t);
    // Don't add a1.dart, a2.dart, or b.dart - they should be discovered.
    // And c.dart is not in .packages, so should not be discovered.

    await driver.discoverAvailableFiles();

    expect(driver.knownFiles, contains(t));
    expect(driver.knownFiles, contains(a1));
    expect(driver.knownFiles, contains(a2));
    expect(driver.knownFiles, isNot(contains(a3)));
    expect(driver.knownFiles, contains(b));
    expect(driver.knownFiles, isNot(contains(c)));

    // We call wait for discovery more than once.
    await driver.discoverAvailableFiles();
  }

  test_discoverAvailableFiles_sdk() async {
    await driver.discoverAvailableFiles();

    void assertHasDartUri(String uri) {
      var file = sdk.mapDartUri(uri).fullName;
      expect(driver.knownFiles, contains(file));
    }

    assertHasDartUri('dart:async');
    assertHasDartUri('dart:collection');
    assertHasDartUri('dart:convert');
    assertHasDartUri('dart:core');
    assertHasDartUri('dart:math');
  }

  test_errors_uriDoesNotExist_export() async {
    addTestFile(r'''
export 'foo.dart';
''');

    ResolvedUnitResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import() async {
    addTestFile(r'''
import 'foo.dart';
''');

    ResolvedUnitResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import_deferred() async {
    addTestFile(r'''
import 'foo.dart' deferred as foo;
main() {
  foo.loadLibrary();
}
''', priority: true);

    ResolvedUnitResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_part() async {
    addTestFile(r'''
library lib;
part 'foo.dart';
''');

    ResolvedUnitResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_externalSummaries() async {
    var a = convertPath('/a.dart');
    var b = convertPath('/b.dart');
    newFile(a, content: r'''
class A {}
''');
    newFile(b, content: r'''
import 'a.dart';
var a = new A();
''');

    // Prepare the store with a.dart and everything it needs.
    SummaryDataStore summaryStore =
        await createAnalysisDriver().test.getSummaryStore(a);

    // There are at least a.dart and dart:core libraries.
    String aUri = toUriStr(a);
    expect(summaryStore.unlinkedMap.keys, contains(aUri));
    expect(summaryStore.linkedMap.keys, contains(aUri));
    expect(summaryStore.unlinkedMap.keys, contains('dart:core'));
    expect(summaryStore.linkedMap.keys, contains('dart:core'));

    // Remove a.dart from the file system.
    deleteFile(a);

    // We don't need a.dart file when we analyze with the summary store.
    // Still no analysis errors.
    AnalysisDriver driver =
        createAnalysisDriver(externalSummaries: summaryStore);
    ResolvedUnitResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_externalSummaries_partReuse() async {
    var a = convertPath('/a.dart');
    var b = convertPath('/b.dart');
    var c = convertPath('/c.dart');
    newFile(a, content: r'''
library a;
part 'b.dart';
class A {}
''');
    newFile(b, content: r'''
part of a;
class _B {}
''');
    newFile(c, content: r'''
library a;
import 'a.dart';
part 'b.dart';
var a = new A();
var b = new _B();
''');

    // Prepare the store with a.dart and everything it needs.
    SummaryDataStore summaryStore =
        await createAnalysisDriver().test.getSummaryStore(a);

    String aUri = toUriStr(a);
    String bUri = toUriStr(b);
    // There are unlinked units for a.dart and b.dart files.
    expect(summaryStore.hasUnlinkedUnit(aUri), isTrue);
    expect(summaryStore.hasUnlinkedUnit(bUri), isTrue);
    // Only a.dart is linked, because b.dart is not a library.
    expect(summaryStore.hasLinkedLibrary(aUri), isTrue);
    expect(summaryStore.hasLinkedLibrary(bUri), isFalse);

    // Remove a.dart from the file system.
    // Keep b.dart, because we (re)use it as a part.
    deleteFile(a);

    // We don't need a.dart file when we analyze with the summary store.
    // We can instantiate the class A the library a.dart.
    // We can instantiate the class _A the part b.dart.
    AnalysisDriver driver =
        createAnalysisDriver(externalSummaries: summaryStore);
    ResolvedUnitResult result = await driver.getResult(c);
    expect(result.errors, isEmpty);
  }

  test_generatedFile() async {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = convertPath('/aaa/lib/foo.dart');
    String generatedPath = convertPath('/generated/aaa/lib/foo.dart');

    newFile(templatePath, content: r'''
a() {}
b() {}
''');

    newFile(generatedPath, content: r'''
aaa() {}
bbb() {}
''');

    Source generatedSource = new _SourceMock(generatedPath, uri);

    generatedUriResolver.resolveAbsoluteFunction =
        (uri, actualUri) => generatedSource;
    generatedUriResolver.restoreAbsoluteFunction = (Source source) {
      String path = source.fullName;
      if (path == templatePath || path == generatedPath) {
        return uri;
      } else {
        return null;
      }
    };

    driver.addFile(templatePath);

    await waitForIdleWithoutExceptions();
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    var result = await driver.getResult(templatePath);
    expect(result, isNull);
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    var element = await driver.getUnitElement(templatePath);
    expect(element, isNull);
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    driver.priorityFiles = [templatePath];
    driver.changeFile(templatePath);
    await waitForIdleWithoutExceptions();
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    expect(driver.knownFiles, isNot(contains(templatePath)));
  }

  test_getCachedResult() async {
    var a = convertPath('/test/bin/a.dart');
    newFile(a, content: 'var a = 1;');

    expect(driver.getCachedResult(a), isNull);

    driver.priorityFiles = [a];
    ResolvedUnitResult result = await driver.getResult(a);

    expect(driver.getCachedResult(a), same(result));
  }

  test_getErrors() async {
    String content = 'int f() => 42 + bar();';
    addTestFile(content, priority: true);

    ErrorsResult result = await driver.getErrors(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.errors, hasLength(1));
  }

  test_getErrors_notAbsolutePath() async {
    try {
      await driver.getErrors('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getFilesDefiningClassMemberName_class() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    var c = convertPath('/test/bin/c.dart');
    var d = convertPath('/test/bin/d.dart');

    newFile(a, content: 'class A { m1() {} }');
    newFile(b, content: 'class B { m2() {} }');
    newFile(c, content: 'class C { m2() {} }');
    newFile(d, content: 'class D { m3() {} }');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);

    expect(await driver.getFilesDefiningClassMemberName('m1'),
        unorderedEquals([a]));

    expect(await driver.getFilesDefiningClassMemberName('m2'),
        unorderedEquals([b, c]));

    expect(await driver.getFilesDefiningClassMemberName('m3'),
        unorderedEquals([d]));
  }

  test_getFilesDefiningClassMemberName_mixin() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    var c = convertPath('/test/bin/c.dart');
    var d = convertPath('/test/bin/d.dart');

    newFile(a, content: 'mixin A { m1() {} }');
    newFile(b, content: 'mixin B { m2() {} }');
    newFile(c, content: 'mixin C { m2() {} }');
    newFile(d, content: 'mixin D { m3() {} }');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);

    expect(await driver.getFilesDefiningClassMemberName('m1'),
        unorderedEquals([a]));

    expect(await driver.getFilesDefiningClassMemberName('m2'),
        unorderedEquals([b, c]));

    expect(await driver.getFilesDefiningClassMemberName('m3'),
        unorderedEquals([d]));
  }

  test_getFilesReferencingName() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    var c = convertPath('/test/bin/c.dart');
    var d = convertPath('/test/bin/d.dart');
    var e = convertPath('/test/bin/e.dart');

    newFile(a, content: 'class A {}');
    newFile(b, content: "import 'a.dart'; A a;");
    newFile(c, content: "import 'a.dart'; var a = new A();");
    newFile(d, content: "class A{} A a;");
    newFile(e, content: "import 'a.dart'; main() {}");

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);

    // 'b.dart' references an external 'A'.
    // 'c.dart' references an external 'A'.
    // 'd.dart' references the local 'A'.
    // 'e.dart' does not reference 'A' at all.
    List<String> files = await driver.getFilesReferencingName('A');
    expect(files, unorderedEquals([b, c]));

    // We get the same results second time.
    List<String> files2 = await driver.getFilesReferencingName('A');
    expect(files2, unorderedEquals([b, c]));
  }

  test_getFilesReferencingName_discover() async {
    var t = convertPath('/test/lib/test.dart');
    var a = convertPath('/aaa/lib/a.dart');
    var b = convertPath('/bbb/lib/b.dart');
    var c = convertPath('/ccc/lib/c.dart');

    newFile(t, content: 'int t;');
    newFile(a, content: 'int a;');
    newFile(b, content: 'int b;');
    newFile(c, content: 'int c;');

    driver.addFile(t);

    List<String> files = await driver.getFilesReferencingName('int');
    expect(files, contains(t));
    expect(files, contains(a));
    expect(files, contains(b));
    expect(files, isNot(contains(c)));
  }

  test_getFileSync_library() async {
    var path = convertPath('/test/lib/a.dart');
    newFile(path);
    var file = driver.getFileSync(path);
    expect(file.path, path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.isPart, isFalse);
  }

  test_getFileSync_notAbsolutePath() async {
    try {
      driver.getFileSync('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getFileSync_part() async {
    var path = convertPath('/test/lib/a.dart');
    newFile(path, content: 'part of lib;');
    var file = driver.getFileSync(path);
    expect(file.path, path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.isPart, isTrue);
  }

  test_getIndex() async {
    String content = r'''
foo(int p) {}
main() {
  foo(42);
}
''';
    addTestFile(content);

    AnalysisDriverUnitIndex index = await driver.getIndex(testFile);

    int unitId = index.strings.indexOf('package:test/test.dart');
    int fooId = index.strings.indexOf('foo');
    expect(unitId, isNonNegative);
    expect(fooId, isNonNegative);
  }

  test_getIndex_notAbsolutePath() async {
    try {
      await driver.getIndex('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getLibraryByUri() async {
    var a = '/test/lib/a.dart';
    var b = '/test/lib/b.dart';

    String aUriStr = 'package:test/a.dart';
    String bUriStr = 'package:test/b.dart';

    newFile(a, content: r'''
part 'b.dart';

class A {}
''');

    newFile(b, content: r'''
part of 'a.dart';

class B {}
''');

    var library = await driver.getLibraryByUri(aUriStr);
    expect(library.getType('A'), isNotNull);
    expect(library.getType('B'), isNotNull);

    // It is an error to ask for a library when we know that it is a part.
    expect(() async {
      await driver.getLibraryByUri(bUriStr);
    }, throwsArgumentError);
  }

  test_getLibraryByUri_external() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    String aUriStr = 'package:test/a.dart';
    String bUriStr = 'package:test/b.dart';

    newFile(a, content: r'''
part 'b.dart';

class A {}
''');

    newFile(b, content: r'''
part of 'a.dart';

class B {}
''');

    // Prepare the store with package:test/test.dart URI.
    var store = await createAnalysisDriver().test.getSummaryStore(a);

    // package:test/test.dart is in the store.
    expect(store.unlinkedMap.keys, contains(aUriStr));
    expect(store.unlinkedMap.keys, contains(bUriStr));
    expect(store.linkedMap.keys, contains(aUriStr));
    expect(store.linkedMap.keys, isNot(contains(bUriStr)));

    // Remove the files from the file system.
    deleteFile(a);
    deleteFile(b);

    // We can resynthesize the library from the store.
    var driver = createAnalysisDriver(externalSummaries: store);

    // Ask by URI, so we get the "external" FileState.
    var aUri = Uri.parse(aUriStr);
    var aFile = driver.fsState.getFileForUri(aUri);
    expect(aFile.uri, aUri);
    expect(aFile.path, isNull);

    // We still can resynthesize the library.
    // The URI is known to be external, so we don't talk to the file.
    var library = await driver.getLibraryByUri(aUriStr);
    expect(library.getType('A'), isNotNull);
    expect(library.getType('B'), isNotNull);

    // It is an error to ask for a library when we know that it is a part.
    expect(() async {
      await driver.getLibraryByUri(bUriStr);
    }, throwsArgumentError);
  }

  test_getLibraryByUri_sdk_analyze() async {
    LibraryElement coreLibrary = await driver.getLibraryByUri('dart:core');
    expect(coreLibrary, isNotNull);
    expect(coreLibrary.getType('Object'), isNotNull);
    expect(coreLibrary.getType('int'), isNotNull);
  }

  test_getLibraryByUri_sdk_resynthesize() async {
    String corePath = sdk.mapDartUri('dart:core').fullName;
    String asyncPath = sdk.mapDartUri('dart:async').fullName;
    var sdkStore = await createAnalysisDriver().test.getSummaryStore(corePath);

    // There are dart:core and dart:async in the store.
    expect(sdkStore.unlinkedMap.keys, contains('dart:core'));
    expect(sdkStore.unlinkedMap.keys, contains('dart:async'));
    expect(sdkStore.linkedMap.keys, contains('dart:core'));
    expect(sdkStore.linkedMap.keys, contains('dart:async'));

    // Remove dart:core and dart:async.
    // So, the new driver below cannot parse and summarize them.
    deleteFile(corePath);
    deleteFile(asyncPath);

    // We still get get dart:core library element.
    AnalysisDriver driver = createAnalysisDriver(externalSummaries: sdkStore);
    LibraryElement coreLibrary = await driver.getLibraryByUri('dart:core');
    expect(coreLibrary, isNotNull);
    expect(coreLibrary.getType('Object'), isNotNull);
  }

  test_getParsedLibrary_external() async {
    var a1 = convertPath('/aaa/lib/a1.dart');
    var a2 = convertPath('/aaa/lib/a2.dart');

    var a1UriStr = 'package:aaa/a1.dart';
    var a2UriStr = 'package:aaa/a2.dart';

    newFile(a1, content: "part 'a2.dart';  class A {}");
    newFile(a2, content: "part of 'a1.dart';");

    // Build the store with the library.
    var store = await createAnalysisDriver().test.getSummaryStore(a1);
    expect(store.unlinkedMap.keys, contains(a1UriStr));
    expect(store.unlinkedMap.keys, contains(a2UriStr));
    expect(store.linkedMap.keys, contains(a1UriStr));

    var driver = createAnalysisDriver(externalSummaries: store);
    var libraryElement = await driver.getLibraryByUri(a1UriStr);
    var classA = libraryElement.library.getType('A');

    var parsedLibrary = driver.getParsedLibrary(a1);
    expect(parsedLibrary, isNotNull);
    expect(parsedLibrary.state, ResultState.NOT_A_FILE);
    expect(() {
      parsedLibrary.getElementDeclaration(classA);
    }, throwsStateError);

    // It is an error to ask for a library when we know that it is a part.
    expect(() {
      driver.getParsedLibrary(a2);
    }, throwsArgumentError);
  }

  test_getParsedLibraryByUri_external() async {
    var a1 = convertPath('/aaa/lib/a1.dart');
    var a2 = convertPath('/aaa/lib/a2.dart');

    var a1UriStr = 'package:aaa/a1.dart';
    var a2UriStr = 'package:aaa/a2.dart';

    var a1Uri = Uri.parse(a1UriStr);
    var a2Uri = Uri.parse(a2UriStr);

    newFile(a1, content: "part 'a2.dart';  class A {}");
    newFile(a2, content: "part of 'a1.dart';");

    // Build the store with the library.
    var store = await createAnalysisDriver().test.getSummaryStore(a1);
    expect(store.unlinkedMap.keys, contains(a1UriStr));
    expect(store.unlinkedMap.keys, contains(a2UriStr));
    expect(store.linkedMap.keys, contains(a1UriStr));

    var driver = createAnalysisDriver(externalSummaries: store);
    var libraryElement = await driver.getLibraryByUri(a1UriStr);
    var classA = libraryElement.library.getType('A');

    {
      var parsedLibrary = driver.getParsedLibraryByUri(a1Uri);
      expect(parsedLibrary, isNotNull);
      expect(parsedLibrary.state, ResultState.NOT_A_FILE);
      expect(() {
        parsedLibrary.getElementDeclaration(classA);
      }, throwsStateError);
    }

    // We can also get the result from the session.
    {
      var session = driver.currentSession;
      var parsedLibrary = session.getParsedLibraryByElement(libraryElement);
      expect(parsedLibrary, isNotNull);
      expect(parsedLibrary.state, ResultState.NOT_A_FILE);
      expect(() {
        parsedLibrary.getElementDeclaration(classA);
      }, throwsStateError);
    }

    // It is an error to ask for a library when we know that it is a part.
    expect(() {
      driver.getParsedLibraryByUri(a2Uri);
    }, throwsArgumentError);
  }

  test_getResolvedLibrary_external() async {
    var a1 = convertPath('/aaa/lib/a1.dart');
    var a2 = convertPath('/aaa/lib/a2.dart');

    var a1UriStr = 'package:aaa/a1.dart';
    var a2UriStr = 'package:aaa/a2.dart';

    newFile(a1, content: "part 'a2.dart';  class A {}");
    newFile(a2, content: "part of 'a1.dart';");

    // Build the store with the library.
    var store = await createAnalysisDriver().test.getSummaryStore(a1);
    expect(store.unlinkedMap.keys, contains(a1UriStr));
    expect(store.unlinkedMap.keys, contains(a2UriStr));
    expect(store.linkedMap.keys, contains(a1UriStr));

    var driver = createAnalysisDriver(externalSummaries: store);
    var libraryElement = await driver.getLibraryByUri(a1UriStr);
    var classA = libraryElement.library.getType('A');

    var resolvedLibrary = await driver.getResolvedLibrary(a1);
    expect(resolvedLibrary, isNotNull);
    expect(resolvedLibrary.state, ResultState.NOT_A_FILE);
    expect(() {
      resolvedLibrary.getElementDeclaration(classA);
    }, throwsStateError);

    // It is an error to ask for a library when we know that it is a part.
    expect(() async {
      await driver.getResolvedLibrary(a2);
    }, throwsArgumentError);
  }

  test_getResolvedLibraryByUri_external() async {
    var a1 = convertPath('/aaa/lib/a1.dart');
    var a2 = convertPath('/aaa/lib/a2.dart');

    var a1UriStr = 'package:aaa/a1.dart';
    var a2UriStr = 'package:aaa/a2.dart';

    var a1Uri = Uri.parse(a1UriStr);
    var a2Uri = Uri.parse(a2UriStr);

    newFile(a1, content: "part 'a2.dart';  class A {}");
    newFile(a2, content: "part of 'a1.dart';");

    // Build the store with the library.
    var store = await createAnalysisDriver().test.getSummaryStore(a1);
    expect(store.unlinkedMap.keys, contains(a1UriStr));
    expect(store.unlinkedMap.keys, contains(a2UriStr));
    expect(store.linkedMap.keys, contains(a1UriStr));

    var driver = createAnalysisDriver(externalSummaries: store);
    var libraryElement = await driver.getLibraryByUri(a1UriStr);
    var classA = libraryElement.library.getType('A');

    {
      var resolvedLibrary = await driver.getResolvedLibraryByUri(a1Uri);
      expect(resolvedLibrary, isNotNull);
      expect(resolvedLibrary.state, ResultState.NOT_A_FILE);
      expect(() {
        resolvedLibrary.getElementDeclaration(classA);
      }, throwsStateError);
    }

    // We can also get the result from the session.
    {
      var session = driver.currentSession;
      var resolvedLibrary =
          await session.getResolvedLibraryByElement(libraryElement);
      expect(resolvedLibrary, isNotNull);
      expect(resolvedLibrary.state, ResultState.NOT_A_FILE);
      expect(() {
        resolvedLibrary.getElementDeclaration(classA);
      }, throwsStateError);
    }

    // It is an error to ask for a library when we know that it is a part.
    expect(() async {
      await driver.getResolvedLibraryByUri(a2Uri);
    }, throwsArgumentError);
  }

  test_getResult() async {
    String content = 'int f() => 42;';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.state, ResultState.VALID);
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');

    // The same result is also received through the stream.
    await waitForIdleWithoutExceptions();
    expect(allResults, [result]);
  }

  test_getResult_constants_defaultParameterValue_localFunction() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, content: 'const C = 42;');
    newFile(b, content: r'''
import 'a.dart';
main() {
  foo({int p: C}) {}
  foo();
}
''');
    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    ResolvedUnitResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_getResult_doesNotExist() async {
    var a = convertPath('/test/lib/a.dart');

    ResolvedUnitResult result = await driver.getResult(a);
    expect(result.path, a);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.state, ResultState.NOT_A_FILE);
    expect(result.content, '');
  }

  test_getResult_errors() async {
    String content = 'main() { int vv; }';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, hasLength(1));
    {
      AnalysisError error = result.errors[0];
      expect(error.offset, 13);
      expect(error.length, 2);
      expect(error.errorCode, HintCode.UNUSED_LOCAL_VARIABLE);
      expect(error.message, "The value of the local variable 'vv' isn't used.");
      expect(error.correction, "Try removing the variable, or using it.");
    }
  }

  test_getResult_functionTypeFormalParameter_withTypeParameter() async {
    // This was code crashing because of incomplete implementation.
    // Consider (re)moving after fixing dartbug.com/28515
    addTestFile(r'''
class A {
  int foo( bar<T extends B>() ) {}
}
class B {}
''');

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
  }

  test_getResult_genericFunctionType_parameter_named() async {
    String content = '''
class C {
  test({bool Function(String) p}) {}
}
''';
    addTestFile(content, priority: true);

    var result = await driver.getResult(testFile);
    expect(result.errors, isEmpty);
  }

  test_getResult_importLibrary_thenRemoveIt() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: r'''
import 'a.dart';
class B extends A {}
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // No errors in b.dart
    {
      ResolvedUnitResult result = await driver.getResult(b);
      expect(result.errors, isEmpty);
    }

    // Remove a.dart and reanalyze.
    deleteFile(a);
    driver.removeFile(a);

    // The unresolved URI error must be reported.
    {
      ResolvedUnitResult result = await driver.getResult(b);
      expect(
          result.errors,
          contains(predicate((AnalysisError e) =>
              e.errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST)));
    }

    // Restore a.dart and reanalyze.
    newFile(a, content: 'class A {}');
    driver.addFile(a);

    // No errors in b.dart again.
    {
      ResolvedUnitResult result = await driver.getResult(b);
      expect(result.errors, isEmpty);
    }
  }

  test_getResult_inferTypes_finalField() async {
    addTestFile(r'''
class C {
  final f = 42;
}
''', priority: true);
    await waitForIdleWithoutExceptions();

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(_getClassFieldType(result.unit, 'C', 'f'), 'int');
  }

  test_getResult_inferTypes_instanceMethod() async {
    addTestFile(r'''
class A {
  int m(double p) => 1;
}
class B extends A {
  m(double p) => 2;
}
''', priority: true);
    await waitForIdleWithoutExceptions();

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(_getClassMethodReturnType(result.unit, 'A', 'm'), 'int');
    expect(_getClassMethodReturnType(result.unit, 'B', 'm'), 'int');
  }

  test_getResult_invalid_annotation_functionAsConstructor() async {
    addTestFile(r'''
fff() {}

@fff()
class C {}
''', priority: true);

    ResolvedUnitResult result = await driver.getResult(testFile);
    ClassDeclaration c = result.unit.declarations[1] as ClassDeclaration;
    Annotation a = c.metadata[0];
    expect(a.name.name, 'fff');
    expect(a.name.staticElement, isFunctionElement);
  }

  test_getResult_invalidUri() async {
    String content = r'''
import ':[invalid uri]';
import '[invalid uri]:foo.dart';
import 'package:aaa/a1.dart';
import ':[invalid uri]';
import '[invalid uri]:foo.dart';

export ':[invalid uri]';
export '[invalid uri]:foo.dart';
export 'package:aaa/a2.dart';
export ':[invalid uri]';
export '[invalid uri]:foo.dart';

part ':[invalid uri]';
part 'a3.dart';
part ':[invalid uri]';
''';
    addTestFile(content);

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
  }

  test_getResult_invalidUri_exports_dart() async {
    String content = r'''
export 'dart:async';
export 'dart:noSuchLib';
export 'dart:math';
''';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    // Has only exports for valid URIs.
    List<ExportElement> imports = resolutionMap
        .elementDeclaredByCompilationUnit(result.unit)
        .library
        .exports;
    expect(imports.map((import) {
      return import.exportedLibrary?.source?.uri?.toString();
    }), ['dart:async', null, 'dart:math']);
  }

  test_getResult_invalidUri_imports_dart() async {
    String content = r'''
import 'dart:async';
import 'dart:noSuchLib';
import 'dart:math';
''';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    // Has only imports for valid URIs.
    List<ImportElement> imports = resolutionMap
        .elementDeclaredByCompilationUnit(result.unit)
        .library
        .imports;
    expect(imports.map((import) {
      return import.importedLibrary?.source?.uri?.toString();
    }), ['dart:async', null, 'dart:math', 'dart:core']);
  }

  test_getResult_invalidUri_metadata() async {
    String content = r'''
@foo
import '';

@foo
export '';

@foo
part '';
''';
    addTestFile(content);
    await driver.getResult(testFile);
  }

  test_getResult_mix_fileAndPackageUris() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    var c = convertPath('/test/lib/c.dart');
    var d = convertPath('/test/test/d.dart');
    newFile(a, content: r'''
import 'package:test/c.dart';
int x = y;
''');
    newFile(b, content: r'''
import '../lib/c.dart';
int x = y;
''');
    newFile(c, content: r'''
import '../test/d.dart';
var y = z;
''');
    newFile(d, content: r'''
String z = "string";
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);

    // Analysis of my_pkg/bin/a.dart produces no error because
    // file:///my_pkg/bin/a.dart imports package:my_pkg/c.dart, and
    // package:my_pkg/c.dart's import is erroneous, causing y's reference to z
    // to be unresolved (and therefore have type dynamic).
    {
      ResolvedUnitResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
    }

    // Analysis of my_pkg/bin/b.dart produces the error "A value of type
    // 'String' can't be assigned to a variable of type 'int'", because
    // file:///my_pkg/bin/b.dart imports file:///my_pkg/lib/c.dart, which
    // successfully imports file:///my_pkg/test/d.dart, causing y to have an
    // inferred type of String.
    {
      ResolvedUnitResult result = await driver.getResult(b);
      List<AnalysisError> errors = result.errors;
      expect(errors, hasLength(1));
      expect(errors[0].errorCode, StaticTypeWarningCode.INVALID_ASSIGNMENT);
    }
  }

  test_getResult_nameConflict_local() async {
    String content = r'''
foo([p = V]) {}
V();
var V;
''';
    addTestFile(content);
    await driver.getResult(testFile);
  }

  test_getResult_nameConflict_local_typeInference() async {
    String content = r'''
typedef F();
var F;
F _ff() => null;
var f = _ff(); // the inference must fail
main() {
  f();
}
''';
    addTestFile(content);
    await driver.getResult(testFile);
  }

  test_getResult_notAbsolutePath() async {
    try {
      await driver.getResult('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getResult_notDartFile() async {
    var path = convertPath('/test/lib/test.txt');
    newFile(path, content: 'class A {}');

    ResolvedUnitResult result = await driver.getResult(path);
    expect(result, isNotNull);
    expect(result.unit.declaredElement.types.map((e) => e.name), ['A']);
  }

  test_getResult_recursiveFlatten() async {
    String content = r'''
import 'dart:async';
class C<T> implements Future<C<T>> {}
''';
    addTestFile(content);
    // Should not throw exceptions.
    await driver.getResult(testFile);
  }

  test_getResult_sameFile_twoUris() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/test/c.dart');
    newFile(a, content: 'class A<T> {}');
    newFile(b, content: r'''
import 'a.dart';
var VB = new A<int>();
''');
    newFile(c, content: r'''
import '../lib/a.dart';
var VC = new A<double>();
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    {
      ResolvedUnitResult result = await driver.getResult(b);
      expect(_getImportSource(result.unit, 0).uri.toString(),
          'package:test/a.dart');
      expect(_getTopLevelVarType(result.unit, 'VB'), 'A<int>');
    }

    {
      ResolvedUnitResult result = await driver.getResult(c);
      expect(
        _getImportSource(result.unit, 0).uri,
        toUri('/test/lib/a.dart'),
      );
      expect(_getTopLevelVarType(result.unit, 'VC'), 'A<double>');
    }
  }

  test_getResult_selfConsistent() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    newFile(b, content: r'''
import 'a.dart';
var B1 = A1;
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    {
      ResolvedUnitResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'int');
    }

    // Update "a" so that "A1" is now "double".
    // Get result for "a".
    //
    // We get "double" for "A2", even though "A2" has the type from "b".
    // That's because we check for "a" API signature consistency, and because
    // it has changed, we invalidated the dependency cache, relinked libraries
    // and recomputed types.
    modifyFile(a, r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    {
      ResolvedUnitResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'double');
    }
  }

  test_getResult_thenRemove() async {
    addTestFile('main() {}', priority: true);

    Future<ResolvedUnitResult> resultFuture = driver.getResult(testFile);
    driver.removeFile(testFile);

    ResolvedUnitResult result = await resultFuture;
    expect(result, isNotNull);
    expect(result.path, testFile);
    expect(result.unit, isNotNull);
  }

  test_getResult_twoPendingFutures() async {
    String content = 'main() {}';
    addTestFile(content, priority: true);

    Future<ResolvedUnitResult> future1 = driver.getResult(testFile);
    Future<ResolvedUnitResult> future2 = driver.getResult(testFile);

    // Both futures complete, with the same result.
    ResolvedUnitResult result1 = await future1;
    ResolvedUnitResult result2 = await future2;
    expect(result2, same(result1));
    expect(result1.path, testFile);
    expect(result1.unit, isNotNull);
  }

  test_getSourceKind_library() async {
    var path = convertPath('/test/lib/test.dart');
    newFile(path, content: 'class A {}');
    expect(await driver.getSourceKind(path), SourceKind.LIBRARY);
  }

  test_getSourceKind_notAbsolutePath() async {
    try {
      await driver.getSourceKind('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getSourceKind_notDartFile() async {
    var path = convertPath('/test/lib/test.txt');
    newFile(path, content: 'class A {}');
    expect(await driver.getSourceKind(path), isNull);
  }

  test_getSourceKind_part() async {
    var path = convertPath('/test/lib/test.dart');
    newFile(path, content: 'part of lib; class A {}');
    expect(await driver.getSourceKind(path), SourceKind.PART);
  }

  test_getTopLevelNameDeclarations() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    var d = convertPath('/test/lib/d.dart');

    newFile(a, content: 'class A {}');
    newFile(b, content: 'export "a.dart"; class B {}');
    newFile(c, content: 'import "d.dart"; class C {}');
    newFile(d, content: 'class D {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    // Don't add d.dart, it is referenced implicitly.

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('A'), [a, b], [false, true]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('B'), [b], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('C'), [c], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('D'), [d], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('X'), [], []);
  }

  test_getTopLevelNameDeclarations_discover() async {
    var t = convertPath('/test/lib/test.dart');
    var a1 = convertPath('/aaa/lib/a1.dart');
    var a2 = convertPath('/aaa/lib/src/a2.dart');
    var b = convertPath('/bbb/lib/b.dart');
    var c = convertPath('/ccc/lib/c.dart');

    newFile(t, content: 'class T {}');
    newFile(a1, content: 'class A1 {}');
    newFile(a2, content: 'class A2 {}');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');

    driver.addFile(t);
    // Don't add a1.dart, a2.dart, or b.dart - they should be discovered.
    // And c.dart is not in .packages, so should not be discovered.

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('T'), [t], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('A1'), [a1], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('A2'), [a2], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('B'), [b], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('C'), [], []);
  }

  test_getTopLevelNameDeclarations_parts() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');

    newFile(a, content: r'''
library lib;
part 'b.dart';
part 'c.dart';
class A {}
''');
    newFile(b, content: 'part of lib; class B {}');
    newFile(c, content: 'part of lib; class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('A'), [a], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('B'), [a], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('C'), [a], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('X'), [], []);
  }

  test_getUnitElement() async {
    String content = r'''
foo(int p) {}
main() {
  foo(42);
}
''';
    addTestFile(content);

    UnitElementResult unitResult = await driver.getUnitElement(testFile);
    expect(unitResult, isNotNull);
    CompilationUnitElement unitElement = unitResult.element;
    expect(unitElement.source.fullName, testFile);
    expect(unitElement.functions.map((c) => c.name),
        unorderedEquals(['foo', 'main']));
  }

  test_getUnitElement_doesNotExist_afterResynthesized() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, content: r'''
import 'package:test/b.dart';
''');

    await driver.getResolvedLibrary(a);
    await driver.getUnitElement(b);
  }

  test_getUnitElement_notAbsolutePath() async {
    try {
      await driver.getUnitElement('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getUnitElement_notDart() async {
    var path = convertPath('/test.txt');
    newFile(path, content: 'class A {}');
    UnitElementResult unitResult = await driver.getUnitElement(path);
    expect(unitResult, isNotNull);
    expect(unitResult.element.types.map((e) => e.name), ['A']);
  }

  test_getUnitElementSignature() async {
    var a = convertPath('/test/lib/a.dart');

    newFile(a, content: 'foo() {}');

    String signature = await driver.getUnitElementSignature(a);
    expect(signature, isNotNull);

    UnitElementResult unitResult = await driver.getUnitElement(a);
    expect(unitResult.path, a);
    expect(unitResult.signature, signature);

    modifyFile(a, 'bar() {}');
    driver.changeFile(a);

    String signature2 = await driver.getUnitElementSignature(a);
    expect(signature2, isNotNull);
    expect(signature2, isNot(signature));
  }

  test_hasFilesToAnalyze() async {
    // No files yet, nothing to analyze.
    expect(driver.hasFilesToAnalyze, isFalse);

    // Add a new file, it should be analyzed.
    addTestFile('main() {}', priority: false);
    expect(driver.hasFilesToAnalyze, isTrue);

    // Wait for idle, nothing to do.
    await waitForIdleWithoutExceptions();
    expect(driver.hasFilesToAnalyze, isFalse);

    // Ask to analyze the file, so there is a file to analyze.
    Future<ResolvedUnitResult> future = driver.getResult(testFile);
    expect(driver.hasFilesToAnalyze, isTrue);

    // Once analysis is done, there is nothing to analyze.
    await future;
    expect(driver.hasFilesToAnalyze, isFalse);

    // Change a file, even if not added, it still might affect analysis.
    driver.changeFile(convertPath('/not/added.dart'));
    expect(driver.hasFilesToAnalyze, isTrue);
    await waitForIdleWithoutExceptions();
    expect(driver.hasFilesToAnalyze, isFalse);

    // Request of referenced names is not analysis of a file.
    driver.getFilesReferencingName('X');
    expect(driver.hasFilesToAnalyze, isFalse);
  }

  test_hermetic_modifyLibraryFile_resolvePart() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, content: r'''
library a;
part 'b.dart';
class C {
  int foo;
}
''');
    newFile(b, content: r'''
part of a;
var c = new C();
''');

    driver.addFile(a);
    driver.addFile(b);

    await driver.getResult(b);

    // Modify the library, but don't notify the driver.
    // The driver should use the previous library content and elements.
    newFile(a, content: r'''
library a;
part 'b.dart';
class C {
  int bar;
}
''');

    var result = await driver.getResult(b);
    var c = _getTopLevelVar(result.unit, 'c');
    var typeC = c.declaredElement.type as InterfaceType;
    // The class C has an old field 'foo', not the new 'bar'.
    expect(typeC.element.getField('foo'), isNotNull);
    expect(typeC.element.getField('bar'), isNull);
  }

  test_hermetic_overlayOnly_part() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    contentOverlay[a] = r'''
library a;
part 'b.dart';
class A {}
var b = new B();
''';
    contentOverlay[b] = 'part of a; class B {}';

    driver.addFile(a);
    driver.addFile(b);

    ResolvedUnitResult result = await driver.getResult(a);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_importOfNonLibrary_part_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');

    newFile(a, content: '''
library my.lib;

part 'b.dart';
''');
    newFile(b, content: '''
part of my.lib;

class A {}
''');
    newFile(c, content: '''
import 'b.dart';
''');

    // This ensures that `a.dart` linked library is cached.
    await driver.getResult(a);

    // Should not fail because of considering `b.dart` part as `a.dart` library.
    await driver.getResult(c);
  }

  test_instantiateToBounds_invalid() async {
    var a = convertPath('/test/lib/a.dart');
    newFile(a, content: r'''
class A<T extends B> {}
class B<T extends A<B>> {}
''');

    driver.addFile(a);
    await waitForIdleWithoutExceptions();
  }

  test_isLibraryByUri() async {
    var a1 = '/aaa/lib/a1.dart';
    var a2 = '/aaa/lib/a2.dart';
    var b1 = '/bbb/lib/b1.dart';
    var b2 = '/bbb/lib/b2.dart';

    String a1UriStr = 'package:aaa/a1.dart';
    String a2UriStr = 'package:aaa/a2.dart';
    String b1UriStr = 'package:bbb/b1.dart';
    String b2UriStr = 'package:bbb/b2.dart';

    newFile(a1, content: "part 'a2.dart';");
    newFile(a2, content: "part of 'a1.dart';");
    newFile(b1, content: "part 'b2.dart';");
    newFile(b2, content: "part of 'b1.dart';");

    // Build the store with the library.
    var store =
        await createAnalysisDriver().test.getSummaryStore(convertPath(a1));
    expect(store.unlinkedMap.keys, contains(a1UriStr));
    expect(store.unlinkedMap.keys, contains(a2UriStr));
    expect(store.linkedMap.keys, contains(a1UriStr));

    // Remove the stored files from the file system.
    deleteFile(a1);
    deleteFile(a2);

    // We can ask isLibraryByUri() for both external and local units.
    AnalysisDriver driver = createAnalysisDriver(externalSummaries: store);
    expect(driver.isLibraryByUri(Uri.parse(a1UriStr)), isTrue);
    expect(driver.isLibraryByUri(Uri.parse(a2UriStr)), isFalse);
    expect(driver.isLibraryByUri(Uri.parse(b1UriStr)), isTrue);
    expect(driver.isLibraryByUri(Uri.parse(b2UriStr)), isFalse);
  }

  test_isLibraryByUri_doesNotExist() async {
    var uri = Uri.parse('file:///test.dart');
    expect(driver.isLibraryByUri(uri), isTrue);
  }

  test_isLibraryByUri_invalidUri() async {
    var uri = Uri.parse('package:aaa');
    expect(driver.isLibraryByUri(uri), isTrue);
  }

  test_issue34619() async {
    var a = convertPath('/test/lib/a.dart');
    newFile(a, content: r'''
class C {
  final Set<String> f = new Set<String>();

  @override
  List<int> foo() {}
}
''');

    driver.addFile(a);
    await waitForIdleWithoutExceptions();

    // Update the file in a
    modifyFile(a, r'''
class C {
  final Set<String> f = a + b + c;

  @override
  List<int> foo() {}
}
''');
    driver.changeFile(a);
    await waitForIdleWithoutExceptions();
  }

  test_knownFiles() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');

    newFile(a, content: r'''
import 'b.dart';
''');
    newFile(b);
    newFile(c);

    driver.addFile(a);
    driver.addFile(c);
    await waitForIdleWithoutExceptions();

    expect(driver.knownFiles, contains(a));
    expect(driver.knownFiles, contains(b));
    expect(driver.knownFiles, contains(c));

    // Remove a.dart and analyze.
    // Both a.dart and b.dart are not known now.
    driver.removeFile(a);
    await waitForIdleWithoutExceptions();
    expect(driver.knownFiles, isNot(contains(a)));
    expect(driver.knownFiles, isNot(contains(b)));
    expect(driver.knownFiles, contains(c));
  }

  test_knownFiles_beforeAnalysis() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a);

    // 'a.dart' is added, but not processed yet.
    // So, the set of known files is empty yet.
    driver.addFile(a);
    expect(driver.knownFiles, isEmpty);

    // Remove 'a.dart'.
    // It has been no analysis yet, so 'a.dart' is not in the file state, only
    // in 'added' files. So, it disappears when removed.
    driver.removeFile(a);
    expect(driver.knownFiles, isNot(contains(a)));
    expect(driver.knownFiles, isNot(contains(b)));
  }

  test_missingDartLibrary_async() async {
    var asyncPath = sdk.mapDartUri('dart:async').fullName;
    getFile(asyncPath).delete();
    addTestFile('class C {}');

    ErrorsResult result = await driver.getErrors(testFile);
    expect(result.errors, hasLength(1));

    AnalysisError error = result.errors[0];
    expect(error.errorCode, CompileTimeErrorCode.MISSING_DART_LIBRARY);
  }

  test_missingDartLibrary_core() async {
    var corePath = sdk.mapDartUri('dart:core').fullName;
    getFile(corePath).delete();
    addTestFile('class C {}');

    ErrorsResult result = await driver.getErrors(testFile);
    expect(result.errors, hasLength(1));

    AnalysisError error = result.errors[0];
    expect(error.errorCode, CompileTimeErrorCode.MISSING_DART_LIBRARY);
  }

  test_parseFile_notAbsolutePath() async {
    try {
      await driver.parseFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_parseFile_notDart() async {
    var p = convertPath('/test/bin/a.txt');
    newFile(p, content: 'class A {}');

    ParsedUnitResult parseResult = await driver.parseFile(p);
    expect(parseResult, isNotNull);
    expect(driver.knownFiles, contains(p));
  }

  test_parseFile_shouldRefresh() async {
    var p = convertPath('/test/bin/a.dart');

    newFile(p, content: 'class A {}');
    driver.addFile(p);

    // Get the result, so force the file reading.
    await driver.getResult(p);

    // Update the file.
    newFile(p, content: 'class A2 {}');

    ParsedUnitResult parseResult = await driver.parseFile(p);
    var clazz = parseResult.unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.name, 'A2');
  }

  test_parseFileSync_notAbsolutePath() async {
    try {
      driver.parseFileSync('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_parseFileSync_notDart() {
    var p = convertPath('/test/bin/a.txt');
    newFile(p, content: 'class A {}');

    ParsedUnitResult parseResult = driver.parseFileSync(p);
    expect(parseResult, isNotNull);
    expect(driver.knownFiles, contains(p));
  }

  test_parseFileSync_shouldRefresh() async {
    var p = convertPath('/test/bin/a.dart');

    newFile(p, content: 'class A {}');
    driver.addFile(p);

    // Get the result, so force the file reading.
    await driver.getResult(p);

    // Update the file.
    newFile(p, content: 'class A2 {}');

    ParsedUnitResult parseResult = driver.parseFileSync(p);
    var clazz = parseResult.unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.name, 'A2');
  }

  test_part_getErrors_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    {
      ErrorsResult result = await driver.getErrors(a);
      expect(result.errors, isEmpty);
    }

    // c.dart does not have errors in the context of a.dart
    {
      ErrorsResult result = await driver.getErrors(c);
      expect(result.errors, isEmpty);
    }
  }

  test_part_getErrors_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // c.dart is resolve in the context of a.dart, so have no errors
    {
      ErrorsResult result = await driver.getErrors(c);
      expect(result.errors, isEmpty);
    }
  }

  test_part_getResult_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    {
      ResolvedUnitResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'c'), 'C');
    }

    // Now c.dart can be resolved without errors in the context of a.dart
    {
      ResolvedUnitResult result = await driver.getResult(c);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'a'), 'A');
      expect(_getTopLevelVarType(result.unit, 'b'), 'B');
    }
  }

  test_part_getResult_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // b.dart will be analyzed after a.dart is analyzed.
    // So, A and B references are resolved.
    ResolvedUnitResult result = await driver.getResult(c);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'a'), 'A');
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_part_getResult_changePart_invalidatesLibraryCycle() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: r'''
import 'dart:async';
part 'b.dart';
''');
    driver.addFile(a);

    // Analyze the library without the part.
    await driver.getResult(a);

    // Create the part file.
    // This should invalidate library file state (specifically the library
    // cycle), so that we can re-link the library, and get new dependencies.
    newFile(b, content: r'''
part of 'a.dart';
Future<int> f;
''');
    driver.changeFile(b);

    // This should not crash.
    var result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_part_getResult_noLibrary() async {
    var c = convertPath('/test/lib/c.dart');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    ResolvedUnitResult result = await driver.getResult(c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNotNull);
  }

  test_part_getUnitElement_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    await driver.getResult(a);

    // c.dart is resolve in the context of a.dart, knows 'A' and 'B'.
    {
      UnitElementResult result = await driver.getUnitElement(c);
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].type.name, 'A');
      expect(partUnit.topLevelVariables[1].type.name, 'B');

      var libraryUnit = partUnit.library.definingCompilationUnit;
      expect(libraryUnit.topLevelVariables[0].type.name, 'C');
    }
  }

  test_part_getUnitElement_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // c.dart is resolve in the context of a.dart, knows 'A' and 'B'.
    {
      UnitElementResult result = await driver.getUnitElement(c);
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].type.name, 'A');
      expect(partUnit.topLevelVariables[1].type.name, 'B');

      var libraryUnit = partUnit.library.definingCompilationUnit;
      expect(libraryUnit.topLevelVariables[0].type.name, 'C');
    }
  }

  test_part_getUnitElement_noLibrary() async {
    var c = convertPath('/test/lib/c.dart');
    newFile(c, content: r'''
part of a;
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // We don't know the library of c.dart, but we should get a result.
    // The types "A" and "B" are unresolved.
    {
      UnitElementResult result = await driver.getUnitElement(c);
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].name, 'a');
      expect(partUnit.topLevelVariables[0].type.name, 'dynamic');

      expect(partUnit.topLevelVariables[1].name, 'b');
      expect(partUnit.topLevelVariables[1].type.name, 'dynamic');
    }
  }

  test_part_getUnitElementSignature() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Compute the signature before analyzing the library.
    String signatureBefore = await driver.getUnitElementSignature(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    await driver.getResult(a);

    // The before and after signatures must be the same.
    String signatureAfter = await driver.getUnitElementSignature(c);
    expect(signatureBefore, signatureAfter);
  }

  test_part_results_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    {
      await waitForIdleWithoutExceptions();

      // c.dart was added after a.dart, so it is analyzed after a.dart,
      // so we know that a.dart is the library of c.dart, so no errors.
      ResolvedUnitResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isEmpty);
      expect(result.unit, isNull);
    }

    // Update a.dart so that c.dart is not a part.
    {
      modifyFile(a, '// does not use c.dart anymore');
      driver.changeFile(a);
      await waitForIdleWithoutExceptions();

      // Now c.dart does not have a library context, so A and B cannot be
      // resolved, so there are errors.
      ResolvedUnitResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isNotEmpty);
      expect(result.unit, isNull);
    }
  }

  test_part_results_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await waitForIdleWithoutExceptions();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    ResolvedUnitResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_noLibrary() async {
    var c = convertPath('/test/lib/c.dart');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    await waitForIdleWithoutExceptions();

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    ResolvedUnitResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_priority_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, content: 'class B {}');
    newFile(c, content: r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.priorityFiles = [c];
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await waitForIdleWithoutExceptions();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    ResolvedUnitResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNotNull);
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: r'''
import 'b.dart';
var A = B;
''');
    newFile(b, content: 'var B = 1;');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);

    // We have results for both "a" and "b".
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(2));
    {
      ResolvedUnitResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    {
      ResolvedUnitResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B'), 'int');
    }
    allResults.clear();

    // Remove "b" and send the change notification.
    modifyFile(b, 'var B = 1.2;');
    driver.removeFile(b);
    driver.changeFile(b);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // We don't get a result for "b".
    // But the change causes "a" to be reanalyzed.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      ResolvedUnitResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_removeFile_changeFile_notAnalyzed() async {
    addTestFile('main() {}');

    // We have a result.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    expect(allResults[0].path, testFile);
    allResults.clear();

    // Remove the file and send the change notification.
    // The change notification does nothing, because the file is explicitly
    // or implicitly analyzed.
    driver.removeFile(testFile);
    driver.changeFile(testFile);

    await waitForIdleWithoutExceptions();
    expect(allResults, isEmpty);
  }

  test_removeFile_invalidate_importers() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, content: 'class A {}');
    newFile(b, content: "import 'a.dart';  var a = new A();");

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // b.dart s clean.
    expect(allResults.singleWhere((r) => r.path == b).errors, isEmpty);
    allResults.clear();

    // Remove a.dart, now b.dart should be reanalyzed and has an error.
    deleteFile(a);
    driver.removeFile(a);
    await waitForIdleWithoutExceptions();
    expect(allResults.singleWhere((r) => r.path == b).errors, hasLength(2));
    allResults.clear();
  }

  test_removeFile_notAbsolutePath() async {
    try {
      driver.removeFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_resetUriResolution() async {
    var a = convertPath('/aaa/lib/a.dart');
    var b = convertPath('/bbb/lib/b.dart');

    newFile(a, content: '');
    newFile(b, content: r'''
import 'package:aaa/a.dart'; // ignore: unused_import
A a;
''');

    // Subscribe for errors.
    driver.addFile(b);

    // `package:aaa/a.dart` does not define class `A`.
    // So, there is an error in `b.dart`.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    expect(allResults[0].path, b);
    expect(allResults[0].errors, hasLength(1));

    // Create generated file for `package:aaa/a.dart`.
    var aUri = Uri.parse('package:aaa/a.dart');
    var aGeneratedPath = convertPath('/generated/aaa/lib/a2.dart');
    var aGeneratedFile = newFile(aGeneratedPath, content: 'class A {}');

    // Configure UriResolver to provide this generated file.
    generatedUriResolver.resolveAbsoluteFunction =
        (uri, actualUri) => aGeneratedFile.createSource(actualUri);
    generatedUriResolver.restoreAbsoluteFunction = (source) {
      String path = source.fullName;
      if (path == a || path == aGeneratedPath) {
        return aUri;
      } else {
        return null;
      }
    };

    // Reset URI resolution, and analyze.
    allResults.clear();
    driver.resetUriResolution();

    // `package:aaa/a.dart` is resolved differently now, so the new list of
    // errors for `b.dart` (the empty list) is reported.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    expect(allResults[0].path, b);
    expect(allResults[0].errors, isEmpty);
  }

  test_results_order() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    var d = convertPath('/test/lib/d.dart');
    var e = convertPath('/test/lib/e.dart');
    var f = convertPath('/test/lib/f.dart');
    newFile(a, content: r'''
import 'd.dart';
''');
    newFile(b);
    newFile(c, content: r'''
import 'd.dart';
''');
    newFile(d, content: r'''
import 'b.dart';
''');
    newFile(e, content: r'''
export 'b.dart';
''');
    newFile(f, content: r'''
import 'e.dart';
class F extends X {}
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);
    driver.addFile(f);
    await waitForIdleWithoutExceptions();

    // The file f.dart has an error or warning.
    // So, its analysis will have higher priority.
    expect(driver.fsState.getFileForPath(f).hasErrorOrWarning, isTrue);

    allResults.clear();

    // Update a.dart with changing its API signature.
    modifyFile(b, 'class A {}');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();

    List<String> analyzedPaths = allResults.map((r) => r.path).toList();

    // The changed file must be the first.
    expect(analyzedPaths[0], b);

    // Then the file that imports the changed file.
    expect(analyzedPaths[1], d);

    // Then the file that has an error (even if it is unrelated).
    expect(analyzedPaths[2], f);
  }

  test_results_order_allChangedFirst_thenImports() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    var d = convertPath('/test/lib/d.dart');
    var e = convertPath('/test/lib/e.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    newFile(c);
    newFile(d, content: "import 'a.dart';");
    newFile(e, content: "import 'b.dart';");

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);
    await waitForIdleWithoutExceptions();

    allResults.clear();

    // Change b.dart and then a.dart files.
    // So, a.dart and b.dart should be analyzed first.
    // Then d.dart and e.dart because they import a.dart and b.dart files.
    modifyFile(a, 'class A2 {}');
    modifyFile(b, 'class B2 {}');
    driver.changeFile(b);
    driver.changeFile(a);
    await waitForIdleWithoutExceptions();

    List<String> analyzedPaths = allResults.map((r) => r.path).toList();

    // The changed files must be the first.
    expect(analyzedPaths[0], a);
    expect(analyzedPaths[1], b);

    // Then the file that imports the changed file.
    expect(analyzedPaths[2], d);
    expect(analyzedPaths[3], e);
  }

  test_results_priority() async {
    String content = 'int f() => 42;';
    addTestFile(content, priority: true);

    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(1));
    ResolvedUnitResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');
  }

  test_results_priorityFirst() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');
    newFile(c, content: 'class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.priorityFiles = [b];
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(3));
    ResolvedUnitResult result = allResults[0];
    expect(result.path, b);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));
  }

  test_results_regular() async {
    String content = 'int f() => 42;';
    addTestFile(content);
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(1));
    ResolvedUnitResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, isNull);
    expect(result.unit, isNull);
    expect(result.errors, hasLength(0));
  }

  test_results_removeFile_changeFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, content: r'''
var v = 0;
''');
    driver.addFile(a);

    await waitForIdleWithoutExceptions();
    expect(allResults.singleWhere((r) => r.path == a).errors, hasLength(0));
    allResults.clear();

    newFile(a, content: r'''
var v = 0
''');
    driver.removeFile(b);
    driver.changeFile(a);
    await waitForIdleWithoutExceptions();
    expect(allResults.singleWhere((r) => r.path == a).errors, hasLength(1));
  }

  test_results_skipNotAffected() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, content: 'class A {}');
    newFile(b, content: 'class B {}');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(2));
    allResults.clear();

    // Update a.dart and notify.
    modifyFile(a, 'class A2 {}');
    driver.changeFile(a);

    // Only result for a.dart should be produced, b.dart is not affected.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
  }

  test_results_status() async {
    addTestFile('int f() => 42;');
    await waitForIdleWithoutExceptions();

    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[0].isIdle, isFalse);
    expect(allStatuses[1].isAnalyzing, isFalse);
    expect(allStatuses[1].isIdle, isTrue);
  }

  test_waitForIdle() async {
    // With no analysis to do, scheduler.waitForIdle should complete immediately.
    await waitForIdleWithoutExceptions();
    // Now schedule some analysis.
    addTestFile('int f() => 42;');
    expect(allResults, isEmpty);
    // scheduler.waitForIdle should wait for the analysis.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    // Make sure there is no more analysis pending.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
  }

  Future waitForIdleWithoutExceptions() async {
    await scheduler.waitForIdle();

    if (allExceptions.isNotEmpty) {
      var buffer = new StringBuffer();
      for (var exception in allExceptions) {
        buffer.writeln('Path: ${exception.path}');
        buffer.writeln('Exception: ${exception.exception}');
      }
      fail('Unexpected exceptions:\n$buffer');
    }
  }

  void _assertTopLevelDeclarations(
      List<TopLevelDeclarationInSource> declarations,
      List<String> expectedFiles,
      List<bool> expectedIsExported) {
    expect(expectedFiles, hasLength(expectedIsExported.length));
    for (int i = 0; i < expectedFiles.length; i++) {
      expect(declarations,
          contains(predicate((TopLevelDeclarationInSource declaration) {
        return declaration.source.fullName == expectedFiles[i] &&
            declaration.isExported == expectedIsExported[i];
      })));
    }
  }

  void _expectCircularityError(EvaluationResultImpl evaluationResult) {
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNull);
    expect(evaluationResult.errors, hasLength(1));
    expect(evaluationResult.errors[0].errorCode,
        CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT);
  }

  ClassDeclaration _getClass(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        if (declaration.name.name == name) {
          return declaration;
        }
      }
    }
    fail('Cannot find the class $name in\n$unit');
  }

  VariableDeclaration _getClassField(
      CompilationUnit unit, String className, String fieldName) {
    ClassDeclaration classDeclaration = _getClass(unit, className);
    for (ClassMember declaration in classDeclaration.members) {
      if (declaration is FieldDeclaration) {
        for (var field in declaration.fields.variables) {
          if (field.name.name == fieldName) {
            return field;
          }
        }
      }
    }
    fail('Cannot find the field $fieldName in the class $className in\n$unit');
  }

  String _getClassFieldType(
      CompilationUnit unit, String className, String fieldName) {
    return resolutionMap
        .elementDeclaredByVariableDeclaration(
            _getClassField(unit, className, fieldName))
        .type
        .toString();
  }

  MethodDeclaration _getClassMethod(
      CompilationUnit unit, String className, String methodName) {
    ClassDeclaration classDeclaration = _getClass(unit, className);
    for (ClassMember declaration in classDeclaration.members) {
      if (declaration is MethodDeclaration &&
          declaration.name.name == methodName) {
        return declaration;
      }
    }
    fail('Cannot find the method $methodName in the class $className in\n'
        '$unit');
  }

  String _getClassMethodReturnType(
      CompilationUnit unit, String className, String fieldName) {
    return resolutionMap
        .elementDeclaredByMethodDeclaration(
            _getClassMethod(unit, className, fieldName))
        .type
        .returnType
        .toString();
  }

  ImportElement _getImportElement(CompilationUnit unit, int directiveIndex) {
    var import = unit.directives[directiveIndex] as ImportDirective;
    return import.element as ImportElement;
  }

  Source _getImportSource(CompilationUnit unit, int directiveIndex) {
    return _getImportElement(unit, directiveIndex).importedLibrary.source;
  }

  VariableDeclaration _getTopLevelVar(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in declaration.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    fail('Cannot find the top-level variable $name in\n$unit');
  }

  String _getTopLevelVarType(CompilationUnit unit, String name) {
    VariableDeclaration variable = _getTopLevelVar(unit, name);
    return resolutionMap
        .elementDeclaredByVariableDeclaration(variable)
        .type
        .toString();
  }
}

@reflectiveTest
class CacheAllAnalysisDriverTest extends BaseAnalysisDriverTest {
  bool get disableChangesAndCacheAllResults => true;

  test_addFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    driver.addFile(a);
    driver.addFile(b);
  }

  test_changeFile() async {
    var path = convertPath('/test.dart');
    expect(() {
      driver.changeFile(path);
    }, throwsStateError);
  }

  test_getResult_libraryUnits() async {
    var lib = convertPath('/lib.dart');
    var part1 = convertPath('/part1.dart');
    var part2 = convertPath('/part2.dart');

    newFile(lib, content: r'''
library test;
part 'part1.dart';
part 'part2.dart';
''');
    newFile(part1, content: 'part of test; class A {}');
    newFile(part2, content: 'part of test; class B {}');

    driver.addFile(lib);
    driver.addFile(part1);
    driver.addFile(part2);

    // No analyzed libraries initially.
    expect(driver.test.numOfAnalyzedLibraries, 0);

    ResolvedUnitResult libResult = await driver.getResult(lib);
    ResolvedUnitResult partResult1 = await driver.getResult(part1);
    ResolvedUnitResult partResult2 = await driver.getResult(part2);

    // Just one library was analyzed, results for parts are cached.
    expect(driver.test.numOfAnalyzedLibraries, 1);

    expect(libResult.path, lib);
    expect(partResult1.path, part1);
    expect(partResult2.path, part2);

    expect(libResult.unit, isNotNull);
    expect(partResult1.unit, isNotNull);
    expect(partResult2.unit, isNotNull);

    // The parts uses the same resynthesized library element.
    var libLibrary = libResult.unit.declaredElement.library;
    var partLibrary1 = partResult1.unit.declaredElement.library;
    var partLibrary2 = partResult2.unit.declaredElement.library;
    expect(partLibrary1, same(libLibrary));
    expect(partLibrary2, same(libLibrary));
  }

  test_getResult_singleFile() async {
    var path = convertPath('/test.dart');
    newFile(path, content: 'main() {}');
    driver.addFile(path);

    ResolvedUnitResult result1 = await driver.getResult(path);
    expect(driver.test.numOfAnalyzedLibraries, 1);
    var unit1 = result1.unit;
    var unitElement1 = unit1.declaredElement;
    expect(result1.path, path);
    expect(unit1, isNotNull);
    expect(unitElement1, isNotNull);

    ResolvedUnitResult result2 = await driver.getResult(path);
    expect(driver.test.numOfAnalyzedLibraries, 1);
    expect(result2.path, path);
    expect(result2.unit, same(unit1));
    expect(result2.unit.declaredElement, same(unitElement1));
  }

  test_removeFile() async {
    var path = convertPath('/test.dart');
    expect(() {
      driver.removeFile(path);
    }, throwsStateError);
  }
}

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
