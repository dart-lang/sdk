// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/cache.dart' as cache;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * An [AnalysisContext] in which analysis can be performed.
 */
class AnalysisContextImpl implements InternalAnalysisContext {
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
  cache.CachePartition _privatePartition;

  /**
   * The cache in which information about the results associated with targets
   * are stored.
   */
  cache.AnalysisCache _cache;

  /**
   * The task manager used to manage the tasks used to analyze code.
   */
  TaskManager _taskManager;

  /**
   * The analysis driver used to perform analysis.
   */
  AnalysisDriver _driver;

  /**
   * A list containing sources for which data should not be flushed.
   */
  List<Source> _priorityOrder = Source.EMPTY_ARRAY;

  /**
   * A map from all sources for which there are futures pending to a list of
   * the corresponding PendingFuture objects.  These sources will be analyzed
   * in the same way as priority sources, except with higher priority.
   */
  HashMap<Source, List<PendingFuture>> _pendingFutureSources =
      new HashMap<Source, List<PendingFuture>>();

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
    _privatePartition = new cache.UniversalCachePartition(this,
        AnalysisOptionsImpl.DEFAULT_CACHE_SIZE,
        new ContextRetentionPolicy(this));
    _cache = createCacheFromSourceFactory(null);
    _taskManager = AnalysisEngine.instance.taskManager;
    _driver = new AnalysisDriver(_taskManager, this);
    _onSourcesChangedController =
        new StreamController<SourcesChangedEvent>.broadcast();
  }

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
        this._options.preserveComments != options.preserveComments ||
        this._options.enableNullAwareOperators !=
            options.enableNullAwareOperators ||
        this._options.enableStrictCallChecks != options.enableStrictCallChecks;
    int cacheSize = options.cacheSize;
    if (this._options.cacheSize != cacheSize) {
      this._options.cacheSize = cacheSize;
      _privatePartition.maxCacheSize = cacheSize;
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
      _invalidateAllLocalResolutionInformation(false);
    }
  }

  @override
  void set analysisPriorityOrder(List<Source> sources) {
    if (sources == null || sources.isEmpty) {
      _priorityOrder = Source.EMPTY_ARRAY;
    } else {
      while (sources.remove(null)) {
        // Nothing else to do.
      }
      if (sources.isEmpty) {
        _priorityOrder = Source.EMPTY_ARRAY;
      } else {
        _priorityOrder = sources;
      }
    }
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
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
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
    // TODO(brianwilkerson) This needs to filter out libraries that do not
    // reference dart:html, either directly or indirectly.
    List<Source> sources = new List<Source>();
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      cache.CacheEntry entry = iterator.value;
      if (target is Source &&
          entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY &&
          !target.isInSystemLibrary) {
//          DartEntry dartEntry = (DartEntry) sourceEntry;
//          if (dartEntry.getValue(DartEntry.IS_LAUNCHABLE) && !dartEntry.getValue(DartEntry.IS_CLIENT)) {
        sources.add(target);
//          }
      }
    }
    return sources;
  }

  @override
  List<Source> get launchableServerLibrarySources {
    // TODO(brianwilkerson) This needs to filter out libraries that reference
    // dart:html, either directly or indirectly.
    List<Source> sources = new List<Source>();
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      cache.CacheEntry entry = iterator.value;
      if (target is Source &&
          entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY &&
          !target.isInSystemLibrary) {
//          DartEntry dartEntry = (DartEntry) sourceEntry;
//          if (dartEntry.getValue(DartEntry.IS_LAUNCHABLE) && !dartEntry.getValue(DartEntry.IS_CLIENT)) {
        sources.add(target);
//          }
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
  HashMap<Source, List<PendingFuture>> get pendingFutureSources_forTesting =>
      _pendingFutureSources;

  @override
  List<Source> get prioritySources => _priorityOrder;

  @override
  List<AnalysisTarget> get priorityTargets => prioritySources;

  @override
  List<Source> get refactoringUnsafeSources {
    // TODO(brianwilkerson) Implement this.
    List<Source> sources = new List<Source>();
//    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
//    while (iterator.moveNext()) {
//      cache.CacheEntry entry = iterator.value;
//      AnalysisTarget target = iterator.key;
//      if (target is Source &&
//          !target.isInSystemLibrary &&
//          !entry.isRefactoringSafe) {
//        sources.add(target);
//      }
//    }
    return sources;
  }

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
    _invalidateAllLocalResolutionInformation(true);
  }

  @override
  List<Source> get sources {
    List<Source> sources = new List<Source>();
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      if (target is Source) {
        sources.add(target);
      }
    }
    return sources;
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

    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
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

  /**
   * Return `true` if the (new) task model should be used to perform analysis.
   */
  bool get useTaskModel => AnalysisEngine.instance.useTaskModel;

  @override
  void addListener(AnalysisListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void addSourceInfo(Source source, SourceEntry info) {
    // TODO(brianwilkerson) This method needs to be replaced by something that
    // will copy CacheEntry's.
//    _cache.put(source, info);
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
    NodeLocator locator = new NodeLocator.con1(element.nameOffset);
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
  List<Source> computeImportedLibraries(Source source) => _computeResult(
      source, IMPORTED_LIBRARIES);

  @override
  SourceKind computeKindOf(Source source) =>
      _computeResult(source, SOURCE_KIND);

  @override
  LibraryElement computeLibraryElement(Source source) =>
      _computeResult(source, LIBRARY_ELEMENT); //_computeResult(source, HtmlEntry.ELEMENT);

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
    // TODO(brianwilkerson) Implement this.
    return new CancelableFuture<CompilationUnit>(() => null);
//    return new _AnalysisFutureHelper<CompilationUnit>(this).computeAsync(
//        unitSource, (SourceEntry sourceEntry) {
//      if (sourceEntry is DartEntry) {
//        if (sourceEntry.getStateInLibrary(
//                DartEntry.RESOLVED_UNIT, librarySource) ==
//            CacheState.ERROR) {
//          throw sourceEntry.exception;
//        }
//        return sourceEntry.getValueInLibrary(
//            DartEntry.RESOLVED_UNIT, librarySource);
//      }
//      throw new AnalysisNotScheduledError();
//    });
  }

  /**
   * Create an analysis cache based on the given source [factory].
   */
  cache.AnalysisCache createCacheFromSourceFactory(SourceFactory factory) {
    if (factory == null) {
      return new cache.AnalysisCache(<cache.CachePartition>[_privatePartition]);
    }
    DartSdk sdk = factory.dartSdk;
    if (sdk == null) {
      return new cache.AnalysisCache(<cache.CachePartition>[_privatePartition]);
    }
    return new cache.AnalysisCache(<cache.CachePartition>[
      AnalysisEngine.instance.partitionManager_new.forSdk(sdk),
      _privatePartition
    ]);
  }

  @override
  void dispose() {
    _disposed = true;
    for (List<PendingFuture> pendingFutures in _pendingFutureSources.values) {
      for (PendingFuture pendingFuture in pendingFutures) {
        pendingFuture.forciblyComplete();
      }
    }
    _pendingFutureSources.clear();
  }

  @override
  List<CompilationUnit> ensureResolvedDartUnits(Source unitSource) {
    // TODO(brianwilkerson) Implement this.
    return null;
//    cache.CacheEntry entry = _cache.get(unitSource);
//    // Check every library.
//    List<CompilationUnit> units = <CompilationUnit>[];
//    List<Source> containingLibraries = entry.containingLibraries;
//    for (Source librarySource in containingLibraries) {
//      CompilationUnit unit =
//          entry.getValueInLibrary(DartEntry.RESOLVED_UNIT, librarySource);
//      if (unit == null) {
//        units = null;
//        break;
//      }
//      units.add(unit);
//    }
//    // Invalidate the flushed RESOLVED_UNIT to force it eventually.
//    if (units == null) {
//      bool shouldBeScheduled = false;
//      for (Source librarySource in containingLibraries) {
//        if (entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, librarySource) ==
//            CacheState.FLUSHED) {
//          entry.setStateInLibrary(
//              DartEntry.RESOLVED_UNIT, librarySource, CacheState.INVALID);
//          shouldBeScheduled = true;
//        }
//      }
//      if (shouldBeScheduled) {
//        _workManager.add(unitSource, SourcePriority.UNKNOWN);
//      }
//      // We cannot provide resolved units right now,
//      // but the future analysis will.
//      return null;
//    }
//    // done
//    return units;
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

  Element findElementById(int id) {
    // TODO(brianwilkerson) Implement this.
    return null;
//    _ElementByIdFinder finder = new _ElementByIdFinder(id);
//    try {
//      MapIterator<AnalysisTarget, cache.CacheEntry> iterator =
//          _cache.iterator();
//      while (iterator.moveNext()) {
//        cache.CacheEntry entry = iterator.value;
//        if (entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY) {
//          DartEntry dartEntry = entry;
//          LibraryElement library = dartEntry.getValue(DartEntry.ELEMENT);
//          if (library != null) {
//            library.accept(finder);
//          }
//        }
//      }
//    } on _ElementByIdFinderException {
//      return finder.result;
//    }
//    return null;
  }

  @override
  cache.CacheEntry getCacheEntry(AnalysisTarget target) {
    cache.CacheEntry entry = _cache.get(target);
    if (entry == null) {
      entry = new cache.CacheEntry();
      _cache.put(target, entry);
    }
    return entry;
  }

  @override
  CompilationUnitElement getCompilationUnitElement(
      Source unitSource, Source librarySource) {
    AnalysisTarget target = new LibrarySpecificUnit(librarySource, unitSource);
    return _getResult(target, COMPILATION_UNIT_ELEMENT);
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
  AnalysisErrorInfo getErrors(Source source) => _getResult(source, DART_ERRORS);

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
      return Source.EMPTY_ARRAY;
    }
    List<Source> htmlSources = new List<Source>();
    while (true) {
      if (sourceKind == SourceKind.PART) {
        List<Source> librarySources = getLibrariesContaining(source);
        MapIterator<AnalysisTarget, cache.CacheEntry> iterator =
            _cache.iterator();
        while (iterator.moveNext()) {
          cache.CacheEntry entry = iterator.value;
          if (entry.getValue(SOURCE_KIND) == SourceKind.HTML) {
            List<Source> referencedLibraries =
                (entry as HtmlEntry).getValue(HtmlEntry.REFERENCED_LIBRARIES);
            if (_containsAny(referencedLibraries, librarySources)) {
              htmlSources.add(iterator.key);
            }
          }
        }
      } else {
        MapIterator<AnalysisTarget, cache.CacheEntry> iterator =
            _cache.iterator();
        while (iterator.moveNext()) {
          cache.CacheEntry entry = iterator.value;
          if (entry.getValue(SOURCE_KIND) == SourceKind.HTML) {
            List<Source> referencedLibraries =
                (entry as HtmlEntry).getValue(HtmlEntry.REFERENCED_LIBRARIES);
            if (_contains(referencedLibraries, source)) {
              htmlSources.add(iterator.key);
            }
          }
        }
      }
      break;
    }
    if (htmlSources.isEmpty) {
      return Source.EMPTY_ARRAY;
    }
    return htmlSources;
  }

  @override
  SourceKind getKindOf(Source source) => _getResult(source, SOURCE_KIND);

  @override
  List<Source> getLibrariesContaining(Source source) {
    // TODO(brianwilkerson) Implement this.
//    cache.CacheEntry sourceEntry = _cache.get(source);
//    if (sourceEntry is DartEntry) {
//      return sourceEntry.containingLibraries;
//    }
    return Source.EMPTY_ARRAY;
  }

  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    List<Source> dependentLibraries = new List<Source>();
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      cache.CacheEntry entry = iterator.value;
      if (entry.getValue(SOURCE_KIND) == SourceKind.LIBRARY) {
        if (_contains(entry.getValue(EXPORTED_LIBRARIES), librarySource)) {
          dependentLibraries.add(iterator.key);
        }
        if (_contains(entry.getValue(IMPORTED_LIBRARIES), librarySource)) {
          dependentLibraries.add(iterator.key);
        }
      }
    }
    if (dependentLibraries.isEmpty) {
      return Source.EMPTY_ARRAY;
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
    return Source.EMPTY_ARRAY;
  }

  @override
  LibraryElement getLibraryElement(Source source) =>
      _getResult(source, LIBRARY_ELEMENT);

  @override
  LineInfo getLineInfo(Source source) => _getResult(source, LINE_INFO);

  @override
  int getModificationStamp(Source source) {
    int stamp = _contentCache.getModificationStamp(source);
    if (stamp != null) {
      return stamp;
    }
    return source.modificationStamp;
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
   * Return the cache entry associated with the given [source], or `null` if
   * there is no entry associated with the source.
   */
  cache.CacheEntry getReadableSourceEntryOrNull(Source source) =>
      _cache.get(source);

  @override
  CompilationUnit getResolvedCompilationUnit(
      Source unitSource, LibraryElement library) {
    if (library == null) {
      return null;
    }
    return getResolvedCompilationUnit2(unitSource, library.source);
  }

  @override
  CompilationUnit getResolvedCompilationUnit2(
      Source unitSource, Source librarySource) => _getResult(
          new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT);

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
    List<Source> sources = <Source>[];
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      if (target is Source && target.fullName == path) {
        sources.add(target);
      }
    }
    return sources;
  }

  @override
  bool handleContentsChanged(
      Source source, String originalContents, String newContents, bool notify) {
    cache.CacheEntry entry = _cache.get(source);
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
        entry.setValue(CONTENT, newContents);
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
          entry.setValue(CONTENT, fileContentsData);
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

  /**
   * Invalidates hints in the given [librarySource] and included parts.
   */
  void invalidateLibraryHints(Source librarySource) {
    cache.CacheEntry entry = _cache.get(librarySource);
    // Prepare sources to invalidate hints in.
    List<Source> sources = <Source>[librarySource];
    sources.addAll(entry.getValue(INCLUDED_PARTS));
    // Invalidate hints.
    for (Source source in sources) {
      LibrarySpecificUnit unitTarget =
          new LibrarySpecificUnit(librarySource, source);
      cache.CacheEntry unitEntry = _cache.get(unitTarget);
      if (unitEntry.getState(HINTS) == CacheState.VALID) {
        unitEntry.setState(HINTS, CacheState.INVALID);
      }
    }
  }

  @override
  bool isClientLibrary(Source librarySource) {
    cache.CacheEntry entry = _cache.get(librarySource);
    return entry.getValue(IS_CLIENT) && entry.getValue(IS_LAUNCHABLE);
  }

  @override
  bool isServerLibrary(Source librarySource) {
    cache.CacheEntry entry = _cache.get(librarySource);
    return !entry.getValue(IS_CLIENT) && entry.getValue(IS_LAUNCHABLE);
  }

  @override
  CompilationUnit parseCompilationUnit(Source source) {
    if (!AnalysisEngine.isDartFileName(source.shortName)) {
      return null;
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
      bool done = !_driver.performAnalysisTask();
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
      cache.CacheEntry entry = getCacheEntry(librarySource);
      entry.setValue(BUILD_DIRECTIVES_ERRORS, AnalysisError.NO_ERRORS);
      entry.setValue(
          BUILD_FUNCTION_TYPE_ALIASES_ERRORS, AnalysisError.NO_ERRORS);
      entry.setValue(BUILD_LIBRARY_ERRORS, AnalysisError.NO_ERRORS);
      // CLASS_ELEMENTS
      entry.setValue(COMPILATION_UNIT_ELEMENT, library.definingCompilationUnit);
      // CONSTRUCTORS
      // CONSTRUCTORS_ERRORS
      entry.setState(CONTENT, CacheState.FLUSHED);
      entry.setValue(EXPORTED_LIBRARIES, Source.EMPTY_ARRAY);
      // EXPORT_SOURCE_CLOSURE
      entry.setValue(IMPORTED_LIBRARIES, Source.EMPTY_ARRAY);
      // IMPORT_SOURCE_CLOSURE
      entry.setValue(INCLUDED_PARTS, Source.EMPTY_ARRAY);
      entry.setValue(IS_CLIENT, true);
      entry.setValue(IS_LAUNCHABLE, false);
      entry.setValue(LIBRARY_ELEMENT, library);
      entry.setValue(LIBRARY_ELEMENT1, library);
      entry.setValue(LIBRARY_ELEMENT2, library);
      entry.setValue(LIBRARY_ELEMENT3, library);
      entry.setValue(LIBRARY_ELEMENT4, library);
      entry.setValue(LIBRARY_ELEMENT5, library);
      entry.setValue(LINE_INFO, new LineInfo(<int>[0]));
      entry.setValue(PARSE_ERRORS, AnalysisError.NO_ERRORS);
      entry.setState(PARSED_UNIT, CacheState.FLUSHED);
      entry.setState(RESOLVE_TYPE_NAMES_ERRORS, CacheState.FLUSHED);
      entry.setValue(SCAN_ERRORS, AnalysisError.NO_ERRORS);
      entry.setValue(SOURCE_KIND, SourceKind.LIBRARY);
      entry.setState(TOKEN_STREAM, CacheState.FLUSHED);
      entry.setValue(UNITS, <Source>[librarySource]);

      LibrarySpecificUnit unit =
          new LibrarySpecificUnit(librarySource, librarySource);
      entry = getCacheEntry(unit);
      entry.setValue(HINTS, AnalysisError.NO_ERRORS);
      // dartEntry.setValue(LINTS, AnalysisError.NO_ERRORS);
      entry.setState(RESOLVE_REFERENCES_ERRORS, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT1, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT2, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT3, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT4, CacheState.FLUSHED);
      entry.setState(RESOLVED_UNIT5, CacheState.FLUSHED);
      // USED_IMPORTED_ELEMENTS
      // USED_LOCAL_ELEMENTS
      entry.setValue(VERIFY_ERRORS, AnalysisError.NO_ERRORS);
    });

    cache.CacheEntry entry = getCacheEntry(AnalysisContextTarget.request);
    entry.setValue(TYPE_PROVIDER, typeProvider);
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
      Source unitSource, Source librarySource) => _computeResult(
          new LibrarySpecificUnit(librarySource, unitSource), RESOLVED_UNIT);

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
  void visitCacheItems(void callback(Source source, SourceEntry dartEntry,
      DataDescriptor rowDesc, CacheState state)) {
    // TODO(brianwilkerson) Figure out where this is used and adjust the call
    // sites to use CacheEntry's.
//    bool hintsEnabled = _options.hint;
//    bool lintsEnabled = _options.lint;
//    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
//    while (iterator.moveNext()) {
//      Source source = iterator.key;
//      cache.CacheEntry sourceEntry = iterator.value;
//      for (DataDescriptor descriptor in sourceEntry.descriptors) {
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
//            source, sourceEntry, descriptor, sourceEntry.getState(descriptor));
//      }
//      if (sourceEntry is DartEntry) {
//        // get library-specific values
//        List<Source> librarySources = getLibrariesContaining(source);
//        for (Source librarySource in librarySources) {
//          for (DataDescriptor descriptor in sourceEntry.libraryDescriptors) {
//            if (descriptor == DartEntry.BUILT_ELEMENT ||
//                descriptor == DartEntry.BUILT_UNIT) {
//              // These values are not currently being computed, so their state
//              // is not interesting.
//              continue;
//            } else if (!sourceEntry.explicitlyAdded &&
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
//            callback(librarySource, sourceEntry, descriptor,
//                sourceEntry.getStateInLibrary(descriptor, librarySource));
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
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      Source source = iterator.key;
      if (container.contains(source)) {
        sources.add(source);
      }
    }
  }

  /**
   * Return the priority that should be used when the source associated with
   * the given [entry] is added to the work manager.
   */
  SourcePriority _computePriority(cache.CacheEntry entry) {
    // Used in commented out code.
    SourceKind kind = entry.getValue(SOURCE_KIND);
    if (kind == SourceKind.LIBRARY) {
      return SourcePriority.LIBRARY;
    } else if (kind == SourceKind.PART) {
      return SourcePriority.NORMAL_PART;
    }
    return SourcePriority.UNKNOWN;
  }

  Object /*V*/ _computeResult(
      AnalysisTarget target, ResultDescriptor /*<V>*/ descriptor) {
    cache.CacheEntry entry = _cache.get(target);
    if (entry == null) {
      return descriptor.defaultValue;
    }
    if (descriptor is CompositeResultDescriptor) {
      List compositeResults = [];
      for (ResultDescriptor descriptor in descriptor.contributors) {
        List value = _computeResult(target, descriptor);
        compositeResults.addAll(value);
      }
      return compositeResults;
    }
    CacheState state = entry.getState(descriptor);
    if (state == CacheState.FLUSHED || state == CacheState.INVALID) {
      _driver.computeResult(target, descriptor);
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
        cache.CacheEntry entry = _cache.get(source);
        if (entry != null) {
          entry.modificationTime = _contentCache.getModificationStamp(source);
          entry.setValue(CONTENT, contents);
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
  cache.CacheEntry _createCacheEntry(Source source, bool explicitlyAdded) {
    cache.CacheEntry entry = new cache.CacheEntry();
    entry.modificationTime = getModificationStamp(source);
    entry.explicitlyAdded = explicitlyAdded;
    _cache.put(source, entry);
    return entry;
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
      return ChangeNoticeImpl.EMPTY_ARRAY;
    }
    List<ChangeNotice> notices = new List.from(_pendingNotices.values);
    _pendingNotices.clear();
    return notices;
  }

  /**
   * Return a change notice for the given [source], creating one if one does not
   * already exist.
   */
  ChangeNoticeImpl _getNotice(Source source) {
    // Used in commented out code.
    ChangeNoticeImpl notice = _pendingNotices[source];
    if (notice == null) {
      notice = new ChangeNoticeImpl(source);
      _pendingNotices[source] = notice;
    }
    return notice;
  }

  Object _getResult(AnalysisTarget target, ResultDescriptor descriptor) {
    cache.CacheEntry entry = _cache.get(target);
    if (entry != null && entry.isValid(descriptor)) {
      return entry.getValue(descriptor);
    }
    return descriptor.defaultValue;
  }

  /**
   * Return a list containing all of the sources known to this context that have
   * the given [kind].
   */
  List<Source> _getSources(SourceKind kind) {
    List<Source> sources = new List<Source>();
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      if (iterator.value.getValue(SOURCE_KIND) == kind &&
          iterator.key is Source) {
        sources.add(iterator.key);
      }
    }
    return sources;
  }

  /**
   * Look at the given [source] to see whether a task needs to be performed
   * related to it. If so, add the source to the set of sources that need to be
   * processed. This method is intended to be used for testing purposes only.
   */
  void _getSourcesNeedingProcessing(Source source, cache.CacheEntry sourceEntry,
      bool isPriority, bool hintsEnabled, bool lintsEnabled,
      HashSet<Source> sources) {
    CacheState state = sourceEntry.getState(CONTENT);
    if (state == CacheState.INVALID ||
        (isPriority && state == CacheState.FLUSHED)) {
      sources.add(source);
      return;
    } else if (state == CacheState.ERROR) {
      return;
    }
    state = sourceEntry.getState(SOURCE_KIND);
    if (state == CacheState.INVALID ||
        (isPriority && state == CacheState.FLUSHED)) {
      sources.add(source);
      return;
    } else if (state == CacheState.ERROR) {
      return;
    }
    SourceKind kind = sourceEntry.getValue(SOURCE_KIND);
    if (kind == SourceKind.LIBRARY || kind == SourceKind.PART) {
      state = sourceEntry.getState(SCAN_ERRORS);
      if (state == CacheState.INVALID ||
          (isPriority && state == CacheState.FLUSHED)) {
        sources.add(source);
        return;
      } else if (state == CacheState.ERROR) {
        return;
      }
      state = sourceEntry.getState(PARSE_ERRORS);
      if (state == CacheState.INVALID ||
          (isPriority && state == CacheState.FLUSHED)) {
        sources.add(source);
        return;
      } else if (state == CacheState.ERROR) {
        return;
      }
//      if (isPriority) {
//        if (!sourceEntry.hasResolvableCompilationUnit) {
//          sources.add(source);
//          return;
//        }
//      }
      for (Source librarySource in getLibrariesContaining(source)) {
        cache.CacheEntry libraryEntry = _cache.get(librarySource);
        state = libraryEntry.getState(LIBRARY_ELEMENT);
        if (state == CacheState.INVALID ||
            (isPriority && state == CacheState.FLUSHED)) {
          sources.add(source);
          return;
        } else if (state == CacheState.ERROR) {
          return;
        }
        cache.CacheEntry unitEntry =
            _cache.get(new LibrarySpecificUnit(librarySource, source));
        state = unitEntry.getState(RESOLVED_UNIT);
        if (state == CacheState.INVALID ||
            (isPriority && state == CacheState.FLUSHED)) {
          sources.add(source);
          return;
        } else if (state == CacheState.ERROR) {
          return;
        }
        if (_shouldErrorsBeAnalyzed(source, unitEntry)) {
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
//      CacheState parsedUnitState = sourceEntry.getState(HtmlEntry.PARSED_UNIT);
//      if (parsedUnitState == CacheState.INVALID ||
//          (isPriority && parsedUnitState == CacheState.FLUSHED)) {
//        sources.add(source);
//        return;
//      }
//      CacheState resolvedUnitState =
//          sourceEntry.getState(HtmlEntry.RESOLVED_UNIT);
//      if (resolvedUnitState == CacheState.INVALID ||
//          (isPriority && resolvedUnitState == CacheState.FLUSHED)) {
//        sources.add(source);
//        return;
//      }
    }
  }

  /**
   * Invalidate all of the resolution results computed by this context. The flag
   * [invalidateUris] should be `true` if the cached results of converting URIs
   * to source files should also be invalidated.
   */
  void _invalidateAllLocalResolutionInformation(bool invalidateUris) {
    HashMap<Source, List<Source>> oldPartMap =
        new HashMap<Source, List<Source>>();
    // TODO(brianwilkerson) Implement this
//    MapIterator<AnalysisTarget, cache.CacheEntry> iterator =
//        _privatePartition.iterator();
//    while (iterator.moveNext()) {
//      AnalysisTarget target = iterator.key;
//      cache.CacheEntry entry = iterator.value;
//      if (entry is HtmlEntry) {
//        HtmlEntry htmlEntry = entry;
//        htmlEntry.invalidateAllResolutionInformation(invalidateUris);
//        iterator.value = htmlEntry;
//        _workManager.add(target, SourcePriority.HTML);
//      } else if (entry is DartEntry) {
//        DartEntry dartEntry = entry;
//        oldPartMap[target] = dartEntry.getValue(DartEntry.INCLUDED_PARTS);
//        dartEntry.invalidateAllResolutionInformation(invalidateUris);
//        iterator.value = dartEntry;
//        _workManager.add(target, _computePriority(dartEntry));
//      }
//    }
    _removeFromPartsUsingMap(oldPartMap);
  }

  /**
   * In response to a change to at least one of the compilation units in the
   * library defined by the given [librarySource], invalidate any results that
   * are dependent on the result of resolving that library.
   *
   * <b>Note:</b> Any cache entries that were accessed before this method was
   * invoked must be re-accessed after this method returns.
   */
  void _invalidateLibraryResolution(Source librarySource) {
    // TODO(brianwilkerson) Figure out whether we still need this.
    // TODO(brianwilkerson) This could be optimized. There's no need to flush
    // all of these entries if the public namespace hasn't changed, which will
    // be a fairly common case. The question is whether we can afford the time
    // to compute the namespace to look for differences.
//    DartEntry libraryEntry = _getReadableDartEntry(librarySource);
//    if (libraryEntry != null) {
//      List<Source> includedParts =
//          libraryEntry.getValue(DartEntry.INCLUDED_PARTS);
//      libraryEntry.invalidateAllResolutionInformation(false);
//      _workManager.add(librarySource, SourcePriority.LIBRARY);
//      for (Source partSource in includedParts) {
//        SourceEntry partEntry = _cache.get(partSource);
//        if (partEntry is DartEntry) {
//          partEntry.invalidateAllResolutionInformation(false);
//        }
//      }
//    }
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

  /**
   * Remove the given libraries that are keys in the given map from the list of
   * containing libraries for each of the parts in the corresponding value.
   */
  void _removeFromPartsUsingMap(HashMap<Source, List<Source>> oldPartMap) {
    // TODO(brianwilkerson) Figure out whether we still need this.
//    oldPartMap.forEach((Source librarySource, List<Source> oldParts) {
//      for (int i = 0; i < oldParts.length; i++) {
//        Source partSource = oldParts[i];
//        if (partSource != librarySource) {
//          DartEntry partEntry = _getReadableDartEntry(partSource);
//          if (partEntry != null) {
//            partEntry.removeContainingLibrary(librarySource);
//            if (partEntry.containingLibraries.length == 0 &&
//                !exists(partSource)) {
//              _cache.remove(partSource);
//            }
//          }
//        }
//      }
//    });
  }

  /**
   * Remove the given [source] from the priority order if it is in the list.
   */
  void _removeFromPriorityOrder(Source source) {
    int count = _priorityOrder.length;
    List<Source> newOrder = new List<Source>();
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
   * Return `true` if errors should be produced for the given [source]. The
   * [entry] associated with the source is passed in for efficiency.
   */
  bool _shouldErrorsBeAnalyzed(Source source, cache.CacheEntry entry) {
    if (source.isInSystemLibrary) {
      return _options.generateSdkErrors;
    } else if (!entry.explicitlyAdded) {
      return _options.generateImplicitErrors;
    } else {
      return true;
    }
  }

  /**
   * Create an entry for the newly added [source] and invalidate any sources
   * that referenced the source before it existed.
   */
  void _sourceAvailable(Source source) {
    cache.CacheEntry entry = _cache.get(source);
    if (entry == null) {
      _createCacheEntry(source, true);
    } else {
      // TODO(brianwilkerson) Implement this.
//      _propagateInvalidation(source, entry);
    }
  }

  /**
   * Invalidate the [source] that was changed and any sources that referenced
   * the source before it existed.
   */
  void _sourceChanged(Source source) {
    cache.CacheEntry entry = _cache.get(source);
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
          return;
        }
      } catch (e) {}
    }
    // We need to invalidate the cache.
    // TODO(brianwilkerson) Implement this.
//    _propagateInvalidation(source, entry);
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
    List<Source> containingLibraries = getLibrariesContaining(source);
    if (containingLibraries != null && containingLibraries.isNotEmpty) {
      HashSet<Source> libraries = new HashSet<Source>();
      for (Source librarySource in containingLibraries) {
        libraries.add(librarySource);
        for (Source dependentLibrary
            in getLibrariesDependingOn(librarySource)) {
          libraries.add(dependentLibrary);
        }
      }
      for (Source librarySource in libraries) {
        _invalidateLibraryResolution(librarySource);
      }
    }
    _cache.remove(source);
    _removeFromPriorityOrder(source);
  }

  /**
   * TODO(scheglov) A hackish, limited incremental resolution implementation.
   */
  bool _tryPoorMansIncrementalResolution(Source unitSource, String newCode) {
    // TODO(brianwilkerson) Implement this.
    return false;
//    return PerformanceStatistics.incrementalAnalysis.makeCurrentWhile(() {
//      incrementalResolutionValidation_lastUnitSource = null;
//      incrementalResolutionValidation_lastLibrarySource = null;
//      incrementalResolutionValidation_lastUnit = null;
//      // prepare the entry
//      cache.CacheEntry entry = _cache.get(unitSource);
//      if (entry == null) {
//        return false;
//      }
//      // prepare the (only) library source
//      List<Source> librarySources = getLibrariesContaining(unitSource);
//      if (librarySources.length != 1) {
//        return false;
//      }
//      Source librarySource = librarySources[0];
//      // prepare the library element
//      LibraryElement libraryElement = getLibraryElement(librarySource);
//      if (libraryElement == null) {
//        return false;
//      }
//      // prepare the existing unit
//      CompilationUnit oldUnit =
//          getResolvedCompilationUnit2(unitSource, librarySource);
//      if (oldUnit == null) {
//        return false;
//      }
//      // do resolution
//      Stopwatch perfCounter = new Stopwatch()..start();
//      PoorMansIncrementalResolver resolver = new PoorMansIncrementalResolver(
//          typeProvider, unitSource, entry, oldUnit,
//          analysisOptions.incrementalApi, analysisOptions);
//      bool success = resolver.resolve(newCode);
//      AnalysisEngine.instance.instrumentationService.logPerformance(
//          AnalysisPerformanceKind.INCREMENTAL, perfCounter,
//          'success=$success,context_id=$_id,code_length=${newCode.length}');
//      if (!success) {
//        return false;
//      }
//      // if validation, remember the result, but throw it away
//      if (analysisOptions.incrementalValidation) {
//        incrementalResolutionValidation_lastUnitSource = oldUnit.element.source;
//        incrementalResolutionValidation_lastLibrarySource =
//            oldUnit.element.library.source;
//        incrementalResolutionValidation_lastUnit = oldUnit;
//        return false;
//      }
//      // prepare notice
//      {
//        LineInfo lineInfo = getLineInfo(unitSource);
//        ChangeNoticeImpl notice = _getNotice(unitSource);
//        notice.resolvedDartUnit = oldUnit;
//        notice.setErrors(entry.allErrors, lineInfo);
//      }
//      // OK
//      return true;
//    });
  }

  /**
   * Check the cache for any invalid entries (entries whose modification time
   * does not match the modification time of the source associated with the
   * entry). Invalid entries will be marked as invalid so that the source will
   * be re-analyzed. Return `true` if at least one entry was invalid.
   */
  bool _validateCacheConsistency() {
    int consistencyCheckStart = JavaSystem.nanoTime();
    List<AnalysisTarget> changedTargets = new List<AnalysisTarget>();
    List<AnalysisTarget> missingTargets = new List<AnalysisTarget>();
    MapIterator<AnalysisTarget, cache.CacheEntry> iterator = _cache.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      cache.CacheEntry entry = iterator.value;
      if (target is Source) {
        int sourceTime = getModificationStamp(target);
        if (sourceTime != entry.modificationTime) {
          changedTargets.add(target);
        }
      }
      if (entry.exception != null) {
        if (!exists(target)) {
          missingTargets.add(target);
        }
      }
    }
    int count = changedTargets.length;
    for (int i = 0; i < count; i++) {
      _sourceChanged(changedTargets[i]);
    }
    int removalCount = 0;
    for (AnalysisTarget target in missingTargets) {
      if (target is Source &&
          getLibrariesContaining(target).isEmpty &&
          getLibrariesDependingOn(target).isEmpty) {
        _cache.remove(target);
        removalCount++;
      }
    }
    int consistencyCheckEnd = JavaSystem.nanoTime();
    if (changedTargets.length > 0 || missingTargets.length > 0) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Consistency check took ");
      buffer.write((consistencyCheckEnd - consistencyCheckStart) / 1000000.0);
      buffer.writeln(" ms and found");
      buffer.write("  ");
      buffer.write(changedTargets.length);
      buffer.writeln(" inconsistent entries");
      buffer.write("  ");
      buffer.write(missingTargets.length);
      buffer.write(" missing sources (");
      buffer.write(removalCount);
      buffer.writeln(" removed");
      for (Source source in missingTargets) {
        buffer.write("    ");
        buffer.writeln(source.fullName);
      }
      _logInformation(buffer.toString());
    }
    return changedTargets.length > 0;
  }
}

