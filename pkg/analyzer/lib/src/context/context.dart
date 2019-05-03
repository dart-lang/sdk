// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/driver.dart';

/**
 * An [AnalysisContext] in which analysis can be performed.
 */
class AnalysisContextImpl implements InternalAnalysisContext {
  /**
   * A client-provided name used to identify this context, or `null` if the
   * client has not provided a name.
   */
  @override
  String name;

  /**
   * The set of analysis options controlling the behavior of this context.
   */
  AnalysisOptionsImpl _options = new AnalysisOptionsImpl();

  /**
   * The source factory used to create the sources that can be analyzed in this
   * context.
   */
  SourceFactory _sourceFactory;

  /**
   * The set of declared variables used when computing constant values.
   */
  DeclaredVariables _declaredVariables = new DeclaredVariables();

  @override
  final ReentrantSynchronousStream<InvalidatedResult> onResultInvalidated =
      new ReentrantSynchronousStream<InvalidatedResult>();

  ReentrantSynchronousStreamSubscription onResultInvalidatedSubscription = null;

  /**
   * A list of all [WorkManager]s used by this context.
   */
  @override
  final List<WorkManager> workManagers = <WorkManager>[];

  /**
   * The analysis driver used to perform analysis.
   */
  AnalysisDriver driver;

  /**
   * The [TypeProvider] for this context, `null` if not yet created.
   */
  TypeProvider _typeProvider;

  /**
   * The [TypeSystem] for this context, `null` if not yet created.
   */
  TypeSystem _typeSystem;

  /**
   * Determines whether this context should attempt to make use of the global
   * SDK cache partition. Note that if this context is responsible for
   * resynthesizing the SDK element model, this flag should be set to `false`,
   * so that resynthesized elements belonging to this context won't leak into
   * the global SDK cache partition.
   */
  bool useSdkCachePartition = true;

  /**
   * The most recently incrementally resolved source, or `null` when it was
   * already validated, or the most recent change was not incrementally resolved.
   */
  Source incrementalResolutionValidation_lastUnitSource;

  /**
   * The most recently incrementally resolved library source, or `null` when it
   * was already validated, or the most recent change was not incrementally
   * resolved.
   */
  Source incrementalResolutionValidation_lastLibrarySource;

  /**
   * The result of incremental resolution result of
   * [incrementalResolutionValidation_lastUnitSource].
   */
  CompilationUnit incrementalResolutionValidation_lastUnit;

  @override
  ResolverProvider fileResolverProvider;

  /**
   * Initialize a newly created analysis context.
   */
  AnalysisContextImpl();

  @override
  AnalysisCache get analysisCache {
    throw UnimplementedError();
  }

  @override
  AnalysisOptions get analysisOptions => _options;

  @override
  void set analysisOptions(AnalysisOptions options) {
    this._options = options;
  }

  @override
  void set analysisPriorityOrder(List<Source> sources) {
    throw UnimplementedError();
  }

  CacheConsistencyValidator get cacheConsistencyValidator {
    throw UnimplementedError();
  }

  @override
  set contentCache(ContentCache value) {
    throw UnimplementedError();
  }

  @override
  DeclaredVariables get declaredVariables => _declaredVariables;

  /**
   * Set the declared variables to the give collection of declared [variables].
   */
  void set declaredVariables(DeclaredVariables variables) {
    _declaredVariables = variables;
  }

  @deprecated
  @override
  EmbedderYamlLocator get embedderYamlLocator {
    throw UnimplementedError();
  }

  @override
  List<AnalysisTarget> get explicitTargets {
    throw UnimplementedError();
  }

  @override
  List<Source> get htmlSources {
    throw UnimplementedError();
  }

  @override
  Stream<ImplicitAnalysisEvent> get implicitAnalysisEvents {
    throw UnimplementedError();
  }

  @override
  bool get isActive {
    throw UnimplementedError();
  }

  @override
  set isActive(bool active) {
    throw UnimplementedError();
  }

  @override
  bool get isDisposed {
    throw UnimplementedError();
  }

  @override
  List<Source> get launchableClientLibrarySources {
    throw UnimplementedError();
  }

  @override
  List<Source> get launchableServerLibrarySources {
    throw UnimplementedError();
  }

  @override
  List<Source> get librarySources {
    throw UnimplementedError();
  }

  @override
  Stream<SourcesChangedEvent> get onSourcesChanged {
    throw UnimplementedError();
  }

