// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/simple_error.dart';
import 'package:package_config/packages_file.dart' as package_config;
import 'package:kernel/kernel.dart' show Program, loadProgramFromBytes;

/// Wrapper around [CompilerOptions] which exposes the options in a form useful
/// to the front end implementation.
///
/// The intent is that the front end should immediately wrap any incoming
/// [CompilerOptions] object in this class before doing further processing, and
/// should thereafter access all options via the wrapper.  This ensures that
/// options are interpreted in a consistent way and that data derived from
/// options is not unnecessarily recomputed.
class ProcessedOptions {
  /// The raw [CompilerOptions] which this class wraps.
  final CompilerOptions _raw;

  /// The package map derived from the options, or `null` if the package map has
  /// not been computed yet.
  Map<String, Uri> _packages;

  /// The object that knows how to resolve "package:" and "dart:" URIs,
  /// or `null` if it has not been computed yet.
  TranslateUri _uriTranslator;

  /// The SDK summary, or `null` if it has not been read yet.
  Program _sdkSummaryProgram;

  /// The summary for each uri in `options.inputSummaries`.
  List<Program> _inputSummariesPrograms;

  /// The location of the SDK, or `null` if the location hasn't been determined
  /// yet.
  Uri _sdkRoot;

  Uri get sdkRoot => _sdkRoot ??= _normalizeSdkRoot();

  /// Initializes a [ProcessedOptions] object wrapping the given [rawOptions].
  ProcessedOptions(CompilerOptions rawOptions) : this._raw = rawOptions;

  /// The logger to report compilation progress.
  PerformanceLog get logger {
    return _raw.logger;
  }

  /// The byte storage to get and put serialized data.
  ByteStore get byteStore {
    return _raw.byteStore;
  }

  /// Runs various validations checks on the input options. For instance,
  /// if an option is a path to a file, it checks that the file exists.
  Future<bool> validateOptions() async {
    var fs = _raw.fileSystem;
    var root = _raw.sdkRoot;

    bool _report(String msg) {
      _raw.onError(new SimpleError(msg));
      return false;
    }

    if (root != null && !await fs.entityForUri(root).exists()) {
      return _report("SDK root directory not found: ${_raw.sdkRoot}");
    }

    var summary = _raw.sdkSummary;
    if (summary != null && !await fs.entityForUri(summary).exists()) {
      return _report("SDK summary not found: ${_raw.sdkSummary}");
    }

    // TODO(sigmund): add checks for options that are meant to be disjoint (like
    // sdkRoot and sdkSummary).
    return true;
  }

  /// Determine whether to generate code for the SDK when compiling a
  /// whole-program.
  bool get compileSdk => _raw.compileSdk;

  /// Get the [FileSystem] which should be used by the front end to access
  /// files.
  ///
  /// If the client supplied roots using [CompilerOptions.multiRoots], the
  /// returned [FileSystem] will automatically perform the appropriate mapping.
  FileSystem get fileSystem {
    // TODO(paulberry): support multiRoots.
    assert(_raw.multiRoots.isEmpty);
    return _raw.fileSystem;
  }

  /// Whether to interpret Dart sources in strong-mode.
  bool get strongMode => _raw.strongMode;

  /// Get an outline program that summarizes the SDK.
  Future<Program> get sdkSummaryProgram async {
    if (_sdkSummaryProgram == null) {
      if (_raw.sdkSummary == null) return null;
      _sdkSummaryProgram = await _loadProgram(_raw.sdkSummary);
    }
    return _sdkSummaryProgram;
  }

  /// Get the summary programs for each of the underlying `inputSummaries`
  /// provided via [CompilerOptions].
  Future<List<Program>> get inputSummariesPrograms async {
    if (_inputSummariesPrograms == null) {
      var uris = _raw.inputSummaries;
      if (uris == null || uris.isEmpty) return const <Program>[];
      _inputSummariesPrograms = await Future.wait(uris.map(_loadProgram));
    }
    return _inputSummariesPrograms;
  }

  Future<Program> _loadProgram(Uri uri) async {
    var bytes = await fileSystem.entityForUri(uri).readAsBytes();
    return loadProgramFromBytes(bytes)..unbindCanonicalNames();
  }

  /// Get the [TranslateUri] which resolves "package:" and "dart:" URIs.
  ///
  /// This is an asynchronous method since file system operations may be
  /// required to locate/read the packages file as well as SDK metadata.
  Future<TranslateUri> getUriTranslator() async {
    if (_uriTranslator == null) {
      await _getPackages();
      // TODO(scheglov) Load SDK libraries from whatever format we decide.
      // TODO(scheglov) Remove the field "_raw.dartLibraries".
      _uriTranslator = new TranslateUri(
          _packages, _raw.dartLibraries, const <String, List<Uri>>{});
      _uriTranslator.dartLibraries.addAll(_raw.dartLibraries);
    }
    return _uriTranslator;
  }

  /// Get the package map which maps package names to URIs.
  ///
  /// This is an asynchronous getter since file system operations may be
  /// required to locate/read the packages file.
  Future<Map<String, Uri>> _getPackages() async {
    if (_packages == null) {
      if (_raw.packagesFileUri == null) {
        throw new UnimplementedError(); // TODO(paulberry): search for .packages
      } else if (_raw.packagesFileUri.path.isEmpty) {
        _packages = {};
      } else {
        var contents =
            await fileSystem.entityForUri(_raw.packagesFileUri).readAsBytes();
        _packages = package_config.parse(contents, _raw.packagesFileUri);
      }
    }
    return _packages;
  }

  /// Get the location of the SDK.
  ///
  /// This is an asynchronous getter since file system operations may be
  /// required to locate the SDK.
  Uri _normalizeSdkRoot() {
    // If an SDK summary location was provided, the SDK itself should not be
    // needed.
    assert(_raw.sdkSummary == null);
    if (_raw.sdkRoot == null) {
      // TODO(paulberry): implement the algorithm for finding the SDK
      // automagically.
      throw new UnimplementedError();
    }
    var root = _raw.sdkRoot;
    if (!root.path.endsWith('/')) {
      root = root.replace(path: _sdkRoot.path + '/');
    }
    return root;
  }
}
