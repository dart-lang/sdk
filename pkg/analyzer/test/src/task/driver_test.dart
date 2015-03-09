// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.driver_test;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import 'test_support.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisDriverTest);
  runReflectiveTests(WorkOrderTest);
  runReflectiveTests(WorkItemTest);
}

@reflectiveTest
class AnalysisDriverTest extends EngineTestCase {
  TaskManager manager;
  _TestContext context;
  AnalysisDriver driver;

  void setUp() {
    manager = new TaskManager();
    context = new _TestContext();
    driver = new AnalysisDriver(manager, context);
  }

  test_computeResult() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target, descriptor: descriptor);
    manager.addTaskDescriptor(descriptor);

    driver.computeResult(target, result);
    expect(context.getCacheEntry(target).getValue(result), 1);
  }

  test_create() {
    expect(driver, isNotNull);
    expect(driver.context, context);
    expect(driver.currentWorkOrder, isNull);
    expect(driver.taskManager, manager);
  }

  test_createNextWorkOrder_complete() {
    AnalysisTarget priorityTarget = new TestSource();
    AnalysisTarget normalTarget = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    manager.addGeneralResult(result);
    manager.addTaskDescriptor(descriptor);
    context.priorityTargets.add(priorityTarget);
    context.getCacheEntry(priorityTarget).setValue(result, '');
    context.explicitTargets.add(normalTarget);
    context.getCacheEntry(priorityTarget).setValue(result, '');

    expect(driver.createNextWorkOrder(), isNull);
  }

  test_createNextWorkOrder_normalTarget() {
    AnalysisTarget priorityTarget = new TestSource();
    AnalysisTarget normalTarget = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    manager.addGeneralResult(result);
    manager.addTaskDescriptor(descriptor);
    context.priorityTargets.add(priorityTarget);
    context.getCacheEntry(priorityTarget).setValue(result, '');
    context.explicitTargets.add(normalTarget);
    context.getCacheEntry(normalTarget).setState(result, CacheState.INVALID);

    WorkOrder workOrder = driver.createNextWorkOrder();
    expect(workOrder, isNotNull);
    expect(workOrder.moveNext(), true);
    expect(workOrder.currentItem.target, normalTarget);
  }

  test_createNextWorkOrder_noTargets() {
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    manager.addGeneralResult(result);
    manager.addTaskDescriptor(descriptor);

    expect(driver.createNextWorkOrder(), isNull);
  }

  test_createNextWorkOrder_priorityTarget() {
    AnalysisTarget priorityTarget = new TestSource();
    AnalysisTarget normalTarget = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    manager.addGeneralResult(result);
    manager.addTaskDescriptor(descriptor);
    context.priorityTargets.add(priorityTarget);
    context.getCacheEntry(priorityTarget).setState(result, CacheState.INVALID);
    context.explicitTargets.add(normalTarget);
    context.getCacheEntry(normalTarget).setState(result, CacheState.INVALID);

    WorkOrder workOrder = driver.createNextWorkOrder();
    expect(workOrder, isNotNull);
    expect(workOrder.moveNext(), true);
    expect(workOrder.currentItem.target, priorityTarget);
  }

  test_createWorkOrderForResult_error() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    CaughtException exception = new CaughtException(null, null);
    context
        .getCacheEntry(target)
        .setErrorState(exception, <ResultDescriptor>[result]);

    expect(driver.createWorkOrderForResult(target, result), isNull);
  }

  test_createWorkOrderForResult_inProcess() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    context.getCacheEntry(target).setState(result, CacheState.IN_PROCESS);

    expect(driver.createWorkOrderForResult(target, result), isNull);
  }

  test_createWorkOrderForResult_invalid() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    manager.addTaskDescriptor(descriptor);
    context.getCacheEntry(target).setState(result, CacheState.INVALID);

    WorkOrder workOrder = driver.createWorkOrderForResult(target, result);
    expect(workOrder, isNotNull);
  }

  test_createWorkOrderForResult_valid() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    context.getCacheEntry(target).setValue(result, '');

    expect(driver.createWorkOrderForResult(target, result), isNull);
  }

  test_createWorkOrderForTarget_complete_generalTarget_generalResult() {
    _createWorkOrderForTarget(true, false, false);
  }

  test_createWorkOrderForTarget_complete_generalTarget_priorityResult() {
    _createWorkOrderForTarget(true, false, true);
  }

  test_createWorkOrderForTarget_complete_priorityTarget_generalResult() {
    _createWorkOrderForTarget(true, true, false);
  }

  test_createWorkOrderForTarget_complete_priorityTarget_priorityResult() {
    _createWorkOrderForTarget(true, true, true);
  }

  test_createWorkOrderForTarget_incomplete_generalTarget_generalResult() {
    _createWorkOrderForTarget(false, false, false);
  }

  test_createWorkOrderForTarget_incomplete_generalTarget_priorityResult() {
    _createWorkOrderForTarget(false, false, true);
  }

  test_createWorkOrderForTarget_incomplete_priorityTarget_generalResult() {
    _createWorkOrderForTarget(false, true, false);
  }

  test_createWorkOrderForTarget_incomplete_priorityTarget_priorityResult() {
    _createWorkOrderForTarget(false, true, true);
  }

  test_performAnalysisTask() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target, descriptor: descriptor);
    manager.addTaskDescriptor(descriptor);
    manager.addGeneralResult(result);
    context.priorityTargets.add(target);

    expect(driver.performAnalysisTask(), true);
    expect(driver.performAnalysisTask(), true);
    expect(driver.performAnalysisTask(), false);
  }

  test_performAnalysisTask_inputsFirst() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor resultA = new ResultDescriptor('resultA', -1);
    ResultDescriptor resultB = new ResultDescriptor('resultB', -2);
    // configure tasks
    TestAnalysisTask task1;
    TestAnalysisTask task2;
    TaskDescriptor descriptor1 = new TaskDescriptor(
        'task1', (context, target) => task1, (target) => {}, [resultA]);
    TaskDescriptor descriptor2 = new TaskDescriptor('task2',
        (context, target) => task2,
        (target) => {'inputA': new SimpleTaskInput<int>(target, resultA)}, [
      resultB
    ]);
    task1 = new TestAnalysisTask(context, target,
        descriptor: descriptor1, results: [resultA], value: 10);
    task2 = new TestAnalysisTask(context, target,
        descriptor: descriptor2, value: 20);
    manager.addTaskDescriptor(descriptor1);
    manager.addTaskDescriptor(descriptor2);
    context.explicitTargets.add(target);
    manager.addGeneralResult(resultB);
    // prepare work order
    expect(driver.performAnalysisTask(), true);
    expect(context.getCacheEntry(target).getValue(resultA), -1);
    expect(context.getCacheEntry(target).getValue(resultB), -2);
    // compute resultA
    expect(driver.performAnalysisTask(), true);
    expect(context.getCacheEntry(target).getValue(resultA), 10);
    expect(context.getCacheEntry(target).getValue(resultB), -2);
    // compute resultB
    expect(driver.performAnalysisTask(), true);
    expect(context.getCacheEntry(target).getValue(resultA), 10);
    expect(context.getCacheEntry(target).getValue(resultB), 20);
    // done
    expect(driver.performAnalysisTask(), false);
  }

  test_performWorkItem_exceptionInTask() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    CaughtException exception =
        new CaughtException(new AnalysisException(), null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target,
        descriptor: descriptor, exception: exception);
    WorkItem item = new WorkItem(context, target, descriptor);

    driver.performWorkItem(item);
    CacheEntry targetEntry = context.getCacheEntry(item.target);
    expect(targetEntry.exception, exception);
    expect(targetEntry.getState(result), CacheState.ERROR);
  }

  test_performWorkItem_noException() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TestAnalysisTask task;
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', (context, target) => task, (target) => {}, [result]);
    task = new TestAnalysisTask(context, target, descriptor: descriptor);
    WorkItem item = new WorkItem(context, target, descriptor);

    driver.performWorkItem(item);
    CacheEntry targetEntry = context.getCacheEntry(item.target);
    expect(targetEntry.exception, isNull);
    expect(targetEntry.getState(result), CacheState.VALID);
  }

  test_performWorkItem_preExistingException() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    CaughtException exception =
        new CaughtException(new AnalysisException(), null);
    WorkItem item = new WorkItem(context, target, descriptor);
    item.exception = exception;

    driver.performWorkItem(item);
    CacheEntry targetEntry = context.getCacheEntry(item.target);
    expect(targetEntry.exception, exception);
    expect(targetEntry.getState(result), CacheState.ERROR);
  }

  test_reset() {
    ResultDescriptor inputResult = new ResultDescriptor('input', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {'one': inputResult.inputFor(target)}, [
      new ResultDescriptor('output', null)
    ]);
    driver.currentWorkOrder =
        new WorkOrder(manager, new WorkItem(null, null, descriptor));

    driver.reset();
    expect(driver.currentWorkOrder, isNull);
  }

  /**
   * [complete] is `true` if the value of the result has already been computed.
   * [priorityTarget] is `true` if the target is in the list of priority
   * targets.
   * [priorityResult] is `true` if the result should only be computed for
   * priority targets.
   */
  _createWorkOrderForTarget(
      bool complete, bool priorityTarget, bool priorityResult) {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('result', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [result]);
    if (priorityResult) {
      manager.addPriorityResult(result);
    } else {
      manager.addGeneralResult(result);
    }
    manager.addTaskDescriptor(descriptor);
    if (priorityTarget) {
      context.priorityTargets.add(target);
    } else {
      context.explicitTargets.add(target);
    }
    if (complete) {
      context.getCacheEntry(target).setValue(result, '');
    } else {
      context.getCacheEntry(target).setState(result, CacheState.INVALID);
    }

    WorkOrder workOrder =
        driver.createWorkOrderForTarget(target, priorityTarget);
    if (complete) {
      expect(workOrder, isNull);
    } else if (priorityResult) {
      expect(workOrder, priorityTarget ? isNotNull : isNull);
    } else {
      expect(workOrder, isNotNull);
    }
  }
}

