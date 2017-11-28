// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/file_system.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/kernel.dart';
import 'package:meta/meta.dart';

/// Implementation of [IncrementalKernelGenerator].
///
/// This implementation uses simplified approach to tracking dependencies.
/// When a change happens to a file, we invalidate this file, its library,
/// and then transitive closure of all libraries that reference it.
class MinimalIncrementalKernelGenerator implements IncrementalKernelGenerator {
  static const MSG_PENDING_COMPUTE =
      'A computeDelta() invocation is still executing.';

  static const MSG_NO_LAST_DELTA =
      'The last delta has been already accepted or rejected.';

  static const MSG_HAS_LAST_DELTA =
      'The last delta must be either accepted or rejected.';

  /// Options used by the kernel compiler.
  final ProcessedOptions _options;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final UriTranslator uriTranslator;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The function to notify when files become used or unused, or `null`.
  final WatchUsedFilesFn _watchFn;

  /// A [FileSystem] or [_WatchingFileSystem] instance.
  final FileSystem _fileSystem;

  /// The [Program] with currently valid libraries. When a file is invalidated,
  /// we remove the file, its library, and everything affected from [_program].
  Program _program = new Program();

  /// Each key is the file system URI of a library.
  /// Each value is the libraries that directly depend on the key library.
  Map<String, Set<String>> _directLibraryDependencies = {};

  /// Each key is the file system URI of a library.
  /// Each value is the [Library] that is still in the [_program].
  Map<String, Library> _uriToLibrary = {};

  /// Each key is the file system URI of a part.
  /// Each value is the file system URI of the library that sources the part.
  Map<String, String> _partToLibrary = {};

  /// Whether [computeDelta] is executing.
  bool _isComputeDeltaExecuting = false;

  /// The set of libraries (file system URIs) accepted by the client, and not
  /// yet invalidated explicitly or implicitly via a transitive dependency.
  ///
  /// When we produce a new delta, we put newly compiled libraries into
  /// the [_lastLibraries] field, so [_currentLibraries] and [_lastLibraries]
  /// don't intersect.
  final Set<String> _currentLibraries = new Set<String>();

  /// The set of new libraries (file system URIs) returned to the client by the
  /// last [computeDelta], or `null` if the last delta was either accepted or
  /// rejected.
  Set<String> _lastLibraries;

  /// The object that provides additional information for tests.
  _TestView _testView;

  MinimalIncrementalKernelGenerator(this._options, this.uriTranslator,
      List<int> sdkOutlineBytes, this._entryPoint,
      {WatchUsedFilesFn watch})
      : _logger = _options.logger,
        _watchFn = watch,
        _fileSystem = watch == null
            ? _options.fileSystem
            : new _WatchingFileSystem(_options.fileSystem, watch) {
    _testView = new _TestView();

    // Pre-populate the Program with SDK.
    if (sdkOutlineBytes != null) {
      loadProgramFromBytes(sdkOutlineBytes, _program);
      for (var sdkLibrary in _program.libraries) {
        _currentLibraries.add(sdkLibrary.fileUri);
      }
    }
  }

  /// Return the object that provides additional information for tests.
  @visibleForTesting
  _TestView get test => _testView;

  @override
  void acceptLastDelta() {
    _throwIfNoLastDelta();
    _currentLibraries.addAll(_lastLibraries);
    _lastLibraries = null;
  }

