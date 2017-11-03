// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:front_end/byte_store.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/byte_store/protected_file_byte_store.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/kernel.dart';
import 'package:meta/meta.dart';

/// Implementation of [IncrementalKernelGenerator].
///
/// TODO(scheglov) Update the documentation.
///
/// Theory of operation: an instance of [IncrementalResolvedAstGenerator] is
/// used to obtain resolved ASTs, and these are fed into kernel code generation
/// logic.
class IncrementalKernelGeneratorImpl implements IncrementalKernelGenerator {
  static const MSG_PENDING_COMPUTE =
      'A computeDelta() invocation is still executing.';

  static const MSG_NO_LAST_DELTA =
      'The last delta has been already accepted or rejected.';

  static const MSG_HAS_LAST_DELTA =
      'The last delta must be either accepted or rejected.';

  /// The logger to report compilation progress.
  final PerformanceLog _logger;

  /// The [ByteStore] used to cache results.
  final ByteStore _byteStore;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The function to notify when files become used or unused, or `null`.
  final WatchUsedFilesFn _watchFn;

  /// Whether we the generator is configured to use SDK outline.
  bool _hasSdkOutlineBytes;

  /// The [KernelDriver] that is used to compute kernels.
  KernelDriver _driver;

  /// Whether [computeDelta] is executing.
  bool _isComputeDeltaExecuting = false;

  /// The current signatures for libraries.
  final Map<Uri, String> _currentSignatures = {};

  /// The signatures for libraries produced by the last [computeDelta], or
  /// `null` if the last delta was either accepted or rejected.
  Map<Uri, String> _lastSignatures;

  /// The object that provides additional information for tests.
  _TestView _testView;

  IncrementalKernelGeneratorImpl(ProcessedOptions options,
      UriTranslator uriTranslator, List<int> sdkOutlineBytes, this._entryPoint,
      {WatchUsedFilesFn watch})
      : _logger = options.logger,
        _byteStore = options.byteStore,
        _watchFn = watch {
    _hasSdkOutlineBytes = sdkOutlineBytes != null;
    _testView = new _TestView(this);

    Future<Null> onFileAdded(Uri uri) {
      if (_watchFn != null) {
        return _watchFn(uri, true);
      }
      return new Future.value();
    }

    _driver = new KernelDriver(options, uriTranslator,
        sdkOutlineBytes: sdkOutlineBytes, fileAddedFn: onFileAdded);
  }

  /// Return the object that provides additional information for tests.
  @visibleForTesting
  _TestView get test => _testView;

  @override
  void acceptLastDelta() {
    _throwIfNoLastDelta();
    _updateProtectedFileByteStore();
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

    return _logger.runAsync('Compute delta', () async {
      try {
        KernelSequenceResult kernelResult =
            await _driver.getKernelSequence(_entryPoint);
        List<LibraryCycleResult> results = kernelResult.results;

        // Exclude the SDK cycle if was not compiled.
        if (_hasSdkOutlineBytes) {
          results.removeWhere((cycle) => cycle.signature == '<sdk>');
        }

        // The file graph might have changed, perform GC.
        await _gc();

        // The set of affected library cycles (have different signatures).
        final affectedLibraryCycles = new Set<LibraryCycle>();
        for (LibraryCycleResult result in results) {
          for (Library library in result.kernelLibraries) {
            Uri uri = library.importUri;
            if (_currentSignatures[uri] != result.signature) {
              _lastSignatures[uri] = result.signature;
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
            program.uriToSource.addAll(result.uriToSource);
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

        var stateString = _ExternalState.asString(_lastSignatures);
        return new DeltaProgram(stateString, program);
      } finally {
        _isComputeDeltaExecuting = false;
      }
    });
  }

  @override
  void invalidate(Uri uri) {
    _driver.invalidate(uri);
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

  /// Find files which are not referenced from the entry point and report
  /// them to the watch function.
  Future<Null> _gc() async {
    var removedFiles = _driver.fsState.gc(_entryPoint);
    if (removedFiles.isNotEmpty && _watchFn != null) {
      for (var removedFile in removedFiles) {
        await _watchFn(removedFile.fileUri, false);
      }
    }
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

  /// If [ProtectedFileByteStore] is used, update the protected keys.
  void _updateProtectedFileByteStore() {
    ByteStore byteStore = this._byteStore;
    if (byteStore is ProtectedFileByteStore) {
      // Compute the set of added and removed ByteStore keys.
      // We use knowledge about KernelDriver implementation details.
      var addedKeys = new Set<String>();
      var removedKeys = new Set<String>();
      for (var lastUri in _lastSignatures.keys) {
        var currentSignature = _currentSignatures[lastUri];
        var lastSignature = _lastSignatures[lastUri];
        addedKeys.add('$lastSignature.kernel');
        if (currentSignature != null && lastSignature != null) {
          removedKeys.add('$currentSignature.kernel');
        }
      }

      byteStore.updateProtectedKeys(
          add: addedKeys.toList(), remove: removedKeys.toList());
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
  final IncrementalKernelGeneratorImpl _generator;

  _TestView(this._generator);

  /// The [KernelDriver] that is used to actually compile.
  KernelDriver get driver => _generator._driver;
}