@reflectiveTest
class WorkItemTest extends EngineTestCase {
  test_buildTask_complete() {
    AnalysisContext context = new _TestContext();
    AnalysisTarget target = new TestSource();
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [new ResultDescriptor('output', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    AnalysisTask task = item.buildTask();
    expect(task, isNotNull);
  }

  test_buildTask_incomplete() {
    AnalysisContext context = new _TestContext();
    AnalysisTarget target = new TestSource();
    ResultDescriptor inputResult = new ResultDescriptor('input', null);
    List<ResultDescriptor> outputResults = <ResultDescriptor>[
      new ResultDescriptor('output', null)
    ];
    TaskDescriptor descriptor = new TaskDescriptor('task', (context, target) =>
            new TestAnalysisTask(context, target, results: outputResults),
        (target) => {'one': inputResult.inputFor(target)}, outputResults);
    WorkItem item = new WorkItem(context, target, descriptor);
    expect(() => item.buildTask(), throwsStateError);
  }

  test_create() {
    AnalysisContext context = new _TestContext();
    AnalysisTarget target = new TestSource();
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', null, (target) => {}, [new ResultDescriptor('result', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    expect(item, isNotNull);
    expect(item.context, context);
    expect(item.descriptor, descriptor);
    expect(item.target, target);
  }

  test_gatherInputs_complete() {
    TaskManager manager = new TaskManager();
    AnalysisContext context = new _TestContext();
    AnalysisTarget target = new TestSource();
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {}, [new ResultDescriptor('output', null)]);
    WorkItem item = new WorkItem(context, target, descriptor);
    WorkItem result = item.gatherInputs(manager);
    expect(result, isNull);
    expect(item.exception, isNull);
  }

  test_gatherInputs_incomplete() {
    TaskManager manager = new TaskManager();
    AnalysisContext context = new _TestContext();
    AnalysisTarget target = new TestSource();
    ResultDescriptor resultA = new ResultDescriptor('resultA', null);
    ResultDescriptor resultB = new ResultDescriptor('resultB', null);
    TaskDescriptor task1 = new TaskDescriptor('task', (context, target) =>
            new TestAnalysisTask(context, target, results: [resultA]),
        (target) => {}, [resultA]);
    TaskDescriptor task2 = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {'one': resultA.inputFor(target)}, [resultB]);
    manager.addTaskDescriptor(task1);
    manager.addTaskDescriptor(task2);
    WorkItem item = new WorkItem(context, target, task2);
    expect(item.gatherInputs(manager), isNotNull);
  }

