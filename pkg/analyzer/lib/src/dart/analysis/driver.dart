// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions, ChangeSet;
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

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
 */
class AnalysisDriver {
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
  final ContentCache _contentCache;

  /**
   * The [SourceFactory] is used to resolve URIs to paths and restore URIs
   * from file paths.
   */
  final SourceFactory _sourceFactory;

  /**
   * The analysis options to analyze with.
   */
  final AnalysisOptions _analysisOptions;

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
   * The set of files were reported as changed through [changeFile] and not
   * checked for actual changes yet.
   */
  final _changedFiles = new LinkedHashSet<String>();

  /**
   * The set of files that are currently scheduled for analysis.
   */
  final _filesToAnalyze = new LinkedHashSet<String>();

  /**
   * Cache of URI resolution. The outer map key is the absolute URI of the
   * containing file. The inner map key is the URI text of a directive
   * contained in that file. The inner map value is the [Source] object which
   * that URI text resolves to.
   */
  final _uriResolutionCache = <Uri, Map<String, Source>>{};

  /**
   * The current file state.
   *
   * It maps file paths to the MD5 hash of the file content.
   */
  final _fileContentHashMap = <String, String>{};

  /**
   * The API signatures corresponding to [_fileContentHashMap].
   *
   * It maps file paths to the unlinked API signatures.
   */
  final _fileApiSignatureMap = <String, String>{};

  /**
   * Mapping from library URIs to the dependency signature of the library.
   */
  final _dependencySignatureMap = <Uri, String>{};

  /**
   * The monitor that is signalled when there is work to do.
   */
  final _Monitor _hasWork = new _Monitor();

  /**
   * The controller for the [status] stream.
   */
  final _statusController = new StreamController<AnalysisStatus>();

  /**
   * The last status sent to the [status] stream.
   */
  AnalysisStatus _currentStatus = AnalysisStatus.IDLE;

