// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.src.options;

import '../compiler.dart' show PackagesDiscoveryProvider;
import 'commandline_options.dart' show Flags;

/// Options used for controlling diagnostic messages.
abstract class DiagnosticOptions {
  const DiagnosticOptions();

  /// If `true`, warnings cause the compilation to fail.
  bool get fatalWarnings;

  /// Emit terse diagnostics without howToFix.
  bool get terseDiagnostics;

  /// If `true`, warnings are not reported.
  bool get suppressWarnings;

  /// If `true`, hints are not reported.
  bool get suppressHints;

  /// Returns `true` if warnings and hints are shown for all packages.
  bool get showAllPackageWarnings;

  /// Returns `true` if warnings and hints are hidden for all packages.
  bool get hidePackageWarnings;

  /// Returns `true` if warnings should be should for [uri].
  bool showPackageWarningsFor(Uri uri);
}

/// Object for passing options to the compiler. Superclasses are used to select
/// subsets of these options, enabling each part of the compiler to depend on
/// as few as possible.
class CompilerOptions implements DiagnosticOptions {
  /// The entry point of the application that is being compiled.
  final Uri entryPoint;

  /// Root location where SDK libraries are found.
  final Uri libraryRoot;

  /// Package root location.
  ///
  /// If not null then [packageConfig] should be null.
  final Uri packageRoot;

  /// Location of the package configuration file.
  ///
  /// If not null then [packageRoot] should be null.
  final Uri packageConfig;

  // TODO(sigmund): Move out of here, maybe to CompilerInput. Options should not
  // hold code, just configuration options.
  final PackagesDiscoveryProvider packagesDiscoveryProvider;

  /// Resolved constant "environment" values passed to the compiler via the `-D`
  /// flags.
  final Map<String, dynamic> environment;

  /// Whether we allow mocking compilation of libraries such as dart:io and
  /// dart:html for unit testing purposes.
  final bool allowMockCompilation;

  /// Whether the native extension syntax is supported by the frontend.
  final bool allowNativeExtensions;

  /// Whether to resolve all functions in the program, not just those reachable
  /// from main. This implies [analyzeOnly] is true as well.
  final bool analyzeAll;

  /// Whether to disable tree-shaking for the main script. This marks all
  /// functions in the main script as reachable (not just a function named
  /// `main`).
  // TODO(sigmund): rename. The current name seems to indicate that only the
  // main function is retained, which is the opposite of what this does.
  final bool analyzeMain;

  /// Whether to run the compiler just for the purpose of analysis. That is, to
  /// run resolution and type-checking alone, but otherwise do not generate any
  /// code.
  final bool analyzeOnly;

  /// Whether to skip analysis of method bodies and field initializers. Implies
  /// [analyzeOnly].
  final bool analyzeSignaturesOnly;

  /// ID associated with this sdk build.
  final String buildId;

  /// Whether there is a build-id available so we can use it on error messages
  /// and in the emitted output of the compiler.
  bool get hasBuildId => buildId != _UNDETERMINED_BUILD_ID;

  /// Location where to generate a map containing details of how deferred
  /// libraries are subdivided.
  final Uri deferredMapUri;

  /// Whether to disable inlining during the backend optimizations.
  // TODO(sigmund): negate, so all flags are positive
  final bool disableInlining;

  /// Diagnostic option: If `true`, warnings cause the compilation to fail.
  final bool fatalWarnings;

  /// Diagnostic option: Emit terse diagnostics without howToFix.
  final bool terseDiagnostics;

  /// Diagnostic option: If `true`, warnings are not reported.
  final bool suppressWarnings;

  /// Diagnostic option: If `true`, hints are not reported.
  final bool suppressHints;

  /// Diagnostic option: List of packages for which warnings and hints are
  /// reported. If `null`, no package warnings or hints are reported. If
  /// empty, all warnings and hints are reported.
  final List<String> _shownPackageWarnings;

  /// Whether to disable global type inference.
  final bool disableTypeInference;

  /// Whether to emit a .json file with a summary of the information used by the
  /// compiler during optimization. This includes resolution details,
  /// dependencies between elements, results of type inference, and the output
  /// code for each function.
  final bool dumpInfo;

  /// Whether we allow passing an extra argument to `assert`, containing a
  /// reason for why an assertion fails. (experimental)
  ///
  /// This is only included so that tests can pass the --assert-message flag
  /// without causing dart2js to crash. The flag has no effect.
  final bool enableAssertMessage;

