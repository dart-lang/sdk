// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.options_work_manager_test;

import 'package:analyzer/error/error.dart' show AnalysisError;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/error/codes.dart' show AnalysisOptionsErrorCode;
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisEngine,
        AnalysisErrorInfo,
        AnalysisErrorInfoImpl,
        CacheState,
        ChangeNoticeImpl,
        InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/task/options_work_manager.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsWorkManagerNewFileTest);
    defineReflectiveTests(OptionsWorkManagerOldFileTest);
  });
}

@reflectiveTest
class OptionsWorkManagerNewFileTest extends OptionsWorkManagerTest {
  String get optionsFile => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;
}

@reflectiveTest
class OptionsWorkManagerOldFileTest extends OptionsWorkManagerTest {
  String get optionsFile => AnalysisEngine.ANALYSIS_OPTIONS_FILE;
}

abstract class OptionsWorkManagerTest {
  InternalAnalysisContext context = new _InternalAnalysisContextMock();
  AnalysisCache cache;
  OptionsWorkManager manager;

  CaughtException caughtException = new CaughtException(null, null);

  Source source1;

  Source source2;
  Source source3;
  Source source4;
  CacheEntry entry1;
  CacheEntry entry2;
  CacheEntry entry3;
  CacheEntry entry4;
  String get optionsFile;

  void expect_sourceQueue(List<Source> sources) {
    expect(manager.sourceQueue, unorderedEquals(sources));
  }

  void setUp() {
    cache = context.analysisCache;
    manager = new OptionsWorkManager(context);
    source1 = new TestSource('test1/$optionsFile');
    source2 = new TestSource('test2/$optionsFile');
    source3 = new TestSource('test3/$optionsFile');
    source4 = new TestSource('test4/$optionsFile');
    entry1 = context.getCacheEntry(source1);
    entry2 = context.getCacheEntry(source2);
    entry3 = context.getCacheEntry(source3);
    entry4 = context.getCacheEntry(source4);
  }

  void test_applyChange_add() {
    // add source1
    manager.applyChange([source1], [], []);
    expect_sourceQueue([source1]);
    // add source2
    manager.applyChange([source2], [], []);
    expect_sourceQueue([source1, source2]);
  }

  void test_applyChange_add_duplicate() {
    // add source1
    manager.applyChange([source1], [], []);
    expect_sourceQueue([source1]);
    // add source1 again
    manager.applyChange([source1], [], []);
    expect_sourceQueue([source1]);
  }

  void test_applyChange_change() {
    // change source1
    manager.applyChange([], [source1], []);
    expect_sourceQueue([source1]);
  }

  void test_applyChange_change_afterAdd() {
    manager.applyChange([source1, source2], [], []);
    // change source1
    manager.applyChange([], [source1], []);
    expect_sourceQueue([source1, source2]);
  }

  void test_applyChange_remove() {
    manager.applyChange([source1, source2], [], []);
    // remove source1
    manager.applyChange([], [], [source1]);
    expect_sourceQueue([source2]);
    // remove source2
    manager.applyChange([], [], [source2]);
    expect_sourceQueue([]);
    // remove source3
    manager.applyChange([], [], [source3]);
    expect_sourceQueue([]);
  }

