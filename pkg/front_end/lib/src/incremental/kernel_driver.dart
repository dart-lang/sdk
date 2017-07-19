// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/file_system.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_library_builder.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart' hide Source;
import 'package:kernel/target/targets.dart' show Target;
import 'package:meta/meta.dart';

/// This function is invoked for each newly discovered file, and the returned
/// [Future] is awaited before reading the file content.
typedef Future<Null> KernelDriverFileAddedFn(Uri uri);

/// This class computes [KernelResult]s for Dart files.
///
/// Let the "current file state" represent a map from file URI to the file
/// contents most recently read from that file. When the driver needs to
/// access a file that is not in the current file state yet, it will call
/// the optional "file added" function, read the file and put it into the
/// current file state.
///
/// The client invokes [getKernel] to schedule computing the [KernelResult]
/// for a Dart file. The driver will eventually use the current file state
/// of the specified file and all files that it transitively depends on to
/// compute corresponding kernel files (or read them from the [ByteStore]).
///
/// A call to [invalidate] removes the specified file from the current file
/// state, so that it will be reread before any following [getKernel] will
/// return a result.
class KernelDriver {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 1;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The [FileSystem] which should be used by the front end to access files.
  final FileSystem _fileSystem;

  /// The byte storage to get and put serialized data.
  final ByteStore _byteStore;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final UriTranslator _uriTranslator;

  /// The backend target to generate kernels for.
  final Target _target;

  /// The function that is invoked when a new file is about to be added to
  /// the current file state. The [Future] that it returns is awaited before
  /// reading the file contents.
  final KernelDriverFileAddedFn _fileAddedFn;

  /// The salt to mix into all hashes used as keys for serialized data.
  List<int> _salt;

  /// The current file system state.
  FileSystemState _fsState;

  /// The set of absolute file URIs that were reported through [invalidate]
  /// and not checked for actual changes yet.
  final Set<Uri> _invalidatedFiles = new Set<Uri>();

  /// The object that provides additional information for tests.
  final _TestView _testView = new _TestView();

  KernelDriver(this._logger, this._fileSystem, this._byteStore,
      this._uriTranslator, this._target,
      {KernelDriverFileAddedFn fileAddedFn})
      : _fileAddedFn = fileAddedFn {
    _computeSalt();

    Future<Null> onFileAdded(Uri uri) {
      if (_fileAddedFn != null) {
        return _fileAddedFn(uri);
      }
      return new Future.value();
    }

    _fsState = new FileSystemState(
        _byteStore, _fileSystem, _uriTranslator, _salt, onFileAdded);
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
  /// If the driver has the cached result for the file with the current file
  /// state, it is returned.
  ///
  /// Otherwise the driver will compute new kernel files and return them.
  Future<KernelResult> getKernel(Uri uri) async {
    return await runWithFrontEndContext('Compute delta', () async {
      await _refreshInvalidatedFiles();

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

      CanonicalName nameRoot = new CanonicalName.root();
      DillTarget dillTarget =
          new DillTarget(new Ticker(isVerbose: false), _uriTranslator, _target);

      List<LibraryCycleResult> results = [];
      _testView.compiledCycles.clear();
      await _logger.runAsync('Compute results for cycles', () async {
        for (LibraryCycle cycle in cycles) {
          LibraryCycleResult result =
              await _compileCycle(nameRoot, dillTarget, cycle);
          results.add(result);
        }
      });

      return new KernelResult(nameRoot, results);
    });
  }

  Future<T> runWithFrontEndContext<T>(String msg, Future<T> f()) async {
    var options = new CompilerOptions()
      ..target = _target
      // Note: we do not report error on the console because the driver is an
      // ongoing background service that shouldn't polute stdout.
      // TODO(scheglov,sigmund): add an error handler to forward errors to
      // analyzer driver and incremental kernel generator.
      ..reportMessages = false;
    return await CompilerContext.runWithOptions(
        new ProcessedOptions(options), (_) => _logger.runAsync(msg, f));
  }

  /// The file with the given [uri] might have changed - updated, added, or
  /// removed. Or not, we don't know. Or it might have, but then changed back.
  ///
  /// The [uri] must be absolute and normalized file URI.
  ///
  /// Schedules the file contents for the [uri] to be read into the current
  /// file state prior the next invocation of [getKernel] returns the result.
  ///
  /// Invocation of this method will not prevent a [Future] returned from
  /// [getKernel] from completing with a result, but the result is not
  /// guaranteed to be consistent with the new current file state after this
  /// [invalidate] invocation.
  void invalidate(Uri uri) {
    _invalidatedFiles.add(uri);
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

          return new LibraryCycleResult(cycle, signature, program.libraries);
        });
      }

      // Create KernelTarget and configure it for compiling the cycle URIs.
      KernelTarget kernelTarget = new KernelTarget(
          _fsState.fileSystemView, true, dillTarget, _uriTranslator);
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
        List<int> bytes =
            serializeProgram(program, filter: kernelLibraries.contains);
        _byteStore.put(kernelKey, bytes);
        _logger.writeln('Stored ${bytes.length} bytes.');
      });

      return new LibraryCycleResult(cycle, signature, kernelLibraries);
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
    saltBuilder.addBool(_target.strongMode);
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
  final CanonicalName nameRoot;
  final List<LibraryCycleResult> results;

  KernelResult(this.nameRoot, this.results);
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

  /// Kernel libraries for libraries in the [cycle].  Bodies of dependencies
  /// are not included, but but references to those dependencies are included.
  final List<Library> kernelLibraries;

  LibraryCycleResult(this.cycle, this.signature, this.kernelLibraries);
}

@visibleForTesting
class _TestView {
  /// The list of [LibraryCycle]s compiled for the last delta.
  /// It does not include libraries which were read from the cache.
  final List<LibraryCycle> compiledCycles = [];
}