  /// Whether the user specified a flag to allow the use of dart:mirrors. This
  /// silences a warning produced by the compiler.
  final bool enableExperimentalMirrors;

  /// Whether to enable minification
  // TODO(sigmund): rename to minify
  final bool enableMinification;

  /// Whether to model which native classes are live based on annotations on the
  /// core libraries. If false, all native classes will be included by default.
  final bool enableNativeLiveTypeAnalysis;

  /// Whether to generate code containing checked-mode assignability checks.
  final bool enableTypeAssertions;

  /// Whether to generate code containing user's `assert` statements.
  final bool enableUserAssertions;

  /// Whether to generate output even when there are compile-time errors.
  final bool generateCodeWithCompileTimeErrors;

  /// Whether to generate a source-map file together with the output program.
  final bool generateSourceMap;

  /// URI of the main output if the compiler is generating source maps.
  final Uri outputUri;

  /// Location of the platform configuration file.
  final Uri platformConfigUri;

  /// Whether to emit URIs in the reflection metadata.
  final bool preserveUris;

  /// The locations of serialized data used for resolution.
  final List<Uri> resolutionInputs;

  /// The location of the serialized data from resolution.
  final Uri resolutionOutput;

  /// If `true`, sources are resolved and serialized.
  final bool resolveOnly;

  /// If `true`, sources are only available from serialized data.
  final bool compileOnly;

  /// URI where the compiler should generate the output source map file.
  final Uri sourceMapUri;

  /// The compiler is run from the build bot.
  final bool testMode;

  /// Whether to trust JS-interop annotations. (experimental)
  final bool trustJSInteropTypeAnnotations;

  /// Whether to trust primitive types during inference and optimizations.
  final bool trustPrimitives;

  /// Whether to trust type annotations during inference and optimizations.
  final bool trustTypeAnnotations;

  /// Whether to generate code compliant with content security policy (CSP).
  final bool useContentSecurityPolicy;

  /// Whether to use kernel internally as part of compilation.
  final bool useKernelInSsa;

  /// Preview the unified front-end and compilation from kernel.
  ///
  /// When enabled the compiler will use the unified front-end to compile
  /// sources to kernel, and then continue compilation from the kernel
  /// representation. Setting this flag will implicitly set [useKernelInSsa] to
  /// true as well.
  ///
  /// When this flag is on, the compiler also acccepts reading .dill files from
  /// disk. The compiler reads the sources differently depending on the
  /// extension format.
  final bool useKernel;

  // Whether to use kernel internally for global type inference calculations.
  // TODO(efortuna): Remove this and consolidate with useKernel.
  final bool kernelGlobalInference;

  /// When obfuscating for minification, whether to use the frequency of a name
  /// as an heuristic to pick shorter names.
  final bool useFrequencyNamer;

  /// Whether to generate source-information from both the old and the new
  /// source-information engines. (experimental)
  final bool useMultiSourceInfo;

  /// Whether to use the new source-information implementation for source-maps.
  /// (experimental)
  final bool useNewSourceInfo;

  /// Whether the user requested to use the fast startup emitter. The full
  /// emitter might still be used if the program uses dart:mirrors.
  final bool useStartupEmitter;

  /// Enable verbose printing during compilation. Includes progress messages
  /// during each phase and a time-breakdown between phases at the end.
  final bool verbose;

  /// Track allocations in the JS output.
  ///
  /// This is an experimental feature.
  final bool experimentalTrackAllocations;

  /// The path to the file that contains the profiled allocations.
  ///
  /// The file must contain the Map that was produced by using
  /// [experimentalTrackAllocations] encoded as a JSON map.
  ///
  /// This is an experimental feature.
  final String experimentalAllocationsPath;

  // -------------------------------------------------
  // Options for deprecated features
  // -------------------------------------------------
  // TODO(sigmund): delete these as we delete the underlying features

  /// Whether to preserve comments while scanning (only use for dart:mirrors).
  final bool preserveComments;

  /// Strip option used by dart2dart.
  final List<String> strips;

