// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_context.dart' as api;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/file_tracker.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisContext,
        AnalysisEngine,
        AnalysisOptions,
        AnalysisOptionsImpl,
        PerformanceStatistics;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/registry.dart' as linter;
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:meta/meta.dart';

/**
 * TODO(scheglov) We could use generalized Function in [AnalysisDriverTestView],
 * but this breaks `AnalysisContext` and code generation. So, for now let's
 * work around them, and rewrite generators to [AnalysisDriver].
 */
typedef Future<void> WorkToWaitAfterComputingResult(String path);

/**
 * This class computes [AnalysisResult]s for Dart files.
 *
 * Let the set of "explicitly analyzed files" denote the set of paths that have
 * been passed to [addFile] but not subsequently passed to [removeFile]. Let
 * the "current analysis results" denote the map from the set of explicitly
 * analyzed files to the most recent [AnalysisResult] delivered to [results]
 * for each file. Let the "current file state" represent a map from file path
 * to the file contents most recently read from that file, or fetched from the
 * content cache (considering all possible possible file paths, regardless of
 * whether they're in the set of explicitly analyzed files). Let the
 * "analysis state" be either "analyzing" or "idle".
 *
 * (These are theoretical constructs; they may not necessarily reflect data
 * structures maintained explicitly by the driver).
 *
 * Then we make the following guarantees:
 *
 *    - Whenever the analysis state is idle, the current analysis results are
 *      consistent with the current file state.
 *
 *    - A call to [addFile] or [changeFile] causes the analysis state to
 *      transition to "analyzing", and schedules the contents of the given
 *      files to be read into the current file state prior to the next time
 *      the analysis state transitions back to "idle".
 *
 *    - If at any time the client stops making calls to [addFile], [changeFile],
 *      and [removeFile], the analysis state will eventually transition back to
 *      "idle" after a finite amount of processing.
 *
 * As a result of these guarantees, a client may ensure that the analysis
 * results are "eventually consistent" with the file system by simply calling
 * [changeFile] any time the contents of a file on the file system have changed.
 *
 * TODO(scheglov) Clean up the list of implicitly analyzed files.
 */
class AnalysisDriver implements AnalysisDriverGeneric {
  /**
   * The version of data format, should be incremented on every format change.
   */
  static const int DATA_VERSION = 80;

  /**
   * The number of exception contexts allowed to write. Once this field is
   * zero, we stop writing any new exception contexts in this process.
   */
  static int allowedNumberOfContextsToWrite = 10;

  /**
   * Whether summary2 should be used to resynthesize elements.
   */
  static final bool useSummary2 = false;

  /**
   * The scheduler that schedules analysis work in this, and possibly other
   * analysis drivers.
   */
  final AnalysisDriverScheduler _scheduler;

  /**
   * The logger to write performed operations and performance to.
   */
  final PerformanceLog _logger;

  /**
   * The resource provider for working with files.
   */
  final ResourceProvider _resourceProvider;

  /**
   * The byte storage to get and put serialized data.
   *
   * It can be shared with other [AnalysisDriver]s.
   */
  final ByteStore _byteStore;

  /**
   * The optional store with externally provided unlinked and corresponding
   * linked summaries. These summaries are always added to the store for any
   * file analysis.
   */
  final SummaryDataStore _externalSummaries;

  /**
   * This [ContentCache] is consulted for a file content before reading
   * the content from the file.
   */
  final FileContentOverlay _contentOverlay;

  /**
   * The analysis options to analyze with.
   */
  AnalysisOptionsImpl _analysisOptions;

  /**
   * The [SourceFactory] is used to resolve URIs to paths and restore URIs
   * from file paths.
   */
  SourceFactory _sourceFactory;

  /**
   * The declared environment variables.
   */
  DeclaredVariables declaredVariables = new DeclaredVariables();

  /**
   * Information about the context root being analyzed by this driver.
   */
  final ContextRoot contextRoot;

  /**
   * The analysis context that created this driver / session.
   */
  api.AnalysisContext analysisContext;

  /**
   * The salt to mix into all hashes used as keys for unlinked data.
   */
  final Uint32List _unlinkedSalt =
      new Uint32List(2 + AnalysisOptionsImpl.unlinkedSignatureLength);

  /**
   * The salt to mix into all hashes used as keys for linked data.
   */
  final Uint32List _linkedSalt =
      new Uint32List(2 + AnalysisOptions.signatureLength);

  /**
   * The set of priority files, that should be analyzed sooner.
   */
  final _priorityFiles = new LinkedHashSet<String>();

  /**
   * The mapping from the files for which analysis was requested using
   * [getResult] to the [Completer]s to report the result.
   */
  final _requestedFiles = <String, List<Completer<ResolvedUnitResult>>>{};

  /**
   * The mapping from the files for which analysis was requested using
   * [getResolvedLibrary] to the [Completer]s to report the result.
   */
  final _requestedLibraries =
      <String, List<Completer<ResolvedLibraryResult>>>{};

  /**
   * The task that discovers available files.  If this field is not `null`,
   * and the task is not completed, it should be performed and completed
   * before any name searching task.
   */
  _DiscoverAvailableFilesTask _discoverAvailableFilesTask;

  /**
   * The list of tasks to compute files defining a class member name.
   */
  final _definingClassMemberNameTasks = <_FilesDefiningClassMemberNameTask>[];

  /**
   * The list of tasks to compute files referencing a name.
   */
  final _referencingNameTasks = <_FilesReferencingNameTask>[];

  /**
   * The list of tasks to compute top-level declarations of a name.
   */
  final _topLevelNameDeclarationsTasks = <_TopLevelNameDeclarationsTask>[];

  /**
   * The mapping from the files for which the index was requested using
   * [getIndex] to the [Completer]s to report the result.
   */
  final _indexRequestedFiles =
      <String, List<Completer<AnalysisDriverUnitIndex>>>{};

  /**
   * The mapping from the files for which the unit element key was requested
   * using [getUnitElementSignature] to the [Completer]s to report the result.
   */
  final _unitElementSignatureFiles = <String, List<Completer<String>>>{};

  /**
   * The mapping from the files for which the unit element key was requested
   * using [getUnitElementSignature], and which were found to be parts without
   * known libraries, to the [Completer]s to report the result.
   */
  final _unitElementSignatureParts = <String, List<Completer<String>>>{};

  /**
   * The mapping from the files for which the unit element was requested using
   * [getUnitElement] to the [Completer]s to report the result.
   */
  final _unitElementRequestedFiles =
      <String, List<Completer<UnitElementResult>>>{};

  /**
   * The mapping from the files for which the unit element was requested using
   * [getUnitElement], and which were found to be parts without known libraries,
   * to the [Completer]s to report the result.
   */
  final _unitElementRequestedParts =
      <String, List<Completer<UnitElementResult>>>{};

  /**
   * The mapping from the files for which analysis was requested using
   * [getResult], and which were found to be parts without known libraries,
   * to the [Completer]s to report the result.
   */
  final _requestedParts = <String, List<Completer<ResolvedUnitResult>>>{};

  /**
   * The set of part files that are currently scheduled for analysis.
   */
  final _partsToAnalyze = new LinkedHashSet<String>();

  /**
   * The controller for the [results] stream.
   */
  final _resultController = new StreamController<ResolvedUnitResult>();

  /**
   * The stream that will be written to when analysis results are produced.
   */
  Stream<ResolvedUnitResult> _onResults;

  /**
   * Resolution signatures of the most recently produced results for files.
   */
  final Map<String, String> _lastProducedSignatures = {};

  /**
   * Cached results for [_priorityFiles].
   */
  final Map<String, ResolvedUnitResult> _priorityResults = {};

  /**
   * The controller for the [exceptions] stream.
   */
  final StreamController<ExceptionResult> _exceptionController =
      new StreamController<ExceptionResult>();

  /**
   * The instance of the [Search] helper.
   */
  Search _search;

  AnalysisDriverTestView _testView;

  FileSystemState _fsState;

  /**
   * The [FileTracker] used by this driver.
   */
  FileTracker _fileTracker;

  /**
   * When this flag is set to `true`, the set of analyzed files must not change,
   * and all [AnalysisResult]s are cached infinitely.
   *
   * The flag is intended to be used for non-interactive clients, like DDC,
   * which start a new analysis session, load a set of files, resolve all of
   * them, process the resolved units, and then throw away that whole session.
   *
   * The key problem that this flag is solving is that the driver analyzes the
   * whole library when the result for a unit of the library is requested. So,
   * when the client requests sequentially the defining unit, then the first
   * part, then the second part, the driver has to perform analysis of the
   * library three times and every time throw away all the units except the one
   * which was requested. With this flag set to `true`, the driver can analyze
   * once and cache all the resolved units.
   */
  final bool disableChangesAndCacheAllResults;

  /**
   * Whether resolved units should be indexed.
   */
  final bool enableIndex;

  /**
   * The cache to use with [disableChangesAndCacheAllResults].
   */
  final Map<String, AnalysisResult> _allCachedResults = {};

  /**
   * The current analysis session.
   */
  AnalysisSessionImpl _currentSession;

  /**
   * The current library context, consistent with the [_currentSession].
   *
   * TODO(scheglov) We probably should tie it into the session.
   */
  LibraryContext _libraryContext;

