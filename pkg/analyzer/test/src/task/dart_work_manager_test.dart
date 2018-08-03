// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show AnalysisError;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart' show ScannerErrorCode;
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisContext,
        AnalysisErrorInfo,
        AnalysisErrorInfoImpl,
        AnalysisOptions,
        AnalysisOptionsImpl,
        CacheState,
        ChangeNoticeImpl,
        InternalAnalysisContext;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/task/api/dart.dart';
import 'package:analyzer/src/task/api/general.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/dart_work_manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartWorkManagerTest);
  });
}

@reflectiveTest
class DartWorkManagerTest {
  _InternalAnalysisContextMock context = new _InternalAnalysisContextMock();
  AnalysisCache cache;
  DartWorkManager manager;

  CaughtException caughtException = new CaughtException(null, null);

  Source source1 = new TestSource('1.dart');
  Source source2 = new TestSource('2.dart');
  Source source3 = new TestSource('3.dart');
  Source source4 = new TestSource('4.dart');
  CacheEntry entry1;
  CacheEntry entry2;
  CacheEntry entry3;
  CacheEntry entry4;

  void expect_librarySourceQueue(List<Source> sources) {
    expect(manager.librarySourceQueue, unorderedEquals(sources));
  }

  void expect_unknownSourceQueue(List<Source> sources) {
    expect(manager.unknownSourceQueue, unorderedEquals(sources));
  }

  void setUp() {
    cache = context.analysisCache;
    manager = new DartWorkManager(context);
    entry1 = _getOrCreateEntry(source1);
    entry2 = _getOrCreateEntry(source2);
    entry3 = _getOrCreateEntry(source3);
    entry4 = _getOrCreateEntry(source4);
  }

  void test_applyChange_add() {
    // add source1
    manager.applyChange([source1], [], []);
    expect_unknownSourceQueue([source1]);
    expect_librarySourceQueue([]);
    // add source2
    manager.applyChange([source2], [], []);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }

  void test_applyChange_add_duplicate() {
    // add source1
    manager.applyChange([source1], [], []);
    expect_unknownSourceQueue([source1]);
    expect_librarySourceQueue([]);
    // add source2
    manager.applyChange([source1], [], []);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1]);
  }

  void test_applyChange_addRemove() {
    manager.applyChange([source1, source2], [], [source2, source3]);
    expect_unknownSourceQueue([source1]);
    expect_librarySourceQueue([]);
  }

  void test_applyChange_change() {
    manager.librarySourceQueue.addAll([source1, source3]);
    manager.unknownSourceQueue.addAll([source4]);
    // change source1
    manager.applyChange([], [source1], []);
    expect_librarySourceQueue([source3]);
    expect_unknownSourceQueue([source4, source1]);
  }

  /**
   * When we perform limited invalidation, we keep [SOURCE_KIND] valid. So, we
   * don't need to put such sources into [DartWorkManager.unknownSourceQueue],
   * and remove from [DartWorkManager.librarySourceQueue].
   */
  void test_applyChange_change_hasSourceKind() {
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    manager.librarySourceQueue.addAll([source1, source2]);
    manager.unknownSourceQueue.addAll([source3]);
    // change source1
    manager.applyChange([], [source1, source2], []);
    expect_librarySourceQueue([source1]);
    expect_unknownSourceQueue([source2, source3]);
  }

  void test_applyChange_remove() {
    manager.librarySourceQueue.addAll([source1, source3]);
    manager.unknownSourceQueue.addAll([source4]);
    // remove source1
    manager.applyChange([], [], [source1]);
    expect_librarySourceQueue([source3]);
    expect_unknownSourceQueue([source4]);
    // remove source3
    manager.applyChange([], [], [source3]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source4]);
    // remove source4
    manager.applyChange([], [], [source4]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([]);
  }

  void test_applyChange_updatePartsLibraries_changeLibrary() {
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    manager.partLibrariesMap[part1] = [library1, library2];
    manager.partLibrariesMap[part2] = [library2];
    manager.partLibrariesMap[part3] = [library1];
    manager.libraryPartsMap[library1] = [part1, part3];
    manager.libraryPartsMap[library2] = [part1, part2];
    _getOrCreateEntry(part1).setValue(CONTAINING_LIBRARIES, [], []);
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.VALID);
    // change library1
    manager.applyChange([], [library1], []);
    expect(manager.partLibrariesMap[part1], unorderedEquals([library2]));
    expect(manager.partLibrariesMap[part2], unorderedEquals([library2]));
    expect(manager.partLibrariesMap[part3], unorderedEquals([]));
    expect(manager.libraryPartsMap[library1], isNull);
    expect(manager.libraryPartsMap[library2], [part1, part2]);
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.INVALID);
  }

  void test_applyChange_updatePartsLibraries_changePart() {
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    manager.partLibrariesMap[part1] = [library1, library2];
    manager.partLibrariesMap[part2] = [library2];
    manager.partLibrariesMap[part3] = [library1];
    manager.libraryPartsMap[library1] = [part1, part3];
    manager.libraryPartsMap[library2] = [part1, part2];
    _getOrCreateEntry(part1).setValue(CONTAINING_LIBRARIES, [], []);
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.VALID);
    // change part1
    manager.applyChange([], [part1], []);
    expect(manager.partLibrariesMap[part2], unorderedEquals([library2]));
    expect(manager.partLibrariesMap[part3], unorderedEquals([library1]));
    expect(manager.libraryPartsMap[library1], [part1, part3]);
    expect(manager.libraryPartsMap[library2], [part1, part2]);
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.INVALID);
  }

  void test_applyChange_updatePartsLibraries_removeLibrary() {
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    manager.partLibrariesMap[part1] = [library1, library2];
    manager.partLibrariesMap[part2] = [library2];
    manager.partLibrariesMap[part3] = [library1];
    manager.libraryPartsMap[library1] = [part1, part3];
    manager.libraryPartsMap[library2] = [part1, part2];
    // remove library1
    manager.applyChange([], [], [library1]);
    expect(manager.partLibrariesMap[part1], unorderedEquals([library2]));
    expect(manager.partLibrariesMap[part2], unorderedEquals([library2]));
    expect(manager.partLibrariesMap[part3], unorderedEquals([]));
    expect(manager.libraryPartsMap[library1], isNull);
    expect(manager.libraryPartsMap[library2], [part1, part2]);
  }

  void test_applyChange_updatePartsLibraries_removePart() {
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    manager.partLibrariesMap[part1] = [library1, library2];
    manager.partLibrariesMap[part2] = [library2];
    manager.partLibrariesMap[part3] = [library1];
    manager.libraryPartsMap[library1] = [part1, part3];
    manager.libraryPartsMap[library2] = [part1, part2];
    // remove part1
    manager.applyChange([], [], [part1]);
    expect(manager.partLibrariesMap[part1], isNull);
    expect(manager.partLibrariesMap[part2], unorderedEquals([library2]));
    expect(manager.partLibrariesMap[part3], unorderedEquals([library1]));
    expect(manager.libraryPartsMap[library1], [part1, part3]);
    expect(manager.libraryPartsMap[library2], [part1, part2]);
  }

  void test_applyPriorityTargets_isLibrary_computeErrors() {
    context.setShouldErrorsBeAnalyzed(source2, true);
    context.setShouldErrorsBeAnalyzed(source3, true);
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry2.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    manager.priorityResultQueue
        .add(new TargetedResult(source1, LIBRARY_ERRORS_READY));
    manager.priorityResultQueue
        .add(new TargetedResult(source2, LIBRARY_ERRORS_READY));
    // -source1 +source3
    manager.applyPriorityTargets([source2, source3]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source2, LIBRARY_ERRORS_READY),
          new TargetedResult(source3, LIBRARY_ERRORS_READY)
        ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, LIBRARY_ERRORS_READY);
  }

  void test_applyPriorityTargets_isLibrary_computeUnit() {
    context.setShouldErrorsBeAnalyzed(source2, false);
    context.setShouldErrorsBeAnalyzed(source3, false);
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry2.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    manager.priorityResultQueue
        .add(new TargetedResult(source1, LIBRARY_ERRORS_READY));
    manager.priorityResultQueue
        .add(new TargetedResult(source2, LIBRARY_ERRORS_READY));
    // -source1 +source3
    manager.applyPriorityTargets([source2, source3]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(
              new LibrarySpecificUnit(source2, source2), RESOLVED_UNIT),
          new TargetedResult(
              new LibrarySpecificUnit(source3, source3), RESOLVED_UNIT),
        ]));
  }

  void test_applyPriorityTargets_isPart() {
    entry1.setValue(SOURCE_KIND, SourceKind.PART, []);
    entry2.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    // +source2 +source3
    context.getLibrariesContainingMap[source1] = <Source>[source2, source3];
    manager.applyPriorityTargets([source1]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source2, LIBRARY_ERRORS_READY),
          new TargetedResult(source3, LIBRARY_ERRORS_READY)
        ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, LIBRARY_ERRORS_READY);
  }

  void test_applyPriorityTargets_isUnknown() {
    manager.applyPriorityTargets([source2, source3]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source2, SOURCE_KIND),
          new TargetedResult(source3, SOURCE_KIND)
        ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, SOURCE_KIND);
  }

  void test_getErrors() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    context.getLibrariesContainingMap[source1] = <Source>[source2];
    entry1.setValue(SCAN_ERRORS, <AnalysisError>[error1], []);
    context
        .getCacheEntry(new LibrarySpecificUnit(source2, source1))
        .setValue(VERIFY_ERRORS, <AnalysisError>[error2], []);
    List<AnalysisError> errors = manager.getErrors(source1);
    expect(errors, unorderedEquals([error1, error2]));
  }

  void test_getErrors_hasFullList() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    context.getLibrariesContainingMap[source1] = <Source>[source2];
    entry1.setValue(DART_ERRORS, <AnalysisError>[error1, error2], []);
    List<AnalysisError> errors = manager.getErrors(source1);
    expect(errors, unorderedEquals([error1, error2]));
  }

  void test_getLibrariesContainingPart() {
    context.aboutToComputeEverything = false;
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    manager.partLibrariesMap[part1] = [library1, library2];
    manager.partLibrariesMap[part2] = [library2];
    manager.libraryPartsMap[library1] = [part1];
    manager.libraryPartsMap[library2] = [part1, part2];
    // getLibrariesContainingPart
    expect(manager.getLibrariesContainingPart(part1),
        unorderedEquals([library1, library2]));
    expect(
        manager.getLibrariesContainingPart(part2), unorderedEquals([library2]));
    expect(manager.getLibrariesContainingPart(part3), isEmpty);
  }

  void test_getLibrariesContainingPart_askResultProvider() {
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    // configure AnalysisContext mock
    context.aboutToComputeResultMap[CONTAINING_LIBRARIES] =
        (CacheEntry entry, ResultDescriptor result) {
      if (entry.target == part1) {
        entry.setValue(result as ResultDescriptor<List<Source>>,
            <Source>[library1, library2], []);
        return true;
      }
      if (entry.target == part2) {
        entry.setValue(
            result as ResultDescriptor<List<Source>>, <Source>[library2], []);
        return true;
      }
      return false;
    };
    // getLibrariesContainingPart
    expect(manager.getLibrariesContainingPart(part1),
        unorderedEquals([library1, library2]));
    expect(
        manager.getLibrariesContainingPart(part2), unorderedEquals([library2]));
    expect(manager.getLibrariesContainingPart(part3), isEmpty);
  }

  void test_getLibrariesContainingPart_inSDK() {
    _SourceMock part = new _SourceMock('part.dart');
    part.isInSystemLibrary = true;
    // SDK work manager
    _DartWorkManagerMock sdkDartWorkManagerMock = new _DartWorkManagerMock();
    sdkDartWorkManagerMock.librariesContainingPartMap[part] = <Source>[
      source2,
      source3
    ];
    // SDK context mock
    _InternalAnalysisContextMock sdkContextMock =
        new _InternalAnalysisContextMock();
    sdkContextMock.workManagers = <WorkManager>[sdkDartWorkManagerMock];
    // SDK mock
    _DartSdkMock sdkMock = new _DartSdkMock();
    sdkMock.context = sdkContextMock;
    // SourceFactory mock
    _SourceFactoryMock sourceFactory = new _SourceFactoryMock();
    sourceFactory.dartSdk = sdkMock;
    context.sourceFactory = sourceFactory;
    // SDK source mock
    _SourceMock source = new _SourceMock('test.dart');
    source.source = source;
    source.isInSystemLibrary = true;
    // validate
    expect(manager.getLibrariesContainingPart(part),
        unorderedEquals([source2, source3]));
  }

  void test_getNextResult_hasLibraries_firstIsError() {
    entry1.setErrorState(caughtException, [LIBRARY_ERRORS_READY]);
    manager.librarySourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, LIBRARY_ERRORS_READY);
    // source1 is out, source2 is waiting
    expect_librarySourceQueue([source2]);
  }

  void test_getNextResult_hasLibraries_firstIsInvalid() {
    entry1.setState(LIBRARY_ERRORS_READY, CacheState.INVALID);
    manager.librarySourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source1);
    expect(request.result, LIBRARY_ERRORS_READY);
    // no changes until computed
    expect_librarySourceQueue([source1, source2]);
  }

  void test_getNextResult_hasLibraries_firstIsValid() {
    entry1.setValue(LIBRARY_ERRORS_READY, true, []);
    manager.librarySourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, LIBRARY_ERRORS_READY);
    // source1 is out, source2 is waiting
    expect_librarySourceQueue([source2]);
  }

  void test_getNextResult_hasPriority_firstIsError() {
    manager.addPriorityResult(source1, SOURCE_KIND);
    manager.addPriorityResult(source2, SOURCE_KIND);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source1, SOURCE_KIND),
          new TargetedResult(source2, SOURCE_KIND)
        ]));
    // configure state and get next result
    entry1.setErrorState(caughtException, [SOURCE_KIND]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, SOURCE_KIND);
    // source1 is out, source2 is waiting
    expect(manager.priorityResultQueue,
        unorderedEquals([new TargetedResult(source2, SOURCE_KIND)]));
  }

  void test_getNextResult_hasPriority_firstIsValid() {
    manager.addPriorityResult(source1, SOURCE_KIND);
    manager.addPriorityResult(source2, SOURCE_KIND);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source1, SOURCE_KIND),
          new TargetedResult(source2, SOURCE_KIND)
        ]));
    // configure state and get next result
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, SOURCE_KIND);
    // source1 is out, source2 is waiting
    expect(manager.priorityResultQueue,
        unorderedEquals([new TargetedResult(source2, SOURCE_KIND)]));
  }

  void test_getNextResult_hasUnknown_firstIsError() {
    entry1.setErrorState(caughtException, [SOURCE_KIND]);
    manager.unknownSourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, SOURCE_KIND);
    // source1 is out, source2 is waiting
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source2]);
  }

  void test_getNextResult_hasUnknown_firstIsInvalid() {
    manager.unknownSourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source1);
    expect(request.result, SOURCE_KIND);
    // no changes until computed
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }

  void test_getNextResult_hasUnknown_firstIsValid() {
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    manager.unknownSourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, SOURCE_KIND);
    // source1 is out, source2 is waiting
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source2]);
  }

  void test_getNextResult_nothingToDo() {
    TargetedResult request = manager.getNextResult();
    expect(request, isNull);
  }

  void test_getNextResultPriority_hasLibrary() {
    manager.librarySourceQueue.addAll([source1]);
    expect(manager.getNextResultPriority(), WorkOrderPriority.NORMAL);
  }

  void test_getNextResultPriority_hasPriority() {
    manager.addPriorityResult(source1, SOURCE_KIND);
    expect(manager.getNextResultPriority(), WorkOrderPriority.PRIORITY);
  }

  void test_getNextResultPriority_hasUnknown() {
    manager.unknownSourceQueue.addAll([source1]);
    expect(manager.getNextResultPriority(), WorkOrderPriority.NORMAL);
  }

  void test_getNextResultPriority_nothingToDo() {
    expect(manager.getNextResultPriority(), WorkOrderPriority.NONE);
  }

  void test_onAnalysisOptionsChanged() {
    context.everythingExists = true;
    // set cache values
    entry1.setValue(PARSED_UNIT, AstTestFactory.compilationUnit(), []);
    entry1.setValue(IMPORTED_LIBRARIES, <Source>[], []);
    entry1.setValue(EXPLICITLY_IMPORTED_LIBRARIES, <Source>[], []);
    entry1.setValue(EXPORTED_LIBRARIES, <Source>[], []);
    entry1.setValue(INCLUDED_PARTS, <Source>[], []);
    // configure LibrarySpecificUnit
    LibrarySpecificUnit unitTarget = new LibrarySpecificUnit(source2, source3);
    CacheEntry unitEntry = new CacheEntry(unitTarget);
    cache.put(unitEntry);
    unitEntry.setValue(BUILD_LIBRARY_ERRORS, <AnalysisError>[], []);
    expect(unitEntry.getState(BUILD_LIBRARY_ERRORS), CacheState.VALID);
    // notify
    manager.onAnalysisOptionsChanged();
    // resolution is invalidated
    expect(unitEntry.getState(BUILD_LIBRARY_ERRORS), CacheState.INVALID);
    // ...but URIs are still value
    expect(entry1.getState(PARSED_UNIT), CacheState.VALID);
    expect(entry1.getState(IMPORTED_LIBRARIES), CacheState.VALID);
    expect(entry1.getState(EXPLICITLY_IMPORTED_LIBRARIES), CacheState.VALID);
    expect(entry1.getState(EXPORTED_LIBRARIES), CacheState.VALID);
    expect(entry1.getState(INCLUDED_PARTS), CacheState.VALID);
  }

  void test_onResultInvalidated_scheduleInvalidatedLibraries() {
    // make source3 implicit
    entry3.explicitlyAdded = false;
    // set SOURCE_KIND
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry2.setValue(SOURCE_KIND, SourceKind.PART, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    // set LIBRARY_ERRORS_READY for source1 and source3
    entry1.setValue(LIBRARY_ERRORS_READY, true, []);
    entry3.setValue(LIBRARY_ERRORS_READY, true, []);
    // invalidate LIBRARY_ERRORS_READY for source1, schedule it
    entry1.setState(LIBRARY_ERRORS_READY, CacheState.INVALID);
    expect_librarySourceQueue([source1]);
    // invalidate LIBRARY_ERRORS_READY for source3, implicit, not scheduled
    entry3.setState(LIBRARY_ERRORS_READY, CacheState.INVALID);
    expect_librarySourceQueue([source1]);
  }

  void test_onSourceFactoryChanged() {
    context.everythingExists = true;
    // set cache values
    entry1.setValue(PARSED_UNIT, AstTestFactory.compilationUnit(), []);
    entry1.setValue(IMPORTED_LIBRARIES, <Source>[], []);
    entry1.setValue(EXPLICITLY_IMPORTED_LIBRARIES, <Source>[], []);
    entry1.setValue(EXPORTED_LIBRARIES, <Source>[], []);
    entry1.setValue(INCLUDED_PARTS, <Source>[], []);
    entry1.setValue(LIBRARY_SPECIFIC_UNITS, <LibrarySpecificUnit>[], []);
    entry1.setValue(UNITS, <Source>[], []);
    // configure LibrarySpecificUnit
    LibrarySpecificUnit unitTarget = new LibrarySpecificUnit(source2, source3);
    CacheEntry unitEntry = new CacheEntry(unitTarget);
    cache.put(unitEntry);
    unitEntry.setValue(BUILD_LIBRARY_ERRORS, <AnalysisError>[], []);
    expect(unitEntry.getState(BUILD_LIBRARY_ERRORS), CacheState.VALID);
    // notify
    manager.onSourceFactoryChanged();
    // resolution is invalidated
    expect(unitEntry.getState(BUILD_LIBRARY_ERRORS), CacheState.INVALID);
    // ...and URIs resolution too
    expect(entry1.getState(PARSED_UNIT), CacheState.INVALID);
    expect(entry1.getState(IMPORTED_LIBRARIES), CacheState.INVALID);
    expect(entry1.getState(EXPLICITLY_IMPORTED_LIBRARIES), CacheState.INVALID);
    expect(entry1.getState(EXPORTED_LIBRARIES), CacheState.INVALID);
    expect(entry1.getState(INCLUDED_PARTS), CacheState.INVALID);
    expect(entry1.getState(LIBRARY_SPECIFIC_UNITS), CacheState.INVALID);
    expect(entry1.getState(UNITS), CacheState.INVALID);
  }

  void test_resultsComputed_errors_forLibrarySpecificUnit() {
    LineInfo lineInfo = new LineInfo([0]);
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    context.getLibrariesContainingMap[source1] = <Source>[source2];
    context.errorsMap[source1] =
        new AnalysisErrorInfoImpl([error1, error2], lineInfo);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1.setValue(SCAN_ERRORS, <AnalysisError>[error1], []);
    AnalysisTarget unitTarget = new LibrarySpecificUnit(source2, source1);
    context
        .getCacheEntry(unitTarget)
        .setValue(VERIFY_ERRORS, <AnalysisError>[error2], []);
    // RESOLVED_UNIT is ready, set errors
    manager.resultsComputed(
        unitTarget, {RESOLVED_UNIT: AstTestFactory.compilationUnit()});
    // all of the errors are included
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.errors, unorderedEquals([error1, error2]));
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_errors_forSource() {
    LineInfo lineInfo = new LineInfo([0]);
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    context.getLibrariesContainingMap[source1] = <Source>[source2];
    context.errorsMap[source1] =
        new AnalysisErrorInfoImpl([error1, error2], lineInfo);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1.setValue(SCAN_ERRORS, <AnalysisError>[error1], []);
    entry1.setValue(PARSE_ERRORS, <AnalysisError>[error2], []);
    // PARSED_UNIT is ready, set errors
    manager.resultsComputed(
        source1, {PARSED_UNIT: AstTestFactory.compilationUnit()});
    // all of the errors are included
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.errors, unorderedEquals([error1, error2]));
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_includedParts_updatePartLibraries() {
    Source part1 = new TestSource('part1.dart');
    Source part2 = new TestSource('part2.dart');
    Source part3 = new TestSource('part3.dart');
    Source library1 = new TestSource('library1.dart');
    Source library2 = new TestSource('library2.dart');
    _getOrCreateEntry(part1).setValue(CONTAINING_LIBRARIES, [], []);
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.VALID);
    // configure AnalysisContext mock
    context.prioritySources = <Source>[];
    context.analyzeAllErrors = false;
    // library1 parts
    manager.resultsComputed(library1, <ResultDescriptor, dynamic>{
      INCLUDED_PARTS: [part1, part2],
      SOURCE_KIND: SourceKind.LIBRARY
    });
    expect(manager.partLibrariesMap[part1], [library1]);
    expect(manager.partLibrariesMap[part2], [library1]);
    expect(manager.partLibrariesMap[part3], isNull);
    expect(manager.libraryPartsMap[library1], [part1, part2]);
    expect(manager.libraryPartsMap[library2], isNull);
    // library2 parts
    manager.resultsComputed(library2, <ResultDescriptor, dynamic>{
      INCLUDED_PARTS: [part2, part3],
      SOURCE_KIND: SourceKind.LIBRARY
    });
    expect(manager.partLibrariesMap[part1], [library1]);
    expect(manager.partLibrariesMap[part2], [library1, library2]);
    expect(manager.partLibrariesMap[part3], [library2]);
    expect(manager.libraryPartsMap[library1], [part1, part2]);
    expect(manager.libraryPartsMap[library2], [part2, part3]);
    // part1 CONTAINING_LIBRARIES
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.INVALID);
  }

  void test_resultsComputed_inSDK() {
    _DartWorkManagerMock sdkDartWorkManagerMock = new _DartWorkManagerMock();
    // SDK context mock
    _InternalAnalysisContextMock sdkContextMock =
        new _InternalAnalysisContextMock();
    sdkContextMock.workManagers = <WorkManager>[sdkDartWorkManagerMock];
    // SDK mock
    _DartSdkMock sdkMock = new _DartSdkMock();
    sdkMock.context = sdkContextMock;
    // SourceFactory mock
    _SourceFactoryMock sourceFactory = new _SourceFactoryMock();
    sourceFactory.dartSdk = sdkMock;
    context.sourceFactory = sourceFactory;
    // SDK source mock
    _SourceMock source = new _SourceMock('test.dart');
    source.source = source;
    source.isInSystemLibrary = true;
    // notify and validate
    Map<ResultDescriptor, dynamic> outputs = <ResultDescriptor, dynamic>{};
    manager.resultsComputed(source, outputs);
    var bySourceMap = sdkDartWorkManagerMock.resultsComputedCounts[source];
    expect(bySourceMap, isNotNull);
    expect(bySourceMap[outputs], 1);
  }

  void test_resultsComputed_noSourceKind() {
    manager.unknownSourceQueue.addAll([source1, source2]);
    manager.resultsComputed(source1, {});
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }

  void test_resultsComputed_notDart() {
    manager.unknownSourceQueue.addAll([source1, source2]);
    manager.resultsComputed(new TestSource('test.html'), {});
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }

  void test_resultsComputed_parsedUnit() {
    LineInfo lineInfo = new LineInfo([0]);
    context.getLibrariesContainingMap[source1] = <Source>[];
    context.errorsMap[source1] = new AnalysisErrorInfoImpl([], lineInfo);
    entry1.setValue(LINE_INFO, lineInfo, []);
    CompilationUnit unit = AstTestFactory.compilationUnit();
    manager.resultsComputed(source1, {PARSED_UNIT: unit});
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.parsedDartUnit, unit);
    expect(notice.resolvedDartUnit, isNull);
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_resolvedUnit() {
    LineInfo lineInfo = new LineInfo([0]);
    context.getLibrariesContainingMap[source2] = <Source>[];
    context.errorsMap[source2] = new AnalysisErrorInfoImpl([], lineInfo);
    entry2.setValue(LINE_INFO, lineInfo, []);
    CompilationUnit unit = AstTestFactory.compilationUnit();
    manager.resultsComputed(
        new LibrarySpecificUnit(source1, source2), {RESOLVED_UNIT: unit});
    ChangeNoticeImpl notice = context.getNotice(source2);
    expect(notice.parsedDartUnit, isNull);
    expect(notice.resolvedDartUnit, unit);
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_sourceKind_isLibrary() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    context.prioritySources = <Source>[];
    context.shouldErrorsBeAnalyzedMap[source2] = true;
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.LIBRARY});
    expect_librarySourceQueue([source2]);
    expect_unknownSourceQueue([source1, source3]);
  }

  void test_resultsComputed_sourceKind_isLibrary_isPriority_computeErrors() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    context.prioritySources = <Source>[source2];
    context.shouldErrorsBeAnalyzedMap[source2] = true;
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.LIBRARY});
    expect_unknownSourceQueue([source1, source3]);
    expect(manager.priorityResultQueue,
        unorderedEquals([new TargetedResult(source2, LIBRARY_ERRORS_READY)]));
  }

  void test_resultsComputed_sourceKind_isLibrary_isPriority_computeUnit() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    context.prioritySources = <Source>[source2];
    context.shouldErrorsBeAnalyzedMap[source2] = false;
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.LIBRARY});
    expect_unknownSourceQueue([source1, source3]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(
              new LibrarySpecificUnit(source2, source2), RESOLVED_UNIT)
        ]));
  }

  void test_resultsComputed_sourceKind_isPart() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.PART});
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source3]);
  }

  void test_resultsComputed_updatePartsLibraries_partParsed() {
    Source part = new TestSource('part.dart');
    expect(manager.libraryPartsMap, isEmpty);
    // part.dart parsed, no changes is the map of libraries
    manager.resultsComputed(part, <ResultDescriptor, dynamic>{
      SOURCE_KIND: SourceKind.PART,
      INCLUDED_PARTS: <Source>[]
    });
    expect(manager.libraryPartsMap, isEmpty);
  }

  void test_unitIncrementallyResolved() {
    manager.unitIncrementallyResolved(source1, source2);
    expect_librarySourceQueue([source1]);
  }

  CacheEntry _getOrCreateEntry(Source source, [bool explicit = true]) {
    CacheEntry entry = cache.get(source);
    if (entry == null) {
      entry = new CacheEntry(source);
      entry.explicitlyAdded = explicit;
      cache.put(entry);
    }
    return entry;
  }
}

