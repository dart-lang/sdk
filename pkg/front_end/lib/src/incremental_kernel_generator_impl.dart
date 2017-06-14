// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/file_system.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/dill/dill_library_builder.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/kernel.dart' hide Source;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;
import 'package:meta/meta.dart';

class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}

/// Implementation of [IncrementalKernelGenerator].
///
/// TODO(scheglov) Update the documentation.
///
/// Theory of operation: an instance of [IncrementalResolvedAstGenerator] is
/// used to obtain resolved ASTs, and these are fed into kernel code generation
/// logic.
class IncrementalKernelGeneratorImpl implements IncrementalKernelGenerator {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 1;

  /// The compiler options, such as the [FileSystem], the SDK dill location,
  /// etc.
  final ProcessedOptions _options;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final TranslateUri _uriTranslator;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The byte storage to get and put serialized data.
  final ByteStore _byteStore;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The function to notify when files become used or unused, or `null`.
  final WatchUsedFilesFn _watchFn;

  /// The salt to mix into all hashes used as keys for serialized data.
  List<int> _salt;

  /// The current file system state.
  FileSystemState _fsState;

  /// Latest compilation signatures produced by [computeDelta] for libraries.
  final Map<Uri, String> _latestSignature = {};

  /// The set of absolute file URIs that were reported through [invalidate]
  /// and not checked for actual changes yet.
  final Set<Uri> _invalidatedFiles = new Set<Uri>();

  /// The object that provides additional information for tests.
  final _TestView _testView = new _TestView();

  IncrementalKernelGeneratorImpl(
      this._options, this._uriTranslator, this._entryPoint,
      {WatchUsedFilesFn watch})
      : _logger = _options.logger,
        _byteStore = _options.byteStore,
        _watchFn = watch {
    _computeSalt();

    Future<Null> onFileAdded(Uri uri) {
      if (_watchFn != null) {
        return _watchFn(uri, true);
      }
      return new Future.value();
    }

    _fsState = new FileSystemState(_options.byteStore, _options.fileSystem,
        _uriTranslator, _salt, onFileAdded);
  }

  /// Return the object that provides additional information for tests.
  @visibleForTesting
  _TestView get test => _testView;