  void test_applyPriorityTargets() {
    when(context.shouldErrorsBeAnalyzed(source2)).thenReturn(true);
    when(context.shouldErrorsBeAnalyzed(source3)).thenReturn(true);
    manager.priorityResultQueue
        .add(new TargetedResult(source1, ANALYSIS_OPTIONS_ERRORS));
    manager.priorityResultQueue
        .add(new TargetedResult(source2, ANALYSIS_OPTIONS_ERRORS));
    // -source1 +source3
    manager.applyPriorityTargets([source2, source3]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source2, ANALYSIS_OPTIONS_ERRORS),
          new TargetedResult(source3, ANALYSIS_OPTIONS_ERRORS)
        ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, ANALYSIS_OPTIONS_ERRORS);
  }

  void test_getErrors() {
    AnalysisError error1 = new AnalysisError(
        source1, 1, 0, AnalysisOptionsErrorCode.PARSE_ERROR, ['']);
    AnalysisError error2 = new AnalysisError(
        source1, 2, 0, AnalysisOptionsErrorCode.PARSE_ERROR, ['']);
    entry1
        .setValue(ANALYSIS_OPTIONS_ERRORS, <AnalysisError>[error1, error2], []);

    List<AnalysisError> errors = manager.getErrors(source1);
    expect(errors, unorderedEquals([error1, error2]));
  }

  void test_getNextResult_hasNormal_firstIsError() {
    entry1.setErrorState(caughtException, [ANALYSIS_OPTIONS_ERRORS]);
    manager.sourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, ANALYSIS_OPTIONS_ERRORS);
    // source1 is out, source2 is waiting
    expect_sourceQueue([source2]);
  }

  void test_getNextResult_hasNormal_firstIsInvalid() {
    entry1.setState(ANALYSIS_OPTIONS_ERRORS, CacheState.INVALID);
    manager.sourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source1);
    expect(request.result, ANALYSIS_OPTIONS_ERRORS);
    // no changes until computed
    expect_sourceQueue([source1, source2]);
  }

  void test_getNextResult_hasNormal_firstIsValid() {
    entry1.setValue(ANALYSIS_OPTIONS_ERRORS, [], []);
    manager.sourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, ANALYSIS_OPTIONS_ERRORS);
    // source1 is out, source2 is waiting
    expect_sourceQueue([source2]);
  }

  void test_getNextResult_hasNormalAndPriority() {
    entry1.setState(ANALYSIS_OPTIONS_ERRORS, CacheState.INVALID);
    manager.sourceQueue.addAll([source1, source2]);
    manager.addPriorityResult(source3, ANALYSIS_OPTIONS_ERRORS);

    TargetedResult request = manager.getNextResult();
    expect(request.target, source3);
    expect(request.result, ANALYSIS_OPTIONS_ERRORS);
    // no changes until computed
    expect_sourceQueue([source1, source2]);
  }

  void test_getNextResult_hasPriority() {
    manager.addPriorityResult(source1, ANALYSIS_OPTIONS_ERRORS);
    manager.addPriorityResult(source2, ANALYSIS_OPTIONS_ERRORS);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source1, ANALYSIS_OPTIONS_ERRORS),
          new TargetedResult(source2, ANALYSIS_OPTIONS_ERRORS)
        ]));

    TargetedResult request = manager.getNextResult();
    expect(request.target, source1);
    expect(request.result, ANALYSIS_OPTIONS_ERRORS);
    // no changes until computed
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source1, ANALYSIS_OPTIONS_ERRORS),
          new TargetedResult(source2, ANALYSIS_OPTIONS_ERRORS)
        ]));
  }

  void test_getNextResult_nothingToDo() {
    TargetedResult request = manager.getNextResult();
    expect(request, isNull);
  }

  void test_getNextResultPriority_hasPriority() {
    manager.addPriorityResult(source1, SOURCE_KIND);
    expect(manager.getNextResultPriority(), WorkOrderPriority.PRIORITY);
  }

  void test_getNextResultPriority_hasSource() {
    manager.sourceQueue.addAll([source1]);
    expect(manager.getNextResultPriority(), WorkOrderPriority.NORMAL);
  }

  void test_getNextResultPriority_nothingToDo() {
    expect(manager.getNextResultPriority(), WorkOrderPriority.NONE);
  }

  void test_resultsComputed_errors() {
    AnalysisError error1 = new AnalysisError(
        source1, 1, 0, AnalysisOptionsErrorCode.PARSE_ERROR, ['']);
    AnalysisError error2 = new AnalysisError(
        source1, 2, 0, AnalysisOptionsErrorCode.PARSE_ERROR, ['']);
    LineInfo lineInfo = new LineInfo([0]);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1
        .setValue(ANALYSIS_OPTIONS_ERRORS, <AnalysisError>[error1, error2], []);
    // RESOLVED_UNIT is ready, set errors
    manager.resultsComputed(source1, {ANALYSIS_OPTIONS_ERRORS: null});
    // all of the errors are included
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.errors, unorderedEquals([error1, error2]));
    expect(notice.lineInfo, lineInfo);
  }
}

class _InternalAnalysisContextMock extends Mock
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
  AnalysisErrorInfo getErrors(Source source) {
    List<AnalysisError> errors = AnalysisError.NO_ERRORS;
    if (AnalysisEngine.isAnalysisOptionsFileName(source.shortName)) {
      errors = getCacheEntry(source).getValue(ANALYSIS_OPTIONS_ERRORS);
    }
    return new AnalysisErrorInfoImpl(
        errors, getCacheEntry(source).getValue(LINE_INFO));
  }

  @override
  ChangeNoticeImpl getNotice(Source source) =>
      _pendingNotices.putIfAbsent(source, () => new ChangeNoticeImpl(source));
}
