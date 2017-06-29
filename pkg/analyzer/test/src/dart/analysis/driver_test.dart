// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show ResolverErrorCode;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

import '../../../utils.dart';
import '../../context/mock_sdk.dart';
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
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

@reflectiveTest
class AnalysisDriverSchedulerTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();
  DartSdk sdk;
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  List<AnalysisResult> allResults = [];

  AnalysisDriver newDriver() {
    sdk = new MockSdk(resourceProvider: provider);
    AnalysisDriver driver = new AnalysisDriver(
        scheduler,
        logger,
        provider,
        byteStore,
        contentOverlay,
        null,
        new SourceFactory(
            [new DartUriResolver(sdk), new ResourceUriResolver(provider)],
            null,
            provider),
        new AnalysisOptionsImpl()..strongMode = true);
    driver.results.forEach(allResults.add);
    return driver;
  }

  void setUp() {
    sdk = new MockSdk(resourceProvider: provider);
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_priorities_allChangedFirst() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    String d = _p('/d.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, "import 'a.dart';");
    provider.newFile(c, 'class C {}');
    provider.newFile(d, "import 'c.dart';");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver2.addFile(d);

    await scheduler.waitForIdle();
    allResults.clear();

    provider.updateFile(a, 'class A2 {}');
    provider.updateFile(c, 'class C2 {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, "import 'c.dart';");
    provider.newFile(b, 'class B {}');
    provider.newFile(c, "import 'b.dart';");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);

    await scheduler.waitForIdle();
    allResults.clear();

    provider.updateFile(b, 'class B2 {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    String d = _p('/d.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, "export 'a.dart';");
    provider.newFile(c, "import 'b.dart';");
    provider.newFile(d, "import 'b.dart'; class D extends X {}");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver2.addFile(d);

    await scheduler.waitForIdle();
    allResults.clear();

    provider.updateFile(a, 'class A2 {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    AnalysisResult result = await driver2.getResult(b);
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
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

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
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

  String _p(String path) => provider.convertPath(path);
}

@reflectiveTest
class AnalysisDriverTest extends BaseAnalysisDriverTest {
  test_addedFiles() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    driver.addFile(a);
    expect(driver.addedFiles, contains(a));
    expect(driver.addedFiles, isNot(contains(b)));

    driver.removeFile(a);
    expect(driver.addedFiles, isNot(contains(a)));
    expect(driver.addedFiles, isNot(contains(b)));
  }

  test_addFile_shouldRefresh() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(
        b,
        r'''
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
    await scheduler.waitForIdle();
    assertNumberOfErrorsInB(1);

    // Update 'b' to use 'a', no more hints.
    provider.newFile(
        b,
        r'''
import 'a.dart';
main() {
  print(A);
}
''');
    driver.changeFile(b);
    await scheduler.waitForIdle();
    assertNumberOfErrorsInB(0);

    // Change 'b' content so that it has a hint.
    // Remove 'b' and add it again.
    // The file 'b' must be refreshed, and the hint must be reported.
    provider.newFile(
        b,
        r'''
import 'a.dart';
''');
    driver.removeFile(b);
    driver.addFile(b);
    await scheduler.waitForIdle();
    assertNumberOfErrorsInB(1);
  }

  test_addFile_thenRemove() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver.addFile(a);
    driver.addFile(b);

    // Now remove 'a'.
    driver.removeFile(a);

    await scheduler.waitForIdle();

    // Only 'b' has been analyzed, because 'a' was removed before we started.
    expect(allResults, hasLength(1));
    expect(allResults[0].path, b);
  }

  test_analyze_resolveDirectives() async {
    var lib = _p('/test/lib.dart');
    var part1 = _p('/test/part1.dart');
    var part2 = _p('/test/part2.dart');
    provider.newFile(
        lib,
        '''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
    provider.newFile(
        part1,
        '''
part of lib;
''');
    provider.newFile(
        part2,
        '''
part of 'lib.dart';
''');

    AnalysisResult libResult = await driver.getResult(lib);
    AnalysisResult partResult1 = await driver.getResult(part1);
    AnalysisResult partResult2 = await driver.getResult(part2);

    CompilationUnit libUnit = libResult.unit;
    CompilationUnit partUnit1 = partResult1.unit;
    CompilationUnit partUnit2 = partResult2.unit;

    CompilationUnitElement unitElement = libUnit.element;
    CompilationUnitElement partElement1 = partUnit1.element;
    CompilationUnitElement partElement2 = partUnit2.element;

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
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(
        lib,
        '''
part 'part.dart';
''');
    provider.newFile(
        part,
        '''
part of lib;
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    if (libResult.unit.element.context.analysisOptions.enableUriInPartOf) {
      expect(errors, hasLength(1));
      expect(errors[0].errorCode, ResolverErrorCode.PART_OF_UNNAMED_LIBRARY);
    } else {
      expect(errors, hasLength(1));
      expect(errors[0].errorCode,
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART);
    }
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byName() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(
        lib,
        '''
library lib;
part 'part.dart';
''');
    provider.newFile(
        part,
        '''
part of someOtherLib;
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byUri() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(
        lib,
        '''
library lib;
part 'part.dart';
''');
    provider.newFile(
        part,
        '''
part of 'other_lib.dart';
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfNonPart() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(
        lib,
        '''
library lib;
part 'part.dart';
''');
    provider.newFile(
        part,
        '''
// no part of directive
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_NON_PART);
  }

  test_cachedPriorityResults() async {
    var a = _p('/test/bin/a.dart');
    provider.newFile(a, 'var a = 1;');

    driver.priorityFiles = [a];

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result1));

    AnalysisResult result2 = await driver.getResult(a);
    expect(result2, same(result1));
  }

  test_cachedPriorityResults_flush_onAnyFileChange() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    provider.newFile(a, 'var a = 1;');
    provider.newFile(a, 'var b = 2;');

    driver.priorityFiles = [a];

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Change a file.
    // The cache is flushed.
    driver.changeFile(a);
    expect(driver.test.priorityResults, isEmpty);
    AnalysisResult result2 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result2));

    // Add a file.
    // The cache is flushed.
    driver.addFile(b);
    expect(driver.test.priorityResults, isEmpty);
    AnalysisResult result3 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result3));

    // Remove a file.
    // The cache is flushed.
    driver.removeFile(b);
    expect(driver.test.priorityResults, isEmpty);
  }

  test_cachedPriorityResults_flush_onPrioritySetChange() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    provider.newFile(a, 'var a = 1;');
    provider.newFile(b, 'var b = 2;');

    driver.priorityFiles = [a];

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Make "a" and "b" priority.
    // We still have the result for "a" cached.
    driver.priorityFiles = [a, b];
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Get the result for "b".
    AnalysisResult result2 = await driver.getResult(b);
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
    var a = _p('/test/bin/a.dart');
    provider.newFile(a, 'var a = 1;');

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, isEmpty);

    // The file is not priority, so its result is not cached.
    AnalysisResult result2 = await driver.getResult(a);
    expect(result2, isNot(same(result1)));
  }

  test_changeFile_implicitlyAnalyzed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A = B;