  AnalysisDriver(this._logger, this._resourceProvider, this._byteStore,
      this._contentCache, SourceFactory sourceFactory, this._analysisOptions)
      : _sourceFactory = sourceFactory.clone() {
    _sdkBundle = sourceFactory.dartSdk.getLinkedBundle();
  }

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
    _transitionToAnalyzing();
    _hasWork.notify();
  }

  /**
   * Return the [Stream] that produces [AnalysisResult]s for added files.
   *
   * Analysis starts when the client starts listening to the stream, and stops
   * when the client cancels the subscription.
   *
   * When the client starts listening, the analysis state transitions to
   * "analyzing" and an analysis result is produced for every added file prior
   * to the next time the analysis state transitions to "idle".
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
  Stream<AnalysisResult> get results async* {
    try {
      PerformanceLogSection analysisSection = null;
      while (true) {
        await _hasWork.signal;

        if (analysisSection == null) {
          analysisSection = _logger.enter('Analyzing');
        }

        // Verify all changed files one at a time.
        if (_changedFiles.isNotEmpty) {
          String path = _removeFirst(_changedFiles);
          _verifyApiSignatureOfChangedFile(path);
          // Repeat the processing loop.
          _hasWork.notify();
          continue;
        }

        // Analyze a requested file.
        if (_requestedFiles.isNotEmpty) {
          String path = _requestedFiles.keys.first;
          AnalysisResult result = _computeAnalysisResult(path, withUnit: true);
          // Notify the completers.
          _requestedFiles.remove(path).forEach((completer) {
            completer.complete(result);
          });
          // Remove from to be analyzed and produce it now.
          _filesToAnalyze.remove(path);
          yield result;
          // Repeat the processing loop.
          _hasWork.notify();
          continue;
        }

        // Analyze a priority file.
        if (_priorityFiles.isNotEmpty) {
          bool analyzed = false;
          for (String path in _priorityFiles) {
            if (_filesToAnalyze.remove(path)) {
              analyzed = true;
              AnalysisResult result =
                  _computeAnalysisResult(path, withUnit: true);
              yield result;
              break;
            }
          }
          // Repeat the processing loop.
          if (analyzed) {
            _hasWork.notify();
            continue;
          }
        }

        // Analyze a general file.
        if (_filesToAnalyze.isNotEmpty) {
          String path = _removeFirst(_filesToAnalyze);
          AnalysisResult result = _computeAnalysisResult(path, withUnit: false);
          yield result;
          // Repeat the processing loop.
          _hasWork.notify();
          continue;
        }

        // There is nothing to do.
        analysisSection.exit();
        analysisSection = null;
        _transitionToIdle();
      }
    } finally {
      print('The stream was cancelled.');
    }
  }

  /**
   * Return the stream that produces [AnalysisStatus] events.
   */
  Stream<AnalysisStatus> get status => _statusController.stream;

  /**
   * Add the file with the given [path] to the set of files to analyze.
   *
   * The [path] must be absolute and normalized.
   *
   * The results of analysis are eventually produced by the [results] stream.
   */
  void addFile(String path) {
    _explicitFiles.add(path);
    _filesToAnalyze.add(path);
    _transitionToAnalyzing();
    _hasWork.notify();
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
    _changedFiles.add(path);
    if (_explicitFiles.contains(path)) {
      _filesToAnalyze.add(path);
    }
    _transitionToAnalyzing();
    _hasWork.notify();
  }

  /**
   * Return the [Future] that completes with a [AnalysisResult] for the file
   * with the given [path].
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
    var completer = new Completer<AnalysisResult>();
    _requestedFiles
        .putIfAbsent(path, () => <Completer<AnalysisResult>>[])
        .add(completer);
    _transitionToAnalyzing();
    _hasWork.notify();
    return completer.future;
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
      SummaryDataStore store, String uri, UnlinkedUnit unlinked) {
    store.unlinkedMap[uri] = unlinked;
  }

  /**
   * Return the cached or newly computed analysis result of the file with the
   * given [path].
   *
   * The result will have the fully resolved unit and will always be newly
   * compute only if [withUnit] is `true`.
   */
  AnalysisResult _computeAnalysisResult(String path, {bool withUnit: false}) {
    Source source = _sourceForPath(path);

    // If we don't need the fully resolved unit, check for the cached result.
    if (!withUnit) {
      _File file = new _File.forLinking(this, source);
      // Prepare the key for the cached result.
      String key = _getResolvedUnitKey(file);
      if (key == null) {
        _logger.run('Compute the dependency hash for $source', () {
          _createLibraryContext(file);
          key = _getResolvedUnitKey(file);
        });
      }
      // Check for the cached result.
      AnalysisResult result = _getCachedAnalysisResult(file, key);
      if (result != null) {
        return result;
      }
    }

    // We need the fully resolved unit, or the result is not cached.
    return _logger.run('Compute analysis result for $source', () {
      // Still no result, compute and store it.
      _File file = new _File.forResolution(this, source);
      _LibraryContext libraryContext = _createLibraryContext(file);
      AnalysisContext analysisContext = _createAnalysisContext(libraryContext);
      try {
        analysisContext.setContents(file.source, file.content);
        // TODO(scheglov) Add support for parts.
        CompilationUnit resolvedUnit = withUnit
            ? analysisContext.resolveCompilationUnit2(file.source, file.source)
            : null;
        List<AnalysisError> errors = analysisContext.computeErrors(file.source);

        // Store the result into the cache.
        {
          List<int> bytes = new AnalysisDriverResolvedUnitBuilder(
                  errors: errors
                      .map((error) => new AnalysisDriverUnitErrorBuilder(
                          offset: error.offset,
                          length: error.length,
                          uniqueName: error.errorCode.uniqueName,
                          message: error.message,
                          correction: error.correction))
                      .toList())
              .toBuffer();
          String key = _getResolvedUnitKey(file);
          _byteStore.put(key, bytes);
        }

        // Return the result, full or partial.
        _logger.writeln('Computed new analysis result.');
        return new AnalysisResult(
            file.path,
            file.uri,
            withUnit ? file.content : null,
            file.contentHash,
            resolvedUnit,
            errors);
      } finally {
        analysisContext.dispose();
      }
    });
  }

  AnalysisContext _createAnalysisContext(_LibraryContext libraryContext) {
    AnalysisContextImpl analysisContext =
        AnalysisEngine.instance.createAnalysisContext();
    analysisContext.analysisOptions = _analysisOptions;

    analysisContext.sourceFactory =
        new SourceFactory((_sourceFactory as SourceFactoryImpl).resolvers);
    analysisContext.resultProvider =
        new InputPackagesResultProvider(analysisContext, libraryContext.store);
    analysisContext
        .applyChanges(new ChangeSet()..addedSource(libraryContext.file.source));
    return analysisContext;
  }

  /**
   * Return the context in which the library represented by the given
   * [libraryFile] should be analyzed it.
   *
   * TODO(scheglov) We often don't need [SummaryDataStore], only dependency
   * signature.
   */
  _LibraryContext _createLibraryContext(_File libraryFile) {
    return _logger.run('Create library context', () {
      Map<String, _LibraryNode> nodes = <String, _LibraryNode>{};
      SummaryDataStore store = new SummaryDataStore(const <String>[]);
      store.addBundle(null, _sdkBundle);

      _LibraryNode createLibraryNodes(_File libraryFile) {
        Uri libraryUri = libraryFile.uri;

        // URIs with the 'dart:' scheme are served from the SDK bundle.
        if (libraryUri.scheme == 'dart') {
          return null;
        }

        String libraryUriStr = libraryUri.toString();
        _LibraryNode node = nodes[libraryUriStr];
        if (node == null) {
          node = new _LibraryNode(this, nodes, libraryUri);
          nodes[libraryUriStr] = node;

          // Append the defining unit.
          _ReferencedUris referenced;
          {
            PackageBundle bundle = libraryFile.unlinked;
            UnlinkedUnit unlinked = bundle.unlinkedUnits.single;
            referenced = new _ReferencedUris(unlinked);
            node.unlinkedBundles.add(bundle);
            _addToStoreUnlinked(store, libraryUriStr, unlinked);
          }

          // Append parts.
          for (String uri in referenced.parted) {
            _File file = libraryFile.resolveUri(uri);
            PackageBundle bundle = file.unlinked;
            UnlinkedUnit unlinked = bundle.unlinkedUnits.single;
            node.unlinkedBundles.add(bundle);
            _addToStoreUnlinked(store, file.uri.toString(), unlinked);
          }

          // Create nodes for referenced libraries.
          for (String uri in referenced.imported) {
            _File file = libraryFile.resolveUri(uri);
            createLibraryNodes(file);
          }
          for (String uri in referenced.exported) {
            _File file = libraryFile.resolveUri(uri);
            createLibraryNodes(file);
          }
        }

        // Done with this node.
        return node;
      }

      _LibraryNode libraryNode = _logger.run('Compute library nodes', () {
        return createLibraryNodes(libraryFile);
      });

      Set<String> libraryUrisToLink = new Set<String>();
      _logger.run('Load linked bundles', () {
        for (_LibraryNode node in nodes.values) {
          String key = '${node.dependencySignature}.linked';
          List<int> bytes = _byteStore.get(key);
          if (bytes != null) {
            PackageBundle linked = new PackageBundle.fromBuffer(bytes);
            _addToStoreLinked(
                store, node.uri.toString(), linked.linkedLibraries.single);
          } else {
            libraryUrisToLink.add(node.uri.toString());
          }
        }
        int numOfLoaded = nodes.length - libraryUrisToLink.length;
        _logger.writeln('Loaded $numOfLoaded linked bundles.');
      });

      Map<String, LinkedLibraryBuilder> linkedLibraries = {};
      _logger.run('Link bundles', () {
        linkedLibraries = link(libraryUrisToLink, (String uri) {
          LinkedLibrary linkedLibrary = store.linkedMap[uri];
          if (linkedLibrary == null) {
            throw new StateError('No linked library for: $uri');
          }
          return linkedLibrary;
        }, (String uri) {
          UnlinkedUnit unlinkedUnit = store.unlinkedMap[uri];
          if (unlinkedUnit == null) {
            throw new StateError('No unlinked unit for: $uri');
          }
          return unlinkedUnit;
        }, (_) => null, _analysisOptions.strongMode);
        _logger.writeln('Linked ${linkedLibraries.length} bundles.');
      });

      linkedLibraries.forEach((uri, linkedBuilder) {
        _LibraryNode node = nodes[uri];
        String key = '${node.dependencySignature}.linked';
        List<int> bytes;
        {
          PackageBundleAssembler assembler = new PackageBundleAssembler();
          assembler.addLinkedLibrary(uri, linkedBuilder);
          bytes = assembler.assemble().toBuffer();
        }
        PackageBundle linked = new PackageBundle.fromBuffer(bytes);
        _addToStoreLinked(store, uri, linked.linkedLibraries.single);
        _byteStore.put(key, bytes);
      });

      return new _LibraryContext(libraryFile, libraryNode, store);
    });
  }

  /**
   * If we know the result [key] for the [file], try to load the analysis
   * result from the cache. Return `null` if not found.
   */
  AnalysisResult _getCachedAnalysisResult(_File file, String key) {
    List<int> bytes = _byteStore.get(key);
    if (bytes != null) {
      var unit = new AnalysisDriverResolvedUnit.fromBuffer(bytes);
      List<AnalysisError> errors = unit.errors
          .map((error) => new AnalysisError.forValues(
              file.source,
              error.offset,
              error.length,
              ErrorCode.byUniqueName(error.uniqueName),
              error.message,
              error.correction))
          .toList();
      return new AnalysisResult(
          file.path, file.uri, null, file.contentHash, null, errors);
    }
    return null;
  }

  /**
   * Return the key to store fully resolved results for the [file] into the
   * cache. Return `null` if the dependency signature is not known yet.
   */
  String _getResolvedUnitKey(_File file) {
    String dependencyHash = _dependencySignatureMap[file.uri];
    if (dependencyHash != null) {
      ApiSignature signature = new ApiSignature();
      signature.addString(dependencyHash);
      signature.addString(file.contentHash);
      return '${signature.toHex()}.resolved';
    }
    return null;
  }

  /**
   * Return the [Source] for the given [path] in [_sourceFactory].
   */
  Source _sourceForPath(String path) {
    Source fileSource = _resourceProvider.getFile(path).createSource();
    Uri uri = _sourceFactory.restoreUri(fileSource);
    return _resourceProvider.getFile(path).createSource(uri);
  }

  /**
   * Send a notifications to the [status] stream that the driver started
   * analyzing.
   */
  void _transitionToAnalyzing() {
    if (_currentStatus != AnalysisStatus.ANALYZING) {
      _currentStatus = AnalysisStatus.ANALYZING;
      _statusController.add(AnalysisStatus.ANALYZING);
    }
  }

  /**
   * Send a notifications to the [status] stream that the driver is idle.
   */
  void _transitionToIdle() {
    if (_currentStatus != AnalysisStatus.IDLE) {
      _currentStatus = AnalysisStatus.IDLE;
      _statusController.add(AnalysisStatus.IDLE);
    }
  }

  /**
   * Verify the API signature for the file with the given [path], and decide
   * which linked libraries should be invalidated, and files reanalyzed.
   *
   * TODO(scheglov) I see that adding a local var changes (full) API signature.
   */
  void _verifyApiSignatureOfChangedFile(String path) {
    _logger.run('Verify API signature of $path', () {
      String oldSignature = _fileApiSignatureMap[path];
      // Compute the new API signature.
      // _File.forResolution() also updates the content hash in the cache.
      Source source = _sourceForPath(path);
      _File newFile = new _File.forResolution(this, source);
      String newSignature = newFile.unlinked.apiSignature;
      // If the old API signature is not null, then the file was used to
      // compute at least one dependency signature. If the new API signature
      // is different, then potentially all dependency signatures and
      // resolution results are invalid.
      if (oldSignature != null && oldSignature != newSignature) {
        _logger.writeln('API signatures mismatch found for $newFile');
        _dependencySignatureMap.clear();
        _filesToAnalyze.addAll(_explicitFiles);
      }
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
   * The fully resolved compilation unit for the [content].
   */
  final CompilationUnit unit;

  /**
   * The full list of computed analysis errors, both syntactic and semantic.
   */
  final List<AnalysisError> errors;

  AnalysisResult(this.path, this.uri, this.content, this.contentHash, this.unit,
      this.errors);
}

/**
 * The status of [AnalysisDriver]
 */
class AnalysisStatus {
  static const IDLE = const AnalysisStatus._(false);
  static const ANALYZING = const AnalysisStatus._(true);

  final bool _analyzing;

  const AnalysisStatus._(this._analyzing);

  /**
   * Return `true` is the driver is analyzing.
   */
  bool get isAnalyzing => _analyzing;

  /**
   * Return `true` is the driver is idle.
   */
  bool get isIdle => !_analyzing;
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
 * Information about a file being analyzed, explicitly or implicitly.
 *
 * It provides a stable, consistent view on its [content], [contentHash],
 * [unlinked] and [unit].
 *
 * A new file can be created either for resolution or for linking.
 *
 * When file is created for linking, it assumes that the file has not been
 * changed since the last time its content was read and hashed. So, this
 * content hash is also used to look for an existing unlinked bundle in the
 * [AnalysisDriver._byteStore]. If any of the caches is empty, the file is
 * created without caching, as for resolution.
 *
 * When file is created for resolution, we always read the content, compute its
 * hash and update [AnalysisDriver._fileContentHashMap], parse the content,
 * compute the unlinked bundle and update [AnalysisDriver._fileApiSignatureMap].
 * It is important to keep these two maps in sync.
 */
class _File {
  /**
   * The driver instance that is used to access [SourceFactory] and caches.
   */
  final AnalysisDriver driver;

  /**
   * The [Source] this [_File] instance represents.
   */
  final Source source;

  /**
   * The [source] content, or `null` if this file is for linking.
   */
  final String content;

  /**
   * The [source] content hash, not `null` even if [content] is `null`.
   */
  final String contentHash;

  /**
   * The unlinked bundle, not `null`.
   */
  final PackageBundle unlinked;

  /**
   * The unresolved unit, not `null` if this file is for resolution.
   */
  final CompilationUnit unit;

  /**
   * Return the file with consistent [content] and [contentHash].
   */
  factory _File.forContent(AnalysisDriver driver, Source source) {
    String path = source.fullName;
    // Read the content.
    String content;
    try {
      content = driver._contentCache.getContents(source);
      content ??= source.contents.data;
    } catch (_) {
      content = '';
      // TODO(scheglov) We fail to report URI_DOES_NOT_EXIST.
      // On one hand we need to provide an unlinked bundle to prevent
      // analysis context from reading the file (we want it to work
      // hermetically and handle one one file at a time). OTOH,
      // ResynthesizerResultProvider happily reports that any source in the
      // SummaryDataStore has MODIFICATION_TIME `0`. We need to return `-1`
      // for missing files. Maybe add this feature to SummaryDataStore?
    }
    // Compute the content hash.
    List<int> textBytes = UTF8.encode(content);
    List<int> hashBytes = md5.convert(textBytes).bytes;
    String contentHash = hex.encode(hashBytes);
    driver._fileContentHashMap[path] = contentHash;
    // Return information about the file content.
    return new _File._(driver, source, content, contentHash, null, null);
  }

  factory _File.forLinking(AnalysisDriver driver, Source source) {
    String path = source.fullName;
    String contentHash = driver._fileContentHashMap[path];
    // If we don't have the file content hash, compute it.
    if (contentHash == null) {
      _File file = new _File.forContent(driver, source);
      contentHash = file.contentHash;
    }
    // If we have the cached unlinked bundle, use it.
    {
      String key = '$contentHash.unlinked';
      List<int> bytes = driver._byteStore.get(key);
      if (bytes != null) {
        PackageBundle unlinked = new PackageBundle.fromBuffer(bytes);
        _updateApiSignature(driver, path, unlinked.apiSignature);
        return new _File._(driver, source, null, contentHash, unlinked, null);
      }
    }
    // Otherwise, read the source, parse and build a new unlinked bundle.
    return new _File.forResolution(driver, source);
  }

  factory _File.forResolution(AnalysisDriver driver, Source source) {
    _File file = new _File.forContent(driver, source);
    String path = file.path;
    String content = file.content;
    String contentHash = file.contentHash;
    // Parse the unit.
    CompilationUnit unit = _parse(driver, source, content);
    // Prepare the unlinked bundle.
    PackageBundle unlinked;
    {
      String key = '$contentHash.unlinked';
      List<int> bytes = driver._byteStore.get(key);
      if (bytes == null) {
        driver._logger.run('Create unlinked for $path', () {
          UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
          PackageBundleAssembler assembler = new PackageBundleAssembler();
          assembler.addUnlinkedUnitWithHash(
              source.uri.toString(), unlinkedUnit, contentHash);
          bytes = assembler.assemble().toBuffer();
          driver._byteStore.put(key, bytes);
        });
      }
      unlinked = new PackageBundle.fromBuffer(bytes);
      _updateApiSignature(driver, path, unlinked.apiSignature);
    }
    // Return the full file.
    return new _File._(driver, source, content, contentHash, unlinked, unit);
  }

  _File._(this.driver, this.source, this.content, this.contentHash,
      this.unlinked, this.unit);

  String get path => source.fullName;

  Uri get uri => source.uri;

  /**
   * Return the [_File] for the [uri] referenced in this file.
   *
   * This [_File] can be used only for linking.
   */
  _File resolveUri(String uri) {
    // TODO(scheglov) Consider removing this caching after implementing other
    // optimizations, e.g. changeFile() optimization.
    Source uriSource = driver._uriResolutionCache
        .putIfAbsent(this.uri, () => <String, Source>{})
        .putIfAbsent(uri, () => driver._sourceFactory.resolveUri(source, uri));
    return new _File.forLinking(driver, uriSource);
  }

  @override
  String toString() => path;

  /**
   * Return the parsed unresolved [CompilationUnit] for the given [content].
   */
  static CompilationUnit _parse(
      AnalysisDriver driver, Source source, String content) {
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;

    CharSequenceReader reader = new CharSequenceReader(content);
    Scanner scanner = new Scanner(source, reader, errorListener);
    scanner.scanGenericMethodComments = driver._analysisOptions.strongMode;
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);

    Parser parser = new Parser(source, errorListener);
    parser.parseGenericMethodComments = driver._analysisOptions.strongMode;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }

  static void _updateApiSignature(
      AnalysisDriver driver, String path, String newSignature) {
    String oldSignature = driver._fileApiSignatureMap[path];
    if (oldSignature != null && oldSignature != newSignature) {
      driver._dependencySignatureMap.clear();
    }
    driver._fileApiSignatureMap[path] = newSignature;
  }
}

/**
 * TODO(scheglov) document
 */
class _LibraryContext {
  final _File file;
  final _LibraryNode node;
  final SummaryDataStore store;
  _LibraryContext(this.file, this.node, this.store);
}

class _LibraryNode {
  final AnalysisDriver driver;
  final Map<String, _LibraryNode> nodes;
  final Uri uri;
  final List<PackageBundle> unlinkedBundles = <PackageBundle>[];

  Set<_LibraryNode> transitiveDependencies;
  List<_LibraryNode> _dependencies;
  String _dependencySignature;

  _LibraryNode(this.driver, this.nodes, this.uri);

  /**
   * Retrieve the dependencies of this node.
   */
  List<_LibraryNode> get dependencies {
    if (_dependencies == null) {
      Set<_LibraryNode> dependencies = new Set<_LibraryNode>();

      void appendDependency(String uriStr) {
        Uri uri = FastUri.parse(uriStr);
        if (uri.scheme == 'dart') {
          // Dependency on the SDK is implicit and always added.
          // The SDK linked bundle is precomputed before linking packages.
        } else {
          if (!uri.isAbsolute) {
            uri = resolveRelativeUri(this.uri, uri);
            uriStr = uri.toString();
          }
          _LibraryNode node = nodes[uriStr];
          if (node == null) {
            throw new StateError('No node for: $uriStr');
          }
          dependencies.add(node);
        }
      }

      for (PackageBundle unlinkedBundle in unlinkedBundles) {
        for (UnlinkedUnit unit in unlinkedBundle.unlinkedUnits) {
          for (UnlinkedImport import in unit.imports) {
            if (!import.isImplicit) {
              appendDependency(import.uri);
            }
          }
          for (UnlinkedExportPublic export in unit.publicNamespace.exports) {
            appendDependency(export.uri);
          }
        }
      }

      _dependencies = dependencies.toList();
    }
    return _dependencies;
  }

  String get dependencySignature {
    return _dependencySignature ??=
        driver._dependencySignatureMap.putIfAbsent(uri, () {
      computeTransitiveDependencies();

      // Add all unlinked API signatures.
      List<String> signatures = <String>[];
      signatures.add(driver._sdkBundle.apiSignature);
      transitiveDependencies
          .map((node) => node.unlinkedBundles)
          .expand((bundles) => bundles)
          .map((bundle) => bundle.apiSignature)
          .forEach(signatures.add);
      signatures.sort();

      // Combine into a single hash.
      ApiSignature signature = new ApiSignature();
      signature.addString(uri.toString());
      signatures.forEach(signature.addString);
      return signature.toHex();
    });
  }

  @override
  int get hashCode => uri.hashCode;

  bool operator ==(other) {
    return other is _LibraryNode && other.uri == uri;
  }

  void computeTransitiveDependencies() {
    if (transitiveDependencies == null) {
      transitiveDependencies = new Set<_LibraryNode>();

      void appendDependencies(_LibraryNode node) {
        if (transitiveDependencies.add(node)) {
          node.dependencies.forEach(appendDependencies);
        }
      }

      appendDependencies(this);
    }
  }

  @override
  String toString() => uri.toString();
}

/**
 * [_Monitor] can be used to wait for a signal.
 *
 * Signals are not queued, the client will receive exactly one signal
 * regardless of the number of [notify] invocations. The [signal] is reset
 * after completion and will not complete until [notify] is called next time.
 */
class _Monitor {
  Completer<Null> _completer = new Completer<Null>();

  /**
   * Return a [Future] that completes when [notify] is called at least once.
   */
  Future<Null> get signal async {
    await _completer.future;
    _completer = new Completer<Null>();
  }

  /**
   * Complete the [signal] future if it is not completed yet. It is safe to
   * call this method multiple times, but the [signal] will complete only once.
   */
  void notify() {
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }
}

/**
 * TODO(scheglov) document
 */
class _ReferencedUris {
  bool isLibrary = true;
  final List<String> imported = <String>[];
  final List<String> exported = <String>[];
  final List<String> parted = <String>[];

  factory _ReferencedUris(UnlinkedUnit unit) {
    _ReferencedUris referenced = new _ReferencedUris._();
    referenced.parted.addAll(unit.publicNamespace.parts);
    for (UnlinkedImport import in unit.imports) {
      if (!import.isImplicit) {
        referenced.imported.add(import.uri);
      }
    }
    for (UnlinkedExportPublic export in unit.publicNamespace.exports) {
      referenced.exported.add(export.uri);
    }
    return referenced;
  }

  _ReferencedUris._();
}