  /**
   * This function is invoked when the current session is about to be discarded.
   * The argument represents the path of the resource causing the session
   * to be discarded or `null` if there are multiple or this is unknown.
   */
  void Function(String) onCurrentSessionAboutToBeDiscarded;

  /**
   * Create a new instance of [AnalysisDriver].
   *
   * The given [SourceFactory] is cloned to ensure that it does not contain a
   * reference to a [AnalysisContext] in which it could have been used.
   */
  AnalysisDriver(
      this._scheduler,
      PerformanceLog logger,
      this._resourceProvider,
      this._byteStore,
      this._contentOverlay,
      this.contextRoot,
      SourceFactory sourceFactory,
      this._analysisOptions,
      {this.disableChangesAndCacheAllResults: false,
      this.enableIndex: false,
      SummaryDataStore externalSummaries})
      : _logger = logger,
        _sourceFactory = sourceFactory.clone(),
        _externalSummaries = externalSummaries {
    _createNewSession(null);
    _onResults = _resultController.stream.asBroadcastStream();
    _testView = new AnalysisDriverTestView(this);
    _createFileTracker();
    _scheduler.add(this);
    _search = new Search(this);
  }

  /**
   * Return the set of files explicitly added to analysis using [addFile].
   */
  Set<String> get addedFiles => _fileTracker.addedFiles;

  /**
   * Return the analysis options used to control analysis.
   */
  AnalysisOptions get analysisOptions => _analysisOptions;

  /**
   * Return the current analysis session.
   */
  AnalysisSession get currentSession => _currentSession;

  /**
   * Return the stream that produces [ExceptionResult]s.
   */
  Stream<ExceptionResult> get exceptions => _exceptionController.stream;

  /**
   * The current file system state.
   */
  FileSystemState get fsState => _fsState;

  @override
  bool get hasFilesToAnalyze {
    return _fileTracker.hasChangedFiles ||
        _requestedFiles.isNotEmpty ||
        _requestedParts.isNotEmpty ||
        _fileTracker.hasPendingFiles ||
        _partsToAnalyze.isNotEmpty;
  }

  /**
   * Return the set of files that are known at this moment. This set does not
   * always include all added files or all implicitly used file. If a file has
   * not been processed yet, it might be missing.
   */
  Set<String> get knownFiles => _fsState.knownFilePaths;

  /**
   * Return the path of the folder at the root of the context.
   */
  String get name => contextRoot?.root ?? '';

  /**
   * Return the number of files scheduled for analysis.
   */
  int get numberOfFilesToAnalyze => _fileTracker.numberOfPendingFiles;

  /**
   * Return the list of files that the driver should try to analyze sooner.
   */
  List<String> get priorityFiles => _priorityFiles.toList(growable: false);

  @override
  void set priorityFiles(List<String> priorityPaths) {
    _priorityResults.keys
        .toSet()
        .difference(priorityPaths.toSet())
        .forEach(_priorityResults.remove);
    _priorityFiles.clear();
    _priorityFiles.addAll(priorityPaths);
    _scheduler.notify(this);
  }

  /**
   * Return the [ResourceProvider] that is used to access the file system.
   */
  ResourceProvider get resourceProvider => _resourceProvider;

  /**
   * Return the [Stream] that produces [AnalysisResult]s for added files.
   *
   * Note that the stream supports only one single subscriber.
   *
   * Analysis starts when the [AnalysisDriverScheduler] is started and the
   * driver is added to it. The analysis state transitions to "analyzing" and
   * an analysis result is produced for every added file prior to the next time
   * the analysis state transitions to "idle".
   *
   * At least one analysis result is produced for every file passed to
   * [addFile] or [changeFile] prior to the next time the analysis state
   * transitions to "idle", unless the file is later removed from analysis
   * using [removeFile]. Analysis results for other files are produced only if
   * the changes affect analysis results of other files.
   *
   * More than one result might be produced for the same file, even if the
   * client does not change the state of the files.
   *
   * Results might be produced even for files that have never been added
   * using [addFile], for example when [getResult] was called for a file.
   */
  Stream<ResolvedUnitResult> get results => _onResults;

  /**
   * Return the search support for the driver.
   */
  Search get search => _search;

  /**
   * Return the source factory used to resolve URIs to paths and restore URIs
   * from file paths.
   */
  SourceFactory get sourceFactory => _sourceFactory;

  @visibleForTesting
  AnalysisDriverTestView get test => _testView;

