// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsImplTest);
    defineReflectiveTests(SourcesChangedEventTest);
  });
}

@reflectiveTest
class AnalysisOptionsImplTest {
  test_resetToDefaults() {
    // Note that this only tests options visible from the interface.
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    AnalysisOptionsImpl modifiedOptions = new AnalysisOptionsImpl();
    modifiedOptions.dart2jsHint = true;
    modifiedOptions.disableCacheFlushing = true;
    modifiedOptions.enabledPluginNames = ['somePackage'];
    modifiedOptions.enableLazyAssignmentOperators = true;
    modifiedOptions.enableTiming = true;
    modifiedOptions.errorProcessors = [null];
    modifiedOptions.excludePatterns = ['a'];
    modifiedOptions.generateImplicitErrors = false;
    modifiedOptions.generateSdkErrors = true;
    modifiedOptions.hint = false;
    modifiedOptions.lint = true;
    modifiedOptions.lintRules = [null];
    modifiedOptions.patchPaths = {
      'dart:core': ['/dart_core.patch.dart']
    };
    modifiedOptions.preserveComments = false;
    modifiedOptions.trackCacheDependencies = false;

    modifiedOptions.resetToDefaults();

    expect(modifiedOptions.dart2jsHint, defaultOptions.dart2jsHint);
    expect(modifiedOptions.disableCacheFlushing,
        defaultOptions.disableCacheFlushing);
    expect(modifiedOptions.enabledPluginNames, isEmpty);
    expect(modifiedOptions.enableLazyAssignmentOperators,
        defaultOptions.enableLazyAssignmentOperators);
    expect(modifiedOptions.enableTiming, defaultOptions.enableTiming);
    expect(modifiedOptions.errorProcessors, defaultOptions.errorProcessors);
    expect(modifiedOptions.excludePatterns, defaultOptions.excludePatterns);
    expect(modifiedOptions.generateImplicitErrors,
        defaultOptions.generateImplicitErrors);
    expect(modifiedOptions.generateSdkErrors, defaultOptions.generateSdkErrors);
    expect(modifiedOptions.hint, defaultOptions.hint);
    expect(modifiedOptions.lint, defaultOptions.lint);
    expect(modifiedOptions.lintRules, defaultOptions.lintRules);
    expect(modifiedOptions.patchPaths, defaultOptions.patchPaths);
    expect(modifiedOptions.preserveComments, defaultOptions.preserveComments);
    expect(modifiedOptions.trackCacheDependencies,
        defaultOptions.trackCacheDependencies);
  }
}

/**
 * A listener used to gather the [ImplicitAnalysisEvent]s that are produced
 * during analysis.
 */
class AnalyzedSourcesListener {
  /**
   * The events that have been gathered.
   */
  List<ImplicitAnalysisEvent> actualEvents = <ImplicitAnalysisEvent>[];

  /**
   * The sources that are being implicitly analyzed.
   */
  List<Source> analyzedSources = <Source>[];

  /**
   * Assert that the given source is currently being implicitly analyzed.
   */
  void expectAnalyzed(Source source) {
    expect(analyzedSources, contains(source));
  }

  /**
   * Assert that the given source is not currently being implicitly analyzed.
   */
  void expectNotAnalyzed(Source source) {
    expect(analyzedSources, isNot(contains(source)));
  }

  /**
   * Record that the given event was produced.
   */
  void onData(ImplicitAnalysisEvent event) {
    actualEvents.add(event);
    if (event.isAnalyzed) {
      analyzedSources.add(event.source);
    } else {
      analyzedSources.remove(event.source);
    }
  }
}

class MockSourceFactory extends SourceFactoryImpl {
  MockSourceFactory() : super([]);
  Source resolveUri(Source containingSource, String containedUri) {
    throw new UnimplementedError();
  }
}