''');
    provider.newFile(b, 'var B = 1;');

    driver.priorityFiles = [a];
    driver.addFile(a);

    // We have a result only for "a".
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    allResults.clear();

    // Change "b" and notify.
    provider.updateFile(b, 'var B = 1.2;');
    driver.changeFile(b);

    // "b" is not an added file, so it is not scheduled for analysis.
    expect(driver.test.fileTracker.hasPendingFiles, isFalse);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // The change causes "a" to be reanalyzed.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_changeFile_notUsed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/other/b.dart');
    provider.newFile(a, '');
    provider.newFile(b, 'class B1 {}');

    driver.addFile(a);

    await scheduler.waitForIdle();
    allResults.clear();

    // Change "b" and notify.
    // Nothing depends on "b", so nothing is analyzed.
    provider.updateFile(b, 'class B2 {}');
    driver.changeFile(b);
    await scheduler.waitForIdle();
    expect(allResults, isEmpty);

    // This should not add "b" to the file state.
    expect(driver.fsState.knownFilePaths, isNot(contains(b)));
  }

  test_changeFile_selfConsistent() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var B1 = A1;
''');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    // We have results for both "a" and "b".
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'int');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'int');
    }

    // Clear the results and update "a".
    allResults.clear();
    provider.updateFile(
        a,
        r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    // We again get results for both "a" and "b".
    // The results are consistent.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'double');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'double');
    }
  }

  test_changeFile_single() async {
    addTestFile('var V = 1;', priority: true);

    // Initial analysis.
    {
      await scheduler.waitForIdle();
      expect(allResults, hasLength(1));
      AnalysisResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'int');
    }

    // Update the file, but don't notify the driver.
    allResults.clear();
    provider.updateFile(testFile, 'var V = 1.2;');

    // No new results.
    await pumpEventQueue();
    expect(allResults, isEmpty);

    // Notify the driver about the change.
    driver.changeFile(testFile);

    // The file was added, so it is scheduled for analysis.
    expect(driver.test.fileTracker.isFilePending(testFile), isTrue);

    // We get a new result.
    {
      await scheduler.waitForIdle();
      expect(allResults, hasLength(1));
      AnalysisResult result = allResults[0];
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

  test_errors_uriDoesNotExist_export() async {
    addTestFile(r'''
export 'foo.dart';
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import() async {
    addTestFile(r'''
import 'foo.dart';
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import_deferred() async {
    addTestFile(
        r'''
import 'foo.dart' deferred as foo;
main() {
  foo.loadLibrary();
}
''',
        priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_part() async {
    addTestFile(r'''
library lib;
part 'foo.dart';
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_externalSummaries() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(
        a,
        r'''
class A {}
''');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var a = new A();
''');

    // Prepare the store with a.dart and everything it needs.
    SummaryDataStore summaryStore =
        createAnalysisDriver().test.getSummaryStore(a);

    // There are at least a.dart and dart:core libraries.
    String aUri = provider.pathContext.toUri(a).toString();
    expect(summaryStore.unlinkedMap.keys, contains(aUri));
    expect(summaryStore.linkedMap.keys, contains(aUri));
    expect(summaryStore.unlinkedMap.keys, contains('dart:core'));
    expect(summaryStore.linkedMap.keys, contains('dart:core'));

    // Remove a.dart from the file system.
    provider.deleteFile(a);

    // We don't need a.dart file when we analyze with the summary store.
    // Still no analysis errors.
    AnalysisDriver driver =
        createAnalysisDriver(externalSummaries: summaryStore);
    AnalysisResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_generatedFile() async {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = _p('/aaa/lib/foo.dart');
    String generatedPath = _p('/generated/aaa/lib/foo.dart');

    provider.newFile(
        templatePath,
        r'''
a() {}
b() {}
''');

    provider.newFile(
        generatedPath,
        r'''
aaa() {}
bbb() {}
''');

    Source generatedSource = new _SourceMock();
    when(generatedSource.uri).thenReturn(uri);
    when(generatedSource.fullName).thenReturn(generatedPath);

    when(generatedUriResolver.resolveAbsolute(uri, uri))
        .thenReturn(generatedSource);
    when(generatedUriResolver.restoreAbsolute(anyObject))
        .thenInvoke((Source source) {
      String path = source.fullName;
      if (path == templatePath || path == generatedPath) {
        return uri;
      } else {
        return null;
      }
    });

    driver.addFile(templatePath);

    await scheduler.waitForIdle();
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
    await scheduler.waitForIdle();
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    expect(driver.knownFiles, isNot(contains(templatePath)));
  }

  test_getErrors() async {
    String content = 'int f() => 42 + bar();';
    addTestFile(content, priority: true);

    ErrorsResult result = await driver.getErrors(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.errors, hasLength(1));
  }

  test_getFilesDefiningClassMemberName() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/bin/c.dart');
    var d = _p('/test/bin/d.dart');

    provider.newFile(a, 'class A { m1() {} }');
    provider.newFile(b, 'class B { m2() {} }');
    provider.newFile(c, 'class C { m2() {} }');
    provider.newFile(d, 'class D { m3() {} }');

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
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/bin/c.dart');
    var d = _p('/test/bin/d.dart');
    var e = _p('/test/bin/e.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, "import 'a.dart'; A a;");
    provider.newFile(c, "import 'a.dart'; var a = new A();");
    provider.newFile(d, "class A{} A a;");
    provider.newFile(e, "import 'a.dart'; main() {}");

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

  test_getLibraryByUri_external_resynthesize() async {
    provider.newFile(
        testFile,
        r'''
class Test {}
''');

    // Prepare the store with package:test/test.dart URI.
    SummaryDataStore summaryStore =
        createAnalysisDriver().test.getSummaryStore(testFile);

    // package:test/test.dart is in the store.
    String uri = 'package:test/test.dart';
    expect(summaryStore.unlinkedMap.keys, contains(uri));
    expect(summaryStore.linkedMap.keys, contains(uri));

    // Remove the file from the file system.
    provider.deleteFile(testFile);

    // We can resynthesize the library from the store without reading the file.
    AnalysisDriver driver =
        createAnalysisDriver(externalSummaries: summaryStore);
    expect(driver.test.numOfCreatedLibraryContexts, 0);
    LibraryElement library = await driver.getLibraryByUri(uri);
    expect(library.getType('Test'), isNotNull);
  }

  test_getLibraryByUri_sdk_analyze() async {
    LibraryElement coreLibrary = await driver.getLibraryByUri('dart:core');
    expect(coreLibrary, isNotNull);
    expect(coreLibrary.getType('Object'), isNotNull);
    expect(coreLibrary.getType('int'), isNotNull);
  }

  test_getLibraryByUri_sdk_resynthesize() async {
    SummaryDataStore sdkStore;
    {
      String corePath = sdk.mapDartUri('dart:core').fullName;
      sdkStore = createAnalysisDriver().test.getSummaryStore(corePath);
    }

    // There are dart:core and dart:async in the store.
    expect(sdkStore.unlinkedMap.keys, contains('dart:core'));
    expect(sdkStore.unlinkedMap.keys, contains('dart:async'));
    expect(sdkStore.linkedMap.keys, contains('dart:core'));
    expect(sdkStore.linkedMap.keys, contains('dart:async'));

    // We don't create new library context (so, don't parse, summarize and
    // link) for dart:core. The library is resynthesized from the provided
    // external store.
    AnalysisDriver driver = createAnalysisDriver(externalSummaries: sdkStore);
    LibraryElement coreLibrary = await driver.getLibraryByUri('dart:core');
    expect(driver.test.numOfCreatedLibraryContexts, 0);
    expect(coreLibrary, isNotNull);
    expect(coreLibrary.getType('Object'), isNotNull);
  }

  test_getResult() async {
    String content = 'int f() => 42;';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.exists, isTrue);
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');

    // The same result is also received through the stream.
    await scheduler.waitForIdle();
    expect(allResults, [result]);
  }

  test_getResult_constants_defaultParameterValue_localFunction() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    provider.newFile(a, 'const C = 42;');
    provider.newFile(
        b,
        r'''
import 'a.dart';
main() {
  foo({int p: C}) {}
  foo();
}
''');
    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    AnalysisResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_getResult_doesNotExist() async {
    var a = _p('/test/lib/a.dart');

    AnalysisResult result = await driver.getResult(a);
    expect(result.path, a);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.exists, isFalse);
    expect(result.content, '');
  }

  test_getResult_errors() async {
    String content = 'main() { int vv; }';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
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

  test_getResult_fileContentOverlay_throughAnalysisContext() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');

    provider.newFile(a, 'import "b.dart";');
    provider.newFile(b, 'var v = 1;');
    contentOverlay[b] = 'var v = 2;';

    var result = await driver.getResult(a);

    // The content that was set into the overlay for "b" should be visible
    // through the AnalysisContext that was used to analyze "a".
    CompilationUnitElement unitA = result.unit.element;
    Source sourceB = unitA.library.imports[0].importedLibrary.source;
    expect(unitA.context.getContents(sourceB).data, 'var v = 2;');
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

    AnalysisResult result = await driver.getResult(testFile);
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

  test_getResult_inferTypes_finalField() async {
    addTestFile(
        r'''
class C {
  final f = 42;
}
''',
        priority: true);
    await scheduler.waitForIdle();

    AnalysisResult result = await driver.getResult(testFile);
    expect(_getClassFieldType(result.unit, 'C', 'f'), 'int');
  }

  test_getResult_inferTypes_instanceMethod() async {
    addTestFile(
        r'''
class A {
  int m(double p) => 1;
}
class B extends A {
  m(double p) => 2;
}
''',
        priority: true);
    await scheduler.waitForIdle();

    AnalysisResult result = await driver.getResult(testFile);
    expect(_getClassMethodReturnType(result.unit, 'A', 'm'), 'int');
    expect(_getClassMethodReturnType(result.unit, 'B', 'm'), 'int');
  }

  test_getResult_invalid_annotation_functionAsConstructor() async {
    addTestFile(
        r'''
fff() {}

@fff()
class C {}
''',
        priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    ClassDeclaration c = result.unit.declarations[1] as ClassDeclaration;
    Annotation a = c.metadata[0];
    expect(a.name.name, 'fff');
    expect(a.name.staticElement, new isInstanceOf<FunctionElement>());
  }

  test_getResult_invalidUri() async {
    String content = r'''
import '[invalid uri]';
import '[invalid uri]:foo.dart';
import 'package:aaa/a1.dart';
import '[invalid uri]';
import '[invalid uri]:foo.dart';

export '[invalid uri]';
export '[invalid uri]:foo.dart';
export 'package:aaa/a2.dart';
export '[invalid uri]';
export '[invalid uri]:foo.dart';

part '[invalid uri]';
part 'a3.dart';
part '[invalid uri]';
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
  }

  test_getResult_invalidUri_exports_dart() async {
    String content = r'''
export 'dart:async';
export 'dart:noSuchLib';
export 'dart:math';
''';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
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

    AnalysisResult result = await driver.getResult(testFile);
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
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/test/d.dart');
    provider.newFile(
        a,
        r'''
import 'package:test/c.dart';
int x = y;
''');
    provider.newFile(
        b,
        r'''
import '../lib/c.dart';
int x = y;
''');
    provider.newFile(
        c,
        r'''
import '../test/d.dart';
var y = z;
''');
    provider.newFile(
        d,
        r'''
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
      AnalysisResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
    }

    // Analysis of my_pkg/bin/b.dart produces the error "A value of type
    // 'String' can't be assigned to a variable of type 'int'", because
    // file:///my_pkg/bin/b.dart imports file:///my_pkg/lib/c.dart, which
    // successfully imports file:///my_pkg/test/d.dart, causing y to have an
    // inferred type of String.
    {
      AnalysisResult result = await driver.getResult(b);
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

  test_getResult_notDartFile() async {
    var path = _p('/test/lib/test.txt');
    provider.newFile(path, 'class A {}');

    AnalysisResult result = await driver.getResult(path);
    expect(result, isNotNull);
    expect(result.unit.element.types.map((e) => e.name), ['A']);
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
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/test/c.dart');
    provider.newFile(a, 'class A<T> {}');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var VB = new A<int>();
''');
    provider.newFile(
        c,
        r'''
import '../lib/a.dart';
var VC = new A<double>();
''');

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    {
      AnalysisResult result = await driver.getResult(b);
      expect(_getImportSource(result.unit, 0).uri.toString(),
          'package:test/a.dart');
      expect(_getTopLevelVarType(result.unit, 'VB'), 'A<int>');
    }

    {
      AnalysisResult result = await driver.getResult(c);
      expect(_getImportSource(result.unit, 0).uri,
          provider.pathContext.toUri(_p('/test/lib/a.dart')));
      expect(_getTopLevelVarType(result.unit, 'VC'), 'A<double>');
    }
  }

  test_getResult_selfConsistent() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var B1 = A1;
''');

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    {
      AnalysisResult result = await driver.getResult(a);
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
    provider.updateFile(
        a,
        r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    {
      AnalysisResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'double');
    }
  }

  test_getResult_thenRemove() async {
    addTestFile('main() {}', priority: true);

    Future<AnalysisResult> resultFuture = driver.getResult(testFile);
    driver.removeFile(testFile);

    AnalysisResult result = await resultFuture;
    expect(result, isNotNull);
    expect(result.path, testFile);
    expect(result.unit, isNotNull);
  }

  test_getResult_importLibrary_thenRemoveIt() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(
        b,
        r'''
import 'a.dart';
class B extends A {}
''');

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    // No errors in b.dart
    {
      AnalysisResult result = await driver.getResult(b);
      expect(result.errors, isEmpty);
    }

    // Remove a.dart and reanalyze.
    provider.deleteFile(a);
    driver.removeFile(a);

    // The unresolved URI error must be reported.
    {
      AnalysisResult result = await driver.getResult(b);
      expect(
          result.errors,
          contains(predicate((AnalysisError e) =>
              e.errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST)));
    }

    // Restore a.dart and reanalyze.
    provider.newFile(a, 'class A {}');
    driver.addFile(a);

    // No errors in b.dart again.
    {
      AnalysisResult result = await driver.getResult(b);
      expect(result.errors, isEmpty);
    }
  }

  test_getResult_twoPendingFutures() async {
    String content = 'main() {}';
    addTestFile(content, priority: true);

    Future<AnalysisResult> future1 = driver.getResult(testFile);
    Future<AnalysisResult> future2 = driver.getResult(testFile);

    // Both futures complete, with the same result.
    AnalysisResult result1 = await future1;
    AnalysisResult result2 = await future2;
    expect(result2, same(result1));
    expect(result1.path, testFile);
    expect(result1.unit, isNotNull);
  }

  test_getSourceKind_library() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'class A {}');
    expect(await driver.getSourceKind(path), SourceKind.LIBRARY);
  }

  test_getSourceKind_notDartFile() async {
    var path = _p('/test/lib/test.txt');
    provider.newFile(path, 'class A {}');
    expect(await driver.getSourceKind(path), isNull);
  }

  test_getSourceKind_part() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'part of lib; class A {}');
    expect(await driver.getSourceKind(path), SourceKind.PART);
  }

  test_getTopLevelNameDeclarations() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/lib/d.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'export "a.dart"; class B {}');
    provider.newFile(c, 'import "d.dart"; class C {}');
    provider.newFile(d, 'class D {}');

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

  test_getTopLevelNameDeclarations_parts() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');

    provider.newFile(
        a,
        r'''
library lib;
part 'b.dart';
part 'c.dart';
class A {}
''');
    provider.newFile(b, 'part of lib; class B {}');
    provider.newFile(c, 'part of lib; class C {}');

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

  test_getUnitElement_notDart() async {
    var path = _p('/test.txt');
    provider.newFile(path, 'class A {}');
    UnitElementResult unitResult = await driver.getUnitElement(path);
    expect(unitResult, isNotNull);
    expect(unitResult.element.types.map((e) => e.name), ['A']);
  }

  test_getUnitElementSignature() async {
    var a = _p('/test/lib/a.dart');

    provider.newFile(a, 'foo() {}');

    String signature = await driver.getUnitElementSignature(a);
    expect(signature, isNotNull);

    UnitElementResult unitResult = await driver.getUnitElement(a);
    expect(unitResult.path, a);
    expect(unitResult.signature, signature);

    provider.updateFile(a, 'bar() {}');
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
    await scheduler.waitForIdle();
    expect(driver.hasFilesToAnalyze, isFalse);

    // Ask to analyze the file, so there is a file to analyze.
    Future<AnalysisResult> future = driver.getResult(testFile);
    expect(driver.hasFilesToAnalyze, isTrue);

    // Once analysis is done, there is nothing to analyze.
    await future;
    expect(driver.hasFilesToAnalyze, isFalse);

    // Change a file, even if not added, it still might affect analysis.
    driver.changeFile(_p('/not/added.dart'));
    expect(driver.hasFilesToAnalyze, isTrue);
    await scheduler.waitForIdle();
    expect(driver.hasFilesToAnalyze, isFalse);

    // Request of referenced names is not analysis of a file.
    driver.getFilesReferencingName('X');
    expect(driver.hasFilesToAnalyze, isFalse);
  }

  test_hermetic_modifyLibraryFile_resolvePart() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(
        a,
        r'''
library a;
part 'b.dart';
class C {
  int foo;
}
''');
    provider.newFile(
        b,
        r'''
part of a;
var c = new C();
''');

    driver.addFile(a);
    driver.addFile(b);

    await driver.getResult(b);

    // Modify the library, but don't notify the driver.
    // The driver should use the previous library content and elements.
    provider.newFile(
        a,
        r'''
library a;
part 'b.dart';
class C {
  int bar;
}
''');

    var result = await driver.getResult(b);
    var c = _getTopLevelVar(result.unit, 'c');
    var typeC = c.element.type as InterfaceType;
    // The class C has an old field 'foo', not the new 'bar'.
    expect(typeC.element.getField('foo'), isNotNull);
    expect(typeC.element.getField('bar'), isNull);
  }

  test_hermetic_overlayOnly_part() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    contentOverlay[a] = r'''
library a;
part 'b.dart';
class A {}
var b = new B();
''';
    contentOverlay[b] = 'part of a; class B {}';

    driver.addFile(a);
    driver.addFile(b);

    AnalysisResult result = await driver.getResult(a);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_knownFiles() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');

    provider.newFile(
        a,
        r'''
import 'b.dart';
''');
    provider.newFile(b, '');
    provider.newFile(c, '');

    driver.addFile(a);
    driver.addFile(c);
    await scheduler.waitForIdle();

    expect(driver.knownFiles, contains(a));
    expect(driver.knownFiles, contains(b));
    expect(driver.knownFiles, contains(c));

    // Remove a.dart and analyze.
    // Both a.dart and b.dart are not known now.
    driver.removeFile(a);
    await scheduler.waitForIdle();
    expect(driver.knownFiles, isNot(contains(a)));
    expect(driver.knownFiles, isNot(contains(b)));
    expect(driver.knownFiles, contains(c));
  }

  test_knownFiles_beforeAnalysis() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, '');

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

  test_parseFile_notDart() async {
    var p = _p('/test/bin/a.txt');
    provider.newFile(p, 'class A {}');

    ParseResult parseResult = await driver.parseFile(p);
    expect(parseResult, isNotNull);
    expect(driver.knownFiles, contains(p));
  }

  test_parseFile_shouldRefresh() async {
    var p = _p('/test/bin/a.dart');

    provider.newFile(p, 'class A {}');
    driver.addFile(p);

    // Get the result, so force the file reading.
    await driver.getResult(p);

    // Update the file.
    provider.newFile(p, 'class A2 {}');

    ParseResult parseResult = await driver.parseFile(p);
    var clazz = parseResult.unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.name, 'A2');
  }

  test_part_getErrors_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
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
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
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
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
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
      AnalysisResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'c'), 'C');
    }

    // Now c.dart can be resolved without errors in the context of a.dart
    {
      AnalysisResult result = await driver.getResult(c);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'a'), 'A');
      expect(_getTopLevelVarType(result.unit, 'b'), 'B');
    }
  }

  test_part_getResult_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
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
    AnalysisResult result = await driver.getResult(c);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'a'), 'A');
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_part_getResult_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    AnalysisResult result = await driver.getResult(c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNotNull);
  }

  test_part_results_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
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
      await scheduler.waitForIdle();

      // c.dart was added after a.dart, so it is analyzed after a.dart,
      // so we know that a.dart is the library of c.dart, so no errors.
      AnalysisResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isEmpty);
      expect(result.unit, isNull);
    }

    // Update a.dart so that c.dart is not a part.
    {
      provider.updateFile(a, '// does not use c.dart anymore');
      driver.changeFile(a);
      await scheduler.waitForIdle();

      // Now c.dart does not have a library context, so A and B cannot be
      // resolved, so there are errors.
      AnalysisResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isNotEmpty);
      expect(result.unit, isNull);
    }
  }

  test_part_results_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await scheduler.waitForIdle();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    await scheduler.waitForIdle();

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_priority_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
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

    await scheduler.waitForIdle();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNotNull);
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A = B;
''');
    provider.newFile(b, 'var B = 1;');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);

    // We have results for both "a" and "b".
    await scheduler.waitForIdle();
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B'), 'int');
    }
    allResults.clear();

    // Remove "b" and send the change notification.
    provider.updateFile(b, 'var B = 1.2;');
    driver.removeFile(b);
    driver.changeFile(b);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // We don't get a result for "b".
    // But the change causes "a" to be reanalyzed.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_removeFile_changeFile_notAnalyzed() async {
    addTestFile('main() {}');

    // We have a result.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
    expect(allResults[0].path, testFile);
    allResults.clear();

    // Remove the file and send the change notification.
    // The change notification does nothing, because the file is explicitly
    // or implicitly analyzed.
    driver.removeFile(testFile);
    driver.changeFile(testFile);

    await scheduler.waitForIdle();
    expect(allResults, isEmpty);
  }

  test_removeFile_invalidate_importers() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, "import 'a.dart';  var a = new A();");

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    // b.dart s clean.
    expect(allResults.singleWhere((r) => r.path == b).errors, isEmpty);
    allResults.clear();

    // Remove a.dart, now b.dart should be reanalyzed and has an error.
    provider.deleteFile(a);
    driver.removeFile(a);
    await scheduler.waitForIdle();
    expect(allResults.singleWhere((r) => r.path == b).errors, hasLength(2));
    allResults.clear();
  }

  test_results_order() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/lib/d.dart');
    var e = _p('/test/lib/e.dart');
    var f = _p('/test/lib/f.dart');
    provider.newFile(
        a,
        r'''
