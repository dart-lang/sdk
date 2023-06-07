// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_type_matchers.dart';
import '../../../utils.dart';
import '../resolution/context_collection_resolution.dart';
import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverSchedulerTest);
    defineReflectiveTests(AnalysisDriverTest);
    defineReflectiveTests(AnalysisDriver_PubPackageTest);
    defineReflectiveTests(AnalysisDriver_BlazeWorkspaceTest);
  });
}

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future pumpEventQueue([int times = 5000]) {
  if (times == 0) return Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return Future.delayed(Duration.zero, () => pumpEventQueue(times - 1));
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
  @override
  void setUp() {
    super.setUp();
    registerLintRules();
  }

  test_getLibraryByUri_cannotResolveUri() async {
    final driver = driverFor(testFile);
    expect(
      await driver.getLibraryByUri('foo:bar'),
      isA<CannotResolveUriResult>(),
    );
  }

  test_getLibraryByUri_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    expect(
      await driver.getLibraryByUri('package:test/a.dart'),
      isA<NotLibraryButAugmentationResult>(),
    );
  }

  test_getLibraryByUri_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    expect(
      await driver.getLibraryByUri('package:test/a.dart'),
      isA<NotLibraryButPartResult>(),
    );
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

  test_getResolvedLibrary_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    expect(
      await driver.getResolvedLibrary(a.path),
      isA<NotLibraryButAugmentationResult>(),
    );
  }

  test_getResolvedLibrary_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    expect(
      await driver.getResolvedLibrary(a.path),
      isA<NotLibraryButPartResult>(),
    );
  }

  test_getResolvedLibraryByUri_cannotResolveUri() async {
    final driver = driverFor(testFile);
    final uri = Uri.parse('foo:bar');
    expect(
      await driver.getResolvedLibraryByUri(uri),
      isA<CannotResolveUriResult>(),
    );
  }

  test_getResolvedLibraryByUri_notLibrary_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'b.dart';
