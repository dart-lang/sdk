// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/plugin/task.dart';
import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/dart_work_manager.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart' show Document;

/**
 * Type of callback functions used by PendingFuture. Functions of this type
 * should perform a computation based on the data in [entry] and return it. If
 * the computation can't be performed yet because more analysis is needed,
 * `null` should be returned.
 *
 * The function may also throw an exception, in which case the corresponding
 * future will be completed with failure.
 *
 * Because this function is called while the state of analysis is being updated,
 * it should be free of side effects so that it doesn't cause reentrant changes
 * to the analysis state.
 */
typedef T PendingFutureComputer<T>(CacheEntry entry);

/**
 * An [AnalysisContext] in which analysis can be performed.
 */
class AnalysisContextImpl implements InternalAnalysisContext {
  /**
   * The flag that is `true` if the context is being analyzed.
   */
  bool _isActive = false;

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
   * The embedder yaml locator for this context.
   */
  @deprecated
  EmbedderYamlLocator _embedderYamlLocator = new EmbedderYamlLocator(null);

  /**
   * A flag indicating whether this context is disposed.
   */
  bool _disposed = false;

  /**
   * A cache of content used to override the default content of a source.
   */
  ContentCache _contentCache = new ContentCache();

  /**
   * The source factory used to create the sources that can be analyzed in this
   * context.
   */
  SourceFactory _sourceFactory;

  /**
   * The set of declared variables used when computing constant values.
   */
  DeclaredVariables _declaredVariables = new DeclaredVariables();

  /**
   * The partition that contains analysis results that are not shared with other
   * contexts.
   */
  CachePartition _privatePartition;

  /**
   * The cache in which information about the results associated with targets
   * are stored.
   */
  AnalysisCache _cache;

  @override
  final ReentrantSynchronousStream<InvalidatedResult> onResultInvalidated =
      new ReentrantSynchronousStream<InvalidatedResult>();

  ReentrantSynchronousStreamSubscription onResultInvalidatedSubscription = null;

  /**
   * Configuration data associated with this context.
   */
  final HashMap<ResultDescriptor, Object> _configurationData =
      new HashMap<ResultDescriptor, Object>();

  /**
   * The task manager used to manage the tasks used to analyze code.
   */
  TaskManager _taskManager;

  /**
   * A list of all [WorkManager]s used by this context.
   */
  @override
  final List<WorkManager> workManagers = <WorkManager>[];

  /**
   * The [DartWorkManager] instance that performs Dart specific scheduling.
   */
  DartWorkManager dartWorkManager;

  /**
   * The analysis driver used to perform analysis.
   */
  AnalysisDriver driver;

  /**
   * A list containing sources for which data should not be flushed.
   */
  List<Source> _priorityOrder = <Source>[];

  CacheConsistencyValidatorImpl _cacheConsistencyValidator;

  /**
   * A map from all sources for which there are futures pending to a list of
   * the corresponding PendingFuture objects.  These sources will be analyzed
   * in the same way as priority sources, except with higher priority.
   */
  HashMap<AnalysisTarget, List<PendingFuture>> _pendingFutureTargets =
      new HashMap<AnalysisTarget, List<PendingFuture>>();

  /**
   * A table mapping sources to the change notices that are waiting to be
   * returned related to that source.
   */
  HashMap<Source, ChangeNoticeImpl> _pendingNotices =
      new HashMap<Source, ChangeNoticeImpl>();

  /**
   * The [TypeProvider] for this context, `null` if not yet created.
   */
  TypeProvider _typeProvider;

  /**
   * The [TypeSystem] for this context, `null` if not yet created.
   */
  TypeSystem _typeSystem;

  /**
   * The controller for sending [SourcesChangedEvent]s.
   */
  StreamController<SourcesChangedEvent> _onSourcesChangedController;

  /**
   * A subscription for a stream of events indicating when files are (and are
   * not) being implicitly analyzed.
   */
  StreamController<ImplicitAnalysisEvent> _implicitAnalysisEventsController;

  /**
   * The listeners that are to be notified when various analysis results are
   * produced in this context.
   */
  List<AnalysisListener> _listeners = new List<AnalysisListener>();

  /**
   * Determines whether this context should attempt to make use of the global
   * SDK cache partition. Note that if this context is responsible for
   * resynthesizing the SDK element model, this flag should be set to `false`,
   * so that resynthesized elements belonging to this context won't leak into
   * the global SDK cache partition.
   */
  bool useSdkCachePartition = true;

  @override
  ResultProvider resultProvider;

  /**
   * The map of [ResultChangedEvent] controllers.
   */
  final Map<ResultDescriptor, StreamController<ResultChangedEvent>>
      _resultChangedControllers =
      <ResultDescriptor, StreamController<ResultChangedEvent>>{};

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
  AnalysisContextImpl() {
    AnalysisEngine.instance.processRequiredPlugins();
    _privatePartition = new UniversalCachePartition(this);
    _cache = createCacheFromSourceFactory(null);
    _taskManager = AnalysisEngine.instance.taskManager;
    for (WorkManagerFactory factory
        in AnalysisEngine.instance.enginePlugin.workManagerFactories) {
      WorkManager workManager = factory(this);
      if (workManager != null) {
        workManagers.add(workManager);
        if (workManager is DartWorkManager) {
          dartWorkManager = workManager;
        }
      }
    }
    driver = new AnalysisDriver(_taskManager, workManagers, this);
    _onSourcesChangedController =
        new StreamController<SourcesChangedEvent>.broadcast();
    _implicitAnalysisEventsController =
        new StreamController<ImplicitAnalysisEvent>.broadcast();
  }

  @override
  AnalysisCache get analysisCache => _cache;

  @override
  AnalysisOptions get analysisOptions => _options;

  @override
  void set analysisOptions(AnalysisOptions options) {
    bool needsRecompute = this._options.analyzeFunctionBodiesPredicate !=
            options.analyzeFunctionBodiesPredicate ||
        this._options.generateImplicitErrors !=
            options.generateImplicitErrors ||
        this._options.generateSdkErrors != options.generateSdkErrors ||
        this._options.dart2jsHint != options.dart2jsHint ||
        _notEqual(
            this._options.enabledPluginNames, options.enabledPluginNames) ||
        _notEqual(this._options.errorProcessors, options.errorProcessors) ||
        _notEqual(this._options.excludePatterns, options.excludePatterns) ||
        (this._options.hint && !options.hint) ||
        (this._options.lint && !options.lint) ||
        _notEqual(this._options.lintRules, options.lintRules) ||
        this._options.preserveComments != options.preserveComments ||
        this._options.strongMode != options.strongMode ||
        this._options.useFastaParser != options.useFastaParser ||
        this._options.enableAssertInitializer !=
            options.enableAssertInitializer ||
        this._options.enableLazyAssignmentOperators !=
            options.enableLazyAssignmentOperators ||
        ((options is AnalysisOptionsImpl)
            ? this._options.strongModeHints != options.strongModeHints
            : false) ||
        ((options is AnalysisOptionsImpl)
            ? this._options.declarationCasts != options.declarationCasts
            : false) ||
        ((options is AnalysisOptionsImpl)
            ? this._options.implicitCasts != options.implicitCasts
            : false) ||
        ((options is AnalysisOptionsImpl)
            ? this._options.nonnullableTypes != options.nonnullableTypes
            : false) ||
        ((options is AnalysisOptionsImpl)
            ? this._options.implicitDynamic != options.implicitDynamic
            : false) ||
        this._options.enableStrictCallChecks !=
            options.enableStrictCallChecks ||
        this._options.enableSuperMixins != options.enableSuperMixins ||
        !_samePatchPaths(this._options.patchPaths, options.patchPaths);
    this._options.analyzeFunctionBodiesPredicate =
        options.analyzeFunctionBodiesPredicate;
    this._options.generateImplicitErrors = options.generateImplicitErrors;
    this._options.generateSdkErrors = options.generateSdkErrors;
    this._options.dart2jsHint = options.dart2jsHint;
    this._options.enableAssertInitializer = options.enableAssertInitializer;
    this._options.enableStrictCallChecks = options.enableStrictCallChecks;
    this._options.enableLazyAssignmentOperators =
        options.enableLazyAssignmentOperators;
    this._options.enableSuperMixins = options.enableSuperMixins;
    this._options.enableTiming = options.enableTiming;
    this._options.enabledPluginNames = options.enabledPluginNames;
    this._options.errorProcessors = options.errorProcessors;
    this._options.excludePatterns = options.excludePatterns;
    this._options.hint = options.hint;
    this._options.lint = options.lint;
    this._options.lintRules = options.lintRules;
    this._options.preserveComments = options.preserveComments;
    if (this._options.strongMode != options.strongMode) {
      _typeSystem = null;
    }
    this._options.strongMode = options.strongMode;
    this._options.useFastaParser = options.useFastaParser;
    this._options.trackCacheDependencies = options.trackCacheDependencies;
    this._options.disableCacheFlushing = options.disableCacheFlushing;
    this._options.patchPaths = options.patchPaths;
    if (options is AnalysisOptionsImpl) {
      this._options.strongModeHints = options.strongModeHints;
      this._options.declarationCasts = options.declarationCasts;
      this._options.implicitCasts = options.implicitCasts;
      this._options.nonnullableTypes = options.nonnullableTypes;
      this._options.implicitDynamic = options.implicitDynamic;
    }
    if (needsRecompute) {
      for (WorkManager workManager in workManagers) {
        workManager.onAnalysisOptionsChanged();
      }
    }
  }