  @override
  List<Source> get prioritySources {
    throw UnimplementedError();
  }

  @override
  List<AnalysisTarget> get priorityTargets {
    throw UnimplementedError();
  }

  @override
  CachePartition get privateAnalysisCachePartition {
    throw UnimplementedError();
  }

  @override
  SourceFactory get sourceFactory => _sourceFactory;

  @override
  void set sourceFactory(SourceFactory factory) {
    _sourceFactory = factory;
  }

  @override
  List<Source> get sources {
    throw UnimplementedError();
  }

  /**
   * Return a list of the sources that would be processed by
   * [performAnalysisTask]. This method duplicates, and must therefore be kept
   * in sync with, [getNextAnalysisTask]. This method is intended to be used for
   * testing purposes only.
   */
  List<Source> get sourcesNeedingProcessing {
    throw UnimplementedError();
  }

  List<Source> get test_priorityOrder {
    throw UnimplementedError();
  }

  @override
  TypeProvider get typeProvider {
    return _typeProvider;
  }

  /**
   * Sets the [TypeProvider] for this context.
   */
  @override
  void set typeProvider(TypeProvider typeProvider) {
    _typeProvider = typeProvider;
  }

  @override
  TypeSystem get typeSystem {
    return _typeSystem ??= Dart2TypeSystem(typeProvider);
  }

  @override
  bool aboutToComputeResult(CacheEntry entry, ResultDescriptor result) {
    throw UnimplementedError();
  }

  @override
  void addListener(AnalysisListener listener) {
    throw UnimplementedError();
  }

  @override
  void applyAnalysisDelta(AnalysisDelta delta) {
    throw UnimplementedError();
  }

  @override
  void applyChanges(ChangeSet changeSet) {
    throw UnimplementedError();
  }

  @override
  String computeDocumentationComment(Element element) {
    throw UnimplementedError();
  }

  @override
  List<AnalysisError> computeErrors(Source source) {
    throw UnimplementedError();
  }

  @override
  List<Source> computeExportedLibraries(Source source) {
    throw UnimplementedError();
  }

  @override
  List<Source> computeImportedLibraries(Source source) {
    throw UnimplementedError();
  }

  @override
  SourceKind computeKindOf(Source source) {
    throw UnimplementedError();
  }

  @override
  LibraryElement computeLibraryElement(Source source) {
    throw UnimplementedError();
  }

  @override
  LineInfo computeLineInfo(Source source) {
    throw UnimplementedError();
  }

  @override
  CancelableFuture<CompilationUnit> computeResolvedCompilationUnitAsync(
      Source unitSource, Source librarySource) {
    throw UnimplementedError();
  }

  @override
  V computeResult<V>(AnalysisTarget target, ResultDescriptor<V> descriptor) {
    throw UnimplementedError();
  }

  /**
   * Create an analysis cache based on the given source [factory].
   */
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  List<CompilationUnit> ensureResolvedDartUnits(Source unitSource) {
    throw UnimplementedError();
  }

