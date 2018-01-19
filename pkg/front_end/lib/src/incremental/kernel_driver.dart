// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/api_prototype/compilation_message.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/metadata_collector.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';
import 'package:meta/meta.dart';

/// This function is invoked for each newly discovered file, and the returned
/// [Future] is awaited before reading the file content.
typedef Future<Null> KernelDriverFileAddedFn(Uri uri);

/// This function is invoked to create a new instance of [KernelTarget],
/// which might be a backend specific subclass.
typedef KernelTarget KernelTargetFactory(FileSystem fileSystem,
    bool includeComments, DillTarget dillTarget, UriTranslator uriTranslator,
    {MetadataCollector metadataCollector});

/// This class computes [KernelSequenceResult]s for Dart files.
///
/// Let the "current file state" represent a map from file URI to the file
/// contents most recently read from that file. When the driver needs to
/// access a file that is not in the current file state yet, it will call
/// the optional "file added" function, read the file and put it into the
/// current file state.
///
/// The client invokes [getKernelSequence] to schedule computing the
/// [KernelSequenceResult] for a Dart file. The driver will eventually use the
/// current file state of the specified file and all files that it transitively
/// depends on to compute corresponding kernel files (or read them from the
/// [ByteStore]).
///
/// If the client is interested only in the full library for a single Dart
/// file, it should use [getKernel] instead. This will allow the driver to
/// compute only single fully resolved library (or the cycle it belongs to),
/// and provide just outlines of other libraries.
///
/// A call to [invalidate] removes the specified file from the current file
/// state, so that it will be reread before any following [getKernel] or
/// [getKernelSequence] will return a result.
class KernelDriver {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 2;

  /// Options used by the kernel compiler.
  final ProcessedOptions _options;

  /// The optional SDK outline as a serialized program.
  /// If provided, the driver will not attempt to read SDK files.
  final List<int> _sdkOutlineBytes;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The [FileSystem] which should be used by the front end to access files.
  final FileSystem _fileSystem;

  /// The byte storage to get and put serialized data.
  final ByteStore _byteStore;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final UriTranslator uriTranslator;

  /// The function that is invoked when a new file is about to be added to
  /// the current file state. The [Future] that it returns is awaited before
  /// reading the file contents.
  final KernelDriverFileAddedFn _fileAddedFn;

  /// Factory for working with metadata.
  final MetadataFactory _metadataFactory;

  /// The listener to errors during kernel compilation.
  final KernelErrorListener kernelErrorListener;

  /// The optional SDK outline loaded from [_sdkOutlineBytes].
  /// Might be `null` if the bytes are not provided, or if not loaded yet.
  Program _sdkOutline;

  /// The salt to mix into all hashes used as keys for serialized data.
  List<int> _salt;

  /// The current file system state.
  FileSystemState _fsState;

  /// The set of absolute file URIs that were reported through [invalidate]
  /// and not checked for actual changes yet.
  final Set<Uri> _invalidatedFiles = new Set<Uri>();

  /// The object that provides additional information for tests.
  final _TestView _testView = new _TestView();

  KernelDriver(this._options, this.uriTranslator, this.kernelErrorListener,
      {List<int> sdkOutlineBytes,
      KernelDriverFileAddedFn fileAddedFn,
      MetadataFactory metadataFactory})
      : _logger = _options.logger,
        _fileSystem = _options.fileSystem,
        _byteStore = _options.byteStore,
        _sdkOutlineBytes = sdkOutlineBytes,
        _fileAddedFn = fileAddedFn,
        _metadataFactory = metadataFactory {
    _computeSalt();

    Future<Null> onFileAdded(Uri uri) {
      if (_fileAddedFn != null) {
        return _fileAddedFn(uri);
      }
      return new Future.value();
    }

    _fsState = new FileSystemState(_byteStore, _fileSystem, _options.target,
        uriTranslator, _salt, onFileAdded);
  }

  /// Return the [FileSystemState] that contains the current file state.
  FileSystemState get fsState => _fsState;

  /// Return the object that provides additional information for tests.
  @visibleForTesting
  _TestView get test => _testView;

