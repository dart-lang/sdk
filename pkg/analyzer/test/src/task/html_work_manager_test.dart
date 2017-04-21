// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.html_work_manager_test;

import 'package:analyzer/error/error.dart' show AnalysisError;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/error/codes.dart' show HtmlErrorCode;
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisEngine,
        AnalysisErrorInfo,
        AnalysisErrorInfoImpl,
        CacheState,
        ChangeNoticeImpl,
        InternalAnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/src/task/html_work_manager.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HtmlWorkManagerTest);
    defineReflectiveTests(HtmlWorkManagerIntegrationTest);
  });
}

@reflectiveTest
class HtmlWorkManagerTest {
  InternalAnalysisContext context = new _InternalAnalysisContextMock();
  AnalysisCache cache;
  HtmlWorkManager manager;

  CaughtException caughtException = new CaughtException(null, null);

  Source source1 = new TestSource('1.html');
  Source source2 = new TestSource('2.html');
  Source source3 = new TestSource('3.html');
  Source source4 = new TestSource('4.html');
  CacheEntry entry1;
  CacheEntry entry2;
  CacheEntry entry3;
  CacheEntry entry4;

  void expect_sourceQueue(List<Source> sources) {
    expect(manager.sourceQueue, unorderedEquals(sources));
  }