  test_gatherInputs_invalid() {
    TaskManager manager = new TaskManager();
    AnalysisContext context = new _TestContext();
    AnalysisTarget target = new TestSource();
    ResultDescriptor inputResult = new ResultDescriptor('input', null);
    TaskDescriptor descriptor = new TaskDescriptor('task',
        (context, target) => new TestAnalysisTask(context, target),
        (target) => {'one': inputResult.inputFor(target)}, [
      new ResultDescriptor('output', null)
    ]);
    WorkItem item = new WorkItem(context, target, descriptor);
    WorkItem result = item.gatherInputs(manager);
    expect(result, isNull);
    expect(item.exception, isNotNull);
  }
}

@reflectiveTest
class WorkOrderTest extends EngineTestCase {
  test_create() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', null, (_) => {}, [new ResultDescriptor('result', null)]);
    WorkOrder order =
        new WorkOrder(manager, new WorkItem(null, null, descriptor));
    expect(order, isNotNull);
    expect(order.currentItem, isNull);
    expect(order.pendingItems, hasLength(1));
    expect(order.taskManager, manager);
  }

  test_moveNext() {
    TaskManager manager = new TaskManager();
    TaskDescriptor descriptor = new TaskDescriptor(
        'task', null, (_) => {}, [new ResultDescriptor('result', null)]);
    WorkItem workItem = new WorkItem(null, null, descriptor);
    WorkOrder order = new WorkOrder(manager, workItem);
    // "item" has no child items
    expect(order.moveNext(), isTrue);
    expect(order.current, workItem);
    // done
    expect(order.moveNext(), isFalse);
    expect(order.current, isNull);
  }
}

