// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// New Compiler API. This API is under construction, use only internally or
/// in unittests.

library compiler_new;

import 'dart:async';
import 'src/apiimpl.dart';
import 'src/commandline_options.dart';
import 'src/diagnostics/diagnostic_listener.dart' show DiagnosticOptions;

import 'compiler.dart' show Diagnostic, PackagesDiscoveryProvider;
export 'compiler.dart' show Diagnostic, PackagesDiscoveryProvider;

// Unless explicitly allowed, passing `null` for any argument to the
// methods of library will result in an Error being thrown.

/// Interface for providing the compiler with input. That is, Dart source files,
/// package config files, etc.
abstract class CompilerInput {
  /// Returns a future that completes to the source corresponding to [uri].
  /// If an exception occurs, the future completes with this exception.
  ///
  /// The source can be represented either as a [:List<int>:] of UTF-8 bytes or
  /// as a [String].
  ///
  /// The following text is non-normative:
  ///
  /// It is recommended to return a UTF-8 encoded list of bytes because the
  /// scanner is more efficient in this case. In either case, the data structure
  /// is expected to hold a zero element at the last position. If this is not
  /// the case, the entire data structure is copied before scanning.
  Future/*<String | List<int>>*/ readFromUri(Uri uri);
}

/// Interface for producing output from the compiler. That is, JavaScript target
/// files, source map files, dump info files, etc.
abstract class CompilerOutput {
  /// Returns an [EventSink] that will serve as compiler output for the given
  ///  component.
  ///
  ///  Components are identified by [name] and [extension]. By convention,
  /// the empty string [:"":] will represent the main script
  /// (corresponding to the script parameter of [compile]) even if the
  /// main script is a library. For libraries that are compiled
  /// separately, the library name is used.
  ///
  /// At least the following extensions can be expected:
  ///
  /// * "js" for JavaScript output.
  /// * "js.map" for source maps.
  /// * "dart" for Dart output.
  /// * "dart.map" for source maps.
  ///
  /// As more features are added to the compiler, new names and
  /// extensions may be introduced.
  EventSink<String> createEventSink(String name, String extension);
}

/// Interface for receiving diagnostic message from the compiler. That is,
/// errors, warnings, hints, etc.
abstract class CompilerDiagnostics {
  /// Invoked by the compiler to report diagnostics. If [uri] is `null`, so are
  /// [begin] and [end]. No other arguments may be `null`. If [uri] is not
  /// `null`, neither are [begin] and [end]. [uri] indicates the compilation
  /// unit from where the diagnostic originates. [begin] and [end] are
  /// zero-based character offsets from the beginning of the compilation unit.
  /// [message] is the diagnostic message, and [kind] indicates indicates what
  /// kind of diagnostic it is.
  ///
  /// Experimental: [code] gives access to an id for the messages. Currently it
  /// is the [Message] used to create the diagnostic, if available, from which
  /// the [MessageKind] is accessible.
  void report(
      var code, Uri uri, int begin, int end, String text, Diagnostic kind);
}

/// Information resulting from the compilation.
class CompilationResult {
  /// `true` if the compilation succeeded, that is, compilation didn't fail due
  /// to compile-time errors and/or internal errors.
  final bool isSuccess;

  /// The compiler object used for the compilation.
  ///
  /// Note: The type of [compiler] is implementation dependent and may vary.
  /// Use only for debugging and testing.
  final compiler;

  CompilationResult(this.compiler, {this.isSuccess: true});
}

/// Object for passing options to the compiler.
class CompilerOptions {
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

  /// Several options to configure diagnostic messages.
  // TODO(sigmund): should we simply embed those options here?
  final DiagnosticOptions diagnosticOptions;

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