  @override
  Future<DeltaProgram> computeDelta() {
    if (_isComputeDeltaExecuting) {
      throw new StateError(MSG_PENDING_COMPUTE);
    }

    if (_lastLibraries != null) {
      throw new StateError(MSG_HAS_LAST_DELTA);
    }
    _lastLibraries = new Set<String>();

    _isComputeDeltaExecuting = true;

    return _runWithFrontEndContext('Compute delta', () async {
      try {
        var dillTarget = new DillTarget(
            new Ticker(isVerbose: false), uriTranslator, _options.target);

        // Append all libraries what we still have in the current program.
        await _logger.runAsync('Load dill libraries', () async {
          dillTarget.loader.appendLibraries(_program);
          await dillTarget.buildOutlines();
        });

        // Configure KernelTarget to compile the entry point.
        var kernelTarget =
            new KernelTarget(_fileSystem, false, dillTarget, uriTranslator);
        kernelTarget.read(_entryPoint);

        // Compile the entry point into the new program.
        _program = await _logger.runAsync('Compile', () async {
          await kernelTarget.buildOutlines(nameRoot: _program.root);
          return await kernelTarget.buildProgram() ?? _program;
        });

        await _unwatchFiles();

        _logger.run('Compute dependencies', _computeDependencies);

        // Compose the resulting program with new libraries.
        var program = new Program(nameRoot: _program.root);
        _testView.compiledUris.clear();
        for (var library in _program.libraries) {
          String uri = library.fileUri;
          if (_currentLibraries.contains(uri)) continue;

          _lastLibraries.add(uri);
          _testView.compiledUris.add(library.importUri);

          program.uriToSource[uri] = _program.uriToSource[uri];
          for (var part in library.parts) {
            program.uriToSource[part.fileUri] =
                _program.uriToSource[part.fileUri];
          }

          program.libraries.add(library);
          library.parent = program;
        }
        program.mainMethod = _program.mainMethod;

        return new DeltaProgram('', program);
      } finally {
        _isComputeDeltaExecuting = false;
      }
    });
  }

  @override
  void invalidate(Uri uri) {
    void invalidateLibrary(String libraryUri) {
      Library library = _uriToLibrary.remove(libraryUri);
      if (library == null) return;

      // Invalidate the library.
      _program.libraries.remove(library);
      _program.root.removeChild(library.importUri.toString());
      _program.uriToSource.remove(libraryUri);
      _currentLibraries.remove(libraryUri);

      // Recursively invalidate dependencies.
      Set<String> directDependencies =
          _directLibraryDependencies.remove(libraryUri);
      directDependencies?.forEach(invalidateLibrary);
    }

    String uriStr = uri.toString();
    String libraryUri = _partToLibrary.remove(uriStr) ?? uriStr;
    invalidateLibrary(libraryUri);
  }

  @override
  void rejectLastDelta() {
    _throwIfNoLastDelta();
    _lastLibraries = null;
  }

  @override
  void reset() {
    _currentLibraries.clear();
    _lastLibraries = null;
  }

  @override
  void setState(String state) {
    // TODO(scheglov): Do we need this at all?
    // If we don't know the previous state, we will give the client all
    // libraries to reload. While this is suboptimal, this should not affect
    // correctness.
    // Note that even if we don't give the client all libraries, we will have
    // to compile them all anyway, because this implementation does not use
    // any persistent caching.
  }

  /// Recompute [_directLibraryDependencies] for the current [_program].
  void _computeDependencies() {
    _directLibraryDependencies.clear();
    _uriToLibrary.clear();
    _partToLibrary.clear();

    var processedLibraries = new Set<Library>();

    void processLibrary(Library library) {
      if (!processedLibraries.add(library)) return;
      _uriToLibrary[library.fileUri] = library;

      // Remember libraries for parts.
      for (var part in library.parts) {
        _partToLibrary[part.fileUri] = library.fileUri;
      }

      // Record reverse dependencies.
      for (LibraryDependency dependency in library.dependencies) {
        Library targetLibrary = dependency.targetLibrary;
        _directLibraryDependencies
            .putIfAbsent(targetLibrary.fileUri, () => new Set<String>())
            .add(library.fileUri);
        processLibrary(targetLibrary);
      }
    }

    var entryPointLibrary = _getEntryPointLibrary();
    processLibrary(entryPointLibrary);
  }

  Library _getEntryPointLibrary() =>
      _program.libraries.singleWhere((lib) => lib.importUri == _entryPoint);

