// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:convert/convert.dart';
import 'package:front_end/byte_store.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_outline_shaker.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/metadata_collector.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/incremental/combine.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:kernel/type_environment.dart';
import 'package:meta/meta.dart';

/// This function is invoked for each newly discovered file, and the returned
/// [Future] is awaited before reading the file content.
typedef Future<Null> KernelDriverFileAddedFn(Uri uri);

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
  static const int DATA_VERSION = 1;

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

  KernelDriver(this._options, this.uriTranslator,
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
    return await runWithFrontEndContext('Compute kernel', () async {
      await _refreshInvalidatedFiles();

      // Load the SDK outline before building the graph, so that the file
      // system state is configured to skip SDK libraries.
      await _loadSdkOutline();

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

      LibraryCycle cycle = cycles.last;
      await _compileCycle2(cycle, needsKernelBytesForDependencies: false);

      // Read kernel bytes into the program with combined dependencies.
      Program program;
      {
        CombineResult combined = _combineDirectDependencyOutlines(cycle);
        program = combined.program;
        try {
          _readProgram(program, cycle.kernelBytes);
        } finally {
          combined.undo();
        }
      }

      List<Library> dependencies = <Library>[];
      Library requestedLibrary;
      for (var library in program.libraries) {
        if (library.importUri == uri) {
          requestedLibrary = library;
        } else {
          dependencies.add(library);
        }
      }

      // Even if we don't compile SDK libraries, add them to results.
      // We need to be able to access dart:core and dart:async classes.
      if (_sdkOutline != null) {
        for (var library in _sdkOutline.libraries) {
          var uriStr = library.importUri.toString();
          if (uriStr == 'dart:core' || uriStr == 'dart:async') {
            dependencies.add(library);
          }
        }
      }

      return new KernelResult(dependencies, null, requestedLibrary);
    });
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
            new LibraryCycle(), '<sdk>', {}, _sdkOutline.libraries));
      }

      _testView.compiledCycles.clear();
      await _logger.runAsync('Compute results for cycles', () async {
        for (LibraryCycle cycle in cycles) {
          LibraryCycleResult result =
              await _compileCycle(nameRoot, dillTarget, cycle);
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
    var coreLibraries = results.first.kernelLibraries;
    var program = new Program(nameRoot: nameRoot, libraries: coreLibraries);
    return new TypeEnvironment(
        new CoreTypes(program), new IncrementalClassHierarchy());
  }

  CombineResult _combineDirectDependencyOutlines(LibraryCycle cycle) {
    var outlines = cycle.directDependencies.map((c) => c.outline).toList();
    return combine(outlines);
  }

  /// Ensure that [dillTarget] includes the [cycle] libraries.  It already
  /// contains all the libraries that sorted before the given [cycle] in
  /// topological order.  Return the result with the cycle libraries.
  Future<LibraryCycleResult> _compileCycle(
      CanonicalName nameRoot, DillTarget dillTarget, LibraryCycle cycle) async {
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
      var cycleFileUris = new Set<String>();
      for (FileState library in cycle.libraries) {
        cycleFileUris.add(library.fileUriStr);
        for (var partFile in library.partFiles) {
          cycleFileUris.add(partFile.fileUriStr);
        }
      }

      Future<Null> appendNewDillLibraries(Program program) async {
        dillTarget.loader.appendLibraries(program, libraryUris.contains);
        await dillTarget.buildOutlines();
      }

      // Check if there is already a bundle with these libraries.
      List<int> bytes = _byteStore.get(kernelKey);
      if (bytes != null) {
        return _logger.runAsync('Read serialized libraries', () async {
          var program = new Program(nameRoot: nameRoot);
          _readProgram(program, bytes);
          await appendNewDillLibraries(program);

          return new LibraryCycleResult(
              cycle, signature, program.uriToSource, program.libraries);
        });
      }

      // Create KernelTarget and configure it for compiling the cycle URIs.
      KernelTarget kernelTarget = new KernelTarget(
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

      // Remove source for libraries outside of the cycle.
      {
        var urisToRemoveSources = <String>[];
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
          cycle, signature, program.uriToSource, kernelLibraries);
    });
  }

  /// Ensure that the given [cycle] has its outline, and, if [needsKernelBytes]
  /// the kernel bytes ready.  Direct dependencies of the [cycle] are processed
  /// first, recursively.
  ///
  /// TODO(scheglov) Rewrite [getKernelSequence] using this method too.
  Future<Null> _compileCycle2(LibraryCycle cycle,
      {bool needsKernelBytes: true,
      bool needsKernelBytesForDependencies: true}) async {
    // Nothing to do if the results have already been computed.
    if (cycle.outline != null) {
      if (!needsKernelBytes || cycle.kernelBytes != null) {
        return;
      }
    }

    // Compile direct dependencies.
    for (var dependency in cycle.directDependencies) {
      await _compileCycle2(dependency,
          needsKernelBytes: needsKernelBytesForDependencies,
          needsKernelBytesForDependencies: needsKernelBytesForDependencies);
    }

    await _logger.runAsync('Compile cycle $cycle', () async {
      // Compute the signature of the cycle.
      {
        var signatureBuilder = new ApiSignature();
        signatureBuilder.addBytes(_salt);

        // Append the direct dependencies.
        signatureBuilder.addInt(cycle.directDependencies.length);
        for (var dependency in cycle.directDependencies) {
          signatureBuilder.addBytes(dependency.outlineSignature);
        }

        // Append libraries in the cycle.
        signatureBuilder.addInt(cycle.libraries.length);
        for (var library in cycle.libraries) {
          signatureBuilder.addString(library.uriStr);
          signatureBuilder.addBytes(library.contentHash);
          signatureBuilder.addInt(1 + library.partFiles.length);
          for (var part in library.partFiles) {
            signatureBuilder.addBytes(part.contentHash);
          }
        }

        cycle.signature = signatureBuilder.toByteList();
      }

      String signatureHex = hex.encode(cycle.signature);
      _logger.writeln('Signature: $signatureHex.');

      var kernelKey = '$signatureHex.kernel';
      var outlineSignatureKey = '$signatureHex.outline_signature';

      // Get already existing outline signature, key, and outline.
      // There is many-to-one mapping from signatures to outline signatures.
      String outlineKey;
      {
        cycle.outlineSignature = _byteStore.get(outlineSignatureKey);
        if (cycle.outlineSignature != null) {
          outlineKey = hex.encode(cycle.outlineSignature) + '.outline';
          // TODO(scheglov): Load using the object cache.
          List<int> outlineBytes = _byteStore.get(outlineKey);
          if (outlineBytes != null) {
            _logger.writeln('Read ${outlineBytes.length} outline bytes.');
            cycle.outline = loadProgramFromBytes(outlineBytes);
          }
        }
      }

      // Get already existing kernel.
      if (needsKernelBytes) {
        List<int> kernelBytes = _byteStore.get(kernelKey);
        if (kernelBytes != null) {
          _logger.writeln('Read ${kernelBytes.length} kernel bytes.');
          cycle.kernelBytes = kernelBytes;
        }
      }

      // We're done if we found all required results in the cache.
      if (cycle.outline != null &&
          (!needsKernelBytes || cycle.kernelBytes != null)) {
        return;
      }

      CanonicalName nameRoot = new CanonicalName.root();
      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false), uriTranslator, _options.target);

      // Load the SDK outline before building the graph, so that the file
      // system state is configured to skip SDK libraries.
      await _loadSdkOutline();
      if (_sdkOutline != null) {
        dillTarget.loader.appendLibraries(_sdkOutline);
        await dillTarget.buildOutlines();
      }

      // We need kernel libraries for these URIs.
      var libraryUris = new Set<Uri>();
      for (FileState library in cycle.libraries) {
        Uri uri = library.uri;
        libraryUris.add(uri);
      }

      // Compile against combined outlines of direct dependencies.
      CombineResult combinedOutlines = _combineDirectDependencyOutlines(cycle);
      try {
        nameRoot = combinedOutlines.program.root;

        // Append outlines of direct dependencies.
        dillTarget.loader.appendLibraries(combinedOutlines.program);
        await dillTarget.buildOutlines();

        // Create KernelTarget and configure it for compiling the cycle URIs.
        KernelTarget kernelTarget = new KernelTarget(
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

        // Store the full kernel with libraries of this cycle.
        int numFullLibraries = libraryUris.length;
        _logger.run('Serialize kernel with $numFullLibraries libraries', () {
          List<int> kernelBytes = serializeProgram(program,
              filter: (library) => libraryUris.contains(library.importUri));
          cycle.kernelBytes = kernelBytes;
          _byteStore.put(kernelKey, kernelBytes);
          _logger.writeln('Stored ${kernelBytes.length} bytes.');
        });

        _logger.run('Serialize outline', () {
          var byteSink = new ByteSink();
          serializeTrimmedOutline(
              byteSink, program, (uri) => libraryUris.contains(uri));
          List<int> bytes = byteSink.builder.takeBytes();

          var signatureBuilder = new ApiSignature();
          signatureBuilder.addBytes(_salt);
          signatureBuilder.addBytes(bytes);
          cycle.outlineSignature = signatureBuilder.toByteList();
          outlineKey = hex.encode(cycle.outlineSignature) + '.outline';

          // Store the results.
          _byteStore.put(outlineSignatureKey, cycle.outlineSignature);
          _byteStore.put(outlineKey, bytes);
          _logger.writeln('Stored ${bytes.length} bytes.');

          // Read the outline from the bytes.
          // TODO(scheglov): Put into the object cache.
          cycle.outline = loadProgramFromBytes(bytes);
          _logger.writeln('Read ${cycle.outline.libraries.length} libraries.');
        });
      } finally {
        combinedOutlines.undo();
      }

      // Log the outline signature to help to understand (re)compilation.
      String outlineSignatureHex = hex.encode(cycle.outlineSignature);
      _logger.writeln('Outline signature: ${outlineSignatureHex}.');
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
}

/// The result of compiling of a single file.
class KernelResult {
  /// The dependencies of the [library].
  /// Most of them are shaken outlines, but some might be full libraries.
  final List<Library> dependencies;

  /// The [TypeEnvironment] based on the SDK library outlines.
  final TypeEnvironment types;

  /// The library of the requested file.
  final Library library;

  KernelResult(this.dependencies, this.types, this.library);
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
  final Map<String, Source> uriToSource;

  /// Kernel libraries for libraries in the [cycle].  Bodies of dependencies
  /// are not included, but but references to those dependencies are included.
  final List<Library> kernelLibraries;

  LibraryCycleResult(
      this.cycle, this.signature, this.uriToSource, this.kernelLibraries);
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