  @override
  AnalysisDriverPriority get workPriority {
    if (_requestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_requestedLibraries.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_discoverAvailableFilesTask != null &&
        !_discoverAvailableFilesTask.isCompleted) {
      return AnalysisDriverPriority.interactive;
    }
    if (_definingClassMemberNameTasks.isNotEmpty ||
        _referencingNameTasks.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_indexRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_unitElementSignatureFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_unitElementRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_topLevelNameDeclarationsTasks.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_fileTracker.isFilePending(path)) {
          return AnalysisDriverPriority.priority;
        }
      }
    }
    if (_fileTracker.hasChangedFiles) {
      return AnalysisDriverPriority.changedFiles;
    }
    if (_fileTracker.hasPendingChangedFiles) {
      return AnalysisDriverPriority.generalChanged;
    }
    if (_fileTracker.hasPendingImportFiles) {
      return AnalysisDriverPriority.generalImportChanged;
    }
    if (_fileTracker.hasPendingErrorFiles) {
      return AnalysisDriverPriority.generalWithErrors;
    }
    if (_fileTracker.hasPendingFiles) {
      return AnalysisDriverPriority.general;
    }
    if (_requestedParts.isNotEmpty ||
        _partsToAnalyze.isNotEmpty ||
        _unitElementSignatureParts.isNotEmpty ||
        _unitElementRequestedParts.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    _libraryContext = null;
    return AnalysisDriverPriority.nothing;
  }

  @override
  void addFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (AnalysisEngine.isDartFileName(path)) {
      _fileTracker.addFile(path);
      // If the file is known, it has already been read, even if it did not
      // exist. Now we are notified that the file exists, so we need to
      // re-read it and make sure that we invalidate signature of the files
      // that reference it.
      if (_fsState.knownFilePaths.contains(path)) {
        _changeFile(path);
      }
    }
  }

  /**
   * The file with the given [path] might have changed - updated, added or
   * removed. Or not, we don't know. Or it might have, but then changed back.
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   *
   * Causes the analysis state to transition to "analyzing" (if it is not in
   * that state already). Schedules the file contents for [path] to be read
   * into the current file state prior to the next time the analysis state
   * transitions to "idle".
   *
   * Invocation of this method will not prevent a [Future] returned from
   * [getResult] from completing with a result, but the result is not
   * guaranteed to be consistent with the new current file state after this
   * [changeFile] invocation.
   */
  void changeFile(String path) {
    _throwIfNotAbsolutePath(path);
    _throwIfChangesAreNotAllowed();
    _changeFile(path);
  }

  /**
   * Some state on which analysis depends has changed, so the driver needs to be
   * re-configured with the new state.
   *
   * At least one of the optional parameters should be provided, but only those
   * that represent state that has actually changed need be provided.
   */
  void configure(
      {AnalysisOptions analysisOptions, SourceFactory sourceFactory}) {
    if (analysisOptions != null) {
      _analysisOptions = analysisOptions;
    }
    if (sourceFactory != null) {
      _sourceFactory = sourceFactory;
    }
    Iterable<String> addedFiles = _fileTracker.addedFiles;
    _createFileTracker();
    _fileTracker.addFiles(addedFiles);
  }

  /**
   * Return a [Future] that completes when discovery of all files that are
   * potentially available is done, so that they are included in [knownFiles].
   */
  Future<void> discoverAvailableFiles() {
    if (_discoverAvailableFilesTask != null &&
        _discoverAvailableFilesTask.isCompleted) {
      return new Future.value();
    }
    _discoverAvailableFiles();
    _scheduler.notify(this);
    return _discoverAvailableFilesTask.completer.future;
  }

  @override
  void dispose() {
    _scheduler.remove(this);
  }

  /**
   * Return the cached [ResolvedUnitResult] for the Dart file with the given
   * [path]. If there is no cached result, return `null`. Usually only results
   * of priority files are cached.
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   */
  ResolvedUnitResult getCachedResult(String path) {
    _throwIfNotAbsolutePath(path);
    ResolvedUnitResult result = _priorityResults[path];
    if (disableChangesAndCacheAllResults) {
      result ??= _allCachedResults[path];
    }
    return result;
  }

  /**
   * Return a [Future] that completes with the [ErrorsResult] for the Dart
   * file with the given [path]. If the file is not a Dart file or cannot
   * be analyzed, the [Future] completes with `null`.
   *
   * The [path] must be absolute and normalized.
   *
   * This method does not use analysis priorities, and must not be used in
   * interactive analysis, such as Analysis Server or its plugins.
   */
  Future<ErrorsResult> getErrors(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    _throwIfNotAbsolutePath(path);

    // Ask the analysis result without unit, so return cached errors.
    // If no cached analysis result, it will be computed.
    ResolvedUnitResult analysisResult = _computeAnalysisResult(path);

    // If not computed yet, because a part file without a known library,
    // we have to compute the full analysis result, with the unit.
    analysisResult ??= await getResult(path);
    if (analysisResult == null) {
      return null;
    }

    return new ErrorsResultImpl(currentSession, path, analysisResult.uri,
        analysisResult.lineInfo, analysisResult.isPart, analysisResult.errors);
  }

  /**
   * Return a [Future] that completes with the list of added files that
   * define a class member with the given [name].
   */
  Future<List<String>> getFilesDefiningClassMemberName(String name) {
    _discoverAvailableFiles();
    var task = new _FilesDefiningClassMemberNameTask(this, name);
    _definingClassMemberNameTasks.add(task);
    _scheduler.notify(this);
    return task.completer.future;
  }

  /**
   * Return a [Future] that completes with the list of known files that
   * reference the given external [name].
   */
  Future<List<String>> getFilesReferencingName(String name) {
    _discoverAvailableFiles();
    var task = new _FilesReferencingNameTask(this, name);
    _referencingNameTasks.add(task);
    _scheduler.notify(this);
    return task.completer.future;
  }

  /**
   * Return the [FileResult] for the Dart file with the given [path].
   *
   * The [path] must be absolute and normalized.
   */
  FileResult getFileSync(String path) {
    _throwIfNotAbsolutePath(path);
    FileState file = _fileTracker.verifyApiSignature(path);
    return new FileResultImpl(
        _currentSession, path, file.uri, file.lineInfo, file.isPart);
  }

  /**
   * Return a [Future] that completes with the [AnalysisDriverUnitIndex] for
   * the file with the given [path], or with `null` if the file cannot be
   * analyzed.
   */
  Future<AnalysisDriverUnitIndex> getIndex(String path) {
    _throwIfNotAbsolutePath(path);
    if (!enableIndex) {
      throw new ArgumentError('Indexing is not enabled.');
    }
    if (!_fsState.hasUri(path)) {
      return new Future.value();
    }
    var completer = new Completer<AnalysisDriverUnitIndex>();
    _indexRequestedFiles
        .putIfAbsent(path, () => <Completer<AnalysisDriverUnitIndex>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /**
   * Return a [Future] that completes with the [LibraryElement] for the given
   * [uri], which is either resynthesized from the provided external summary
   * store, or built for a file to which the given [uri] is resolved.
   *
   * Throw [ArgumentError] if the [uri] does not correspond to a file.
   *
   * Throw [ArgumentError] if the [uri] corresponds to a part.
   */
  Future<LibraryElement> getLibraryByUri(String uri) async {
    var uriObj = Uri.parse(uri);
    var file = _fsState.getFileForUri(uriObj);

    if (file.isUnresolved) {
      throw ArgumentError('$uri cannot be resolved to a file.');
    }

    if (file.isExternalLibrary) {
      return _createLibraryContext(file).getLibraryElement(file);
    }

    if (file.isPart) {
      throw ArgumentError('$uri is not a library.');
    }

    UnitElementResult unitResult = await getUnitElement(file.path);
    return unitResult.element.library;
  }

  /**
   * Return a [ParsedLibraryResult] for the library with the given [path].
   *
   * Throw [ArgumentError] if the given [path] is not the defining compilation
   * unit for a library (that is, is a part of a library).
   *
   * The [path] must be absolute and normalized.
   */
  ParsedLibraryResult getParsedLibrary(String path) {
    FileState file = _fsState.getFileForPath(path);

    if (file.isExternalLibrary) {
      return ParsedLibraryResultImpl.external(currentSession, file.uri);
    }

    if (file.isPart) {
      throw ArgumentError('Is a part: $path');
    }

    var units = <ParsedUnitResult>[];
    for (var unitFile in file.libraryFiles) {
      var unitPath = unitFile.path;
      if (unitPath != null) {
        var unitResult = parseFileSync(unitPath);
        units.add(unitResult);
      }
    }

    return ParsedLibraryResultImpl(currentSession, path, file.uri, units);
  }

  /**
   * Return a [ParsedLibraryResult] for the library with the given [uri].
   *
   * Throw [ArgumentError] if the given [uri] is not the defining compilation
   * unit for a library (that is, is a part of a library).
   */
  ParsedLibraryResult getParsedLibraryByUri(Uri uri) {
    FileState file = _fsState.getFileForUri(uri);

    if (file.isExternalLibrary) {
      return ParsedLibraryResultImpl.external(currentSession, file.uri);
    }

    if (file.isPart) {
      throw ArgumentError('Is a part: $uri');
    }

    // The file is a local file, we can get the result.
    return getParsedLibrary(file.path);
  }

  /**
   * Return a [Future] that completes with a [ResolvedLibraryResult] for the
   * Dart library file with the given [path].  If the file is not a Dart file
   * or cannot be analyzed, the [Future] completes with `null`.
   *
   * Throw [ArgumentError] if the given [path] is not the defining compilation
   * unit for a library (that is, is a part of a library).
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   *
   * Invocation of this method causes the analysis state to transition to
   * "analyzing" (if it is not in that state already), the driver will produce
   * the resolution result for it, which is consistent with the current file
   * state (including new states of the files previously reported using
   * [changeFile]), prior to the next time the analysis state transitions
   * to "idle".
   */
  Future<ResolvedLibraryResult> getResolvedLibrary(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return new Future.value();
    }

    FileState file = _fsState.getFileForPath(path);

    if (file.isExternalLibrary) {
      return Future.value(
        ResolvedLibraryResultImpl.external(currentSession, file.uri),
      );
    }

    if (file.isPart) {
      throw ArgumentError('Is a part: $path');
    }

    // Schedule analysis.
    var completer = new Completer<ResolvedLibraryResult>();
    _requestedLibraries
        .putIfAbsent(path, () => <Completer<ResolvedLibraryResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /**
   * Return a [Future] that completes with a [ResolvedLibraryResult] for the
   * Dart library file with the given [uri].
   *
   * Throw [ArgumentError] if the given [uri] is not the defining compilation
   * unit for a library (that is, is a part of a library).
   *
   * Invocation of this method causes the analysis state to transition to
   * "analyzing" (if it is not in that state already), the driver will produce
   * the resolution result for it, which is consistent with the current file
   * state (including new states of the files previously reported using
   * [changeFile]), prior to the next time the analysis state transitions
   * to "idle".
   */
  Future<ResolvedLibraryResult> getResolvedLibraryByUri(Uri uri) {
    FileState file = _fsState.getFileForUri(uri);

    if (file.isExternalLibrary) {
      return Future.value(
        ResolvedLibraryResultImpl.external(currentSession, file.uri),
      );
    }

    if (file.isPart) {
      throw ArgumentError('Is a part: $uri');
    }

    // The file is a local file, we can get the result.
    return getResolvedLibrary(file.path);
  }

  ApiSignature getResolvedUnitKeyByPath(String path) {
    _throwIfNotAbsolutePath(path);
    ApiSignature signature = getUnitKeyByPath(path);
    var file = fsState.getFileForPath(path);
    signature.addString(file.contentHash);
    return signature;
  }

  /**
   * Return a [Future] that completes with a [ResolvedUnitResult] for the Dart
   * file with the given [path]. If the file is not a Dart file or cannot
   * be analyzed, the [Future] completes with `null`.
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   *
   * If the driver has the cached analysis result for the file, it is returned.
   * If [sendCachedToStream] is `true`, then the result is also reported into
   * the [results] stream, just as if it were freshly computed.
   *
   * Otherwise causes the analysis state to transition to "analyzing" (if it is
   * not in that state already), the driver will produce the analysis result for
   * it, which is consistent with the current file state (including new states
   * of the files previously reported using [changeFile]), prior to the next
   * time the analysis state transitions to "idle".
   */
  Future<ResolvedUnitResult> getResult(String path,
      {bool sendCachedToStream: false}) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return new Future.value();
    }

    // Return the cached result.
    {
      ResolvedUnitResult result = getCachedResult(path);
      if (result != null) {
        if (sendCachedToStream) {
          _resultController.add(result);
        }
        return new Future.value(result);
      }
    }

    // Schedule analysis.
    var completer = new Completer<ResolvedUnitResult>();
    _requestedFiles
        .putIfAbsent(path, () => <Completer<ResolvedUnitResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /**
   * Return a [Future] that completes with the [SourceKind] for the Dart
   * file with the given [path]. If the file is not a Dart file or cannot
   * be analyzed, the [Future] completes with `null`.
   *
   * The [path] must be absolute and normalized.
   */
  Future<SourceKind> getSourceKind(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    _throwIfNotAbsolutePath(path);
    if (AnalysisEngine.isDartFileName(path)) {
      FileState file = _fsState.getFileForPath(path);
      return file.isPart ? SourceKind.PART : SourceKind.LIBRARY;
    }
    return null;
  }

  /**
   * Return a [Future] that completes with top-level declarations with the
   * given [name] in all known libraries.
   */
  Future<List<TopLevelDeclarationInSource>> getTopLevelNameDeclarations(
      String name) {
    _discoverAvailableFiles();
    var task = new _TopLevelNameDeclarationsTask(this, name);
    _topLevelNameDeclarationsTasks.add(task);
    _scheduler.notify(this);
    return task.completer.future;
  }

  /**
   * Return a [Future] that completes with the [UnitElementResult] for the
   * file with the given [path], or with `null` if the file cannot be analyzed.
   */
  Future<UnitElementResult> getUnitElement(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return new Future.value();
    }
    var completer = new Completer<UnitElementResult>();
    _unitElementRequestedFiles
        .putIfAbsent(path, () => <Completer<UnitElementResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /**
   * Return a [Future] that completes with the signature for the
   * [UnitElementResult] for the file with the given [path], or with `null` if
   * the file cannot be analyzed.
   *
   * The signature is based the APIs of the files of the library (including
   * the file itself) of the requested file and the transitive closure of files
   * imported and exported by the library.
   */
  Future<String> getUnitElementSignature(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return new Future.value();
    }
    var completer = new Completer<String>();
    _unitElementSignatureFiles
        .putIfAbsent(path, () => <Completer<String>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  ApiSignature getUnitKeyByPath(String path) {
    _throwIfNotAbsolutePath(path);
    var file = fsState.getFileForPath(path);
    ApiSignature signature = new ApiSignature();
    signature.addUint32List(_linkedSalt);
    signature.addString(file.transitiveSignature);
    return signature;
  }

  /**
   * Return `true` is the file with the given absolute [uri] is a library,
   * or `false` if it is a part. More specifically, return `true` if the file
   * is not known to be a part.
   *
   * Correspondingly, return `true` if the [uri] does not correspond to a file,
   * for any reason, e.g. the file does not exist, or the [uri] cannot be
   * resolved to a file path, or the [uri] is invalid, e.g. a `package:` URI
   * without a package name. In these cases we cannot prove that the file is
   * not a part, so it must be a library.
   */
  bool isLibraryByUri(Uri uri) {
    return !_fsState.getFileForUri(uri).isPart;
  }

  /**
   * Return a [Future] that completes with a [ParsedUnitResult] for the file
   * with the given [path].
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   *
   * The parsing is performed in the method itself, and the result is not
   * produced through the [results] stream (just because it is not a fully
   * resolved unit).
   */
  Future<ParsedUnitResult> parseFile(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    return parseFileSync(path);
  }

  /**
   * Return a [ParsedUnitResult] for the file with the given [path].
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   *
   * The parsing is performed in the method itself, and the result is not
   * produced through the [results] stream (just because it is not a fully
   * resolved unit).
   */
  ParsedUnitResult parseFileSync(String path) {
    _throwIfNotAbsolutePath(path);
    FileState file = _fileTracker.verifyApiSignature(path);
    RecordingErrorListener listener = new RecordingErrorListener();
    CompilationUnit unit = file.parse(listener);
    return new ParsedUnitResultImpl(currentSession, file.path, file.uri,
        file.content, file.lineInfo, file.isPart, unit, listener.errors);
  }

  @override
  Future<void> performWork() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (_fileTracker.verifyChangedFilesIfNeeded()) {
      return;
    }

    // Analyze a requested file.
    if (_requestedFiles.isNotEmpty) {
      String path = _requestedFiles.keys.first;
      try {
        AnalysisResult result = _computeAnalysisResult(path, withUnit: true);
        // If a part without a library, delay its analysis.
        if (result == null) {
          _requestedParts
              .putIfAbsent(path, () => [])
              .addAll(_requestedFiles.remove(path));
          return;
        }
        // Notify the completers.
        _requestedFiles.remove(path).forEach((completer) {
          completer.complete(result);
        });
        // Remove from to be analyzed and produce it now.
        _fileTracker.fileWasAnalyzed(path);
        _resultController.add(result);
      } catch (exception, stackTrace) {
        _fileTracker.fileWasAnalyzed(path);
        _requestedFiles.remove(path).forEach((completer) {
          completer.completeError(exception, stackTrace);
        });
      }
      return;
    }

    // Analyze a requested library.
    if (_requestedLibraries.isNotEmpty) {
      String path = _requestedLibraries.keys.first;
      try {
        var result = _computeResolvedLibrary(path);
        _requestedLibraries.remove(path).forEach((completer) {
          completer.complete(result);
        });
      } catch (exception, stackTrace) {
        _requestedLibraries.remove(path).forEach((completer) {
          completer.completeError(exception, stackTrace);
        });
      }
      return;
    }

    // Process an index request.
    if (_indexRequestedFiles.isNotEmpty) {
      String path = _indexRequestedFiles.keys.first;
      AnalysisDriverUnitIndex index = _computeIndex(path);
      _indexRequestedFiles.remove(path).forEach((completer) {
        completer.complete(index);
      });
      return;
    }

    // Process a unit element key request.
    if (_unitElementSignatureFiles.isNotEmpty) {
      String path = _unitElementSignatureFiles.keys.first;
      String signature = _computeUnitElementSignature(path);
      var completers = _unitElementSignatureFiles.remove(path);
      if (signature != null) {
        completers.forEach((completer) {
          completer.complete(signature);
        });
      } else {
        _unitElementSignatureParts
            .putIfAbsent(path, () => [])
            .addAll(completers);
      }
      return;
    }

    // Process a unit element request.
    if (_unitElementRequestedFiles.isNotEmpty) {
      String path = _unitElementRequestedFiles.keys.first;
      UnitElementResult result = _computeUnitElement(path);
      var completers = _unitElementRequestedFiles.remove(path);
      if (result != null) {
        completers.forEach((completer) {
          completer.complete(result);
        });
      } else {
        _unitElementRequestedParts
            .putIfAbsent(path, () => [])
            .addAll(completers);
      }
      return;
    }

    // Discover available files.
    if (_discoverAvailableFilesTask != null &&
        !_discoverAvailableFilesTask.isCompleted) {
      _discoverAvailableFilesTask.perform();
      return;
    }

    // Compute files defining a name.
    if (_definingClassMemberNameTasks.isNotEmpty) {
      _FilesDefiningClassMemberNameTask task =
          _definingClassMemberNameTasks.first;
      bool isDone = task.perform();
      if (isDone) {
        _definingClassMemberNameTasks.remove(task);
      }
      return;
    }

    // Compute files referencing a name.
    if (_referencingNameTasks.isNotEmpty) {
      _FilesReferencingNameTask task = _referencingNameTasks.first;
      bool isDone = task.perform();
      if (isDone) {
        _referencingNameTasks.remove(task);
      }
      return;
    }

    // Compute top-level declarations.
    if (_topLevelNameDeclarationsTasks.isNotEmpty) {
      _TopLevelNameDeclarationsTask task = _topLevelNameDeclarationsTasks.first;
      bool isDone = task.perform();
      if (isDone) {
        _topLevelNameDeclarationsTasks.remove(task);
      }
      return;
    }

    // Analyze a priority file.
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_fileTracker.isFilePending(path)) {
          try {
            AnalysisResult result =
                _computeAnalysisResult(path, withUnit: true);
            if (result == null) {
              _partsToAnalyze.add(path);
            } else {
              _resultController.add(result);
            }
          } catch (exception, stackTrace) {
            _reportException(path, exception, stackTrace);
          } finally {
            _fileTracker.fileWasAnalyzed(path);
          }
          return;
        }
      }
    }

    // Analyze a general file.
    if (_fileTracker.hasPendingFiles) {
      String path = _fileTracker.anyPendingFile;
      try {
        AnalysisResult result = _computeAnalysisResult(path,
            withUnit: false, skipIfSameSignature: true);
        if (result == null) {
          _partsToAnalyze.add(path);
        } else if (result == AnalysisResult._UNCHANGED) {
          // We found that the set of errors is the same as we produced the
          // last time, so we don't need to produce it again now.
        } else {
          _resultController.add(result);
          _lastProducedSignatures[result.path] = result._signature;
        }
      } catch (exception, stackTrace) {
        _reportException(path, exception, stackTrace);
      } finally {
        _fileTracker.fileWasAnalyzed(path);
      }
      return;
    }

    // Analyze a requested part file.
    if (_requestedParts.isNotEmpty) {
      String path = _requestedParts.keys.first;
      try {
        AnalysisResult result = _computeAnalysisResult(path,
            withUnit: true, asIsIfPartWithoutLibrary: true);
        // Notify the completers.
        _requestedParts.remove(path).forEach((completer) {
          completer.complete(result);
        });
        // Remove from to be analyzed and produce it now.
        _partsToAnalyze.remove(path);
        _resultController.add(result);
      } catch (exception, stackTrace) {
        _partsToAnalyze.remove(path);
        _requestedParts.remove(path).forEach((completer) {
          completer.completeError(exception, stackTrace);
        });
      }
      return;
    }

    // Analyze a general part.
    if (_partsToAnalyze.isNotEmpty) {
      String path = _partsToAnalyze.first;
      _partsToAnalyze.remove(path);
      try {
        AnalysisResult result = _computeAnalysisResult(path,
            withUnit: _priorityFiles.contains(path),
            asIsIfPartWithoutLibrary: true);
        _resultController.add(result);
      } catch (exception, stackTrace) {
        _reportException(path, exception, stackTrace);
      }
      return;
    }

    // Process a unit element signature request for a part.
    if (_unitElementSignatureParts.isNotEmpty) {
      String path = _unitElementSignatureParts.keys.first;
      String signature =
          _computeUnitElementSignature(path, asIsIfPartWithoutLibrary: true);
      _unitElementSignatureParts.remove(path).forEach((completer) {
        completer.complete(signature);
      });
      return;
    }

    // Process a unit element request for a part.
    if (_unitElementRequestedParts.isNotEmpty) {
      String path = _unitElementRequestedParts.keys.first;
      UnitElementResult result =
          _computeUnitElement(path, asIsIfPartWithoutLibrary: true);
      _unitElementRequestedParts.remove(path).forEach((completer) {
        completer.complete(result);
      });
      return;
    }
  }

  /**
   * Remove the file with the given [path] from the list of files to analyze.
   *
   * The [path] must be absolute and normalized.
   *
   * The results of analysis of the file might still be produced by the
   * [results] stream. The driver will try to stop producing these results,
   * but does not guarantee this.
   */
  void removeFile(String path) {
    _throwIfNotAbsolutePath(path);
    _throwIfChangesAreNotAllowed();
    _fileTracker.removeFile(path);
    _libraryContext = null;
    _priorityResults.clear();
  }

  /**
   * Reset URI resolution, read again all files, build files graph, and ensure
   * that for all added files new results are reported.
   */
  void resetUriResolution() {
    _fsState.resetUriResolution();
    _fileTracker.scheduleAllAddedFiles();
    _changeHook(null);
  }

  /**
   * Implementation for [changeFile].
   */
  void _changeFile(String path) {
    _fileTracker.changeFile(path);
    _libraryContext = null;
    _priorityResults.clear();
  }

  /**
   * Handles a notification from the [FileTracker] that there has been a change
   * of state.
   */
  void _changeHook(String path) {
    _createNewSession(path);
    _libraryContext = null;
    _priorityResults.clear();
    _scheduler.notify(this);
  }

  /**
   * Return the cached or newly computed analysis result of the file with the
   * given [path].
   *
   * The result will have the fully resolved unit and will always be newly
   * compute only if [withUnit] is `true`.
   *
   * Return `null` if the file is a part of an unknown library, so cannot be
   * analyzed yet. But [asIsIfPartWithoutLibrary] is `true`, then the file is
   * analyzed anyway, even without a library.
   *
   * Return [AnalysisResult._UNCHANGED] if [skipIfSameSignature] is `true` and
   * the resolved signature of the file in its library is the same as the one
   * that was the most recently produced to the client.
   */
  AnalysisResult _computeAnalysisResult(String path,
      {bool withUnit: false,
      bool asIsIfPartWithoutLibrary: false,
      bool skipIfSameSignature: false}) {
    FileState file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    FileState library = file.isPart ? file.library : file;
    if (library == null) {
      if (asIsIfPartWithoutLibrary) {
        library = file;
      } else {
        return null;
      }
    }

    // Prepare the signature and key.
    String signature = _getResolvedUnitSignature(library, file);
    String key = _getResolvedUnitKey(signature);

    // Skip reading if the signature, so errors, are the same as the last time.
    if (skipIfSameSignature) {
      assert(!withUnit);
      if (_lastProducedSignatures[path] == signature) {
        return AnalysisResult._UNCHANGED;
      }
    }

    // If we don't need the fully resolved unit, check for the cached result.
    if (!withUnit) {
      List<int> bytes = DriverPerformance.cache.makeCurrentWhile(() {
        return _byteStore.get(key);
      });
      if (bytes != null) {
        return _getAnalysisResultFromBytes(file, signature, bytes);
      }
    }

    // We need the fully resolved unit, or the result is not cached.
    return _logger.run('Compute analysis result for $path', () {
      try {
        _testView.numOfAnalyzedLibraries++;

        if (!_fsState.getFileForUri(Uri.parse('dart:core')).exists) {
          return _newMissingDartLibraryResult(file, 'dart:core');
        }
        if (!_fsState.getFileForUri(Uri.parse('dart:async')).exists) {
          return _newMissingDartLibraryResult(file, 'dart:async');
        }
        var libraryContext = _createLibraryContext(library);

        LibraryAnalyzer analyzer = new LibraryAnalyzer(
            analysisOptions,
            declaredVariables,
            sourceFactory,
            libraryContext.isLibraryUri,
            libraryContext.analysisContext,
            libraryContext.resynthesizer,
            libraryContext.elementFactory,
            libraryContext.inheritanceManager,
            library,
            _resourceProvider);
        Map<FileState, UnitAnalysisResult> results = analyzer.analyze();

        List<int> bytes;
        CompilationUnit resolvedUnit;
        for (FileState unitFile in results.keys) {
          UnitAnalysisResult unitResult = results[unitFile];
          List<int> unitBytes =
              _serializeResolvedUnit(unitResult.unit, unitResult.errors);
          String unitSignature = _getResolvedUnitSignature(library, unitFile);
          String unitKey = _getResolvedUnitKey(unitSignature);
          _byteStore.put(unitKey, unitBytes);
          if (unitFile == file) {
            bytes = unitBytes;
            resolvedUnit = unitResult.unit;
          }
          if (disableChangesAndCacheAllResults) {
            AnalysisResult result = _getAnalysisResultFromBytes(
                unitFile, unitSignature, unitBytes,
                content: unitFile.content, resolvedUnit: unitResult.unit);
            _allCachedResults[unitFile.path] = result;
          }
        }

        // Return the result, full or partial.
        _logger.writeln('Computed new analysis result.');
        AnalysisResult result = _getAnalysisResultFromBytes(
            file, signature, bytes,
            content: withUnit ? file.content : null,
            resolvedUnit: withUnit ? resolvedUnit : null);
        if (withUnit && _priorityFiles.contains(path)) {
          _priorityResults[path] = result;
        }
        return result;
      } catch (exception, stackTrace) {
        String contextKey =
            _storeExceptionContext(path, library, exception, stackTrace);
        throw new _ExceptionState(exception, stackTrace, contextKey);
      }
    });
  }

  AnalysisDriverUnitIndex _computeIndex(String path) {
    AnalysisResult analysisResult = _computeAnalysisResult(path,
        withUnit: false, asIsIfPartWithoutLibrary: true);
    return analysisResult._index;
  }

  /**
   * Return the newly computed resolution result of the library with the
   * given [path].
   */
  ResolvedLibraryResultImpl _computeResolvedLibrary(String path) {
    FileState library = _fsState.getFileForPath(path);

    return _logger.run('Compute resolved library $path', () {
      _testView.numOfAnalyzedLibraries++;
      var libraryContext = _createLibraryContext(library);

      LibraryAnalyzer analyzer = new LibraryAnalyzer(
          analysisOptions,
          declaredVariables,
          sourceFactory,
          libraryContext.isLibraryUri,
          libraryContext.analysisContext,
          libraryContext.resynthesizer,
          libraryContext.elementFactory,
          libraryContext.inheritanceManager,
          library,
          _resourceProvider);
      Map<FileState, UnitAnalysisResult> unitResults = analyzer.analyze();
      var resolvedUnits = <ResolvedUnitResult>[];

      for (var unitFile in unitResults.keys) {
        if (unitFile.path != null) {
          var unitResult = unitResults[unitFile];
          resolvedUnits.add(
            new AnalysisResult(
              currentSession,
              _sourceFactory,
              unitFile.path,
              unitFile.uri,
              unitFile.exists,
              unitFile.content,
              unitFile.lineInfo,
              unitFile.isPart,
              null,
              unitResult.unit,
              unitResult.errors,
              null,
            ),
          );
        }
      }

      return new ResolvedLibraryResultImpl(
        currentSession,
        library.path,
        library.uri,
        resolvedUnits.first.libraryElement,
        libraryContext.typeProvider,
        resolvedUnits,
      );
    });
  }

  UnitElementResult _computeUnitElement(String path,
      {bool asIsIfPartWithoutLibrary: false}) {
    FileState file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    FileState library = file.isPart ? file.library : file;
    if (library == null) {
      if (asIsIfPartWithoutLibrary) {
        library = file;
      } else {
        return null;
      }
    }

    var libraryContext = _createLibraryContext(library);
    var element = libraryContext.computeUnitElement(library, file);
    return new UnitElementResultImpl(
        currentSession, path, file.uri, library.transitiveSignature, element);
  }

  String _computeUnitElementSignature(String path,
      {bool asIsIfPartWithoutLibrary: false}) {
    FileState file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    FileState library = file.isPart ? file.library : file;
    if (library == null) {
      if (asIsIfPartWithoutLibrary) {
        library = file;
      } else {
        return null;
      }
    }

    return library.transitiveSignature;
  }

  /**
   * Creates new [FileSystemState] and [FileTracker] objects.
   *
   * This is used both on initial construction and whenever the configuration
   * changes.
   */
  void _createFileTracker() {
    _fillSalt();
    _fsState = new FileSystemState(
      _logger,
      _byteStore,
      _contentOverlay,
      _resourceProvider,
      sourceFactory,
      analysisOptions,
      _unlinkedSalt,
      _linkedSalt,
      externalSummaries: _externalSummaries,
      useSummary2: useSummary2,
    );
    _fileTracker = new FileTracker(_logger, _fsState, _changeHook);
  }

  /**
   * Return the context in which the [library] should be analyzed.
   */
  LibraryContext _createLibraryContext(FileState library) {
    if (_libraryContext != null) {
      if (_libraryContext.pack()) {
        _libraryContext = null;
      }
    }

    if (_libraryContext == null || useSummary2) {
      _libraryContext = new LibraryContext(
        session: currentSession,
        logger: _logger,
        fsState: fsState,
        byteStore: _byteStore,
        analysisOptions: _analysisOptions,
        declaredVariables: declaredVariables,
        sourceFactory: _sourceFactory,
        externalSummaries: _externalSummaries,
        targetLibrary: library,
        useSummary2: useSummary2,
      );
    } else {
      _libraryContext.load(library);
    }
    return _libraryContext;
  }

  /**
   * Create a new analysis session, so invalidating the current one.
   */
  void _createNewSession(String path) {
    if (onCurrentSessionAboutToBeDiscarded != null) {
      onCurrentSessionAboutToBeDiscarded(path);
    }
    _currentSession = new AnalysisSessionImpl(this);
  }

  /**
   * If this has not been done yet, schedule discovery of all files that are
   * potentially available, so that they are included in [knownFiles].
   */
  void _discoverAvailableFiles() {
    _discoverAvailableFilesTask ??= new _DiscoverAvailableFilesTask(this);
  }

  /**
   * Fill [_unlinkedSalt] and [_linkedSalt] with data.
   */
  void _fillSalt() {
    _unlinkedSalt[0] = DATA_VERSION;
    _unlinkedSalt[1] = enableIndex ? 1 : 0;
    _unlinkedSalt.setAll(2, _analysisOptions.unlinkedSignature);

    _linkedSalt[0] = DATA_VERSION;
    _linkedSalt[1] = enableIndex ? 1 : 0;
    _linkedSalt.setAll(2, _analysisOptions.signature);
  }

  /**
   * Load the [AnalysisResult] for the given [file] from the [bytes]. Set
   * optional [content] and [resolvedUnit].
   */
  AnalysisResult _getAnalysisResultFromBytes(
      FileState file, String signature, List<int> bytes,
      {String content, CompilationUnit resolvedUnit}) {
    var unit = new AnalysisDriverResolvedUnit.fromBuffer(bytes);
    List<AnalysisError> errors = _getErrorsFromSerialized(file, unit.errors);
    _updateHasErrorOrWarningFlag(file, errors);
    return new AnalysisResult(
        currentSession,
        _sourceFactory,
        file.path,
        file.uri,
        file.exists,
        content,
        file.lineInfo,
        file.isPart,
        signature,
        resolvedUnit,
        errors,
        unit.index);
  }

  /**
   * Return [AnalysisError]s for the given [serialized] errors.
   */
  List<AnalysisError> _getErrorsFromSerialized(
      FileState file, List<AnalysisDriverUnitError> serialized) {
    List<AnalysisError> errors = <AnalysisError>[];
    for (AnalysisDriverUnitError error in serialized) {
      String errorName = error.uniqueName;
      ErrorCode errorCode =
          errorCodeByUniqueName(errorName) ?? _lintCodeByUniqueName(errorName);
      if (errorCode == null) {
        // This could fail because the error code is no longer defined, or, in
        // the case of a lint rule, if the lint rule has been disabled since the
        // errors were written.
        AnalysisEngine.instance.instrumentationService
            .logError('No error code for "$error" in "$file"');
      } else {
        errors.add(new AnalysisError.forValues(
            file.source,
            error.offset,
            error.length,
            errorCode,
            error.message,
            error.correction.isEmpty ? null : error.correction));
      }
    }
    return errors;
  }

  /**
   * Return the key to store fully resolved results for the [signature].
   */
  String _getResolvedUnitKey(String signature) {
    return '$signature.resolved';
  }

  /**
   * Return the signature that identifies fully resolved results for the [file]
   * in the [library], e.g. element model, errors, index, etc.
   */
  String _getResolvedUnitSignature(FileState library, FileState file) {
    ApiSignature signature = new ApiSignature();
    signature.addUint32List(_linkedSalt);
    signature.addString(library.transitiveSignature);
    signature.addString(file.contentHash);
    return signature.toHex();
  }

  /**
   * Return the lint code with the given [errorName], or `null` if there is no
   * lint registered with that name.
   */
  ErrorCode _lintCodeByUniqueName(String errorName) {
    const String lintPrefix = 'LintCode.';
    if (errorName.startsWith(lintPrefix)) {
      String lintName = errorName.substring(lintPrefix.length);
      return linter.Registry.ruleRegistry.getRule(lintName)?.lintCode;
    }

    const String lintPrefixOld = '_LintCode.';
    if (errorName.startsWith(lintPrefixOld)) {
      String lintName = errorName.substring(lintPrefixOld.length);
      return linter.Registry.ruleRegistry.getRule(lintName)?.lintCode;
    }

    return null;
  }

  /**
   * We detected that one of the required `dart` libraries is missing.
   * Return the empty analysis result with the error.
   */
  AnalysisResult _newMissingDartLibraryResult(
      FileState file, String missingUri) {
    // TODO(scheglov) Find a better way to report this.
    return new AnalysisResult(
        currentSession,
        _sourceFactory,
        file.path,
        file.uri,
        file.exists,
        null,
        file.lineInfo,
        file.isPart,
        null,
        null,
        [
          new AnalysisError(file.source, 0, 0,
              CompileTimeErrorCode.MISSING_DART_LIBRARY, [missingUri])
        ],
        null);
  }

  void _reportException(String path, exception, StackTrace stackTrace) {
    String contextKey = null;
    if (exception is _ExceptionState) {
      var state = exception as _ExceptionState;
      exception = state.exception;
      stackTrace = state.stackTrace;
      contextKey = state.contextKey;
    }
    CaughtException caught = new CaughtException(exception, stackTrace);
    _exceptionController.add(new ExceptionResult(path, caught, contextKey));
  }

  /**
   * Serialize the given [resolvedUnit] errors and index into bytes.
   */
  List<int> _serializeResolvedUnit(
      CompilationUnit resolvedUnit, List<AnalysisError> errors) {
    AnalysisDriverUnitIndexBuilder index = enableIndex
        ? indexUnit(resolvedUnit)
        : new AnalysisDriverUnitIndexBuilder();
    return new AnalysisDriverResolvedUnitBuilder(
            errors: errors
                .map((error) => new AnalysisDriverUnitErrorBuilder(
                    offset: error.offset,
                    length: error.length,
                    uniqueName: error.errorCode.uniqueName,
                    message: error.message,
                    correction: error.correction))
                .toList(),
            index: index)
        .toBuffer();
  }

  String _storeExceptionContext(
      String path, FileState libraryFile, exception, StackTrace stackTrace) {
    if (allowedNumberOfContextsToWrite <= 0) {
      return null;
    } else {
      allowedNumberOfContextsToWrite--;
    }
    try {
      List<AnalysisDriverExceptionFileBuilder> contextFiles = libraryFile
          .transitiveFiles
          .map((file) => new AnalysisDriverExceptionFileBuilder(
              path: file.path, content: file.content))
          .toList();
      contextFiles.sort((a, b) => a.path.compareTo(b.path));
      AnalysisDriverExceptionContextBuilder contextBuilder =
          new AnalysisDriverExceptionContextBuilder(
              path: path,
              exception: exception.toString(),
              stackTrace: stackTrace.toString(),
              files: contextFiles);
      List<int> bytes = contextBuilder.toBuffer();

      String _twoDigits(int n) {
        if (n >= 10) return '$n';
        return '0$n';
      }

      String _threeDigits(int n) {
        if (n >= 100) return '$n';
        if (n >= 10) return '0$n';
        return '00$n';
      }

      DateTime time = new DateTime.now();
      String m = _twoDigits(time.month);
      String d = _twoDigits(time.day);
      String h = _twoDigits(time.hour);
      String min = _twoDigits(time.minute);
      String sec = _twoDigits(time.second);
      String ms = _threeDigits(time.millisecond);
      String key = 'exception_${time.year}$m$d' '_$h$min$sec' + '_$ms';

      _byteStore.put(key, bytes);
      return key;
    } catch (_) {
      return null;
    }
  }

  /**
   * If the driver is used in the read-only mode with infinite cache,
   * we should not allow invocations that change files.
   */
  void _throwIfChangesAreNotAllowed() {
    if (disableChangesAndCacheAllResults) {
      throw new StateError('Changing files is not allowed for this driver.');
    }
  }

  /**
   * The driver supports only absolute paths, this method is used to validate
   * any input paths to prevent errors later.
   */
  void _throwIfNotAbsolutePath(String path) {
    if (!_resourceProvider.pathContext.isAbsolute(path)) {
      throw new ArgumentError('Only absolute paths are supported: $path');
    }
  }

  /**
   * Given the list of [errors] for the [file], update the [file]'s
   * [FileState.hasErrorOrWarning] flag.
   */
  void _updateHasErrorOrWarningFlag(
      FileState file, List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      ErrorSeverity severity = error.errorCode.errorSeverity;
      if (severity == ErrorSeverity.ERROR ||
          severity == ErrorSeverity.WARNING) {
        file.hasErrorOrWarning = true;
        return;
      }
    }
    file.hasErrorOrWarning = false;
  }
}

