// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compilation_error.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/multi_root_file_system.dart';
import 'package:kernel/kernel.dart'
    show Program, loadProgramFromBytes, CanonicalName;
import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm_fasta.dart';
import 'package:package_config/packages_file.dart' as package_config;
import 'package:source_span/source_span.dart' show SourceSpan;

/// All options needed for the front end implementation.
///
/// This includes: all of [CompilerOptions] in a form useful to the
/// implementation, default values for options that were not provided,
/// and information derived from how the compiler was invoked (like the
/// entry-points given to the compiler and whether a modular or whole-program
/// API was used).
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
  ///
  /// A summary, also referred to as "outline" internally, is a [Program] where
  /// all method bodies are left out. In essence, it contains just API
  /// signatures and constants. When strong-mode is enabled, the summary already
  /// includes inferred types.
  Program _sdkSummaryProgram;

  /// The summary for each uri in `options.inputSummaries`.
  ///
  /// A summary, also referred to as "outline" internally, is a [Program] where
  /// all method bodies are left out. In essence, it contains just API
  /// signatures and constants. When strong-mode is enabled, the summary already
  /// includes inferred types.
  List<Program> _inputSummariesPrograms;

  /// Other programs that are meant to be linked and compiled with the input
  /// sources.
  List<Program> _linkedDependencies;

  /// The location of the SDK, or `null` if the location hasn't been determined
  /// yet.
  Uri _sdkRoot;
  Uri get sdkRoot => _sdkRoot ??= _normalizeSdkRoot();

  Uri _sdkSummary;
  Uri get sdkSummary => _sdkSummary ??= _computeSdkSummaryUri();

  Ticker ticker;

  bool get verbose => _raw.verbose;

  bool get verify => _raw.verify;

  bool get debugDump => _raw.debugDump;

  /// Like [CompilerOptions.chaseDependencies] but with the appropriate default
  /// value filled in.
  bool get chaseDependencies => _raw.chaseDependencies ?? !_modularApi;

  /// Whether the compiler was invoked with a modular API.
  ///
  /// Used to determine the default behavior for [chaseDependencies].
  final bool _modularApi;

  /// The entry-points provided to the compiler.
  final List<Uri> inputs;

  /// Initializes a [ProcessedOptions] object wrapping the given [rawOptions].
  ProcessedOptions(CompilerOptions rawOptions,
      [this._modularApi = false, this.inputs = const []])
      : this._raw = rawOptions,
        ticker = new Ticker(isVerbose: rawOptions.verbose);

  /// The logger to report compilation progress.
  PerformanceLog get logger {
    return _raw.logger;
  }

  /// The byte storage to get and put serialized data.
  ByteStore get byteStore {
    return _raw.byteStore;
  }

  // TODO(sigmund): delete. We should use messages with error codes directly
  // instead.
  void reportError(String message) {
    _raw.onError(new _CompilationError(message));
  }

  /// Runs various validations checks on the input options. For instance,
  /// if an option is a path to a file, it checks that the file exists.
  Future<bool> validateOptions() async {
    for (var source in inputs) {
      if (source.scheme == 'file' &&
          !await fileSystem.entityForUri(source).exists()) {
        reportError("Entry-point file not found: $source");
        return false;
      }
    }

    if (_raw.sdkRoot != null &&
        !await fileSystem.entityForUri(sdkRoot).exists()) {
      reportError("SDK root directory not found: ${sdkRoot}");
      return false;
    }

    var summary = sdkSummary;
    if (summary != null && !await fileSystem.entityForUri(summary).exists()) {
      reportError("SDK summary not found: ${summary}");
      return false;
    }

    if (compileSdk && summary != null) {
      reportError(
          "The compileSdk and sdkSummary options are mutually exclusive");
      return false;
    }
    return true;
  }

  /// Determine whether to generate code for the SDK when compiling a
  /// whole-program.
  bool get compileSdk => _raw.compileSdk;

  FileSystem _fileSystem;

  /// Get the [FileSystem] which should be used by the front end to access
  /// files.
  ///
  /// If the client supplied roots using [CompilerOptions.multiRoots], the
  /// returned [FileSystem] will automatically perform the appropriate mapping.
  FileSystem get fileSystem => _fileSystem ??= _createFileSystem();

  /// Whether to interpret Dart sources in strong-mode.
  bool get strongMode => _raw.strongMode;

  Target _target;
  Target get target => _target ??=
      _raw.target ?? new VmFastaTarget(new TargetFlags(strongMode: strongMode));

  /// Get an outline program that summarizes the SDK, if any.
  // TODO(sigmund): move, this doesn't feel like an "option".
  Future<Program> loadSdkSummary(CanonicalName nameRoot) async {
    if (_sdkSummaryProgram == null) {
      if (sdkSummary == null) return null;
      var bytes = await fileSystem.entityForUri(sdkSummary).readAsBytes();
      _sdkSummaryProgram = loadProgram(bytes, nameRoot);
    }
    return _sdkSummaryProgram;
  }

  /// Get the summary programs for each of the underlying `inputSummaries`
  /// provided via [CompilerOptions].
  // TODO(sigmund): move, this doesn't feel like an "option".
  Future<List<Program>> loadInputSummaries(CanonicalName nameRoot) async {
    if (_inputSummariesPrograms == null) {
      var uris = _raw.inputSummaries;
      if (uris == null || uris.isEmpty) return const <Program>[];
      // TODO(sigmund): throttle # of concurrent opreations.
      var allBytes = await Future
          .wait(uris.map((uri) => fileSystem.entityForUri(uri).readAsBytes()));
      _inputSummariesPrograms =
          allBytes.map((bytes) => loadProgram(bytes, nameRoot)).toList();
    }
    return _inputSummariesPrograms;
  }

  /// Load each of the [CompilerOptions.linkedDependencies] programs.
  // TODO(sigmund): move, this doesn't feel like an "option".
  Future<List<Program>> loadLinkDependencies(CanonicalName nameRoot) async {
    if (_linkedDependencies == null) {
      var uris = _raw.linkedDependencies;
      if (uris == null || uris.isEmpty) return const <Program>[];
      // TODO(sigmund): throttle # of concurrent opreations.
      var allBytes = await Future
          .wait(uris.map((uri) => fileSystem.entityForUri(uri).readAsBytes()));
      _linkedDependencies =
          allBytes.map((bytes) => loadProgram(bytes, nameRoot)).toList();
    }
    return _linkedDependencies;
  }

  /// Helper to load a .dill file from [uri] using the existing [nameRoot].
  Program loadProgram(List<int> bytes, CanonicalName nameRoot) {
    return loadProgramFromBytes(bytes, new Program(nameRoot: nameRoot));
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
      var libraries = _raw.dartLibraries ?? await _parseLibraries();
      _uriTranslator =
          new TranslateUri(_packages, libraries, const <String, List<Uri>>{});
      ticker.logMs("Read packages file");
    }
    return _uriTranslator;
  }

  Future<Map<String, Uri>> _parseLibraries() async {
    Uri librariesJson = _raw.sdkRoot?.resolve("lib/libraries.json");
    return await computeLibraries(fileSystem, librariesJson);
  }

  /// Get the package map which maps package names to URIs.
  ///
  /// This is an asynchronous getter since file system operations may be
  /// required to locate/read the packages file.
  Future<Map<String, Uri>> _getPackages() async {
    if (_packages == null) {
      if (_raw.packagesFileUri == null) {
        // TODO(sigmund,paulberry): implement
        throw new UnimplementedError('search for .packages');
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
  Uri _normalizeSdkRoot() {
    // If an SDK summary location was provided, the SDK itself should not be
    // needed.
    assert(_raw.sdkSummary == null);
    if (_raw.sdkRoot == null) {
      // TODO(paulberry): implement the algorithm for finding the SDK
      // automagically.
      throw new UnimplementedError('infer the default sdk location');
    }
    var root = _raw.sdkRoot;
    if (!root.path.endsWith('/')) {
      root = root.replace(path: root.path + '/');
    }
    return root;
  }

  /// Get or infer the location of the SDK summary.
  Uri _computeSdkSummaryUri() {
    if (_raw.sdkSummary != null) return _raw.sdkSummary;

    // Infer based on the sdkRoot, but only when `compileSdk` is false,
    // otherwise the default intent was to compile the sdk from sources and not
    // to load an sdk summary file.
    if (_raw.compileSdk) return null;
    return sdkRoot.resolve('outline.dill');
  }

  /// Create a [FileSystem] specific to the current options.
  ///
  /// If `_raw.multiRoots` is not empty, the file-system will implement the
  /// semantics of multiple roots. If [chaseDependencies] is false, the
  /// resulting file system will be hermetic.
  FileSystem _createFileSystem() {
    var result = _raw.fileSystem;
    // Note: hermetic checks are done before translating multi-root URIs, so
    // the order in which we create the file systems below is relevant.
    if (!_raw.multiRoots.isEmpty) {
      result = new MultiRootFileSystem('multi-root', _raw.multiRoots, result);
    }
    if (!chaseDependencies) {
      var allInputs = inputs.toSet();
      allInputs.addAll(_raw.inputSummaries);
      allInputs.addAll(_raw.linkedDependencies);

      if (sdkSummary != null) allInputs.add(sdkSummary);

      if (_raw.sdkRoot != null) {
        // TODO(sigmund): refine this, we should be more explicit about when
        // sdkRoot and libraries.json are allowed to be used.
        allInputs.add(sdkRoot);
        allInputs.add(sdkRoot.resolve("lib/libraries.json"));
      }

      /// Note: Searching the file-system for the package-config is not
      /// supported in hermetic builds.
      if (_raw.packagesFileUri != null) allInputs.add(_raw.packagesFileUri);
      result = new HermeticFileSystem(allInputs, result);
    }
    return result;
  }
}

/// A [FileSystem] that only allows access to files that have been explicitly
/// whitelisted.
class HermeticFileSystem implements FileSystem {
  final Set<Uri> includedFiles;
  final FileSystem _realFileSystem;

  HermeticFileSystem(this.includedFiles, this._realFileSystem);

  FileSystemEntity entityForUri(Uri uri) {
    if (includedFiles.contains(uri)) return _realFileSystem.entityForUri(uri);
    throw new HermeticAccessException(uri);
  }
}

class HermeticAccessException extends FileSystemException {
  HermeticAccessException(Uri uri)
      : super(
            uri,
            'Invalid access to $uri: '
            'the file is accessed in a modular hermetic build, '
            'but it was not explicitly listed as an input.');

  @override
  String toString() => message;
}

/// An error that only contains a message and no error location.
class _CompilationError implements CompilationError {
  String get correction => null;
  SourceSpan get span => null;
  final String message;
  _CompilationError(this.message);

  String toString() => message;
}
