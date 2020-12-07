// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exitCode;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/kernel.dart'
    show
        CanonicalName,
        Component,
        Location,
        NonNullableByDefaultCompiledMode,
        Version;

import 'package:kernel/target/targets.dart'
    show NoneTarget, Target, TargetFlags;

import 'package:package_config/package_config.dart';

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import '../api_prototype/experimental_flags.dart' as flags;

import '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

import '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

import '../fasta/command_line_reporting.dart' as command_line_reporting;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/fasta_codes.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        messageCantInferPackagesFromManyInputs,
        messageCantInferPackagesFromPackageUri,
        messageInternalProblemProvidedBothCompileSdkAndSdkSummary,
        messageMissingInput,
        noLength,
        templateCannotReadSdkSpecification,
        templateCantReadFile,
        templateDebugTrace,
        templateExceptionReadingFile,
        templateInputFileNotFound,
        templateInternalProblemUnsupported,
        templatePackagesFileFormat,
        templateSdkRootNotFound,
        templateSdkSpecificationNotFound,
        templateSdkSummaryNotFound;

import '../fasta/messages.dart' show getLocation;

import '../fasta/problems.dart' show DebugAbort, unimplemented;

import '../fasta/ticker.dart' show Ticker;

import '../fasta/uri_translator.dart' show UriTranslator;

import 'libraries_specification.dart'
    show
        LibrariesSpecification,
        LibrariesSpecificationException,
        TargetLibrariesSpecification;