/**
 * A retention policy used by an analysis context.
 */
class ContextRetentionPolicy implements cache.CacheRetentionPolicy {
  /**
   * The context associated with this policy.
   */
  final AnalysisContextImpl context;

  /**
   * Initialize a newly created policy to be associated with the given
   * [context].
   */
  ContextRetentionPolicy(this.context);

  @override
  RetentionPriority getAstPriority(
      AnalysisTarget target, cache.CacheEntry entry) {
    int priorityCount = context._priorityOrder.length;
    for (int i = 0; i < priorityCount; i++) {
      if (target == context._priorityOrder[i]) {
        return RetentionPriority.HIGH;
      }
    }
    if (_astIsNeeded(entry)) {
      return RetentionPriority.MEDIUM;
    }
    return RetentionPriority.LOW;
  }

  bool _astIsNeeded(cache.CacheEntry entry) =>
      entry.isInvalid(BUILD_FUNCTION_TYPE_ALIASES_ERRORS) ||
          entry.isInvalid(BUILD_LIBRARY_ERRORS) ||
          entry.isInvalid(CONSTRUCTORS_ERRORS) ||
          entry.isInvalid(HINTS) ||
          //entry.isInvalid(LINTS) ||
          entry.isInvalid(RESOLVE_REFERENCES_ERRORS) ||
          entry.isInvalid(RESOLVE_TYPE_NAMES_ERRORS) ||
          entry.isInvalid(VERIFY_ERRORS);
}

/**
 * An object that manages the partitions that can be shared between analysis
 * contexts.
 */
class PartitionManager {
  /**
   * The default cache size for a Dart SDK partition.
   */
  static int _DEFAULT_SDK_CACHE_SIZE = 256;

  /**
   * A table mapping SDK's to the partitions used for those SDK's.
   */
  HashMap<DartSdk, cache.SdkCachePartition> _sdkPartitions =
      new HashMap<DartSdk, cache.SdkCachePartition>();

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
  cache.SdkCachePartition forSdk(DartSdk sdk) {
    // Call sdk.context now, because when it creates a new
    // InternalAnalysisContext instance, it calls forSdk() again, so creates an
    // SdkCachePartition instance.
    // So, if we initialize context after "partition == null", we end up
    // with two SdkCachePartition instances.
    InternalAnalysisContext sdkContext = sdk.context;
    // Check cache for an existing partition.
    cache.SdkCachePartition partition = _sdkPartitions[sdk];
    if (partition == null) {
      partition =
          new cache.SdkCachePartition(sdkContext, _DEFAULT_SDK_CACHE_SIZE);
      _sdkPartitions[sdk] = partition;
    }
    return partition;
  }
}