''');

    final driver = driverFor(a);
    final uri = Uri.parse('package:test/a.dart');
    expect(
      await driver.getResolvedLibraryByUri(uri),
      isA<NotLibraryButAugmentationResult>(),
    );
  }

  test_getResolvedLibraryByUri_notLibrary_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
''');

    final driver = driverFor(a);
    final uri = Uri.parse('package:test/a.dart');
    expect(
      await driver.getResolvedLibraryByUri(uri),
      isA<NotLibraryButPartResult>(),
    );
  }

  test_getResult_part_doesNotExist_lints() async {
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

  test_getResult_part_empty_lints() async {
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

  test_getResult_part_hasPartOfName_notThisLibrary_lints() async {
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

  test_getResult_part_hasPartOfUri_notThisLibrary_lints() async {
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
}

@reflectiveTest
class AnalysisDriverSchedulerTest with ResourceProviderMixin {
  final ByteStore byteStore = MemoryByteStore();

  final StringBuffer logBuffer = StringBuffer();
  late final PerformanceLog logger;

  late final AnalysisDriverScheduler scheduler;

  final List<AnalysisResultWithErrors> allResults = [];

  Folder get sdkRoot => newFolder('/sdk');

  AnalysisDriver newDriver() {
    var sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);
    AnalysisDriver driver = AnalysisDriver(
      scheduler: scheduler,
      logger: logger,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      sourceFactory: SourceFactory(
        [DartUriResolver(sdk), ResourceUriResolver(resourceProvider)],
      ),
      analysisOptions: AnalysisOptionsImpl(),
      packages: Packages.empty,
    );
    driver.results.listen((result) {
      if (result is AnalysisResultWithErrors) {
        allResults.add(result);
      }
    });
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
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

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
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

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
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

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

  test_priorities_getResult_beforePriority() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

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

    var result = await driver2.getResult(b) as ResolvedUnitResult;
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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');
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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);

    Monitor idleStatusMonitor = Monitor();
    List<AnalysisStatus> allStatuses = [];
    // awaiting times out.
    // ignore: unawaited_futures
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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);

    Monitor idleStatusMonitor = Monitor();
    List<AnalysisStatus> allStatuses = [];
    // awaiting times out.
    // ignore: unawaited_futures
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

@reflectiveTest
class AnalysisDriverTest extends BaseAnalysisDriverTest {
  void assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
  }

  test_addedFiles() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    driver.addFile(a);
    await driver.applyPendingFileChanges();
    expect(driver.addedFiles, contains(a));
    expect(driver.addedFiles, isNot(contains(b)));

    driver.removeFile(a);
    await driver.applyPendingFileChanges();
    expect(driver.addedFiles, isNot(contains(a)));
    expect(driver.addedFiles, isNot(contains(b)));
  }

  test_addFile_notAbsolutePath() async {
    expect(() {
      driver.addFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_addFile_shouldRefresh() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, 'class A {}');
    newFile(b, r'''
import 'a.dart';
''');

    driver.addFile(a);
    driver.addFile(b);

    void assertNumberOfErrorsInB(int n) {
      var bResult = allResults.withPath(b);
      expect(bResult.errors, hasLength(n));
      allResults.clear();
    }

    // Initial analysis, 'b' does not use 'a', so there is a hint.
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(1);

    // Update 'b' to use 'a', no more hints.
    newFile(b, r'''
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
    newFile(b, r'''
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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    driver.addFile(a);
    driver.addFile(b);

    // Now remove 'a'.
    driver.removeFile(a);

    await waitForIdleWithoutExceptions();

    // Only 'b' has been analyzed, because 'a' was removed before we started.
    expect(allResults.pathList, [b]);
  }

  test_analyze_resolveDirectives_error_missingLibraryDirective() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, '''
part 'part.dart';
''');
    newFile(part, '''
part of lib;
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResultValid(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byName() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, '''
library lib;
part 'part.dart';
''');
    newFile(part, '''
part of someOtherLib;
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResultValid(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byUri() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, '''
library lib;
part 'part.dart';
''');
    newFile(part, '''
part of 'other_lib.dart';
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResultValid(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfNonPart() async {
    var lib = convertPath('/test/lib.dart');
    var part = convertPath('/test/part.dart');
    newFile(lib, '''
library lib;
part 'part.dart';
''');
    newFile(part, '''
// no part of directive
''');

    driver.addFile(lib);

    ResolvedUnitResult libResult = await driver.getResultValid(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_NON_PART);
  }

  test_cachedPriorityResults() async {
    var a = convertPath('/test/bin/a.dart');
    newFile(a, 'var a = 1;');

    driver.priorityFiles = [a];

    ResolvedUnitResult result1 = await driver.getResultValid(a);
    expect(driver.testView!.priorityResults, containsPair(a, result1));

    await waitForIdleWithoutExceptions();
    allResults.clear();

    // Get the (cached) result, not reported to the stream.
    {
      ResolvedUnitResult result2 = await driver.getResultValid(a);
      expect(result2, same(result1));
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, reported to the stream.
    {
      var result2 = await driver.getResult(a, sendCachedToStream: true);
      expect(result2, same(result1));

      expect(allResults, hasLength(1));
      expect(allResults.single, same(result1));
    }
  }

  test_cachedPriorityResults_flush_onAnyFileChange() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, 'var a = 1;');
    newFile(a, 'var b = 2;');

    driver.priorityFiles = [a];

    ResolvedUnitResult result1 = await driver.getResultValid(a);
    expect(driver.testView!.priorityResults, containsPair(a, result1));

    // Change a file.
    // The cache is flushed.
    driver.changeFile(a);
    expect(driver.testView!.priorityResults, isEmpty);
    ResolvedUnitResult result2 = await driver.getResultValid(a);
    expect(driver.testView!.priorityResults, containsPair(a, result2));

    // Add a file.
    // The cache is flushed.
    driver.addFile(b);
    expect(driver.testView!.priorityResults, isEmpty);
    ResolvedUnitResult result3 = await driver.getResultValid(a);
    expect(driver.testView!.priorityResults, containsPair(a, result3));

    // Remove a file.
    // The cache is flushed.
    driver.removeFile(b);
    expect(driver.testView!.priorityResults, isEmpty);
  }

  test_cachedPriorityResults_flush_onPrioritySetChange() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, 'var a = 1;');
    newFile(b, 'var b = 2;');

    driver.priorityFiles = [a];

    ResolvedUnitResult result1 = await driver.getResultValid(a);
    expect(driver.testView!.priorityResults, hasLength(1));
    expect(driver.testView!.priorityResults, containsPair(a, result1));

    // Make "a" and "b" priority.
    // We still have the result for "a" cached.
    driver.priorityFiles = [a, b];
    expect(driver.testView!.priorityResults, hasLength(1));
    expect(driver.testView!.priorityResults, containsPair(a, result1));

    // Get the result for "b".
    ResolvedUnitResult result2 = await driver.getResultValid(b);
    expect(driver.testView!.priorityResults, hasLength(2));
    expect(driver.testView!.priorityResults, containsPair(a, result1));
    expect(driver.testView!.priorityResults, containsPair(b, result2));

    // Only "b" is priority.
    // The result for "a" is flushed.
    driver.priorityFiles = [b];
    expect(driver.testView!.priorityResults, hasLength(1));
    expect(driver.testView!.priorityResults, containsPair(b, result2));
  }

  test_cachedPriorityResults_notPriority() async {
    var a = convertPath('/test/bin/a.dart');
    newFile(a, 'var a = 1;');

    ResolvedUnitResult result1 = await driver.getResultValid(a);
    expect(driver.testView!.priorityResults, isEmpty);

    // The file is not priority, so its result is not cached.
    ResolvedUnitResult result2 = await driver.getResultValid(a);
    expect(result2, isNot(same(result1)));
  }

  test_cachedPriorityResults_wholeLibrary_priorityLibrary_askLibrary() async {
    final a = newFile('/test/lib/a.dart', r'''
part 'b.dart';
''').path;

    final b = newFile('/test/lib/b.dart', r'''
part of 'a.dart';
''').path;

    driver.priorityFiles = [a];

    // Ask the result for `a`, should cache for both `a` and `b`.
    final aResult1 = await driver.getResultValid(a);

    final testView = driver.testView!;
    final cache = testView.priorityResults;
    final bResult1 = cache[b];
    expect(bResult1, isNotNull);

    expect(cache, containsPair(a, aResult1));
    expect(cache, containsPair(b, bResult1));
    expect(cache.keys, containsAll([a, b]));

    await waitForIdleWithoutExceptions();
    testView.numOfAnalyzedLibraries = 0;
    allResults.clear();

    // Get the (cached) result, not reported to the stream: a
    {
      final aResult2 = await driver.getResultValid(a);
      expect(aResult2, same(aResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, not reported to the stream: b
    {
      final bResult2 = await driver.getResultValid(b);
      expect(bResult2, same(bResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Ask for resolved library.
    final libraryResult = await driver.getResolvedLibrary(a);
    libraryResult as ResolvedLibraryResult;
    expect(libraryResult.unitWithPath(a), same(aResult1));
    expect(libraryResult.unitWithPath(b), same(bResult1));

    // No new analysis, no results into the stream.
    expect(testView.numOfAnalyzedLibraries, isZero);
    expect(allResults, isEmpty);
  }

  test_cachedPriorityResults_wholeLibrary_priorityLibrary_askPart() async {
    final a = newFile('/test/lib/a.dart', r'''
part 'b.dart';
''').path;

    final b = newFile('/test/lib/b.dart', r'''
part of 'a.dart';
''').path;

    driver.priorityFiles = [a];

    // Ask the result for `b`, should cache for both `a` and `b`.
    final bResult1 = await driver.getResultValid(b);

    final testView = driver.testView!;
    final cache = testView.priorityResults;
    final aResult1 = cache[a];
    expect(bResult1, isNotNull);

    expect(cache, containsPair(a, aResult1));
    expect(cache, containsPair(b, bResult1));
    expect(cache.keys, containsAll([a, b]));

    await waitForIdleWithoutExceptions();
    testView.numOfAnalyzedLibraries = 0;
    allResults.clear();

    // Get the (cached) result, not reported to the stream: a
    {
      final aResult2 = await driver.getResultValid(a);
      expect(aResult2, same(aResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, not reported to the stream: b
    {
      final bResult2 = await driver.getResultValid(b);
      expect(bResult2, same(bResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Ask for resolved library.
    final libraryResult = await driver.getResolvedLibrary(a);
    libraryResult as ResolvedLibraryResult;
    expect(libraryResult.unitWithPath(a), same(aResult1));
    expect(libraryResult.unitWithPath(b), same(bResult1));

    // No new analysis, no results into the stream.
    expect(testView.numOfAnalyzedLibraries, isZero);
    expect(allResults, isEmpty);
  }

  test_cachedPriorityResults_wholeLibrary_priorityPart_askPart() async {
    final a = newFile('/test/lib/a.dart', r'''
part 'b.dart';
''').path;

    final b = newFile('/test/lib/b.dart', r'''
part of 'a.dart';
''').path;

    driver.priorityFiles = [b];

    // Ask the result for `b`, should cache for both `a` and `b`.
    final bResult1 = await driver.getResultValid(b);

    final testView = driver.testView!;
    final cache = testView.priorityResults;
    final aResult1 = cache[a];
    expect(bResult1, isNotNull);

    expect(cache, containsPair(a, aResult1));
    expect(cache, containsPair(b, bResult1));
    expect(cache.keys, containsAll([a, b]));

    await waitForIdleWithoutExceptions();
    testView.numOfAnalyzedLibraries = 0;
    allResults.clear();

    // Get the (cached) result, not reported to the stream: a
    {
      final aResult2 = await driver.getResultValid(a);
      expect(aResult2, same(aResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, not reported to the stream: b
    {
      final bResult2 = await driver.getResultValid(b);
      expect(bResult2, same(bResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Ask for resolved library.
    final libraryResult = await driver.getResolvedLibrary(a);
    libraryResult as ResolvedLibraryResult;
    expect(libraryResult.unitWithPath(a), same(aResult1));
    expect(libraryResult.unitWithPath(b), same(bResult1));

    // No new analysis, no results into the stream.
    expect(testView.numOfAnalyzedLibraries, isZero);
    expect(allResults, isEmpty);
  }

  test_changeFile_implicitlyAnalyzed() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, r'''
import 'b.dart';
var A = B;
''');
    newFile(b, 'var B = 1;');

    driver.priorityFiles = [a];
    driver.addFile(a);

    // We have a result only for "a".
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      ResolvedUnitResult ar = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == a);
      _assertTopLevelVarType(ar.unit, 'A', 'int');
    }
    allResults.clear();

    // Change "b" and notify.
    modifyFile(b, 'var B = 1.2;');
    driver.changeFile(b);

    // "b" is not an added file, so it is not scheduled for analysis.
    expect(driver.testView!.fileTracker.hasPendingFiles, isFalse);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // The change causes "a" to be reanalyzed.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      ResolvedUnitResult ar = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == a);
      _assertTopLevelVarType(ar.unit, 'A', 'double');
    }
  }

  test_changeFile_notAbsolutePath() async {
    expect(() {
      driver.changeFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_changeFile_notUsed() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/other/b.dart');
    newFile(a, '');
    newFile(b, 'class B1 {}');

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

  test_changeFile_potentiallyAffected_imported() async {
    newFile('/test/lib/a.dart', '');
    var b = newFile('/test/lib/b.dart', '''
import 'a.dart';
''');
    var c = newFile('/test/lib/c.dart', '''
import 'b.dart';
''');
    var d = newFile('/test/lib/d.dart', '''
import 'c.dart';
''');
    newFile('/test/lib/e.dart', '');

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
    driver.changeFile(b.path);
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
    var a = newFile('/test/lib/a.dart', '''
part of 'b.dart';
''');
    var b = newFile('/test/lib/b.dart', '''
part 'a.dart';
''');
    var c = newFile('/test/lib/c.dart', '''
import 'b.dart';
''');
    newFile('/test/lib/d.dart', '');

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
    driver.changeFile(a.path);
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
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    newFile(b, r'''
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
      ResolvedUnitResult ar = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == a);
      _assertTopLevelVarType(ar.unit, 'A1', 'int');
      _assertTopLevelVarType(ar.unit, 'A2', 'int');
    }
    {
      ResolvedUnitResult br = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == b);
      _assertTopLevelVarType(br.unit, 'B1', 'int');
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
      ResolvedUnitResult ar = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == a);
      _assertTopLevelVarType(ar.unit, 'A1', 'double');
      _assertTopLevelVarType(ar.unit, 'A2', 'double');
    }
    {
      ResolvedUnitResult br = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == b);
      _assertTopLevelVarType(br.unit, 'B1', 'double');
    }
  }

  test_changeFile_single() async {
    addTestFile('var V = 1;', priority: true);

    // Initial analysis.
    {
      await waitForIdleWithoutExceptions();
      final result = allResults.whereType<ResolvedUnitResult>().single;
      expect(result.path, testFile);
      _assertTopLevelVarType(result.unit, 'V', 'int');
    }

    // Update the file, but don't notify the driver.
    allResults.clear();
    modifyFile(testFile, 'var V = 1.2;');

    // No new results.
    await pumpEventQueue();
    expect(allResults, isEmpty);

    // Notify the driver about the change.
    driver.changeFile(testFile);
    await driver.applyPendingFileChanges();

    // We get a new result.
    {
      await waitForIdleWithoutExceptions();
      final result = allResults.whereType<ResolvedUnitResult>().single;
      expect(result.path, testFile);
      _assertTopLevelVarType(result.unit, 'V', 'double');
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
    var result = await driver.getResultValid(testFile);
    var atD = AstFinder.getClass(result.unit, 'C').metadata[0];
    var atDI = atD.elementAnnotation as ElementAnnotationImpl;
    var value = atDI.evaluationResult!.value;
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
    var result = await driver.getResultValid(testFile);
    var atD = AstFinder.getClass(result.unit, 'C').metadata[0];
    var atDI = atD.elementAnnotation as ElementAnnotationImpl;
    var value = atDI.evaluationResult!.value!;
    expect(value.type, isNotNull);
    assertType(value.type, 'D');
    expect(value.fields!.keys, ['value']);
    expect(value.getField('value')!.toIntValue(), 1);
    expect(atDI.evaluationResult!.errors, isEmpty);
  }

  test_const_annotation_withoutArgs() async {
    addTestFile('''
const x = 1;
@x class C {}
''');
    var result = await driver.getResultValid(testFile);
    Annotation at_x = AstFinder.getClass(result.unit, 'C').metadata[0];
    expect(at_x.elementAnnotation!.computeConstantValue()!.toIntValue(), 1);
  }

  test_const_circular_reference() async {
    addTestFile('''
const x = y + 1;
const y = x + 1;
''');
    var result = await driver.getResultValid(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x')
        as TopLevelVariableElementImpl;
    _expectCircularityError(x.evaluationResult!);
  }

  test_const_dependency_sameUnit() async {
    addTestFile('''
const x = y + 1;
const y = 1;
''');
    var result = await driver.getResultValid(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    var y = AstFinder.getTopLevelVariableElement(result.unit, 'y');
    expect(x.computeConstantValue()!.toIntValue(), 2);
    expect(y.computeConstantValue()!.toIntValue(), 1);
  }

  test_const_externalConstFactory() async {
    addTestFile('''
const x = const C.foo();

class C extends B {
  external const factory C.foo();
}

class B {}
''');
    var result = await driver.getResultValid(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.computeConstantValue(), isNotNull);
  }

  test_const_implicitCreation() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, r'''
class C {
  const C();
  static const C WARNING = C();
}
''');
    newFile(b, r'''
import 'a.dart';

class D {
  const D();
  static const D WARNING = D();
}

const c = C.WARNING;
const d = D.WARNING;
''');
    ResolvedUnitResult result = await driver.getResultValid(b);
    expect(result.errors, isEmpty);
  }

  test_const_implicitCreation_rewrite() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, r'''
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
    newFile(b, r'''
import 'a.dart';

main() {
  const C();
}
''');
    ResolvedUnitResult result = await driver.getResultValid(b);
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
    var result = await driver.getResultValid(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.computeConstantValue(), isNotNull);
  }

  test_const_simple_topLevelVariable() async {
    addTestFile('''
const x = 1;
''');
    var result = await driver.getResultValid(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.computeConstantValue()!.toIntValue(), 1);
  }

  test_currentSession() async {
    var a = convertPath('/test/lib/a.dart');

    newFile(a, 'var V = 1;');
    await driver.getResultValid(a);

    var session1 = driver.currentSession;
    expect(session1, isNotNull);

    modifyFile(a, 'var V = 2;');
    driver.changeFile(a);
    await driver.getResultValid(a);

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

    newFile(t, 'class T {}');
    newFile(a1, 'class A1 {}');
    newFile(a2, 'class A2 {}');
    newFile(a3, 'text');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');

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
      var file = sdk.mapDartUri(uri)!.fullName;
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

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import() async {
    addTestFile(r'''
import 'foo.dart';
''');

    ResolvedUnitResult result = await driver.getResultValid(testFile);
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

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_part() async {
    addTestFile(r'''
library lib;
part 'foo.dart';
''');

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_generatedFile2() async {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = convertPath('/aaa/lib/foo.dart');
    String generatedPath = convertPath('/generated/aaa/lib/foo.dart');

    newFile(templatePath, r'''
a() {}
b() {}
''');

    newFile(generatedPath, r'''
aaa() {}
bbb() {}
''');

    Source generatedSource = _SourceMock(generatedPath, uri);

    generatedUriResolver.resolveAbsoluteFunction = (uri) => generatedSource;
    generatedUriResolver.pathToUriFunction = (path) {
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

    {
      var result = await driver.getResolvedLibrary(templatePath);
      expect(result, isA<NotPathOfUriResult>());
      expect(allExceptions, isEmpty);
      expect(allResults, isEmpty);
    }

    {
      var result = await driver.getResult(templatePath);
      expect(result, isA<NotPathOfUriResult>());
      expect(allExceptions, isEmpty);
      expect(allResults, isEmpty);
    }

    {
      var result = await driver.getUnitElement(templatePath);
      expect(result, isA<NotPathOfUriResult>());
      expect(allExceptions, isEmpty);
      expect(allResults, isEmpty);
    }

    driver.priorityFiles = [templatePath];
    driver.changeFile(templatePath);
    await waitForIdleWithoutExceptions();
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    expect(driver.knownFiles, isNot(contains(templatePath)));
  }

  test_getCachedResult() async {
    var a = convertPath('/test/bin/a.dart');
    newFile(a, 'var a = 1;');

    expect(driver.getCachedResult(a), isNull);

    driver.priorityFiles = [a];
    ResolvedUnitResult result = await driver.getResultValid(a);

    expect(driver.getCachedResult(a), same(result));
  }

  test_getErrors() async {
    String content = 'int f() => 42 + bar();';
    addTestFile(content, priority: true);

    var result = await driver.getErrors(testFile) as ErrorsResult;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.errors, hasLength(1));
  }

  test_getErrors_notAbsolutePath() async {
    var result = await driver.getErrors('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getFilesDefiningClassMemberName_class() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    var c = convertPath('/test/bin/c.dart');
    var d = convertPath('/test/bin/d.dart');

    newFile(a, 'class A { m1() {} }');
    newFile(b, 'class B { m2() {} }');
    newFile(c, 'class C { m2() {} }');
    newFile(d, 'class D { m3() {} }');

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

    newFile(a, 'mixin A { m1() {} }');
    newFile(b, 'mixin B { m2() {} }');
    newFile(c, 'mixin C { m2() {} }');
    newFile(d, 'mixin D { m3() {} }');

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

    newFile(a, 'class A {}');
    newFile(b, "import 'a.dart'; A a;");
    newFile(c, "import 'a.dart'; var a = new A();");
    newFile(d, "class A{} A a;");
    newFile(e, "import 'a.dart'; main() {}");

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

    newFile(t, 'int t;');
    newFile(a, 'int a;');
    newFile(b, 'int b;');
    newFile(c, 'int c;');

    driver.addFile(t);

    List<String> files = await driver.getFilesReferencingName('int');
    expect(files, contains(t));
    expect(files, contains(a));
    expect(files, contains(b));
    expect(files, isNot(contains(c)));
  }

  test_getFileSync_changedFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, '');
    newFile(b, r'''
import 'a.dart';

void f(A a) {}
''');

    // Ensure that [a.dart] library cycle is loaded.
    // So, `a.dart` is in the library context.
    await driver.getResultValid(a);

    // Update the file, changing its API signature.
    // Note that we don't call `changeFile`.
    newFile(a, 'class A {}\n');

    // Get the file.
    // We have not called `changeFile(a)`, so we should not read the file.
    // Moreover, doing this will create a new library cycle [a.dart].
    // Library cycles are compared by their identity, so we would try to
    // reload linked summary for [a.dart], and crash.
    expect(driver.getFileSyncValid(a).lineInfo.lineCount, 1);

    // We have not read `a.dart`, so `A` is still not declared.
    expect((await driver.getResultValid(b)).errors, isNotEmpty);

    // Notify the driver that the file was changed.
    driver.changeFile(a);

    // ...and apply this change.
    await driver.applyPendingFileChanges();

    // So, `class A {}` is declared now.
    expect(driver.getFileSyncValid(a).lineInfo.lineCount, 2);
    expect((await driver.getResultValid(b)).errors, isEmpty);
  }

  test_getFileSync_library() async {
    var path = convertPath('/test/lib/a.dart');
    newFile(path, '');
    var file = driver.getFileSyncValid(path);
    expect(file.path, path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.isPart, isFalse);
  }

  test_getFileSync_notAbsolutePath() async {
    var result = driver.getFileSync('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getFileSync_part() async {
    var path = convertPath('/test/lib/a.dart');
    newFile(path, 'part of lib;');
    var file = driver.getFileSyncValid(path);
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

    AnalysisDriverUnitIndex index = (await driver.getIndex(testFile))!;

    int unitId = index.strings.indexOf('package:test/test.dart');
    int fooId = index.strings.indexOf('foo');
    expect(unitId, isNonNegative);
    expect(fooId, isNonNegative);
  }

  test_getIndex_notAbsolutePath() async {
    expect(() async {
      await driver.getIndex('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_getLibraryByUri() async {
    var a = '/test/lib/a.dart';
    var b = '/test/lib/b.dart';

    String aUriStr = 'package:test/a.dart';
    String bUriStr = 'package:test/b.dart';

    newFile(a, r'''
part 'b.dart';

class A {}
''');

    newFile(b, r'''
part of 'a.dart';

class B {}
''');

    var result = await driver.getLibraryByUri(aUriStr);
    result as LibraryElementResult;
    expect(result.element.getClass('A'), isNotNull);
    expect(result.element.getClass('B'), isNotNull);

    // It is an error to ask for a library when we know that it is a part.
    expect(
      await driver.getLibraryByUri(bUriStr),
      isA<NotLibraryButPartResult>(),
    );
  }

  test_getLibraryByUri_unresolvedUri() async {
    var result = await driver.getLibraryByUri('package:foo/foo.dart');
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getParsedLibrary() async {
    var content = 'class A {}';
    addTestFile(content);
    var result = driver.getParsedLibrary(testFile);
    result as ParsedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].path, testFile);
    expect(result.units[0].content, content);
    expect(result.units[0].unit, isNotNull);
    expect(result.units[0].errors, isEmpty);
  }

  test_getParsedLibrary_invalidPath_notAbsolute() async {
    var result = driver.getParsedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getParsedLibrary_notLibraryButPart() async {
    addTestFile('part of my;');
    var result = driver.getParsedLibrary(testFile);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getParsedLibraryByUri() async {
    var content = 'class A {}';
    addTestFile(content);

    var uri = Uri.parse('package:test/test.dart');
    var result = driver.getParsedLibraryByUri(uri);
    result as ParsedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].uri, uri);
    expect(result.units[0].path, testFile);
    expect(result.units[0].content, content);
  }

  test_getParsedLibraryByUri_notLibrary() async {
    addTestFile('part of my;');

    var uri = Uri.parse('package:test/test.dart');
    var result = driver.getParsedLibraryByUri(uri);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getParsedLibraryByUri_unresolvedUri() async {
    var uri = Uri.parse('package:unknown/a.dart');
    var result = driver.getParsedLibraryByUri(uri);
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getResolvedLibrary() async {
    var content = 'class A {}';
    addTestFile(content);
    var result = await driver.getResolvedLibrary(testFile);
    result as ResolvedLibraryResult;
    expect(result.units, hasLength(1));
    expect(result.units[0].path, testFile);
    expect(result.units[0].content, content);
    expect(result.units[0].unit, isNotNull);
    expect(result.units[0].errors, isEmpty);
  }

  test_getResolvedLibrary_cachePriority() async {
    final a = newFile('/test/lib/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('/test/lib/b.dart', r'''
part of 'a.dart';
''');

    driver.priorityFiles = [a.path];

    final result1 = await driver.getResolvedLibrary(a.path);
    result1 as ResolvedLibraryResult;

    final testView = driver.testView!;

    // Resolving the library caches individual unit results.
    final cache = testView.priorityResults;
    expect(cache.keys, containsAll([a.path, b.path]));
    final aResult1 = cache[a.path] as ResolvedUnitResult;
    final bResult1 = cache[b.path] as ResolvedUnitResult;

    await waitForIdleWithoutExceptions();
    testView.numOfAnalyzedLibraries = 0;
    allResults.clear();

    // Ask again, the same cache instance should be returned.
    final result2 = await driver.getResolvedLibrary(a.path);
    expect(result2, same(result1));

    // No new analysis, no results into the stream.
    expect(testView.numOfAnalyzedLibraries, isZero);
    expect(allResults, isEmpty);

    // Get the (cached) result, not reported to the stream: a
    {
      final aResult2 = await driver.getResultValid(a.path);
      expect(aResult2, same(aResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, not reported to the stream: b
    {
      final bResult2 = await driver.getResultValid(b.path);
      expect(bResult2, same(bResult1));
      expect(testView.numOfAnalyzedLibraries, isZero);
      expect(allResults, isEmpty);
    }
  }

  test_getResolvedLibrary_invalidPath_notAbsolute() async {
    var result = await driver.getResolvedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary_notLibraryButPart() async {
    addTestFile('part of my;');
    var result = await driver.getResolvedLibrary(testFile);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getResolvedLibraryByUri() async {
    var content = 'class A {}';
    addTestFile(content);

    var uri = Uri.parse('package:test/test.dart');
    var result = await driver.getResolvedLibraryByUri(uri);
    result as ResolvedLibraryResult;
    expect(result.element.source.fullName, testFile);
    expect(result.units, hasLength(1));
    expect(result.units[0].uri, uri);
    expect(result.units[0].path, testFile);
    expect(result.units[0].content, content);
  }

  test_getResolvedLibraryByUri_notLibrary() async {
    addTestFile('part of my;');

    var uri = Uri.parse('package:test/test.dart');
    var result = await driver.getResolvedLibraryByUri(uri);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getResolvedLibraryByUri_unresolvedUri() async {
    var uri = Uri.parse('package:unknown/a.dart');
    var result = await driver.getResolvedLibraryByUri(uri);
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getResult() async {
    String content = 'int f() => 42;';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    assertType(f.declaredElement!.type, 'int Function()');
    assertType(f.returnType!.typeOrThrow, 'int');

    // The same result is also received through the stream.
    await waitForIdleWithoutExceptions();
    expect(allResults.toList(), [result]);
  }

  test_getResult_constants_defaultParameterValue_localFunction() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    newFile(a, 'const C = 42;');
    newFile(b, r'''
import 'a.dart';
main() {
  foo({int p = C}) {}
  foo();
}
''');
    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    ResolvedUnitResult result = await driver.getResultValid(b);
    expect(result.errors, isEmpty);
  }

  test_getResult_dartAsyncPart() async {
    var path = convertPath('/sdk/lib/async/stream.dart');
    var result = await driver.getResultValid(path);
    expect(result.path, path);
    expect(result.unit, isNotNull);
  }

  test_getResult_doesNotExist() async {
    var a = convertPath('/test/lib/a.dart');

    ResolvedUnitResult result = await driver.getResultValid(a);
    expect(result.path, a);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.exists, isFalse);
    expect(result.content, '');
  }

  test_getResult_errors() async {
    String content = 'main() { int vv; }';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    expect(result.path, testFile);
    expect(result.errors, hasLength(1));
    {
      AnalysisError error = result.errors[0];
      expect(error.offset, 13);
      expect(error.length, 2);
      expect(error.errorCode, HintCode.UNUSED_LOCAL_VARIABLE);
      expect(error.message, "The value of the local variable 'vv' isn't used.");
      expect(error.correction, "Try removing the variable or using it.");
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

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    expect(result.path, testFile);
  }

  test_getResult_genericFunctionType_parameter_named() async {
    String content = '''
class C {
  test({bool Function(String) p}) {}
}
''';
    addTestFile(content, priority: true);

    var result = await driver.getResultValid(testFile);
    expect(result.errors, isEmpty);
  }

  test_getResult_importLibrary_thenRemoveIt() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, 'class A {}');
    newFile(b, r'''
import 'a.dart';
class B extends A {}
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // No errors in b.dart
    {
      ResolvedUnitResult result = await driver.getResultValid(b);
      expect(result.errors, isEmpty);
    }

    // Remove a.dart and reanalyze.
    deleteFile(a);
    driver.removeFile(a);

    // The unresolved URI error must be reported.
    {
      ResolvedUnitResult result = await driver.getResultValid(b);
      expect(
          result.errors,
          contains(predicate((AnalysisError e) =>
              e.errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST)));
    }

    // Restore a.dart and reanalyze.
    newFile(a, 'class A {}');
    driver.addFile(a);

    // No errors in b.dart again.
    {
      ResolvedUnitResult result = await driver.getResultValid(b);
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

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    _assertClassFieldType(result.unit, 'C', 'f', 'int');
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

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    _assertClassMethodReturnType(result.unit, 'A', 'm', 'int');
    _assertClassMethodReturnType(result.unit, 'B', 'm', 'int');
  }

  test_getResult_invalid_annotation_functionAsConstructor() async {
    addTestFile(r'''
fff() {}

@fff()
class C {}
''', priority: true);

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    ClassDeclaration c = result.unit.declarations[1] as ClassDeclaration;
    Annotation a = c.metadata[0];
    expect(a.name.name, 'fff');
    expect(a.name.staticElement, isFunctionElement);
  }

  test_getResult_invalidPath_notAbsolute() async {
    var result = await driver.getResult('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
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

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    expect(result.path, testFile);
  }

  test_getResult_invalidUri_exports_dart() async {
    String content = r'''
export 'dart:async';
export 'dart:noSuchLib';
export 'dart:math';
''';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    expect(result.path, testFile);
    // Has only exports for valid URIs.
    final exports = result.libraryElement.libraryExports;
    expect(exports.map((import) {
      return import.exportedLibrary?.source.uri.toString();
    }), ['dart:async', null, 'dart:math']);
  }

  test_getResult_invalidUri_imports_dart() async {
    String content = r'''
import 'dart:async';
import 'dart:noSuchLib';
import 'dart:math';
''';
    addTestFile(content, priority: true);

    ResolvedUnitResult result = await driver.getResultValid(testFile);
    expect(result.path, testFile);
    // Has only imports for valid URIs.
    final imports = result.libraryElement.libraryImports;
    expect(imports.map((import) {
      return import.importedLibrary?.source.uri.toString();
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
    await driver.getResultValid(testFile);
  }

  test_getResult_languageVersion() async {
    var path = convertPath('/test/lib/test.dart');
    newFile(path, r'''
// @dart = 2.7
class A{}
''');

    var result = await driver.getResultValid(path);
    var languageVersion = result.unit.languageVersionToken!;
    expect(languageVersion.major, 2);
    expect(languageVersion.minor, 7);
  }

  test_getResult_mix_fileAndPackageUris() async {
    var a = convertPath('/test/bin/a.dart');
    var b = convertPath('/test/bin/b.dart');
    var c = convertPath('/test/lib/c.dart');
    var d = convertPath('/test/test/d.dart');
    newFile(a, r'''
import 'package:test/c.dart';
int x = y;
''');
    newFile(b, r'''
import '../lib/c.dart';
int x = y;
''');
    newFile(c, r'''
import '../test/d.dart';
var y = z;
''');
    newFile(d, r'''
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
      ResolvedUnitResult result = await driver.getResultValid(a);
      expect(result.errors, isEmpty);
    }

    // Analysis of my_pkg/bin/a.dart produces no error because
    // the import `../lib/c.dart` is resolved to package:my_pkg/c.dart, and
    // package:my_pkg/c.dart's import is erroneous, causing y's reference to z
    // to be unresolved (and therefore have type dynamic).
    {
      ResolvedUnitResult result = await driver.getResultValid(b);
      expect(result.errors, isEmpty);
    }
  }

  test_getResult_nameConflict_local() async {
    String content = r'''
foo([p = V]) {}
V();
var V;
''';
    addTestFile(content);
    await driver.getResultValid(testFile);
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
    await driver.getResultValid(testFile);
  }

  test_getResult_notDartFile() async {
    var path = convertPath('/test/lib/test.txt');
    newFile(path, 'class A {}');

    ResolvedUnitResult result = await driver.getResultValid(path);
    expect(result, isNotNull);
    expect(result.unit.declaredElement!.classes.map((e) => e.name), ['A']);
  }

  test_getResult_recursiveFlatten() async {
    String content = r'''
import 'dart:async';
class C<T> implements Future<C<T>> {}
''';
    addTestFile(content);
    // Should not throw exceptions.
    await driver.getResultValid(testFile);
  }

  test_getResult_sameFile_twoUris() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/test/c.dart');
    newFile(a, 'class A<T> {}');
    newFile(b, r'''
import 'a.dart';
var VB = new A<int>();
''');
    newFile(c, r'''
import '../lib/a.dart';
var VC = new A<double>();
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    {
      ResolvedUnitResult result = await driver.getResultValid(b);
      expect(
        _getImportSource(result.unit, 0).uri,
        Uri.parse('package:test/a.dart'),
      );
      _assertTopLevelVarType(result.unit, 'VB', 'A<int>');
    }

    {
      ResolvedUnitResult result = await driver.getResultValid(c);
      expect(
        _getImportSource(result.unit, 0).uri,
        Uri.parse('package:test/a.dart'),
      );
      _assertTopLevelVarType(result.unit, 'VC', 'A<double>');
    }
  }

  test_getResult_selfConsistent() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    newFile(b, r'''
import 'a.dart';
var B1 = A1;
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    {
      ResolvedUnitResult result = await driver.getResultValid(a);
      _assertTopLevelVarType(result.unit, 'A1', 'int');
      _assertTopLevelVarType(result.unit, 'A2', 'int');
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
      ResolvedUnitResult result = await driver.getResultValid(a);
      _assertTopLevelVarType(result.unit, 'A1', 'double');
      _assertTopLevelVarType(result.unit, 'A2', 'double');
    }
  }

  test_getResult_thenRemove() async {
    addTestFile('main() {}', priority: true);

    var resultFuture = driver.getResultValid(testFile);
    driver.removeFile(testFile);

    var result = await resultFuture;
    expect(result.path, testFile);
    expect(result.unit, isNotNull);
  }

  test_getResult_twoPendingFutures() async {
    String content = 'main() {}';
    addTestFile(content, priority: true);

    var future1 = driver.getResultValid(testFile);
    var future2 = driver.getResultValid(testFile);

    // Both futures complete, with the same result.
    ResolvedUnitResult result1 = await future1;
    ResolvedUnitResult result2 = await future2;
    expect(result2, same(result1));
    expect(result1.path, testFile);
    expect(result1.unit, isNotNull);
  }

  test_getUnitElement() async {
    String content = r'''
foo(int p) {}
main() {
  foo(42);
}
''';
    addTestFile(content);

    var unitResult = await driver.getUnitElement(testFile);
    unitResult as UnitElementResult;
    CompilationUnitElement unitElement = unitResult.element;
    expect(unitElement.source.fullName, testFile);
    expect(unitElement.functions.map((c) => c.name),
        unorderedEquals(['foo', 'main']));
  }

  test_getUnitElement_doesNotExist_afterResynthesized() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, r'''
import 'package:test/b.dart';
''');

    await driver.getResolvedLibrary(a);
    await driver.getUnitElement(b);
  }

  test_getUnitElement_invalidPath_notAbsolute() async {
    var result = await driver.getUnitElement('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getUnitElement_notDart() async {
    var path = convertPath('/test.txt');
    newFile(path, 'class A {}');
    var unitResult = await driver.getUnitElement(path);
    unitResult as UnitElementResult;
    expect(unitResult.element.classes.map((e) => e.name), ['A']);
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
    var future = driver.getResultValid(testFile);
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
    await driver.getFilesReferencingName('X');
    expect(driver.hasFilesToAnalyze, isFalse);
  }

  test_hermetic_modifyLibraryFile_resolvePart() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, r'''
library a;
part 'b.dart';
class C {
  int foo;
}
''');
    newFile(b, r'''
part of a;
var c = new C();
''');

    driver.addFile(a);
    driver.addFile(b);

    await driver.getResultValid(b);

    // Modify the library, but don't notify the driver.
    // The driver should use the previous library content and elements.
    newFile(a, r'''
library a;
part 'b.dart';
class C {
  int bar;
}
''');

    var result = await driver.getResultValid(b);
    var c = _getTopLevelVar(result.unit, 'c');
    var typeC = c.declaredElement!.type as InterfaceType;
    // The class C has an old field 'foo', not the new 'bar'.
    expect(typeC.element.getField('foo'), isNotNull);
    expect(typeC.element.getField('bar'), isNull);
  }

  test_importOfNonLibrary_part_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');

    newFile(a, '''
library my.lib;

part 'b.dart';
''');
    newFile(b, '''
part of my.lib;

class A {}
''');
    newFile(c, '''
import 'b.dart';
''');

    // This ensures that `a.dart` linked library is cached.
    await driver.getResultValid(a);

    // Should not fail because of considering `b.dart` part as `a.dart` library.
    await driver.getResultValid(c);
  }

  test_instantiateToBounds_invalid() async {
    var a = convertPath('/test/lib/a.dart');
    newFile(a, r'''
class A<T extends B> {}
class B<T extends A<B>> {}
''');

    driver.addFile(a);
    await waitForIdleWithoutExceptions();
  }

  test_issue34619() async {
    var a = convertPath('/test/lib/a.dart');
    newFile(a, r'''
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

    newFile(a, r'''
import 'b.dart';
''');
    newFile(b, '');
    newFile(c, '');

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

    newFile(a, '');

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
    var asyncPath = sdk.mapDartUri('dart:async')!.fullName;
    getFile(asyncPath).delete();
    addTestFile('class C {}');

    var result = await driver.getErrors(testFile) as ErrorsResult;
    expect(result.errors, hasLength(1));

    AnalysisError error = result.errors[0];
    expect(error.errorCode, CompileTimeErrorCode.MISSING_DART_LIBRARY);
  }

  test_missingDartLibrary_core() async {
    var corePath = sdk.mapDartUri('dart:core')!.fullName;
    getFile(corePath).delete();
    addTestFile('class C {}');

    var result = await driver.getErrors(testFile) as ErrorsResult;
    expect(result.errors, hasLength(1));

    AnalysisError error = result.errors[0];
    expect(error.errorCode, CompileTimeErrorCode.MISSING_DART_LIBRARY);
  }

  test_parseFileSync_changedFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, '');
    newFile(b, r'''
import 'a.dart';

void f(A a) {}
''');

    // Ensure that [a.dart] library cycle is loaded.
    // So, `a.dart` is in the library context.
    await driver.getResultValid(a);

    // Update the file, changing its API signature.
    // Note that we don't call `changeFile`.
    newFile(a, 'class A {}');

    // Parse the file.
    // We have not called `changeFile(a)`, so we should not read the file.
    // Moreover, doing this will create a new library cycle [a.dart].
    // Library cycles are compared by their identity, so we would try to
    // reload linked summary for [a.dart], and crash.
    {
      var parseResult = driver.parseFileSync(a) as ParsedUnitResult;
      expect(parseResult.unit.declarations, isEmpty);
    }

    // We have not read `a.dart`, so `A` is still not declared.
    {
      var bResult = await driver.getResultValid(b);
      expect(bResult.errors, isNotEmpty);
    }

    // Notify the driver that the file was changed.
    driver.changeFile(a);

    // ...and apply this change.
    await driver.applyPendingFileChanges();

    // So, `class A {}` is declared now.
    {
      var parseResult = driver.parseFileSync(a) as ParsedUnitResult;
      expect(parseResult.unit.declarations, hasLength(1));
    }
    {
      var bResult = await driver.getResultValid(b);
      expect(bResult.errors, isEmpty);
    }
  }

  test_parseFileSync_doesNotReadImportedFiles() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, '');
    newFile(b, r'''
import 'a.dart';
''');

    expect(driver.fsState.knownFilePaths, isEmpty);

    // Don't read `a.dart` when parse.
    driver.parseFileSync(b);
    expect(driver.fsState.knownFilePaths, unorderedEquals([b]));

    // Still don't read `a.dart` when parse the second time.
    driver.parseFileSync(b);
    expect(driver.fsState.knownFilePaths, unorderedEquals([b]));
  }

  test_parseFileSync_languageVersion() async {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, r'''
// @dart = 2.7
class A {}
''');

    var parseResult = driver.parseFileSync(path) as ParsedUnitResult;
    var languageVersion = parseResult.unit.languageVersionToken!;
    expect(languageVersion.major, 2);
    expect(languageVersion.minor, 7);
  }

  test_parseFileSync_languageVersion_null() async {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, r'''
class A {}
''');

    var parseResult = driver.parseFileSync(path) as ParsedUnitResult;
    expect(parseResult.unit.languageVersionToken, isNull);
  }

  test_parseFileSync_notAbsolutePath() async {
    var result = driver.parseFileSync('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_parseFileSync_notDart() async {
    var p = convertPath('/test/bin/a.txt');
    newFile(p, 'class A {}');

    var parseResult = driver.parseFileSync(p) as ParsedUnitResult;
    expect(parseResult, isNotNull);
    expect(driver.knownFiles, contains(p));
  }

  test_partOfName_getErrors_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
      var result = await driver.getErrors(a) as ErrorsResult;
      expect(result.errors, isEmpty);
    }

    // c.dart does not have errors in the context of a.dart
    {
      var result = await driver.getErrors(c) as ErrorsResult;
      expect(result.errors, isEmpty);
    }
  }

  test_partOfName_getErrors_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
      var result = await driver.getErrors(c) as ErrorsResult;
      expect(result.errors, isEmpty);
    }
  }

  test_partOfName_getResult_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
      ResolvedUnitResult result = await driver.getResultValid(a);
      expect(result.errors, isEmpty);
      _assertTopLevelVarType(result.unit, 'c', 'C');
    }

    // Now c.dart can be resolved without errors in the context of a.dart
    {
      ResolvedUnitResult result = await driver.getResultValid(c);
      expect(result.errors, isEmpty);
      _assertTopLevelVarType(result.unit, 'a', 'A');
      _assertTopLevelVarType(result.unit, 'b', 'B');
    }
  }

  test_partOfName_getResult_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
    ResolvedUnitResult result = await driver.getResultValid(c);
    expect(result.errors, isEmpty);
    _assertTopLevelVarType(result.unit, 'a', 'A');
    _assertTopLevelVarType(result.unit, 'b', 'B');
  }

  test_partOfName_getResult_changePart_invalidatesLibraryCycle() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, r'''
import 'dart:async';
part 'b.dart';
''');
    driver.addFile(a);

    // Analyze the library without the part.
    await driver.getResultValid(a);

    // Create the part file.
    // This should invalidate library file state (specifically the library
    // cycle), so that we can re-link the library, and get new dependencies.
    newFile(b, r'''
part of 'a.dart';
Future<int> f;
''');
    driver.changeFile(b);

    // This should not crash.
    var result = await driver.getResultValid(b);
    expect(result.errors, isEmpty);
  }

  test_partOfName_getResult_hasLibrary_noPart() async {
    final a = newFile('/test/lib/a.dart', r'''
library my.lib;
''');

    final c = newFile('/test/lib/c.dart', r'''
part of my.lib;
final a = A();
''');

    // Discover the library.
    driver.getFileSync(a.path);

    // There is no library which c.dart is a part of, so `A` is unresolved.
    ResolvedUnitResult result = await driver.getResultValid(c.path);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNotNull);
  }

  test_partOfName_getResult_noLibrary() async {
    var c = convertPath('/test/lib/c.dart');
    newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    ResolvedUnitResult result = await driver.getResultValid(c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNotNull);
  }

  test_partOfName_getUnitElement_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    await driver.getResultValid(a);

    // c.dart is resolve in the context of a.dart, knows 'A' and 'B'.
    {
      var result = await driver.getUnitElement(c);
      result as UnitElementResult;
      var partUnit = result.element;

      assertType(partUnit.topLevelVariables[0].type, 'A');
      assertType(partUnit.topLevelVariables[1].type, 'B');

      var libraryUnit = partUnit.library.definingCompilationUnit;
      assertType(libraryUnit.topLevelVariables[0].type, 'C');
    }
  }

  test_partOfName_getUnitElement_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
      var result = await driver.getUnitElement(c);
      result as UnitElementResult;
      var partUnit = result.element;

      assertType(partUnit.topLevelVariables[0].type, 'A');
      assertType(partUnit.topLevelVariables[1].type, 'B');

      var libraryUnit = partUnit.library.definingCompilationUnit;
      assertType(libraryUnit.topLevelVariables[0].type, 'C');
    }
  }

  test_partOfName_getUnitElement_noLibrary() async {
    var c = convertPath('/test/lib/c.dart');
    newFile(c, r'''
part of a;
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // We don't know the library of c.dart, but we should get a result.
    // The types "A" and "B" are unresolved.
    {
      var result = await driver.getUnitElement(c);
      result as UnitElementResult;
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].name, 'a');
      assertType(partUnit.topLevelVariables[0].type, 'InvalidType');

      expect(partUnit.topLevelVariables[1].name, 'b');
      assertType(partUnit.topLevelVariables[1].type, 'InvalidType');
    }
  }

  test_partOfName_results_afterLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
      var result =
          allResults.whereType<ErrorsResult>().lastWhere((r) => r.path == c);
      expect(result.errors, isEmpty);
    }

    // Update a.dart so that c.dart is not a part.
    {
      modifyFile(a, '// does not use c.dart anymore');
      driver.changeFile(a);
      await waitForIdleWithoutExceptions();

      // Now c.dart does not have a library context, so A and B cannot be
      // resolved, so there are errors.
      var result =
          allResults.whereType<ErrorsResult>().lastWhere((r) => r.path == c);
      expect(result.errors, isNotEmpty);
    }
  }

  test_partOfName_results_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
    var result =
        allResults.whereType<ErrorsResult>().lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
  }

  test_partOfName_results_noLibrary() async {
    var c = convertPath('/test/lib/c.dart');
    newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    await waitForIdleWithoutExceptions();

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    var result =
        allResults.whereType<ErrorsResult>().lastWhere((r) => r.path == c);
    expect(result.errors, isNotEmpty);
  }

  test_partOfName_results_noLibrary_priority() async {
    var c = newFile('/test/lib/c.dart', r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c.path);
    driver.priorityFiles = [c.path];

    await waitForIdleWithoutExceptions();

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    final result = allResults
        .whereType<ResolvedUnitResult>()
        .lastWhere((result) => result.path == c.path);
    expect(result.errors, isNotEmpty);
  }

  test_partOfName_results_priority_beforeLibrary() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    newFile(b, 'class B {}');
    newFile(c, r'''
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
    ResolvedUnitResult result = allResults
        .whereType<ResolvedUnitResult>()
        .lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNotNull);
  }

  test_removeFile_addFile_results() async {
    var a = convertPath('/test/lib/a.dart');
    newFile(a, 'class A {}');

    driver.addFile(a);

    await waitForIdleWithoutExceptions();
    expect(allResults.pathSet, {a});
    allResults.clear();

    driver.removeFile(a);
    driver.addFile(a);

    // a.dart should be produced again
    await waitForIdleWithoutExceptions();
    expect(allResults.pathSet, {a});
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, r'''
import 'b.dart';
var A = B;
''');
    newFile(b, 'var B = 1;');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);

    // We have results for both "a" and "b".
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(2));
    {
      ResolvedUnitResult ar = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == a);
      _assertTopLevelVarType(ar.unit, 'A', 'int');
    }
    {
      ResolvedUnitResult br = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == b);
      _assertTopLevelVarType(br.unit, 'B', 'int');
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
      ResolvedUnitResult ar = allResults
          .whereType<ResolvedUnitResult>()
          .firstWhere((r) => r.path == a);
      _assertTopLevelVarType(ar.unit, 'A', 'double');
    }
  }

  test_removeFile_changeFile_notAnalyzed() async {
    addTestFile('main() {}');

    // We have a result.
    await waitForIdleWithoutExceptions();
    expect(allResults.pathSet, {testFile});
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

    newFile(a, 'class A {}');
    newFile(b, "import 'a.dart';  var a = new A();");

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // b.dart s clean.
    expect(allResults.withPath(b).errors, isEmpty);
    allResults.clear();

    // Remove a.dart, now b.dart should be reanalyzed and has an error.
    deleteFile(a);
    driver.removeFile(a);
    await waitForIdleWithoutExceptions();
    expect(allResults.withPath(b).errors, hasLength(2));
    allResults.clear();
  }

  test_removeFile_notAbsolutePath() async {
    expect(() {
      driver.removeFile('not_absolute.dart');
    }, throwsArgumentError);
  }

  test_results_order() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    var d = convertPath('/test/lib/d.dart');
    var e = convertPath('/test/lib/e.dart');
    var f = convertPath('/test/lib/f.dart');
    newFile(a, r'''
import 'd.dart';
''');
    newFile(b, '');
    newFile(c, r'''
import 'd.dart';
''');
    newFile(d, r'''
import 'b.dart';
''');
    newFile(e, r'''
export 'b.dart';
''');
    newFile(f, r'''
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

    // Update b.dart with changing its API signature.
    modifyFile(b, 'class A {}');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();

    List<String> analyzedPaths = allResults.pathList;

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
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, '');
    newFile(d, "import 'a.dart';");
    newFile(e, "import 'b.dart';");

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

    List<String> analyzedPaths = allResults.pathList;

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
    var result = allResults.single as ResolvedUnitResult;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    assertType(f.declaredElement!.type, 'int Function()');
    assertType(f.returnType!.typeOrThrow, 'int');
  }

  test_results_priorityFirst() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    var c = convertPath('/test/lib/c.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');
    newFile(c, 'class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.priorityFiles = [b];
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(3));
    var result = allResults.first as ResolvedUnitResult;
    expect(result.path, b);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));
  }

  test_results_regular() async {
    String content = 'int f() => 42;';
    addTestFile(content);
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(1));
    var result = allResults.single as ErrorsResult;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.errors, hasLength(0));
  }

  test_results_removeFile_changeFile() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');

    newFile(a, r'''
var v = 0;
''');
    driver.addFile(a);

    await waitForIdleWithoutExceptions();
    expect(allResults.withPath(a).errors, hasLength(0));
    allResults.clear();

    newFile(a, r'''
var v = 0
''');
    driver.removeFile(b);
    driver.changeFile(a);
    await waitForIdleWithoutExceptions();
    expect(allResults.withPath(a).errors, hasLength(1));
  }

  test_results_skipNotAffected() async {
    var a = convertPath('/test/lib/a.dart');
    var b = convertPath('/test/lib/b.dart');
    newFile(a, 'class A {}');
    newFile(b, 'class B {}');

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
      var buffer = StringBuffer();
      for (var exception in allExceptions) {
        buffer.writeln('Path: ${exception.filePath}');
        buffer.writeln('Exception: ${exception.exception}');
      }
      fail('Unexpected exceptions:\n$buffer');
    }
  }

  void _assertClassFieldType(CompilationUnit unit, String className,
      String fieldName, String expected) {
    var node = _getClassField(unit, className, fieldName);
    var type = node.declaredElement!.type;
    assertType(type, expected);
  }

  void _assertClassMethodReturnType(CompilationUnit unit, String className,
      String fieldName, String expected) {
    var node = _getClassMethod(unit, className, fieldName);
    var type = node.declaredElement!.returnType;
    assertType(type, expected);
  }

  void _assertTopLevelVarType(
      CompilationUnit unit, String name, String expected) {
    VariableDeclaration variable = _getTopLevelVar(unit, name);
    assertType(variable.declaredElement!.type, expected);
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
        if (declaration.name.lexeme == name) {
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
          if (field.name.lexeme == fieldName) {
            return field;
          }
        }
      }
    }
    fail('Cannot find the field $fieldName in the class $className in\n$unit');
  }

  MethodDeclaration _getClassMethod(
      CompilationUnit unit, String className, String methodName) {
    ClassDeclaration classDeclaration = _getClass(unit, className);
    for (ClassMember declaration in classDeclaration.members) {
      if (declaration is MethodDeclaration &&
          declaration.name.lexeme == methodName) {
        return declaration;
      }
    }
    fail('Cannot find the method $methodName in the class $className in\n'
        '$unit');
  }

  LibraryImportElement _getImportElement(
      CompilationUnit unit, int directiveIndex) {
    var import = unit.directives[directiveIndex] as ImportDirective;
    return import.element!;
  }

  Source _getImportSource(CompilationUnit unit, int directiveIndex) {
    return _getImportElement(unit, directiveIndex).importedLibrary!.source;
  }

  VariableDeclaration _getTopLevelVar(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in declaration.variables.variables) {
          if (variable.name.lexeme == name) {
            return variable;
          }
        }
      }
    }
    fail('Cannot find the top-level variable $name in\n$unit');
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
    throw StateError('Unexpected invocation of ${invocation.memberName}');
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

  FileResult getFileSyncValid(String path) {
    return getFileSync(path) as FileResult;
  }

  Future<LibraryElementResult> getLibraryByUriValid(String uriStr) async {
    return await getLibraryByUri(uriStr) as LibraryElementResult;
  }

  Future<ResolvedUnitResult> getResultValid(String path) async {
    return await getResult(path) as ResolvedUnitResult;
  }
}
