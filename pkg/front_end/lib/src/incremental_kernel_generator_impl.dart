// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/file_system.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/incremental_resolved_ast_generator.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart' hide Source;

dynamic unimplemented() {
  // TODO(paulberry): get rid of this.
  throw new UnimplementedError();
}

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
  /// The compiler options, such as the [FileSystem], the SDK dill location,
  /// etc.
  final ProcessedOptions _options;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final TranslateUri _uriTranslator;

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The current file system state.
  final FileSystemState _fsState;

  /// The byte storage to get and put serialized data.
  final ByteStore _byteStore;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// Latest compilation signatures produced by [computeDelta] for libraries.
  final Map<Uri, String> _uriToLatestSignature = {};

  /// The set of absolute file URIs that were reported through [invalidate]
  /// and not checked for actual changes yet.
  final Set<Uri> _invalidatedFiles = new Set<Uri>();

  IncrementalKernelGeneratorImpl(
      this._options, this._uriTranslator, this._entryPoint)
      : _logger = _options.logger,
        _fsState = new FileSystemState(_options.fileSystem, _uriTranslator),
        _byteStore = _options.byteStore;

  @override
  Future<DeltaProgram> computeDelta(
      {Future<Null> watch(Uri uri, bool used)}) async {
    return await _logger.runAsync('Compute delta', () async {
      await _refreshInvalidatedFiles();

      // Ensure that the graph starting at the entry point is ready.
      FileState entryLibrary = await _fsState.getFile(_entryPoint);

      List<LibraryCycle> cycles = _logger.run('Compute library cycles', () {
        List<LibraryCycle> cycles = entryLibrary.topologicalOrder;
        _logger.writeln('Computed ${cycles.length} cycles.');
        return cycles;
      });

      CanonicalName nameRoot = new CanonicalName.root();
      DillTarget dillTarget =
          new DillTarget(new Ticker(isVerbose: false), _uriTranslator);

      List<_LibraryCycleResult> results = [];
      await _logger.runAsync('Compute results for cycles', () async {
        for (LibraryCycle cycle in cycles) {
          _LibraryCycleResult result =
              await _compileCycle(nameRoot, dillTarget, cycle);
          results.add(result);
        }
      });

      Program program = new Program(nameRoot: nameRoot);

      // Add affected libraries (with different signatures).
      for (_LibraryCycleResult result in results) {
        for (Library library in result.kernelLibraries) {
          Uri uri = library.importUri;
          if (_uriToLatestSignature[uri] != result.signature) {
            _uriToLatestSignature[uri] = result.signature;
            program.libraries.add(library);
          }
        }
      }

      // TODO(scheglov) Add libraries which import changed libraries.

      return new DeltaProgram(program);
    });
  }

  @override
  void invalidate(Uri uri) {
    _invalidatedFiles.add(uri);
  }

  @override
  void invalidateAll() => unimplemented();

  /// Ensure that [dillTarget] includes the [cycle] libraries.  It already
  /// contains all the libraries that sorted before the given [cycle] in
  /// topological order.  Return the result with the cycle libraries.
  Future<_LibraryCycleResult> _compileCycle(
      CanonicalName nameRoot, DillTarget dillTarget, LibraryCycle cycle) async {
    return _logger.runAsync('Compile cycle $cycle', () async {
      String signature;
      {
        var signatureBuilder = new ApiSignature();
        // TODO(scheglov) add salt
        //    signature.addUint32List(_fsState._salt);
        Set<FileState> transitiveFiles = cycle.libraries
            .map((library) => library.transitiveFiles)
            .expand((files) => files)
            .toSet();
        signatureBuilder.addInt(transitiveFiles.length);
        for (FileState file in transitiveFiles) {
          signatureBuilder.addString(file.uri.toString());
          // TODO(scheglov) use API signature
          signatureBuilder.addBytes(file.contentHash);
        }
        signature = signatureBuilder.toHex();
      }

      _logger.writeln('Signature: $signature.');
      String kernelKey = '$signature.kernel';

      /// We need kernel libraries for these URIs.
      Set<Uri> libraryUris = new Set<Uri>();
      for (FileState library in cycle.libraries) {
        libraryUris.add(library.uri);
      }

      /// Check if there is already a bundle with these libraries.
      List<int> bytes = _byteStore.get(kernelKey);
      if (bytes != null) {
        return _logger.run('Read serialized libraries', () {
          var program = new Program(nameRoot: nameRoot);
          var reader = new BinaryBuilder(bytes);
          reader.readProgram(program);
          dillTarget.loader
              .appendLibraries(program, (uri) => libraryUris.contains(uri));
          return new _LibraryCycleResult(cycle, signature, program.libraries);
        });
      }

      // Ask DILL to fill outlines using loaded libraries.
      await dillTarget.writeOutline(null);

      // Create KernelTarget and configure it for compiling the cycle URIs.
      KernelTarget kernelTarget = new KernelTarget(_fsState.fileSystemView,
          dillTarget, _uriTranslator, _options.strongMode);
      for (FileState library in cycle.libraries) {
        kernelTarget.read(library.uri);
      }

      // Compile the cycle libraries into a new full program.
      Program program = await _logger.runAsync(
          'Compile ${cycle.libraries.length} cycle libraries', () async {
        await kernelTarget.writeOutline(null, nameRoot: nameRoot);
        return await kernelTarget.writeProgram(null);
      });

      // Add newly compiled libraries into DILL.
      List<Library> kernelLibraries = program.libraries
          .where((library) => libraryUris.contains(library.importUri))
          .toList();
      dillTarget.loader
          .appendLibraries(program, (uri) => libraryUris.contains(uri));

      _logger.run('Serialize ${kernelLibraries.length} libraries', () {
        program.unbindCanonicalNames();
        List<int> bytes = _writeProgramBytes(program, kernelLibraries.contains);
        _byteStore.put(kernelKey, bytes);
        _logger.writeln('Stored ${bytes.length} bytes.');
      });

      return new _LibraryCycleResult(cycle, signature, kernelLibraries);
    });
  }

  /// Refresh all the invalidated files and update dependencies.
  Future<Null> _refreshInvalidatedFiles() async {
    await _logger.runAsync('Refresh invalidated files', () async {
      for (Uri fileUri in _invalidatedFiles) {
        FileState file = await _fsState.getFile(fileUri);
        await file.refresh();
      }
      _invalidatedFiles.clear();
    });
  }

  List<int> _writeProgramBytes(Program program, bool filter(Library library)) {
    ByteSink byteSink = new ByteSink();
    new LibraryFilteringBinaryPrinter(byteSink, filter)
        .writeProgramFile(program);
    return byteSink.builder.takeBytes();
  }
}

/// Compilation result for a library cycle.
class _LibraryCycleResult {
  final LibraryCycle cycle;

  /// The signature of the result.
  ///
  /// Currently it is based on the full content of the transitive closure of
  /// the [cycle] files and all its dependencies.
  /// TODO(scheglov) Not used yet.
  /// TODO(scheglov) Use API signatures.
  /// TODO(scheglov) Or use tree shaking and compute signatures of outlines.
  final String signature;

  /// Kernel libraries for libraries in the [cycle].  Dependencies are not
  /// included, they were returned as results for preceding cycles.
  final List<Library> kernelLibraries;

  _LibraryCycleResult(this.cycle, this.signature, this.kernelLibraries);
}
