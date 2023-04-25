// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline.options;

/// Commandline flags used in `dart2js.dart` and/or `apiimpl.dart`.
class Flags {
  // The uri of the main script file.
  static const String entryUri = '--entry-uri';

  // The uri of the main input dill.
  static const String inputDill = '--input-dill';

  static const String allowMockCompilation = '--allow-mock-compilation';
  static const String allowNativeExtensions = '--allow-native-extensions';
  static const String disableInlining = '--disable-inlining';
  static const String disableProgramSplit = '--disable-program-split';
  static const String disableDiagnosticColors = '--disable-diagnostic-colors';
  static const String disableNativeLiveTypeAnalysis =
      '--disable-native-live-type-analysis';
  static const String useTrivialAbstractValueDomain =
      '--use-trivial-abstract-value-domain';
  static const String disableTypeInference = '--disable-type-inference';
  static const String disableRtiOptimization = '--disable-rti-optimization';
  static const String dumpInfo = '--dump-info';
  static const String dumpDeferredGraph = '--dump-deferred-graph';
  static const String dumpSsa = '--dump-ssa';
  static const String enableAssertMessage = '--assert-message';
  static const String enableCheckedMode = '--enable-checked-mode';
  static const String enableAsserts = '--enable-asserts';
  static const String enableNullAssertions = '--null-assertions';
  static const String enableDiagnosticColors = '--enable-diagnostic-colors';
  static const String experimentalTrackAllocations =
      '--experimental-track-allocations';

  static const String experimentalWrapped = '--experimental-wrapped';
  static const String experimentalPowersets = '--experimental-powersets';

  // Temporary experiment for code generation of locals for frequently used
  // 'this' and constants.
  static const String experimentLocalNames = '--experiment-code-1';

  // Experimentally try to force part-file functions to be seen as IIFEs.
  static const String experimentStartupFunctions = '--experiment-code-2';

  // Experimentally rely on JavaScript ToBoolean conversions.
  static const String experimentToBoolean = '--experiment-code-3';

  // Experiment to make methods that are inferred as unreachable throw an
  // exception rather than generate suspect code.
  static const String experimentUnreachableMethodsThrow =
      '--experiment-unreachable-throw';

  // Add instrumentation to log every method call.
  static const String experimentCallInstrumentation =
      '--experiment-call-instrumentation';

  static const String experimentNewRti = '--experiment-new-rti';

  static const String enableLanguageExperiments = '--enable-experiment';

  static const String fastStartup = '--fast-startup';
  static const String fatalWarnings = '--fatal-warnings';
  static const String generateCodeWithCompileTimeErrors =
      '--generate-code-with-compile-time-errors';

  static const String previewDart2 = '--preview-dart-2';

  static const String omitImplicitChecks = '--omit-implicit-checks';
  static const String omitAsCasts = '--omit-as-casts';
  static const String laxRuntimeTypeToString = '--lax-runtime-type-to-string';

  static const String platformBinaries = '--platform-binaries=.+';

  static const String minify = '--minify';
  static const String noFrequencyBasedMinification =
      '--no-frequency-based-minification';
  // Disables minification even if enabled by other options, e.g. '-O2'.
  static const String noMinify = '--no-minify';

  static const String nativeNullAssertions = '--native-null-assertions';
  static const String noNativeNullAssertions = '--no-native-null-assertions';

  static const String noSourceMaps = '--no-source-maps';

  static const String omitLateNames = '--omit-late-names';
  static const String noOmitLateNames = '--no-omit-late-names';

  static const String preserveUris = '--preserve-uris';
  static const String printLegacyStars = '--debug-print-legacy-stars';
  static const String showPackageWarnings = '--show-package-warnings';
  static const String suppressHints = '--suppress-hints';
  static const String suppressWarnings = '--suppress-warnings';
  static const String terse = '--terse';
  static const String testMode = '--test-mode';
  static const String trustPrimitives = '--trust-primitives';
  static const String trustTypeAnnotations = '--trust-type-annotations';
  static const String trustJSInteropTypeAnnotations =
      '--experimental-trust-js-interop-type-annotations';
  static const String useMultiSourceInfo = '--use-multi-source-info';
  static const String useNewSourceInfo = '--use-new-source-info';
  static const String useOldRti = '--use-old-rti';
  static const String useSimpleLoadIds = '--simple-load-ids';
  static const String verbose = '--verbose';
  static const String verbosity = '--verbosity';
  static const String progress = '--show-internal-progress';
  static const String version = '--version';
  static const String reportMetrics = '--report-metrics';
  static const String reportAllMetrics = '--report-all-metrics';