@reflectiveTest
class SourcesChangedEventTest {
  void test_added() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.addedSource(source);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, wereSourcesAdded: true);
  }

  void test_changedContent() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.changedContent(source, 'library A;');
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, changedSources: [source]);
  }

  void test_changedContent2() {
    var source = new StringSource('', '/test.dart');
    var event = new SourcesChangedEvent.changedContent(source, 'library A;');
    assertEvent(event, changedSources: [source]);
  }

  void test_changedRange() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.changedRange(source, 'library A;', 0, 0, 13);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, changedSources: [source]);
  }

  void test_changedRange2() {
    var source = new StringSource('', '/test.dart');
    var event =
        new SourcesChangedEvent.changedRange(source, 'library A;', 0, 0, 13);
    assertEvent(event, changedSources: [source]);
  }

  void test_changedSources() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.changedSource(source);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, changedSources: [source]);
  }

  void test_empty() {
    var changeSet = new ChangeSet();
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event);
  }

  void test_removed() {
    var source = new StringSource('', '/test.dart');
    var changeSet = new ChangeSet();
    changeSet.removedSource(source);
    var event = new SourcesChangedEvent(changeSet);
    assertEvent(event, wereSourcesRemoved: true);
  }

  static void assertEvent(SourcesChangedEvent event,
      {bool wereSourcesAdded: false,
      List<Source> changedSources: const <Source>[],
      bool wereSourcesRemoved: false}) {
    expect(event.wereSourcesAdded, wereSourcesAdded);
    expect(event.changedSources, changedSources);
    expect(event.wereSourcesRemoved, wereSourcesRemoved);
  }
}

class SourcesChangedListener {
  List<SourcesChangedEvent> actualEvents = [];

  void assertEvent(
      {bool wereSourcesAdded: false,
      List<Source> changedSources: const <Source>[],
      bool wereSourcesRemovedOrDeleted: false}) {
    if (actualEvents.isEmpty) {
      fail('Expected event but found none');
    }
    SourcesChangedEvent actual = actualEvents.removeAt(0);
    SourcesChangedEventTest.assertEvent(actual,
        wereSourcesAdded: wereSourcesAdded,
        changedSources: changedSources,
        wereSourcesRemoved: wereSourcesRemovedOrDeleted);
  }

  void assertNoMoreEvents() {
    expect(actualEvents, []);
  }

  void onData(SourcesChangedEvent event) {
    actualEvents.add(event);
  }
}

/**
 * An analysis context in which almost every method will cause a test to fail
 * when invoked.
 */
class TestAnalysisContext implements InternalAnalysisContext {
  @override
  final ReentrantSynchronousStream<InvalidatedResult> onResultInvalidated =
      new ReentrantSynchronousStream<InvalidatedResult>();

  @override
  ResultProvider resultProvider;

  @override
  AnalysisCache get analysisCache {
    fail("Unexpected invocation of analysisCache");
  }

  @override
  AnalysisOptions get analysisOptions {
    fail("Unexpected invocation of getAnalysisOptions");
  }

  @override
  void set analysisOptions(AnalysisOptions options) {
    fail("Unexpected invocation of setAnalysisOptions");
  }

  @override
  void set analysisPriorityOrder(List<Source> sources) {
    fail("Unexpected invocation of setAnalysisPriorityOrder");
  }

  @override
  CacheConsistencyValidator get cacheConsistencyValidator {
    fail("Unexpected invocation of cacheConsistencyValidator");
  }

  @override
  set contentCache(ContentCache value) {
    fail("Unexpected invocation of setContentCache");
  }

  @override
  DeclaredVariables get declaredVariables {
    fail("Unexpected invocation of getDeclaredVariables");
  }

  @deprecated
  @override
  EmbedderYamlLocator get embedderYamlLocator {
    fail("Unexpected invocation of get embedderYamlLocator");
  }

  @override
  List<AnalysisTarget> get explicitTargets {
    fail("Unexpected invocation of visitCacheItems");
  }

  @override
  ResolverProvider get fileResolverProvider {
    fail("Unexpected invocation of fileResolverProvider");
  }

  @override
  void set fileResolverProvider(ResolverProvider resolverProvider) {
    fail("Unexpected invocation of fileResolverProvider");
  }

  @override
  List<Source> get htmlSources {
    fail("Unexpected invocation of getHtmlSources");
  }

  @override
  Stream<ImplicitAnalysisEvent> get implicitAnalysisEvents {
    fail("Unexpected invocation of analyzedSources");
  }

  bool get isActive {
    fail("Unexpected invocation of isActive");
  }

  void set isActive(bool isActive) {
    fail("Unexpected invocation of isActive");
  }

  @override
  bool get isDisposed {
    fail("Unexpected invocation of isDisposed");
  }

  @override
  List<Source> get launchableClientLibrarySources {
    fail("Unexpected invocation of getLaunchableClientLibrarySources");
  }

