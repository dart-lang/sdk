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
   * The mapping from the files for which analysis was requested using
   * [getResult] to the [Completer]s to report the result.
   */
  final _requestedFiles = <String, List<Completer<AnalysisResult>>>{};

  /**
   * The set of explicitly analyzed files.
   */
  final _explicitFiles = new LinkedHashSet<String>();

  /**
   * The set of files were reported as changed through [changeFile] and for
   * which API signatures should be recomputed and compared before performing
   * any other analysis.
   */
  final _filesToVerifyUnlinkedSignature = new Set<String>();

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

  AnalysisDriver(this._logger, this._resourceProvider, this._byteStore,
      this._contentCache, this._sourceFactory, this._analysisOptions) {
    _sdkBundle = _sourceFactory.dartSdk.getLinkedBundle();
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
    // TODO(scheglov) implement
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
   * transitions to "idle". Analysis results for other files are produced
   * only if the changes affect analysis results of other files.
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
        // TODO(scheglov) implement state transitioning
        await _hasWork.signal;

        if (analysisSection == null) {
          analysisSection = _logger.enter('Analyzing');
        }

        // TODO(scheglov) verify one file at a time
        _verifyUnlinkedSignatureOfChangedFiles();

        // Analyze the first file in the general queue.
        if (_filesToAnalyze.isNotEmpty) {
          String path = _filesToAnalyze.first;
          _filesToAnalyze.remove(path);
          _File file = _fileForPath(path);
          AnalysisResult result = _computeAnalysisResult(file);
          yield result;
        }

        // If there is work to do, notify the monitor.
        if (_filesToAnalyze.isNotEmpty) {
          _hasWork.notify();
        } else {
          analysisSection.exit();
          analysisSection = null;
        }
      }
      // TODO(scheglov) implement
    } finally {
      print('The stream was cancelled.');
    }
  }

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
    _filesToVerifyUnlinkedSignature.add(path);
    _filesToAnalyze.add(path);
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
   * Compute the [AnalysisResult] for the [file].
   */
  AnalysisResult _computeAnalysisResult(_File file) {
    // TODO(scheglov) Computing resolved unit fails for these units.
    // pkg/analyzer/lib/plugin/embedded_resolver_provider.dart
    // pkg/analyzer/lib/plugin/embedded_resolver_provider.dart
    if (file.path.endsWith(
            'pkg/analyzer/lib/plugin/embedded_resolver_provider.dart') ||
        file.path.endsWith('pkg/analyzer/lib/source/embedder.dart') ||
        file.path.endsWith('pkg/analyzer/lib/src/generated/ast.dart') ||
        file.path.endsWith('pkg/analyzer/lib/src/generated/element.dart') ||
        file.path
            .endsWith('pkg/analyzer/lib/src/generated/element_handle.dart') ||
        file.path.endsWith('pkg/analyzer/lib/src/generated/error.dart') ||
        file.path.endsWith('pkg/analyzer/lib/src/generated/scanner.dart') ||
        file.path.endsWith('pkg/analyzer/lib/src/generated/sdk_io.dart') ||
        file.path.endsWith('pkg/analyzer/lib/src/generated/visitors.dart') ||
        file.path.endsWith('pkg/analyzer/test/generated/constant_test.dart') ||
        file.path.endsWith('pkg/analyzer/test/source/embedder_test.dart')) {
      return new AnalysisResult(
          file.path, file.uri, null, file.contentHash, null, []);
    }

    return _logger.run('Compute analysis result for $file', () {
      _LibraryContext libraryContext = _createLibraryContext(file);
      AnalysisContext analysisContext = _createAnalysisContext(libraryContext);
      try {
        analysisContext.setContents(file.source, file.content);
        // TODO(scheglov) Add support for parts.
        CompilationUnit resolvedUnit =
            analysisContext.resolveCompilationUnit2(file.source, file.source);
        List<AnalysisError> errors = analysisContext.computeErrors(file.source);
        return new AnalysisResult(file.path, file.uri, file.content,
            file.contentHash, resolvedUnit, errors);
      } finally {
        analysisContext.dispose();
      }
    });
  }

  AnalysisContext _createAnalysisContext(_LibraryContext libraryContext) {
    AnalysisContextImpl analysisContext =
        AnalysisEngine.instance.createAnalysisContext();

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
   * Return the [_File] for the given [path] in [_sourceFactory].
   */
  _File _fileForPath(String path) {
    Source fileSource = _resourceProvider.getFile(path).createSource();
    Uri uri = _sourceFactory.restoreUri(fileSource);
    Source source = _resourceProvider.getFile(path).createSource(uri);
    return new _File.forResolution(this, source);
  }

  /**
   * Verify the API signatures for the changed files, and decide which linked
   * libraries should be invalidated, and files reanalyzed.
   *
   * TODO(scheglov) I see that adding a local var changes (full) API signature.
   */
  void _verifyUnlinkedSignatureOfChangedFiles() {
    if (_filesToVerifyUnlinkedSignature.isEmpty) {
      return;
    }
    int numOfFiles = _filesToVerifyUnlinkedSignature.length;
    _logger.run('Verify API signatures of $numOfFiles files', () {
      bool hasMismatch = false;
      for (String path in _filesToVerifyUnlinkedSignature) {
        String oldSignature = _fileApiSignatureMap[path];
        // Compute the new API signature.
        // _File.forResolution() also updates the content hash in the cache.
        _File newFile = _fileForPath(path);
        String newSignature = newFile.unlinked.apiSignature;
        // If the old API signature is not null, then the file was used to
        // compute at least one dependency signature. If the new API signature
        // is different, then potentially all dependency signatures and
        // resolution results are invalid.
        if (oldSignature != null && oldSignature != newSignature) {
          _logger.writeln('API signature mismatch found for $newFile.');
          hasMismatch = true;
        }
      }
      if (hasMismatch) {
        _dependencySignatureMap.clear();
        _filesToAnalyze.addAll(_explicitFiles);
      } else {
        _logger.writeln('All API signatures match.');
      }
      _filesToVerifyUnlinkedSignature.clear();
    });
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
   * The [Source] this [_File] instance represent.
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

  factory _File.forLinking(AnalysisDriver driver, Source source) {
    // If we have enough cached information, use it.
    String contentHash = driver._fileContentHashMap[source.fullName];
    if (contentHash != null) {
      String key = '$contentHash.unlinked';
      List<int> bytes = driver._byteStore.get(key);
      if (bytes != null) {
        PackageBundle unlinked = new PackageBundle.fromBuffer(bytes);
        return new _File._(driver, source, null, contentHash, unlinked, null);
      }
    }
    // Otherwise, read the source, parse and build a new unlinked bundle.
    return new _File.forResolution(driver, source);
  }

  factory _File.forResolution(AnalysisDriver driver, Source source) {
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
      driver._fileApiSignatureMap[path] = unlinked.apiSignature;
    }
    // Update the current file state.
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
      _completer.complete(true);
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