import 'd.dart';
''');
    provider.newFile(b, '');
    provider.newFile(
        c,
        r'''
import 'd.dart';
''');
    provider.newFile(
        d,
        r'''
import 'b.dart';
''');
    provider.newFile(
        e,
        r'''
export 'b.dart';
''');
    provider.newFile(
        f,
        r'''
import 'e.dart';
class F extends X {}
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);
    driver.addFile(f);
    await scheduler.waitForIdle();

    // The file f.dart has an error or warning.
    // So, its analysis will have higher priority.
    expect(driver.fsState.getFileForPath(f).hasErrorOrWarning, isTrue);

    allResults.clear();

    // Update a.dart with changing its API signature.
    provider.updateFile(b, 'class A {}');
    driver.changeFile(b);
    await scheduler.waitForIdle();

    List<String> analyzedPaths = allResults.map((r) => r.path).toList();

    // The changed file must be the first.
    expect(analyzedPaths[0], b);

    // Then the file that imports the changed file.
    expect(analyzedPaths[1], d);

    // Then the file that has an error (even if it is unrelated).
    expect(analyzedPaths[2], f);
  }

  test_results_order_allChangedFirst_thenImports() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/lib/d.dart');
    var e = _p('/test/lib/e.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, '');
    provider.newFile(d, "import 'a.dart';");
    provider.newFile(e, "import 'b.dart';");

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);
    await scheduler.waitForIdle();

    allResults.clear();

    // Change b.dart and then a.dart files.
    // So, a.dart and b.dart should be analyzed first.
    // Then d.dart and e.dart because they import a.dart and b.dart files.
    provider.updateFile(a, 'class A2 {}');
    provider.updateFile(b, 'class B2 {}');
    driver.changeFile(b);
    driver.changeFile(a);
    await scheduler.waitForIdle();

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

    await scheduler.waitForIdle();

    expect(allResults, hasLength(1));
    AnalysisResult result = allResults.single;
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
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.priorityFiles = [b];
    await scheduler.waitForIdle();

    expect(allResults, hasLength(3));
    AnalysisResult result = allResults[0];
    expect(result.path, b);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));
  }

  test_results_regular() async {
    String content = 'int f() => 42;';
    addTestFile(content);
    await scheduler.waitForIdle();

    expect(allResults, hasLength(1));
    AnalysisResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, isNull);
    expect(result.unit, isNull);
    expect(result.errors, hasLength(0));
  }

  test_results_skipNotAffected() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');

    driver.addFile(a);
    driver.addFile(b);
    await scheduler.waitForIdle();

    expect(allResults, hasLength(2));
    allResults.clear();

    // Update a.dart and notify.
    provider.updateFile(a, 'class A2 {}');
    driver.changeFile(a);

    // Only result for a.dart should be produced, b.dart is not affected.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
  }

  test_results_status() async {
    addTestFile('int f() => 42;');
    await scheduler.waitForIdle();

    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[0].isIdle, isFalse);
    expect(allStatuses[1].isAnalyzing, isFalse);
    expect(allStatuses[1].isIdle, isTrue);
  }

  test_waitForIdle() async {
    // With no analysis to do, scheduler.waitForIdle should complete immediately.
    await scheduler.waitForIdle();
    // Now schedule some analysis.
    addTestFile('int f() => 42;');
    expect(allResults, isEmpty);
    // scheduler.waitForIdle should wait for the analysis.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
    // Make sure there is no more analysis pending.
    await scheduler.waitForIdle();
    expect(allResults, hasLength(1));
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
    return null;
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
    return null;
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
    return null;
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
    return null;
  }

  String _getTopLevelVarType(CompilationUnit unit, String name) {
    VariableDeclaration variable = _getTopLevelVar(unit, name);
    return resolutionMap
        .elementDeclaredByVariableDeclaration(variable)
        .type
        .toString();
  }

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}

