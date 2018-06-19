// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.src.options;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

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
  Uri entryPoint;

  /// Root location where SDK libraries are found.
  Uri libraryRoot;

  /// Package root location.
  ///
  /// If not null then [packageConfig] should be null.
  Uri packageRoot;

  /// Location of the package configuration file.
  ///
  /// If not null then [packageRoot] should be null.
  Uri packageConfig;

  // TODO(sigmund): Move out of here, maybe to CompilerInput. Options should not
  // hold code, just configuration options.
  PackagesDiscoveryProvider packagesDiscoveryProvider;

  /// Resolved constant "environment" values passed to the compiler via the `-D`
  /// flags.
  Map<String, String> environment = const <String, String>{};

  /// A possibly null state object for kernel compilation.
  fe.InitializedCompilerState kernelInitializedCompilerState;

  /// Whether we allow mocking compilation of libraries such as dart:io and
  /// dart:html for unit testing purposes.
  bool allowMockCompilation = false;

  /// Whether to resolve all functions in the program, not just those reachable
  /// from main. This implies [analyzeOnly] is true as well.
  bool analyzeAll = false;

  /// Whether to disable tree-shaking for the main script. This marks all
  /// functions in the main script as reachable (not just a function named
  /// `main`).
  // TODO(sigmund): rename. The current name seems to indicate that only the
  // main function is retained, which is the opposite of what this does.
  bool analyzeMain = false;

  /// Whether to run the compiler just for the purpose of analysis. That is, to
  /// run resolution and type-checking alone, but otherwise do not generate any
  /// code.
  bool analyzeOnly = false;

  /// Whether to skip analysis of method bodies and field initializers. Implies
  /// [analyzeOnly].
  bool analyzeSignaturesOnly = false;

  /// Sets a combination of flags for benchmarking 'production' mode.
  bool benchmarkingProduction = false;

  /// ID associated with this sdk build.
  String buildId = _UNDETERMINED_BUILD_ID;

  /// Whether there is a build-id available so we can use it on error messages
  /// and in the emitted output of the compiler.
  bool get hasBuildId => buildId != _UNDETERMINED_BUILD_ID;

  /// Whether to compile for the server category. This is used to compile to JS
  /// that is intended to be run on server-side VMs like nodejs.
  bool compileForServer = false;

  /// Location where to generate a map containing details of how deferred
  /// libraries are subdivided.
  Uri deferredMapUri;

  /// Whether to disable inlining during the backend optimizations.
  // TODO(sigmund): negate, so all flags are positive
  bool disableInlining = false;

  /// Disable deferred loading, instead generate everything in one output unit.
  /// Note: the resulting program still correctly checks that loadLibrary &
  /// checkLibrary calls are correct.
  bool disableProgramSplit = false;

  /// Diagnostic option: If `true`, warnings cause the compilation to fail.
  bool fatalWarnings = false;

  /// Diagnostic option: Emit terse diagnostics without howToFix.
  bool terseDiagnostics = false;

  /// Diagnostic option: If `true`, warnings are not reported.
  bool suppressWarnings = false;

  /// Diagnostic option: If `true`, hints are not reported.
  bool suppressHints = false;

  /// Diagnostic option: List of packages for which warnings and hints are
  /// reported. If `null`, no package warnings or hints are reported. If
  /// empty, all warnings and hints are reported.
  List<String> shownPackageWarnings; // &&&&&

  /// Whether to disable global type inference.
  bool disableTypeInference = false;

  /// Whether to disable optimization for need runtime type information.
  bool disableRtiOptimization = false;

  /// Whether to emit a .json file with a summary of the information used by the
  /// compiler during optimization. This includes resolution details,
  /// dependencies between elements, results of type inference, and the output
  /// code for each function.
  bool dumpInfo = false;

  /// Whether we allow passing an extra argument to `assert`, containing a
  /// reason for why an assertion fails. (experimental)
  ///
  /// This is only included so that tests can pass the --assert-message flag
  /// without causing dart2js to crash. The flag has no effect.
  bool enableAssertMessage = true;

  /// Whether the user specified a flag to allow the use of dart:mirrors. This
  /// silences a warning produced by the compiler.
  bool enableExperimentalMirrors = false;

  /// Whether to enable minification
  // TODO(sigmund): rename to minify
  bool enableMinification = false;

  /// Whether to model which native classes are live based on annotations on the
  /// core libraries. If false, all native classes will be included by default.
  bool enableNativeLiveTypeAnalysis = true;

  /// Whether to generate code containing checked-mode assignability checks.
  bool enableTypeAssertions = false;

  /// Whether to generate code containing user's `assert` statements.
  bool enableUserAssertions = false;

  /// Whether to generate output even when there are compile-time errors.
  bool generateCodeWithCompileTimeErrors = false;

  /// Whether to generate a source-map file together with the output program.
  bool generateSourceMap = true;

  /// URI of the main output if the compiler is generating source maps.
  Uri outputUri;

  /// Location of the platform configuration file.
  // TODO(sigmund): deprecate and remove, use only [librariesSpecificationUri]
  Uri platformConfigUri;

  /// Location of the libraries specification file.
  Uri librariesSpecificationUri;

  /// Location of the kernel platform `.dill` files.
  Uri platformBinaries;

  /// URI where the compiler should generate the output source map file.
  Uri sourceMapUri;

  /// The compiler is run from the build bot.
  bool testMode = false;

  /// Whether to trust JS-interop annotations. (experimental)
  bool trustJSInteropTypeAnnotations = false;

  /// Whether to trust primitive types during inference and optimizations.
  bool trustPrimitives = false;

  /// Whether to trust type annotations during inference and optimizations.
  bool trustTypeAnnotations = false;

  /// Whether to omit implicit strong mode checks.
  bool omitImplicitChecks = false;

  /// Whether to omit class type arguments only needed for `toString` on
  /// `RuntimeType`.
  bool laxRuntimeTypeToString = false;

  /// What should the compiler do with type assertions of assignments.
  ///
  /// This is an internal configuration option derived from other flags.
  CheckPolicy assignmentCheckPolicy;

  /// What should the compiler do with parameter type assertions.
  ///
  /// This is an internal configuration option derived from other flags.
  CheckPolicy parameterCheckPolicy;

  /// What should the compiler do with implicit downcasts.
  ///
  /// This is an internal configuration option derived from other flags.
  CheckPolicy implicitDowncastCheckPolicy;

  /// Whether to generate code compliant with content security policy (CSP).
  bool useContentSecurityPolicy = false;

  /// Enables strong mode in dart2js.
  bool strongMode = true;

  /// When obfuscating for minification, whether to use the frequency of a name
  /// as an heuristic to pick shorter names.
  bool useFrequencyNamer = true;

  /// Whether to generate source-information from both the old and the new
  /// source-information engines. (experimental)
  bool useMultiSourceInfo = false;

  /// Whether to use the new source-information implementation for source-maps.
  /// (experimental)
  bool useNewSourceInfo = false;

  /// Whether the user requested to use the fast startup emitter. The full
  /// emitter might still be used if the program uses dart:mirrors.
  bool useStartupEmitter = false;

  /// Enable verbose printing during compilation. Includes progress messages
  /// during each phase and a time-breakdown between phases at the end.
  bool verbose = false;

  /// Track allocations in the JS output.
  ///
  /// This is an experimental feature.
  bool experimentalTrackAllocations = false;

  /// The path to the file that contains the profiled allocations.
  ///
  /// The file must contain the Map that was produced by using
  /// [experimentalTrackAllocations] encoded as a JSON map.
  ///
  /// This is an experimental feature.
  String experimentalAllocationsPath;

  // -------------------------------------------------
  // Options for deprecated features
  // -------------------------------------------------
  // TODO(sigmund): delete these as we delete the underlying features

  /// Whether to start `async` functions synchronously.
  bool startAsyncSynchronously = false;

  /// Create an options object by parsing flags from [options].
  static CompilerOptions parse(List<String> options,
      {Uri libraryRoot, Uri platformBinaries}) {
    return new CompilerOptions()
      ..libraryRoot = libraryRoot
      ..allowMockCompilation = _hasOption(options, Flags.allowMockCompilation)
      ..analyzeAll = _hasOption(options, Flags.analyzeAll)
      ..analyzeMain = _hasOption(options, Flags.analyzeMain)
      ..analyzeOnly = _hasOption(options, Flags.analyzeOnly)
      ..analyzeSignaturesOnly = _hasOption(options, Flags.analyzeSignaturesOnly)
      ..benchmarkingProduction =
          _hasOption(options, Flags.benchmarkingProduction)
      ..buildId =
          _extractStringOption(options, '--build-id=', _UNDETERMINED_BUILD_ID)
      ..compileForServer = _resolveCompileForServerFromOptions(options)
      ..deferredMapUri = _extractUriOption(options, '--deferred-map=')
      ..fatalWarnings = _hasOption(options, Flags.fatalWarnings)
      ..terseDiagnostics = _hasOption(options, Flags.terse)
      ..suppressWarnings = _hasOption(options, Flags.suppressWarnings)
      ..suppressHints = _hasOption(options, Flags.suppressHints)
      ..shownPackageWarnings =
          _extractOptionalCsvOption(options, Flags.showPackageWarnings)
      ..disableInlining = _hasOption(options, Flags.disableInlining)
      ..disableProgramSplit = _hasOption(options, Flags.disableProgramSplit)
      ..disableTypeInference = _hasOption(options, Flags.disableTypeInference)
      ..disableRtiOptimization =
          _hasOption(options, Flags.disableRtiOptimization)
      ..dumpInfo = _hasOption(options, Flags.dumpInfo)
      ..enableExperimentalMirrors =
          _hasOption(options, Flags.enableExperimentalMirrors)
      ..enableMinification = _hasOption(options, Flags.minify)
      ..enableNativeLiveTypeAnalysis =
          !_hasOption(options, Flags.disableNativeLiveTypeAnalysis)
      ..enableTypeAssertions = _hasOption(options, Flags.enableCheckedMode) &&
          !_hasOption(options, Flags.strongMode)
      ..enableUserAssertions = _hasOption(options, Flags.enableCheckedMode) ||
          _hasOption(options, Flags.enableAsserts)
      ..experimentalTrackAllocations =
          _hasOption(options, Flags.experimentalTrackAllocations)
      ..experimentalAllocationsPath = _extractStringOption(
          options, "${Flags.experimentalAllocationsPath}=", null)
      ..generateCodeWithCompileTimeErrors =
          _hasOption(options, Flags.generateCodeWithCompileTimeErrors)
      ..generateSourceMap = !_hasOption(options, Flags.noSourceMaps)
      ..outputUri = _extractUriOption(options, '--out=')
      ..platformConfigUri =
          _resolvePlatformConfigFromOptions(libraryRoot, options)
      ..librariesSpecificationUri = _resolveLibrariesSpecification(libraryRoot)
      ..platformBinaries =
          platformBinaries ?? _extractUriOption(options, '--platform-binaries=')
      ..sourceMapUri = _extractUriOption(options, '--source-map=')
      ..strongMode = _hasOption(options, Flags.strongMode) ||
          !_hasOption(options, Flags.noPreviewDart2)
      ..omitImplicitChecks = _hasOption(options, Flags.omitImplicitChecks)
      ..laxRuntimeTypeToString =
          _hasOption(options, Flags.laxRuntimeTypeToString)
      ..testMode = _hasOption(options, Flags.testMode)
      ..trustJSInteropTypeAnnotations =
          _hasOption(options, Flags.trustJSInteropTypeAnnotations)
      ..trustPrimitives = _hasOption(options, Flags.trustPrimitives)
      ..trustTypeAnnotations = _hasOption(options, Flags.trustTypeAnnotations)
      ..useContentSecurityPolicy =
          _hasOption(options, Flags.useContentSecurityPolicy)
      ..useFrequencyNamer =
          !_hasOption(options, Flags.noFrequencyBasedMinification)
      ..useMultiSourceInfo = _hasOption(options, Flags.useMultiSourceInfo)
      ..useNewSourceInfo = _hasOption(options, Flags.useNewSourceInfo)
      ..useStartupEmitter = _hasOption(options, Flags.fastStartup)
      ..startAsyncSynchronously = !_hasOption(options, Flags.noSyncAsync)
      ..verbose = _hasOption(options, Flags.verbose);
  }

  void validate() {
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
    if (platformBinaries == null) {
      throw new ArgumentError("Missing required ${Flags.platformBinaries}");
    }
  }

  void deriveOptions() {
    if (analyzeSignaturesOnly || analyzeAll) analyzeOnly = true;
    if (benchmarkingProduction) {
      useStartupEmitter = true;
      trustPrimitives = true;
      if (strongMode) {
        omitImplicitChecks = true;
      } else {
        trustTypeAnnotations = true;
      }
    }
    // TODO(johnniwinther): Should we support this in the future?
    generateCodeWithCompileTimeErrors = false;
    if (platformConfigUri == null) {
      platformConfigUri = _resolvePlatformConfig(libraryRoot, null, const []);
    }
    librariesSpecificationUri = _resolveLibrariesSpecification(libraryRoot);

    if (strongMode) {
      // Strong mode always trusts type annotations (inferred or explicit), so
      // assignments checks should be trusted.
      assignmentCheckPolicy = CheckPolicy.trusted;
      if (omitImplicitChecks) {
        parameterCheckPolicy = CheckPolicy.trusted;
        implicitDowncastCheckPolicy = CheckPolicy.trusted;
      } else {
        parameterCheckPolicy = CheckPolicy.checked;
        implicitDowncastCheckPolicy = CheckPolicy.checked;
      }
    } else {
      // The implicit-downcast representation is a strong-mode only feature.
      implicitDowncastCheckPolicy = CheckPolicy.ignored;

      if (enableTypeAssertions) {
        assignmentCheckPolicy = CheckPolicy.checked;
        parameterCheckPolicy = CheckPolicy.checked;
      } else if (trustTypeAnnotations) {
        assignmentCheckPolicy = CheckPolicy.trusted;
        parameterCheckPolicy = CheckPolicy.trusted;
      } else {
        assignmentCheckPolicy = CheckPolicy.ignored;
        parameterCheckPolicy = CheckPolicy.ignored;
      }
    }
  }

  /// Returns `true` if warnings and hints are shown for all packages.
  bool get showAllPackageWarnings {
    return shownPackageWarnings != null && shownPackageWarnings.isEmpty;
  }

  /// Returns `true` if warnings and hints are hidden for all packages.
  bool get hidePackageWarnings => shownPackageWarnings == null;

  /// Returns `true` if warnings should be should for [uri].
  bool showPackageWarningsFor(Uri uri) {
    if (showAllPackageWarnings) {
      return true;
    }
    if (shownPackageWarnings != null) {
      return uri.scheme == 'package' &&
          shownPackageWarnings.contains(uri.pathSegments.first);
    }
    return false;
  }
}