  /// Compile the library with the given [uri] using the [KernelTarget] that
  /// is returned by the [kernelTargetFactory].
  ///
  /// TODO(scheglov) I think we don't need the return, or most of it.
  Future<KernelSequenceResult> compileLibrary(
      KernelTargetFactory kernelTargetFactory, Uri uri) async {
    return await runWithFrontEndContext('Compile library $uri', () async {
      await _refreshInvalidatedFiles();

      CanonicalName nameRoot = new CanonicalName.root();

      // Load the SDK outline before building the graph, so that the file
      // system state is configured to skip SDK libraries.
      await _loadSdkOutline();
      if (_sdkOutline != null) {
        for (var library in _sdkOutline.libraries) {
          nameRoot.adoptChild(library.canonicalName);
        }
      }

      // Ensure that the graph starting at the entry point is ready.
      FileState entryLibrary =
          await _logger.runAsync('Build graph of files', () async {
        return await _fsState.getFile(uri);
      });

      List<LibraryCycle> cycles = _logger.run('Compute library cycles', () {
        List<LibraryCycle> cycles = entryLibrary.topologicalOrder;
        _logger.writeln('Computed ${cycles.length} cycles.');
        return cycles;
      });

      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false), uriTranslator, _options.target);

      // If there is SDK outline, load it.
      if (_sdkOutline != null) {
        dillTarget.loader.appendLibraries(_sdkOutline);
        await dillTarget.buildOutlines();
      }

      List<LibraryCycleResult> results = [];

      // Even if we don't compile SDK libraries, add them to results.
      // We need to be able to access dart:core and dart:async classes.
      if (_sdkOutline != null) {
        results.add(new LibraryCycleResult(
            new LibraryCycle(),
            '<sdk>',
            {},
            _sdkOutline.libraries
                // TODO are there errors to report here?
                .map((l) => new LibraryResult(l, []))
                .toList()));
      }

      var lastCycle = cycles.last;

      // Compute results for all, but the very last cycle. We need just
      // outlines for these cycles, to be able to compile the last one.
      _testView.compiledCycles.clear();
      await _logger.runAsync('Compute results for cycles', () async {
        for (LibraryCycle cycle in cycles) {
          if (cycle == lastCycle) {
            break;
          }
          LibraryCycleResult result =
              await _compileCycle(nameRoot, dillTarget, cycle, null);
          results.add(result);
        }
      });

      // Compile the last cycle using the given KernelTargetFactory.
      LibraryCycleResult lastResult = await _compileCycle(
          nameRoot, dillTarget, lastCycle, kernelTargetFactory);
      results.add(lastResult);

      TypeEnvironment types = _buildTypeEnvironment(nameRoot, results);

      return new KernelSequenceResult(nameRoot, types, results);
    });
  }

  /// Return the [KernelResult] for the Dart file with the given [uri].
  ///
  /// The [uri] must be absolute and normalized.
  ///
  /// The driver will update the current file state for any file previously
  /// reported using [invalidate].
  ///
  /// If the driver has cached results for the file and its dependencies for
  /// the current file state, these cached results are returned.
  ///
  /// Otherwise the driver will compute new results and return them.
  Future<KernelResult> getKernel(Uri uri) async {
    // TODO(scheglov): Use IKG-like implementation with full program in memory.
    KernelSequenceResult sequence = await getKernelSequence(uri);

    var dependencies = <Library>[];
    LibraryResult requestedLibrary;
    for (var i = 0; i < sequence.results.length; i++) {
      List<LibraryResult> libraryResults = sequence.results[i].libraryResults;
      if (i == sequence.results.length - 1) {
        for (var libraryResult in libraryResults) {
          if (libraryResult.library.importUri == uri) {
            requestedLibrary = libraryResult;
          } else {
            dependencies.add(libraryResult.library);
          }
        }
      } else {
        dependencies.addAll(libraryResults.map((l) => l.library));
      }
    }

    return new KernelResult(dependencies, sequence.types, requestedLibrary);
  }

  /// Return the [KernelSequenceResult] for the Dart file with the given [uri].
  ///
  /// The [uri] must be absolute and normalized.
  ///
  /// The driver will update the current file state for any file previously
  /// reported using [invalidate].
  ///
  /// If the driver has cached results for the file and its dependencies for
  /// the current file state, these cached results are returned.
  ///
  /// Otherwise the driver will compute new results and return them.
  Future<KernelSequenceResult> getKernelSequence(Uri uri) async {
    return await runWithFrontEndContext('Compute kernels', () async {
      await _refreshInvalidatedFiles();

      CanonicalName nameRoot = new CanonicalName.root();

      // Load the SDK outline before building the graph, so that the file
      // system state is configured to skip SDK libraries.
      await _loadSdkOutline();
      if (_sdkOutline != null) {
        for (var library in _sdkOutline.libraries) {
          nameRoot.adoptChild(library.canonicalName);
        }
      }

      // Ensure that the graph starting at the entry point is ready.
      FileState entryLibrary =
          await _logger.runAsync('Build graph of files', () async {
        return await _fsState.getFile(uri);
      });

      List<LibraryCycle> cycles;
      if (_fsState.skipSdkLibraries.contains(uri)) {
        cycles = <LibraryCycle>[];
      } else {
        cycles = _logger.run('Compute library cycles', () {
          List<LibraryCycle> cycles = entryLibrary.topologicalOrder;
          _logger.writeln('Computed ${cycles.length} cycles.');
          return cycles;
        });
      }

      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false), uriTranslator, _options.target);

      // If there is SDK outline, load it.
      if (_sdkOutline != null) {
        dillTarget.loader.appendLibraries(_sdkOutline);
        await dillTarget.buildOutlines();
      }

      List<LibraryCycleResult> results = [];

      // Even if we don't compile SDK libraries, add them to results.
      // We need to be able to access dart:core and dart:async classes.
      if (_sdkOutline != null) {
        results.add(new LibraryCycleResult(
            new LibraryCycle(),
            '<sdk>',
            {},
            _sdkOutline.libraries
                // TODO are there errors to report here?
                .map((l) => new LibraryResult(l, []))
                .toList()));
      }

      _testView.compiledCycles.clear();
      await _logger.runAsync('Compute results for cycles', () async {
        for (LibraryCycle cycle in cycles) {
          LibraryCycleResult result =
              await _compileCycle(nameRoot, dillTarget, cycle, null);
          results.add(result);
        }
      });

      TypeEnvironment types = _buildTypeEnvironment(nameRoot, results);

      return new KernelSequenceResult(nameRoot, types, results);
    });
  }

  /// The file with the given [uri] might have changed - updated, added, or
  /// removed. Or not, we don't know. Or it might have, but then changed back.
  ///
  /// The [uri] must be absolute and normalized file URI.
  ///
  /// Schedules the file contents for the [uri] to be read into the current
  /// file state prior the next invocation of [getKernel] or
  /// [getKernelSequence] returns the result.
  ///
  /// Invocation of this method will not prevent a [Future] returned from
  /// [getKernelSequence] from completing with a result, but the result is not
  /// guaranteed to be consistent with the new current file state after this
  /// [invalidate] invocation.
  void invalidate(Uri uri) {
    _invalidatedFiles.add(uri);
  }

  Future<T> runWithFrontEndContext<T>(String msg, Future<T> f()) async {
    return await CompilerContext.runWithOptions(_options, (context) {
      context.disableColors();
      return _logger.runAsync(msg, f);
    });
  }

  /// Return the [TypeEnvironment] that corresponds to the [results].
  /// All the libraries for [CoreTypes] are expected to be in the first result.
  TypeEnvironment _buildTypeEnvironment(
      CanonicalName nameRoot, List<LibraryCycleResult> results) {
    var coreLibraries =
        results.first.libraryResults.map((l) => l.library).toList();
    var program = new Program(nameRoot: nameRoot, libraries: coreLibraries);
    return new TypeEnvironment(
        new CoreTypes(program), new ClassHierarchy(program));
  }

  /// Ensure that [dillTarget] includes the [cycle] libraries.  It already
  /// contains all the libraries that sorted before the given [cycle] in
  /// topological order.  Return the result with the cycle libraries.
  Future<LibraryCycleResult> _compileCycle(
      CanonicalName nameRoot,
      DillTarget dillTarget,
      LibraryCycle cycle,
      KernelTargetFactory kernelTargetFactory) async {
    return _logger.runAsync('Compile cycle $cycle', () async {
      String signature = _getCycleSignature(cycle);

      _logger.writeln('Signature: $signature.');
      var kernelKey = '$signature.kernel';

      // We need kernel libraries for these URIs.
      var libraryUris = new Set<Uri>();
      var libraryUriToFile = <Uri, FileState>{};
      for (FileState library in cycle.libraries) {
        Uri uri = library.uri;
        libraryUris.add(uri);
        libraryUriToFile[uri] = library;
      }

      // Prepare file URIs for the cycle.
      var cycleFileUris = new Set<Uri>();
      for (FileState library in cycle.libraries) {
        cycleFileUris.add(library.fileUri);
        for (var partFile in library.partFiles) {
          cycleFileUris.add(partFile.fileUri);
        }
      }

      Future<Null> appendNewDillLibraries(Program program) async {
        dillTarget.loader
            .appendLibraries(program, filter: libraryUris.contains);
        await dillTarget.buildOutlines();
      }

      // Check if there is already a bundle with these libraries.
      if (kernelTargetFactory == null) {
        kernelTargetFactory = _defaultKernelTargetFactory;
        List<int> bytes = _byteStore.get(kernelKey);
        if (bytes != null) {
          return _logger.runAsync('Read serialized libraries', () async {
            var program = new Program(nameRoot: nameRoot);
            _readProgram(program, bytes);
            await appendNewDillLibraries(program);

            return new LibraryCycleResult(
                cycle,
                signature,
                program.uriToSource,
                program.libraries
                    // TODO report errors here
                    .map((l) => new LibraryResult(l, []))
                    .toList());
          });
        }
      }

      // Create KernelTarget and configure it for compiling the cycle URIs.
      KernelTarget kernelTarget = kernelTargetFactory(
          _fsState.fileSystemView, true, dillTarget, uriTranslator,
          metadataCollector: _metadataFactory?.newCollector());
      for (FileState library in cycle.libraries) {
        kernelTarget.read(library.uri);
      }

      // Compile the cycle libraries into a new full program.
      Program program = await _logger
          .runAsync('Compile ${cycle.libraries.length} libraries', () async {
        await kernelTarget.buildOutlines(nameRoot: nameRoot);
        return await kernelTarget.buildProgram();
      });

      _testView.compiledCycles.add(cycle);

      // Add newly compiled libraries into DILL.
      await appendNewDillLibraries(program);

      List<Library> kernelLibraries = program.libraries
          .where((library) => libraryUris.contains(library.importUri))
          .toList();

      final indexedErrors = <Uri, List<CompilationMessage>>{};
      kernelErrorListener.errors.forEach((error) =>
          indexedErrors.putIfAbsent(error.span.sourceUrl, () => []).add(error));
      List<LibraryResult> kernelLibrariesResults = kernelLibraries
          .map((l) => new LibraryResult(l, indexedErrors[l.fileUri]))
          .toList();

      kernelErrorListener.errors.clear();

      // Remove source for libraries outside of the cycle.
      {
        var urisToRemoveSources = <Uri>[];
        for (var uri in program.uriToSource.keys) {
          if (!cycleFileUris.contains(uri)) {
            urisToRemoveSources.add(uri);
          }
        }
        urisToRemoveSources.forEach(program.uriToSource.remove);
      }

      _logger.run('Serialize ${kernelLibraries.length} libraries', () {
        List<int> bytes =
            serializeProgram(program, filter: kernelLibraries.contains);
        _byteStore.put(kernelKey, bytes);
        _logger.writeln('Stored ${bytes.length} bytes.');
      });

      return new LibraryCycleResult(
          cycle, signature, program.uriToSource, kernelLibrariesResults);
    });
  }

  /// Compute salt and put into [_salt].
  void _computeSalt() {
    var saltBuilder = new ApiSignature();
    saltBuilder.addInt(DATA_VERSION);
    saltBuilder.addBool(_options.strongMode);
    if (_sdkOutlineBytes != null) {
      saltBuilder.addBytes(_sdkOutlineBytes);
    }
    if (_metadataFactory != null) {
      saltBuilder.addInt(_metadataFactory.version);
    }
    _salt = saltBuilder.toByteList();
  }

  String _getCycleSignature(LibraryCycle cycle) {
    bool hasMixinApplication =
        cycle.libraries.any((library) => library.hasMixinApplicationLibrary);
    var signatureBuilder = new ApiSignature();
    signatureBuilder.addBytes(_salt);
    Set<FileState> transitiveFiles = cycle.libraries
        .map((library) => library.transitiveFiles)
        .expand((files) => files)
        .toSet();
    signatureBuilder.addInt(transitiveFiles.length);

    // Append API signatures of transitive files.
    for (var file in transitiveFiles) {
      signatureBuilder.addBytes(file.uriBytes);
      // TODO(scheglov): Stop using content hashes here, when Kernel stops
      // copying methods of mixed-in classes.
      // https://github.com/dart-lang/sdk/issues/29881
      if (hasMixinApplication) {
        signatureBuilder.addBytes(file.contentHash);
      } else {
        signatureBuilder.addBytes(file.apiSignature);
      }
    }

    // Append content hashes of the cycle files.
    for (var library in cycle.libraries) {
      signatureBuilder.addBytes(library.contentHash);
      for (var part in library.partFiles) {
        signatureBuilder.addBytes(part.contentHash);
      }
    }

    return signatureBuilder.toHex();
  }

  /// If SDK outline bytes are provided, and it is not loaded yet into
  /// [_sdkOutline], load it and configure the file system state to skip SDK
  /// library files.
  Future<Null> _loadSdkOutline() async {
    if (_sdkOutlineBytes != null && _sdkOutline == null) {
      await _logger.runAsync('Load SDK outline from bytes', () async {
        _sdkOutline = loadProgramFromBytes(_sdkOutlineBytes);
        // Configure the file system state to skip the outline libraries.
        for (var outlineLibrary in _sdkOutline.libraries) {
          _fsState.skipSdkLibraries.add(outlineLibrary.importUri);
        }
      });
    }
  }

  /// Read libraries from the given [bytes] into the [program], using the
  /// configured metadata factory.  The [program] must be ready to read these
  /// libraries, i.e. either the [bytes] represent a full program with all
  /// dependencies, or the [program] already has all required dependencies.
  void _readProgram(Program program, List<int> bytes) {
    if (_metadataFactory != null) {
      var repository = _metadataFactory.newRepositoryForReading();
      program.addMetadataRepository(repository);
      new BinaryBuilderWithMetadata(bytes).readSingleFileProgram(program);
    } else {
      new BinaryBuilder(bytes).readProgram(program);
    }
  }

  /// Refresh all the invalidated files and update dependencies.
  Future<Null> _refreshInvalidatedFiles() async {
    await _logger.runAsync('Refresh invalidated files', () async {
      // Create a copy to avoid concurrent modifications.
      var invalidatedFiles = _invalidatedFiles.toList();
      _invalidatedFiles.clear();

      // Refresh the files.
      for (var fileUri in invalidatedFiles) {
        var file = _fsState.getFileByFileUri(fileUri);
        if (file != null) {
          _logger.writeln('Refresh $fileUri');
          await file.refresh();
        }
      }
    });
  }

  /// The default [KernelTargetFactory], that creates [KernelTarget].
  static KernelTarget _defaultKernelTargetFactory(FileSystem fileSystem,
      bool includeComments, DillTarget dillTarget, UriTranslator uriTranslator,
      {Map<String, Source> uriToSource, MetadataCollector metadataCollector}) {
    return new KernelTarget(
        fileSystem, includeComments, dillTarget, uriTranslator,
        metadataCollector: metadataCollector);
  }
}