/**
 * A generic schedulable interface via the AnalysisDriverScheduler. Currently
 * only implemented by [AnalysisDriver] and the angular plugin, at least as
 * a temporary measure until the official plugin API is ready (and a different
 * scheduler is used)
 */
abstract class AnalysisDriverGeneric {
  /**
   * Return `true` if the driver has a file to analyze.
   */
  bool get hasFilesToAnalyze;

  /**
   * Set the list of files that the driver should try to analyze sooner.
   *
   * Every path in the list must be absolute and normalized.
   *
   * The driver will produce the results through the [results] stream. The
   * exact order in which results are produced is not defined, neither
   * between priority files, nor between priority and non-priority files.
   */
  void set priorityFiles(List<String> priorityPaths);

  /**
   * Return the priority of work that the driver needs to perform.
   */
  AnalysisDriverPriority get workPriority;

  /**
   * Add the file with the given [path] to the set of files that are explicitly
   * being analyzed.
   *
   * The [path] must be absolute and normalized.
   *
   * The results of analysis are eventually produced by the [results] stream.
   */
  void addFile(String path);

  /**
   * Notify the driver that the client is going to stop using it.
   */
  void dispose();

  /**
   * Perform a single chunk of work and produce [results].
   */
  Future<void> performWork();
}

/**
 * Priorities of [AnalysisDriver] work. The farther a priority to the beginning
 * of the list, the earlier the corresponding [AnalysisDriver] should be asked
 * to perform work.
 */