  @override
  bool exists(Source source) {
    throw UnimplementedError();
  }

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    throw UnimplementedError();
  }

  @override
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource) {
    throw UnimplementedError();
  }

  @deprecated
  @override
  V getConfigurationData<V>(ResultDescriptor<V> key) {
    throw UnimplementedError();
  }

  @override
  TimestampedData<String> getContents(Source source) {
    throw UnimplementedError();
  }

  @override
  InternalAnalysisContext getContextFor(Source source) {
    throw UnimplementedError();
  }

  @override
  Element getElement(ElementLocation location) {
    throw UnimplementedError();
  }

  @override
  AnalysisErrorInfo getErrors(Source source) {
    throw UnimplementedError();
  }

  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    throw UnimplementedError();
  }

  @override
  SourceKind getKindOf(Source source) {
    throw UnimplementedError();
  }

  @override
  List<Source> getLibrariesContaining(Source source) {
    throw UnimplementedError();
  }

  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    throw UnimplementedError();
  }

  @override
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
    throw UnimplementedError();
  }

  @override
  LibraryElement getLibraryElement(Source source) {
    throw UnimplementedError();
  }

  @override
  LineInfo getLineInfo(Source source) {
    throw UnimplementedError();
  }

  @override
  int getModificationStamp(Source source) {
    throw UnimplementedError();
  }

  @override
  ChangeNoticeImpl getNotice(Source source) {
    throw UnimplementedError();
  }

  @override
  Namespace getPublicNamespace(LibraryElement library) {
    // TODO(brianwilkerson) Rename this to not start with 'get'.
    // Note that this is not part of the API of the interface.
    // TODO(brianwilkerson) The public namespace used to be cached, but no
    // longer is. Konstantin adds:
    // The only client of this method is NamespaceBuilder._createExportMapping(),
    // and it is not used with tasks - instead we compute export namespace once
    // using BuildExportNamespaceTask and reuse in scopes.
    NamespaceBuilder builder = new NamespaceBuilder();
    return builder.createPublicNamespaceForLibrary(library);
  }

  @override
  CompilationUnit getResolvedCompilationUnit(
      Source unitSource, LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  CompilationUnit getResolvedCompilationUnit2(
      Source unitSource, Source librarySource) {
    throw UnimplementedError();
  }

  @override
  V getResult<V>(AnalysisTarget target, ResultDescriptor<V> result) {
    throw UnimplementedError();
  }

  @override
  List<Source> getSourcesWithFullName(String path) {
    throw UnimplementedError();
  }

  @override
  bool handleContentsChanged(
      Source source, String originalContents, String newContents, bool notify) {
    throw UnimplementedError();
  }

  /**
   * Invalidate analysis cache and notify work managers that they have work
   * to do.
   */
  void invalidateCachedResults() {
    throw UnimplementedError();
  }

  @override
  void invalidateLibraryHints(Source librarySource) {
    throw UnimplementedError();
  }

  @override
  bool isClientLibrary(Source librarySource) {
    throw UnimplementedError();
  }

  @override
  bool isServerLibrary(Source librarySource) {
    throw UnimplementedError();
  }

  @override
  Stream<ResultChangedEvent> onResultChanged(ResultDescriptor descriptor) {
    throw UnimplementedError();
  }

  @override
  @deprecated
  Stream<ComputedResult> onResultComputed(ResultDescriptor descriptor) {
    throw UnimplementedError();
  }

  @override
  CompilationUnit parseCompilationUnit(Source source) {
    throw UnimplementedError();
  }

  @override
  AnalysisResult performAnalysisTask() {
    throw UnimplementedError();
  }

  @override
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    throw UnimplementedError();
  }

  @override
  void removeListener(AnalysisListener listener) {
    throw UnimplementedError();
  }

  @override
  CompilationUnit resolveCompilationUnit(
      Source unitSource, LibraryElement library) {
    throw UnimplementedError();
  }

  @override
  CompilationUnit resolveCompilationUnit2(
      Source unitSource, Source librarySource) {
    throw UnimplementedError();
  }

  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    throw UnimplementedError();
  }

  @deprecated
  @override
  void setConfigurationData(ResultDescriptor key, Object data) {
    throw UnimplementedError();
  }

  @override
  void setContents(Source source, String contents) {
    throw UnimplementedError();
  }

  @override
  bool shouldErrorsBeAnalyzed(Source source) {
    throw UnimplementedError();
  }

  @override
  void test_flushAstStructures(Source source) {
    throw UnimplementedError();
  }

  @override
  void visitContentCache(ContentCacheVisitor visitor) {
    throw UnimplementedError();
  }
}

/**
 * An object that manages the partitions that can be shared between analysis
 * contexts.
 */
class PartitionManager {
  /**
   * Clear any cached data being maintained by this manager.
   */
  void clearCache() {}

  /**
   * Return the partition being used for the given [sdk], creating the partition
   * if necessary.
   */
  SdkCachePartition forSdk(DartSdk sdk) {
    throw UnimplementedError();
  }
}

/**
 * An [AnalysisContext] that only contains sources for a Dart SDK.
 */
class SdkAnalysisContext extends AnalysisContextImpl {
  /**
   * Initialize a newly created SDK analysis context with the given [options].
   * Analysis options cannot be changed afterwards.  If the given [options] are
   * `null`, then default options are used.
   */
  SdkAnalysisContext(AnalysisOptions options) {
    if (options != null) {
      super.analysisOptions = options;
    }
  }

  @override
  void set analysisOptions(AnalysisOptions options) {
    throw new StateError('AnalysisOptions of SDK context cannot be changed.');
  }

  @override
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    throw UnimplementedError();
  }
}