  void setUp() {
    cache = context.analysisCache;
    manager = new HtmlWorkManager(context);
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
    manager.priorityResultQueue.add(new TargetedResult(source1, HTML_ERRORS));
    manager.priorityResultQueue.add(new TargetedResult(source2, HTML_ERRORS));
    // -source1 +source3
    manager.applyPriorityTargets([source2, source3]);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source2, HTML_ERRORS),
          new TargetedResult(source3, HTML_ERRORS)
        ]));
    // get next request
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, HTML_ERRORS);
  }

  void test_getErrors_fullList() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, HtmlErrorCode.PARSE_ERROR, ['']);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, HtmlErrorCode.PARSE_ERROR, ['']);
    entry1.setValue(HTML_DOCUMENT_ERRORS, <AnalysisError>[error1], []);

    DartScript script = new DartScript(source1, []);
    entry1.setValue(DART_SCRIPTS, [script], []);
    CacheEntry scriptEntry = context.getCacheEntry(script);
    scriptEntry.setValue(DART_ERRORS, [error2], []);

    List<AnalysisError> errors = manager.getErrors(source1);
    expect(errors, unorderedEquals([error1, error2]));
  }

  void test_getErrors_partialList() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, HtmlErrorCode.PARSE_ERROR, ['']);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, HtmlErrorCode.PARSE_ERROR, ['']);
    entry1.setValue(HTML_DOCUMENT_ERRORS, <AnalysisError>[error1, error2], []);

    List<AnalysisError> errors = manager.getErrors(source1);
    expect(errors, unorderedEquals([error1, error2]));
  }

  void test_getNextResult_hasNormal_firstIsError() {
    entry1.setErrorState(caughtException, [HTML_ERRORS]);
    manager.sourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, HTML_ERRORS);
    // source1 is out, source2 is waiting
    expect_sourceQueue([source2]);
  }

  void test_getNextResult_hasNormal_firstIsInvalid() {
    entry1.setState(HTML_ERRORS, CacheState.INVALID);
    manager.sourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source1);
    expect(request.result, HTML_ERRORS);
    // no changes until computed
    expect_sourceQueue([source1, source2]);
  }

  void test_getNextResult_hasNormal_firstIsValid() {
    entry1.setValue(HTML_ERRORS, [], []);
    manager.sourceQueue.addAll([source1, source2]);
    TargetedResult request = manager.getNextResult();
    expect(request.target, source2);
    expect(request.result, HTML_ERRORS);
    // source1 is out, source2 is waiting
    expect_sourceQueue([source2]);
  }

  void test_getNextResult_hasNormalAndPriority() {
    entry1.setState(HTML_ERRORS, CacheState.INVALID);
    manager.sourceQueue.addAll([source1, source2]);
    manager.addPriorityResult(source3, HTML_ERRORS);

    TargetedResult request = manager.getNextResult();
    expect(request.target, source3);
    expect(request.result, HTML_ERRORS);
    // no changes until computed
    expect_sourceQueue([source1, source2]);
  }

  void test_getNextResult_hasPriority() {
    manager.addPriorityResult(source1, HTML_ERRORS);
    manager.addPriorityResult(source2, HTML_ERRORS);
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source1, HTML_ERRORS),
          new TargetedResult(source2, HTML_ERRORS)
        ]));

    TargetedResult request = manager.getNextResult();
    expect(request.target, source1);
    expect(request.result, HTML_ERRORS);
    // no changes until computed
    expect(
        manager.priorityResultQueue,
        unorderedEquals([
          new TargetedResult(source1, HTML_ERRORS),
          new TargetedResult(source2, HTML_ERRORS)
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

  void test_onAnalysisOptionsChanged() {
    when(context.exists(anyObject)).thenReturn(true);
    // set cache values
    entry1.setValue(DART_SCRIPTS, [], []);
    entry1.setValue(HTML_DOCUMENT, null, []);
    entry1.setValue(HTML_DOCUMENT_ERRORS, [], []);
    entry1.setValue(HTML_ERRORS, [], []);
    entry1.setValue(REFERENCED_LIBRARIES, [], []);
    // notify
    manager.onAnalysisOptionsChanged();
    // Only resolution-based values are invalidated.
    expect(entry1.getState(DART_SCRIPTS), CacheState.VALID);
    expect(entry1.getState(HTML_DOCUMENT), CacheState.VALID);
    expect(entry1.getState(HTML_DOCUMENT_ERRORS), CacheState.VALID);
    expect(entry1.getState(HTML_ERRORS), CacheState.INVALID);
    expect(entry1.getState(REFERENCED_LIBRARIES), CacheState.VALID);
  }

  void test_onResultInvalidated_scheduleInvalidatedLibraries() {
    // set HTML_ERRORS for source1 and source3
    entry1.setValue(HTML_ERRORS, [], []);
    entry3.setValue(HTML_ERRORS, [], []);
    // invalidate HTML_ERRORS for source1, schedule it
    entry1.setState(HTML_ERRORS, CacheState.INVALID);
    expect_sourceQueue([source1]);
    // invalidate HTML_ERRORS for source3, schedule it
    entry3.setState(HTML_ERRORS, CacheState.INVALID);
    expect_sourceQueue([source1, source3]);
  }

  void test_onSourceFactoryChanged() {
    when(context.exists(anyObject)).thenReturn(true);
    // set cache values
    entry1.setValue(DART_SCRIPTS, [], []);
    entry1.setValue(HTML_DOCUMENT, null, []);
    entry1.setValue(HTML_DOCUMENT_ERRORS, [], []);
    entry1.setValue(HTML_ERRORS, [], []);
    entry1.setValue(REFERENCED_LIBRARIES, [], []);
    // notify
    manager.onSourceFactoryChanged();
    // Only resolution-based values are invalidated.
    expect(entry1.getState(DART_SCRIPTS), CacheState.VALID);
    expect(entry1.getState(HTML_DOCUMENT), CacheState.VALID);
    expect(entry1.getState(HTML_DOCUMENT_ERRORS), CacheState.VALID);
    expect(entry1.getState(HTML_ERRORS), CacheState.INVALID);
    expect(entry1.getState(REFERENCED_LIBRARIES), CacheState.INVALID);
  }

  void test_resultsComputed_errors() {
    AnalysisError error1 =
        new AnalysisError(source1, 1, 0, HtmlErrorCode.PARSE_ERROR, ['']);
    AnalysisError error2 =
        new AnalysisError(source1, 2, 0, HtmlErrorCode.PARSE_ERROR, ['']);
    LineInfo lineInfo = new LineInfo([0]);
    entry1.setValue(LINE_INFO, lineInfo, []);
    entry1.setValue(HTML_ERRORS, <AnalysisError>[error1, error2], []);
    // RESOLVED_UNIT is ready, set errors
    manager.resultsComputed(source1, {HTML_ERRORS: null});
    // all of the errors are included
    ChangeNoticeImpl notice = context.getNotice(source1);
    expect(notice.errors, unorderedEquals([error1, error2]));
    expect(notice.lineInfo, lineInfo);
  }
}

@reflectiveTest
class HtmlWorkManagerIntegrationTest {
  InternalAnalysisContext context = new AnalysisContextImpl();
  HtmlWorkManager manager;

  Source source1 = new TestSource('1.html');
  Source source2 = new TestSource('2.html');
  CacheEntry entry1;
  CacheEntry entry2;

  void expect_sourceQueue(List<Source> sources) {
    expect(manager.sourceQueue, unorderedEquals(sources));
  }

  void setUp() {
    manager = new HtmlWorkManager(context);
    entry1 = context.getCacheEntry(source1);
    entry2 = context.getCacheEntry(source2);
  }

  void
      test_onResultInvalidated_scheduleInvalidatedLibrariesAfterSetSourceFactory() {
    // Change the source factory, changing the analysis cache from when
    // the work manager was constructed. This used to create a failure
    // case for test_onResultInvalidated_scheduleInvalidLibraries so its
    // tested here.
    context.sourceFactory = new _SourceFactoryMock();

    // now just do the same checks as
    // test_onResultInvalidated_scheduleInvalidLibraries

    // set HTML_ERRORS for source1 and source2
    entry1.setValue(HTML_ERRORS, [], []);
    entry2.setValue(HTML_ERRORS, [], []);
    // invalidate HTML_ERRORS for source1, schedule it
    entry1.setState(HTML_ERRORS, CacheState.INVALID);
    expect_sourceQueue([source1]);
    // invalidate HTML_ERRORS for source2, schedule it
    entry2.setState(HTML_ERRORS, CacheState.INVALID);
    expect_sourceQueue([source1, source2]);
  }
}

class _SourceFactoryMock extends TypedMock implements SourceFactory {}

class _InternalAnalysisContextMock extends TypedMock
    implements InternalAnalysisContext {
  @override
  CachePartition privateAnalysisCachePartition;

  @override
  AnalysisCache analysisCache;

  // The production version is a stream that carries messages from the cache
  // since the cache changes. Here, we can just pass the inner stream because
  // it doesn't change.
  @override
  get onResultInvalidated => analysisCache.onResultInvalidated;

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
    String name = source.shortName;
    List<AnalysisError> errors = AnalysisError.NO_ERRORS;
    if (AnalysisEngine.isDartFileName(name) || source is DartScript) {
      errors = getCacheEntry(source).getValue(DART_ERRORS);
    } else if (AnalysisEngine.isHtmlFileName(name)) {
      errors = getCacheEntry(source).getValue(HTML_ERRORS);
    }
    return new AnalysisErrorInfoImpl(
        errors, getCacheEntry(source).getValue(LINE_INFO));
  }

  @override
  ChangeNoticeImpl getNotice(Source source) {
    return _pendingNotices.putIfAbsent(
        source, () => new ChangeNoticeImpl(source));
  }
}