  /// Create an options object by parsing flags from [options].
  factory CompilerOptions.parse(
      {Uri entryPoint,
      Uri libraryRoot,
      Uri packageRoot,
      Uri packageConfig,
      List<Uri> resolutionInputs,
      Uri resolutionOutput,
      PackagesDiscoveryProvider packagesDiscoveryProvider,
      Map<String, dynamic> environment: const <String, dynamic>{},
      List<String> options}) {
    return new CompilerOptions(
        entryPoint: entryPoint,
        libraryRoot: libraryRoot,
        packageRoot: packageRoot,
        packageConfig: packageConfig,
        packagesDiscoveryProvider: packagesDiscoveryProvider,
        environment: environment,
        allowMockCompilation: _hasOption(options, Flags.allowMockCompilation),
        allowNativeExtensions: _hasOption(options, Flags.allowNativeExtensions),
        analyzeAll: _hasOption(options, Flags.analyzeAll),
        analyzeMain: _hasOption(options, Flags.analyzeMain),
        analyzeOnly: _hasOption(options, Flags.analyzeOnly),
        analyzeSignaturesOnly: _hasOption(options, Flags.analyzeSignaturesOnly),
        buildId: _extractStringOption(
            options, '--build-id=', _UNDETERMINED_BUILD_ID),
        deferredMapUri: _extractUriOption(options, '--deferred-map='),
        fatalWarnings: _hasOption(options, Flags.fatalWarnings),
        terseDiagnostics: _hasOption(options, Flags.terse),
        suppressWarnings: _hasOption(options, Flags.suppressWarnings),
        suppressHints: _hasOption(options, Flags.suppressHints),
        shownPackageWarnings:
            _extractOptionalCsvOption(options, Flags.showPackageWarnings),
        disableInlining: _hasOption(options, Flags.disableInlining),
        disableTypeInference: _hasOption(options, Flags.disableTypeInference),
        dumpInfo: _hasOption(options, Flags.dumpInfo),
        enableExperimentalMirrors:
            _hasOption(options, Flags.enableExperimentalMirrors),
        enableMinification: _hasOption(options, Flags.minify),
        enableNativeLiveTypeAnalysis:
            !_hasOption(options, Flags.disableNativeLiveTypeAnalysis),
        enableTypeAssertions: _hasOption(options, Flags.enableCheckedMode),
        enableUserAssertions: _hasOption(options, Flags.enableCheckedMode) ||
            _hasOption(options, Flags.enableAsserts),
        experimentalTrackAllocations:
            _hasOption(options, Flags.experimentalTrackAllocations),
        experimentalAllocationsPath: _extractStringOption(
            options, "${Flags.experimentalAllocationsPath}=", null),
        generateCodeWithCompileTimeErrors:
            _hasOption(options, Flags.generateCodeWithCompileTimeErrors),
        generateSourceMap: !_hasOption(options, Flags.noSourceMaps),
        kernelGlobalInference: _hasOption(options, Flags.kernelGlobalInference),
        outputUri: _extractUriOption(options, '--out='),
        platformConfigUri:
            _resolvePlatformConfigFromOptions(libraryRoot, options),
        preserveComments: _hasOption(options, Flags.preserveComments),
        preserveUris: _hasOption(options, Flags.preserveUris),
        resolutionInputs: resolutionInputs,
        resolutionOutput: resolutionOutput,
        resolveOnly: _hasOption(options, Flags.resolveOnly),
        sourceMapUri: _extractUriOption(options, '--source-map='),
        strips: _extractCsvOption(options, '--force-strip='),
        testMode: _hasOption(options, Flags.testMode),
        trustJSInteropTypeAnnotations:
            _hasOption(options, Flags.trustJSInteropTypeAnnotations),
        trustPrimitives: _hasOption(options, Flags.trustPrimitives),
        trustTypeAnnotations: _hasOption(options, Flags.trustTypeAnnotations),
        useContentSecurityPolicy:
            _hasOption(options, Flags.useContentSecurityPolicy),
        useKernelInSsa: _hasOption(options, Flags.useKernelInSsa),
        useKernel: _hasOption(options, Flags.useKernel),
        useFrequencyNamer:
            !_hasOption(options, Flags.noFrequencyBasedMinification),
        useMultiSourceInfo: _hasOption(options, Flags.useMultiSourceInfo),
        useNewSourceInfo: _hasOption(options, Flags.useNewSourceInfo),
        useStartupEmitter: _hasOption(options, Flags.fastStartup),
        verbose: _hasOption(options, Flags.verbose));
  }

