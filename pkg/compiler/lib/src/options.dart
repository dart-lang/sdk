// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.src.options;

import 'commandline_options.dart' show Flags;
import '../compiler.dart' show PackagesDiscoveryProvider;

/// Options used for parsing.
///
/// Use this to conditionally support certain constructs, e.g.,
/// experimental ones.
abstract class ParserOptions {
  const ParserOptions();

  /// Support parsing of generic method declarations, and invocations of
  /// methods where type arguments are passed.
  bool get enableGenericMethodSyntax;
}

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
class CompilerOptions implements DiagnosticOptions, ParserOptions {
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
  final bool enableAssertMessage;

  /// Support parsing of generic method declarations, and invocations of
  /// methods where type arguments are passed.
  final bool enableGenericMethodSyntax;

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

  /// Whether some values are cached for reuse in incremental compilation.
  /// Incremental compilation allows calling `Compiler.run` more than once
  /// (experimental).
  final bool hasIncrementalSupport;

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

  // If `true`, sources are resolved and serialized.
  final bool resolveOnly;

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

  /// Use the experimental CPS based backend.
  final bool useCpsIr;

  /// When obfuscating for minification, whether to use the frequency of a name
  /// as an heuristic to pick shorter names.
  final bool useFrequencyNamer;

  /// Whether to use the new source-information implementation for source-maps.
  /// (experimental)
  final bool useNewSourceInfo;

  /// Whether the user requested to use the fast startup emitter. The full
  /// emitter might still be used if the program uses dart:mirrors.
  final bool useStartupEmitter;

  /// Enable verbose printing during compilation. Includes progress messages
  /// during each phase and a time-breakdown between phases at the end.
  final bool verbose;

  // -------------------------------------------------
  // Options for deprecated features
  // -------------------------------------------------
  // TODO(sigmund): delete these as we delete the underlying features

  /// Whether to preserve comments while scanning (only use for dart:mirrors).
  final bool preserveComments;

  /// Whether to emit JavaScript (false enables dart2dart).
  final bool emitJavaScript;

