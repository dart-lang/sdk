// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/kernel.dart' hide Source;
import 'package:meta/meta.dart';

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

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The function to notify when files become used or unused, or `null`.
  final WatchUsedFilesFn _watchFn;

  /// TODO(scheglov) document
  KernelDriver _driver;

  /// Latest compilation signatures produced by [computeDelta] for libraries.
  final Map<Uri, String> _latestSignature = {};

  /// The object that provides additional information for tests.
  _TestView _testView;

  IncrementalKernelGeneratorImpl(
      ProcessedOptions options, TranslateUri uriTranslator, this._entryPoint,
      {WatchUsedFilesFn watch})
      : _logger = options.logger,
        _watchFn = watch {
    _testView = new _TestView(this);

    Future<Null> onFileAdded(Uri uri) {
      if (_watchFn != null) {
        return _watchFn(uri, true);
      }
      return new Future.value();
    }

    _driver = new KernelDriver(_logger, options.fileSystem, options.byteStore,
        uriTranslator, options.strongMode,
        fileAddedFn: onFileAdded);
  }

  /// Return the object that provides additional information for tests.
  @visibleForTesting
  _TestView get test => _testView;

  @override
  Future<DeltaProgram> computeDelta() async {
    return await _logger.runAsync('Compute delta', () async {
      KernelResult kernelResult = await _driver.getKernel(_entryPoint);
      List<LibraryCycleResult> results = kernelResult.results;

      // The file graph might have changed, perform GC.
      await _gc();

      // The set of affected library cycles (have different signatures).
      final affectedLibraryCycles = new Set<LibraryCycle>();
      for (LibraryCycleResult result in results) {
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
      Program program = new Program(nameRoot: kernelResult.nameRoot);
      for (LibraryCycleResult result in results) {
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
    _driver.invalidate(uri);
  }

  @override
  void invalidateAll() {
    _driver.invalidateAll();
  }

  /// TODO(scheglov) document
  Future<Null> _gc() async {
    var removedFiles = _driver.fsState.gc(_entryPoint);
    if (removedFiles.isNotEmpty && _watchFn != null) {
      for (var removedFile in removedFiles) {
        await _watchFn(removedFile.fileUri, false);
      }
    }
  }
}

@visibleForTesting
class _TestView {
  final IncrementalKernelGeneratorImpl _generator;

  _TestView(this._generator);

  /// The [KernelDriver] that is used to actually compile.
  KernelDriver get driver => _generator._driver;
}