  /// Creates an option object for the compiler.
  ///
  /// This validates and normalizes dependent options to be consistent. For
  /// example, if [analyzeAll] is true, the resulting options object will also
  /// have [analyzeOnly] as true.
  factory CompilerOptions(
      {Uri entryPoint,
      Uri libraryRoot,
      Uri packageRoot,
      Uri packageConfig,
      PackagesDiscoveryProvider packagesDiscoveryProvider,
      Map<String, dynamic> environment: const <String, dynamic>{},
      bool allowMockCompilation: false,
      bool allowNativeExtensions: false,
      bool analyzeAll: false,
      bool analyzeMain: false,
      bool analyzeOnly: false,
      bool analyzeSignaturesOnly: false,
      String buildId: _UNDETERMINED_BUILD_ID,
      Uri deferredMapUri: null,
      bool fatalWarnings: false,
      bool terseDiagnostics: false,
      bool suppressWarnings: false,
      bool suppressHints: false,
      List<String> shownPackageWarnings: null,
      bool disableInlining: false,
      bool disableTypeInference: false,
      bool dumpInfo: false,
      bool enableAssertMessage: true,
      bool enableExperimentalMirrors: false,
      bool enableMinification: false,
      bool enableNativeLiveTypeAnalysis: true,
      bool enableTypeAssertions: false,
      bool enableUserAssertions: false,
      bool experimentalTrackAllocations: false,
      String experimentalAllocationsPath: null,
      bool generateCodeWithCompileTimeErrors: false,
      bool generateSourceMap: true,
      bool kernelGlobalInference: false,
      Uri outputUri: null,
      Uri platformConfigUri: null,
      bool preserveComments: false,
      bool preserveUris: false,
      List<Uri> resolutionInputs: null,
      Uri resolutionOutput: null,
      bool resolveOnly: false,
      Uri sourceMapUri: null,
      List<String> strips: const [],
      bool testMode: false,
      bool trustJSInteropTypeAnnotations: false,
      bool trustPrimitives: false,
      bool trustTypeAnnotations: false,
      bool useContentSecurityPolicy: false,
      bool useKernelInSsa: false,
      bool useKernel: false,
      bool useFrequencyNamer: true,
      bool useMultiSourceInfo: false,
      bool useNewSourceInfo: false,
      bool useStartupEmitter: false,
      bool verbose: false}) {
    // TODO(sigmund): should entrypoint be here? should we validate it is not
    // null? In unittests we use the same compiler to analyze or build multiple
    // entrypoints.
    if (libraryRoot == null) {
      throw new ArgumentError("[libraryRoot] is null.");
    }
    if (!libraryRoot.path.endsWith("/")) {
      throw new ArgumentError("[libraryRoot] must end with a /");
    }
    if (packageRoot != null && packageConfig != null) {
      throw new ArgumentError("Only one of [packageRoot] or [packageConfig] "
          "may be given.");
    }
    if (packageRoot != null && !packageRoot.path.endsWith("/")) {
      throw new ArgumentError("[packageRoot] must end with a /");
    }
    if (!analyzeOnly) {
      if (allowNativeExtensions) {
        throw new ArgumentError(
            "${Flags.allowNativeExtensions} is only supported in combination "
            "with ${Flags.analyzeOnly}");
      }
    }
    return new CompilerOptions._(entryPoint, libraryRoot, packageRoot,
        packageConfig, packagesDiscoveryProvider, environment,
        allowMockCompilation: allowMockCompilation,
        allowNativeExtensions: allowNativeExtensions,
        analyzeAll: analyzeAll || resolveOnly,
        analyzeMain: analyzeMain,
        analyzeOnly:
            analyzeOnly || analyzeSignaturesOnly || analyzeAll || resolveOnly,
        analyzeSignaturesOnly: analyzeSignaturesOnly,
        buildId: buildId,
        deferredMapUri: deferredMapUri,
        fatalWarnings: fatalWarnings,
        terseDiagnostics: terseDiagnostics,
        suppressWarnings: suppressWarnings,
        suppressHints: suppressHints,
        shownPackageWarnings: shownPackageWarnings,
        // TODO(sigmund): remove once we support inlining and type-inference
        // with `useKernel`.
        disableInlining: disableInlining || useKernel,
        disableTypeInference: disableTypeInference || useKernel,
        dumpInfo: dumpInfo,
        enableAssertMessage: enableAssertMessage,
        enableExperimentalMirrors: enableExperimentalMirrors,
        enableMinification: enableMinification,
        enableNativeLiveTypeAnalysis: enableNativeLiveTypeAnalysis,
        enableTypeAssertions: enableTypeAssertions,
        enableUserAssertions: enableUserAssertions,
        experimentalTrackAllocations: experimentalTrackAllocations,
        experimentalAllocationsPath: experimentalAllocationsPath,
        generateCodeWithCompileTimeErrors:
            generateCodeWithCompileTimeErrors && !useKernel,
        generateSourceMap: generateSourceMap,
        kernelGlobalInference: kernelGlobalInference,
        outputUri: outputUri,
        platformConfigUri: platformConfigUri ??
            _resolvePlatformConfig(libraryRoot, null, const []),
        preserveComments: preserveComments,
        preserveUris: preserveUris,
        resolutionInputs: resolutionInputs,
        resolutionOutput: resolutionOutput,
        resolveOnly: resolveOnly,
        sourceMapUri: sourceMapUri,
        strips: strips,
        testMode: testMode,
        trustJSInteropTypeAnnotations: trustJSInteropTypeAnnotations,
        trustPrimitives: trustPrimitives,
        trustTypeAnnotations: trustTypeAnnotations,
        useContentSecurityPolicy: useContentSecurityPolicy,
        useKernelInSsa: useKernelInSsa || useKernel,
        useKernel: useKernel,
        useFrequencyNamer: useFrequencyNamer,
        useMultiSourceInfo: useMultiSourceInfo,
        useNewSourceInfo: useNewSourceInfo,
        useStartupEmitter: useStartupEmitter,
        verbose: verbose);
  }