class _TestContext implements ExtendedAnalysisContext {
  InternalAnalysisContext baseContext =
      AnalysisContextFactory.contextWithCore();

  @override
  List<AnalysisTarget> explicitTargets = <AnalysisTarget>[];

  Map<AnalysisTarget, CacheEntry> entryMap =
      new HashMap<AnalysisTarget, CacheEntry>();

  @override
  List<AnalysisTarget> priorityTargets = <AnalysisTarget>[];

  String name = 'Test Context';

  _TestContext();

  AnalysisOptions get analysisOptions => baseContext.analysisOptions;

  void set analysisOptions(AnalysisOptions options) {
    baseContext.analysisOptions = options;
  }

  @override
  void set analysisPriorityOrder(List<Source> sources) {
    baseContext.analysisPriorityOrder = sources;
  }

  @override
  set contentCache(ContentCache value) {
    baseContext.contentCache = value;
  }

  @override
  DeclaredVariables get declaredVariables => baseContext.declaredVariables;

  @override
  List<Source> get htmlSources => baseContext.htmlSources;

  @override
  bool get isDisposed => baseContext.isDisposed;

  @override
  List<Source> get launchableClientLibrarySources =>
      baseContext.launchableClientLibrarySources;

  @override
  List<Source> get launchableServerLibrarySources =>
      baseContext.launchableServerLibrarySources;

  @override
  List<Source> get librarySources => baseContext.librarySources;

  @override
  Stream<SourcesChangedEvent> get onSourcesChanged =>
      baseContext.onSourcesChanged;

  @override
  List<Source> get prioritySources => baseContext.prioritySources;

  @override
  List<Source> get refactoringUnsafeSources =>
      baseContext.refactoringUnsafeSources;

  @override
  ResolverVisitorFactory get resolverVisitorFactory =>
      baseContext.resolverVisitorFactory;

  SourceFactory get sourceFactory => baseContext.sourceFactory;

  void set sourceFactory(SourceFactory factory) {
    baseContext.sourceFactory = factory;
  }

  @override
  AnalysisContextStatistics get statistics => baseContext.statistics;

  @override
  TypeProvider get typeProvider => baseContext.typeProvider;

  @override
  TypeResolverVisitorFactory get typeResolverVisitorFactory =>
      baseContext.typeResolverVisitorFactory;

  @override
  void addListener(AnalysisListener listener) {
    baseContext.addListener(listener);
  }

  @override
  void addSourceInfo(Source source, SourceEntry info) {
    baseContext.addSourceInfo(source, info);
  }

  @override
  void applyAnalysisDelta(AnalysisDelta delta) {
    baseContext.applyAnalysisDelta(delta);
  }

  @override
  void applyChanges(ChangeSet changeSet) {
    baseContext.applyChanges(changeSet);
  }

  @override
  String computeDocumentationComment(Element element) {
    return baseContext.computeDocumentationComment(element);
  }

  @override
  List<AnalysisError> computeErrors(Source source) {
    return baseContext.computeErrors(source);
  }

  @override
  List<Source> computeExportedLibraries(Source source) {
    return baseContext.computeExportedLibraries(source);
  }

  @override
  HtmlElement computeHtmlElement(Source source) {
    return baseContext.computeHtmlElement(source);
  }

  @override
  List<Source> computeImportedLibraries(Source source) {
    return baseContext.computeImportedLibraries(source);
  }

  @override
  SourceKind computeKindOf(Source source) {
    return baseContext.computeKindOf(source);
  }

  @override
  LibraryElement computeLibraryElement(Source source) {
    return baseContext.computeLibraryElement(source);
  }

  @override
  LineInfo computeLineInfo(Source source) {
    return baseContext.computeLineInfo(source);
  }

  @override
  CompilationUnit computeResolvableCompilationUnit(Source source) {
    return baseContext.computeResolvableCompilationUnit(source);
  }