class _DartSdkMock implements DartSdk {
  AnalysisContext context;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

class _DartWorkManagerMock implements DartWorkManager {
  Map<Source, List<Source>> librariesContainingPartMap =
      <Source, List<Source>>{};

  Map<Source, Map<Map<ResultDescriptor, dynamic>, int>> resultsComputedCounts =
      <Source, Map<Map<ResultDescriptor, dynamic>, int>>{};

  @override
  List<Source> getLibrariesContainingPart(Source part) {
    return librariesContainingPartMap[part] ?? <Source>[];
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  void resultsComputed(
      AnalysisTarget target, Map<ResultDescriptor, dynamic> outputs) {
    Map<Map<ResultDescriptor, dynamic>, int> bySourceMap =
        resultsComputedCounts.putIfAbsent(target, () => {});
    bySourceMap[outputs] = (bySourceMap[outputs] ?? 0) + 1;
  }
}

class _InternalAnalysisContextMock implements InternalAnalysisContext {
  @override
  CachePartition privateAnalysisCachePartition;

  @override
  AnalysisCache analysisCache;

  @override
  SourceFactory sourceFactory;

  bool analyzeAllErrors;

  bool everythingExists = false;

  bool aboutToComputeEverything;

  @override
  List<Source> prioritySources = <Source>[];