  Future<T> _runWithFrontEndContext<T>(String msg, Future<T> f()) async {
    return await CompilerContext.runWithOptions(_options, (context) {
      context.disableColors();
      return _logger.runAsync(msg, f);
    });
  }

  /// Throw [StateError] if [_lastLibraries] is `null`, i.e. there is no
  /// last delta - it either has not been computed yet, or has been already
  /// accepted or rejected.
  void _throwIfNoLastDelta() {
    if (_isComputeDeltaExecuting) {
      throw new StateError(MSG_PENDING_COMPUTE);
    }
    if (_lastLibraries == null) {
      throw new StateError(MSG_NO_LAST_DELTA);
    }
  }

  /// Compute the set of of files transitively referenced from the entry point,
  /// remove all other files from [_program], and call [_watchFn] to unwatch
  /// known files that are not longer referenced.
  Future<Null> _unwatchFiles() async {
    var entryPointFiles = new Set<String>();

    // Don't remove SDK libraries.
    for (var library in _program.libraries) {
      if (library.importUri.isScheme('dart')) {
        entryPointFiles.add(library.fileUri);
        for (var part in library.parts) {
          entryPointFiles.add(part.fileUri);
        }
      }
    }

    void appendTransitiveFiles(Library library) {
      if (entryPointFiles.add(library.fileUri)) {
        for (var part in library.parts) {
          entryPointFiles.add(part.fileUri);
        }
        for (var dependency in library.dependencies) {
          appendTransitiveFiles(dependency.targetLibrary);
        }
      }
    }

    // Append files transitively referenced from the entry point.
    var entryPointLibrary = _getEntryPointLibrary();
    appendTransitiveFiles(entryPointLibrary);

    // Remove not loaded files from the set of known files.
    if (_fileSystem is _WatchingFileSystem) {
      _WatchingFileSystem fileSystem = _fileSystem;
      for (Uri knownUri in fileSystem.knownFiles.toList()) {
        var knownUriStr = knownUri.toString();
        if (!entryPointFiles.contains(knownUriStr)) {
          await _watchFn(knownUri, false);
          fileSystem.knownFiles.remove(knownUri);
          _program.uriToSource.remove(knownUriStr);
        }
      }
    }

    // Remove libraries that are no longer referenced.
    _program.libraries
        .removeWhere((library) => !entryPointFiles.contains(library.fileUri));
  }
}

@visibleForTesting
class _TestView {
  /// The list of [Uri]s compiled for the last delta.
  /// It does not include libraries which were reused from the last program.
  final Set<Uri> compiledUris = new Set<Uri>();
}

/// [FileSystem] that notifies [WatchUsedFilesFn] about new files.
class _WatchingFileSystem implements FileSystem {
  final FileSystem fileSystem;
  final WatchUsedFilesFn watchFn;
  final Set<Uri> knownFiles = new Set<Uri>();

  _WatchingFileSystem(this.fileSystem, this.watchFn);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    var entity = fileSystem.entityForUri(uri);
    return new _WatchingFileSystemEntity(this, entity, watchFn);
  }
}

/// [FileSystemEntity] that notifies the [WatchUsedFilesFn] about new files.
class _WatchingFileSystemEntity implements FileSystemEntity {
  final _WatchingFileSystem fileSystem;
  final FileSystemEntity entity;
  final WatchUsedFilesFn watchFn;

  _WatchingFileSystemEntity(this.fileSystem, this.entity, this.watchFn);

  @override
  Uri get uri => entity.uri;

  @override
  Future<bool> exists() {
    return entity.exists();
  }

  @override
  Future<List<int>> readAsBytes() async {
    if (fileSystem.knownFiles.add(uri)) {
      await watchFn(uri, true);
    }
    return entity.readAsBytes();
  }

  @override
  Future<String> readAsString() async {
    if (fileSystem.knownFiles.add(uri)) {
      await watchFn(uri, true);
    }
    return entity.readAsString();
  }
}