  @override
  CancelableFuture<CompilationUnit> computeResolvedCompilationUnitAsync(
      Source source, Source librarySource) {
    return baseContext.computeResolvedCompilationUnitAsync(
        source, librarySource);
  }

  @override
  void dispose() {
    baseContext.dispose();
  }

  @override
  List<CompilationUnit> ensureResolvedDartUnits(Source source) {
    return baseContext.ensureResolvedDartUnits(source);
  }

  @override
  bool exists(Source source) {
    return baseContext.exists(source);
  }

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    return entryMap.putIfAbsent(target, () => new CacheEntry());
  }

  @override
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource) {
    return baseContext.getCompilationUnitElement(unitSource, librarySource);
  }

  @override
  TimestampedData<String> getContents(Source source) {
    return baseContext.getContents(source);
  }

  @override
  InternalAnalysisContext getContextFor(Source source) {
    return baseContext.getContextFor(source);
  }

  @override
  Element getElement(ElementLocation location) {
    return baseContext.getElement(location);
  }

  @override
  AnalysisErrorInfo getErrors(Source source) {
    return baseContext.getErrors(source);
  }

  @override
  HtmlElement getHtmlElement(Source source) {
    return baseContext.getHtmlElement(source);
  }

  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    return baseContext.getHtmlFilesReferencing(source);
  }

  @override
  SourceKind getKindOf(Source source) {
    return baseContext.getKindOf(source);
  }

  @override
  List<Source> getLibrariesContaining(Source source) {
    return baseContext.getLibrariesContaining(source);
  }

  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    return baseContext.getLibrariesDependingOn(librarySource);
  }

  @override
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
    return baseContext.getLibrariesReferencedFromHtml(htmlSource);
  }

  @override
  LibraryElement getLibraryElement(Source source) {
    return baseContext.getLibraryElement(source);
  }

  @override
  LineInfo getLineInfo(Source source) {
    return baseContext.getLineInfo(source);
  }

  @override
  int getModificationStamp(Source source) {
    return baseContext.getModificationStamp(source);
  }

  @override
  Namespace getPublicNamespace(LibraryElement library) {
    return baseContext.getPublicNamespace(library);
  }

  @override
  CompilationUnit getResolvedCompilationUnit(
      Source unitSource, LibraryElement library) {
    return baseContext.getResolvedCompilationUnit(unitSource, library);
  }

  @override
  CompilationUnit getResolvedCompilationUnit2(
      Source unitSource, Source librarySource) {
    return baseContext.getResolvedCompilationUnit2(unitSource, librarySource);
  }

  @override
  HtmlUnit getResolvedHtmlUnit(Source htmlSource) {
    return baseContext.getResolvedHtmlUnit(htmlSource);
  }

  @override
  bool handleContentsChanged(
      Source source, String originalContents, String newContents, bool notify) {
    return baseContext.handleContentsChanged(
        source, originalContents, newContents, notify);
  }

  @override
  bool isClientLibrary(Source librarySource) {
    return baseContext.isClientLibrary(librarySource);
  }

  @override
  bool isServerLibrary(Source librarySource) {
    return baseContext.isServerLibrary(librarySource);
  }

  @override
  CompilationUnit parseCompilationUnit(Source source) {
    return baseContext.parseCompilationUnit(source);
  }

  @override
  HtmlUnit parseHtmlUnit(Source source) {
    return baseContext.parseHtmlUnit(source);
  }

  @override
  AnalysisResult performAnalysisTask() {
    return baseContext.performAnalysisTask();
  }

  @override
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    baseContext.recordLibraryElements(elementMap);
  }

  @override
  void removeListener(AnalysisListener listener) {
    baseContext.removeListener(listener);
  }

  @override
  CompilationUnit resolveCompilationUnit(
      Source unitSource, LibraryElement library) {
    return baseContext.resolveCompilationUnit(unitSource, library);
  }

  @override
  CompilationUnit resolveCompilationUnit2(
      Source unitSource, Source librarySource) {
    return baseContext.resolveCompilationUnit2(unitSource, librarySource);
  }

  @override
  HtmlUnit resolveHtmlUnit(Source htmlSource) {
    return baseContext.resolveHtmlUnit(htmlSource);
  }

  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    baseContext.setChangedContents(
        source, contents, offset, oldLength, newLength);
  }

  @override
  void setContents(Source source, String contents) {
    baseContext.setContents(source, contents);
  }

  @override
  void visitCacheItems(void callback(Source source, SourceEntry dartEntry,
      DataDescriptor rowDesc, CacheState state)) {
    baseContext.visitCacheItems(callback);
  }
}