  CompilerOptions._(this.entryPoint, this.libraryRoot, this.packageRoot,
      this.packageConfig, this.packagesDiscoveryProvider, this.environment,
      {this.allowMockCompilation: false,
      this.allowNativeExtensions: false,
      this.analyzeAll: false,
      this.analyzeMain: false,
      this.analyzeOnly: false,
      this.analyzeSignaturesOnly: false,
      this.buildId: _UNDETERMINED_BUILD_ID,
      this.deferredMapUri: null,
      this.fatalWarnings: false,
      this.terseDiagnostics: false,
      this.suppressWarnings: false,
      this.suppressHints: false,
      List<String> shownPackageWarnings: null,
      this.disableInlining: false,
      this.disableTypeInference: false,
      this.dumpInfo: false,
      this.enableAssertMessage: true,
      this.enableExperimentalMirrors: false,
      this.enableMinification: false,
      this.enableNativeLiveTypeAnalysis: false,
      this.enableTypeAssertions: false,
      this.enableUserAssertions: false,
      this.experimentalTrackAllocations: false,
      this.experimentalAllocationsPath: null,
      this.generateCodeWithCompileTimeErrors: false,
      this.generateSourceMap: true,
      this.kernelGlobalInference: false,
      this.outputUri: null,
      this.platformConfigUri: null,
      this.preserveComments: false,
      this.preserveUris: false,
      this.resolutionInputs: null,
      this.resolutionOutput: null,
      this.resolveOnly: false,
      this.compileOnly: false,
      this.sourceMapUri: null,
      this.strips: const [],
      this.testMode: false,
      this.trustJSInteropTypeAnnotations: false,
      this.trustPrimitives: false,
      this.trustTypeAnnotations: false,
      this.useContentSecurityPolicy: false,
      this.useKernelInSsa: false,
      this.useKernel: false,
      this.useFrequencyNamer: false,
      this.useMultiSourceInfo: false,
      this.useNewSourceInfo: false,
      this.useStartupEmitter: false,
      this.verbose: false})
      : _shownPackageWarnings = shownPackageWarnings;

