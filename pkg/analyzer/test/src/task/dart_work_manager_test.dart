// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.dart_work_manager_test;

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart'
    show CacheState, InternalAnalysisContext;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/dart_work_manager.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/dart.dart';
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
  AnalysisCache cache;
  InternalAnalysisContext context = new _InternalAnalysisContextMock();
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
    expect(manager.librarySourceQueue, orderedEquals(sources));
  }

  void expect_librarySources(List<Source> sources) {
    expect(manager.librarySources, unorderedEquals(sources));
  }

  void expect_partSources(List<Source> sources) {
    expect(manager.partSources, unorderedEquals(sources));
  }

  void expect_unknownSourceQueue(List<Source> sources) {
    expect(manager.unknownSourceQueue, orderedEquals(sources));
  }

  void setUp() {
    cache = new AnalysisCache([new UniversalCachePartition(context)]);
    manager = new DartWorkManager(context);
    entry1 = new CacheEntry(source1);
    entry2 = new CacheEntry(source2);
    entry3 = new CacheEntry(source3);
    entry4 = new CacheEntry(source4);
    cache.put(entry1);
    cache.put(entry2);
    cache.put(entry3);
    cache.put(entry4);
    when(context.getCacheEntry(source1)).thenReturn(entry1);
    when(context.getCacheEntry(source2)).thenReturn(entry2);
    when(context.getCacheEntry(source3)).thenReturn(entry3);
    when(context.getCacheEntry(source4)).thenReturn(entry4);
  }

  void test_applyChange_add() {
    // add source1
    manager.applyChange([source1], [], []);
    expect_librarySources([]);
    expect_partSources([]);
    expect_unknownSourceQueue([source1]);
    expect_librarySourceQueue([]);
    // add source2
    manager.applyChange([source2], [], []);
    expect_librarySources([]);
    expect_partSources([]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }

  void test_applyChange_add_duplicate() {
    // add source1
    manager.applyChange([source1], [], []);
    expect_librarySources([]);
    expect_partSources([]);
    expect_unknownSourceQueue([source1]);
    expect_librarySourceQueue([]);
    // add source2
    manager.applyChange([source1], [], []);
    expect_librarySources([]);
    expect_partSources([]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1]);
  }

  void test_applyChange_addRemove() {
    manager.applyChange([source1, source2], [], [source2, source3]);
    expect_librarySources([]);
    expect_partSources([]);
    expect_unknownSourceQueue([source1]);
    expect_librarySourceQueue([]);
  }

  void test_applyChange_change() {
    manager.librarySources.addAll([source1, source3]);
    manager.partSources.addAll([source2]);
    manager.librarySourceQueue.addAll([source1, source3]);
    manager.unknownSourceQueue.addAll([source4]);
    // change source1
    manager.applyChange([], [source1], []);
    expect_librarySources([source3]);
    expect_partSources([source2]);
    expect_librarySourceQueue([source3]);
    expect_unknownSourceQueue([source4, source1]);
  }

  void test_applyChange_remove() {
    manager.librarySources.addAll([source1, source3]);
    manager.partSources.addAll([source2]);
    manager.librarySourceQueue.addAll([source1, source3]);
    manager.unknownSourceQueue.addAll([source4]);
    // remove source1
    manager.applyChange([], [], [source1]);
    expect_librarySources([source3]);
    expect_partSources([source2]);
    expect_librarySourceQueue([source3]);
    expect_unknownSourceQueue([source4]);
    // remove source3
    manager.applyChange([], [], [source3]);
    expect_librarySources([]);
    expect_partSources([source2]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source4]);
    // remove source4
    manager.applyChange([], [], [source4]);
    expect_librarySources([]);
    expect_partSources([source2]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([]);
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

  void test_getNextResult_hasLibraries_nothingToDo() {
    manager.librarySources.addAll([source1]);
    manager.partSources.addAll([source2]);
    TargetedResult request = manager.getNextResult();
    expect(request, isNull);
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

  void test_getNextResultPriority_hasLibrary() {
    manager.librarySourceQueue.addAll([source1]);
    expect(manager.getNextResultPriority(), WorkOrderPriority.NORMAL);
  }

  void test_getNextResultPriority_hasUnknown() {
    manager.unknownSourceQueue.addAll([source1]);
    expect(manager.getNextResultPriority(), WorkOrderPriority.NORMAL);
  }

  void test_getNextResultPriority_nothingToDo() {
    expect(manager.getNextResultPriority(), WorkOrderPriority.NONE);
  }

  void test_resultsComputed_isLibrary() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.LIBRARY});
    expect_librarySources([source2]);
    expect_partSources([]);
    expect_librarySourceQueue([source2]);
    expect_unknownSourceQueue([source1, source3]);
  }

  void test_resultsComputed_isPart() {
    manager.unknownSourceQueue.addAll([source1, source2, source3]);
    manager.resultsComputed(source2, {SOURCE_KIND: SourceKind.PART});
    expect_librarySources([]);
    expect_partSources([source2]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source3]);
  }

  void test_resultsComputed_noSourceKind() {
    manager.unknownSourceQueue.addAll([source1, source2]);
    manager.resultsComputed(source1, {});
    expect_librarySources([]);
    expect_partSources([]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }

  void test_resultsComputed_notDart() {
    manager.unknownSourceQueue.addAll([source1, source2]);
    manager.resultsComputed(new TestSource('test.html'), {});
    expect_librarySources([]);
    expect_partSources([]);
    expect_librarySourceQueue([]);
    expect_unknownSourceQueue([source1, source2]);
  }
}

class _InternalAnalysisContextMock extends TypedMock
    implements InternalAnalysisContext {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