  /// When using dart2dart, whether to use the multi file format.
  final bool dart2dartMultiFile;

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
        dart2dartMultiFile: _hasOption(options, '--output-type=dart-multi'),
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
        emitJavaScript: !(_hasOption(options, '--output-type=dart') ||
            _hasOption(options, '--output-type=dart-multi')),
        enableAssertMessage: _hasOption(options, Flags.enableAssertMessage),
        enableGenericMethodSyntax:
            _hasOption(options, Flags.genericMethodSyntax),
        enableExperimentalMirrors:
            _hasOption(options, Flags.enableExperimentalMirrors),
        enableMinification: _hasOption(options, Flags.minify),
        enableNativeLiveTypeAnalysis:
            !_hasOption(options, Flags.disableNativeLiveTypeAnalysis),
        enableTypeAssertions: _hasOption(options, Flags.enableCheckedMode),
        enableUserAssertions: _hasOption(options, Flags.enableCheckedMode),
        generateCodeWithCompileTimeErrors:
            _hasOption(options, Flags.generateCodeWithCompileTimeErrors),
        generateSourceMap: !_hasOption(options, Flags.noSourceMaps),
        hasIncrementalSupport: _forceIncrementalSupport ||
            _hasOption(options, Flags.incrementalSupport),
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
        useCpsIr: _hasOption(options, Flags.useCpsIr),
        useFrequencyNamer:
            !_hasOption(options, Flags.noFrequencyBasedMinification),
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
      bool dart2dartMultiFile: false,
      Uri deferredMapUri: null,
      bool fatalWarnings: false,
      bool terseDiagnostics: false,
      bool suppressWarnings: false,
      bool suppressHints: false,
      List<String> shownPackageWarnings: null,
      bool disableInlining: false,
      bool disableTypeInference: false,
      bool dumpInfo: false,
      bool emitJavaScript: true,
      bool enableAssertMessage: false,
      bool enableGenericMethodSyntax: false,
      bool enableExperimentalMirrors: false,
      bool enableMinification: false,
      bool enableNativeLiveTypeAnalysis: true,
      bool enableTypeAssertions: false,
      bool enableUserAssertions: false,
      bool generateCodeWithCompileTimeErrors: false,
      bool generateSourceMap: true,
      bool hasIncrementalSupport: false,
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
      bool useCpsIr: false,
      bool useFrequencyNamer: true,
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
        dart2dartMultiFile: dart2dartMultiFile,
        deferredMapUri: deferredMapUri,
        fatalWarnings: fatalWarnings,
        terseDiagnostics: terseDiagnostics,
        suppressWarnings: suppressWarnings,
        suppressHints: suppressHints,
        shownPackageWarnings: shownPackageWarnings,
        disableInlining: disableInlining || hasIncrementalSupport,
        disableTypeInference: disableTypeInference || !emitJavaScript,
        dumpInfo: dumpInfo,
        emitJavaScript: emitJavaScript,
        enableAssertMessage: enableAssertMessage,
        enableGenericMethodSyntax: enableGenericMethodSyntax,
        enableExperimentalMirrors: enableExperimentalMirrors,
        enableMinification: enableMinification,
        enableNativeLiveTypeAnalysis: enableNativeLiveTypeAnalysis,
        enableTypeAssertions: enableTypeAssertions,
        enableUserAssertions: enableUserAssertions,
        generateCodeWithCompileTimeErrors: generateCodeWithCompileTimeErrors,
        generateSourceMap: generateSourceMap,
        hasIncrementalSupport: hasIncrementalSupport,
        outputUri: outputUri,
        platformConfigUri: platformConfigUri ??
            _resolvePlatformConfig(
                libraryRoot, null, !emitJavaScript, const []),
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
        useCpsIr: useCpsIr,
        useFrequencyNamer: useFrequencyNamer,
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
      this.dart2dartMultiFile: false,
      this.deferredMapUri: null,
      this.fatalWarnings: false,
      this.terseDiagnostics: false,
      this.suppressWarnings: false,
      this.suppressHints: false,
      List<String> shownPackageWarnings: null,
      this.disableInlining: false,
      this.disableTypeInference: false,
      this.dumpInfo: false,
      this.emitJavaScript: true,
      this.enableAssertMessage: false,
      this.enableGenericMethodSyntax: false,
      this.enableExperimentalMirrors: false,
      this.enableMinification: false,
      this.enableNativeLiveTypeAnalysis: false,
      this.enableTypeAssertions: false,
      this.enableUserAssertions: false,
      this.generateCodeWithCompileTimeErrors: false,
      this.generateSourceMap: true,
      this.hasIncrementalSupport: false,
      this.outputUri: null,
      this.platformConfigUri: null,
      this.preserveComments: false,
      this.preserveUris: false,
      this.resolutionInputs: null,
      this.resolutionOutput: null,
      this.resolveOnly: false,
      this.sourceMapUri: null,
      this.strips: const [],
      this.testMode: false,
      this.trustJSInteropTypeAnnotations: false,
      this.trustPrimitives: false,
      this.trustTypeAnnotations: false,
      this.useContentSecurityPolicy: false,
      this.useCpsIr: false,
      this.useFrequencyNamer: false,
      this.useNewSourceInfo: false,
      this.useStartupEmitter: false,
      this.verbose: false})
      : _shownPackageWarnings = shownPackageWarnings;

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

Uri _resolvePlatformConfig(Uri libraryRoot, String platformConfigPath,
    bool isDart2Dart, Iterable<String> categories) {
  if (platformConfigPath != null) {
    return libraryRoot.resolve(platformConfigPath);
  } else if (isDart2Dart) {
    return libraryRoot.resolve(_dart2dartPlatform);
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
      _hasOption(options, '--output-type=dart'),
      _extractCsvOption(options, '--categories='));
}

/// Locations of the platform descriptor files relative to the library root.
const String _clientPlatform = "lib/dart_client.platform";
const String _serverPlatform = "lib/dart_server.platform";
const String _sharedPlatform = "lib/dart_shared.platform";
const String _dart2dartPlatform = "lib/dart2dart.platform";

const String _UNDETERMINED_BUILD_ID = "build number could not be determined";
const bool _forceIncrementalSupport =
    const bool.fromEnvironment('DART2JS_EXPERIMENTAL_INCREMENTAL_SUPPORT');
