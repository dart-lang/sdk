// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:front_end/byte_store.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:front_end/src/incremental/reference_index.dart';
import 'package:kernel/kernel.dart';
import 'package:meta/meta.dart';

/// Implementation of [IncrementalKernelGenerator].
///
/// The initial compilation of the entry point is performed not incrementally.
///
/// Each file that is transitively referenced from the entry point is read,
/// its API signature is computed.  Then full compilation is performed, without
/// any incrementality, to get the initial program.  When a file is invalidated,
/// it is read again, and its API signature is recomputed.  If the API signature
/// is the same as it was before, then only the library of the file is
/// recompiled, and the current program is updated.  If the API signature of
/// a file is different, all libraries that transitively use the changed file
/// are removed from the current program, and recompiled using the remaining
/// libraries.
class IncrementalKernelGeneratorImpl implements IncrementalKernelGenerator {
  static const MSG_PENDING_COMPUTE =
      'A computeDelta() invocation is still executing.';

  static const MSG_NO_LAST_DELTA =
      'The last delta has been already accepted or rejected.';

  static const MSG_HAS_LAST_DELTA =
      'The last delta must be either accepted or rejected.';

  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 1;

  /// Options used by the kernel compiler.
  final ProcessedOptions options;

  /// The optional SDK outline as a serialized program.
  /// If provided, the driver will not attempt to read SDK files.
  final List<int> _sdkOutlineBytes;

  /// The [FileSystem] which should be used by the front end to access files.
  final FileSystem _fileSystem;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The [ByteStore] used to cache results.
  final ByteStore _byteStore;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final UriTranslator uriTranslator;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The function to notify when files become used or unused, or `null`.
  final WatchUsedFilesFn _watchFn;

  /// The salt to mix into all hashes used as keys for serialized data.
  List<int> _salt;

  /// The current file system state.
  FileSystemState _fsState;

  /// The list of absolute file URIs that were reported through [invalidate]
  /// and not checked for actual changes yet.
  List<Uri> _invalidatedFiles = [];

  /// The set of libraries for which the content of the library file, or
  /// one of its parts, changed using [invalidate].
  final Set<FileState> _changedLibrariesWithSameApi = new Set<FileState>();

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

  /// The index that keeps track of references and nodes that use them,
  /// and allows fast reference replacement on a single library compilation.
  final ReferenceIndex _referenceIndex = new ReferenceIndex();

  /// Whether [computeDelta] is executing.
  bool _isComputeDeltaExecuting = false;

  /// The current signatures for libraries.
  final Map<Uri, String> _currentSignatures = {};

  /// The signatures for libraries produced by the last [computeDelta], or
  /// `null` if the last delta was either accepted or rejected.
  Map<Uri, String> _lastSignatures;

  /// The object that provides additional information for tests.
  final _TestView _testView = new _TestView();

  IncrementalKernelGeneratorImpl(this.options, this.uriTranslator,
      List<int> sdkOutlineBytes, this._entryPoint,
      {WatchUsedFilesFn watch})
      : _sdkOutlineBytes = sdkOutlineBytes,
        _fileSystem = options.fileSystem,
        _logger = options.logger,
        _byteStore = options.byteStore,
        _watchFn = watch {
    _computeSalt();

    Future<Null> onFileAdded(Uri uri) {
      if (_watchFn != null) {
        return _watchFn(uri, true);
      }
      return new Future.value();
    }

    _fsState = new FileSystemState(_byteStore, _fileSystem, options.target,
        uriTranslator, _salt, onFileAdded);

    // Pre-populate the Program with SDK.
    _loadSdkOutline();
  }

  /// Return the object that provides additional information for tests.
  @visibleForTesting
  _TestView get test => _testView;

  @override
  void acceptLastDelta() {
    _throwIfNoLastDelta();
    _currentSignatures.addAll(_lastSignatures);
    _lastSignatures = null;
  }