  /// Creates a copy of the [CompilerOptions] where the provided non-null
  /// option values replace existing.
  static CompilerOptions copy(CompilerOptions options,
      {entryPoint,
      libraryRoot,
      packageRoot,
      packageConfig,
      packagesDiscoveryProvider,
      environment,
      allowMockCompilation,
      allowNativeExtensions,
      analyzeAll,
      analyzeMain,
      analyzeOnly,
      analyzeSignaturesOnly,
      buildId,
      deferredMapUri,
      fatalWarnings,
      terseDiagnostics,
      suppressWarnings,
      suppressHints,
      List<String> shownPackageWarnings,
      disableInlining,
      disableTypeInference,
      dumpInfo,
      enableAssertMessage,
      enableExperimentalMirrors,
      enableMinification,
      enableNativeLiveTypeAnalysis,
      enableTypeAssertions,
      enableUserAssertions,
      experimentalTrackAllocations,
      experimentalAllocationsPath,
      generateCodeWithCompileTimeErrors,
      generateSourceMap,
      kernelGlobalInference,
      outputUri,
      platformConfigUri,
      preserveComments,
      preserveUris,
      resolutionInputs,
      resolutionOutput,
      resolveOnly,
      compileOnly,
      sourceMapUri,
      strips,
      testMode,
      trustJSInteropTypeAnnotations,
      trustPrimitives,
      trustTypeAnnotations,
      useContentSecurityPolicy,
      useKernelInSsa,
      useKernel,
      useFrequencyNamer,
      useMultiSourceInfo,
      useNewSourceInfo,
      useStartupEmitter,
      verbose}) {
    return new CompilerOptions._(
        entryPoint ?? options.entryPoint,
        libraryRoot ?? options.libraryRoot,
        packageRoot ?? options.packageRoot,
        packageConfig ?? options.packageConfig,
        packagesDiscoveryProvider ?? options.packagesDiscoveryProvider,
        environment ?? options.environment,
        allowMockCompilation:
            allowMockCompilation ?? options.allowMockCompilation,
        allowNativeExtensions:
            allowNativeExtensions ?? options.allowNativeExtensions,
        analyzeAll: analyzeAll ?? options.analyzeAll,
        analyzeMain: analyzeMain ?? options.analyzeMain,
        analyzeOnly: analyzeOnly ?? options.analyzeOnly,
        analyzeSignaturesOnly:
            analyzeSignaturesOnly ?? options.analyzeSignaturesOnly,
        buildId: buildId ?? options.buildId,
        deferredMapUri: deferredMapUri ?? options.deferredMapUri,
        fatalWarnings: fatalWarnings ?? options.fatalWarnings,
        terseDiagnostics: terseDiagnostics ?? options.terseDiagnostics,
        suppressWarnings: suppressWarnings ?? options.suppressWarnings,
        suppressHints: suppressHints ?? options.suppressHints,
        shownPackageWarnings:
            shownPackageWarnings ?? options._shownPackageWarnings,
        disableInlining: disableInlining ?? options.disableInlining,
        disableTypeInference:
            disableTypeInference ?? options.disableTypeInference,
        dumpInfo: dumpInfo ?? options.dumpInfo,
        enableAssertMessage: enableAssertMessage ?? options.enableAssertMessage,
        enableExperimentalMirrors:
            enableExperimentalMirrors ?? options.enableExperimentalMirrors,
        enableMinification: enableMinification ?? options.enableMinification,
        enableNativeLiveTypeAnalysis: enableNativeLiveTypeAnalysis ??
            options.enableNativeLiveTypeAnalysis,
        enableTypeAssertions:
            enableTypeAssertions ?? options.enableTypeAssertions,
        enableUserAssertions:
            enableUserAssertions ?? options.enableUserAssertions,
        experimentalTrackAllocations: experimentalTrackAllocations ??
            options.experimentalTrackAllocations,
        experimentalAllocationsPath:
            experimentalAllocationsPath ?? options.experimentalAllocationsPath,
        generateCodeWithCompileTimeErrors: generateCodeWithCompileTimeErrors ??
            options.generateCodeWithCompileTimeErrors,
        generateSourceMap: generateSourceMap ?? options.generateSourceMap,
        kernelGlobalInference:
            kernelGlobalInference ?? options.kernelGlobalInference,
        outputUri: outputUri ?? options.outputUri,
        platformConfigUri: platformConfigUri ?? options.platformConfigUri,
        preserveComments: preserveComments ?? options.preserveComments,
        preserveUris: preserveUris ?? options.preserveUris,
        resolutionInputs: resolutionInputs ?? options.resolutionInputs,
        resolutionOutput: resolutionOutput ?? options.resolutionOutput,
        resolveOnly: resolveOnly ?? options.resolveOnly,
        compileOnly: compileOnly ?? options.compileOnly,
        sourceMapUri: sourceMapUri ?? options.sourceMapUri,
        strips: strips ?? options.strips,
        testMode: testMode ?? options.testMode,
        trustJSInteropTypeAnnotations: trustJSInteropTypeAnnotations ??
            options.trustJSInteropTypeAnnotations,
        trustPrimitives: trustPrimitives ?? options.trustPrimitives,
        trustTypeAnnotations:
            trustTypeAnnotations ?? options.trustTypeAnnotations,
        useContentSecurityPolicy:
            useContentSecurityPolicy ?? options.useContentSecurityPolicy,
        useKernelInSsa: useKernelInSsa ?? options.useKernelInSsa,
        useKernel: useKernel ?? options.useKernel,
        useFrequencyNamer: useFrequencyNamer ?? options.useFrequencyNamer,
        useMultiSourceInfo: useMultiSourceInfo ?? options.useMultiSourceInfo,
        useNewSourceInfo: useNewSourceInfo ?? options.useNewSourceInfo,
        useStartupEmitter: useStartupEmitter ?? options.useStartupEmitter,
        verbose: verbose ?? options.verbose);
  }