  @override
  List<Source> get launchableServerLibrarySources {
    fail("Unexpected invocation of getLaunchableServerLibrarySources");
  }

  @override
  List<Source> get librarySources {
    fail("Unexpected invocation of getLibrarySources");
  }

  @override
  String get name {
    fail("Unexpected invocation of name");
  }

  @override
  set name(String value) {
    fail("Unexpected invocation of name");
  }

  @override
  Stream<SourcesChangedEvent> get onSourcesChanged {
    fail("Unexpected invocation of onSourcesChanged");
  }

  @override
  List<Source> get prioritySources {
    fail("Unexpected invocation of getPrioritySources");
  }

  @override
  List<AnalysisTarget> get priorityTargets {
    fail("Unexpected invocation of visitCacheItems");
  }

  @override
  CachePartition get privateAnalysisCachePartition {
    fail("Unexpected invocation of privateAnalysisCachePartition");
  }

  @override
  SourceFactory get sourceFactory {
    fail("Unexpected invocation of getSourceFactory");
  }

  @override
  void set sourceFactory(SourceFactory factory) {
    fail("Unexpected invocation of setSourceFactory");
  }

  @override
  List<Source> get sources {
    fail("Unexpected invocation of sources");
  }

  @override
  TypeProvider get typeProvider {
    fail("Unexpected invocation of getTypeProvider");
  }

  @override
  void set typeProvider(TypeProvider typeProvider) {
    fail("Unexpected invocation of set typeProvider");
  }

  @override
  TypeSystem get typeSystem {
    fail("Unexpected invocation of getTypeSystem");
  }

  @override
  List<WorkManager> get workManagers {
    fail("Unexpected invocation of workManagers");
  }

  @override
  bool aboutToComputeResult(CacheEntry entry, ResultDescriptor result) {
    fail("Unexpected invocation of aboutToComputeResult");
  }

  @override
  void addListener(AnalysisListener listener) {
    fail("Unexpected invocation of addListener");
  }

  @override
  void applyAnalysisDelta(AnalysisDelta delta) {
    fail("Unexpected invocation of applyAnalysisDelta");
  }

  @override
  void applyChanges(ChangeSet changeSet) {
    fail("Unexpected invocation of applyChanges");
  }

  @override
  String computeDocumentationComment(Element element) {
    fail("Unexpected invocation of computeDocumentationComment");
  }

  @override
  List<AnalysisError> computeErrors(Source source) {
    fail("Unexpected invocation of computeErrors");
  }

  @override
  List<Source> computeExportedLibraries(Source source) {
    fail("Unexpected invocation of computeExportedLibraries");
  }

  @override
  List<Source> computeImportedLibraries(Source source) {
    fail("Unexpected invocation of computeImportedLibraries");
  }

  @override
  SourceKind computeKindOf(Source source) {
    fail("Unexpected invocation of computeKindOf");
  }

  @override
  LibraryElement computeLibraryElement(Source source) {
    fail("Unexpected invocation of computeLibraryElement");
  }

  @override
  LineInfo computeLineInfo(Source source) {
    fail("Unexpected invocation of computeLineInfo");
  }

  @override
  CancelableFuture<CompilationUnit> computeResolvedCompilationUnitAsync(
      Source source, Source librarySource) {
    fail("Unexpected invocation of getResolvedCompilationUnitFuture");
  }

  @override
  V computeResult<V>(AnalysisTarget target, ResultDescriptor<V> result) {
    fail("Unexpected invocation of computeResult");
  }

  @override
  void dispose() {
    fail("Unexpected invocation of dispose");
  }

  @override
  List<CompilationUnit> ensureResolvedDartUnits(Source source) {
    fail("Unexpected invocation of ensureResolvedDartUnits");
  }

