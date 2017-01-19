// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as driver;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/util/absolute_path.dart';
import 'package:front_end/incremental_resolved_ast_generator.dart';
import 'package:front_end/src/base/file_repository.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/source.dart';
import 'package:front_end/src/dependency_grapher_impl.dart';
import 'package:path/src/context.dart';

dynamic unimplemented() {
  // TODO(paulberry): get rid of this.
  throw new UnimplementedError();
}

/// Implementation of [IncrementalKernelGenerator].
///
/// Theory of operation: this class is a thin wrapper around
/// [driver.AnalysisDriver].  When the client requests a new delta, we forward
/// the request to the analysis driver.  When the client calls an invalidate
/// method, we ensure that the proper files will be re-read next time a delta is
/// requested.
///
/// Note that the analysis driver expects to be able to read file contents
/// synchronously based on filesystem path rather than asynchronously based on
/// URI, so the file contents are first read into memory using the asynchronous
/// FileSystem API, and then these are fed into the analysis driver using a
/// proxy implementation of [ResourceProvider].  TODO(paulberry): make this (and
/// other proxies in this file) unnecessary.
class IncrementalResolvedAstGeneratorImpl
    implements IncrementalResolvedAstGenerator {
  driver.AnalysisDriverScheduler _scheduler;
  final _fileRepository = new FileRepository();
  _ResourceProviderProxy _resourceProvider;
  driver.AnalysisDriver _driver;
  bool _isInitialized = false;
  final ProcessedOptions _options;
  final Uri _source;
  bool _schedulerStarted = false;

  IncrementalResolvedAstGeneratorImpl(this._source, this._options);

  @override
  Future<DeltaLibraries> computeDelta() async {
    if (!_isInitialized) {
      await init();
    }
    // The analysis driver doesn't currently support an asynchronous file API,
    // so we have to find all the files first to read their contents.
    // TODO(paulberry): this is an unnecessary source of duplicate work and
    // should be eliminated ASAP.
    var graph = await graphForProgram([_source], _options);
    var libraries = <Uri, ResolvedLibrary>{};
    if (!_schedulerStarted) {
      _scheduler.start();
      _schedulerStarted = true;
    }
    // The driver will request files from dart:, even though it actually uses
    // the data from the summary.  TODO(paulberry): fix this.
    _fileRepository.store(Uri.parse('dart:core'), '');
    for (var libraryCycle in graph.topologicallySortedCycles) {
      for (var libraryUri in libraryCycle.libraries.keys) {
        var libraryNode = libraryCycle.libraries[libraryUri];
        var libraryContents =
            await _options.fileSystem.entityForUri(libraryUri).readAsString();
        _fileRepository.store(libraryUri, libraryContents);
        for (var partUri in libraryNode.parts) {
          var partContents =
              await _options.fileSystem.entityForUri(partUri).readAsString();
          _fileRepository.store(partUri, partContents);
        }
      }
      for (var libraryUri in libraryCycle.libraries.keys) {
        var libraryNode = libraryCycle.libraries[libraryUri];
        var result =
            await _driver.getResult(_fileRepository.pathForUri(libraryUri));
        // TODO(paulberry): handle errors.
        var definingCompilationUnit = result.unit;
        var partUnits = <Uri, CompilationUnit>{};
        for (var partUri in libraryNode.parts) {
          // Really we ought to have a driver API that lets us request a
          // specific part of a given library.  Otherwise we will run into
          // problems if a part is included in multiple libraries.
          // TODO(paulberry): address this.
          var partResult =
              await _driver.getResult(_fileRepository.pathForUri(partUri));
          // TODO(paulberry): handle errors.
          partUnits[partUri] = partResult.unit;
        }
        libraries[libraryUri] =
            new ResolvedLibrary(definingCompilationUnit, partUnits);
      }
    }
    _driver.addFile(_fileRepository.pathForUri(_source));
    // TODO(paulberry): stop the scheduler
    return new DeltaLibraries(libraries);
  }

  Future<Null> init() async {
    // TODO(paulberry): can we just use null?
    var performanceLog = new driver.PerformanceLog(new _NullStringSink());
    _scheduler = new driver.AnalysisDriverScheduler(performanceLog);
    _resourceProvider = new _ResourceProviderProxy(_fileRepository);
    // TODO(paulberry): MemoryByteStore leaks memory (it never discards data).
    // Do something better here.
    var byteStore = new MemoryByteStore();
    // TODO(paulberry): can we just use null?
    var fileContentOverlay = new FileContentOverlay();
    var sdkContext = new AnalysisContextImpl();
    var dartSdk = new _DartSdkProxy(await _options.getSdkSummary(), sdkContext);
    sdkContext.sourceFactory =
        new SourceFactory([new DartUriResolver(dartSdk)]);
    bool strongMode = true; // TODO(paulberry): support strong mode flag.
    sdkContext.resultProvider = new SdkSummaryResultProvider(
        sdkContext, await _options.getSdkSummary(), strongMode);

    var sourceFactory = new _SourceFactoryProxy(dartSdk, _fileRepository);
    var analysisOptions = new AnalysisOptionsImpl();
    _driver = new driver.AnalysisDriver(
        _scheduler,
        performanceLog,
        _resourceProvider,
        byteStore,
        fileContentOverlay,
        'front_end',
        sourceFactory,
        analysisOptions);
    _isInitialized = true;
  }

  @override
  void invalidate(String path) {
    throw new UnimplementedError();
  }

  @override
  void invalidateAll() {
    // TODO(paulberry): verify that this has an effect (requires a multi-file
    // test).
    if (_isInitialized) {
      _driver.knownFiles.forEach(_driver.changeFile);
    }
  }
}