  static const String dillDependencies = '--dill-dependencies';
  static const String sources = '--sources';
  static const String readData = '--read-data';
  static const String writeData = '--write-data';
  static const String memoryMappedFiles = '--memory-map-files';
  static const String noClosedWorldInData = '--no-closed-world-in-data';
  static const String writeClosedWorld = '--write-closed-world';
  static const String readClosedWorld = '--read-closed-world';
  static const String readCodegen = '--read-codegen';
  static const String writeCodegen = '--write-codegen';
  static const String readModularAnalysis = '--read-modular-analysis';
  static const String writeModularAnalysis = '--write-modular-analysis';
  static const String codegenShard = '--codegen-shard';
  static const String codegenShards = '--codegen-shards';
  static const String cfeOnly = '--cfe-only';
  static const String debugGlobalInference = '--debug-global-inference';

  static const String serverMode = '--server-mode';

  static const String soundNullSafety = '--sound-null-safety';
  static const String noSoundNullSafety = '--no-sound-null-safety';
  static const String mergeFragmentsThreshold = '--merge-fragments-threshold';

  static const String writeResources = '--write-resources';

  /// Flag for a combination of flags for 'production' mode.
  static const String benchmarkingProduction = '--benchmarking-production';

  /// Flag for a combination of flags for benchmarking 'experiment' mode.
  static const String benchmarkingExperiment = '--benchmarking-x';

  static const String conditionalDirectives = '--conditional-directives';

  static const String cfeInvocationModes = '--cfe-invocation-modes';

  /// Flag to indicate how the compiler is invoked. Used to ensure
  /// dart2js is only invoked from supported tools and through the Dart CLI.
  static const String invoker = '--invoker';

  /// Flag to stop after splitting the program.
  static const String stopAfterProgramSplit = '--stop-after-program-split';

  static const String writeProgramSplit = '--write-program-split';
  static const String readProgramSplit = '--read-program-split';

  // The syntax-only level of support for generic methods is included in the
  // 1.50 milestone for Dart. It is not experimental, but also not permanent:
  // a full implementation is expected in the future. Hence, the
  // 'GENERIC_METHODS' comments which were added when this feature was
  // experimental have been preserved, such that it will be easy to find the
  // relevant locations to update when generic methods are implemented fully.
  //
  // The option is still accepted, but it has no effect: The feature is enabled
  // by default and it cannot be disabled.
  //
  // The approach taken in the implementation is to parse generic methods,
  // introduce AST nodes for them, generate corresponding types (such that
  // front end treatment is consistent with the code that programmers wrote),
  // but considering all method type variables to have bound `dynamic` no
  // matter which bound they have syntactically (such that their value as types
  // is unchecked), and then replacing method type variables by a `DynamicType`
  // (such that the backend does not need to take method type arguments into
  // account).
  //
  // The feature has an informal specification which is available at
  // https://gist.github.com/eernstg/4353d7b4f669745bed3a5423e04a453c.
  static const String genericMethodSyntax = '--generic-method-syntax';

  // Initializing-formal access is enabled by default and cannot be disabled.
  // For backward compatibility the option is still accepted, but it is ignored.
  static const String initializingFormalAccess = '--initializing-formal-access';

  // Whether or not to dump a list of unused libraries.
  static const String dumpUnusedLibraries = '--dump-unused-libraries';

  // Experimental flags.
  static const String resolveOnly = '--resolve-only';

  static const String cfeConstants = '--cfe-constants';

  static const String disableDiagnosticByteCache =
      '--disable-diagnostic-byte-cache';

  // `--no-shipping` and `--canary` control sets of flags. For simplicity, these
  // flags live in options.dart.
  // Shipping features default to on, but can be disabled individually. All
  // shipping features can be disabled with the [noShipping] flag.
  static const String noShipping = '--no-shipping';

  // Canary features default to off, but can still be enabled individually. All
  // canary features can be enabled with the [canary] flag.
  static const String canary = '--canary';
}

class Option {
  static const String showPackageWarnings =
      '${Flags.showPackageWarnings}|${Flags.showPackageWarnings}=.*';

  static const String enableLanguageExperiments =
      '${Flags.enableLanguageExperiments}|'
      '${Flags.enableLanguageExperiments}=.*';

  static const String multiRoots = '--multi-root=.+';
  static const String multiRootScheme = '--multi-root-scheme=.+';

  // Experimental options.
  static const String resolutionInput = '--resolution-input=.+';
  static const String bazelPaths = '--bazel-paths=.+';
}