enum AnalysisDriverPriority {
  nothing,
  general,
  generalWithErrors,
  generalImportChanged,
  generalChanged,
  changedFiles,
  priority,
  interactive
}

/**
 * Instances of this class schedule work in multiple [AnalysisDriver]s so that
 * work with the highest priority is performed first.
 */
class AnalysisDriverScheduler {
  /**
   * Time interval in milliseconds before pumping the event queue.
   *
   * Relinquishing execution flow and running the event loop after every task
   * has too much overhead. Instead we use a fixed length of time, so we can
   * spend less time overall and still respond quickly enough.
   */
  static const int _MS_BEFORE_PUMPING_EVENT_QUEUE = 2;

  /**
   * Event queue pumping is required to allow IO and other asynchronous data
   * processing while analysis is active. For example Analysis Server needs to
   * be able to process `updateContent` or `setPriorityFiles` requests while
   * background analysis is in progress.
   *
   * The number of pumpings is arbitrary, might be changed if we see that
   * analysis or other data processing tasks are starving. Ideally we would
   * need to run all asynchronous operations using a single global scheduler.
   */
  static const int _NUMBER_OF_EVENT_QUEUE_PUMPINGS = 128;

  final PerformanceLog _logger;

  /**
   * The object used to watch as analysis drivers are created and deleted.
   */
  final DriverWatcher driverWatcher;