/// Policy for what to do with a type assertion check.
///
/// This enum-like class is used to configure how the compiler treats type
/// assertions during global type inference and codegen.
class CheckPolicy {
  /// Whether the type assertion should be trusted.
  final bool isTrusted;

  /// Whether the type assertion should be emitted and checked.
  final bool isEmitted;

  /// Whether the type assertion should be ignored.
  final bool isIgnored;

  const CheckPolicy(
      {this.isTrusted: false, this.isEmitted: false, this.isIgnored: false});

  static const trusted = const CheckPolicy(isTrusted: true);
  static const checked = const CheckPolicy(isEmitted: true);
  static const ignored = const CheckPolicy(isIgnored: true);

  String toString() => 'CheckPolicy(isTrusted=$isTrusted,'
      'isEmitted=$isEmitted,isIgnored=$isIgnored)';
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

bool _resolveCompileForServerFromOptions(List<String> options) {
  var categories = _extractCsvOption(options, '--categories=');
  return categories.length == 1 && categories.single == 'Server';
}

Uri _resolvePlatformConfigFromOptions(Uri libraryRoot, List<String> options) {
  return _resolvePlatformConfig(
      libraryRoot,
      _extractStringOption(options, "--platform-config=", null),
      _extractCsvOption(options, '--categories='));
}

Uri _resolveLibrariesSpecification(Uri libraryRoot) =>
    libraryRoot.resolve('lib/libraries.json');

/// Locations of the platform descriptor files relative to the library root.
const String _clientPlatform = "lib/dart_client.platform";
const String _serverPlatform = "lib/dart_server.platform";
const String _sharedPlatform = "lib/dart_shared.platform";

const String _UNDETERMINED_BUILD_ID = "build number could not be determined";