  /// Whether to enable the experimental conditional directives feature.
  final bool enableConditionalDirectives;

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
        diagnosticOptions: new DiagnosticOptions(
            suppressWarnings: _hasOption(options, Flags.suppressWarnings),
            fatalWarnings: _hasOption(options, Flags.fatalWarnings),
            suppressHints: _hasOption(options, Flags.suppressHints),
            terseDiagnostics: _hasOption(options, Flags.terse),
            shownPackageWarnings:
                _extractOptionalCsvOption(options, Flags.showPackageWarnings)),
        disableInlining: _hasOption(options, Flags.disableInlining),
        disableTypeInference: _hasOption(options, Flags.disableTypeInference),
        dumpInfo: _hasOption(options, Flags.dumpInfo),
        emitJavaScript: !(_hasOption(options, '--output-type=dart') ||
            _hasOption(options, '--output-type=dart-multi')),
        enableAssertMessage: _hasOption(options, Flags.enableAssertMessage),
        enableConditionalDirectives:
            _hasOption(options, Flags.conditionalDirectives),
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
        platformConfigUri: _resolvePlatformConfigFromOptions(
            libraryRoot, options),
        preserveComments: _hasOption(options, Flags.preserveComments),
        preserveUris: _hasOption(options, Flags.preserveUris),
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
      DiagnosticOptions diagnosticOptions: const DiagnosticOptions(),
      bool disableInlining: false,
      bool disableTypeInference: false,
      bool dumpInfo: false,
      bool emitJavaScript: true,
      bool enableAssertMessage: false,
      bool enableConditionalDirectives: false,
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
        analyzeAll: analyzeAll,
        analyzeMain: analyzeMain,
        analyzeOnly: analyzeOnly || analyzeSignaturesOnly || analyzeAll,
        analyzeSignaturesOnly: analyzeSignaturesOnly,
        buildId: buildId,
        dart2dartMultiFile: dart2dartMultiFile,
        deferredMapUri: deferredMapUri,
        diagnosticOptions: diagnosticOptions,
        disableInlining: disableInlining || hasIncrementalSupport,
        disableTypeInference: disableTypeInference || !emitJavaScript,
        dumpInfo: dumpInfo,
        emitJavaScript: emitJavaScript,
        enableAssertMessage: enableAssertMessage,
        enableConditionalDirectives: enableConditionalDirectives,
        enableExperimentalMirrors: enableExperimentalMirrors,
        enableMinification: enableMinification,
        enableNativeLiveTypeAnalysis: enableNativeLiveTypeAnalysis,
        enableTypeAssertions: enableTypeAssertions,
        enableUserAssertions: enableUserAssertions,
        generateCodeWithCompileTimeErrors: generateCodeWithCompileTimeErrors,
        generateSourceMap: generateSourceMap,
        hasIncrementalSupport: hasIncrementalSupport,
        outputUri: outputUri,
        platformConfigUri: platformConfigUri ?? _resolvePlatformConfig(
           libraryRoot, null, !emitJavaScript, const []),
        preserveComments: preserveComments,
        preserveUris: preserveUris,
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
      this.diagnosticOptions: null,
      this.disableInlining: false,
      this.disableTypeInference: false,
      this.dumpInfo: false,
      this.emitJavaScript: true,
      this.enableAssertMessage: false,
      this.enableConditionalDirectives: false,
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
      this.verbose: false});
}

/// Returns a future that completes to a [CompilationResult] when the Dart
/// sources in [options] have been compiled.
///
/// The generated compiler output is obtained by providing a [compilerOutput].
///
/// If the compilation fails, the future's `CompilationResult.isSuccess` is
/// `false` and [CompilerDiagnostics.report] on [compilerDiagnostics]
/// is invoked at least once with `kind == Diagnostic.ERROR` or
/// `kind == Diagnostic.CRASH`.
Future<CompilationResult> compile(
    CompilerOptions compilerOptions,
    CompilerInput compilerInput,
    CompilerDiagnostics compilerDiagnostics,
    CompilerOutput compilerOutput) {
  if (compilerOptions == null) {
    throw new ArgumentError("compilerOptions must be non-null");
  }
  if (compilerInput == null) {
    throw new ArgumentError("compilerInput must be non-null");
  }
  if (compilerDiagnostics == null) {
    throw new ArgumentError("compilerDiagnostics must be non-null");
  }
  if (compilerOutput == null) {
    throw new ArgumentError("compilerOutput must be non-null");
  }

  CompilerImpl compiler = new CompilerImpl(
      compilerInput, compilerOutput, compilerDiagnostics, compilerOptions);
  return compiler.run(compilerOptions.entryPoint).then((bool success) {
    return new CompilationResult(compiler, isSuccess: success);
  });
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

Uri _resolvePlatformConfigFromOptions(Uri libraryRoot, List<String> options) {
  return _resolvePlatformConfig(libraryRoot,
      _extractStringOption(options, "--platform-config=", null),
      _hasOption(options, '--output-type=dart'),
      _extractCsvOption(options, '--categories='));
}

Uri _resolvePlatformConfig(Uri libraryRoot,
    String platformConfigPath, bool isDart2Dart, Iterable<String> categories) {
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

bool _hasOption(List<String> options, String option) {
  return options.indexOf(option) >= 0;
}

/// Locations of the platform descriptor files relative to the library root.
const String _clientPlatform = "lib/dart_client.platform";
const String _serverPlatform = "lib/dart_server.platform";
const String _sharedPlatform = "lib/dart_shared.platform";
const String _dart2dartPlatform = "lib/dart2dart.platform";

const String _UNDETERMINED_BUILD_ID = "build number could not be determined";
const bool _forceIncrementalSupport =
    const bool.fromEnvironment('DART2JS_EXPERIMENTAL_INCREMENTAL_SUPPORT');