  final List<AnalysisDriverGeneric> _drivers = [];
  final Monitor _hasWork = new Monitor();
  final StatusSupport _statusSupport = new StatusSupport();

  bool _started = false;

  /**
   * The optional worker that is invoked when its work priority is higher
   * than work priorities in drivers.
   *
   * Don't use outside of Analyzer and Analysis Server.
   */
  SchedulerWorker outOfBandWorker;

  AnalysisDriverScheduler(this._logger, {this.driverWatcher});

  /**
   * Return `true` if we are currently analyzing code.
   */
  bool get isAnalyzing => _hasFilesToAnalyze;

  /**
   * Return the stream that produces [AnalysisStatus] events.
   */
  Stream<AnalysisStatus> get status => _statusSupport.stream;

  /**
   * Return `true` if there is a driver with a file to analyze.
   */
  bool get _hasFilesToAnalyze {
    for (AnalysisDriverGeneric driver in _drivers) {
      if (driver.hasFilesToAnalyze) {
        return true;
      }
    }
    return false;
  }

  /**
   * Add the given [driver] and schedule it to perform its work.
   */
  void add(AnalysisDriverGeneric driver) {
    _drivers.add(driver);
    _hasWork.notify();
    if (driver is AnalysisDriver) {
      driverWatcher?.addedDriver(driver, driver.contextRoot);
    }
  }