/// The result of compiling of a single file.
class KernelResult {
  /// The dependencies of the [library].
  /// Most of them are shaken outlines, but some might be full libraries.
  final List<Library> dependencies;

  /// The [TypeEnvironment] based on the SDK library outlines.
  final TypeEnvironment types;

  /// The library of the requested file.
  final LibraryResult libraryResult;

  KernelResult(this.dependencies, this.types, this.libraryResult);
}

/// The result of compiling of a sequence of libraries.
class KernelSequenceResult {
  final CanonicalName nameRoot;
  final TypeEnvironment types;
  final List<LibraryCycleResult> results;

  KernelSequenceResult(this.nameRoot, this.types, this.results);
}

/// Compilation result for a library cycle.
class LibraryCycleResult {
  final LibraryCycle cycle;

  /// The signature of the result.
  ///
  /// It is based on the full content of the libraries in the [cycle], and
  /// either API signatures of the transitive dependencies (usually), or
  /// the full content of them (in the [cycle] has a library with a mixin
  /// application).
  final String signature;

  /// Map from the [cycle] file URIs to their [Source]s.
  final Map<Uri, Source> uriToSource;

  /// Kernel libraries for libraries in the [cycle].  Bodies of dependencies
  /// are not included, but but references to those dependencies are included.
  final List<LibraryResult> libraryResults;

  LibraryCycleResult(
      this.cycle, this.signature, this.uriToSource, this.libraryResults);
}

/// A [Library] produced by front end and the errors produced from compiling it.
class LibraryResult {
  final Library library;
  final List<CompilationMessage> errors;

  LibraryResult(this.library, this.errors);
}

/// Factory for creating [MetadataCollector]s and [MetadataRepository]s.
abstract class MetadataFactory {
  /// This version is mixed into the signatures of cached compilation result,
  /// because content of these results depends on whether we write additional
  /// metadata or not.
  int get version;

  /// Return a new [MetadataCollector] to write metadata to while compiling a
  /// new library cycle.
  MetadataCollector newCollector();

  /// Return a new [MetadataRepository] instance to read metadata while
  /// reading a [Program] for a library cycle.
  MetadataRepository newRepositoryForReading();
}

@visibleForTesting
class _TestView {
  /// The list of [LibraryCycle]s compiled for the last delta.
  /// It does not include libraries which were read from the cache.
  final List<LibraryCycle> compiledCycles = [];
}

/// A simple errors listener for [CompilationMessage]s from kernel.
class KernelErrorListener {
  final List<CompilationMessage> errors = [];
  void onError(CompilationMessage error) => errors.add(error);
}