  @override
  Future<DeltaProgram> computeDelta() {
    if (_isComputeDeltaExecuting) {
      throw new StateError(MSG_PENDING_COMPUTE);
    }

    if (_lastSignatures != null) {
      throw new StateError(MSG_HAS_LAST_DELTA);
    }
    _lastSignatures = {};

    _isComputeDeltaExecuting = true;

    return _runWithFrontEndContext('Compute delta', () async {
      try {
        await _refreshInvalidatedFiles();
        _testView.compiledUris.clear();

        // Ensure that the graph starting at the entry point is ready.
        await _logger.runAsync('Build graph of files', () async {
          return await _fsState.getFile(_entryPoint);
        });

        // The file graph might have changed, perform GC.
        await _gc();

        DillTarget dillTarget = new DillTarget(
            new Ticker(isVerbose: false), uriTranslator, options.target);

        // Compile just libraries with changes to function bodies, or
        // compile multiple libraries because of API changes.
        if (_changedLibrariesWithSameApi.isNotEmpty) {
          await _logger.runAsync('Compile libraries with body changes',
              () async {
            await _compileLibrariesWithBodyChanges(dillTarget);
          });
        } else {
          // Append all libraries what we still have in the current program.
          var dillCount = _program.libraries.length;
          await _logger.runAsync('Load $dillCount dill libraries', () async {
            dillTarget.loader.appendLibraries(_program);
            await dillTarget.buildOutlines();
          });

          // Configure KernelTarget to compile the entry point.
          var kernelTarget =
              new KernelTarget(_fileSystem, false, dillTarget, uriTranslator);
          kernelTarget.read(_entryPoint);

          // Compile the entry point.
          await _logger.runAsync('Compile', () async {
            await kernelTarget.buildOutlines(nameRoot: _program.root);
            _program = await kernelTarget.buildProgram() ?? _program;
          });
          _program.computeCanonicalNames();

          _logger.run('Compute dependencies', _computeDependencies);
        }

        _logger.run('Index references', () {
          _referenceIndex.indexNewLibraries(_program);
        });

        // Prepare libraries that changed relatively to the current state.
        var newLibraries = new Set<String>();
        for (var library in _program.libraries) {
          var uri = library.importUri;
          var file = _fsState.getFileOrNull(uri);
          if (file != null && _currentSignatures[uri] != file.signatureStr) {
            newLibraries.add(library.fileUri);
            _lastSignatures[uri] = file.signatureStr;
            _testView.compiledUris.add(uri);
          }
        }

        // The set of affected library cycles (have different signatures),
        // or libraries that import or export affected libraries (so VM might
        // have inlined some code from affected libraries into them).
        final vmRequiredLibraries = new Set<String>();

        void gatherVmRequiredLibraries(String libraryUri) {
          if (vmRequiredLibraries.add(libraryUri)) {
            var directUsers = _directLibraryDependencies[libraryUri];
            directUsers?.forEach(gatherVmRequiredLibraries);
          }
        }

        newLibraries.forEach(gatherVmRequiredLibraries);

        // Compose the resulting program with new libraries.
        var program = new Program(nameRoot: _program.root);
        for (var library in _program.libraries) {
          if (_sdkOutlineBytes != null && library.importUri.isScheme('dart')) {
            continue;
          }
          if (vmRequiredLibraries.contains(library.fileUri)) {
            program.uriToSource[library.fileUri] =
                _program.uriToSource[library.fileUri];
            for (var part in library.parts) {
              program.uriToSource[part.fileUri] =
                  _program.uriToSource[part.fileUri];
            }
            program.libraries.add(library);
            library.parent = program;
          }
        }
        program.mainMethod = _program.mainMethod;
        _logger.writeln('Returning ${_lastSignatures.length} libraries.');

        var stateString = _ExternalState.asString(_lastSignatures);
        return new DeltaProgram(stateString, program);
      } finally {
        _isComputeDeltaExecuting = false;
      }
    });
  }

  @override
  void invalidate(Uri uri) {
    _invalidatedFiles.add(uri);
  }

  @override
  void rejectLastDelta() {
    _throwIfNoLastDelta();
    _lastSignatures = null;
  }

  @override
  void reset() {
    _currentSignatures.clear();
    _lastSignatures = null;
  }

  @override
  void setState(String state) {
    if (_isComputeDeltaExecuting) {
      throw new StateError(MSG_PENDING_COMPUTE);
    }
    var signatures = _ExternalState.fromString(state);
    _currentSignatures.clear();
    _currentSignatures.addAll(signatures);
  }

