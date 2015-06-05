// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide
        AnalysisCache,
        CachePartition,
        SdkCachePartition,
        UniversalCachePartition,
        WorkManager;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/dart_work_manager.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

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
   * The next context identifier.
   */
  static int _NEXT_ID = 0;

  /**
   * The unique identifier of this context.
   */
  final int _id = _NEXT_ID++;

  /**
   * A client-provided name used to identify this context, or `null` if the
   * client has not provided a name.
   */
  String name;

  /**
   * The set of analysis options controlling the behavior of this context.
   */
  AnalysisOptionsImpl _options = new AnalysisOptionsImpl();

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

  /**
   * The task manager used to manage the tasks used to analyze code.
   */
  TaskManager _taskManager;

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
   * Cached information used in incremental analysis or `null` if none.
   */
  IncrementalAnalysisCache _incrementalAnalysisCache;

  /**
   * The [TypeProvider] for this context, `null` if not yet created.
   */
  TypeProvider _typeProvider;

  /**
   * The controller for sending [SourcesChangedEvent]s.
   */
  StreamController<SourcesChangedEvent> _onSourcesChangedController;

  /**
   * The listeners that are to be notified when various analysis results are
   * produced in this context.
   */
  List<AnalysisListener> _listeners = new List<AnalysisListener>();

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
   * [incrementalResolutionValidation_lastSource].
   */
  CompilationUnit incrementalResolutionValidation_lastUnit;

  /**
   * A factory to override how the [ResolverVisitor] is created.
   */
  ResolverVisitorFactory resolverVisitorFactory;

  /**
   * A factory to override how the [TypeResolverVisitor] is created.
   */
  TypeResolverVisitorFactory typeResolverVisitorFactory;

  /**
   * A factory to override how [LibraryResolver] is created.
   */
  LibraryResolverFactory libraryResolverFactory;

  /**
   * Initialize a newly created analysis context.
   */
  AnalysisContextImpl() {
    _privatePartition = new UniversalCachePartition(this);
    _cache = createCacheFromSourceFactory(null);
    _taskManager = AnalysisEngine.instance.taskManager;
    // TODO(scheglov) Get WorkManager(Factory)(s) from plugins.
    dartWorkManager = new DartWorkManager(this);
    driver =
        new AnalysisDriver(_taskManager, <WorkManager>[dartWorkManager], this);
    _onSourcesChangedController =
        new StreamController<SourcesChangedEvent>.broadcast();
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
        (this._options.hint && !options.hint) ||
        (this._options.lint && !options.lint) ||
        this._options.preserveComments != options.preserveComments ||
        this._options.enableNullAwareOperators !=
            options.enableNullAwareOperators ||
        this._options.enableStrictCallChecks != options.enableStrictCallChecks;
    int cacheSize = options.cacheSize;
    if (this._options.cacheSize != cacheSize) {
      this._options.cacheSize = cacheSize;
    }
    this._options.analyzeFunctionBodiesPredicate =
        options.analyzeFunctionBodiesPredicate;
    this._options.generateImplicitErrors = options.generateImplicitErrors;
    this._options.generateSdkErrors = options.generateSdkErrors;
    this._options.dart2jsHint = options.dart2jsHint;
    this._options.enableNullAwareOperators = options.enableNullAwareOperators;
    this._options.enableStrictCallChecks = options.enableStrictCallChecks;
    this._options.hint = options.hint;
    this._options.incremental = options.incremental;
    this._options.incrementalApi = options.incrementalApi;
    this._options.incrementalValidation = options.incrementalValidation;
    this._options.lint = options.lint;
    this._options.preserveComments = options.preserveComments;
    if (needsRecompute) {
      dartWorkManager.onAnalysisOptionsChanged();
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
    dartWorkManager.applyPriorityTargets(_priorityOrder);
  }

  @override
  set contentCache(ContentCache value) {
    _contentCache = value;
  }

  @override
  DeclaredVariables get declaredVariables => _declaredVariables;

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
      if (source is Source &&
          entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY &&
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
  HashMap<AnalysisTarget, List<PendingFuture>> get pendingFutureSources_forTesting =>
      _pendingFutureTargets;

  @override
  List<Source> get prioritySources => _priorityOrder;

  @override
  List<AnalysisTarget> get priorityTargets => prioritySources;

  @override
  SourceFactory get sourceFactory => _sourceFactory;

  @override
  void set sourceFactory(SourceFactory factory) {
    if (identical(_sourceFactory, factory)) {
      return;
    } else if (factory.context != null) {
      throw new IllegalStateException(
          "Source factories cannot be shared between contexts");
    }
    if (_sourceFactory != null) {
      _sourceFactory.context = null;
    }
    factory.context = this;
    _sourceFactory = factory;
    _cache = createCacheFromSourceFactory(factory);
    dartWorkManager.onSourceFactoryChanged();
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

  @override
  AnalysisContextStatistics get statistics {
    AnalysisContextStatisticsImpl statistics =
        new AnalysisContextStatisticsImpl();
    // TODO(brianwilkerson) Implement this.
//    visitCacheItems(statistics._internalPutCacheItem);
//    statistics.partitionData = _cache.partitionData;
    return statistics;
  }

  IncrementalAnalysisCache get test_incrementalAnalysisCache {
    return _incrementalAnalysisCache;
  }

  set test_incrementalAnalysisCache(IncrementalAnalysisCache value) {
    _incrementalAnalysisCache = value;
  }

  List<Source> get test_priorityOrder => _priorityOrder;

  @override
  TypeProvider get typeProvider {
    // Make sure a task didn't accidentally try to call back into the context
    // to retrieve the type provider.
    assert(!driver.isTaskRunning);

    if (_typeProvider != null) {
      return _typeProvider;
    }
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
  void set typeProvider(TypeProvider typeProvider) {
    _typeProvider = typeProvider;
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
    List<Source> removedSources =
        new List<Source>.from(changeSet.removedSources);
    for (SourceContainer container in changeSet.removedContainers) {
      _addSourcesInContainer(removedSources, container);
    }
    //
    // Then determine which cached results are no longer valid.
    //
    for (Source source in changeSet.addedSources) {
      _sourceAvailable(source);
    }
    for (Source source in changeSet.changedSources) {
      if (_contentCache.getContents(source) != null) {
        // This source is overridden in the content cache, so the change will
        // have no effect. Just ignore it to avoid wasting time doing
        // re-analysis.
        continue;
      }
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
    for (Source source in changeSet.deletedSources) {
      _sourceDeleted(source);
    }
    for (Source source in removedSources) {
      _sourceRemoved(source);
    }
    dartWorkManager.applyChange(
        changeSet.addedSources, changeSet.changedSources, removedSources);
    _onSourcesChangedController.add(new SourcesChangedEvent(changeSet));
  }

  @override
  String computeDocumentationComment(Element element) {
    if (element == null) {
      return null;
    }
    Source source = element.source;
    if (source == null) {
      return null;
    }
    CompilationUnit unit = parseCompilationUnit(source);
    if (unit == null) {
      return null;
    }
    NodeLocator locator = new NodeLocator(element.nameOffset);
    AstNode nameNode = locator.searchWithin(unit);
    while (nameNode != null) {
      if (nameNode is AnnotatedNode) {
        Comment comment = nameNode.documentationComment;
        if (comment == null) {
          return null;
        }
        StringBuffer buffer = new StringBuffer();
        List<Token> tokens = comment.tokens;
        for (int i = 0; i < tokens.length; i++) {
          if (i > 0) {
            buffer.write("\n");
          }
          buffer.write(tokens[i].lexeme);
        }
        return buffer.toString();
      }
      nameNode = nameNode.parent;
    }
    return null;
  }

  @override
  List<AnalysisError> computeErrors(Source source) =>
      _computeResult(source, DART_ERRORS);

  @override
  List<Source> computeExportedLibraries(Source source) =>
      _computeResult(source, EXPORTED_LIBRARIES);

  @override
  // TODO(brianwilkerson) Implement this.
  HtmlElement computeHtmlElement(Source source) => null;

  @override
  List<Source> computeImportedLibraries(Source source) =>
      _computeResult(source, EXPLICITLY_IMPORTED_LIBRARIES);

  @override
  SourceKind computeKindOf(Source source) {
    String name = source.shortName;
    if (AnalysisEngine.isDartFileName(name)) {
      return _computeResult(source, SOURCE_KIND);
    } else if (AnalysisEngine.isHtmlFileName(name)) {
      return SourceKind.HTML;
    }
    return SourceKind.UNKNOWN;
  }

  @override
  LibraryElement computeLibraryElement(Source source) {
    //_computeResult(source, HtmlEntry.ELEMENT);
    return _computeResult(source, LIBRARY_ELEMENT);
  }

  @override
  LineInfo computeLineInfo(Source source) => _computeResult(source, LINE_INFO);

  @override
  @deprecated
  CompilationUnit computeResolvableCompilationUnit(Source source) {
    return null;
  }

  @override
  CancelableFuture<CompilationUnit> computeResolvedCompilationUnitAsync(
      Source unitSource, Source librarySource) {
    if (!AnalysisEngine.isDartFileName(unitSource.shortName) ||
        !AnalysisEngine.isDartFileName(librarySource.shortName)) {
      return new CancelableFuture.error(new AnalysisNotScheduledError());
    }
    return new _AnalysisFutureHelper<CompilationUnit>(this).computeAsync(
        new LibrarySpecificUnit(librarySource, unitSource), (CacheEntry entry) {
      CacheState state = entry.getState(RESOLVED_UNIT);
      if (state == CacheState.ERROR) {
        throw entry.exception;
      } else if (state == CacheState.INVALID) {
        return null;
      }
      return entry.getValue(RESOLVED_UNIT);
    });
  }

  /**
   * Create an analysis cache based on the given source [factory].
   */
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    if (factory == null) {
      return new AnalysisCache(<CachePartition>[_privatePartition]);
    }
    DartSdk sdk = factory.dartSdk;
    if (sdk == null) {
      return new AnalysisCache(<CachePartition>[_privatePartition]);
    }
    return new AnalysisCache(<CachePartition>[
      AnalysisEngine.instance.partitionManager_new.forSdk(sdk),
      _privatePartition
    ]);
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
  }

  @override
  List<CompilationUnit> ensureResolvedDartUnits(Source unitSource) {
    // Check every library.
    List<CompilationUnit> units = <CompilationUnit>[];
    List<Source> containingLibraries = getLibrariesContaining(unitSource);
    for (Source librarySource in containingLibraries) {
      LibrarySpecificUnit target =
          new LibrarySpecificUnit(librarySource, unitSource);
      CompilationUnit unit = _cache.getValue(target, RESOLVED_UNIT);
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
    // Schedule recomputing RESOLVED_UNIT results.
    for (Source librarySource in containingLibraries) {
      LibrarySpecificUnit target =
          new LibrarySpecificUnit(librarySource, unitSource);
      if (_cache.getState(target, RESOLVED_UNIT) == CacheState.FLUSHED) {
        dartWorkManager.addPriorityResult(target, RESOLVED_UNIT);
      }
    }
    return null;
  }

  @override
  bool exists(Source source) {
    if (source == null) {
      return false;
    }
    if (_contentCache.getContents(source) != null) {
      return true;
    }
    return source.exists();
  }

  @override
  CacheEntry getCacheEntry(AnalysisTarget target) {
    CacheEntry entry = _cache.get(target);
    if (entry == null) {
      entry = new CacheEntry(target);
      if (target is Source) {
        entry.modificationTime = getModificationStamp(target);
      }
      _cache.put(entry);
    }
    return entry;
  }

  @override
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource) {
    AnalysisTarget target = new LibrarySpecificUnit(librarySource, unitSource);
    return _cache.getValue(target, COMPILATION_UNIT_ELEMENT);
  }

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
  InternalAnalysisContext getContextFor(Source source) {
    InternalAnalysisContext context = _cache.getContextFor(source);
    return context == null ? this : context;
  }

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
      if (AnalysisEngine.isHtmlFileName(sourceName)) {
        return computeHtmlElement(source);
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
    return dartWorkManager.getErrors(source);
  }

  @override
  HtmlElement getHtmlElement(Source source) {
    // TODO(brianwilkerson) Implement this.
//    SourceEntry sourceEntry = getReadableSourceEntryOrNull(source);
//    if (sourceEntry is HtmlEntry) {
//      return sourceEntry.getValue(HtmlEntry.ELEMENT);
//    }
    return null;
  }

  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    SourceKind sourceKind = getKindOf(source);
    if (sourceKind == null) {
      return Source.EMPTY_LIST;
    }
    List<Source> htmlSources = <Source>[];
    while (true) {
      if (sourceKind == SourceKind.PART) {
        List<Source> librarySources = getLibrariesContaining(source);
        for (Source source in _cache.sources) {
          CacheEntry entry = _cache.get(source);
          if (entry.getValue(SOURCE_KIND) == SourceKind.HTML) {
            List<Source> referencedLibraries =
                (entry as HtmlEntry).getValue(HtmlEntry.REFERENCED_LIBRARIES);
            if (_containsAny(referencedLibraries, librarySources)) {
              htmlSources.add(source);
            }
          }
        }
      } else {
        for (Source source in _cache.sources) {
          CacheEntry entry = _cache.get(source);
          if (entry.getValue(SOURCE_KIND) == SourceKind.HTML) {
            List<Source> referencedLibraries =
                (entry as HtmlEntry).getValue(HtmlEntry.REFERENCED_LIBRARIES);
            if (_contains(referencedLibraries, source)) {
              htmlSources.add(source);
            }
          }
        }
      }
      break;
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
      return _cache.getValue(source, SOURCE_KIND);
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
    // TODO(brianwilkerson) Implement this.
//    cache.CacheEntry entry = getReadableSourceEntryOrNull(htmlSource);
//    if (entry is HtmlEntry) {
//      HtmlEntry htmlEntry = entry;
//      return htmlEntry.getValue(HtmlEntry.REFERENCED_LIBRARIES);
//    }
    return Source.EMPTY_LIST;
  }

  @override
  LibraryElement getLibraryElement(Source source) =>
      _cache.getValue(source, LIBRARY_ELEMENT);

  @override
  LineInfo getLineInfo(Source source) => _cache.getValue(source, LINE_INFO);

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

  /**
   * Return the cache entry associated with the given [target], or `null` if
   * there is no entry associated with the target.
   */
  CacheEntry getReadableSourceEntryOrNull(AnalysisTarget target) =>
      _cache.get(target);

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
    return _cache.getValue(
        new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT);
  }

  @override
  ht.HtmlUnit getResolvedHtmlUnit(Source htmlSource) {
    // TODO(brianwilkerson) Implement this.
//    SourceEntry sourceEntry = getReadableSourceEntryOrNull(htmlSource);
//    if (sourceEntry is HtmlEntry) {
//      HtmlEntry htmlEntry = sourceEntry;
//      return htmlEntry.getValue(HtmlEntry.RESOLVED_UNIT);
//    }
    return null;
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
    bool changed = newContents != originalContents;
    if (newContents != null) {
      if (newContents != originalContents) {
        _incrementalAnalysisCache =
            IncrementalAnalysisCache.clear(_incrementalAnalysisCache, source);
        if (!analysisOptions.incremental ||
            !_tryPoorMansIncrementalResolution(source, newContents)) {
          _sourceChanged(source);
        }
        entry.modificationTime = _contentCache.getModificationStamp(source);
        entry.setValue(CONTENT, newContents, TargetedResult.EMPTY_LIST);
      } else {
        entry.modificationTime = _contentCache.getModificationStamp(source);
      }
    } else if (originalContents != null) {
      _incrementalAnalysisCache =
          IncrementalAnalysisCache.clear(_incrementalAnalysisCache, source);
      changed = newContents != originalContents;
      // We are removing the overlay for the file, check if the file's
      // contents is the same as it was in the overlay.
      try {
        TimestampedData<String> fileContents = getContents(source);
        String fileContentsData = fileContents.data;
        if (fileContentsData == originalContents) {
          entry.setValue(CONTENT, fileContentsData, TargetedResult.EMPTY_LIST);
          entry.modificationTime = fileContents.modificationTime;
          changed = false;
        }
      } catch (e) {}
      // If not the same content (e.g. the file is being closed without save),
      // then force analysis.
      if (changed) {
        _sourceChanged(source);
      }
    }
    if (notify && changed) {
      _onSourcesChangedController
          .add(new SourcesChangedEvent.changedContent(source, newContents));
    }
    return changed;
  }

  @override
  void invalidateLibraryHints(Source librarySource) {
    List<Source> sources = _cache.getValue(librarySource, UNITS);
    if (sources != null) {
      for (Source source in sources) {
        getCacheEntry(source).setState(HINTS, CacheState.INVALID);
      }
    }
  }

  @override
  bool isClientLibrary(Source librarySource) {
    CacheEntry entry = _cache.get(librarySource);
    return entry.getValue(IS_CLIENT) && entry.getValue(IS_LAUNCHABLE);
  }

  @override
  bool isServerLibrary(Source librarySource) {
    CacheEntry entry = _cache.get(librarySource);
    return !entry.getValue(IS_CLIENT) && entry.getValue(IS_LAUNCHABLE);
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
    return _computeResult(source, PARSED_UNIT);
  }

  @override
  ht.HtmlUnit parseHtmlUnit(Source source) {
    if (!AnalysisEngine.isHtmlFileName(source.shortName)) {
      return null;
    }
    // TODO(brianwilkerson) Implement HTML analysis.
    return null; //_computeResult(source, null);
  }

  @override
  AnalysisResult performAnalysisTask() {
    return PerformanceStatistics.performAnaysis.makeCurrentWhile(() {
      bool done = !driver.performAnalysisTask();
      if (done) {
        done = !_validateCacheConsistency();
      }
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
      setValue(BUILD_FUNCTION_TYPE_ALIASES_ERRORS, AnalysisError.NO_ERRORS);
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
      setValue(IS_CLIENT, true);
      setValue(IS_LAUNCHABLE, false);
      setValue(LIBRARY_ELEMENT, library);
      setValue(LIBRARY_ELEMENT1, library);
      setValue(LIBRARY_ELEMENT2, library);
      setValue(LIBRARY_ELEMENT3, library);
      setValue(LIBRARY_ELEMENT4, library);
      setValue(LIBRARY_ELEMENT5, library);
      setValue(LINE_INFO, new LineInfo(<int>[0]));
      setValue(PARSE_ERRORS, AnalysisError.NO_ERRORS);
      entry.setState(PARSED_UNIT, CacheState.FLUSHED);
      entry.setState(RESOLVE_TYPE_NAMES_ERRORS, CacheState.FLUSHED);
      setValue(SCAN_ERRORS, AnalysisError.NO_ERRORS);
      setValue(SOURCE_KIND, SourceKind.LIBRARY);
      entry.setState(TOKEN_STREAM, CacheState.FLUSHED);
      setValue(UNITS, <Source>[librarySource]);

      LibrarySpecificUnit unit =
          new LibrarySpecificUnit(librarySource, librarySource);
      entry = getCacheEntry(unit);
      setValue(HINTS, AnalysisError.NO_ERRORS);
      // dartEntry.setValue(LINTS, AnalysisError.NO_ERRORS);
      entry.setState(RESOLVE_REFERENCES_ERRORS, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT1, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT2, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT3, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT4, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT5, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT6, CacheState.FLUSHED);
      // USED_IMPORTED_ELEMENTS
      // USED_LOCAL_ELEMENTS
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
    if (!AnalysisEngine.isDartFileName(unitSource.shortName) ||
        !AnalysisEngine.isDartFileName(librarySource.shortName)) {
      return null;
    }
    return _computeResult(
        new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT);
  }

  @override
  ht.HtmlUnit resolveHtmlUnit(Source htmlSource) {
    computeHtmlElement(htmlSource);
    return parseHtmlUnit(htmlSource);
  }

  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    if (_contentRangeChanged(source, contents, offset, oldLength, newLength)) {
      _onSourcesChangedController.add(new SourcesChangedEvent.changedRange(
          source, contents, offset, oldLength, newLength));
    }
  }

  @override
  void setContents(Source source, String contents) {
    _contentsChanged(source, contents, true);
  }

  @override
  bool shouldErrorsBeAnalyzed(Source source, Object entry) {
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
  void visitCacheItems(void callback(Source source, SourceEntry dartEntry,
      DataDescriptor rowDesc, CacheState state)) {
    // TODO(brianwilkerson) Figure out where this is used and adjust the call
    // sites to use CacheEntry's.
//    bool hintsEnabled = _options.hint;
//    bool lintsEnabled = _options.lint;
//    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
//    while (iterator.moveNext()) {
//      Source source = iterator.key;
//      cache.CacheEntry entry = iterator.value;
//      for (DataDescriptor descriptor in entry.descriptors) {
//        if (descriptor == DartEntry.SOURCE_KIND) {
//          // The source kind is always valid, so the state isn't interesting.
//          continue;
//        } else if (descriptor == DartEntry.CONTAINING_LIBRARIES) {
//          // The list of containing libraries is always valid, so the state
//          // isn't interesting.
//          continue;
//        } else if (descriptor == DartEntry.PUBLIC_NAMESPACE) {
//          // The public namespace isn't computed by performAnalysisTask()
//          // and therefore isn't interesting.
//          continue;
//        } else if (descriptor == HtmlEntry.HINTS) {
//          // We are not currently recording any hints related to HTML.
//          continue;
//        }
//        callback(
//            source, entry, descriptor, entry.getState(descriptor));
//      }
//      if (entry is DartEntry) {
//        // get library-specific values
//        List<Source> librarySources = getLibrariesContaining(source);
//        for (Source librarySource in librarySources) {
//          for (DataDescriptor descriptor in entry.libraryDescriptors) {
//            if (descriptor == DartEntry.BUILT_ELEMENT ||
//                descriptor == DartEntry.BUILT_UNIT) {
//              // These values are not currently being computed, so their state
//              // is not interesting.
//              continue;
//            } else if (!entry.explicitlyAdded &&
//                !_generateImplicitErrors &&
//                (descriptor == DartEntry.VERIFICATION_ERRORS ||
//                    descriptor == DartEntry.HINTS ||
//                    descriptor == DartEntry.LINTS)) {
//              continue;
//            } else if (source.isInSystemLibrary &&
//                !_generateSdkErrors &&
//                (descriptor == DartEntry.VERIFICATION_ERRORS ||
//                    descriptor == DartEntry.HINTS ||
//                    descriptor == DartEntry.LINTS)) {
//              continue;
//            } else if (!hintsEnabled && descriptor == DartEntry.HINTS) {
//              continue;
//            } else if (!lintsEnabled && descriptor == DartEntry.LINTS) {
//              continue;
//            }
//            callback(librarySource, entry, descriptor,
//                entry.getStateInLibrary(descriptor, librarySource));
//          }
//        }
//      }
//    }
  }

  /**
   * Visit all entries of the content cache.
   */
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

  Object /*V*/ _computeResult(
      AnalysisTarget target, ResultDescriptor /*<V>*/ descriptor) {
    CacheEntry entry = getCacheEntry(target);
    CacheState state = entry.getState(descriptor);
    if (state == CacheState.FLUSHED || state == CacheState.INVALID) {
      driver.computeResult(target, descriptor);
    }
    state = entry.getState(descriptor);
    if (state == CacheState.ERROR) {
      throw new AnalysisException(
          'Cannot compute $descriptor for $target', entry.exception);
    }
    return entry.getValue(descriptor);
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
        // TODO(brianwilkerson) Find a better way to do incremental analysis.
//        if (_options.incremental) {
//          _incrementalAnalysisCache = IncrementalAnalysisCache.update(
//              _incrementalAnalysisCache, source, originalContents, contents,
//              offset, oldLength, newLength, _cache.get(source));
//        }
        _sourceChanged(source);
        changed = true;
        CacheEntry entry = _cache.get(source);
        if (entry != null) {
          entry.modificationTime = _contentCache.getModificationStamp(source);
          entry.setValue(CONTENT, contents, TargetedResult.EMPTY_LIST);
        }
      }
    } else if (originalContents != null) {
      _incrementalAnalysisCache =
          IncrementalAnalysisCache.clear(_incrementalAnalysisCache, source);
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
    for (Source source in _cache.sources) {
      CacheEntry entry = _cache.get(source);
      if (entry.getValue(SOURCE_KIND) == kind) {
        sources.add(source);
      }
    }
    return sources;
  }

  /**
   * Look at the given [source] to see whether a task needs to be performed
   * related to it. If so, add the source to the set of sources that need to be
   * processed. This method is intended to be used for testing purposes only.
   */
  void _getSourcesNeedingProcessing(Source source, CacheEntry entry,
      bool isPriority, bool hintsEnabled, bool lintsEnabled,
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
        if (shouldErrorsBeAnalyzed(source, unitEntry)) {
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
//          if (lintsEnabled) {
//            state = unitEntry.getState(LINTS);
//            if (state == CacheState.INVALID ||
//                (isPriority && state == CacheState.FLUSHED)) {
//              sources.add(source);
//              return;
//            } else if (state == CacheState.ERROR) {
//              return;
//            }
//          }
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

  @override
  CachePartition get privateAnalysisCachePartition => _privatePartition;

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
    CacheEntry entry = _cache.get(source);
    if (entry == null) {
      _createCacheEntry(source, true);
    } else {
      entry.modificationTime = getModificationStamp(source);
      entry.setState(CONTENT, CacheState.INVALID);
    }
  }

  /**
   * Invalidate the [source] that was changed and any sources that referenced
   * the source before it existed.
   */
  void _sourceChanged(Source source) {
    CacheEntry entry = _cache.get(source);
    // If the source is removed, we don't care about it.
    if (entry == null) {
      return;
    }
    // Check whether the content of the source is the same as it was the last
    // time.
    String sourceContent = entry.getValue(CONTENT);
    if (sourceContent != null) {
      entry.setState(CONTENT, CacheState.FLUSHED);
      try {
        TimestampedData<String> fileContents = getContents(source);
        if (fileContents.data == sourceContent) {
          int time = fileContents.modificationTime;
          for (CacheEntry entry in _entriesFor(source)) {
            entry.modificationTime = time;
          }
          return;
        }
      } catch (e) {}
    }
    // We need to invalidate the cache.
    entry.setState(CONTENT, CacheState.INVALID);
    dartWorkManager.applyChange(
        Source.EMPTY_LIST, <Source>[source], Source.EMPTY_LIST);
  }

  /**
   * Record that the give [source] has been deleted.
   */
  void _sourceDeleted(Source source) {
    // TODO(brianwilkerson) Implement this.
//    SourceEntry sourceEntry = _cache.get(source);
//    if (sourceEntry is HtmlEntry) {
//      HtmlEntry htmlEntry = sourceEntry;
//      htmlEntry.recordContentError(new CaughtException(
//          new AnalysisException("This source was marked as being deleted"),
//          null));
//    } else if (sourceEntry is DartEntry) {
//      DartEntry dartEntry = sourceEntry;
//      HashSet<Source> libraries = new HashSet<Source>();
//      for (Source librarySource in getLibrariesContaining(source)) {
//        libraries.add(librarySource);
//        for (Source dependentLibrary
//            in getLibrariesDependingOn(librarySource)) {
//          libraries.add(dependentLibrary);
//        }
//      }
//      for (Source librarySource in libraries) {
//        _invalidateLibraryResolution(librarySource);
//      }
//      dartEntry.recordContentError(new CaughtException(
//          new AnalysisException("This source was marked as being deleted"),
//          null));
//    }
    _removeFromPriorityOrder(source);
  }

  /**
   * Record that the given [source] has been removed.
   */
  void _sourceRemoved(Source source) {
    _cache.remove(source);
    _removeFromPriorityOrder(source);
  }

  /**
   * TODO(scheglov) A hackish, limited incremental resolution implementation.
   */
  bool _tryPoorMansIncrementalResolution(Source unitSource, String newCode) {
    return PerformanceStatistics.incrementalAnalysis.makeCurrentWhile(() {
      incrementalResolutionValidation_lastUnitSource = null;
      incrementalResolutionValidation_lastLibrarySource = null;
      incrementalResolutionValidation_lastUnit = null;
      // prepare the entry
      CacheEntry sourceEntry = _cache.get(unitSource);
      if (sourceEntry == null) {
        return false;
      }
      // prepare the (only) library source
      List<Source> librarySources = getLibrariesContaining(unitSource);
      if (librarySources.length != 1) {
        return false;
      }
      Source librarySource = librarySources[0];
      CacheEntry unitEntry =
          _cache.get(new LibrarySpecificUnit(librarySource, unitSource));
      if (unitEntry == null) {
        return false;
      }
      // prepare the library element
      LibraryElement libraryElement = getLibraryElement(librarySource);
      if (libraryElement == null) {
        return false;
      }
      // prepare the existing unit
      CompilationUnit oldUnit =
          getResolvedCompilationUnit2(unitSource, librarySource);
      if (oldUnit == null) {
        return false;
      }
      // do resolution
      Stopwatch perfCounter = new Stopwatch()..start();
      PoorMansIncrementalResolver resolver = new PoorMansIncrementalResolver(
          typeProvider, unitSource, null, sourceEntry, unitEntry, oldUnit,
          analysisOptions.incrementalApi, analysisOptions);
      bool success = resolver.resolve(newCode);
      AnalysisEngine.instance.instrumentationService.logPerformance(
          AnalysisPerformanceKind.INCREMENTAL, perfCounter,
          'success=$success,context_id=$_id,code_length=${newCode.length}');
      if (!success) {
        return false;
      }
      // if validation, remember the result, but throw it away
      if (analysisOptions.incrementalValidation) {
        incrementalResolutionValidation_lastUnitSource = oldUnit.element.source;
        incrementalResolutionValidation_lastLibrarySource =
            oldUnit.element.library.source;
        incrementalResolutionValidation_lastUnit = oldUnit;
        return false;
      }
      // prepare notice
      {
        ChangeNoticeImpl notice = getNotice(unitSource);
        notice.resolvedDartUnit = oldUnit;
        AnalysisErrorInfo errorInfo = getErrors(unitSource);
        notice.setErrors(errorInfo.errors, errorInfo.lineInfo);
      }
      // schedule
      dartWorkManager.unitIncrementallyResolved(librarySource, unitSource);
      // OK
      return true;
    });
  }

  /**
   * Check the cache for any invalid entries (entries whose modification time
   * does not match the modification time of the source associated with the
   * entry). Invalid entries will be marked as invalid so that the source will
   * be re-analyzed. Return `true` if at least one entry was invalid.
   */
  bool _validateCacheConsistency() {
    int consistencyCheckStart = JavaSystem.nanoTime();
    HashSet<Source> changedSources = new HashSet<Source>();
    HashSet<Source> missingSources = new HashSet<Source>();
    for (Source source in _cache.sources) {
      CacheEntry entry = _cache.get(source);
      int sourceTime = getModificationStamp(source);
      if (sourceTime != entry.modificationTime) {
        changedSources.add(source);
      }
      if (entry.exception != null) {
        if (!exists(source)) {
          missingSources.add(source);
        }
      }
    }
    for (Source source in changedSources) {
      _sourceChanged(source);
    }
    int removalCount = 0;
    for (Source source in missingSources) {
      if (getLibrariesContaining(source).isEmpty &&
          getLibrariesDependingOn(source).isEmpty) {
        _cache.remove(source);
        removalCount++;
      }
    }
    int consistencyCheckEnd = JavaSystem.nanoTime();
    if (changedSources.length > 0 || missingSources.length > 0) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Consistency check took ");
      buffer.write((consistencyCheckEnd - consistencyCheckStart) / 1000000.0);
      buffer.writeln(" ms and found");
      buffer.write("  ");
      buffer.write(changedSources.length);
      buffer.writeln(" inconsistent entries");
      buffer.write("  ");
      buffer.write(missingSources.length);
      buffer.write(" missing sources (");
      buffer.write(removalCount);
      buffer.writeln(" removed");
      for (Source source in missingSources) {
        buffer.write("    ");
        buffer.writeln(source.fullName);
      }
      _logInformation(buffer.toString());
    }
    return changedSources.length > 0;
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
 * An [AnalysisContext] that only contains sources for a Dart SDK.
 */
class SdkAnalysisContext extends AnalysisContextImpl {
  @override
  AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    if (factory == null) {
      return super.createCacheFromSourceFactory(factory);
    }
    DartSdk sdk = factory.dartSdk;
    if (sdk == null) {
      throw new IllegalArgumentException(
          "The source factory for an SDK analysis context must have a DartUriResolver");
    }
    return new AnalysisCache(<CachePartition>[
      AnalysisEngine.instance.partitionManager_new.forSdk(sdk)
    ]);
  }
}

/**
 * A helper class used to create futures for AnalysisContextImpl. Using a helper
 * class allows us to preserve the generic parameter T.
 */
class _AnalysisFutureHelper<T> {
  final AnalysisContextImpl _context;

  _AnalysisFutureHelper(this._context);

  /**
   * Return a future that will be completed with the result of calling
   * [computeValue].  If [computeValue] returns non-`null`, the future will be
   * completed immediately with the resulting value.  If it returns `null`, then
   * it will be re-executed in the future, after the next time the cached
   * information for [target] has changed.  If [computeValue] throws an
   * exception, the future will fail with that exception.
   *
   * If the [computeValue] still returns `null` after there is no further
   * analysis to be done for [target], then the future will be completed with
   * the error AnalysisNotScheduledError.
   *
   * Since [computeValue] will be called while the state of analysis is being
   * updated, it should be free of side effects so that it doesn't cause
   * reentrant changes to the analysis state.
   */
  CancelableFuture<T> computeAsync(
      AnalysisTarget target, T computeValue(CacheEntry entry)) {
    if (_context.isDisposed) {
      // No further analysis is expected, so return a future that completes
      // immediately with AnalysisNotScheduledError.
      return new CancelableFuture.error(new AnalysisNotScheduledError());
    }
    CacheEntry entry = _context.getReadableSourceEntryOrNull(target);
    if (entry == null) {
      return new CancelableFuture.error(new AnalysisNotScheduledError());
    }
    PendingFuture pendingFuture =
        new PendingFuture<T>(_context, target, computeValue);
    if (!pendingFuture.evaluate(entry)) {
      _context._pendingFutureTargets
          .putIfAbsent(target, () => <PendingFuture>[])
          .add(pendingFuture);
    }
    return pendingFuture.future;
  }
}