class _DartSdkProxy implements DartSdk {
  final PackageBundle summary;

  final AnalysisContext context;

  _DartSdkProxy(this.summary, this.context);

  @override
  PackageBundle getLinkedBundle() => summary;

  @override
  Source mapDartUri(String uri) {
    // TODO(paulberry): this seems hacky.
    return new _SourceProxy(Uri.parse(uri), '$uri.dart');
  }

  noSuchMethod(Invocation invocation) => unimplemented();
}

class _FileProxy implements File {
  final _SourceProxy _source;

  final _ResourceProviderProxy _resourceProvider;

  _FileProxy(this._source, this._resourceProvider);

  @override
  String get path => _source.fullName;

  @override
  String get shortName => path;

  @override
  Source createSource([Uri uri]) {
    assert(uri == null);
    return _source;
  }

  noSuchMethod(Invocation invocation) => unimplemented();

  @override
  String readAsStringSync() {
    return _resourceProvider._fileRepository.contentsForPath(path);
  }
}

/// A string sink that ignores everything written to it.
class _NullStringSink implements StringSink {
  void write(Object obj) {}
  void writeAll(Iterable objects, [String separator = ""]) {}
  void writeCharCode(int charCode) {}
  void writeln([Object obj = ""]) {}
}

class _ResourceProviderProxy implements ResourceProvider {
  final FileRepository _fileRepository;

  _ResourceProviderProxy(this._fileRepository);

  @override
  AbsolutePathContext get absolutePathContext => throw new UnimplementedError();

  @override
  Context get pathContext => throw new UnimplementedError();

  @override
  File getFile(String path) {
    return new _FileProxy(
        new _SourceProxy(_fileRepository.uriForPath(path), path), this);
  }

  @override
  Folder getFolder(String path) => throw new UnimplementedError();

  @override
  Future<List<int>> getModificationTimes(List<Source> sources) =>
      throw new UnimplementedError();

  @override
  Resource getResource(String path) => throw new UnimplementedError();

  @override
  Folder getStateLocation(String pluginId) => throw new UnimplementedError();
}

class _SourceFactoryProxy implements SourceFactory {
  @override
  final DartSdk dartSdk;

  final FileRepository _fileRepository;

  @override
  AnalysisContext context;

  _SourceFactoryProxy(this.dartSdk, this._fileRepository);

  @override
  SourceFactory clone() => new _SourceFactoryProxy(dartSdk, _fileRepository);

  @override
  Source forUri(String absoluteUri) {
    Uri uri = Uri.parse(absoluteUri);
    return new _SourceProxy(uri, _fileRepository.pathForUri(uri));
  }

  noSuchMethod(Invocation invocation) => unimplemented();

  Source resolveUri(Source containingSource, String containedUri) {
    // TODO(paulberry): re-use code from dependency_grapher_impl, and support
    // SDK URI resolution logic.
    var absoluteUri = containingSource == null
        ? containedUri
        : containingSource.uri.resolve(containedUri).toString();
    return forUri(absoluteUri);
  }

  @override
  Uri restoreUri(Source source) => source.uri;
}

class _SourceProxy extends BasicSource {
  @override
  final String fullName;

  _SourceProxy(Uri uri, this.fullName) : super(uri);

  int get modificationStamp => 0;

  noSuchMethod(Invocation invocation) => unimplemented();
}
