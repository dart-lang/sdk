// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart' as events;
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/file_tracker.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/lint/registry.dart' as linter;
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/async.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:meta/meta.dart';

/// This class computes analysis results for Dart files.
///
/// Let the set of "explicitly analyzed files" denote the set of paths that have
/// been passed to [addFile] but not subsequently passed to [removeFile]. Let
/// the "current analysis results" denote the map from the set of explicitly
/// analyzed files to the most recent [AnalysisResult] delivered to `events`
/// for each file. Let the "current file state" represent a map from file path
/// to the file contents most recently read from that file, or fetched from the
/// content cache (considering all possible file paths, regardless of
/// whether they're in the set of explicitly analyzed files). Let the
/// "analysis state" be either "working" or "idle".
///
/// (These are theoretical constructs; they may not necessarily reflect data
/// structures maintained explicitly by the driver).
///
/// Then we make the following guarantees:
///
///    - Whenever the analysis state is idle, the current analysis results are
///      consistent with the current file state.
///
///    - A call to [addFile] or [changeFile] causes the analysis state to
///      transition to "working", and schedules the contents of the given
///      files to be read into the current file state prior to the next time
///      the analysis state transitions back to "idle".
///
///    - If at any time the client stops making calls to [addFile], [changeFile],
///      and [removeFile], the analysis state will eventually transition back to
///      "idle" after a finite amount of processing.
///
/// As a result of these guarantees, a client may ensure that the analysis
/// results are "eventually consistent" with the file system by simply calling
/// [changeFile] any time the contents of a file on the file system have changed.
///
// TODO(scheglov): Clean up the list of implicitly analyzed files.
class AnalysisDriver {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 367;

  /// The number of exception contexts allowed to write. Once this field is
  /// zero, we stop writing any new exception contexts in this process.
  static int allowedNumberOfContextsToWrite = 10;

  /// The scheduler that schedules analysis work in this, and possibly other
  /// analysis drivers.
  final AnalysisDriverScheduler _scheduler;

  /// The logger to write performed operations and performance to.
  final PerformanceLog _logger;

  /// The resource provider for working with files.
  final ResourceProvider _resourceProvider;

  /// The byte storage to get and put serialized data.
  ///
  /// It can be shared with other [AnalysisDriver]s.
  final ByteStore _byteStore;

  /// The cache of deserialized data read from SummaryDataReader.
  ///
  /// It can be shared with other [AnalysisDriver]s.
  final InfoDeclarationStore _infoDeclarationStore;

  /// The optional store with externally provided unlinked and corresponding
  /// linked summaries. These summaries are always added to the store for any
  /// file analysis.
  final SummaryDataStore? _externalSummaries;

  /// This [ContentCache] is consulted for a file content before reading
  /// the content from the file.
  final FileContentCache _fileContentCache;

  /// The already loaded unlinked units,  consulted before deserializing
  /// from file again.
  final UnlinkedUnitStore _unlinkedUnitStore;

  late final StoredFileContentStrategy _fileContentStrategy;

  /// The [Packages] object with packages and their language versions.
  final Packages _packages;

  /// The [SourceFactory] is used to resolve URIs to paths and restore URIs
  /// from file paths.
  final SourceFactory _sourceFactory;

  /// The support for executing macros.
  final MacroSupport? macroSupport;

  /// The container, shared with other drivers within the same collection,
  /// into which all drivers record files ownership.
  final OwnedFiles? ownedFiles;

  /// The declared environment variables.
  final DeclaredVariables declaredVariables;

  /// The analysis context that created this driver / session.
  DriverBasedAnalysisContext? analysisContext;

  /// The salt to mix into all hashes used as keys for unlinked data.
  Uint32List _saltForUnlinked = Uint32List(0);

  /// The salt to mix into all hashes used as keys for elements.
  Uint32List _saltForElements = Uint32List(0);

  /// The salt to mix into all hashes used as keys for linked data.
  Uint32List _saltForResolution = Uint32List(0);

  /// The set of priority files, that should be analyzed sooner.
  final _priorityFiles = <String>{};

  /// The file changes that should be applied before processing requests.
  final List<_FileChange> _pendingFileChanges = [];

  /// When [_applyFileChangesSynchronously] is `true`, affected files are
  /// accumulated here.
  Set<String> _accumulatedAffected = {};

  /// The completers to complete after [_pendingFileChanges] are applied.
  final _pendingFileChangesCompleters = <Completer<List<String>>>[];

  /// The mapping from the files for which analysis was requested using
  /// [getResolvedUnit] to the [Completer]s to report the result.
  final _requestedFiles = <String, List<Completer<SomeResolvedUnitResult>>>{};

  /// The mapping from the files for which analysis was requested using
  /// [getResolvedLibrary] to the [Completer]s to report the result.
  final _requestedLibraries =
      <String, List<Completer<SomeResolvedLibraryResult>>>{};

  /// The queue of requests for completion.
  final List<_ResolveForCompletionRequest> _resolveForCompletionRequests = [];

  /// Set to `true` after first [discoverAvailableFiles].
  bool _hasAvailableFilesDiscovered = false;

  /// The requests to compute files defining a class member with the name.
  final _definingClassMemberNameRequests =
      <_GetFilesDefiningClassMemberNameRequest>[];

  /// The requests to compute files referencing a name.
  final _referencingNameRequests = <_GetFilesReferencingNameRequest>[];

  /// The mapping from the files for which errors were requested using
  /// [getErrors] to the [Completer]s to report the result.
  final _errorsRequestedFiles = <String, List<Completer<SomeErrorsResult>>>{};

  /// The mapping from the files for which the index was requested using
  /// [getIndex] to the [Completer]s to report the result.
  final _indexRequestedFiles =
      <String, List<Completer<AnalysisDriverUnitIndex?>>>{};

  /// The mapping from the files for which the unit element was requested using
  /// [getUnitElement] to the [Completer]s to report the result.
  final _unitElementRequestedFiles =
      <String, List<Completer<SomeUnitElementResult>>>{};

  /// The list of dispose requests, added in [dispose2], almost always empty.
  /// We expect that at most one is added, at the very end of the life cycle.
  final List<Completer<void>> _disposeRequests = [];

  /// Resolution signatures of the most recently produced results for files.
  final Map<String, String> _lastProducedSignatures = {};

  /// Cached results for [_priorityFiles].
  final Map<String, ResolvedUnitResult> _priorityResults = {};

  /// Cached results of [getResolvedLibrary].
  final Map<String, ResolvedLibraryResultImpl> _resolvedLibraryCache = {};

  /// The controller for the [exceptions] stream.
  final StreamController<ExceptionResult> _exceptionController =
      StreamController<ExceptionResult>();

  /// The instance of the [Search] helper.
  late final Search _search;

  final AnalysisDriverTestView? testView;

  late FileSystemState _fsState;

  /// The [FileTracker] used by this driver.
  late FileTracker _fileTracker;

  /// Whether resolved units should be indexed.
  final bool enableIndex;

  /// The context in which libraries should be analyzed.
  LibraryContext? _libraryContext;

  /// Whether `dart:core` has been transitively discovered.
  bool _hasDartCoreDiscovered = false;

  /// This flag is reset to `false` when a new file is added, because it
  /// might be a library, so that some files that were disconnected parts
  /// could be analyzed now.
  bool _hasLibrariesDiscovered = false;

  /// If testing data is being retained, a pointer to the object that is
  /// retaining the testing data.  Otherwise `null`.
  final TestingData? testingData;

  bool _disposed = false;

  /// A map that associates files to corresponding analysis options.
  late final AnalysisOptionsMap analysisOptionsMap;

  /// Create a new instance of [AnalysisDriver].
  ///
  /// The given [SourceFactory] is cloned to ensure that it does not contain a
  /// reference to an [AnalysisContext] in which it could have been used.
  AnalysisDriver({
    required AnalysisDriverScheduler scheduler,
    required PerformanceLog logger,
    required ResourceProvider resourceProvider,
    required ByteStore byteStore,
    required SourceFactory sourceFactory,
    required Packages packages,
    this.macroSupport,
    this.ownedFiles,
    this.analysisContext,
    @Deprecated("Use 'analysisOptionsMap' instead")
    AnalysisOptionsImpl? analysisOptions,
    AnalysisOptionsMap? analysisOptionsMap,
    FileContentCache? fileContentCache,
    UnlinkedUnitStore? unlinkedUnitStore,
    InfoDeclarationStore? infoDeclarationStore,
    this.enableIndex = false,
    SummaryDataStore? externalSummaries,
    DeclaredVariables? declaredVariables,
    bool retainDataForTesting = false,
    this.testView,
  })  : _scheduler = scheduler,
        _resourceProvider = resourceProvider,
        _byteStore = byteStore,
        _fileContentCache =
            fileContentCache ?? FileContentCache.ephemeral(resourceProvider),
        _unlinkedUnitStore = unlinkedUnitStore ?? UnlinkedUnitStoreImpl(),
        _infoDeclarationStore =
            infoDeclarationStore ?? NoOpInfoDeclarationStore(),
        _logger = logger,
        _packages = packages,
        _sourceFactory = sourceFactory,
        _externalSummaries = externalSummaries,
        declaredVariables = declaredVariables ?? DeclaredVariables(),
        testingData = retainDataForTesting ? TestingData() : null {
    analysisContext?.driver = this;
    testView?.driver = this;

    // Setup the options map.
    // This extra work is temporary and will get simplified when the deprecated support for
    // passing in a single analysisOptions is removed.
    if (analysisOptionsMap != null && analysisOptions != null) {
      throw AssertionError(
          'An analysisOptionsMap or analysisOptions can be specified, but not both');
    }
    if (analysisOptions != null) {
      this.analysisOptionsMap =
          AnalysisOptionsMap.forSharedOptions(analysisOptions);
    } else {
      // This '!' is temporary. The analysisOptionsMap is effectively required but can't be until Google3 is updated.
      this.analysisOptionsMap = analysisOptionsMap!;
    }

    _fileContentStrategy = StoredFileContentStrategy(_fileContentCache);

    _createFileTracker();
    _scheduler.add(this);
    _search = Search(this);
  }