  /**
   * Notify that there is a change to the [driver], it it might need to
   * perform some work.
   */
  void notify(AnalysisDriverGeneric driver) {
    _hasWork.notify();
    _statusSupport.preTransitionToAnalyzing();
  }

  /**
   * Remove the given [driver] from the scheduler, so that it will not be
   * asked to perform any new work.
   */
  void remove(AnalysisDriverGeneric driver) {
    if (driver is AnalysisDriver) {
      driverWatcher?.removedDriver(driver);
    }
    _drivers.remove(driver);
    _hasWork.notify();
  }

  /**
   * Start the scheduler, so that any [AnalysisDriver] created before or
   * after will be asked to perform work.
   */
  void start() {
    if (_started) {
      throw new StateError('The scheduler has already been started.');
    }
    _started = true;
    _run();
  }

  /**
   * Return a future that will be completed the next time the status is idle.
   *
   * If the status is currently idle, the returned future will be signaled
   * immediately.
   */
  Future<void> waitForIdle() => _statusSupport.waitForIdle();

  /**
   * Run infinitely analysis cycle, selecting the drivers with the highest
   * priority first.
   */
  Future<void> _run() async {
    // Give other microtasks the time to run before doing the analysis cycle.
    await null;
    Stopwatch timer = new Stopwatch()..start();
    PerformanceLogSection analysisSection;
    while (true) {
      // Pump the event queue.
      if (timer.elapsedMilliseconds > _MS_BEFORE_PUMPING_EVENT_QUEUE) {
        await _pumpEventQueue(_NUMBER_OF_EVENT_QUEUE_PUMPINGS);
        timer.reset();
      }

      await _hasWork.signal;

      // Transition to analyzing if there are files to analyze.
      if (_hasFilesToAnalyze) {
        _statusSupport.transitionToAnalyzing();
        analysisSection ??= _logger.enter('Analyzing');
      }

      // Find the driver with the highest priority.
      AnalysisDriverGeneric bestDriver;
      AnalysisDriverPriority bestPriority = AnalysisDriverPriority.nothing;
      for (AnalysisDriverGeneric driver in _drivers) {
        AnalysisDriverPriority priority = driver.workPriority;
        if (priority.index > bestPriority.index) {
          bestDriver = driver;
          bestPriority = priority;
        }
      }

      if (outOfBandWorker != null) {
        var workerPriority = outOfBandWorker.workPriority;
        if (workerPriority != AnalysisDriverPriority.nothing) {
          if (workerPriority.index > bestPriority.index) {
            await outOfBandWorker.performWork();
            _hasWork.notify();
            continue;
          }
        }
      }

      // Transition to idle if no files to analyze.
      if (!_hasFilesToAnalyze) {
        _statusSupport.transitionToIdle();
        analysisSection?.exit();
        analysisSection = null;
      }

      // Continue to sleep if no work to do.
      if (bestPriority == AnalysisDriverPriority.nothing) {
        continue;
      }

      // Ask the driver to perform a chunk of work.
      await bestDriver.performWork();

      // Schedule one more cycle.
      _hasWork.notify();
    }
  }

  /**
   * Returns a [Future] that completes after performing [times] pumpings of
   * the event queue.
   */
  static Future _pumpEventQueue(int times) {
    if (times == 0) {
      return new Future.value();
    }
    return new Future.delayed(Duration.zero, () => _pumpEventQueue(times - 1));
  }
}

@visibleForTesting
class AnalysisDriverTestView {
  final AnalysisDriver driver;

  int numOfAnalyzedLibraries = 0;

  AnalysisDriverTestView(this.driver);

  FileTracker get fileTracker => driver._fileTracker;

  Map<String, ResolvedUnitResult> get priorityResults {
    return driver._priorityResults;
  }

  SummaryDataStore getSummaryStore(String libraryPath) {
    FileState library = driver.fsState.getFileForPath(libraryPath);
    LibraryContext libraryContext = driver._createLibraryContext(library);
    return libraryContext.store;
  }
}

/**
 * The result of analyzing of a single file.
 *
 * These results are self-consistent, i.e. [content], [lineInfo], the
 * resolved [unit] correspond to each other. All referenced elements, even
 * external ones, are also self-consistent. But none of the results is
 * guaranteed to be consistent with the state of the files.
 *
 * Every result is independent, and is not guaranteed to be consistent with
 * any previously returned result, even inside of the same library.
 */
class AnalysisResult extends ResolvedUnitResultImpl {
  static final _UNCHANGED = new AnalysisResult(
      null, null, null, null, null, null, null, null, null, null, null, null);
  /**
   * The [SourceFactory] with which the file was analyzed.
   */
  final SourceFactory sourceFactory;

  /**
   * The signature of the result based on the content of the file, and the
   * transitive closure of files imported and exported by the library of
   * the requested file.
   */
  final String _signature;

  /**
   * The index of the unit.
   */
  final AnalysisDriverUnitIndex _index;

  AnalysisResult(
      AnalysisSession session,
      this.sourceFactory,
      String path,
      Uri uri,
      bool exists,
      String content,
      LineInfo lineInfo,
      bool isPart,
      this._signature,
      CompilationUnit unit,
      List<AnalysisError> errors,
      this._index)
      : super(session, path, uri, exists, content, lineInfo, isPart, unit,
            errors);

  @override
  LibraryElement get libraryElement => unit.declaredElement.library;

  @override
  TypeProvider get typeProvider => unit.declaredElement.context.typeProvider;

  @override
  TypeSystem get typeSystem => unit.declaredElement.context.typeSystem;
}

class DriverPerformance {
  static final PerformanceTag driver =
      PerformanceStatistics.analyzer.createChild('driver');

  static final PerformanceTag cache = driver.createChild('cache');
}

/**
 * An object that watches for the creation and removal of analysis drivers.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DriverWatcher {
  /**
   * The context manager has just added the given analysis [driver]. This method
   * must be called before the driver has been allowed to perform any analysis.
   */
  void addedDriver(AnalysisDriver driver, ContextRoot contextRoot);

  /**
   * The context manager has just removed the given analysis [driver].
   */
  void removedDriver(AnalysisDriver driver);
}