  /// The [_program] is almost valid, there are [_changedLibrariesWithSameApi]
  /// which should be recompiled, but all other libraries are fine.
  ///
  /// Compile the changed libraries and update referenced in other libraries.
  Future<Null> _compileLibrariesWithBodyChanges(DillTarget dillTarget) async {
    await _logger.runAsync('Append dill libraries', () async {
      dillTarget.loader.appendLibraries(_program);
      await dillTarget.buildOutlines();
    });

    if (_changedLibrariesWithSameApi.isNotEmpty) {
      var kernelTarget =
          new KernelTarget(_fileSystem, false, dillTarget, uriTranslator);

      // Schedule URIs of changed libraries for compilation.
      for (var changedLibrary in _changedLibrariesWithSameApi) {
        _testView.compiledUris.add(changedLibrary.uri);
        // Detach the old library.
        var oldLibrary = _uriToLibrary[changedLibrary.fileUriStr];
        _program.root.removeChild(changedLibrary.uriStr);
        _program.libraries.remove(oldLibrary);
        _referenceIndex.removeLibrary(oldLibrary);
        // We finished loading outlines, including additional exports.
        // So, we don't need changed libraries anymore.
        // Remove them from DillLoader so that they are recompiled.
        dillTarget.loader.builders.remove(changedLibrary.uri);
        dillTarget.loader.libraries.remove(oldLibrary);
        // Schedule the library for compilation.
        kernelTarget.read(changedLibrary.uri);
      }

      var mainReference = _program.mainMethodName;
      await _logger.runAsync('Compile', () async {
        await kernelTarget.buildOutlines(nameRoot: _program.root);
        await kernelTarget.buildProgram();
      });

      // Attach the new library and replace references.
      _logger.run('Replace references', () {
        var builders = kernelTarget.loader.builders;
        for (var changedLibrary in _changedLibrariesWithSameApi) {
          Library oldLibrary = _uriToLibrary[changedLibrary.fileUriStr];
          Library newLibrary = builders[changedLibrary.uri].target;

          _program.root
              .getChildFromUri(newLibrary.importUri)
              .bindTo(newLibrary.reference);
          newLibrary.computeCanonicalNames();

          _program.root.adoptChild(newLibrary.canonicalName);
          _program.libraries.add(newLibrary);

          _uriToLibrary[changedLibrary.fileUriStr] = newLibrary;
          _referenceIndex.replaceLibrary(oldLibrary, newLibrary);

          // If main() was defined in the recompiled library, replace it.
          if (mainReference?.asProcedure?.enclosingLibrary == oldLibrary) {
            mainReference = newLibrary.procedures
                .singleWhere((p) => p.name.name == 'main')
                .reference;
          }
        }
      });

      // Restore the main() procedure reference.
      _program.mainMethodName = mainReference;
    }
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

    var entryPointLibrary =
        _program.libraries.singleWhere((lib) => lib.importUri == _entryPoint);
    processLibrary(entryPointLibrary);
  }

  /// Compute salt and put into [_salt].
  void _computeSalt() {
    var saltBuilder = new ApiSignature();
    saltBuilder.addInt(DATA_VERSION);
    saltBuilder.addBool(options.strongMode);
    if (_sdkOutlineBytes != null) {
      saltBuilder.addBytes(_sdkOutlineBytes);
    }
    _salt = saltBuilder.toByteList();
  }

  /// Find files which are not referenced from the entry point and report
  /// them to the watch function.
  Future<Null> _gc() async {
    List<FileState> removedFiles = _fsState.gc(_entryPoint);
    if (removedFiles.isNotEmpty && _watchFn != null) {
      for (var removedFile in removedFiles) {
        // If a library, remove it from the program.
        Library library = _uriToLibrary.remove(removedFile.fileUriStr);
        if (library != null) {
          _currentSignatures.remove(library.importUri);
          _program.libraries.remove(library);
          _program.root.removeChild(library.importUri.toString());
          _program.uriToSource.remove(library.fileUri);
          for (var part in library.parts) {
            _program.uriToSource.remove(part.fileUri);
          }
        }
        // Notify the client.
        await _watchFn(removedFile.fileUri, false);
      }
    }
  }