@reflectiveTest
class CacheAllAnalysisDriverTest extends BaseAnalysisDriverTest {
  bool get disableChangesAndCacheAllResults => true;

  test_addFile() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    driver.addFile(a);
    driver.addFile(b);
  }

  test_changeFile() async {
    var path = _p('/test.dart');
    expect(() {
      driver.changeFile(path);
    }, throwsStateError);
  }

  test_getResult_libraryUnits() async {
    var lib = _p('/lib.dart');
    var part1 = _p('/part1.dart');
    var part2 = _p('/part2.dart');

    provider.newFile(
        lib,
        r'''
library test;
part 'part1.dart';
part 'part2.dart';
''');
    provider.newFile(part1, 'part of test; class A {}');
    provider.newFile(part2, 'part of test; class B {}');

    driver.addFile(lib);
    driver.addFile(part1);
    driver.addFile(part2);

    // No analyzed libraries initially.
    expect(driver.test.numOfAnalyzedLibraries, 0);

    AnalysisResult libResult = await driver.getResult(lib);
    AnalysisResult partResult1 = await driver.getResult(part1);
    AnalysisResult partResult2 = await driver.getResult(part2);

    // Just one library was analyzed, results for parts are cached.
    expect(driver.test.numOfAnalyzedLibraries, 1);

    expect(libResult.path, lib);
    expect(partResult1.path, part1);
    expect(partResult2.path, part2);

    expect(libResult.unit, isNotNull);
    expect(partResult1.unit, isNotNull);
    expect(partResult2.unit, isNotNull);

    // The parts uses the same resynthesized library element.
    var libLibrary = libResult.unit.element.library;
    var partLibrary1 = partResult1.unit.element.library;
    var partLibrary2 = partResult2.unit.element.library;
    expect(partLibrary1, same(libLibrary));
    expect(partLibrary2, same(libLibrary));
  }

  test_getResult_singleFile() async {
    var path = _p('/test.dart');
    provider.newFile(path, 'main() {}');
    driver.addFile(path);

    AnalysisResult result1 = await driver.getResult(path);
    expect(driver.test.numOfAnalyzedLibraries, 1);
    var unit1 = result1.unit;
    var unitElement1 = unit1.element;
    expect(result1.path, path);
    expect(unit1, isNotNull);
    expect(unitElement1, isNotNull);

    AnalysisResult result2 = await driver.getResult(path);
    expect(driver.test.numOfAnalyzedLibraries, 1);
    expect(result2.path, path);
    expect(result2.unit, same(unit1));
    expect(result2.unit.element, same(unitElement1));
  }

  test_removeFile() async {
    var path = _p('/test.dart');
    expect(() {
      driver.removeFile(path);
    }, throwsStateError);
  }

  String _p(String path) => provider.convertPath(path);
}

class _SourceMock extends TypedMock implements Source {}