  /// Returns `true` if warnings and hints are shown for all packages.
  bool get showAllPackageWarnings {
    return _shownPackageWarnings != null && _shownPackageWarnings.isEmpty;
  }

  /// Returns `true` if warnings and hints are hidden for all packages.
  bool get hidePackageWarnings => _shownPackageWarnings == null;

  /// Returns `true` if warnings should be should for [uri].
  bool showPackageWarningsFor(Uri uri) {
    if (showAllPackageWarnings) {
      return true;
    }
    if (_shownPackageWarnings != null) {
      return uri.scheme == 'package' &&
          _shownPackageWarnings.contains(uri.pathSegments.first);
    }
    return false;
  }
}

String _extractStringOption(
    List<String> options, String prefix, String defaultValue) {
  for (String option in options) {
    if (option.startsWith(prefix)) {
      return option.substring(prefix.length);
    }
  }
  return defaultValue;
}

Uri _extractUriOption(List<String> options, String prefix) {
  var option = _extractStringOption(options, prefix, null);
  return (option == null) ? null : Uri.parse(option);
}

// CSV: Comma separated values.
List<String> _extractCsvOption(List<String> options, String prefix) {
  for (String option in options) {
    if (option.startsWith(prefix)) {
      return option.substring(prefix.length).split(',');
    }
  }
  return const <String>[];
}

bool _hasOption(List<String> options, String option) {
  return options.indexOf(option) >= 0;
}

/// Extract list of comma separated values provided for [flag]. Returns an
/// empty list if [option] contain [flag] without arguments. Returns `null` if
/// [option] doesn't contain [flag] with or without arguments.
List<String> _extractOptionalCsvOption(List<String> options, String flag) {
  String prefix = '$flag=';
  for (String option in options) {
    if (option == flag) {
      return const <String>[];
    }
    if (option.startsWith(flag)) {
      return option.substring(prefix.length).split(',');
    }
  }
  return null;
}

Uri _resolvePlatformConfig(
    Uri libraryRoot, String platformConfigPath, Iterable<String> categories) {
  if (platformConfigPath != null) {
    return libraryRoot.resolve(platformConfigPath);
  } else {
    if (categories.length == 0) {
      return libraryRoot.resolve(_clientPlatform);
    }
    assert(categories.length <= 2);
    if (categories.contains("Client")) {
      if (categories.contains("Server")) {
        return libraryRoot.resolve(_sharedPlatform);
      }
      return libraryRoot.resolve(_clientPlatform);
    }
    assert(categories.contains("Server"));
    return libraryRoot.resolve(_serverPlatform);
  }
}

Uri _resolvePlatformConfigFromOptions(Uri libraryRoot, List<String> options) {
  return _resolvePlatformConfig(
      libraryRoot,
      _extractStringOption(options, "--platform-config=", null),
      _extractCsvOption(options, '--categories='));
}

/// Locations of the platform descriptor files relative to the library root.
const String _clientPlatform = "lib/dart_client.platform";
const String _serverPlatform = "lib/dart_server.platform";
const String _sharedPlatform = "lib/dart_shared.platform";

const String _UNDETERMINED_BUILD_ID = "build number could not be determined";