  /// Return the set of files explicitly added to analysis using [addFile].
  Set<String> get addedFiles => _fileTracker.addedFiles;

  /// See [addedFiles].
  Set<File> get addedFiles2 {
    return addedFiles.map(resourceProvider.getFile).toSet();
  }

  /// Return the analysis options used to control analysis.
  @Deprecated("Use 'getAnalysisOptionsForFile(file)' instead")
  AnalysisOptions get analysisOptions => analysisOptionsMap.firstOrDefault;

  /// Return the current analysis session.
  AnalysisSessionImpl get currentSession {
    return libraryContext.elementFactory.analysisSession;
  }

  /// Return a list of the names of all the plugins enabled in analysis options
  /// in this driver.
  List<String> get enabledPluginNames => analysisOptionsMap.entries
      .map((e) => e.options.enabledPluginNames)
      .flattenedToList2;

  /// Return the stream that produces [ExceptionResult]s.
  Stream<ExceptionResult> get exceptions => _exceptionController.stream;

  /// The current file system state.
  FileSystemState get fsState => _fsState;

  bool get hasPendingFileChanges => _pendingFileChanges.isNotEmpty;

  /// Return the set of files that are known at this moment. This set does not
  /// always include all added files or all implicitly used file. If a file has
  /// not been processed yet, it might be missing.
  Set<FileState> get knownFiles => _fsState.knownFiles;

  /// Return the context in which libraries should be analyzed.
  LibraryContext get libraryContext {
    return _libraryContext ??= LibraryContext(
      testData: testView?.libraryContext,
      analysisSession: AnalysisSessionImpl(this),
      logger: _logger,
      byteStore: _byteStore,
      infoDeclarationStore: _infoDeclarationStore,
      analysisOptionsMap: analysisOptionsMap,
      declaredVariables: declaredVariables,
      sourceFactory: _sourceFactory,
      macroSupport: macroSupport,
      packagesFile: analysisContext?.contextRoot.packagesFile,
      externalSummaries: _externalSummaries,
      fileSystemState: _fsState,
    );
  }

  /// Return the path of the folder at the root of the context.
  String get name => analysisContext?.contextRoot.root.path ?? '';

  /// Return the number of files scheduled for analysis.
  int get numberOfFilesToAnalyze => _fileTracker.numberOfPendingFiles;

  /// Return the list of files that the driver should try to analyze sooner.
  List<String> get priorityFiles => _priorityFiles.toList(growable: false);

  /// Set the list of files that the driver should try to analyze sooner.
  ///
  /// Every path in the list must be absolute and normalized.
  ///
  /// The driver will produce the results through the `events` stream. The
  /// exact order in which results are produced is not defined, neither
  /// between priority files, nor between priority and non-priority files.
  set priorityFiles(List<String> priorityPaths) {
    _priorityResults.keys
        .toSet()
        .difference(priorityPaths.toSet())
        .forEach(_priorityResults.remove);
    _priorityFiles.clear();
    _priorityFiles.addAll(priorityPaths);
    _scheduler.notify();
  }

  /// See [priorityFiles].
  set priorityFiles2(List<File> files) {
    priorityFiles = files.map((e) => e.path).toList();
  }

  /// Return the [ResourceProvider] that is used to access the file system.
  ResourceProvider get resourceProvider => _resourceProvider;

  AnalysisDriverScheduler get scheduler => _scheduler;

  /// Return the search support for the driver.
  Search get search => _search;

  /// Return the source factory used to resolve URIs to paths and restore URIs
  /// from file paths.
  SourceFactory get sourceFactory => _sourceFactory;