  @override
  Future<DeltaProgram> computeDelta() async {
    return await _logger.runAsync('Compute delta', () async {
      await _refreshInvalidatedFiles();

      // Ensure that the graph starting at the entry point is ready.
      FileState entryLibrary =
          await _logger.runAsync('Build graph of files', () async {
        return await _fsState.getFile(_entryPoint);
      });

      List<LibraryCycle> cycles = _logger.run('Compute library cycles', () {
        List<LibraryCycle> cycles = entryLibrary.topologicalOrder;
        _logger.writeln('Computed ${cycles.length} cycles.');
        return cycles;
      });

      CanonicalName nameRoot = new CanonicalName.root();
      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false),
          _uriTranslator,
          new VmFastaTarget(new TargetFlags(strongMode: _options.strongMode)));

      List<_LibraryCycleResult> results = [];
      _testView.compiledCycles.clear();
      await _logger.runAsync('Compute results for cycles', () async {
        for (LibraryCycle cycle in cycles) {
          _LibraryCycleResult result =
              await _compileCycle(nameRoot, dillTarget, cycle);
          results.add(result);
        }
      });

      Program program = new Program(nameRoot: nameRoot);

      // The set of affected library cycles (have different signatures).
      final affectedLibraryCycles = new Set<LibraryCycle>();
      for (_LibraryCycleResult result in results) {
        for (Library library in result.kernelLibraries) {
          Uri uri = library.importUri;
          if (_latestSignature[uri] != result.signature) {
            _latestSignature[uri] = result.signature;
            affectedLibraryCycles.add(result.cycle);
          }
        }
      }

      // The set of affected library cycles (have different signatures),
      // or libraries that import or export affected libraries (so VM might
      // have inlined some code from affected libraries into them).
      final vmRequiredLibraryCycles = new Set<LibraryCycle>();

      void gatherVmRequiredLibraryCycles(LibraryCycle cycle) {
        if (vmRequiredLibraryCycles.add(cycle)) {
          cycle.directUsers.forEach(gatherVmRequiredLibraryCycles);
        }
      }

      affectedLibraryCycles.forEach(gatherVmRequiredLibraryCycles);

      // Add required libraries.
      for (_LibraryCycleResult result in results) {
        if (vmRequiredLibraryCycles.contains(result.cycle)) {
          for (Library library in result.kernelLibraries) {
            program.libraries.add(library);
            library.parent = program;
          }
        }
      }

      // Set the main method.
      if (program.libraries.isNotEmpty) {
        for (Library library in results.last.kernelLibraries) {
          if (library.importUri == _entryPoint) {
            program.mainMethod = library.procedures.firstWhere(
                (procedure) => procedure.name.name == 'main',
                orElse: () => null);
            break;
          }
        }
      }

      return new DeltaProgram(program);
    });
  }

  @override
  void invalidate(Uri uri) {
    _invalidatedFiles.add(uri);
  }

  @override
  void invalidateAll() {
    _invalidatedFiles.addAll(_fsState.fileUris);
  }

  /// Ensure that [dillTarget] includes the [cycle] libraries.  It already
  /// contains all the libraries that sorted before the given [cycle] in
  /// topological order.  Return the result with the cycle libraries.
  Future<_LibraryCycleResult> _compileCycle(
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

      Future<Null> appendNewDillLibraries(Program program) async {
        List<DillLibraryBuilder> libraryBuilders = dillTarget.loader
            .appendLibraries(program, (uri) => libraryUris.contains(uri));

        // Compute local scopes.
        await dillTarget.buildOutlines();

        // Compute export scopes.
        _computeExportScopes(dillTarget, libraryUriToFile, libraryBuilders);
      }

      // Check if there is already a bundle with these libraries.
      List<int> bytes = _byteStore.get(kernelKey);
      if (bytes != null) {
        return _logger.runAsync('Read serialized libraries', () async {
          var program = new Program(nameRoot: nameRoot);
          var reader = new BinaryBuilder(bytes);
          reader.readProgram(program);

          await appendNewDillLibraries(program);

          return new _LibraryCycleResult(cycle, signature, program.libraries);
        });
      }

      // Create KernelTarget and configure it for compiling the cycle URIs.
      KernelTarget kernelTarget =
          new KernelTarget(_fsState.fileSystemView, dillTarget, _uriTranslator);
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

      _logger.run('Serialize ${kernelLibraries.length} libraries', () {
        program.uriToSource.clear();
        List<int> bytes = _writeProgramBytes(program, kernelLibraries.contains);
        _byteStore.put(kernelKey, bytes);
        _logger.writeln('Stored ${bytes.length} bytes.');
      });

      return new _LibraryCycleResult(cycle, signature, kernelLibraries);
    });
  }

  /// Compute exports scopes for a new strongly connected cycle of [libraries].
  /// The [dillTarget] can be used to access libraries from previous cycles.
  /// TODO(scheglov) Remove/replace this when Kernel has export scopes.
  void _computeExportScopes(DillTarget dillTarget,
      Map<Uri, FileState> uriToFile, List<DillLibraryBuilder> libraries) {
    bool wasChanged = false;
    do {
      wasChanged = false;
      for (DillLibraryBuilder library in libraries) {
        FileState file = uriToFile[library.uri];
        for (NamespaceExport export in file.exports) {
          DillLibraryBuilder exportedLibrary =
              dillTarget.loader.read(export.library.uri, -1, accessor: library);
          if (exportedLibrary != null) {
            exportedLibrary.exports.forEach((name, member) {
              if (export.isExposed(name) &&
                  library.addToExportScope(name, member)) {
                wasChanged = true;
              }
            });
          } else {
            // TODO(scheglov) How to handle this?
          }
        }
      }
    } while (wasChanged);
  }

  /// Compute salt and put into [_salt].
  void _computeSalt() {
    var saltBuilder = new ApiSignature();
    saltBuilder.addInt(DATA_VERSION);
    saltBuilder.addBool(_options.strongMode);
    saltBuilder.addString(_entryPoint.toString());
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
      signatureBuilder.addString(file.uri.toString());
      // TODO(scheglov): Stop using content hashes here, when Kernel stops
      // copying methods of mixed-in classes,
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

      // The file graph might have changed, perform GC.
      var removedFiles = _fsState.gc(_entryPoint);
      if (removedFiles.isNotEmpty && _watchFn != null) {
        for (var removedFile in removedFiles) {
          await _watchFn(removedFile.fileUri, false);
        }
      }
    });
  }

  List<int> _writeProgramBytes(Program program, bool filter(Library library)) {
    ByteSink byteSink = new ByteSink();
    new LimitedBinaryPrinter(byteSink, filter).writeProgramFile(program);
    return byteSink.builder.takeBytes();
  }
}

/// Compilation result for a library cycle.
class _LibraryCycleResult {
  final LibraryCycle cycle;

  /// The signature of the result.
  ///
  /// It is based on the full content of the libraries in the [cycle], and
  /// either API signatures of the transitive dependencies (usually), or
  /// the full content of them (in the [cycle] has a library with a mixin
  /// application).
  final String signature;

  /// Kernel libraries for libraries in the [cycle].  Bodies of dependencies
  /// are not included, but but references to those dependencies are included.
  final List<Library> kernelLibraries;

  _LibraryCycleResult(this.cycle, this.signature, this.kernelLibraries);
}

@visibleForTesting
class _TestView {
  /// The list of [LibraryCycle]s compiled for the last delta.
  /// It does not include libraries which were read from the cache.
  final List<LibraryCycle> compiledCycles = [];
}