  @override
  List<WorkManager> workManagers = <WorkManager>[];

  Map<Source, List<Source>> getLibrariesContainingMap =
      <Source, List<Source>>{};

  Map<Source, bool> shouldErrorsBeAnalyzedMap = <Source, bool>{};

  Map<ResultDescriptor, bool Function(CacheEntry entry, ResultDescriptor)>
      aboutToComputeResultMap =
      <ResultDescriptor, bool Function(CacheEntry entry, ResultDescriptor)>{};

  Map<Source, AnalysisErrorInfo> errorsMap = <Source, AnalysisErrorInfo>{};

  Map<Source, ChangeNoticeImpl> _pendingNotices = <Source, ChangeNoticeImpl>{};

  @override
  final AnalysisOptions analysisOptions = new AnalysisOptionsImpl();

  @override
  final ReentrantSynchronousStream<InvalidatedResult> onResultInvalidated =
      new ReentrantSynchronousStream<InvalidatedResult>();

  _InternalAnalysisContextMock() {
    privateAnalysisCachePartition = new UniversalCachePartition(this);
    analysisCache = new AnalysisCache([privateAnalysisCachePartition]);
    analysisCache.onResultInvalidated.listen((InvalidatedResult event) {
      onResultInvalidated.add(event);
    });
  }