  @override
  void set analysisPriorityOrder(List<Source> sources) {
    if (sources == null || sources.isEmpty) {
      _priorityOrder = Source.EMPTY_LIST;
    } else {
      while (sources.remove(null)) {
        // Nothing else to do.
      }
      if (sources.isEmpty) {
        _priorityOrder = Source.EMPTY_LIST;
      } else {
        _priorityOrder = sources;
      }
    }
    for (WorkManager workManager in workManagers) {
      workManager.applyPriorityTargets(_priorityOrder);
    }
    driver.reset();
  }

  CacheConsistencyValidator get cacheConsistencyValidator =>
      _cacheConsistencyValidator ??= new CacheConsistencyValidatorImpl(this);

  @override
  set contentCache(ContentCache value) {
    _contentCache = value;
  }

  @override
  DeclaredVariables get declaredVariables => _declaredVariables;

  @deprecated
  @override
  EmbedderYamlLocator get embedderYamlLocator => _embedderYamlLocator;

  @override
  List<AnalysisTarget> get explicitTargets {
    List<AnalysisTarget> targets = <AnalysisTarget>[];
    MapIterator<AnalysisTarget, CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      if (iterator.value.explicitlyAdded) {
        targets.add(iterator.key);
      }
    }
    return targets;
  }

  @override
  List<Source> get htmlSources => _getSources(SourceKind.HTML);

  @override
  Stream<ImplicitAnalysisEvent> get implicitAnalysisEvents =>
      _implicitAnalysisEventsController.stream;

  @override
  bool get isActive => _isActive;

  @override
  set isActive(bool active) {
    if (active != _isActive) {
      _isActive = active;
      _privatePartition.isActive = active;
    }
  }

  @override
  bool get isDisposed => _disposed;

  @override
  List<Source> get launchableClientLibrarySources {
    List<Source> sources = <Source>[];
    for (Source source in _cache.sources) {
      CacheEntry entry = _cache.get(source);
      if (entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY &&
          !source.isInSystemLibrary &&
          isClientLibrary(source)) {
        sources.add(source);
      }
    }
    return sources;
  }

  @override
  List<Source> get launchableServerLibrarySources {
    List<Source> sources = <Source>[];
    for (Source source in _cache.sources) {
      CacheEntry entry = _cache.get(source);
      if (entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY &&
          !source.isInSystemLibrary &&
          isServerLibrary(source)) {
        sources.add(source);
      }
    }
    return sources;
  }

  @override
  List<Source> get librarySources => _getSources(SourceKind.LIBRARY);

  @override
  Stream<SourcesChangedEvent> get onSourcesChanged =>
      _onSourcesChangedController.stream;

  /**
   * Make _pendingFutureSources available to unit tests.
   */
  HashMap<AnalysisTarget, List<PendingFuture>>
      get pendingFutureSources_forTesting => _pendingFutureTargets;

  @override
  List<Source> get prioritySources => _priorityOrder;

  @override
  List<AnalysisTarget> get priorityTargets => prioritySources;

  @override
  CachePartition get privateAnalysisCachePartition => _privatePartition;

  @override
  SourceFactory get sourceFactory => _sourceFactory;

  @override
  void set sourceFactory(SourceFactory factory) {
    if (identical(_sourceFactory, factory)) {
      return;
    } else if (factory.context != null) {
      throw new StateError(
          "Source factories cannot be shared between contexts");
    }
    if (_sourceFactory != null) {
      _sourceFactory.context = null;
    }
    factory.context = this;
    _sourceFactory = factory;
    _cache?.dispose();
    _cache = createCacheFromSourceFactory(factory);
    for (WorkManager workManager in workManagers) {
      workManager.onSourceFactoryChanged();
    }
  }

  @override
  List<Source> get sources {
    return _cache.sources.toList();
  }

  /**
   * Return a list of the sources that would be processed by
   * [performAnalysisTask]. This method duplicates, and must therefore be kept
   * in sync with, [getNextAnalysisTask]. This method is intended to be used for
   * testing purposes only.
   */
  List<Source> get sourcesNeedingProcessing {
    HashSet<Source> sources = new HashSet<Source>();
    bool hintsEnabled = _options.hint;
    bool lintsEnabled = _options.lint;

    MapIterator<AnalysisTarget, CacheEntry> iterator =
        _privatePartition.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      if (target is Source) {
        _getSourcesNeedingProcessing(
            target, iterator.value, false, hintsEnabled, lintsEnabled, sources);
      }
    }
    return new List<Source>.from(sources);
  }

  List<Source> get test_priorityOrder => _priorityOrder;

  @override
  TypeProvider get typeProvider {
    // The `AnalysisContextTarget.request` results go into the SDK partition,
    // and the TYPE_PROVIDER result is computed and put into the SDK partition
    // only by the first non-SDK analysis context. So, in order to reuse it
    // in other analysis contexts, we need to ask for it from the cache.
    _typeProvider ??= getResult(AnalysisContextTarget.request, TYPE_PROVIDER);
    if (_typeProvider != null) {
      return _typeProvider;
    }

    // Make sure a task didn't accidentally try to call back into the context
    // to retrieve the type provider.
    assert(!driver.isTaskRunning);

    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    if (coreSource == null) {
      throw new AnalysisException("Could not create a source for dart:core");
    }
    LibraryElement coreElement = computeLibraryElement(coreSource);
    if (coreElement == null) {
      throw new AnalysisException("Could not create an element for dart:core");
    }

    Source asyncSource = sourceFactory.forUri(DartSdk.DART_ASYNC);
    if (asyncSource == null) {
      throw new AnalysisException("Could not create a source for dart:async");
    }
    LibraryElement asyncElement = computeLibraryElement(asyncSource);
    if (asyncElement == null) {
      throw new AnalysisException("Could not create an element for dart:async");
    }
    _typeProvider = new TypeProviderImpl(coreElement, asyncElement);
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
    if (_typeSystem == null) {
      _typeSystem = TypeSystem.create(this);
    }
    return _typeSystem;
  }

  @override
  bool aboutToComputeResult(CacheEntry entry, ResultDescriptor result) {
    return PerformanceStatistics.summary.makeCurrentWhile(() {
      // Use this helper if it is set.
      if (resultProvider != null && resultProvider.compute(entry, result)) {
        return true;
      }
      // Ask the SDK.
      DartSdk dartSdk = sourceFactory.dartSdk;
      if (dartSdk != null) {
        AnalysisContext sdkContext = dartSdk.context;
        if (!identical(sdkContext, this) &&
            sdkContext is InternalAnalysisContext) {
          return sdkContext.aboutToComputeResult(entry, result);
        }
      }
      // Cannot provide the result.
      return false;
    });
  }

  @override
  void addListener(AnalysisListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void applyAnalysisDelta(AnalysisDelta delta) {
    ChangeSet changeSet = new ChangeSet();
    delta.analysisLevels.forEach((Source source, AnalysisLevel level) {
      if (level == AnalysisLevel.NONE) {
        changeSet.removedSource(source);
      } else {
        changeSet.addedSource(source);
      }
    });
    applyChanges(changeSet);
  }

  @override
  void applyChanges(ChangeSet changeSet) {
    if (changeSet.isEmpty) {
      return;
    }
    //
    // First, compute the list of sources that have been removed.
    //
    List<Source> removedSources = changeSet.removedSources.toList();
    for (SourceContainer container in changeSet.removedContainers) {
      _addSourcesInContainer(removedSources, container);
    }
    //
    // Then determine which cached results are no longer valid.
    //
    for (Source source in changeSet.addedSources) {
      _sourceAvailable(source);
    }
    // Exclude sources that are overridden in the content cache, so the change
    // will have no effect. Just ignore it to avoid wasting time doing
    // re-analysis.
    List<Source> changedSources = changeSet.changedSources
        .where((s) => _contentCache.getContents(s) == null)
        .toList();
    for (Source source in changedSources) {
      _sourceChanged(source);
    }
    changeSet.changedContents.forEach((Source key, String value) {
      _contentsChanged(key, value, false);
    });
    changeSet.changedRanges
        .forEach((Source source, ChangeSet_ContentChange change) {
      _contentRangeChanged(source, change.contents, change.offset,
          change.oldLength, change.newLength);
    });
    for (Source source in removedSources) {
      _sourceRemoved(source);
    }
    for (WorkManager workManager in workManagers) {
      workManager.applyChange(
          changeSet.addedSources, changedSources, removedSources);
    }
    _onSourcesChangedController.add(new SourcesChangedEvent(changeSet));
  }

  @override
  String computeDocumentationComment(Element element) =>
      element?.documentationComment;

  @override
  List<AnalysisError> computeErrors(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isHtmlFileName(name)) {
      return computeResult(source, HTML_ERRORS);
    }
    return computeResult(source, DART_ERRORS);
  }

  @override
  List<Source> computeExportedLibraries(Source source) =>
      computeResult(source, EXPORTED_LIBRARIES);

  @override
  List<Source> computeImportedLibraries(Source source) =>
      computeResult(source, EXPLICITLY_IMPORTED_LIBRARIES);

  @override
  SourceKind computeKindOf(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isDartFileName(name)) {
      return computeResult(source, SOURCE_KIND);
    } else if (AnalysisEngine.isHtmlFileName(name)) {
      return SourceKind.HTML;
    }
    return SourceKind.UNKNOWN;
  }

  @override
  LibraryElement computeLibraryElement(Source source) {
    //_computeResult(source, HtmlEntry.ELEMENT);
    return computeResult(source, LIBRARY_ELEMENT);
  }

  @override
  LineInfo computeLineInfo(Source source) => computeResult(source, LINE_INFO);

  @override
  CancelableFuture<CompilationUnit> computeResolvedCompilationUnitAsync(
      Source unitSource, Source librarySource) {
    if (!AnalysisEngine.isDartFileName(unitSource.shortName) ||
        !AnalysisEngine.isDartFileName(librarySource.shortName)) {
      return new CancelableFuture.error(new AnalysisNotScheduledError());
    }
    return new AnalysisFutureHelper<CompilationUnit>(this,
            new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT)
        .computeAsync();
  }

  @override
  V computeResult<V>(AnalysisTarget target, ResultDescriptor<V> descriptor) {
    // Make sure we are not trying to invoke the task model in a reentrant
    // fashion.
    assert(!driver.isTaskRunning);
    CacheEntry entry = getCacheEntry(target);
    CacheState state = entry.getState(descriptor);
    if (state == CacheState.FLUSHED || state == CacheState.INVALID) {
      // Check the result provider.
      bool success = aboutToComputeResult(entry, descriptor);
      if (success) {
        return entry.getValue(descriptor);
      }
      // Compute the result.
      driver.computeResult(target, descriptor);
      entry = getCacheEntry(target);
    }
    state = entry.getState(descriptor);
    if (state == CacheState.ERROR) {
      throw new AnalysisException(
          'Cannot compute $descriptor for $target', entry.exception);
    }
    return entry.getValue(descriptor);
  }

  /**
   * Create an analysis cache based on the given source [factory].
   */
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    AnalysisCache createCache() {
      if (factory == null) {
        return new AnalysisCache(<CachePartition>[_privatePartition]);
      }
      if (!useSdkCachePartition) {
        return new AnalysisCache(<CachePartition>[_privatePartition]);
      }
      DartSdk sdk = factory.dartSdk;
      if (sdk == null) {
        return new AnalysisCache(<CachePartition>[_privatePartition]);
      }
      return new AnalysisCache(<CachePartition>[
        AnalysisEngine.instance.partitionManager.forSdk(sdk),
        _privatePartition
      ]);
    }

    AnalysisCache cache = createCache();
    onResultInvalidatedSubscription?.cancel();
    onResultInvalidatedSubscription =
        cache.onResultInvalidated.listen((InvalidatedResult event) {
      onResultInvalidated.add(event);
      StreamController<ResultChangedEvent> controller =
          _resultChangedControllers[event.descriptor];
      if (controller != null) {
        controller.add(new ResultChangedEvent(
            this, event.entry.target, event.descriptor, event.value, false));
      }
    });
    return cache;
  }

  @override
  void dispose() {
    _disposed = true;
    for (List<PendingFuture> pendingFutures in _pendingFutureTargets.values) {
      for (PendingFuture pendingFuture in pendingFutures) {
        pendingFuture.forciblyComplete();
      }
    }
    _pendingFutureTargets.clear();
    _privatePartition.dispose();
    _cache.dispose();
  }

  @override
  List<CompilationUnit> ensureResolvedDartUnits(Source unitSource) {
    // Check every library.
    List<CompilationUnit> units = <CompilationUnit>[];
    List<Source> containingLibraries = getLibrariesContaining(unitSource);
    for (Source librarySource in containingLibraries) {
      LibrarySpecificUnit target =
          new LibrarySpecificUnit(librarySource, unitSource);
      CompilationUnit unit = getResult(target, RESOLVED_UNIT);
      if (unit == null) {
        units = null;
        break;
      }
      units.add(unit);
    }
    // If we have results, then we're done.
    if (units != null) {
      return units;
    }
    // Schedule computing of RESOLVED_UNIT results.
    for (Source librarySource in containingLibraries) {
      LibrarySpecificUnit target =
          new LibrarySpecificUnit(librarySource, unitSource);
      dartWorkManager.addPriorityResult(target, RESOLVED_UNIT);
    }
    return null;
  }

  @override
  bool exists(Source source) {
    if (source == null) {
      return false;
    }
    bool overriddenExists = _contentCache.getExists(source);
    if (overriddenExists != null) {
      return overriddenExists;
    }
    return source.exists();
  }

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    CacheEntry entry = _cache.get(target);
    if (entry == null) {
      entry = new CacheEntry(target);
      ImplicitAnalysisEvent event = null;
      if (target is Source) {
        entry.modificationTime = getModificationStamp(target);
        event = new ImplicitAnalysisEvent(target, true);
      }
      _cache.put(entry);
      if (event != null) {
        _implicitAnalysisEventsController.add(event);
      }
    }
    return entry;
  }

  @override
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource) {
    AnalysisTarget target = new LibrarySpecificUnit(librarySource, unitSource);
    return getResult(target, COMPILATION_UNIT_ELEMENT);
  }

  @deprecated
  @override
  V getConfigurationData<V>(ResultDescriptor<V> key) =>
      (_configurationData[key] ?? key?.defaultValue) as V;

  @override
  TimestampedData<String> getContents(Source source) {
    String contents = _contentCache.getContents(source);
    if (contents != null) {
      return new TimestampedData<String>(
          _contentCache.getModificationStamp(source), contents);
    }
    return source.contents;
  }

  @override
  InternalAnalysisContext getContextFor(Source source) =>
      _cache.getContextFor(source) ?? this;

  @override
  Element getElement(ElementLocation location) {
    // TODO(brianwilkerson) This should not be a "get" method.
    try {
      List<String> components = location.components;
      Source source = _computeSourceFromEncoding(components[0]);
      String sourceName = source.shortName;
      if (AnalysisEngine.isDartFileName(sourceName)) {
        ElementImpl element = computeLibraryElement(source) as ElementImpl;
        for (int i = 1; i < components.length; i++) {
          if (element == null) {
            return null;
          }
          element = element.getChild(components[i]);
        }
        return element;
      }
    } catch (exception) {
      // If the location cannot be decoded for some reason then the underlying
      // cause should have been logged already and we can fall though to return
      // null.
    }
    return null;
  }

  @override
  AnalysisErrorInfo getErrors(Source source) {
    List<AnalysisError> allErrors = <AnalysisError>[];
    for (WorkManager workManager in workManagers) {
      List<AnalysisError> errors = workManager.getErrors(source);
      allErrors.addAll(errors);
    }
    LineInfo lineInfo = getLineInfo(source);
    return new AnalysisErrorInfoImpl(allErrors, lineInfo);
  }

  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    if (!AnalysisEngine.isDartFileName(source.shortName)) {
      return Source.EMPTY_LIST;
    }
    List<Source> htmlSources = <Source>[];
    List<Source> librarySources = getLibrariesContaining(source);
    for (Source source in _cache.sources) {
      if (AnalysisEngine.isHtmlFileName(source.shortName)) {
        List<Source> referencedLibraries =
            getResult(source, REFERENCED_LIBRARIES);
        if (_containsAny(referencedLibraries, librarySources)) {
          htmlSources.add(source);
        }
      }
    }
    if (htmlSources.isEmpty) {
      return Source.EMPTY_LIST;
    }
    return htmlSources;
  }

  @override
  SourceKind getKindOf(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isDartFileName(name)) {
      return getResult(source, SOURCE_KIND);
    } else if (AnalysisEngine.isHtmlFileName(name)) {
      return SourceKind.HTML;
    }
    return SourceKind.UNKNOWN;
  }

  @override
  List<Source> getLibrariesContaining(Source source) {
    SourceKind kind = getKindOf(source);
    if (kind == SourceKind.LIBRARY) {
      return <Source>[source];
    }
    return dartWorkManager.getLibrariesContainingPart(source);
  }

  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    List<Source> dependentLibraries = <Source>[];
    for (Source source in _cache.sources) {
      CacheEntry entry = _cache.get(source);
      if (entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY) {
        if (_contains(entry.getValue(EXPORTED_LIBRARIES), librarySource)) {
          dependentLibraries.add(source);
        }
        if (_contains(entry.getValue(IMPORTED_LIBRARIES), librarySource)) {
          dependentLibraries.add(source);
        }
      }
    }
    if (dependentLibraries.isEmpty) {
      return Source.EMPTY_LIST;
    }
    return dependentLibraries;
  }

  @override
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
    CacheEntry entry = _cache.get(htmlSource);
    if (entry != null) {
      return entry.getValue(REFERENCED_LIBRARIES);
    }
    return Source.EMPTY_LIST;
  }

  @override
  LibraryElement getLibraryElement(Source source) =>
      getResult(source, LIBRARY_ELEMENT);

  @override
  LineInfo getLineInfo(Source source) => getResult(source, LINE_INFO);

  @override
  int getModificationStamp(Source source) {
    int stamp = _contentCache.getModificationStamp(source);
    if (stamp != null) {
      return stamp;
    }
    return source.modificationStamp;
  }

  @override
  ChangeNoticeImpl getNotice(Source source) {
    ChangeNoticeImpl notice = _pendingNotices[source];
    if (notice == null) {
      notice = new ChangeNoticeImpl(source);
      _pendingNotices[source] = notice;
    }
    return notice;
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
    if (library == null ||
        !AnalysisEngine.isDartFileName(unitSource.shortName)) {
      return null;
    }
    return getResolvedCompilationUnit2(unitSource, library.source);
  }

  @override
  CompilationUnit getResolvedCompilationUnit2(
      Source unitSource, Source librarySource) {
    if (!AnalysisEngine.isDartFileName(unitSource.shortName) ||
        !AnalysisEngine.isDartFileName(librarySource.shortName)) {
      return null;
    }
    return getResult(
        new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT);
  }

  @override
  V getResult<V>(AnalysisTarget target, ResultDescriptor<V> result) {
    return _cache.getValue(target, result);
  }

  @override
  List<Source> getSourcesWithFullName(String path) {
    return analysisCache.getSourcesWithFullName(path);
  }

  @override
  bool handleContentsChanged(
      Source source, String originalContents, String newContents, bool notify) {
    CacheEntry entry = _cache.get(source);
    if (entry == null) {
      return false;
    }
    // If there were no "originalContents" in the content cache,
    // use the contents of the file instead.
    if (originalContents == null) {
      try {
        TimestampedData<String> fileContents = source.contents;
        if (fileContents.modificationTime == entry.modificationTime) {
          originalContents = fileContents.data;
        }
      } catch (e) {}
    }
    bool changed = newContents != originalContents;
    if (newContents != null) {
      if (changed) {
        entry.modificationTime = _contentCache.getModificationStamp(source);
        // Don't compare with old contents because the cache has already been
        // updated, and we know at this point that it changed.
        _sourceChanged(source, compareWithOld: false);
        entry.setValue(CONTENT, newContents, TargetedResult.EMPTY_LIST);
      } else {
        entry.modificationTime = _contentCache.getModificationStamp(source);
      }
    } else if (originalContents != null) {
      // We are removing the overlay for the file, check if the file's
      // contents is the same as it was in the overlay.
      try {
        TimestampedData<String> fileContents = getContents(source);
        newContents = fileContents.data;
        entry.modificationTime = fileContents.modificationTime;
        if (newContents == originalContents) {
          entry.setValue(CONTENT, newContents, TargetedResult.EMPTY_LIST);
          changed = false;
        }
      } catch (e) {}
      // If not the same content (e.g. the file is being closed without save),
      // then force analysis.
      if (changed) {
        if (newContents == null) {
          _sourceChanged(source);
        }
      }
    }
    if (notify && changed) {
      _onSourcesChangedController
          .add(new SourcesChangedEvent.changedContent(source, newContents));
    }
    return changed;
  }

  /**
   * Invalidate analysis cache and notify work managers that they have work
   * to do.
   */
  void invalidateCachedResults() {
    _cache?.dispose();
    _cache = createCacheFromSourceFactory(_sourceFactory);
    for (WorkManager workManager in workManagers) {
      workManager.onAnalysisOptionsChanged();
    }
  }

  @override
  void invalidateLibraryHints(Source librarySource) {
    List<Source> sources = getResult(librarySource, UNITS);
    if (sources != null) {
      for (Source source in sources) {
        getCacheEntry(source).setState(HINTS, CacheState.INVALID);
      }
    }
  }

  @override
  bool isClientLibrary(Source librarySource) {
    CacheEntry entry = _cache.get(librarySource);
    return entry != null &&
        _referencesDartHtml(librarySource) &&
        entry.getValue(IS_LAUNCHABLE);
  }

  @override
  bool isServerLibrary(Source librarySource) {
    CacheEntry entry = _cache.get(librarySource);
    return entry != null &&
        !_referencesDartHtml(librarySource) &&
        entry.getValue(IS_LAUNCHABLE);
  }

  @override
  Stream<ResultChangedEvent> onResultChanged(ResultDescriptor descriptor) {
    driver.onResultComputed(descriptor).listen((ResultChangedEvent event) {
      _resultChangedControllers[descriptor]?.add(event);
    });
    return _resultChangedControllers.putIfAbsent(descriptor, () {
      return new StreamController<ResultChangedEvent>.broadcast(sync: true);
    }).stream;
  }

  @override
  @deprecated
  Stream<ComputedResult> onResultComputed(ResultDescriptor descriptor) {
    return onResultChanged(descriptor)
        .where((event) => event.wasComputed)
        .map((event) {
      return new ComputedResult(
          event.context, event.descriptor, event.target, event.value);
    });
  }

  @override
  CompilationUnit parseCompilationUnit(Source source) {
    if (!AnalysisEngine.isDartFileName(source.shortName)) {
      return null;
    }
    try {
      getContents(source);
    } catch (exception, stackTrace) {
      throw new AnalysisException('Could not get contents of $source',
          new CaughtException(exception, stackTrace));
    }
    return computeResult(source, PARSED_UNIT);
  }

  @override
  Document parseHtmlDocument(Source source) {
    if (!AnalysisEngine.isHtmlFileName(source.shortName)) {
      return null;
    }
    return computeResult(source, HTML_DOCUMENT);
  }

  @override
  AnalysisResult performAnalysisTask() {
    return PerformanceStatistics.analysis.makeCurrentWhile(() {
      _evaluatePendingFutures();
      bool done = !driver.performAnalysisTask();
      List<ChangeNotice> notices = _getChangeNotices(done);
      if (notices != null) {
        int noticeCount = notices.length;
        for (int i = 0; i < noticeCount; i++) {
          ChangeNotice notice = notices[i];
          _notifyErrors(notice.source, notice.errors, notice.lineInfo);
        }
      }
      return new AnalysisResult(notices, -1, '', -1);
    });
  }

  @override
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    elementMap.forEach((Source librarySource, LibraryElement library) {
      //
      // Cache the element in the library's info.
      //
      CacheEntry entry = getCacheEntry(librarySource);
      setValue(ResultDescriptor result, value) {
        entry.setValue(result, value, TargetedResult.EMPTY_LIST);
      }

      setValue(BUILD_DIRECTIVES_ERRORS, AnalysisError.NO_ERRORS);
      setValue(BUILD_LIBRARY_ERRORS, AnalysisError.NO_ERRORS);
      // CLASS_ELEMENTS
      setValue(COMPILATION_UNIT_ELEMENT, library.definingCompilationUnit);
      // CONSTRUCTORS
      // CONSTRUCTORS_ERRORS
      entry.setState(CONTENT, CacheState.FLUSHED);
      setValue(EXPORTED_LIBRARIES, Source.EMPTY_LIST);
      // EXPORT_SOURCE_CLOSURE
      setValue(IMPORTED_LIBRARIES, Source.EMPTY_LIST);
      // IMPORT_SOURCE_CLOSURE
      setValue(INCLUDED_PARTS, Source.EMPTY_LIST);
      setValue(IS_LAUNCHABLE, false);
      setValue(LIBRARY_ELEMENT, library);
      setValue(LIBRARY_ELEMENT1, library);
      setValue(LIBRARY_ELEMENT2, library);
      setValue(LIBRARY_ELEMENT3, library);
      setValue(LIBRARY_ELEMENT4, library);
      setValue(LIBRARY_ELEMENT5, library);
      setValue(LIBRARY_ELEMENT6, library);
      setValue(LIBRARY_ELEMENT7, library);
      setValue(LIBRARY_ELEMENT8, library);
      setValue(LIBRARY_ELEMENT9, library);
      setValue(LINE_INFO, new LineInfo(<int>[0]));
      setValue(PARSE_ERRORS, AnalysisError.NO_ERRORS);
      entry.setState(PARSED_UNIT, CacheState.FLUSHED);
      entry.setState(RESOLVE_TYPE_NAMES_ERRORS, CacheState.FLUSHED);
      entry.setState(RESOLVE_TYPE_BOUNDS_ERRORS, CacheState.FLUSHED);
      setValue(SCAN_ERRORS, AnalysisError.NO_ERRORS);
      setValue(SOURCE_KIND, SourceKind.LIBRARY);
      entry.setState(TOKEN_STREAM, CacheState.FLUSHED);
      setValue(UNITS, <Source>[librarySource]);

      LibrarySpecificUnit unit =
          new LibrarySpecificUnit(librarySource, librarySource);
      entry = getCacheEntry(unit);
      setValue(HINTS, AnalysisError.NO_ERRORS);
      setValue(LINTS, AnalysisError.NO_ERRORS);
      setValue(LIBRARY_UNIT_ERRORS, AnalysisError.NO_ERRORS);
      setValue(RESOLVE_DIRECTIVES_ERRORS, AnalysisError.NO_ERRORS);
      setValue(RESOLVE_TYPE_NAMES_ERRORS, AnalysisError.NO_ERRORS);
      setValue(RESOLVE_UNIT_ERRORS, AnalysisError.NO_ERRORS);
      entry.setState(RESOLVED_UNIT, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT1, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT2, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT3, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT4, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT5, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT6, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT7, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT8, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT9, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT10, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT11, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT12, CacheState.FLUSHED);
      // USED_IMPORTED_ELEMENTS
      // USED_LOCAL_ELEMENTS
      setValue(STRONG_MODE_ERRORS, AnalysisError.NO_ERRORS);
      setValue(VARIABLE_REFERENCE_ERRORS, AnalysisError.NO_ERRORS);
      setValue(VERIFY_ERRORS, AnalysisError.NO_ERRORS);
    });

    CacheEntry entry = getCacheEntry(AnalysisContextTarget.request);
    entry.setValue(TYPE_PROVIDER, typeProvider, TargetedResult.EMPTY_LIST);
  }

  @override
  void removeListener(AnalysisListener listener) {
    _listeners.remove(listener);
  }

  @override
  CompilationUnit resolveCompilationUnit(
      Source unitSource, LibraryElement library) {
    if (library == null) {
      return null;
    }
    return resolveCompilationUnit2(unitSource, library.source);
  }

  @override
  CompilationUnit resolveCompilationUnit2(
      Source unitSource, Source librarySource) {
    return computeResult(
        new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT);
  }

  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    if (_contentRangeChanged(source, contents, offset, oldLength, newLength)) {
      _onSourcesChangedController.add(new SourcesChangedEvent.changedRange(
          source, contents, offset, oldLength, newLength));
    }
  }

  @deprecated
  @override
  void setConfigurationData(ResultDescriptor key, Object data) {
    _configurationData[key] = data;
  }

  @override
  void setContents(Source source, String contents) {
    _contentsChanged(source, contents, true);
  }

  @override
  bool shouldErrorsBeAnalyzed(Source source) {
    CacheEntry entry = analysisCache.get(source);
    if (source.isInSystemLibrary) {
      return _options.generateSdkErrors;
    } else if (!entry.explicitlyAdded) {
      return _options.generateImplicitErrors;
    } else {
      return true;
    }
  }

  @override
  void test_flushAstStructures(Source source) {
    CacheEntry entry = getCacheEntry(source);
    entry.setState(PARSED_UNIT, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT1, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT2, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT3, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT4, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT5, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT6, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT7, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT8, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT9, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT10, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT11, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT12, CacheState.FLUSHED);
    entry.setState(RESOLVED_UNIT, CacheState.FLUSHED);
  }

  @override
  void visitContentCache(ContentCacheVisitor visitor) {
    _contentCache.accept(visitor);
  }

  /**
   * Add all of the sources contained in the given source [container] to the
   * given list of [sources].
   */
  void _addSourcesInContainer(List<Source> sources, SourceContainer container) {
    for (Source source in _cache.sources) {
      if (container.contains(source)) {
        sources.add(source);
      }
    }
  }

  /**
   * Remove the given [pendingFuture] from [_pendingFutureTargets], since the
   * client has indicated its computation is not needed anymore.
   */
  void _cancelFuture(PendingFuture pendingFuture) {
    List<PendingFuture> pendingFutures =
        _pendingFutureTargets[pendingFuture.target];
    if (pendingFutures != null) {
      pendingFutures.remove(pendingFuture);
      if (pendingFutures.isEmpty) {
        _pendingFutureTargets.remove(pendingFuture.target);
      }
    }
  }

  /**
   * Given the encoded form of a source ([encoding]), use the source factory to
   * reconstitute the original source.
   */
  Source _computeSourceFromEncoding(String encoding) =>
      _sourceFactory.fromEncoding(encoding);

  /**
   * Return `true` if the given list of [sources] contains the given
   * [targetSource].
   */
  bool _contains(List<Source> sources, Source targetSource) {
    for (Source source in sources) {
      if (source == targetSource) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given list of [sources] contains any of the given
   * [targetSources].
   */
  bool _containsAny(List<Source> sources, List<Source> targetSources) {
    for (Source targetSource in targetSources) {
      if (_contains(sources, targetSource)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Set the contents of the given [source] to the given [contents] and mark the
   * source as having changed. The additional [offset], [oldLength] and
   * [newLength] information is used by the context to determine what reanalysis
   * is necessary. The method [setChangedContents] triggers a source changed
   * event where as this method does not.
   */
  bool _contentRangeChanged(Source source, String contents, int offset,
      int oldLength, int newLength) {
    bool changed = false;
    String originalContents = _contentCache.setContents(source, contents);
    if (contents != null) {
      if (contents != originalContents) {
        _sourceChanged(source);
        changed = true;
        CacheEntry entry = _cache.get(source);
        if (entry != null) {
          entry.modificationTime = _contentCache.getModificationStamp(source);
          entry.setValue(CONTENT, contents, TargetedResult.EMPTY_LIST);
        }
      }
    } else if (originalContents != null) {
      _sourceChanged(source);
      changed = true;
    }
    return changed;
  }

  /**
   * Set the contents of the given [source] to the given [contents] and mark the
   * source as having changed. This has the effect of overriding the default
   * contents of the source. If the contents are `null` the override is removed
   * so that the default contents will be returned. If [notify] is true, a
   * source changed event is triggered.
   */
  void _contentsChanged(Source source, String contents, bool notify) {
    String originalContents = _contentCache.setContents(source, contents);
    handleContentsChanged(source, originalContents, contents, notify);
  }

  /**
   * Create a cache entry for the given [source]. The source was explicitly
   * added to this context if [explicitlyAdded] is `true`. Return the cache
   * entry that was created.
   */
  CacheEntry _createCacheEntry(Source source, bool explicitlyAdded) {
    CacheEntry entry = new CacheEntry(source);
    entry.modificationTime = getModificationStamp(source);
    entry.explicitlyAdded = explicitlyAdded;
    _cache.put(entry);
    if (!explicitlyAdded) {
      _implicitAnalysisEventsController
          .add(new ImplicitAnalysisEvent(source, true));
    }
    return entry;
  }

  /**
   * Return a list containing all of the cache entries for targets associated
   * with the given [source].
   */
  List<CacheEntry> _entriesFor(Source source) {
    List<CacheEntry> entries = <CacheEntry>[];
    MapIterator<AnalysisTarget, CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      if (iterator.key.source == source) {
        entries.add(iterator.value);
      }
    }
    return entries;
  }

  void _evaluatePendingFutures() {
    for (AnalysisTarget target in _pendingFutureTargets.keys) {
      CacheEntry cacheEntry = _cache.get(target);
      List<PendingFuture> pendingFutures = _pendingFutureTargets[target];
      for (int i = 0; i < pendingFutures.length;) {
        if (cacheEntry == null) {
          pendingFutures[i].forciblyComplete();
          pendingFutures.removeAt(i);
        } else if (pendingFutures[i].evaluate(cacheEntry)) {
          pendingFutures.removeAt(i);
        } else {
          i++;
        }
      }
    }
  }

  /**
   * Return a list containing all of the change notices that are waiting to be
   * returned. If there are no notices, then return either `null` or an empty
   * list, depending on the value of [nullIfEmpty].
   */
  List<ChangeNotice> _getChangeNotices(bool nullIfEmpty) {
    if (_pendingNotices.isEmpty) {
      if (nullIfEmpty) {
        return null;
      }
      return ChangeNoticeImpl.EMPTY_LIST;
    }
    List<ChangeNotice> notices = new List.from(_pendingNotices.values);
    _pendingNotices.clear();
    return notices;
  }

  /**
   * Return a list containing all of the sources known to this context that have
   * the given [kind].
   */
  List<Source> _getSources(SourceKind kind) {
    List<Source> sources = <Source>[];
    if (kind == SourceKind.LIBRARY || kind == SourceKind.PART) {
      for (Source source in _cache.sources) {
        CacheEntry entry = _cache.get(source);
        if (entry.getValue(SOURCE_KIND) == kind) {
          sources.add(source);
        }
      }
    } else if (kind == SourceKind.HTML) {
      for (Source source in _cache.sources) {
        if (AnalysisEngine.isHtmlFileName(source.shortName)) {
          sources.add(source);
        }
      }
    }
    if (sources.isEmpty) {
      return Source.EMPTY_LIST;
    }
    return sources;
  }

  /**
   * Look at the given [source] to see whether a task needs to be performed
   * related to it. If so, add the source to the set of sources that need to be
   * processed. This method is intended to be used for testing purposes only.
   */
  void _getSourcesNeedingProcessing(
      Source source,
      CacheEntry entry,
      bool isPriority,
      bool hintsEnabled,
      bool lintsEnabled,
      HashSet<Source> sources) {
    CacheState state = entry.getState(CONTENT);
    if (state == CacheState.INVALID ||
        (isPriority && state == CacheState.FLUSHED)) {
      sources.add(source);
      return;
    } else if (state == CacheState.ERROR) {
      return;
    }
    state = entry.getState(SOURCE_KIND);
    if (state == CacheState.INVALID ||
        (isPriority && state == CacheState.FLUSHED)) {
      sources.add(source);
      return;
    } else if (state == CacheState.ERROR) {
      return;
    }
    SourceKind kind = entry.getValue(SOURCE_KIND);
    if (kind == SourceKind.LIBRARY || kind == SourceKind.PART) {
      state = entry.getState(SCAN_ERRORS);
      if (state == CacheState.INVALID ||
          (isPriority && state == CacheState.FLUSHED)) {
        sources.add(source);
        return;
      } else if (state == CacheState.ERROR) {
        return;
      }
      state = entry.getState(PARSE_ERRORS);
      if (state == CacheState.INVALID ||
          (isPriority && state == CacheState.FLUSHED)) {
        sources.add(source);
        return;
      } else if (state == CacheState.ERROR) {
        return;
      }
//      if (isPriority) {
//        if (!entry.hasResolvableCompilationUnit) {
//          sources.add(source);
//          return;
//        }
//      }
      for (Source librarySource in getLibrariesContaining(source)) {
        CacheEntry libraryEntry = _cache.get(librarySource);
        state = libraryEntry.getState(LIBRARY_ELEMENT);
        if (state == CacheState.INVALID ||
            (isPriority && state == CacheState.FLUSHED)) {
          sources.add(source);
          return;
        } else if (state == CacheState.ERROR) {
          return;
        }
        CacheEntry unitEntry =
            _cache.get(new LibrarySpecificUnit(librarySource, source));
        state = unitEntry.getState(RESOLVED_UNIT);
        if (state == CacheState.INVALID ||
            (isPriority && state == CacheState.FLUSHED)) {
          sources.add(source);
          return;
        } else if (state == CacheState.ERROR) {
          return;
        }
        if (shouldErrorsBeAnalyzed(source)) {
          state = unitEntry.getState(VERIFY_ERRORS);
          if (state == CacheState.INVALID ||
              (isPriority && state == CacheState.FLUSHED)) {
            sources.add(source);
            return;
          } else if (state == CacheState.ERROR) {
            return;
          }
          if (hintsEnabled) {
            state = unitEntry.getState(HINTS);
            if (state == CacheState.INVALID ||
                (isPriority && state == CacheState.FLUSHED)) {
              sources.add(source);
              return;
            } else if (state == CacheState.ERROR) {
              return;
            }
          }
          if (lintsEnabled) {
            state = unitEntry.getState(LINTS);
            if (state == CacheState.INVALID ||
                (isPriority && state == CacheState.FLUSHED)) {
              sources.add(source);
              return;
            } else if (state == CacheState.ERROR) {
              return;
            }
          }
        }
      }
//    } else if (kind == SourceKind.HTML) {
//      CacheState parsedUnitState = entry.getState(HtmlEntry.PARSED_UNIT);
//      if (parsedUnitState == CacheState.INVALID ||
//          (isPriority && parsedUnitState == CacheState.FLUSHED)) {
//        sources.add(source);
//        return;
//      }
//      CacheState resolvedUnitState =
//          entry.getState(HtmlEntry.RESOLVED_UNIT);
//      if (resolvedUnitState == CacheState.INVALID ||
//          (isPriority && resolvedUnitState == CacheState.FLUSHED)) {
//        sources.add(source);
//        return;
//      }
    }
  }

  /**
   * Log the given debugging [message].
   */
  void _logInformation(String message) {
    AnalysisEngine.instance.logger.logInformation(message);
  }

  bool _notEqual<T>(List<T> first, List<T> second) {
    int length = first.length;
    if (length != second.length) {
      return true;
    }
    for (int i = 0; i < length; i++) {
      if (first[i] != second[i]) {
        return true;
      }
    }
    return false;
  }

  /**
   * Notify all of the analysis listeners that the errors associated with the
   * given [source] has been updated to the given [errors].
   */
  void _notifyErrors(
      Source source, List<AnalysisError> errors, LineInfo lineInfo) {
    int count = _listeners.length;
    for (int i = 0; i < count; i++) {
      _listeners[i].computedErrors(this, source, errors, lineInfo);
    }
  }

  bool _referencesDartHtml(Source librarySource) {
    Source htmlSource = sourceFactory.forUri(DartSdk.DART_HTML);
    Set<Source> checkedSources = new Set<Source>();
    bool _refHtml(Source source) {
      if (!checkedSources.add(source)) {
        return false;
      }
      if (source == htmlSource) {
        return true;
      }
      LibraryElement library = _cache.getValue(source, LIBRARY_ELEMENT);
      if (library != null) {
        return library.importedLibraries.any((x) => _refHtml(x.source)) ||
            library.exportedLibraries.any((x) => _refHtml(x.source));
      }
      return false;
    }

    return _refHtml(librarySource);
  }

  void _removeFromCache(Source source) {
    CacheEntry entry = _cache.remove(source);
    if (entry != null && !entry.explicitlyAdded) {
      _implicitAnalysisEventsController
          .add(new ImplicitAnalysisEvent(source, false));
    }
  }

  /**
   * Remove the given [source] from the priority order if it is in the list.
   */
  void _removeFromPriorityOrder(Source source) {
    int count = _priorityOrder.length;
    List<Source> newOrder = <Source>[];
    for (int i = 0; i < count; i++) {
      if (_priorityOrder[i] != source) {
        newOrder.add(_priorityOrder[i]);
      }
    }
    if (newOrder.length < count) {
      analysisPriorityOrder = newOrder;
    }
  }

  /**
   * Create an entry for the newly added [source] and invalidate any sources
   * that referenced the source before it existed.
   */
  void _sourceAvailable(Source source) {
    driver.reset();
    // TODO(brianwilkerson) This method needs to check whether the source was
    // previously being implicitly analyzed. If so, the cache entry needs to be
    // update to reflect the new status and an event needs to be generated to
    // inform clients that it is no longer being implicitly analyzed.
    CacheEntry entry = _cache.get(source);
    if (entry == null) {
      _createCacheEntry(source, true);
    } else {
      entry.explicitlyAdded = true;
      entry.modificationTime = getModificationStamp(source);
      entry.setState(CONTENT, CacheState.INVALID);
      entry.setState(MODIFICATION_TIME, CacheState.INVALID);
    }
  }

  /**
   * Invalidate the [source] that was changed and any sources that referenced
   * the source before it existed.
   *
   * Note: source may be considered "changed" if it was previously missing,
   * but pointed to by an import or export directive.
   */
  void _sourceChanged(Source source, {bool compareWithOld: true}) {
    CacheEntry entry = _cache.get(source);
    // If the source has no cache entry, there is nothing to invalidate.
    if (entry == null) {
      return;
    }

    String oldContents = compareWithOld ? entry.getValue(CONTENT) : null;

    // Flush so that from now on we will get new contents.
    // (For example, in getLibrariesContaining.)
    entry.setState(CONTENT, CacheState.FLUSHED);

    // Prepare the new contents.
    TimestampedData<String> fileContents;
    try {
      fileContents = getContents(source);
    } catch (e) {}

    // Update 'modificationTime' - we are going to update the entry.
    {
      int time = fileContents?.modificationTime ?? -1;
      for (CacheEntry entry in _entriesFor(source)) {
        entry.modificationTime = time;
      }
    }

    // Fast path if the contents is the same as it was last time.
    if (oldContents != null && fileContents?.data == oldContents) {
      return;
    }

    // We're going to update the cache, so reset the driver.
    driver.reset();

    // We need to invalidate the cache.
    {
      entry.setState(CONTENT, CacheState.INVALID);
      entry.setState(MODIFICATION_TIME, CacheState.INVALID);
      entry.setState(SOURCE_KIND, CacheState.INVALID);
    }
    for (WorkManager workManager in workManagers) {
      workManager.applyChange(
          Source.EMPTY_LIST, <Source>[source], Source.EMPTY_LIST);
    }
  }

  /**
   * Record that the given [source] has been removed.
   */
  void _sourceRemoved(Source source) {
    driver.reset();
    _removeFromCache(source);
    _removeFromPriorityOrder(source);
  }

  static bool _samePatchPaths(
      Map<String, List<String>> a, Map<String, List<String>> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      var aValue = a[key];
      var bValue = b[key];
      if (aValue.length != bValue.length) return false;
      for (var i = 0; i < aValue.length; i++) {
        if (aValue[i] != bValue[i]) return false;
      }
    }
    return true;
  }
}

/**
 * A helper class used to create futures for [AnalysisContextImpl].
 * Using a helper class allows us to preserve the generic parameter T.
 */
class AnalysisFutureHelper<T> {
  final AnalysisContextImpl _context;
  final AnalysisTarget _target;
  final ResultDescriptor<T> _descriptor;

  AnalysisFutureHelper(this._context, this._target, this._descriptor);

  /**
   * Return a future that will be completed with the result specified
   * in the constructor. If the result is cached, the future will be
   * completed immediately with the resulting value. If not, then
   * analysis is scheduled that will produce the required result.
   * If the result cannot be generated, then the future will be completed with
   * the error AnalysisNotScheduledError.
   */
  CancelableFuture<T> computeAsync() {
    if (_context.isDisposed) {
      // No further analysis is expected, so return a future that completes
      // immediately with AnalysisNotScheduledError.
      return new CancelableFuture.error(new AnalysisNotScheduledError());
    }
    CacheEntry entry = _context.getCacheEntry(_target);
    PendingFuture<T> pendingFuture =
        new PendingFuture<T>(_context, _target, (CacheEntry entry) {
      CacheState state = entry.getState(_descriptor);
      if (state == CacheState.ERROR) {
        throw entry.exception;
      } else if (state == CacheState.INVALID) {
        return null;
      }
      return entry.getValue(_descriptor);
    });
    if (!pendingFuture.evaluate(entry)) {
      _context._pendingFutureTargets
          .putIfAbsent(_target, () => <PendingFuture>[])
          .add(pendingFuture);
      _context.dartWorkManager.addPriorityResult(_target, _descriptor);
    }
    return pendingFuture.future;
  }
}

class CacheConsistencyValidatorImpl implements CacheConsistencyValidator {
  final AnalysisContextImpl context;

  CacheConsistencyValidatorImpl(this.context);

  @override
  List<Source> getSourcesToComputeModificationTimes() {
    return context._privatePartition.sources.toList();
  }

  @override
  bool sourceModificationTimesComputed(List<Source> sources, List<int> times) {
    Stopwatch timer = new Stopwatch()..start();
    HashSet<Source> changedSources = new HashSet<Source>();
    HashSet<Source> removedSources = new HashSet<Source>();
    for (int i = 0; i < sources.length; i++) {
      Source source = sources[i];
      // When a source is in the content cache,
      // its modification time in the file system does not matter.
      if (context._contentCache.getModificationStamp(source) != null) {
        continue;
      }
      // When we were not able to compute the modification time in the
      // file system, there is nothing to compare with, so skip the source.
      int sourceTime = times[i];
      if (sourceTime == null) {
        continue;
      }
      // Compare with the modification time in the cache entry.
      CacheEntry entry = context._privatePartition.get(source);
      if (entry != null) {
        if (entry.modificationTime != sourceTime) {
          if (sourceTime == -1) {
            removedSources.add(source);
            PerformanceStatistics
                .cacheConsistencyValidationStatistics.numOfRemoved++;
          } else {
            changedSources.add(source);
            PerformanceStatistics
                .cacheConsistencyValidationStatistics.numOfChanged++;
          }
        }
      }
    }
    for (Source source in changedSources) {
      context._sourceChanged(source);
    }
    for (Source source in removedSources) {
      context._sourceRemoved(source);
    }
    if (changedSources.length > 0 || removedSources.length > 0) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Consistency check took ");
      buffer.write(timer.elapsedMilliseconds);
      buffer.writeln(" ms and found");
      buffer.write("  ");
      buffer.write(changedSources.length);
      buffer.writeln(" changed sources");
      buffer.write("  ");
      buffer.write(removedSources.length);
      buffer.write(" removed sources.");
      context._logInformation(buffer.toString());
    }
    return changedSources.isNotEmpty || removedSources.isNotEmpty;
  }
}

/**
 * An object that manages the partitions that can be shared between analysis
 * contexts.
 */
class PartitionManager {
  /**
   * A table mapping SDK's to the partitions used for those SDK's.
   */
  HashMap<DartSdk, SdkCachePartition> _sdkPartitions =
      new HashMap<DartSdk, SdkCachePartition>();

  /**
   * Clear any cached data being maintained by this manager.
   */
  void clearCache() {
    _sdkPartitions.clear();
  }

  /**
   * Return the partition being used for the given [sdk], creating the partition
   * if necessary.
   */
  SdkCachePartition forSdk(DartSdk sdk) {
    // Call sdk.context now, because when it creates a new
    // InternalAnalysisContext instance, it calls forSdk() again, so creates an
    // SdkCachePartition instance.
    // So, if we initialize context after "partition == null", we end up
    // with two SdkCachePartition instances.
    InternalAnalysisContext sdkContext = sdk.context;
    // Check cache for an existing partition.
    SdkCachePartition partition = _sdkPartitions[sdk];
    if (partition == null) {
      partition = new SdkCachePartition(sdkContext);
      _sdkPartitions[sdk] = partition;
    }
    return partition;
  }
}

/**
 * Representation of a pending computation which is based on the results of
 * analysis that may or may not have been completed.
 */
class PendingFuture<T> {
  /**
   * The context in which this computation runs.
   */
  final AnalysisContextImpl _context;

  /**
   * The target used by this computation to compute its value.
   */
  final AnalysisTarget target;

  /**
   * The function which implements the computation.
   */
  final PendingFutureComputer<T> _computeValue;

  /**
   * The completer that should be completed once the computation has succeeded.
   */
  CancelableCompleter<T> _completer;

  PendingFuture(this._context, this.target, this._computeValue) {
    _completer = new CancelableCompleter<T>(_onCancel);
  }

  /**
   * Retrieve the future which will be completed when this object is
   * successfully evaluated.
   */
  CancelableFuture<T> get future => _completer.future;

  /**
   * Execute [_computeValue], passing it the given [entry], and complete
   * the pending future if it's appropriate to do so.  If the pending future is
   * completed by this call, true is returned; otherwise false is returned.
   *
   * Once this function has returned true, it should not be called again.
   *
   * Other than completing the future, this method is free of side effects.
   * Note that any code the client has attached to the future will be executed
   * in a microtask, so there is no danger of side effects occurring due to
   * client callbacks.
   */
  bool evaluate(CacheEntry entry) {
    assert(!_completer.isCompleted);
    try {
      T result = _computeValue(entry);
      if (result == null) {
        return false;
      } else {
        _completer.complete(result);
        return true;
      }
    } catch (exception, stackTrace) {
      _completer.completeError(exception, stackTrace);
      return true;
    }
  }

  /**
   * No further analysis updates are expected which affect this future, so
   * complete it with an AnalysisNotScheduledError in order to avoid
   * deadlocking the client.
   */
  void forciblyComplete() {
    try {
      throw new AnalysisNotScheduledError();
    } catch (exception, stackTrace) {
      _completer.completeError(exception, stackTrace);
    }
  }

  void _onCancel() {
    _context._cancelFuture(this);
  }
}

/**
 * Provider for analysis results.
 */
abstract class ResultProvider {
  /**
   * This method is invoked by an [InternalAnalysisContext] when the state of
   * the [result] of the [entry] is [CacheState.INVALID], so it is about to be
   * computed.
   *
   * If the provider knows how to provide the value, it sets the value into
   * the [entry] with all required dependencies, and returns `true`.
   *
   * Otherwise, it returns `false` to indicate that the result should be
   * computed as usually.
   */
  bool compute(CacheEntry entry, ResultDescriptor result);
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
    if (factory == null) {
      return super.createCacheFromSourceFactory(factory);
    }
    DartSdk sdk = factory.dartSdk;
    if (sdk == null) {
      throw new ArgumentError(
          "The source factory for an SDK analysis context must have a DartUriResolver");
    }
    return new AnalysisCache(
        <CachePartition>[AnalysisEngine.instance.partitionManager.forSdk(sdk)]);
  }
}