  /// If SDK outline bytes are provided, load it and configure the file system
  /// state to skip SDK library files.
  void _loadSdkOutline() {
    if (_sdkOutlineBytes != null) {
      _logger.run('Load SDK outline from bytes', () {
        loadProgramFromBytes(_sdkOutlineBytes, _program);
        // Configure the file system state to skip the outline libraries.
        for (var outlineLibrary in _program.libraries) {
          _fsState.skipSdkLibraries.add(outlineLibrary.importUri);
        }
      });
    }
  }

  /// Refresh all the invalidated files and update dependencies.
  Future<Null> _refreshInvalidatedFiles() async {
    await _logger.runAsync('Refresh invalidated files', () async {
      // Replace the list to avoid concurrent modifications.
      List<Uri> invalidatedFiles = _invalidatedFiles;
      _invalidatedFiles = <Uri>[];

      // Refresh the files.
      _changedLibrariesWithSameApi.clear();
      var filesWithDifferentApiSignature = <FileState>[];
      for (var fileUri in invalidatedFiles) {
        var file = _fsState.getFileByFileUri(fileUri);
        if (file != null) {
          _logger.writeln('Refresh $fileUri');
          bool apiSignatureChanged = await file.refresh();
          if (apiSignatureChanged) {
            filesWithDifferentApiSignature.add(file);
          } else {
            FileState libraryFile = file;
            String libraryFileUriStr = _partToLibrary[file.fileUriStr];
            if (libraryFileUriStr != null) {
              var libraryFileUri = Uri.parse(libraryFileUriStr);
              libraryFile = _fsState.getFileByFileUri(libraryFileUri);
            }
            _changedLibrariesWithSameApi.add(libraryFile);
          }
        }
      }

      if (filesWithDifferentApiSignature.isNotEmpty) {
        _logger.writeln('API changed in $filesWithDifferentApiSignature.');
        _changedLibrariesWithSameApi.clear();

        /// Invalidate the library with the given [libraryUri],
        /// and recursively all its clients.
        void invalidateLibrary(String libraryUri) {
          Library library = _uriToLibrary.remove(libraryUri);
          if (library == null) return;

          // Invalidate the library.
          _program.libraries.remove(library);
          _program.root.removeChild(library.importUri.toString());
          _program.uriToSource.remove(libraryUri);
          _currentSignatures.remove(library.importUri);
          _referenceIndex.removeLibrary(library);

          // Recursively invalidate clients.
          Set<String> directDependencies =
              _directLibraryDependencies.remove(libraryUri);
          directDependencies?.forEach(invalidateLibrary);
        }

        // TODO(scheglov): Some changes still might be incremental.
        for (var uri in invalidatedFiles) {
          String uriStr = uri.toString();
          String libraryUri = _partToLibrary.remove(uriStr) ?? uriStr;
          invalidateLibrary(libraryUri);
        }
      }
    });
  }

  Future<T> _runWithFrontEndContext<T>(String msg, Future<T> f()) async {
    return await CompilerContext.runWithOptions(options, (context) {
      context.disableColors();
      return _logger.runAsync(msg, f);
    });
  }

  /// Throw [StateError] if [_lastSignatures] is `null`, i.e. there is no
  /// last delta - it either has not been computed yet, or has been already
  /// accepted or rejected.
  void _throwIfNoLastDelta() {
    if (_isComputeDeltaExecuting) {
      throw new StateError(MSG_PENDING_COMPUTE);
    }
    if (_lastSignatures == null) {
      throw new StateError(MSG_NO_LAST_DELTA);
    }
  }
}

class _ExternalState {
  /// Return the JSON encoding of the [signatures].
  static String asString(Map<Uri, String> signatures) {
    var json = <String, String>{};
    signatures.forEach((uri, signature) {
      json[uri.toString()] = signature;
    });
    return JSON.encode(json);
  }

  /// Decode the given JSON [state] into the program state.
  static Map<Uri, String> fromString(String state) {
    var signatures = <Uri, String>{};
    Map<String, String> json = JSON.decode(state);
    json.forEach((uriStr, signature) {
      var uri = Uri.parse(uriStr);
      signatures[uri] = signature;
    });
    return signatures;
  }
}

@visibleForTesting
class _TestView {
  /// The list of [Uri]s compiled for the last delta.
  /// It does not include libraries which were reused from the last program.
  final Set<Uri> compiledUris = new Set<Uri>();
}
