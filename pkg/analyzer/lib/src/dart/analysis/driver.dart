// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show CompilationUnitElement;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions, ChangeSet;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/task/dart.dart' show COMPILATION_UNIT_ELEMENT;
import 'package:analyzer/task/dart.dart' show LibrarySpecificUnit;

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
 *
 * TODO(scheglov) Clean up the list of implicitly analyzed files.
 *
 * TODO(scheglov) Handle not existing 'dart:x' URIs (while user is typing).
 */
class AnalysisDriver {
  /**
   * The version of data format, should be incremented on every format change.
   */
  static const int DATA_VERSION = 9;

  /**
   * The name of the driver, e.g. the name of the folder.
   */
  String name;

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
   * This [ContentCache] is consulted for a file content before reading
   * the content from the file.
   */
  final FileContentOverlay _contentOverlay;

  /**
   * The [SourceFactory] is used to resolve URIs to paths and restore URIs
   * from file paths.
   */
  final SourceFactory sourceFactory;

  /**
   * The analysis options to analyze with.
   */
  final AnalysisOptions analysisOptions;

  /**
   * The salt to mix into all hashes used as keys for serialized data.
   */
  final Uint32List _salt =
      new Uint32List(1 + AnalysisOptions.crossContextOptionsLength);

  /**
   * The current file system state.
   */
  FileSystemState _fsState;

  /**
   * The combined unlinked and linked package for the SDK, extracted from
   * the given [_sourceFactory].
   */
  PackageBundle _sdkBundle;

  /**
   * The set of explicitly analyzed files.
   */
  final _explicitFiles = new LinkedHashSet<String>();

  /**
   * The set of priority files, that should be analyzed sooner.
   */
  final _priorityFiles = new LinkedHashSet<String>();

  /**
   * The mapping from the files for which analysis was requested using
   * [getResult] to the [Completer]s to report the result.
   */
  final _requestedFiles = <String, List<Completer<AnalysisResult>>>{};

  /**
   * The list of tasks to compute files referencing a name.
   */
  final _referencingNameTasks = <_FilesReferencingNameTask>[];

  /**
   * The mapping from the files for which the index was requested using
   * [getIndex] to the [Completer]s to report the result.
   */
  final _indexRequestedFiles = <String, List<Completer<IndexResult>>>{};

  /**
   * The set of files were reported as changed through [changeFile] and not
   * checked for actual changes yet.
   */
  final _changedFiles = new LinkedHashSet<String>();

  /**
   * The set of files that are currently scheduled for analysis.
   */
  final _filesToAnalyze = new LinkedHashSet<String>();

  /**
   * The mapping from the files for which analysis was requested using
   * [getResult], and which were found to be parts without known libraries,
   * to the [Completer]s to report the result.
   */
  final _requestedParts = <String, List<Completer<AnalysisResult>>>{};

  /**
   * The set of part files that are currently scheduled for analysis.
   */
  final _partsToAnalyze = new LinkedHashSet<String>();

  /**
   * The controller for the [results] stream.
   */
  final _resultController = new StreamController<AnalysisResult>();

  /**
   * The instance of the status helper.
   */
  final StatusSupport _statusSupport = new StatusSupport();

  /**
   * The instance of the [Search] helper.
   */
  Search _search;

  /**
   * Create a new instance of [AnalysisDriver].
   *
   * The given [SourceFactory] is cloned to ensure that it does not contain a
   * reference to a [AnalysisContext] in which it could have been used.
   */
  AnalysisDriver(
      this._scheduler,
      this._logger,
      this._resourceProvider,
      this._byteStore,
      this._contentOverlay,
      SourceFactory sourceFactory,
      this.analysisOptions)
      : sourceFactory = sourceFactory.clone() {
    _fillSalt();
    _sdkBundle = sourceFactory.dartSdk.getLinkedBundle();
    _fsState = new FileSystemState(
        _logger,
        _byteStore,
        _contentOverlay,
        _resourceProvider,
        sourceFactory,
        analysisOptions,
        _salt,
        _sdkBundle.apiSignature);
    _scheduler._add(this);
    _search = new Search(this);
  }

