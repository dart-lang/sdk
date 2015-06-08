// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.dart_work_manager_test;

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisErrorInfo,
        CacheState,
        ChangeNoticeImpl,
        InternalAnalysisContext;
import 'package:analyzer/src/generated/error.dart' show AnalysisError;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
import 'package:analyzer/src/generated/scanner.dart' show ScannerErrorCode;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/dart_work_manager.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(DartWorkManagerTest);
}

@reflectiveTest
class DartWorkManagerTest {
  InternalAnalysisContext context = new _InternalAnalysisContextMock();
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
    entry1 = context.getCacheEntry(source1);
    entry2 = context.getCacheEntry(source2);
    entry3 = context.getCacheEntry(source3);
    entry4 = context.getCacheEntry(source4);
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

  void test_applyChange_scheduleInvalidatedLibraries() {
    // libraries source1 and source3 are invalid
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry2.setValue(SOURCE_KIND, SourceKind.PART, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry1.setValue(LIBRARY_ERRORS_READY, false, []);
    entry3.setValue(LIBRARY_ERRORS_READY, false, []);
    // change source2, schedule source1 and source3
    manager.applyChange([], [source2], []);
    expect_librarySourceQueue([source1, source3]);
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

  void test_applyPriorityTargets_library() {
    entry1.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry2.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    manager.priorityResultQueue
        .add(new TargetedResult(source1, LIBRARY_ERRORS_READY));
    manager.priorityResultQueue
        .add(new TargetedResult(source2, LIBRARY_ERRORS_READY));
    // -source1 +source3
    manager.applyPriorityTargets([source2, source3]);
    expect(manager.priorityResultQueue, unorderedEquals([
      new TargetedResult(source2, LIBRARY_ERRORS_READY),
      new TargetedResult(source3, LIBRARY_ERRORS_READY)
    ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, LIBRARY_ERRORS_READY);
  }

  void test_applyPriorityTargets_part() {
    entry1.setValue(SOURCE_KIND, SourceKind.PART, []);
    entry2.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    entry3.setValue(SOURCE_KIND, SourceKind.LIBRARY, []);
    // +source2 +source3
    when(context.getLibrariesContaining(source1))
        .thenReturn([source2, source3]);
    manager.applyPriorityTargets([source1]);
    expect(manager.priorityResultQueue, unorderedEquals([
      new TargetedResult(source2, LIBRARY_ERRORS_READY),
      new TargetedResult(source3, LIBRARY_ERRORS_READY)
    ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, LIBRARY_ERRORS_READY);
  }

  void test_getErrors() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    when(context.getLibrariesContaining(source1)).thenReturn([source2]);
    LineInfo lineInfo = new LineInfo([0]);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1.setValue(SCAN_ERRORS, <AnalysisError>[error1], []);
    context.getCacheEntry(new LibrarySpecificUnit(source2, source1)).setValue(
        VERIFY_ERRORS, <AnalysisError>[error2], []);
    AnalysisErrorInfo errorInfo = manager.getErrors(source1);
    expect(errorInfo.errors, unorderedEquals([error1, error2]));
    expect(errorInfo.lineInfo, lineInfo);
  }

  void test_getLibrariesContainingPart() {
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
    expect(manager.priorityResultQueue, unorderedEquals([
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
    expect(manager.priorityResultQueue, unorderedEquals([
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
    when(context.exists(anyObject)).thenReturn(true);
    // set cache values
    entry1.setValue(PARSED_UNIT, AstFactory.compilationUnit(), []);
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

  void test_onSourceFactoryChanged() {
    when(context.exists(anyObject)).thenReturn(true);
    // set cache values
    entry1.setValue(PARSED_UNIT, AstFactory.compilationUnit(), []);
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
    manager.onSourceFactoryChanged();
    // resolution is invalidated
    expect(unitEntry.getState(BUILD_LIBRARY_ERRORS), CacheState.INVALID);
    // ...and URIs resolution too
    expect(entry1.getState(PARSED_UNIT), CacheState.INVALID);
    expect(entry1.getState(IMPORTED_LIBRARIES), CacheState.INVALID);
    expect(entry1.getState(EXPLICITLY_IMPORTED_LIBRARIES), CacheState.INVALID);
    expect(entry1.getState(EXPORTED_LIBRARIES), CacheState.INVALID);
    expect(entry1.getState(INCLUDED_PARTS), CacheState.INVALID);
  }

  void test_resultsComputed_errors_forLibrarySpecificUnit() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    when(context.getLibrariesContaining(source1)).thenReturn([source2]);
    LineInfo lineInfo = new LineInfo([0]);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1.setValue(SCAN_ERRORS, <AnalysisError>[error1], []);
    AnalysisTarget unitTarget = new LibrarySpecificUnit(source2, source1);
    context.getCacheEntry(unitTarget).setValue(
        VERIFY_ERRORS, <AnalysisError>[error2], []);
    // RESOLVED_UNIT is ready, set errors
    manager.resultsComputed(
        unitTarget, {RESOLVED_UNIT: AstFactory.compilationUnit()});
    // all of the errors are included
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.errors, unorderedEquals([error1, error2]));
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_errors_forSource() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, ScannerErrorCode.MISSING_DIGIT);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, ScannerErrorCode.MISSING_DIGIT);
    when(context.getLibrariesContaining(source1)).thenReturn([source2]);
    LineInfo lineInfo = new LineInfo([0]);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1.setValue(SCAN_ERRORS, <AnalysisError>[error1], []);
    entry1.setValue(PARSE_ERRORS, <AnalysisError>[error2], []);
    // PARSED_UNIT is ready, set errors
    manager.resultsComputed(
        source1, {PARSED_UNIT: AstFactory.compilationUnit()});
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
    // library1 parts
    manager.resultsComputed(library1, {INCLUDED_PARTS: [part1, part2]});
    expect(manager.partLibrariesMap[part1], [library1]);
    expect(manager.partLibrariesMap[part2], [library1]);
    expect(manager.partLibrariesMap[part3], isNull);
    expect(manager.libraryPartsMap[library1], [part1, part2]);
    expect(manager.libraryPartsMap[library2], isNull);
    // library2 parts
    manager.resultsComputed(library2, {INCLUDED_PARTS: [part2, part3]});
    expect(manager.partLibrariesMap[part1], [library1]);
    expect(manager.partLibrariesMap[part2], [library1, library2]);
    expect(manager.partLibrariesMap[part3], [library2]);
    expect(manager.libraryPartsMap[library1], [part1, part2]);
    expect(manager.libraryPartsMap[library2], [part2, part3]);
    // part1 CONTAINING_LIBRARIES
    expect(cache.getState(part1, CONTAINING_LIBRARIES), CacheState.INVALID);
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
    when(context.getLibrariesContaining(source1)).thenReturn([]);
    LineInfo lineInfo = new LineInfo([0]);
    entry1.setValue(LINE_INFO, lineInfo, []);
    CompilationUnit unit = AstFactory.compilationUnit();
    manager.resultsComputed(source1, {PARSED_UNIT: unit});
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.parsedDartUnit, unit);
    expect(notice.resolvedDartUnit, isNull);
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_resolvedUnit() {
    when(context.getLibrariesContaining(source2)).thenReturn([]);
    LineInfo lineInfo = new LineInfo([0]);
    entry2.setValue(LINE_INFO, lineInfo, []);
    CompilationUnit unit = AstFactory.compilationUnit();
    manager.resultsComputed(
        new LibrarySpecificUnit(source1, source2), {RESOLVED_UNIT: unit});
    ChangeNoticeImpl notice = context.getNotice(source2);
    expect(notice.parsedDartUnit, isNull);
    expect(notice.resolvedDartUnit, unit);
    expect(notice.lineInfo, lineInfo);
  }

  void test_resultsComputed_sourceKind_isLibrary() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    when(context.shouldErrorsBeAnalyzed(source2, null)).thenReturn(true);
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.LIBRARY});
    expect_librarySourceQueue([source2]);
    expect_unknownSourceQueue([source1, source3]);
  }

  void test_resultsComputed_sourceKind_isPart() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.PART});
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source3]);
  }

  CacheEntry _getOrCreateEntry(Source source) {
    CacheEntry entry = cache.get(source);
    if (entry == null) {
      entry = new CacheEntry(source);
      cache.put(entry);
    }
    return entry;
  }
}

class _InternalAnalysisContextMock extends TypedMock
    implements InternalAnalysisContext {
  @override
  CachePartition privateAnalysisCachePartition;

  @override
  AnalysisCache analysisCache;

  Map<Source, ChangeNoticeImpl> _pendingNotices = <Source, ChangeNoticeImpl>{};

  _InternalAnalysisContextMock() {
    privateAnalysisCachePartition = new UniversalCachePartition(this);
    analysisCache = new AnalysisCache([privateAnalysisCachePartition]);
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
  ChangeNoticeImpl getNotice(Source source) {
    return _pendingNotices.putIfAbsent(
        source, () => new ChangeNoticeImpl(source));
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