/**
 * Exception that happened during analysis.
 */
class ExceptionResult {
  /**
   * The path of the file being analyzed when the [exception] happened.
   *
   * Absolute and normalized.
   */
  final String path;

  /**
   * The exception during analysis of the file with the [path].
   */
  final CaughtException exception;

  /**
   * If the exception happened during a file analysis, and the context in which
   * the exception happened was stored, this field is the key of the context
   * in the byte store. May be `null` if the context is unknown, the maximum
   * number of context to store was reached, etc.
   */
  final String contextKey;

  ExceptionResult(this.path, this.exception, this.contextKey);
}

/// Worker in [AnalysisDriverScheduler].
abstract class SchedulerWorker {
  /// Return the priority of work that this worker needs to perform.
  AnalysisDriverPriority get workPriority;

  /// Perform a single chunk of work.
  Future<void> performWork();
}

/**
 * Task that discovers all files that are available to the driver, and makes
 * them known.
 */
class _DiscoverAvailableFilesTask {
  static const int _MS_WORK_INTERVAL = 5;

  final AnalysisDriver driver;

  bool isCompleted = false;
  Completer<void> completer = new Completer<void>();

  Iterator<Folder> folderIterator;
  List<String> files = [];
  int fileIndex = 0;

  _DiscoverAvailableFilesTask(this.driver);

  /**
   * Perform the next piece of work, and set [isCompleted] to `true` to
   * indicate that the task is done, or keeps it `false` to indicate that the
   * task should continue to be run.
   */
  void perform() {
    if (folderIterator == null) {
      files.addAll(driver.addedFiles);

      // Discover SDK libraries.
      var dartSdk = driver._sourceFactory.dartSdk;
      if (dartSdk != null) {
        for (var sdkLibrary in dartSdk.sdkLibraries) {
          var file = dartSdk.mapDartUri(sdkLibrary.shortName).fullName;
          files.add(file);
        }
      }

      // Discover files in package/lib folders.
      var packageMap = driver._sourceFactory.packageMap;
      if (packageMap != null) {
        folderIterator = packageMap.values.expand((f) => f).iterator;
      } else {
        folderIterator = <Folder>[].iterator;
      }
    }

    // List each package/lib folder recursively.
    Stopwatch timer = new Stopwatch()..start();
    while (folderIterator.moveNext()) {
      var folder = folderIterator.current;
      _appendFilesRecursively(folder);

      // Note: must check if we are exiting before calling moveNext()
      // otherwise we will skip one iteration of the loop when we come back.
      if (timer.elapsedMilliseconds > _MS_WORK_INTERVAL) {
        return;
      }
    }

    // Get know files one by one.
    while (fileIndex < files.length) {
      if (timer.elapsedMilliseconds > _MS_WORK_INTERVAL) {
        return;
      }
      var file = files[fileIndex++];
      driver._fsState.getFileForPath(file);
    }

    // The task is done, clean up.
    folderIterator = null;
    files = null;

    // Complete and clean up.
    isCompleted = true;
    completer.complete();
    completer = null;
  }

  void _appendFilesRecursively(Folder folder) {
    try {
      for (var child in folder.getChildren()) {
        if (child is File) {
          var path = child.path;
          if (AnalysisEngine.isDartFileName(path)) {
            files.add(path);
          }
        } else if (child is Folder) {
          _appendFilesRecursively(child);
        }
      }
    } catch (_) {}
  }
}

/**
 * Information about an exception and its context.
 */
class _ExceptionState {
  final exception;
  final StackTrace stackTrace;

  /**
   * The key under which the context of the exception was stored, or `null`
   * if unknown, the maximum number of context to store was reached, etc.
   */
  final String contextKey;

  _ExceptionState(this.exception, this.stackTrace, this.contextKey);

  @override
  String toString() => '$exception\n$stackTrace';
}

/**
 * Task that computes the list of files that were added to the driver and
 * declare a class member with the given [name].
 */
class _FilesDefiningClassMemberNameTask {
  static const int _MS_WORK_INTERVAL = 5;

  final AnalysisDriver driver;
  final String name;
  final Completer<List<String>> completer = new Completer<List<String>>();

  final List<String> definingFiles = <String>[];
  final Set<String> checkedFiles = new Set<String>();
  final List<String> filesToCheck = <String>[];

  _FilesDefiningClassMemberNameTask(this.driver, this.name);

  /**
   * Perform work for a fixed length of time, and complete the [completer] to
   * either return `true` to indicate that the task is done, or return `false`
   * to indicate that the task should continue to be run.
   *
   * Each invocation of an asynchronous method has overhead, which looks as
   * `_SyncCompleter.complete` invocation, we see as much as 62% in some
   * scenarios. Instead we use a fixed length of time, so we can spend less time
   * overall and keep quick enough response time.
   */
  bool perform() {
    Stopwatch timer = new Stopwatch()..start();
    while (timer.elapsedMilliseconds < _MS_WORK_INTERVAL) {
      // Prepare files to check.
      if (filesToCheck.isEmpty) {
        Set<String> newFiles = driver.addedFiles.difference(checkedFiles);
        filesToCheck.addAll(newFiles);
      }

      // If no more files to check, complete and done.
      if (filesToCheck.isEmpty) {
        completer.complete(definingFiles);
        return true;
      }

      // Check the next file.
      String path = filesToCheck.removeLast();
      FileState file = driver._fsState.getFileForPath(path);
      if (file.definedClassMemberNames.contains(name)) {
        definingFiles.add(path);
      }
      checkedFiles.add(path);
    }

    // We're not done yet.
    return false;
  }
}

/**
 * Task that computes the list of files that were added to the driver and
 * have at least one reference to an identifier [name] defined outside of the
 * file.
 */
class _FilesReferencingNameTask {
  static const int _WORK_FILES = 100;
  static const int _MS_WORK_INTERVAL = 5;

  final AnalysisDriver driver;
  final String name;
  final Completer<List<String>> completer = new Completer<List<String>>();

  int fileStamp = -1;
  List<FileState> filesToCheck;
  int filesToCheckIndex;

  final List<String> referencingFiles = <String>[];

  _FilesReferencingNameTask(this.driver, this.name);

  /**
   * Perform work for a fixed length of time, and complete the [completer] to
   * either return `true` to indicate that the task is done, or return `false`
   * to indicate that the task should continue to be run.
   *
   * Each invocation of an asynchronous method has overhead, which looks as
   * `_SyncCompleter.complete` invocation, we see as much as 62% in some
   * scenarios. Instead we use a fixed length of time, so we can spend less time
   * overall and keep quick enough response time.
   */
  bool perform() {
    if (driver._fsState.fileStamp != fileStamp) {
      filesToCheck = null;
      referencingFiles.clear();
    }

    // Prepare files to check.
    if (filesToCheck == null) {
      fileStamp = driver._fsState.fileStamp;
      filesToCheck = driver._fsState.knownFiles;
      filesToCheckIndex = 0;
    }

    Stopwatch timer = new Stopwatch()..start();
    while (filesToCheckIndex < filesToCheck.length) {
      if (filesToCheckIndex % _WORK_FILES == 0 &&
          timer.elapsedMilliseconds > _MS_WORK_INTERVAL) {
        return false;
      }
      FileState file = filesToCheck[filesToCheckIndex++];
      if (file.referencedNames.contains(name)) {
        referencingFiles.add(file.path);
      }
    }

    // If no more files to check, complete and done.
    completer.complete(referencingFiles);
    return true;
  }
}

/**
 * Task that computes top-level declarations for a certain name in all
 * known libraries.
 */
class _TopLevelNameDeclarationsTask {
  final AnalysisDriver driver;
  final String name;
  final Completer<List<TopLevelDeclarationInSource>> completer =
      new Completer<List<TopLevelDeclarationInSource>>();

  final List<TopLevelDeclarationInSource> libraryDeclarations =
      <TopLevelDeclarationInSource>[];
  final Set<String> checkedFiles = new Set<String>();
  final List<String> filesToCheck = <String>[];

  _TopLevelNameDeclarationsTask(this.driver, this.name);

  /**
   * Perform a single piece of work, and either complete the [completer] and
   * return `true` to indicate that the task is done, return `false` to indicate
   * that the task should continue to be run.
   */
  bool perform() {
    // Prepare files to check.
    if (filesToCheck.isEmpty) {
      filesToCheck.addAll(driver.addedFiles.difference(checkedFiles));
      filesToCheck.addAll(driver.knownFiles.difference(checkedFiles));
    }

    // If no more files to check, complete and done.
    if (filesToCheck.isEmpty) {
      completer.complete(libraryDeclarations);
      return true;
    }

    // Check the next file.
    String path = filesToCheck.removeLast();
    if (checkedFiles.add(path)) {
      FileState file = driver._fsState.getFileForPath(path);
      if (!file.isPart) {
        bool isExported = false;

        TopLevelDeclaration declaration;
        for (FileState part in file.libraryFiles) {
          declaration ??= part.topLevelDeclarations[name];
        }

        if (declaration == null) {
          declaration = file.exportedTopLevelDeclarations[name];
          isExported = true;
        }
        if (declaration != null) {
          libraryDeclarations.add(new TopLevelDeclarationInSource(
              file.source, declaration, isExported));
        }
      }
    }

    // We're not done yet.
    return false;
  }
}