  @override
  bool aboutToComputeResult(CacheEntry entry, ResultDescriptor result) {
    if (aboutToComputeEverything != null) {
      return aboutToComputeEverything;
    }
    bool Function(CacheEntry entry, ResultDescriptor) function =
        aboutToComputeResultMap[result];
    if (function == null) {
      return false;
    }
    return function(entry, result);
  }

  @override
  bool exists(Source source) {
    return everythingExists;
  }

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    CacheEntry entry = analysisCache.get(target);
    if (entry == null) {
      entry = new CacheEntry(target);
      analysisCache.put(entry);
    }
    return entry;
  }

  @override
  AnalysisErrorInfo getErrors(Source source) => errorsMap[source];

  List<Source> getLibrariesContaining(Source source) {
    return getLibrariesContainingMap[source];
  }

  @override
  ChangeNoticeImpl getNotice(Source source) {
    return _pendingNotices.putIfAbsent(
        source, () => new ChangeNoticeImpl(source));
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }

  void setShouldErrorsBeAnalyzed(Source source, bool value) {
    shouldErrorsBeAnalyzedMap[source] = value;
  }

  @override
  bool shouldErrorsBeAnalyzed(Source source) {
    if (analyzeAllErrors != null) {
      return analyzeAllErrors;
    }
    return shouldErrorsBeAnalyzedMap[source];
  }
}

class _SourceFactoryMock implements SourceFactory {
  DartSdk dartSdk;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

class _SourceMock implements Source {
  @override
  final String shortName;

  @override
  bool isInSystemLibrary = false;

  @override
  Source source;

  _SourceMock(this.shortName);

  @override
  String get fullName => '/' + shortName;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  String toString() => fullName;
}