  /**
   * Return the set of files added to analysis using [addFile].
   */
  Set<String> get addedFiles => _explicitFiles;

  /**
   * Return the set of files that are known, i.e. added or used implicitly.
   */
  Set<String> get knownFiles => _fsState.knownFiles;

  /**
   * Set the list of files that the driver should try to analyze sooner.
   *
   * Every path in the list must be absolute and normalized.
   *
   * The driver will produce the results through the [results] stream. The
   * exact order in which results are produced is not defined, neither
   * between priority files, nor between priority and non-priority files.
   */
  void set priorityFiles(List<String> priorityPaths) {
    _priorityFiles.clear();
    _priorityFiles.addAll(priorityPaths);
    _statusSupport.transitionToAnalyzing();
    _scheduler._notify(this);
  }

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
  Stream<AnalysisResult> get results => _resultController.stream;

  /**
   * Return the search support for the driver.
   */
  Search get search => _search;

  /**
   * Return the stream that produces [AnalysisStatus] events.
   */
  Stream<AnalysisStatus> get status => _statusSupport.stream;

  /**
   * Return the priority of work that the driver needs to perform.
   */
  AnalysisDriverPriority get _workPriority {
    if (_requestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_referencingNameTasks.isNotEmpty) {
      return AnalysisDriverPriority.referencingName;
    }
    if (_indexRequestedFiles.isNotEmpty) {
      return AnalysisDriverPriority.getIndex;
    }
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_filesToAnalyze.contains(path)) {
          return AnalysisDriverPriority.priority;
        }
      }
    }
    if (_filesToAnalyze.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    if (_changedFiles.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    if (_requestedParts.isNotEmpty || _partsToAnalyze.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    _statusSupport.transitionToIdle();
    return AnalysisDriverPriority.nothing;
  }

  /**
   * Add the file with the given [path] to the set of files to analyze.
   *
   * The [path] must be absolute and normalized.
   *
   * The results of analysis are eventually produced by the [results] stream.
   */
  void addFile(String path) {
    if (AnalysisEngine.isDartFileName(path)) {
      _explicitFiles.add(path);
      _filesToAnalyze.add(path);
    }
    _statusSupport.transitionToAnalyzing();
    _scheduler._notify(this);
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
    if (AnalysisEngine.isDartFileName(path)) {
      _changedFiles.add(path);
      if (_explicitFiles.contains(path)) {
        _filesToAnalyze.add(path);
      }
    }
    _statusSupport.transitionToAnalyzing();
    _scheduler._notify(this);
  }

  /**
   * Notify the driver that the client is going to stop using it.
   */
  void dispose() {
    _scheduler._remove(this);
  }

  /**
   * Return a [Future] that completes with the list of added files that
   * reference the given external [name].
   */
  Future<List<String>> getFilesReferencingName(String name) {
    var task = new _FilesReferencingNameTask(this, name);
    _referencingNameTasks.add(task);
    _statusSupport.transitionToAnalyzing();
    _scheduler._notify(this);
    return task.completer.future;
  }

  /**
   * Return a [Future] that completes with the [IndexResult] for the file with
   * the given [path].
   */
  Future<IndexResult> getIndex(String path) {
    if (AnalysisEngine.isDartFileName(path)) {
      var completer = new Completer<IndexResult>();
      _indexRequestedFiles
          .putIfAbsent(path, () => <Completer<IndexResult>>[])
          .add(completer);
      _statusSupport.transitionToAnalyzing();
      _scheduler._notify(this);
      return completer.future;
    }
    return new Future.value();
  }

  /**
   * Return a [Future] that completes with a [AnalysisResult] for the Dart
   * file with the given [path]. If the file is not a Dart file, the [Future]
   * completes with `null`.
   *
   * The [path] must be absolute and normalized.
   *
   * The [path] can be any file - explicitly or implicitly analyzed, or neither.
   *
   * Causes the analysis state to transition to "analyzing" (if it is not in
   * that state already), the driver will read the file and produce the analysis
   * result for it, which is consistent with the current file state (including
   * the new state of the file), prior to the next time the analysis state
   * transitions to "idle".
   */
  Future<AnalysisResult> getResult(String path) {
    if (AnalysisEngine.isDartFileName(path)) {
      var completer = new Completer<AnalysisResult>();
      _requestedFiles
          .putIfAbsent(path, () => <Completer<AnalysisResult>>[])
          .add(completer);
      _statusSupport.transitionToAnalyzing();
      _scheduler._notify(this);
      return completer.future;
    }
    return new Future.value();
  }

  /**
   * Return a [Future] that completes with a [ParseResult] for the file
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
  Future<ParseResult> parseFile(String path) async {
    FileState file = _fsState.getFileForPath(path);
    RecordingErrorListener listener = new RecordingErrorListener();
    CompilationUnit unit = file.parse(listener);
    return new ParseResult(file.path, file.uri, file.content, file.contentHash,
        unit.lineInfo, unit, listener.errors);
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
    _explicitFiles.remove(path);
    _filesToAnalyze.remove(path);
  }

  /**
   * TODO(scheglov) see [_addToStoreUnlinked]
   */
  void _addToStoreLinked(
      SummaryDataStore store, String uri, LinkedLibrary linked) {
    store.linkedMap[uri] = linked;
  }

  /**
   * TODO(scheglov) The existing [SummaryDataStore.addBundle] uses
   * [PackageBundle.unlinkedUnitUris] to add [PackageBundle.unlinkedUnits].
   * But we store unlinked bundles with the hash of the file content. This
   * means that when two files are the same, but have different URIs, we
   * add [UnlinkedUnit] with wrong URI.
   *
   * We need to clean this up.
   */
  void _addToStoreUnlinked(
      SummaryDataStore store, Uri uri, UnlinkedUnit unlinked) {
    String uriStr = uri.toString();
    store.unlinkedMap[uriStr] = unlinked;
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
   */
  AnalysisResult _computeAnalysisResult(String path,
      {bool withUnit: false, bool asIsIfPartWithoutLibrary: false}) {
    /**
     * If the [file] is a library, return the [file] itself.
     * If the [file] is a part, return a library it is known to be a part of.
     * If there is no such library, return `null`.
     */
    FileState getLibraryFile(FileState file) {
      FileState libraryFile = file.isPart ? file.library : file;
      if (libraryFile == null && asIsIfPartWithoutLibrary) {
        libraryFile = file;
      }
      return libraryFile;
    }

    // If we don't need the fully resolved unit, check for the cached result.
    if (!withUnit) {
      FileState file = _fsState.getFileForPath(path);

      // Prepare the library file - the file itself, or the known library.
      FileState libraryFile = getLibraryFile(file);
      if (libraryFile == null) {
        return null;
      }

      // Check for the cached result.
      String key = _getResolvedUnitKey(libraryFile, file);
      List<int> bytes = _byteStore.get(key);
      if (bytes != null) {
        return _getAnalysisResultFromBytes(libraryFile, file, bytes);
      }
    }

    // We need the fully resolved unit, or the result is not cached.
    return _logger.run('Compute analysis result for $path', () {
      FileState file = _verifyApiSignature(path);

      // Prepare the library file - the file itself, or the known library.
      FileState libraryFile = getLibraryFile(file);
      if (libraryFile == null) {
        return null;
      }

      _LibraryContext libraryContext = _createLibraryContext(libraryFile);
      AnalysisContext analysisContext = _createAnalysisContext(libraryContext);
      try {
        analysisContext.setContents(file.source, file.content);
        CompilationUnit resolvedUnit = analysisContext.resolveCompilationUnit2(
            file.source, libraryFile.source);
        List<AnalysisError> errors = analysisContext.computeErrors(file.source);
        AnalysisDriverUnitIndexBuilder index = indexUnit(resolvedUnit);

        // Store the result into the cache.
        List<int> bytes;
        {
          bytes = new AnalysisDriverResolvedUnitBuilder(
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
          String key = _getResolvedUnitKey(libraryFile, file);
          _byteStore.put(key, bytes);
        }

        // Return the result, full or partial.
        _logger.writeln('Computed new analysis result.');
        return _getAnalysisResultFromBytes(libraryFile, file, bytes,
            content: withUnit ? file.content : null,
            resolvedUnit: withUnit ? resolvedUnit : null);
      } finally {
        analysisContext.dispose();
      }
    });
  }

  IndexResult _computeIndexResult(String path) {
    AnalysisResult analysisResult = _computeAnalysisResult(path,
        withUnit: false, asIsIfPartWithoutLibrary: true);
    FileState libraryFile = analysisResult._libraryFile;
    FileState file = analysisResult._file;

    // Create the AnalysisContext to resynthesize elements in.
    _LibraryContext libraryContext = _createLibraryContext(libraryFile);
    AnalysisContext analysisContext = _createAnalysisContext(libraryContext);

    // Resynthesize the CompilationUnitElement in the context.
    CompilationUnitElement unitElement;
    try {
      unitElement = analysisContext.computeResult(
          new LibrarySpecificUnit(libraryFile.source, file.source),
          COMPILATION_UNIT_ELEMENT);
    } finally {
      analysisContext.dispose();
    }

    // Return as IndexResult.
    return new IndexResult(unitElement, analysisResult._index);
  }

  AnalysisContext _createAnalysisContext(_LibraryContext libraryContext) {
    AnalysisContextImpl analysisContext =
        AnalysisEngine.instance.createAnalysisContext();
    analysisContext.analysisOptions = analysisOptions;

    analysisContext.sourceFactory = sourceFactory.clone();
    analysisContext.resultProvider =
        new InputPackagesResultProvider(analysisContext, libraryContext.store);
    analysisContext
        .applyChanges(new ChangeSet()..addedSource(libraryContext.file.source));
    return analysisContext;
  }

  /**
   * Return the context in which the [library] should be analyzed it.
   */
  _LibraryContext _createLibraryContext(FileState library) {
    return _logger.run('Create library context', () {
      Map<String, FileState> libraries = <String, FileState>{};
      SummaryDataStore store = new SummaryDataStore(const <String>[]);
      store.addBundle(null, _sdkBundle);

      void appendLibraryFiles(FileState library) {
        // URIs with the 'dart:' scheme are served from the SDK bundle.
        if (library.uri.scheme == 'dart') {
          return null;
        }

        if (!libraries.containsKey(library.uriStr)) {
          libraries[library.uriStr] = library;

          // Append the defining unit.
          {
            UnlinkedUnit unlinked = library.unlinked;
            _addToStoreUnlinked(store, library.uri, unlinked);
          }

          // Append parts.
          for (FileState part in library.partedFiles) {
            UnlinkedUnit unlinked = part.unlinked;
            _addToStoreUnlinked(store, part.uri, unlinked);
          }

          // Append referenced libraries.
          library.importedFiles.forEach(appendLibraryFiles);
          library.exportedFiles.forEach(appendLibraryFiles);
        }
      }

      _logger.run('Append library files', () {
        return appendLibraryFiles(library);
      });

      Set<String> libraryUrisToLink = new Set<String>();
      _logger.run('Load linked bundles', () {
        for (FileState library in libraries.values) {
          String key = '${library.transitiveSignature}.linked';
          List<int> bytes = _byteStore.get(key);
          if (bytes != null) {
            LinkedLibrary linked = new LinkedLibrary.fromBuffer(bytes);
            _addToStoreLinked(store, library.uriStr, linked);
          } else {
            libraryUrisToLink.add(library.uriStr);
          }
        }
        int numOfLoaded = libraries.length - libraryUrisToLink.length;
        _logger.writeln('Loaded $numOfLoaded linked bundles.');
      });

      Map<String, LinkedLibraryBuilder> linkedLibraries = {};
      _logger.run('Link bundles', () {
        linkedLibraries = link(libraryUrisToLink, (String uri) {
          LinkedLibrary linkedLibrary = store.linkedMap[uri];
          return linkedLibrary;
        }, (String uri) {
          UnlinkedUnit unlinkedUnit = store.unlinkedMap[uri];
          return unlinkedUnit;
        }, (_) => null, analysisOptions.strongMode);
        _logger.writeln('Linked ${linkedLibraries.length} bundles.');
      });

      linkedLibraries.forEach((uri, linkedBuilder) {
        FileState library = libraries[uri];
        String key = '${library.transitiveSignature}.linked';
        List<int> bytes = linkedBuilder.toBuffer();
        LinkedLibrary linked = new LinkedLibrary.fromBuffer(bytes);
        _addToStoreLinked(store, uri, linked);
        _byteStore.put(key, bytes);
      });

      return new _LibraryContext(library, store);
    });
  }

  /**
   * Fill [_salt] with data.
   */
  void _fillSalt() {
    _salt[0] = DATA_VERSION;
    List<int> crossContextOptions = analysisOptions.encodeCrossContextOptions();
    assert(crossContextOptions.length ==
        AnalysisOptions.crossContextOptionsLength);
    for (int i = 0; i < crossContextOptions.length; i++) {
      _salt[i + 1] = crossContextOptions[i];
    }
  }

  /**
   * Load the [AnalysisResult] for the given [file] from the [bytes]. Set
   * optional [content] and [resolvedUnit].
   */
  AnalysisResult _getAnalysisResultFromBytes(
      FileState libraryFile, FileState file, List<int> bytes,
      {String content, CompilationUnit resolvedUnit}) {
    var unit = new AnalysisDriverResolvedUnit.fromBuffer(bytes);
    List<AnalysisError> errors = unit.errors.map((error) {
      String errorName = error.uniqueName;
      ErrorCode errorCode = errorCodeByUniqueName(errorName);
      if (errorCode == null) {
        throw new StateError('No ErrorCode for $errorName in $file');
      }
      return new AnalysisError.forValues(file.source, error.offset,
          error.length, errorCode, error.message, error.correction);
    }).toList();
    return new AnalysisResult(
        libraryFile,
        file,
        sourceFactory,
        file.path,
        file.uri,
        content,
        file.contentHash,
        file.lineInfo,
        resolvedUnit,
        errors,
        unit.index);
  }

  /**
   * Return the key to store fully resolved results for the [file] in the
   * [library] into the cache. Return `null` if the dependency signature is
   * not known yet.
   */
  String _getResolvedUnitKey(FileState library, FileState file) {
    ApiSignature signature = new ApiSignature();
    signature.addUint32List(_salt);
    signature.addString(library.transitiveSignature);
    signature.addString(file.contentHash);
    return '${signature.toHex()}.resolved';
  }

  /**
   * Perform a single chunk of work and produce [results].
   */
  Future<Null> _performWork() async {
    // Verify all changed files one at a time.
    if (_changedFiles.isNotEmpty) {
      String path = _removeFirst(_changedFiles);
      _verifyApiSignature(path);
      return;
    }

    // Analyze a requested file.
    if (_requestedFiles.isNotEmpty) {
      String path = _requestedFiles.keys.first;
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
      _filesToAnalyze.remove(path);
      _resultController.add(result);
      return;
    }

    // Process an index request.
    if (_indexRequestedFiles.isNotEmpty) {
      String path = _indexRequestedFiles.keys.first;
      IndexResult result = _computeIndexResult(path);
      _indexRequestedFiles.remove(path).forEach((completer) {
        completer.complete(result);
      });
      return;
    }

    // Compute files referencing a name.
    if (_referencingNameTasks.isNotEmpty) {
      _FilesReferencingNameTask task = _referencingNameTasks.first;
      bool isDone = await task.perform();
      if (isDone) {
        _referencingNameTasks.remove(task);
      }
      return;
    }

    // Analyze a priority file.
    if (_priorityFiles.isNotEmpty) {
      for (String path in _priorityFiles) {
        if (_filesToAnalyze.remove(path)) {
          AnalysisResult result = _computeAnalysisResult(path, withUnit: true);
          if (result == null) {
            _partsToAnalyze.add(path);
          } else {
            _resultController.add(result);
          }
          return;
        }
      }
    }

    // Analyze a general file.
    if (_filesToAnalyze.isNotEmpty) {
      String path = _removeFirst(_filesToAnalyze);
      AnalysisResult result = _computeAnalysisResult(path, withUnit: false);
      if (result == null) {
        _partsToAnalyze.add(path);
      } else {
        _resultController.add(result);
      }
      return;
    }

    // Analyze a requested part file.
    if (_requestedParts.isNotEmpty) {
      String path = _requestedParts.keys.first;
      AnalysisResult result = _computeAnalysisResult(path,
          withUnit: true, asIsIfPartWithoutLibrary: true);
      // Notify the completers.
      _requestedParts.remove(path).forEach((completer) {
        completer.complete(result);
      });
      // Remove from to be analyzed and produce it now.
      _filesToAnalyze.remove(path);
      _resultController.add(result);
      return;
    }

    // Analyze a general part.
    if (_partsToAnalyze.isNotEmpty) {
      String path = _removeFirst(_partsToAnalyze);
      AnalysisResult result = _computeAnalysisResult(path,
          withUnit: _priorityFiles.contains(path),
          asIsIfPartWithoutLibrary: true);
      _resultController.add(result);
      return;
    }
  }

  /**
   * Verify the API signature for the file with the given [path], and decide
   * which linked libraries should be invalidated, and files reanalyzed.
   */
  FileState _verifyApiSignature(String path) {
    return _logger.run('Verify API signature of $path', () {
      bool anyApiChanged = false;
      List<FileState> files = _fsState.getFilesForPath(path);
      for (FileState file in files) {
        bool apiChanged = file.refresh();
        if (apiChanged) {
          anyApiChanged = true;
        }
      }
      if (anyApiChanged) {
        _logger.writeln('API signatures mismatch found for $path');
        // TODO(scheglov) schedule analysis of only affected files
        _filesToAnalyze.addAll(_explicitFiles);
      }
      return files[0];
    });
  }

  /**
   * Remove and return the first item in the given [set].
   */
  static Object/*=T*/ _removeFirst/*<T>*/(LinkedHashSet<Object/*=T*/ > set) {
    Object/*=T*/ element = set.first;
    set.remove(element);
    return element;
  }
}

/**
 * Priorities of [AnalysisDriver] work. The farther a priority to the beginning
 * of the list, the earlier the corresponding [AnalysisDriver] should be asked
 * to perform work.
 */
enum AnalysisDriverPriority {
  nothing,
  general,
  priority,
  referencingName,
  getIndex,
  interactive
}

/**
 * Instances of this class schedule work in multiple [AnalysisDriver]s so that
 * work with the highest priority is performed first.
 */
class AnalysisDriverScheduler {
  final PerformanceLog _logger;
  final List<AnalysisDriver> _drivers = [];
  final Monitor _hasWork = new Monitor();
  final StatusSupport _statusSupport = new StatusSupport();

  bool _started = false;

  AnalysisDriverScheduler(this._logger);

  /**
   * Return the stream that produces [AnalysisStatus] events.
   */
  Stream<AnalysisStatus> get status => _statusSupport.stream;

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
   * Add the given [driver] and schedule it to perform its work.
   */
  void _add(AnalysisDriver driver) {
    _drivers.add(driver);
    _statusSupport.transitionToAnalyzing();
    _hasWork.notify();
  }

  /**
   * Notify that there is a change to the [driver], it it might need to
   * perform some work.
   */
  void _notify(AnalysisDriver driver) {
    _statusSupport.transitionToAnalyzing();
    _hasWork.notify();
  }

  /**
   * Remove the given [driver] from the scheduler, so that it will not be
   * asked to perform any new work.
   */
  void _remove(AnalysisDriver driver) {
    _drivers.remove(driver);
    _statusSupport.transitionToAnalyzing();
    _hasWork.notify();
  }

  /**
   * Run infinitely analysis cycle, selecting the drivers with the highest
   * priority first.
   */
  Future<Null> _run() async {
    PerformanceLogSection analysisSection;
    while (true) {
      // Pump the event queue to allow IO and other asynchronous data
      // processing while analysis is active. For example Analysis Server
      // needs to be able to process `updateContent` or `setPriorityFiles`
      // requests while background analysis is in progress.
      //
      // The number of pumpings is arbitrary, might be changed if we see that
      // analysis or other data processing tasks are starving. Ideally we
      // would need to be able to set priority of (continuous) asynchronous
      // tasks.
      await _pumpEventQueue(128);

      await _hasWork.signal;

      if (analysisSection == null) {
        analysisSection = _logger.enter('Analyzing');
      }

      // Find the driver with the highest priority.
      AnalysisDriver bestDriver;
      AnalysisDriverPriority bestPriority = AnalysisDriverPriority.nothing;
      for (AnalysisDriver driver in _drivers) {
        AnalysisDriverPriority priority = driver._workPriority;
        if (bestPriority == null || priority.index > bestPriority.index) {
          bestDriver = driver;
          bestPriority = priority;
        }
      }

      // Continue to sleep if no work to do.
      if (bestPriority == AnalysisDriverPriority.nothing) {
        analysisSection.exit();
        analysisSection = null;
        _statusSupport.transitionToIdle();
        continue;
      }

      // Ask the driver to perform a chunk of work.
      await bestDriver._performWork();

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
    return new Future.delayed(Duration.ZERO, () => _pumpEventQueue(times - 1));
  }
}

/**
 * The result of analyzing of a single file.
 *
 * These results are self-consistent, i.e. [content], [contentHash], the
 * resolved [unit] correspond to each other. All referenced elements, even
 * external ones, are also self-consistent. But none of the results is
 * guaranteed to be consistent with the state of the files.
 *
 * Every result is independent, and is not guaranteed to be consistent with
 * any previously returned result, even inside of the same library.
 */
class AnalysisResult {
  final FileState _libraryFile;
  final FileState _file;

  /**
   * The [SourceFactory] with which the file was analyzed.
   */
  final SourceFactory sourceFactory;

  /**
   * The path of the analysed file, absolute and normalized.
   */
  final String path;

  /**
   * The URI of the file that corresponded to the [path] in the used
   * [SourceFactory] at some point. Is it not guaranteed to be still consistent
   * to the [path], and provided as FYI.
   */
  final Uri uri;

  /**
   * The content of the file that was scanned, parsed and resolved.
   */
  final String content;

  /**
   * The MD5 hash of the [content].
   */
  final String contentHash;

  /**
   * Information about lines in the [content].
   */
  final LineInfo lineInfo;

  /**
   * The fully resolved compilation unit for the [content].
   */
  final CompilationUnit unit;

  /**
   * The full list of computed analysis errors, both syntactic and semantic.
   */
  final List<AnalysisError> errors;

  /**
   * The index of the unit.
   */
  final AnalysisDriverUnitIndex _index;

  AnalysisResult(
      this._libraryFile,
      this._file,
      this.sourceFactory,
      this.path,
      this.uri,
      this.content,
      this.contentHash,
      this.lineInfo,
      this.unit,
      this.errors,
      this._index);
}

/**
 * The result of indexing of a single file.
 */
class IndexResult {
  /**
   * The element of the file.
   */
  final CompilationUnitElement unitElement;

  /**
   * The index of the file.
   */
  final AnalysisDriverUnitIndex index;

  IndexResult(this.unitElement, this.index);
}

/**
 * The result of parsing of a single file.
 *
 * These results are self-consistent, i.e. [content], [contentHash], the
 * resolved [unit] correspond to each other. But none of the results is
 * guaranteed to be consistent with the state of the files.
 */
class ParseResult {
  /**
   * The path of the parsed file, absolute and normalized.
   */
  final String path;

  /**
   * The URI of the file that corresponded to the [path].
   */
  final Uri uri;

  /**
   * The content of the file that was scanned and parsed.
   */
  final String content;

  /**
   * The MD5 hash of the [content].
   */
  final String contentHash;

  /**
   * Information about lines in the [content].
   */
  final LineInfo lineInfo;

  /**
   * The parsed, unresolved compilation unit for the [content].
   */
  final CompilationUnit unit;

  /**
   * The scanning and parsing errors.
   */
  final List<AnalysisError> errors;

  ParseResult(this.path, this.uri, this.content, this.contentHash,
      this.lineInfo, this.unit, this.errors);
}

/**
 * This class is used to gather and print performance information.
 */
class PerformanceLog {
  final StringSink sink;
  int _level = 0;

  PerformanceLog(this.sink);

  /**
   * Enter a new execution section, which starts at one point of code, runs
   * some time, and then ends at the other point of code.
   *
   * The client must call [PerformanceLogSection.exit] for every [enter].
   */
  PerformanceLogSection enter(String msg) {
    writeln('+++ $msg.');
    _level++;
    return new PerformanceLogSection(this, msg);
  }

  /**
   * Return the result of the function [f] invocation and log the elapsed time.
   *
   * Each invocation of [run] creates a new enclosed section in the log,
   * which begins with printing [msg], then any log output produced during
   * [f] invocation, and ends with printing [msg] with the elapsed time.
   */
  /*=T*/ run/*<T>*/(String msg, /*=T*/ f()) {
    Stopwatch timer = new Stopwatch()..start();
    try {
      writeln('+++ $msg.');
      _level++;
      return f();
    } finally {
      _level--;
      int ms = timer.elapsedMilliseconds;
      writeln('--- $msg in $ms ms.');
    }
  }

  /**
   * Write a new line into the log
   */
  void writeln(String msg) {
    String indent = '\t' * _level;
    sink.writeln('$indent$msg');
  }
}

/**
 * The performance measurement section for operations that start and end
 * at different place in code, so cannot be run using [PerformanceLog.run].
 *
 * The client must call [exit] for every [PerformanceLog.enter].
 */
class PerformanceLogSection {
  final PerformanceLog _logger;
  final String _msg;
  final Stopwatch _timer = new Stopwatch()..start();

  PerformanceLogSection(this._logger, this._msg);

  /**
   * Stop the timer, log the time.
   */
  void exit() {
    _timer.stop();
    _logger._level--;
    int ms = _timer.elapsedMilliseconds;
    _logger.writeln('--- $_msg in $ms ms.');
  }
}

/**
 * Task that computes the list of files that were added to the driver and
 * have at least one reference to an identifier [name] defined outside of the
 * file.
 */
class _FilesReferencingNameTask {
  final AnalysisDriver driver;
  final String name;
  final Completer<List<String>> completer = new Completer<List<String>>();

  final List<String> referencingFiles = <String>[];
  final Set<String> checkedFiles = new Set<String>();
  final List<String> filesToCheck = <String>[];

  _FilesReferencingNameTask(this.driver, this.name);

  /**
   * Perform work for a fixed length of time, and either complete the
   * [completer] and return `true` to indicate that the task is done, return
   * `false` to indicate that the task should continue to be run.
   *
   * Relinquishing execution flow and running event loop after every file
   * works, but has too much overhead. Instead we use a fixed length of time,
   * so we can spend less time overall and keep quick enough response time.
   */
  Future<bool> perform() async {
    Stopwatch timer = new Stopwatch()..start();
    while (timer.elapsedMilliseconds < 5) {
      // Prepare files to check.
      if (filesToCheck.isEmpty) {
        Set<String> newFiles = driver.addedFiles.difference(checkedFiles);
        filesToCheck.addAll(newFiles);
      }

      // If no more files to check, complete and done.
      if (filesToCheck.isEmpty) {
        completer.complete(referencingFiles);
        return true;
      }

      // Check the next file.
      String path = filesToCheck.removeLast();
      FileState file = driver._fsState.getFileForPath(path);
      if (file.referencedNames.contains(name)) {
        referencingFiles.add(path);
      }
      checkedFiles.add(path);
    }

    // We're not done yet.
    return false;
  }
}

/**
 * TODO(scheglov) document
 */
class _LibraryContext {
  final FileState file;
  final SummaryDataStore store;
  _LibraryContext(this.file, this.store);
}