  @override
  bool exists(Source source) {
    fail("Unexpected invocation of exists");
  }

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    fail("Unexpected invocation of visitCacheItems");
  }

  @override
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource) {
    fail("Unexpected invocation of getCompilationUnitElement");
  }

  @deprecated
  @override
  V getConfigurationData<V>(ResultDescriptor<V> key) {
    fail("Unexpected invocation of getConfigurationData");
  }

  @override
  TimestampedData<String> getContents(Source source) {
    fail("Unexpected invocation of getContents");
  }

  @override
  InternalAnalysisContext getContextFor(Source source) {
    fail("Unexpected invocation of getContextFor");
  }

  @override
  Element getElement(ElementLocation location) {
    fail("Unexpected invocation of getElement");
  }

  @override
  AnalysisErrorInfo getErrors(Source source) {
    fail("Unexpected invocation of getErrors");
  }

  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    fail("Unexpected invocation of getHtmlFilesReferencing");
  }

  @override
  SourceKind getKindOf(Source source) {
    fail("Unexpected invocation of getKindOf");
  }

  @override
  List<Source> getLibrariesContaining(Source source) {
    fail("Unexpected invocation of getLibrariesContaining");
  }

  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    fail("Unexpected invocation of getLibrariesDependingOn");
  }

  @override
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
    fail("Unexpected invocation of getLibrariesReferencedFromHtml");
  }

  @override
  LibraryElement getLibraryElement(Source source) {
    fail("Unexpected invocation of getLibraryElement");
  }

  @override
  LineInfo getLineInfo(Source source) {
    fail("Unexpected invocation of getLineInfo");
  }

  @override
  int getModificationStamp(Source source) {
    fail("Unexpected invocation of getModificationStamp");
  }

  @override
  ChangeNoticeImpl getNotice(Source source) {
    fail("Unexpected invocation of getNotice");
  }

  @override
  Namespace getPublicNamespace(LibraryElement library) {
    fail("Unexpected invocation of getPublicNamespace");
  }

  @override
  CompilationUnit getResolvedCompilationUnit(
      Source unitSource, LibraryElement library) {
    fail("Unexpected invocation of getResolvedCompilationUnit");
  }

  @override
  CompilationUnit getResolvedCompilationUnit2(
      Source unitSource, Source librarySource) {
    fail("Unexpected invocation of getResolvedCompilationUnit");
  }

  @override
  V getResult<V>(AnalysisTarget target, ResultDescriptor<V> result) {
    fail("Unexpected invocation of getResult");
  }

  @override
  List<Source> getSourcesWithFullName(String path) {
    fail("Unexpected invocation of getSourcesWithFullName");
  }

  @override
  bool handleContentsChanged(
      Source source, String originalContents, String newContents, bool notify) {
    fail("Unexpected invocation of handleContentsChanged");
  }

  @override
  void invalidateLibraryHints(Source librarySource) {
    fail("Unexpected invocation of invalidateLibraryHints");
  }

  @override
  bool isClientLibrary(Source librarySource) {
    fail("Unexpected invocation of isClientLibrary");
  }

  @override
  bool isServerLibrary(Source librarySource) {
    fail("Unexpected invocation of isServerLibrary");
  }

  @override
  Stream<ResultChangedEvent> onResultChanged(ResultDescriptor descriptor) {
    fail("Unexpected invocation of onResultChanged");
  }

  @deprecated
  @override
  Stream<ComputedResult> onResultComputed(ResultDescriptor descriptor) {
    fail("Unexpected invocation of onResultComputed");
  }

  @override
  CompilationUnit parseCompilationUnit(Source source) {
    fail("Unexpected invocation of parseCompilationUnit");
  }

  @override
  AnalysisResult performAnalysisTask() {
    fail("Unexpected invocation of performAnalysisTask");
  }

  @override
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    fail("Unexpected invocation of recordLibraryElements");
  }

  @override
  void removeListener(AnalysisListener listener) {
    fail("Unexpected invocation of removeListener");
  }

  @override
  CompilationUnit resolveCompilationUnit(
      Source unitSource, LibraryElement library) {
    fail("Unexpected invocation of resolveCompilationUnit");
  }

  @override
  CompilationUnit resolveCompilationUnit2(
      Source unitSource, Source librarySource) {
    fail("Unexpected invocation of resolveCompilationUnit");
  }

  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    fail("Unexpected invocation of setChangedContents");
  }

  @deprecated
  @override
  void setConfigurationData(ResultDescriptor key, Object data) {
    fail("Unexpected invocation of setConfigurationData");
  }

  @override
  void setContents(Source source, String contents) {
    fail("Unexpected invocation of setContents");
  }

  @override
  bool shouldErrorsBeAnalyzed(Source source) {
    fail("Unexpected invocation of shouldErrorsBeAnalyzed");
  }

  @override
  void test_flushAstStructures(Source source) {
    fail("Unexpected invocation of test_flushAstStructures");
  }

  @override
  void visitContentCache(ContentCacheVisitor visitor) {
    fail("Unexpected invocation of visitContentCache");
  }
}