  /// Return the priority of work that the driver needs to perform.
  AnalysisDriverPriority get workPriority {
    if (_disposeRequests.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_resolveForCompletionRequests.isNotEmpty) {
      return AnalysisDriverPriority.completion;
    }
    if (_requestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_requestedLibraries.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_definingClassMemberNameRequests.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_referencingNameRequests.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_errorsRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_indexRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_unitElementRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_fileTracker.isFilePending(path)) {
          return AnalysisDriverPriority.priority;
        }
      }
    }
    if (_pendingFileChanges.isNotEmpty) {
      return AnalysisDriverPriority.general;
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
    if (_pendingFileChangesCompleters.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    return AnalysisDriverPriority.nothing;
  }

  /// Whether the driver has a file to analyze.
  bool get _hasFilesToAnalyze {
    return hasPendingFileChanges ||
        _fileTracker.hasPendingFiles ||
        _fileTracker.hasChangedFiles ||
        _requestedLibraries.isNotEmpty ||
        _requestedFiles.isNotEmpty ||
        _errorsRequestedFiles.isNotEmpty ||
        _definingClassMemberNameRequests.isNotEmpty ||
        _referencingNameRequests.isNotEmpty ||
        _indexRequestedFiles.isNotEmpty ||
        _unitElementRequestedFiles.isNotEmpty ||
        _disposeRequests.isNotEmpty;
  }

  /// Add the file with the given [path] to the set of files that are explicitly
  /// being analyzed.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The results of analysis are eventually produced by the `events` stream.
  void addFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      _priorityResults.clear();
      _resolvedLibraryCache.clear();
      _pendingFileChanges.add(
        _FileChange(path, _FileChangeKind.add),
      );
      _scheduler.notify();
    }
  }

  /// See [addFile].
  void addFile2(File file) {
    addFile(file.path);
  }

  /// Return a [Future] that completes after pending file changes are applied,
  /// so that [currentSession] can be used to compute results.
  ///
  /// The value is the set of all files that are potentially affected by
  /// the pending changes. This set can be both wider than the set of analyzed
  /// files (because it may include files imported from other packages, and
  /// which are on the import path from a changed file to an analyze file),
  /// and narrower than the set of analyzed files (because only files that
  /// were previously accessed are considered to be known and affected).
  Future<List<String>> applyPendingFileChanges() {
    if (_pendingFileChanges.isNotEmpty) {
      if (_disposed) throw DisposedAnalysisContextResult();
      var completer = Completer<List<String>>();
      _pendingFileChangesCompleters.add(completer);
      return completer.future;
    } else {
      var accumulatedAffected = _accumulatedAffected.toList();
      _accumulatedAffected = {};
      return Future.value(accumulatedAffected);
    }
  }

  /// Builds elements for library files from [uriList], and packs them into
  /// a bundle suitable for [PackageBundleReader].
  ///
  /// Disconnected non-library files are ignored.
  Future<Uint8List> buildPackageBundle({
    required List<Uri> uriList,
    PackageBundleSdk? packageBundleSdk,
  }) async {
    var elementFactory = libraryContext.elementFactory;

    var bundleWriter = BundleWriter(
      elementFactory.dynamicRef,
    );
    var packageBundleBuilder = PackageBundleBuilder();

    for (var uri in uriList) {
      var uriStr = uri.toString();
      var libraryResult = await getLibraryByUri(uriStr);
      if (libraryResult is LibraryElementResult) {
        var libraryElement = libraryResult.element as LibraryElementImpl;
        bundleWriter.writeLibraryElement(libraryElement);

        packageBundleBuilder.addLibrary(
          uriStr,
          libraryElement.units.map((e) {
            return e.source.uri.toString();
          }).toList(),
        );
      }
    }

    var writeWriterResult = bundleWriter.finish();

    return packageBundleBuilder.finish(
      resolutionBytes: writeWriterResult.resolutionBytes,
      sdk: packageBundleSdk,
    );
  }

  /// The file with the given [path] might have changed - updated, added or
  /// removed. Or not, we don't know. Or it might have, but then changed back.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// Causes the analysis state to transition to "working" (if it is not in
  /// that state already). Schedules the file contents for [path] to be read
  /// into the current file state prior to the next time the analysis state
  /// transitions to "idle".
  ///
  /// Invocation of this method will not prevent a [Future] returned from
  /// [getResolvedUnit] from completing with a result, but the result is not
  /// guaranteed to be consistent with the new current file state after this
  /// [changeFile] invocation.
  void changeFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      _priorityResults.clear();
      _resolvedLibraryCache.clear();
      _pendingFileChanges.add(
        _FileChange(path, _FileChangeKind.change),
      );
      _scheduler.notify();
    }
  }

  /// See [changeFile].
  void changeFile2(File file) {
    changeFile(file.path);
  }

  /// Clear the library context and any related data structures. Mostly we do
  /// this to reduce memory consumption. The library context holds to every
  /// library that was resynthesized, but after some initial analysis we might
  /// not get again to many of these libraries. So, we should clear the context
  /// periodically.
  void clearLibraryContext() {
    _libraryContext?.dispose();
    _libraryContext = null;
  }

  /// Return a [Future] that completes when discovery of all files that are
  /// potentially available is done, so that they are included in [knownFiles].
  Future<void> discoverAvailableFiles() async {
    if (_hasAvailableFilesDiscovered) {
      return;
    }
    _hasAvailableFilesDiscovered = true;

    // Discover added files.
    for (var path in addedFiles) {
      _fsState.getFileForPath(path);
    }

    // Discover SDK libraries.
    if (_sourceFactory.dartSdk case var dartSdk?) {
      for (var sdkLibrary in dartSdk.sdkLibraries) {
        var source = dartSdk.mapDartUri(sdkLibrary.shortName);
        var path = source!.fullName;
        _fsState.getFileForPath(path);
      }
    }

    void discoverRecursively(Folder folder) {
      try {
        var pathContext = resourceProvider.pathContext;
        for (var child in folder.getChildren()) {
          if (child is File) {
            var path = child.path;
            if (file_paths.isDart(pathContext, path)) {
              _fsState.getFileForPath(path);
            }
          } else if (child is Folder) {
            discoverRecursively(child);
          }
        }
      } catch (_) {}
    }

    // Discover files in package/lib folders.
    if (_sourceFactory.packageMap case var packageMap?) {
      var folders = packageMap.values.flattenedToList2;
      for (var folder in folders) {
        discoverRecursively(folder);
      }
    }
  }

  /// Notify the driver that the client is going to stop using it.
  Future<void> dispose2() async {
    var completer = Completer<void>();
    _disposed = true;
    _disposeRequests.add(completer);

    // Complete all waiting completers.
    for (var completerList in _requestedLibraries.values) {
      for (var completer in completerList) {
        completer.complete(DisposedAnalysisContextResult());
      }
    }
    _requestedLibraries.clear();

    for (var completerList in _requestedFiles.values) {
      for (var completer in completerList) {
        completer.complete(DisposedAnalysisContextResult());
      }
    }
    _requestedFiles.clear();

    for (var completerList in _unitElementRequestedFiles.values) {
      for (var completer in completerList) {
        completer.complete(DisposedAnalysisContextResult());
      }
    }
    _unitElementRequestedFiles.clear();

    for (var completerList in _errorsRequestedFiles.values) {
      for (var completer in completerList) {
        completer.complete(DisposedAnalysisContextResult());
      }
    }
    _errorsRequestedFiles.clear();

    for (var completer in _pendingFileChangesCompleters) {
      completer.completeError(DisposedAnalysisContextResult());
    }
    _pendingFileChangesCompleters.clear();

    _scheduler.notify();
    return completer.future;
  }

  /// NOTE: this API is experimental and subject to change in a future
  /// release (see https://github.com/dart-lang/sdk/issues/53876 for context).
  @experimental
  AnalysisOptionsImpl getAnalysisOptionsForFile(File file) =>
      analysisOptionsMap.getOptions(file);

  /// Return the cached [ResolvedUnitResult] for the Dart file with the given
  /// [path]. If there is no cached result, return `null`. Usually only results
  /// of priority files are cached.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ResolvedUnitResult? getCachedResolvedUnit(String path) {
    _throwIfNotAbsolutePath(path);
    return _priorityResults[path];
  }

  /// See [getCachedResolvedUnit].
  ResolvedUnitResult? getCachedResolvedUnit2(File file) {
    return _priorityResults[file.path];
  }

  /// Return a [Future] that completes with the [ErrorsResult] for the Dart
  /// file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// This method does not use analysis priorities, and must not be used in
  /// interactive analysis, such as Analysis Server or its plugins.
  Future<SomeErrorsResult> getErrors(String path) async {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    if (_disposed) {
      return Future.value(
        DisposedAnalysisContextResult(),
      );
    }

    // If a macro generated file, request its library instead.
    var file = resourceProvider.getFile(path);
    if (file.libraryForMacro case var library?) {
      _errorsRequestedFiles.addKey(library.path);
    }

    // Schedule analysis.
    var completer = Completer<SomeErrorsResult>();
    _errorsRequestedFiles.add(path, completer);
    _scheduler.notify();
    return completer.future;
  }

  /// Completes with files that define a class member with the [name].
  Future<List<FileState>> getFilesDefiningClassMemberName(String name) async {
    await discoverAvailableFiles();
    var request = _GetFilesDefiningClassMemberNameRequest(name);
    _definingClassMemberNameRequests.add(request);
    _scheduler.notify();
    return request.completer.future;
  }

  /// Completes with files that reference the given external [name].
  Future<List<FileState>> getFilesReferencingName(String name) async {
    await discoverAvailableFiles();
    var request = _GetFilesReferencingNameRequest(name);
    _referencingNameRequests.add(request);
    _scheduler.notify();
    return request.completer.future;
  }

  /// Return the [FileResult] for the Dart file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  SomeFileResult getFileSync(String path) {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    FileState file = _fsState.getFileForPath(path);
    return FileResultImpl(
      session: currentSession,
      fileState: file,
    );
  }

  /// See [getFileSync].
  SomeFileResult getFileSync2(File file) {
    return getFileSync(file.path);
  }

  /// Return a [Future] that completes with the [AnalysisDriverUnitIndex] for
  /// the file with the given [path], or with `null` if the file cannot be
  /// analyzed.
  Future<AnalysisDriverUnitIndex?> getIndex(String path) {
    _throwIfNotAbsolutePath(path);
    if (!enableIndex) {
      throw ArgumentError('Indexing is not enabled.');
    }
    if (!_fsState.hasUri(path)) {
      return Future.value();
    }

    // If a macro generated file, request its library instead.
    var file = resourceProvider.getFile(path);
    if (file.libraryForMacro case var library?) {
      _indexRequestedFiles.addKey(library.path);
    }

    // Schedule analysis.
    var completer = Completer<AnalysisDriverUnitIndex?>();
    _indexRequestedFiles.add(path, completer);
    _scheduler.notify();
    return completer.future;
  }

  /// See [getIndex].
  Future<AnalysisDriverUnitIndex?> getIndex2(File file) {
    return getIndex(file.path);
  }

  /// Return a [Future] that completes with [LibraryElementResult] for the given
  /// [uri], which is either resynthesized from the provided external summary
  /// store, or built for a file to which the given [uri] is resolved.
  Future<SomeLibraryElementResult> getLibraryByUri(String uri) async {
    var uriObj = uriCache.parse(uri);

    // Check if the element is already computed.
    if (_pendingFileChanges.isEmpty) {
      var rootReference = libraryContext.elementFactory.rootReference;
      var reference = rootReference.getChild('$uriObj');
      var element = reference.element;
      if (element is LibraryElementImpl) {
        return LibraryElementResultImpl(element);
      }
    }

    var fileOr = _fsState.getFileForUri(uriObj);
    switch (fileOr) {
      case null:
        return CannotResolveUriResult();
      case UriResolutionFile(:var file):
        var kind = file.kind;
        if (kind is LibraryFileKind) {
        } else if (kind is AugmentationFileKind) {
          return NotLibraryButAugmentationResult();
        } else if (kind is PartFileKind) {
          return NotLibraryButPartResult();
        } else {
          throw UnimplementedError('(${kind.runtimeType}) $kind');
        }

        var unitResult = await getUnitElement(file.path);
        if (unitResult is UnitElementResult) {
          return LibraryElementResultImpl(unitResult.element.library);
        }

        // Some invalid results are invalid results for this request.
        // Note that up-down promotion does not work.
        if (unitResult is InvalidResult &&
            unitResult is SomeLibraryElementResult) {
          return unitResult as SomeLibraryElementResult;
        }

        // Should not happen.
        return UnspecifiedInvalidResult();
      case UriResolutionExternalLibrary(:var source):
        var uri = source.uri;
        // TODO(scheglov): Check if the source is not for library.
        var element = libraryContext.getLibraryElement(uri);
        return LibraryElementResultImpl(element);
    }
  }

  /// Return a [ParsedLibraryResult] for the library with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  SomeParsedLibraryResult getParsedLibrary(String path) {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    if (!_fsState.hasUri(path)) {
      return NotPathOfUriResult();
    }

    var file = _fsState.getFileForPath(path);
    var kind = file.kind;
    if (kind is LibraryFileKind) {
    } else if (kind is AugmentationFileKind) {
      return NotLibraryButAugmentationResult();
    } else if (kind is PartFileKind) {
      return NotLibraryButPartResult();
    } else {
      throw UnimplementedError('(${kind.runtimeType}) $kind');
    }

    var units = <ParsedUnitResult>[];
    for (var unitFile in kind.files) {
      var unitPath = unitFile.path;
      var unitResult = parseFileSync(unitPath);
      if (unitResult is! ParsedUnitResult) {
        return UnspecifiedInvalidResult();
      }
      units.add(unitResult);
    }

    return ParsedLibraryResultImpl(
      session: currentSession,
      units: units,
    );
  }

  /// See [getParsedLibrary].
  SomeParsedLibraryResult getParsedLibrary2(File file) {
    return getParsedLibrary(file.path);
  }

  /// Return a [ParsedLibraryResult] for the library with the given [uri].
  SomeParsedLibraryResult getParsedLibraryByUri(Uri uri) {
    var fileOr = _fsState.getFileForUri(uri);
    switch (fileOr) {
      case null:
        return CannotResolveUriResult();
      case UriResolutionFile(:var file):
        return getParsedLibrary(file.path);
      case UriResolutionExternalLibrary():
        return UriOfExternalLibraryResult();
    }
  }

  /// Return a [Future] that completes with a [ResolvedLibraryResult] for the
  /// Dart library file with the given [path].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// Invocation of this method causes the analysis state to transition to
  /// "working" (if it is not in that state already), the driver will produce
  /// the resolution result for it, which is consistent with the current file
  /// state (including new states of the files previously reported using
  /// [changeFile]), prior to the next time the analysis state transitions
  /// to "idle".
  Future<SomeResolvedLibraryResult> getResolvedLibrary(String path) async {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    if (!_fsState.hasUri(path)) {
      return NotPathOfUriResult();
    }

    if (_disposed) {
      return Future.value(
        DisposedAnalysisContextResult(),
      );
    }

    if (_resolvedLibraryCache[path] case var cached?) {
      return cached;
    }

    var completer = Completer<SomeResolvedLibraryResult>();
    _requestedLibraries.add(path, completer);
    _scheduler.notify();
    return completer.future;
  }

  /// Return a [Future] that completes with a [ResolvedLibraryResult] for the
  /// Dart library file with the given [uri].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// Invocation of this method causes the analysis state to transition to
  /// "working" (if it is not in that state already), the driver will produce
  /// the resolution result for it, which is consistent with the current file
  /// state (including new states of the files previously reported using
  /// [changeFile]), prior to the next time the analysis state transitions
  /// to "idle".
  Future<SomeResolvedLibraryResult> getResolvedLibraryByUri(Uri uri) async {
    var fileOr = _fsState.getFileForUri(uri);
    switch (fileOr) {
      case null:
        return CannotResolveUriResult();
      case UriResolutionFile(:var file):
        return getResolvedLibrary(file.path);
      case UriResolutionExternalLibrary():
        return UriOfExternalLibraryResult();
    }
  }

  /// Return a [Future] that completes with a [SomeResolvedUnitResult] for the
  /// Dart file with the given [path].  If the file cannot be analyzed,
  /// the [Future] completes with an [InvalidResult].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// If the driver has the cached analysis result for the file, it is returned.
  /// If [sendCachedToStream] is `true`, then the result is also reported into
  /// the `events` stream, just as if it were freshly computed.
  ///
  /// Otherwise causes the analysis state to transition to "working" (if it is
  /// not in that state already), the driver will produce the analysis result for
  /// it, which is consistent with the current file state (including new states
  /// of the files previously reported using [changeFile]), prior to the next
  /// time the analysis state transitions to "idle".
  Future<SomeResolvedUnitResult> getResolvedUnit(String path,
      {bool sendCachedToStream = false}) {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    // Return the cached result.
    {
      ResolvedUnitResult? result = getCachedResolvedUnit(path);
      if (result != null) {
        if (sendCachedToStream) {
          _scheduler.eventsController.add(result);
        }
        return Future.value(result);
      }
    }

    if (_disposed) {
      return Future.value(
        DisposedAnalysisContextResult(),
      );
    }

    // If a macro generated file, request its library instead.
    var file = resourceProvider.getFile(path);
    if (file.libraryForMacro case var library?) {
      _requestedFiles.addKey(library.path);
    }

    // Schedule analysis.
    var completer = Completer<SomeResolvedUnitResult>();
    _requestedFiles.add(path, completer);
    _scheduler.notify();
    return completer.future;
  }

  /// See [getResolvedUnit].
  Future<SomeResolvedUnitResult> getResolvedUnit2(File file,
      {bool sendCachedToStream = false}) {
    return getResolvedUnit(
      file.path,
      sendCachedToStream: sendCachedToStream,
    );
  }

  /// Return a [Future] that completes with the [SomeUnitElementResult]
  /// for the file with the given [path].
  Future<SomeUnitElementResult> getUnitElement(String path) {
    if (!_isAbsolutePath(path)) {
      return Future.value(
        InvalidPathResult(),
      );
    }

    if (!_fsState.hasUri(path)) {
      return Future.value(
        NotPathOfUriResult(),
      );
    }

    if (_disposed) {
      return Future.value(
        DisposedAnalysisContextResult(),
      );
    }

    // If a macro generated file, request its library.
    // Once the library is ready, we can return the requested result.
    var file = resourceProvider.getFile(path);
    if (file.libraryForMacro case var library?) {
      _unitElementRequestedFiles.addKey(library.path);
    }

    // Schedule analysis.
    var completer = Completer<SomeUnitElementResult>();
    _unitElementRequestedFiles.add(path, completer);
    _scheduler.notify();
    return completer.future;
  }

  /// See [getUnitElement].
  Future<SomeUnitElementResult> getUnitElement2(File file) {
    return getUnitElement(file.path);
  }

  /// Return a [ParsedUnitResult] for the file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The [path] can be any file - explicitly or implicitly analyzed, or neither.
  ///
  /// The parsing is performed in the method itself, and the result is not
  /// produced through the `events` stream (just because it is not a fully
  /// resolved unit).
  SomeParsedUnitResult parseFileSync(String path) {
    if (!_isAbsolutePath(path)) {
      return InvalidPathResult();
    }

    FileState file = _fsState.getFileForPath(path);
    RecordingErrorListener listener = RecordingErrorListener();
    CompilationUnit unit = file.parse(listener);
    return ParsedUnitResultImpl(
      session: currentSession,
      fileState: file,
      unit: unit,
      errors: listener.errors,
    );
  }

  /// See [parseFileSync].
  SomeParsedUnitResult parseFileSync2(File file) {
    return parseFileSync(file.path);
  }

  /// Perform a single chunk of work and produce `events`.
  Future<void> performWork() async {
    _discoverDartCore();
    _discoverLibraries();

    if (_resolveForCompletionRequests.removeLastOrNull() case var request?) {
      try {
        var result = await _resolveForCompletion(request);
        request.completer.complete(result);
      } catch (exception, stackTrace) {
        _reportException(request.path, exception, stackTrace, null);
        request.completer.completeError(exception, stackTrace);
        _clearLibraryContextAfterException();
      }
      return;
    }

    // Analyze a requested file.
    if (_requestedFiles.firstKey case var path?) {
      await _analyzeFile(path);
      return;
    }

    // Analyze a requested library.
    if (_requestedLibraries.firstKey case var path?) {
      await _getResolvedLibrary(path);
      return;
    }

    // Process an error request.
    if (_errorsRequestedFiles.firstKey case var path?) {
      await _getErrors(path);
      return;
    }

    // Process an index request.
    if (_indexRequestedFiles.firstKey case var path?) {
      await _getIndex(path);
      return;
    }

    // Process a unit element request.
    if (_unitElementRequestedFiles.firstKey case var path?) {
      await _getUnitElement(path);
      return;
    }

    // Compute files defining a class member.
    if (_definingClassMemberNameRequests.removeLastOrNull() case var request?) {
      await _getFilesDefiningClassMemberName(request);
      return;
    }

    // Compute files referencing a name.
    if (_referencingNameRequests.removeLastOrNull() case var request?) {
      await _getFilesReferencingName(request);
      return;
    }

    // Analyze a priority file.
    for (var path in _priorityFiles) {
      if (_fileTracker.isFilePending(path)) {
        await _analyzeFile(path);
        return;
      }
    }

    // Analyze a general file.
    if (_fileTracker.anyPendingFile case var path?) {
      await _produceErrors(path);
      return;
    }
  }

  /// Remove the file with the given [path] from the list of files to analyze.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// The results of analysis of the file might still be produced by the
  /// `events` stream. The driver will try to stop producing these results,
  /// but does not guarantee this.
  void removeFile(String path) {
    _throwIfNotAbsolutePath(path);
    if (!_fsState.hasUri(path)) {
      return;
    }
    if (file_paths.isDart(resourceProvider.pathContext, path)) {
      _lastProducedSignatures.remove(path);
      _priorityResults.clear();
      _resolvedLibraryCache.clear();
      _pendingFileChanges.add(
        _FileChange(path, _FileChangeKind.remove),
      );
      _scheduler.notify();
    }
  }

  /// See [removeFile].
  void removeFile2(File file) {
    removeFile(file.path);
  }

  Future<ResolvedForCompletionResultImpl?> resolveForCompletion({
    required String path,
    required int offset,
    required OperationPerformanceImpl performance,
  }) async {
    var request = _ResolveForCompletionRequest(
      path: path,
      offset: offset,
      performance: performance,
    );
    _resolveForCompletionRequests.add(request);
    _scheduler.notify();
    return request.completer.future;
  }

  void _addDeclaredVariablesToSignature(ApiSignature buffer) {
    var variableNames = declaredVariables.variableNames;
    buffer.addInt(variableNames.length);

    for (var name in variableNames) {
      var value = declaredVariables.get(name);
      buffer.addString(name);
      buffer.addString(value!);
    }
  }

  Future<void> _analyzeFile(String path) async {
    await scheduler.accumulatedPerformance.runAsync(
      'analyzeFile',
      (performance) async {
        await _analyzeFileImpl(
          path: path,
          performance: performance,
        );
      },
    );
  }

  Future<void> _analyzeFileImpl({
    required String path,
    required OperationPerformanceImpl performance,
  }) async {
    // We will produce the result for this file, at least.
    // And for any other files of the same library.
    _fileTracker.fileWasAnalyzed(path);

    var file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    var kind = file.kind;
    var library = kind.library ?? kind.asLibrary;

    // We need the fully resolved unit, or the result is not cached.
    return _logger.runAsync('Compute analysis result for $path', () async {
      _logger.writeln('Work in $name');
      try {
        testView?.numOfAnalyzedLibraries++;
        _scheduler.eventsController.add(
          events.AnalyzeFile(
            file: file,
            library: library,
          ),
        );

        if (!_hasLibraryByUri('dart:core')) {
          _errorsRequestedFiles.completeAll(
            path,
            _newMissingDartLibraryResult(file, 'dart:core'),
          );
          return;
        }

        if (!_hasLibraryByUri('dart:async')) {
          _errorsRequestedFiles.completeAll(
            path,
            _newMissingDartLibraryResult(file, 'dart:async'),
          );
          return;
        }

        await performance.runAsync(
          'libraryContext',
          (performance) async {
            await libraryContext.load(
              targetLibrary: library,
              performance: performance,
            );
          },
        );

        for (var import in library.docImports) {
          if (import is LibraryImportWithFile) {
            if (import.importedLibrary case var libraryFileKind?) {
              await libraryContext.load(
                targetLibrary: libraryFileKind,
                performance: OperationPerformanceImpl('<root>'),
              );
            }
          }
        }

        var analysisOptions = file.analysisOptions;
        var libraryElement =
            libraryContext.elementFactory.libraryOfUri2(library.file.uri);
        var typeSystemOperations = TypeSystemOperations(
            libraryElement.typeSystem,
            strictCasts: analysisOptions.strictCasts);

        var results = LibraryAnalyzer(
          analysisOptions,
          declaredVariables,
          libraryElement,
          libraryContext.elementFactory.analysisSession.inheritanceManager,
          library,
          testingData: testingData,
          typeSystemOperations: typeSystemOperations,
        ).analyze();

        var isLibraryWithPriorityFile = _isLibraryWithPriorityFile(library);

        var resolvedUnits = <ResolvedUnitResultImpl>[];
        for (var unitResult in results) {
          var unitFile = unitResult.file;

          var index = enableIndex
              ? indexUnit(unitResult.unit)
              : AnalysisDriverUnitIndexBuilder();

          var resolvedUnit = _createResolvedUnitImpl(
            file: unitFile,
            unitResult: unitResult,
          );
          resolvedUnits.add(resolvedUnit);

          // getResolvedUnit()
          _requestedFiles.completeAll(unitFile.path, resolvedUnit);

          // getErrors()
          _errorsRequestedFiles.completeAll(
            unitFile.path,
            _createErrorsResultImpl(
              file: unitFile,
              errors: unitResult.errors,
            ),
          );

          // getIndex()
          _indexRequestedFiles.completeAll(unitFile.path, index);

          var unitSignature = _getResolvedUnitSignature(library, unitFile);
          {
            var unitKey = _getResolvedUnitKey(unitSignature);
            var unitBytes = AnalysisDriverResolvedUnitBuilder(
              errors: unitResult.errors.map((error) {
                return ErrorEncoding.encode(error);
              }).toList(),
              index: index,
            ).toBuffer();
            _byteStore.putGet(unitKey, unitBytes);
          }

          _fileTracker.fileWasAnalyzed(unitFile.path);
          _lastProducedSignatures[path] = unitSignature;
          _scheduler.eventsController.add(resolvedUnit);

          if (isLibraryWithPriorityFile) {
            _priorityResults[unitFile.path] = resolvedUnit;
          }

          _updateHasErrorOrWarningFlag(unitFile, resolvedUnit.errors);
        }

        var libraryResult = ResolvedLibraryResultImpl(
          session: currentSession,
          element: resolvedUnits.first.libraryElement,
          units: resolvedUnits,
        );

        if (isLibraryWithPriorityFile) {
          _resolvedLibraryCache[library.file.path] = libraryResult;
        }

        // getResolvedLibrary()
        _requestedLibraries.completeAll(library.file.path, libraryResult);

        // Return the result, full or partial.
        _logger.writeln('Computed new analysis result.');
        // return result;
      } catch (exception, stackTrace) {
        var contextKey =
            _storeExceptionContext(path, library, exception, stackTrace);
        _reportException(path, exception, stackTrace, contextKey);

        // Complete all related requests with an error.
        void completeWithError<T>(List<Completer<T>>? completers) {
          if (completers != null) {
            for (var completer in completers) {
              completer.completeError(exception, stackTrace);
            }
          }
        }

        // TODO(scheglov): write tests
        for (var file in library.files) {
          // getResolvedUnit()
          completeWithError(
            _requestedFiles.remove(file.path),
          );
          // getErrors()
          completeWithError(
            _errorsRequestedFiles.remove(file.path),
          );
        }
        // getResolvedLibrary()
        completeWithError(
          _requestedLibraries.remove(library.file.path),
        );
        _clearLibraryContextAfterException();
      }
    });
  }

  void _applyPendingFileChanges() {
    var accumulatedAffected = <String>{};
    for (var fileChange in _pendingFileChanges) {
      var path = fileChange.path;
      _removePotentiallyAffectedLibraries(accumulatedAffected, path);
      switch (fileChange.kind) {
        case _FileChangeKind.add:
          _fileTracker.addFile(path);
        case _FileChangeKind.change:
          _fileTracker.changeFile(path);
        case _FileChangeKind.remove:
          _fileTracker.removeFile(path);
          // TODO(scheglov): We have to do this because we discard files.
          // But this is not right, we need to handle removing better.
          clearLibraryContext();
      }
    }
    _pendingFileChanges.clear();

    // Read files, so that synchronous methods also see new content.
    while (_fileTracker.verifyChangedFilesIfNeeded()) {}

    if (_pendingFileChangesCompleters.isNotEmpty) {
      var completers = _pendingFileChangesCompleters.toList();
      _pendingFileChangesCompleters.clear();
      for (var completer in completers) {
        completer.complete(
          accumulatedAffected.toList(),
        );
      }
    }
  }

  /// There was an exception during a file analysis, we don't know why.
  /// But it might have been caused by an inconsistency of files state, and
  /// the library context state. Reset the library context, and hope that
  /// we will solve the inconsistency while loading / building summaries.
  void _clearLibraryContextAfterException() {
    clearLibraryContext();
    _priorityResults.clear();
    _resolvedLibraryCache.clear();
  }

  ErrorsResultImpl _createErrorsResultFromBytes(
    FileState file,
    LibraryFileKind library,
    Uint8List bytes,
  ) {
    _scheduler.eventsController.add(
      events.GetErrorsFromBytes(
        file: file,
        library: library,
      ),
    );
    var unit = AnalysisDriverResolvedUnit.fromBuffer(bytes);
    var errors = _getErrorsFromSerialized(file, unit.errors);
    _updateHasErrorOrWarningFlag(file, errors);
    var result = _createErrorsResultImpl(
      file: file,
      errors: errors,
    );
    return result;
  }

  ErrorsResultImpl _createErrorsResultImpl({
    required FileState file,
    required List<AnalysisError> errors,
  }) {
    return ErrorsResultImpl(
      session: currentSession,
      file: file.resource,
      content: file.content,
      lineInfo: file.lineInfo,
      uri: file.uri,
      isAugmentation: file.kind is AugmentationFileKind,
      isLibrary: file.kind is LibraryFileKind,
      isMacroAugmentation: file.isMacroAugmentation,
      isPart: file.kind is PartFileKind,
      errors: errors,
      analysisOptions: file.analysisOptions,
    );
  }

  /// Creates new [FileSystemState] and [FileTracker] objects.
  ///
  /// This is used both on initial construction and whenever the configuration
  /// changes.
  void _createFileTracker() {
    _fillSalt();

    var featureSetProvider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: _resourceProvider,
      packages: _packages,
    );

    _fsState = FileSystemState(
      _logger,
      _byteStore,
      _resourceProvider,
      name,
      sourceFactory,
      analysisContext?.contextRoot.workspace,
      declaredVariables,
      _saltForUnlinked,
      _saltForElements,
      featureSetProvider,
      analysisOptionsMap,
      fileContentStrategy: _fileContentStrategy,
      unlinkedUnitStore: _unlinkedUnitStore,
      prefetchFiles: null,
      isGenerated: (_) => false,
      onNewFile: _onNewFile,
      testData: testView?.fileSystem,
    );
    _fileTracker = FileTracker(_logger, _fsState, _fileContentStrategy);
  }

  ResolvedUnitResultImpl _createResolvedUnitImpl({
    required FileState file,
    required UnitAnalysisResult unitResult,
  }) {
    return ResolvedUnitResultImpl(
      session: currentSession,
      fileState: file,
      unit: unitResult.unit,
      errors: unitResult.errors,
    );
  }

  /// When we look at a part that has a `part of name;` directive, we
  /// usually don't know the library (in contrast to `part of uri;`).
  /// So, we have no choice than to resolve this part as its own library.
  ///
  /// But parts of `dart:xyz` libraries are special. The reason is that
  /// `dart:core` is always implicitly imported. So, when we start building
  /// the library cycle of such "part as a library", we discover `dart:core`,
  /// and see that it contains our part. So, we don't add it as a library on
  /// its own. But have already committed that it is a library. This causes
  /// an exception in `LinkedElementFactory`.
  ///
  /// The current workaround for this is to discover `dart:core` before any
  /// analysis.
  void _discoverDartCore() {
    if (_hasDartCoreDiscovered) {
      return;
    }
    _hasDartCoreDiscovered = true;

    var dartCoreUri = uriCache.parse('dart:core');
    var dartCoreResolution = _fsState.getFileForUri(dartCoreUri);
    if (dartCoreResolution is UriResolutionFile) {
      var kind = dartCoreResolution.file.kind;
      if (kind is LibraryFileKind) {
        kind.discoverReferencedFiles();
      }
    }
  }

  void _discoverLibraries() {
    if (_hasLibrariesDiscovered) {
      return;
    }
    _hasLibrariesDiscovered = true;

    for (var path in _fileTracker.addedFiles) {
      _fsState.getFileForPath(path);
    }
  }

  Future<void> _ensureMacroGeneratedFiles() async {
    for (var file in knownFiles.toList()) {
      if (file.kind case LibraryFileKind libraryKind) {
        var libraryCycle = libraryKind.libraryCycle;
        if (libraryCycle.importsMacroClass) {
          if (!libraryCycle.hasMacroFilesCreated) {
            libraryCycle.hasMacroFilesCreated = true;
            // We create macro-generated FileState(s) when load bundles.
            await libraryContext.load(
              targetLibrary: libraryKind,
              performance: OperationPerformanceImpl('<root>'),
            );
          }
        }
      }
    }
  }

  void _fillSalt() {
    _fillSaltForUnlinked();
    _fillSaltForElements();
    _fillSaltForResolution();
  }

  void _fillSaltForElements() {
    var buffer = ApiSignature();
    buffer.addInt(DATA_VERSION);
    _addDeclaredVariablesToSignature(buffer);
    _saltForElements = buffer.toUint32List();
  }

  void _fillSaltForResolution() {
    var buffer = ApiSignature();
    buffer.addInt(DATA_VERSION);
    buffer.addBool(enableIndex);
    buffer.addBool(enableDebugResolutionMarkers);
    _addDeclaredVariablesToSignature(buffer);

    var workspace = analysisContext?.contextRoot.workspace;
    workspace?.contributeToResolutionSalt(buffer);

    _saltForResolution = buffer.toUint32List();
  }

  void _fillSaltForUnlinked() {
    var buffer = ApiSignature();
    buffer.addInt(DATA_VERSION);
    buffer.addBool(enableIndex);

    _saltForUnlinked = buffer.toUint32List();
  }

  Future<void> _getErrors(String path) async {
    var file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    var kind = file.kind;
    var library = kind.library ?? kind.asLibrary;

    // Prepare the signature and key.
    var signature = _getResolvedUnitSignature(library, file);
    var key = _getResolvedUnitKey(signature);

    var bytes = _byteStore.get(key);
    if (bytes != null) {
      var result = _createErrorsResultFromBytes(file, library, bytes);
      _errorsRequestedFiles.completeAll(path, result);
      return;
    }

    await _analyzeFile(path);
  }

  /// Return [AnalysisError]s for the given [serialized] errors.
  List<AnalysisError> _getErrorsFromSerialized(
      FileState file, List<AnalysisDriverUnitError> serialized) {
    List<AnalysisError> errors = <AnalysisError>[];
    for (AnalysisDriverUnitError error in serialized) {
      var analysisError = ErrorEncoding.decode(file.source, error);
      if (analysisError != null) {
        errors.add(analysisError);
      }
    }
    return errors;
  }

  Future<void> _getFilesDefiningClassMemberName(
    _GetFilesDefiningClassMemberNameRequest request,
  ) async {
    await _ensureMacroGeneratedFiles();

    var result = <FileState>[];
    for (var file in knownFiles) {
      if (file.definedClassMemberNames.contains(request.name)) {
        result.add(file);
      }
    }
    request.completer.complete(result);
  }

  Future<void> _getFilesReferencingName(
    _GetFilesReferencingNameRequest request,
  ) async {
    await _ensureMacroGeneratedFiles();

    var result = <FileState>[];
    for (var file in knownFiles) {
      if (file.referencedNames.contains(request.name)) {
        result.add(file);
      }
    }
    request.completer.complete(result);
  }

  Future<void> _getIndex(String path) async {
    var file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    var kind = file.kind;
    var library = kind.library ?? kind.asLibrary;

    // Prepare the signature and key.
    var signature = _getResolvedUnitSignature(library, file);
    var key = _getResolvedUnitKey(signature);

    var bytes = _byteStore.get(key);
    if (bytes != null) {
      var unit = AnalysisDriverResolvedUnit.fromBuffer(bytes);
      _indexRequestedFiles.completeAll(path, unit.index!);
      return;
    }

    await _analyzeFile(path);
  }

  /// Completes the [getResolvedLibrary] request.
  Future<void> _getResolvedLibrary(String path) async {
    var file = _fsState.getFileForPath(path);
    var kind = file.kind;
    switch (kind) {
      case LibraryFileKind():
        break;
      case AugmentationFileKind():
        _requestedLibraries.completeAll(
          path,
          NotLibraryButAugmentationResult(),
        );
        return;
      case PartFileKind():
        _requestedLibraries.completeAll(
          path,
          NotLibraryButPartResult(),
        );
        return;
      default:
        throw UnimplementedError('(${kind.runtimeType}) $kind');
    }

    if (_resolvedLibraryCache[path] case var cached?) {
      _requestedLibraries.completeAll(path, cached);
      return;
    }

    await _analyzeFile(path);
  }

  /// Return the key to store fully resolved results for the [signature].
  String _getResolvedUnitKey(String signature) {
    return '$signature.resolved';
  }

  /// Return the signature that identifies fully resolved results for the [file]
  /// in the [library], e.g. element model, errors, index, etc.
  String _getResolvedUnitSignature(LibraryFileKind library, FileState file) {
    ApiSignature signature = ApiSignature();
    signature.addUint32List(_saltForResolution);
    if (file.workspacePackage is PubPackage) {
      signature.addString(
          (file.workspacePackage as PubPackage).pubspecContent ?? '');
    }
    signature.addString(library.file.uriStr);
    signature.addString(library.libraryCycle.apiSignature);
    signature.addUint32List(library.file.analysisOptions.signature);
    signature.addString(file.uriStr);
    signature.addString(file.contentHash);
    return signature.toHex();
  }

  Future<void> _getUnitElement(String path) async {
    FileState file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    var kind = file.kind;
    var library = kind.library ?? kind.asLibrary;

    await libraryContext.load(
      targetLibrary: library,
      performance: OperationPerformanceImpl('<root>'),
    );

    var element = libraryContext.computeUnitElement(library, file);
    var result = UnitElementResultImpl(
      session: currentSession,
      fileState: file,
      element: element,
    );

    _unitElementRequestedFiles.completeAll(path, result);
  }

  bool _hasLibraryByUri(String uriStr) {
    var uri = uriCache.parse(uriStr);
    var fileOr = _fsState.getFileForUri(uri);
    return switch (fileOr) {
      null => false,
      UriResolutionFile(:var file) => file.exists,
      UriResolutionExternalLibrary() => true,
    };
  }

  bool _isAbsolutePath(String path) {
    return _resourceProvider.pathContext.isAbsolute(path);
  }

  bool _isLibraryWithPriorityFile(LibraryFileKind library) {
    for (var file in library.files) {
      if (_priorityFiles.contains(file.path)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _maybeDispose() async {
    if (_disposeRequests.isNotEmpty) {
      _scheduler.remove(this);
      clearLibraryContext();

      for (var completer in _disposeRequests.toList()) {
        completer.complete();
      }
    }
  }

  /// We detected that one of the required `dart` libraries is missing.
  /// Return the empty analysis result with the error.
  ErrorsResultImpl _newMissingDartLibraryResult(
      FileState file, String missingUri) {
    // TODO(scheglov): Find a better way to report this.
    return ErrorsResultImpl(
      session: currentSession,
      file: file.resource,
      content: file.content,
      lineInfo: file.lineInfo,
      uri: file.uri,
      isAugmentation: file.kind is AugmentationFileKind,
      isLibrary: file.kind is LibraryFileKind,
      isMacroAugmentation: file.isMacroAugmentation,
      isPart: file.kind is PartFileKind,
      errors: [
        AnalysisError.tmp(
          source: file.source,
          offset: 0,
          length: 0,
          errorCode: CompileTimeErrorCode.MISSING_DART_LIBRARY,
          arguments: [missingUri],
        ),
      ],
      analysisOptions: file.analysisOptions,
    );
  }

  void _onNewFile(FileState file) {
    var ownedFiles = this.ownedFiles;
    if (ownedFiles != null) {
      if (addedFiles.contains(file.path)) {
        ownedFiles.addAdded(file.uri, this);
      } else {
        ownedFiles.addKnown(file.uri, this);
      }
    }
  }

  Future<void> _produceErrors(String path) async {
    var file = _fsState.getFileForPath(path);

    // Prepare the library - the file itself, or the known library.
    var kind = file.kind;
    var library = kind.library ?? kind.asLibrary;

    // Errors are based on elements, so load them.
    await libraryContext.load(
      targetLibrary: library,
      performance: OperationPerformanceImpl('<root>'),
    );

    // Check if we have cached errors for all library files.
    List<(FileState, String, Uint8List)>? forAllFiles = [];
    for (var file in library.files) {
      // If the file is priority, we need the resolved unit.
      // So, the cached errors is not enough.
      if (priorityFiles.contains(file.path)) {
        forAllFiles = null;
        break;
      }

      var signature = _getResolvedUnitSignature(library, file);
      var key = _getResolvedUnitKey(signature);

      var bytes = _byteStore.get(key);
      if (bytes == null) {
        forAllFiles = null;
        break;
      }

      // Will not be `null` here.
      forAllFiles?.add((file, signature, bytes));
    }

    // If we have results for all library files, produce them.
    if (forAllFiles != null) {
      for (var (file, signature, bytes) in forAllFiles) {
        // We have the result for this file.
        _fileTracker.fileWasAnalyzed(file.path);

        // Don't produce the result if the signature is the same.
        if (_lastProducedSignatures[file.path] == signature) {
          continue;
        }

        // Produce the result from bytes.
        var result = _createErrorsResultFromBytes(file, library, bytes);
        _lastProducedSignatures[file.path] = signature;
        _errorsRequestedFiles.completeAll(file.path, result);
        _scheduler.eventsController.add(result);
      }
      // We produced all results for the library.
      return;
    }

    // Analyze, will produce results into the stream.
    await _analyzeFile(path);
  }

  void _removePotentiallyAffectedLibraries(
    Set<String> accumulatedAffected,
    String path,
  ) {
    var affected = <FileState>{};
    _fsState.collectAffected(path, affected);

    var removedKeys = <String>{};
    _libraryContext?.remove(affected, removedKeys);

    // TODO(scheglov): Eventually list of `LibraryOrAugmentationFileKind`.
    for (var file in affected) {
      var kind = file.kind;
      if (kind is LibraryFileKind) {
        kind.invalidateLibraryCycle();
      }
      accumulatedAffected.add(file.path);
    }

    _libraryContext?.elementFactory.replaceAnalysisSession(
      AnalysisSessionImpl(this),
    );
  }

  void _reportException(String path, Object exception, StackTrace stackTrace,
      String? contextKey) {
    CaughtException caught = CaughtException(exception, stackTrace);

    var fileContentMap = <String, String>{};

    try {
      var file = _fsState.getFileForPath(path);
      var fileKind = file.kind;
      var libraryKind = fileKind.library;
      if (libraryKind != null) {
        for (var file in libraryKind.files) {
          fileContentMap[file.path] = file.content;
        }
      } else {
        var file = fileKind.file;
        fileContentMap[file.path] = file.content;
      }
    } catch (_) {
      // We might get an exception while parsing to access parts.
      // Ignore, continue with the exception that we are reporting now.
    }

    if (exception is CaughtExceptionWithFiles) {
      for (var nested in exception.fileContentMap.entries) {
        fileContentMap['nested-${nested.key}'] = nested.value;
      }
    }

    _exceptionController.add(
      ExceptionResult(
        filePath: path,
        fileContentMap: fileContentMap,
        exception: caught,
        contextKey: contextKey,
      ),
    );
  }

  Future<ResolvedForCompletionResultImpl?> _resolveForCompletion(
    _ResolveForCompletionRequest request,
  ) async {
    return request.performance.runAsync('body', (performance) async {
      var path = request.path;
      if (!_isAbsolutePath(path)) {
        return null;
      }

      if (!_fsState.hasUri(path)) {
        return null;
      }

      var file = _fsState.getFileForPath(path);

      // Prepare the library - the file itself, or the known library.
      var kind = file.kind;
      var library = kind.library ?? kind.asLibrary;

      await performance.runAsync(
        'libraryContext',
        (performance) async {
          await libraryContext.load(
            targetLibrary: library,
            performance: performance,
          );
        },
      );
      var unitElement = libraryContext.computeUnitElement(library, file);
      var analysisOptions = libraryContext.analysisContext
          .getAnalysisOptionsForFile(file.resource);
      var libraryElement =
          libraryContext.elementFactory.libraryOfUri2(library.file.uri);
      var typeSystemOperations = TypeSystemOperations(libraryElement.typeSystem,
          strictCasts: analysisOptions.strictCasts);

      var analysisResult = LibraryAnalyzer(
        analysisOptions,
        declaredVariables,
        libraryElement,
        libraryContext.elementFactory.analysisSession.inheritanceManager,
        library,
        testingData: testingData,
        typeSystemOperations: typeSystemOperations,
      ).analyzeForCompletion(
        file: file,
        offset: request.offset,
        unitElement: unitElement,
        performance: performance,
      );

      return ResolvedForCompletionResultImpl(
        analysisSession: currentSession,
        fileState: file,
        path: path,
        uri: file.uri,
        exists: file.exists,
        content: file.content,
        lineInfo: file.lineInfo,
        parsedUnit: analysisResult.parsedUnit,
        unitElement: unitElement,
        resolvedNodes: analysisResult.resolvedNodes,
      );
    });
  }

  String? _storeExceptionContext(String path, LibraryFileKind library,
      Object exception, StackTrace stackTrace) {
    if (allowedNumberOfContextsToWrite <= 0) {
      return null;
    } else {
      allowedNumberOfContextsToWrite--;
    }
    try {
      var contextFiles = library.files
          .map((file) => AnalysisDriverExceptionFileBuilder(
              path: file.path, content: file.content))
          .toList();
      contextFiles.sort((a, b) => a.path.compareTo(b.path));
      AnalysisDriverExceptionContextBuilder contextBuilder =
          AnalysisDriverExceptionContextBuilder(
              path: path,
              exception: exception.toString(),
              stackTrace: stackTrace.toString(),
              files: contextFiles);
      var bytes = contextBuilder.toBuffer();

      String twoDigits(int n) {
        if (n >= 10) return '$n';
        return '0$n';
      }

      String threeDigits(int n) {
        if (n >= 100) return '$n';
        if (n >= 10) return '0$n';
        return '00$n';
      }

      DateTime time = DateTime.now();
      String m = twoDigits(time.month);
      String d = twoDigits(time.day);
      String h = twoDigits(time.hour);
      String min = twoDigits(time.minute);
      String sec = twoDigits(time.second);
      String ms = threeDigits(time.millisecond);
      String key = 'exception_${time.year}$m${d}_$h$min${sec}_$ms';

      _byteStore.putGet(key, bytes);
      return key;
    } catch (_) {
      return null;
    }
  }

  /// The driver supports only absolute paths, this method is used to validate
  /// any input paths to prevent errors later.
  void _throwIfNotAbsolutePath(String path) {
    if (!_isAbsolutePath(path)) {
      throw ArgumentError('Only absolute paths are supported: $path');
    }
  }

  /// Given the list of [errors] for the [file], update the [file]'s
  /// [FileState.hasErrorOrWarning] flag.
  void _updateHasErrorOrWarningFlag(
      FileState file, List<AnalysisError> errors) {
    for (AnalysisError error in errors) {
      ErrorSeverity severity = error.errorCode.errorSeverity;
      if (severity == ErrorSeverity.ERROR) {
        file.hasErrorOrWarning = true;
        return;
      }
    }
    file.hasErrorOrWarning = false;
  }
}

/// Priorities of [AnalysisDriver] work. The farther a priority to the beginning
/// of the list, the earlier the corresponding [AnalysisDriver] should be asked
/// to perform work.
enum AnalysisDriverPriority {
  nothing,
  general,
  generalWithErrors,
  generalImportChanged,
  generalChanged,
  changedFiles,
  priority,
  interactive,
  completion
}

/// Instances of this class schedule work in multiple [AnalysisDriver]s so that
/// work with the highest priority is performed first.
class AnalysisDriverScheduler {
  /// Time interval in milliseconds before pumping the event queue.
  ///
  /// Relinquishing execution flow and running the event loop after every task
  /// has too much overhead. Instead we use a fixed length of time, so we can
  /// spend less time overall and still respond quickly enough.
  static const int _MS_BEFORE_PUMPING_EVENT_QUEUE = 2;

  /// Event queue pumping is required to allow IO and other asynchronous data
  /// processing while analysis is active. For example Analysis Server needs to
  /// be able to process `updateContent` or `setPriorityFiles` requests while
  /// background analysis is in progress.
  ///
  /// The number of pumpings is arbitrary, might be changed if we see that
  /// analysis or other data processing tasks are starving. Ideally we would
  /// need to run all asynchronous operations using a single global scheduler.
  static const int _NUMBER_OF_EVENT_QUEUE_PUMPINGS = 128;

  final PerformanceLog _logger;

  /// The object used to watch as analysis drivers are created and deleted.
  final DriverWatcher? driverWatcher;

  /// The controller for [events] stream.
  final StreamController<Object> eventsController = StreamController<Object>();

  /// The cached instance of [events] stream.
  late final Stream<Object> _events = eventsController.stream;

  final List<AnalysisDriver> _drivers = [];
  final Monitor _hasWork = Monitor();

  late final StatusSupport _statusSupport = StatusSupport(
    eventsController: eventsController,
  );

  bool _started = false;

  /// The optional worker that is invoked when its work priority is higher
  /// than work priorities in drivers.
  ///
  /// Don't use outside of Analyzer and Analysis Server.
  SchedulerWorker? outOfBandWorker;

  /// The operations performance accumulated so far.
  ///
  /// It is expected that the consumer of this performance operation will
  /// do analysis operations, take the instance to print and otherwise
  /// process, and reset this field with a new instance.
  OperationPerformanceImpl accumulatedPerformance =
      OperationPerformanceImpl('<scheduler>');

  AnalysisDriverScheduler(this._logger, {this.driverWatcher});

  /// The [Stream] that produces analysis results for all drivers, and status
  /// events.
  ///
  /// Note that the stream supports only one single subscriber.
  ///
  /// Analysis starts when the [AnalysisDriverScheduler] is started and the
  /// driver is added to it. The analysis state transitions to "working" and
  /// an analysis result is produced for every added file prior to the next time
  /// the analysis state transitions to "idle".
  ///
  /// [AnalysisStatusWorking] is produced every time when the current status
  /// is [AnalysisStatusIdle], and there is any work to do in any
  /// [AnalysisDriver]. This includes analysis of files passed to
  /// [AnalysisDriver.addFile], any asynchronous `getXyz()` requests, and
  /// [AnalysisDriver.changeFile].
  ///
  /// [AnalysisStatusIdle] is produced every time when there is no more work
  /// to do after [AnalysisStatusWorking].
  ///
  /// [ErrorsResult]s are produced for files passed to [AnalysisDriver.addFile]
  /// which are not in [AnalysisDriver.priorityFiles]. We can avoid analyzing
  /// a file, if there is already result for it in the [ByteStore].
  ///
  /// [ResolvedUnitResult]s are produced for every analyzed file. Currently
  /// to analyze a file of a library, the whole library is analyzed, all its
  /// files - the defining unit, augmentations, and parts.
  ///
  /// A file requires analysis if:
  /// 1. It was requested by [AnalysisDriver.getResolvedUnit] or
  ///    [AnalysisDriver.getResolvedLibrary], and not cached.
  /// 2. It was [AnalysisDriver.addFile], and either there is no result for it
  ///    in the [ByteStore], or it is in [AnalysisDriver.priorityFiles].
  Stream<Object> get events => _events;

  bool get isStarted => _started;

  /// Returns `true` if we are currently working on requests.
  bool get isWorking {
    return _statusSupport.currentStatus.isWorking;
  }

  /// Return `true` if there is a driver with a file to analyze.
  bool get _hasFilesToAnalyze {
    for (var driver in _drivers) {
      if (driver._hasFilesToAnalyze) {
        return true;
      }
    }
    return false;
  }

  /// Add the given [driver] and schedule it to perform its work.
  void add(AnalysisDriver driver) {
    _drivers.add(driver);
    _hasWork.notify();
    if (driver.analysisContext != null) {
      driverWatcher?.addedDriver(driver);
    }
  }

  /// Notifies the scheduler that there might be work to do.
  void notify() {
    _hasWork.notify();
    _statusSupport.transitionToWorking();
  }

  /// Remove the given [driver] from the scheduler, so that it will not be
  /// asked to perform any new work.
  void remove(AnalysisDriver driver) {
    driverWatcher?.removedDriver(driver);
    _drivers.remove(driver);
    _hasWork.notify();
  }

  /// Start the scheduler, so that any [AnalysisDriver] created before or
  /// after will be asked to perform work.
  void start() {
    if (_started) {
      throw StateError('The scheduler has already been started.');
    }
    _started = true;
    _run();
  }

  /// Return a future that will be completed the next time the status is idle.
  ///
  /// If the status is currently idle, the returned future will be signaled
  /// immediately.
  Future<void> waitForIdle() => _statusSupport.waitForIdle();

  /// Run infinitely analysis cycle, selecting the drivers with the highest
  /// priority first.
  Future<void> _run() async {
    // Give other microtasks the time to run before doing the analysis cycle.
    await null;
    Stopwatch timer = Stopwatch()..start();
    PerformanceLogSection? analysisSection;
    while (true) {
      // Pump the event queue.
      if (timer.elapsedMilliseconds > _MS_BEFORE_PUMPING_EVENT_QUEUE) {
        await _pumpEventQueue(_NUMBER_OF_EVENT_QUEUE_PUMPINGS);
        timer.reset();
      }

      await _hasWork.signal;

      for (var driver in _drivers.toList()) {
        await driver._maybeDispose();
      }

      for (var driver in _drivers) {
        driver._applyPendingFileChanges();
      }

      // Transition to working if there are files to analyze.
      if (_hasFilesToAnalyze) {
        _statusSupport.transitionToWorking();
        analysisSection ??= _logger.enter('Working');
      }

      // Find the driver with the highest priority.
      late AnalysisDriver bestDriver;
      AnalysisDriverPriority bestPriority = AnalysisDriverPriority.nothing;
      for (var driver in _drivers) {
        AnalysisDriverPriority priority = driver.workPriority;
        if (priority.index > bestPriority.index) {
          bestDriver = driver;
          bestPriority = priority;
        }
      }

      if (outOfBandWorker != null) {
        var workerPriority = outOfBandWorker!.workPriority;
        if (workerPriority != AnalysisDriverPriority.nothing) {
          if (workerPriority.index > bestPriority.index) {
            await outOfBandWorker!.performWork();
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

  /// Returns a [Future] that completes after performing [times] pumpings of
  /// the event queue.
  static Future _pumpEventQueue(int times) {
    if (times == 0) {
      return Future.value();
    }
    return Future.delayed(Duration.zero, () => _pumpEventQueue(times - 1));
  }
}

class AnalysisDriverTestView {
  final fileSystem = FileSystemTestData();

  late final libraryContext = LibraryContextTestData(
    fileSystemTestData: fileSystem,
  );

  late final AnalysisDriver driver;

  int numOfAnalyzedLibraries = 0;

  FileTracker get fileTracker => driver._fileTracker;

  Set<String> get loadedLibraryUriSet {
    var elementFactory = driver.libraryContext.elementFactory;
    var libraryReferences = elementFactory.rootReference.children;
    return libraryReferences.map((e) => e.name).toSet();
  }

  Map<String, ResolvedUnitResult> get priorityResults {
    return driver._priorityResults;
  }
}

/// An object that watches for the creation and removal of analysis drivers.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DriverWatcher {
  /// The context manager has just added the given analysis [driver]. This method
  /// must be called before the driver has been allowed to perform any analysis.
  void addedDriver(AnalysisDriver driver);

  /// The context manager has just removed the given analysis [driver].
  void removedDriver(AnalysisDriver driver);
}

class ErrorEncoding {
  static AnalysisError? decode(
    Source source,
    AnalysisDriverUnitError error,
  ) {
    String errorName = error.uniqueName;
    ErrorCode? errorCode =
        errorCodeByUniqueName(errorName) ?? _lintCodeByUniqueName(errorName);
    if (errorCode == null) {
      // This could fail because the error code is no longer defined, or, in
      // the case of a lint rule, if the lint rule has been disabled since the
      // errors were written.
      AnalysisEngine.instance.instrumentationService
          .logError('No error code for "$error" in "$source"');
      return null;
    }

    var contextMessages = <DiagnosticMessageImpl>[];
    for (var message in error.contextMessages) {
      var url = message.url;
      contextMessages.add(
        DiagnosticMessageImpl(
          filePath: message.filePath,
          length: message.length,
          message: message.message,
          offset: message.offset,
          url: url.isEmpty ? null : url,
        ),
      );
    }

    return AnalysisError.forValues(
      source: source,
      offset: error.offset,
      length: error.length,
      errorCode: errorCode,
      message: error.message,
      correctionMessage: error.correction.isEmpty ? null : error.correction,
      contextMessages: contextMessages,
    );
  }

  static AnalysisDriverUnitErrorBuilder encode(AnalysisError error) {
    var contextMessages = <DiagnosticMessageBuilder>[];
    for (var message in error.contextMessages) {
      contextMessages.add(
        DiagnosticMessageBuilder(
          filePath: message.filePath,
          length: message.length,
          message: message.messageText(includeUrl: false),
          offset: message.offset,
          url: message.url,
        ),
      );
    }

    return AnalysisDriverUnitErrorBuilder(
      offset: error.offset,
      length: error.length,
      uniqueName: error.errorCode.uniqueName,
      message: error.message,
      correction: error.correction ?? '',
      contextMessages: contextMessages,
    );
  }

  /// Return the lint code with the given [errorName], or `null` if there is no
  /// lint registered with that name.
  static ErrorCode? _lintCodeByUniqueName(String errorName) {
    return linter.Registry.ruleRegistry.codeForUniqueName(errorName);
  }
}

/// Exception that happened during analysis.
class ExceptionResult {
  /// The path of the library being analyzed when the [exception] happened.
  ///
  /// Absolute and normalized.
  final String filePath;

  /// The content of the library and its parts.
  final Map<String, String> fileContentMap;

  /// The exception during analysis of the file with the [filePath].
  final CaughtException exception;

  /// If the exception happened during a file analysis, and the context in which
  /// the exception happened was stored, this field is the key of the context
  /// in the byte store. May be `null` if the context is unknown, the maximum
  /// number of context to store was reached, etc.
  final String? contextKey;

  ExceptionResult({
    required this.filePath,
    required this.fileContentMap,
    required this.exception,
    required this.contextKey,
  });
}

/// Container that keeps track of file owners.
class OwnedFiles {
  /// Key: the absolute file URI.
  /// Value: the driver to which the file is added.
  final Map<Uri, AnalysisDriver> addedFiles = {};

  /// Key: the absolute file URI.
  /// Value: a driver in which this file is available via dependencies.
  /// This map does not contain any files that are in [addedFiles].
  final Map<Uri, AnalysisDriver> knownFiles = {};

  void addAdded(Uri uri, AnalysisDriver analysisDriver) {
    addedFiles[uri] ??= analysisDriver;
    knownFiles.remove(uri);
  }

  void addKnown(Uri uri, AnalysisDriver analysisDriver) {
    if (!addedFiles.containsKey(uri)) {
      knownFiles[uri] = analysisDriver;
    }
  }
}

/// Worker in [AnalysisDriverScheduler].
abstract class SchedulerWorker {
  /// Return the priority of work that this worker needs to perform.
  AnalysisDriverPriority get workPriority;

  /// Perform a single chunk of work.
  Future<void> performWork();
}

class _FileChange {
  final String path;
  final _FileChangeKind kind;

  _FileChange(this.path, this.kind);

  @override
  String toString() {
    return '[path: $path][kind: $kind]';
  }
}

enum _FileChangeKind { add, change, remove }

class _GetFilesDefiningClassMemberNameRequest {
  final String name;
  final completer = Completer<List<FileState>>();

  _GetFilesDefiningClassMemberNameRequest(this.name);
}

class _GetFilesReferencingNameRequest {
  final String name;
  final completer = Completer<List<FileState>>();

  _GetFilesReferencingNameRequest(this.name);
}

class _ResolveForCompletionRequest {
  final String path;
  final int offset;
  final OperationPerformanceImpl performance;
  final Completer<ResolvedForCompletionResultImpl?> completer = Completer();

  _ResolveForCompletionRequest({
    required this.path,
    required this.offset,
    required this.performance,
  });
}

extension<K, V> on Map<K, List<Completer<V>>> {
  void completeAll(K key, V value) {
    remove(key)?.completeAll(value);
  }
}

extension FileExtension on File {
  File? get libraryForMacro {
    if (path.removeSuffix('.macro.dart') case var noExtPath?) {
      var libraryPath = '$noExtPath.dart';
      return provider.getFile(libraryPath);
    }
    return null;
  }

  File? get macroForLibrary {
    if (path.removeSuffix('.dart') case var noExtPath?) {
      var libraryPath = '$noExtPath.macro.dart';
      return provider.getFile(libraryPath);
    }
    return null;
  }
}