import 'nnbd_mode.dart';

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
  PackageConfig _packages;

  /// The uri for .packages derived from the options, or `null` if the package
  /// map has not been computed yet or there is no .packages in effect.
  Uri _packagesUri;
  Uri get packagesUri => _packagesUri;

  /// The object that knows how to resolve "package:" and "dart:" URIs,
  /// or `null` if it has not been computed yet.
  UriTranslator _uriTranslator;

  /// The SDK summary, or `null` if it has not been read yet.
  ///
  /// A summary, also referred to as "outline" internally, is a [Component]
  /// where all method bodies are left out. In essence, it contains just API
  /// signatures and constants. The summary should include inferred top-level
  /// types unless legacy mode is enabled.
  Component _sdkSummaryComponent;

  /// The component for each uri in `options.additionalDills`.
  ///
  /// A summary, also referred to as "outline" internally, is a [Component]
  /// where all method bodies are left out. In essence, it contains just API
  /// signatures and constants. The summaries should include inferred top-level
  /// types unless legacy mode is enabled.
  List<Component> _additionalDillComponents;

  /// The location of the SDK, or `null` if the location hasn't been determined
  /// yet.
  Uri _sdkRoot;
  Uri get sdkRoot {
    _ensureSdkDefaults();
    return _sdkRoot;
  }

  Uri _sdkSummary;
  Uri get sdkSummary {
    _ensureSdkDefaults();
    return _sdkSummary;
  }

  List<int> _sdkSummaryBytes;
  bool _triedLoadingSdkSummary = false;

  /// Get the bytes of the SDK outline, if any.
  Future<List<int>> loadSdkSummaryBytes() async {
    if (_sdkSummaryBytes == null && !_triedLoadingSdkSummary) {
      if (sdkSummary == null) return null;
      FileSystemEntity entry = fileSystem.entityForUri(sdkSummary);
      _sdkSummaryBytes = await _readAsBytes(entry);
      _triedLoadingSdkSummary = true;
    }
    return _sdkSummaryBytes;
  }

  Uri _librariesSpecificationUri;
  Uri get librariesSpecificationUri {
    _ensureSdkDefaults();
    return _librariesSpecificationUri;
  }

  Ticker ticker;

  Uri get packagesUriRaw => _raw.packagesFileUri;

  bool get verbose => _raw.verbose;

  bool get verify => _raw.verify;

  bool get verifySkipPlatform => _raw.verifySkipPlatform;

  bool get debugDump => _raw.debugDump;

  bool get omitPlatform => _raw.omitPlatform;

  bool get setExitCodeOnProblem => _raw.setExitCodeOnProblem;

  bool get embedSourceText => _raw.embedSourceText;

  bool get throwOnErrorsForDebugging => _raw.throwOnErrorsForDebugging;

  bool get throwOnWarningsForDebugging => _raw.throwOnWarningsForDebugging;

  bool get emitDeps => _raw.emitDeps;

  NnbdMode get nnbdMode => _raw.nnbdMode;

  bool get warnOnReachabilityCheck => _raw.warnOnReachabilityCheck;

  /// The entry-points provided to the compiler.
  final List<Uri> inputs;

  /// The Uri where output is generated, may be null.
  final Uri output;

  final Map<String, String> environmentDefines;

  bool get errorOnUnevaluatedConstant => _raw.errorOnUnevaluatedConstant;

  /// The number of fatal diagnostics encountered so far.
  int fatalDiagnosticCount = 0;

  /// Initializes a [ProcessedOptions] object wrapping the given [rawOptions].
  ProcessedOptions({CompilerOptions options, List<Uri> inputs, this.output})
      : this._raw = options ?? new CompilerOptions(),
        this.inputs = inputs ?? <Uri>[],
        // TODO(askesc): Copy the map when kernel_service supports that.
        this.environmentDefines = options?.environmentDefines,
        // TODO(sigmund, ahe): create ticker even earlier or pass in a stopwatch
        // collecting time since the start of the VM.
        this.ticker = new Ticker(isVerbose: options?.verbose ?? false);

  FormattedMessage format(
      LocatedMessage message, Severity severity, List<LocatedMessage> context,
      {List<Uri> involvedFiles}) {
    int offset = message.charOffset;
    Uri uri = message.uri;
    Location location = offset == -1 ? null : getLocation(uri, offset);
    String formatted =
        command_line_reporting.format(message, severity, location: location);
    List<FormattedMessage> formattedContext;
    if (context != null && context.isNotEmpty) {
      formattedContext =
          new List<FormattedMessage>.filled(context.length, null);
      for (int i = 0; i < context.length; i++) {
        formattedContext[i] = format(context[i], Severity.context, null);
      }
    }
    return message.withFormatting(formatted, location?.line ?? -1,
        location?.column ?? -1, severity, formattedContext,
        involvedFiles: involvedFiles);
  }

  void report(LocatedMessage message, Severity severity,
      {List<LocatedMessage> context, List<Uri> involvedFiles}) {
    if (command_line_reporting.isHidden(severity)) return;
    if (command_line_reporting.isCompileTimeError(severity)) {
      CompilerContext.current.logError(message, severity);
    }
    if (CompilerContext.current.options.setExitCodeOnProblem) {
      exitCode = 1;
    }
    reportDiagnosticMessage(
        format(message, severity, context, involvedFiles: involvedFiles));
    if (command_line_reporting.shouldThrowOn(severity)) {
      if (fatalDiagnosticCount++ < _raw.skipForDebugging) {
        // Skip this one. The interesting one comes later.
        return;
      }
      if (_raw.skipForDebugging < 0) {
        print(templateDebugTrace
            .withArguments("$severity", "${StackTrace.current}")
            .message);
      } else {
        throw new DebugAbort(
            message.uri, message.charOffset, severity, StackTrace.current);
      }
    }
  }

  void reportDiagnosticMessage(DiagnosticMessage message) {
    (_raw.onDiagnostic ?? _defaultDiagnosticMessageHandler)(message);
  }

  void _defaultDiagnosticMessageHandler(DiagnosticMessage message) {
    printDiagnosticMessage(message, print);
  }

  // TODO(askesc): Remove this and direct callers directly to report.
  void reportWithoutLocation(Message message, Severity severity) {
    report(message.withoutLocation(), severity);
  }

  /// Runs various validations checks on the input options. For instance,
  /// if an option is a path to a file, it checks that the file exists.
  Future<bool> validateOptions({bool errorOnMissingInput: true}) async {
    if (verbose) print(debugString());

    if (errorOnMissingInput && inputs.isEmpty) {
      reportWithoutLocation(messageMissingInput, Severity.error);
      return false;
    }

    if (_raw.sdkRoot != null &&
        !await fileSystem.entityForUri(sdkRoot).exists()) {
      reportWithoutLocation(
          templateSdkRootNotFound.withArguments(sdkRoot), Severity.error);
      return false;
    }

    Uri summary = sdkSummary;
    if (summary != null && !await fileSystem.entityForUri(summary).exists()) {
      reportWithoutLocation(
          templateSdkSummaryNotFound.withArguments(summary), Severity.error);
      return false;
    }

    if (compileSdk && summary != null) {
      reportWithoutLocation(
          messageInternalProblemProvidedBothCompileSdkAndSdkSummary,
          Severity.internalProblem);
      return false;
    }

    for (Uri source in _raw.additionalDills) {
      // TODO(ahe): Remove this check, the compiler itself should handle and
      // recover from this.
      if (!await fileSystem.entityForUri(source).exists()) {
        reportWithoutLocation(
            templateInputFileNotFound.withArguments(source), Severity.error);
        return false;
      }
    }
    return true;
  }

  /// Determine whether to generate code for the SDK when compiling a
  /// whole-program.
  bool get compileSdk => _raw.compileSdk;

  FileSystem _fileSystem;

  /// Get the [FileSystem] which should be used by the front end to access
  /// files.
  FileSystem get fileSystem => _fileSystem ??= _createFileSystem();

  /// Clear the file system so any CompilerOptions fileSystem change will have
  /// effect.
  void clearFileSystemCache() => _fileSystem = null;

  /// Whether to write a file (e.g. a dill file) when reporting a crash.
  bool get writeFileOnCrashReport => _raw.writeFileOnCrashReport;

  /// The current sdk version string, e.g. "2.6.0-edge.sha1hash".
  /// For instance used for language versioning (specifying the maximum
  /// version).
  String get currentSdkVersion => _raw.currentSdkVersion;

  Target _target;
  Target get target =>
      _target ??= _raw.target ?? new NoneTarget(new TargetFlags());

  /// Returns `true` if the [flag] is enabled globally.
  ///
  /// This is `true` either if the [flag] is passed through an explicit
  /// `--enable-experiment` option or if the [flag] is expired and on by
  /// default.
  bool isExperimentEnabledByDefault(flags.ExperimentalFlag flag) {
    return flags.isExperimentEnabled(flag,
        defaultExperimentFlagsForTesting:
            _raw.defaultExperimentFlagsForTesting);
  }

  /// Returns `true` if the [flag] is enabled globally.
  ///
  /// This is `true` either if the [flag] is passed through an explicit
  /// `--enable-experiment` option or if the [flag] is expired and on by
  /// default.
  bool isExperimentEnabledGlobally(flags.ExperimentalFlag flag) {
    return flags.isExperimentEnabled(flag,
        explicitExperimentalFlags: _raw.explicitExperimentalFlags,
        defaultExperimentFlagsForTesting:
            _raw.defaultExperimentFlagsForTesting);
  }

  /// Returns `true` if the [flag] is enabled in the library with the given
  /// [importUri].
  ///
  /// This is `true` either if the [flag] is enabled globally as defined
  /// by [isExperimentEnabledGlobally] or is explicitly enabled through
  /// the 'allowed_experiments.json' file for this library.
  bool isExperimentEnabledInLibrary(
      flags.ExperimentalFlag flag, Uri importUri) {
    return _raw.isExperimentEnabledInLibrary(flag, importUri);
  }

  Version getExperimentEnabledVersionInLibrary(
      flags.ExperimentalFlag flag, Uri importUri) {
    return _raw.getExperimentEnabledVersionInLibrary(flag, importUri);
  }

  Component _validateNullSafetyMode(Component component) {
    if (component.mode == NonNullableByDefaultCompiledMode.Invalid) {
      throw new FormatException(
          'Provided .dill file for the following libraries has an invalid null '
          'safety mode and does not support null safety:\n'
          '${component.libraries.join('\n')}');
    }
    if (nnbdMode == NnbdMode.Strong &&
        !(component.mode == NonNullableByDefaultCompiledMode.Strong ||
            component.mode == NonNullableByDefaultCompiledMode.Agnostic)) {
      throw new FormatException(
          'Provided .dill file for the following libraries does not '
          'support sound null safety:\n'
          '${component.libraries.join('\n')}');
    }
    return component;
  }

  /// Get an outline component that summarizes the SDK, if any.
  // TODO(sigmund): move, this doesn't feel like an "option".
  Future<Component> loadSdkSummary(CanonicalName nameRoot) async {
    if (_sdkSummaryComponent == null) {
      if (sdkSummary == null) return null;
      List<int> bytes = await loadSdkSummaryBytes();
      if (bytes != null && bytes.isNotEmpty) {
        _sdkSummaryComponent = loadComponent(bytes, nameRoot);
      }
    }
    return _sdkSummaryComponent;
  }

  void set sdkSummaryComponent(Component platform) {
    if (_sdkSummaryComponent != null) {
      throw new StateError("sdkSummary already loaded.");
    }
    _validateNullSafetyMode(platform);
    _sdkSummaryComponent = platform;
  }

  /// Get the components for each of the underlying `additionalDill`
  /// provided via [CompilerOptions].
  // TODO(sigmund): move, this doesn't feel like an "option".
  Future<List<Component>> loadAdditionalDills(CanonicalName nameRoot) async {
    if (_additionalDillComponents == null) {
      List<Uri> uris = _raw.additionalDills;
      if (uris == null || uris.isEmpty) return const <Component>[];
      // TODO(sigmund): throttle # of concurrent operations.
      List<List<int>> allBytes = await Future.wait(
          uris.map((uri) => _readAsBytes(fileSystem.entityForUri(uri))));
      _additionalDillComponents = allBytes
          .where((bytes) => bytes != null)
          .map((bytes) => loadComponent(bytes, nameRoot))
          .toList();
    }
    return _additionalDillComponents;
  }

  void set loadAdditionalDillsComponents(List<Component> components) {
    if (_additionalDillComponents != null) {
      throw new StateError("inputAdditionalDillsComponents already loaded.");
    }
    components.forEach(_validateNullSafetyMode);
    _additionalDillComponents = components;
  }

  /// Helper to load a .dill file from [uri] using the existing [nameRoot].
  Component loadComponent(List<int> bytes, CanonicalName nameRoot,
      {bool alwaysCreateNewNamedNodes}) {
    Component component =
        target.configureComponent(new Component(nameRoot: nameRoot));
    // TODO(ahe): Pass file name to BinaryBuilder.
    // TODO(ahe): Control lazy loading via an option.
    new BinaryBuilder(bytes,
            filename: null,
            disableLazyReading: false,
            alwaysCreateNewNamedNodes: alwaysCreateNewNamedNodes)
        .readComponent(component);
    return _validateNullSafetyMode(component);
  }

  /// Get the [UriTranslator] which resolves "package:" and "dart:" URIs.
  ///
  /// This is an asynchronous method since file system operations may be
  /// required to locate/read the packages file as well as SDK metadata.
  Future<UriTranslator> getUriTranslator({bool bypassCache: false}) async {
    if (bypassCache) {
      _uriTranslator = null;
      _packages = null;
    }
    if (_uriTranslator == null) {
      ticker.logMs("Started building UriTranslator");
      TargetLibrariesSpecification libraries =
          await _computeLibrarySpecification();
      ticker.logMs("Read libraries file");
      PackageConfig packages = await _getPackages();
      ticker.logMs("Read packages file");
      _uriTranslator = new UriTranslator(libraries, packages);
    }
    return _uriTranslator;
  }

  Future<TargetLibrariesSpecification> _computeLibrarySpecification() async {
    String name = target.name;
    // TODO(sigmund): Eek! We should get to the point where there is no
    // fasta-specific targets and the target names are meaningful.
    if (name.endsWith('_fasta')) name = name.substring(0, name.length - 6);

    if (librariesSpecificationUri == null ||
        !await fileSystem.entityForUri(librariesSpecificationUri).exists()) {
      if (compileSdk) {
        reportWithoutLocation(
            templateSdkSpecificationNotFound
                .withArguments(librariesSpecificationUri),
            Severity.error);
      }
      return new TargetLibrariesSpecification(name);
    }

    String json =
        await fileSystem.entityForUri(librariesSpecificationUri).readAsString();
    try {
      LibrariesSpecification spec =
          await LibrariesSpecification.parse(librariesSpecificationUri, json);
      return spec.specificationFor(name);
    } on LibrariesSpecificationException catch (e) {
      reportWithoutLocation(
          templateCannotReadSdkSpecification.withArguments('${e.error}'),
          Severity.error);
      return new TargetLibrariesSpecification(name);
    }
  }

  /// Get the package map which maps package names to URIs.
  ///
  /// This is an asynchronous getter since file system operations may be
  /// required to locate/read the packages file.
  Future<PackageConfig> _getPackages() async {
    if (_packages != null) return _packages;
    _packagesUri = null;
    if (_raw.packagesFileUri != null) {
      return _packages = await createPackagesFromFile(_raw.packagesFileUri);
    }

    if (inputs.length > 1) {
      // TODO(sigmund): consider not reporting an error if we would infer
      // the same .packages file from all of the inputs.
      reportWithoutLocation(
          messageCantInferPackagesFromManyInputs, Severity.error);
      return _packages = PackageConfig.empty;
    }
    if (inputs.isEmpty) {
      return _packages = PackageConfig.empty;
    }

    Uri input = inputs.first;

    // When compiling the SDK the input files are normally `dart:` URIs.
    if (input.scheme == 'dart') return _packages = PackageConfig.empty;

    if (input.scheme == 'packages') {
      report(
          messageCantInferPackagesFromPackageUri.withLocation(
              input, -1, noLength),
          Severity.error);
      return _packages = PackageConfig.empty;
    }

    return _packages = await _findPackages(inputs.first);
  }

  Future<Uint8List> _readFile(Uri uri, bool reportError) async {
    try {
      // TODO(ahe): We need to compute line endings for this file.
      FileSystemEntity entityForUri = fileSystem.entityForUri(uri);
      if (!reportError && !await entityForUri.exists()) return null;
      List<int> fileContents = await entityForUri.readAsBytes();
      if (fileContents is Uint8List) {
        return fileContents;
      } else {
        return new Uint8List.fromList(fileContents);
      }
    } on FileSystemException catch (e) {
      if (reportError) {
        reportWithoutLocation(
            templateCantReadFile.withArguments(uri, e.message), Severity.error);
      }
    } catch (e) {
      Message message = templateExceptionReadingFile.withArguments(uri, '$e');
      reportWithoutLocation(message, Severity.error);
      // We throw a new exception to ensure that the message include the uri
      // that led to the exception. Exceptions in Uri don't include the
      // offending uri in the exception message.
      throw new ArgumentError(message.message);
    }
    return null;
  }

  /// Create a [PackageConfig] given the Uri to a `.packages` or
  /// `package_config.json` file.
  ///
  /// If the file doesn't exist, it returns null (and an error is reported
  /// based in [forceCreation]).
  /// If the file does exist but is invalid an error is always reported and an
  /// empty package config is returned.
  Future<PackageConfig> _createPackagesFromFile(
      Uri requestedUri, bool forceCreation, bool requireJson) async {
    Uint8List contents = await _readFile(requestedUri, forceCreation);
    if (contents == null) {
      if (forceCreation) {
        _packagesUri = null;
        return PackageConfig.empty;
      }
      return null;
    }

    _packagesUri = requestedUri;
    try {
      void Function(Object error) onError = (Object error) {
        if (error is FormatException) {
          report(
              templatePackagesFileFormat
                  .withArguments(error.message)
                  .withLocation(requestedUri, error.offset, noLength),
              Severity.error);
        } else {
          reportWithoutLocation(
              templateCantReadFile.withArguments(requestedUri, "$error"),
              Severity.error);
        }
      };
      if (requireJson) {
        return PackageConfig.parseBytes(contents, requestedUri,
            onError: onError);
      }
      return await loadPackageConfigUri(requestedUri, preferNewest: false,
          loader: (uri) {
        if (uri != requestedUri) {
          throw new StateError(
              "Unexpected request from package config package");
        }
        return new Future.value(contents);
      }, onError: onError);
    } on FormatException catch (e) {
      report(
          templatePackagesFileFormat
              .withArguments(e.message)
              .withLocation(requestedUri, e.offset, noLength),
          Severity.error);
    } catch (e) {
      reportWithoutLocation(
          templateCantReadFile.withArguments(requestedUri, "$e"),
          Severity.error);
    }
    _packagesUri = null;
    return PackageConfig.empty;
  }

  /// Create a [PackageConfig] given the Uri to a `.packages` or
  /// `package_config.json` file.
  ///
  /// Note that if a `.packages` file is provided and an appropriately placed
  /// (relative to the .packages file) `package_config.json` file exists, the
  /// `package_config.json` file will be used instead.
  Future<PackageConfig> createPackagesFromFile(Uri file) async {
    // If the input is a ".packages" file we assume the standard layout, and
    // if a ".dart_tool/package_config.json" exists, we'll use that (and require
    // it to be a json file).
    if (file.path.endsWith("/.packages")) {
      // .packages -> try the package_config first.
      Uri tryFirst = file.resolve(".dart_tool/package_config.json");
      PackageConfig result =
          await _createPackagesFromFile(tryFirst, false, true);
      if (result != null) return result;
    }
    return _createPackagesFromFile(file, true, false);
  }

  /// Finds a package resolution strategy using a [FileSystem].
  ///
  /// The [scriptUri] points to a Dart script with a valid scheme accepted by
  /// the [FileSystem].
  ///
  /// This function first tries to locate a `.dart_tool/package_config.json`
  /// (then a `.packages`) file in the `scriptUri` directory.
  /// If that is not found, it starts checking parent directories, and stops if
  /// it finds it. Otherwise it gives up and returns [PackageConfig.empty].
  ///
  /// Note: this is a fork from `package:package_config`s discovery to make sure
  /// we use the expected error reporting etc.
  Future<PackageConfig> _findPackages(Uri scriptUri) async {
    Uri dir = scriptUri.resolve('.');
    if (!dir.isAbsolute) {
      reportWithoutLocation(
          templateInternalProblemUnsupported
              .withArguments("Expected input Uri to be absolute: $scriptUri."),
          Severity.internalProblem);
      return PackageConfig.empty;
    }

    Future<Uri> checkInDir(Uri dir) async {
      Uri candidate;
      try {
        candidate = dir.resolve('.dart_tool/package_config.json');
        if (await fileSystem.entityForUri(candidate).exists()) return candidate;
        candidate = dir.resolve('.packages');
        if (await fileSystem.entityForUri(candidate).exists()) return candidate;
        return null;
      } catch (e) {
        Message message =
            templateExceptionReadingFile.withArguments(candidate, '$e');
        reportWithoutLocation(message, Severity.error);
        // We throw a new exception to ensure that the message include the uri
        // that led to the exception. Exceptions in Uri don't include the
        // offending uri in the exception message.
        throw new ArgumentError(message.message);
      }
    }

    // Check for $cwd/.packages
    Uri candidate = await checkInDir(dir);
    if (candidate != null) return createPackagesFromFile(candidate);

    // Check for cwd(/..)+/.packages
    Uri parentDir = dir.resolve('..');
    while (parentDir.path != dir.path) {
      candidate = await checkInDir(parentDir);
      if (candidate != null) break;
      dir = parentDir;
      parentDir = dir.resolve('..');
    }

    if (candidate != null) return createPackagesFromFile(candidate);
    return PackageConfig.empty;
  }

  bool _computedSdkDefaults = false;

  /// Ensure [_sdkRoot], [_sdkSummary] and [_librarySpecUri] are initialized.
  ///
  /// If they are not set explicitly, they are inferred based on the default
  /// behavior described in [CompilerOptions].
  void _ensureSdkDefaults() {
    if (_computedSdkDefaults) return;
    _computedSdkDefaults = true;
    Uri root = _raw.sdkRoot;
    if (root != null) {
      // Normalize to always end in '/'
      if (!root.path.endsWith('/')) {
        root = root.replace(path: root.path + '/');
      }
      _sdkRoot = root;
    } else if (compileSdk) {
      // TODO(paulberry): implement the algorithm for finding the SDK
      // automagically.
      unimplemented('infer the default sdk location', -1, null);
    }

    if (_raw.sdkSummary != null) {
      _sdkSummary = _raw.sdkSummary;
    } else if (!compileSdk) {
      // Infer based on the sdkRoot, but only when `compileSdk` is false,
      // otherwise the default intent was to compile the sdk from sources and
      // not to load an sdk summary file.
      _sdkSummary = root?.resolve("vm_platform_strong.dill");
    }

    if (_raw.librariesSpecificationUri != null) {
      _librariesSpecificationUri = _raw.librariesSpecificationUri;
    } else if (compileSdk) {
      _librariesSpecificationUri = sdkRoot.resolve('lib/libraries.json');
    }
  }

  /// Create a [FileSystem] specific to the current options.
  FileSystem _createFileSystem() {
    return _raw.fileSystem;
  }

  String debugString() {
    StringBuffer sb = new StringBuffer();
    writeList(String name, List elements) {
      if (elements.isEmpty) {
        sb.writeln('$name: <empty>');
        return;
      }
      sb.writeln('$name:');
      elements.forEach((s) {
        sb.writeln('  - $s');
      });
    }

    sb.writeln('Inputs: ${inputs}');
    sb.writeln('Output: ${output}');

    sb.writeln('Was diagnostic message handler provided: '
        '${_raw.onDiagnostic == null ? "no" : "yes"}');

    sb.writeln('FileSystem: ${_fileSystem.runtimeType} '
        '(provided: ${_raw.fileSystem.runtimeType})');

    writeList('Additional Dills', _raw.additionalDills);

    sb.writeln('Packages uri: ${_raw.packagesFileUri}');
    sb.writeln('Packages: ${_packages}');

    sb.writeln('Compile SDK: ${compileSdk}');
    sb.writeln('SDK root: ${_sdkRoot} (provided: ${_raw.sdkRoot})');
    sb.writeln('SDK specification: ${_librariesSpecificationUri} '
        '(provided: ${_raw.librariesSpecificationUri})');
    sb.writeln('SDK summary: ${_sdkSummary} (provided: ${_raw.sdkSummary})');

    sb.writeln('Target: ${_target?.name} (provided: ${_raw.target?.name})');

    sb.writeln('throwOnErrorsForDebugging: ${throwOnErrorsForDebugging}');
    sb.writeln('throwOnWarningsForDebugging: ${throwOnWarningsForDebugging}');
    sb.writeln('exit on problem: ${setExitCodeOnProblem}');
    sb.writeln('Embed sources: ${embedSourceText}');
    sb.writeln('debugDump: ${debugDump}');
    sb.writeln('verbose: ${verbose}');
    sb.writeln('verify: ${verify}');
    return '$sb';
  }

  Future<List<int>> _readAsBytes(FileSystemEntity file) async {
    try {
      return await file.readAsBytes();
    } on FileSystemException catch (error) {
      report(
          templateCantReadFile
              .withArguments(error.uri, error.message)
              .withoutLocation(),
          Severity.error);
      return null;
    }
  }
}

/// A [FileSystem] that only allows access to files that have been explicitly
/// allowlisted.
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
