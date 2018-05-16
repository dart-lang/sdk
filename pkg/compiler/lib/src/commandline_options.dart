// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cmdline.options;

/// Commandline flags used in `dart2js.dart` and/or `apiimpl.dart`.
class Flags {
  static const String allowMockCompilation = '--allow-mock-compilation';
  static const String allowNativeExtensions = '--allow-native-extensions';
  static const String analyzeAll = '--analyze-all';
  static const String analyzeMain = '--analyze-main';
  static const String analyzeOnly = '--analyze-only';
  static const String analyzeSignaturesOnly = '--analyze-signatures-only';
  static const String disableInlining = '--disable-inlining';
  static const String disableProgramSplit = '--disable-program-split';
  static const String disableDiagnosticColors = '--disable-diagnostic-colors';
  static const String disableNativeLiveTypeAnalysis =
      '--disable-native-live-type-analysis';
  static const String disableTypeInference = '--disable-type-inference';
  static const String disableRtiOptimization = '--disable-rti-optimization';
  static const String dumpInfo = '--dump-info';
  static const String enableAssertMessage = '--assert-message';
  static const String enableCheckedMode = '--enable-checked-mode';
  static const String enableAsserts = '--enable-asserts';
  static const String enableDiagnosticColors = '--enable-diagnostic-colors';
  static const String enableExperimentalMirrors =
      '--enable-experimental-mirrors';
  static const String experimentalTrackAllocations =
      '--experimental-track-allocations';
  static const String experimentalAllocationsPath =
      '--experimental-allocations-path';
  static const String fastStartup = '--fast-startup';
  static const String fatalWarnings = '--fatal-warnings';
  static const String generateCodeWithCompileTimeErrors =
      '--generate-code-with-compile-time-errors';

  /// TODO(sigmund): delete these flags.
  static const String useKernel = '--use-kernel';
  static const String useOldFrontend = '--use-old-frontend';

  static const String strongMode = '--strong';
  static const String previewDart2 = '--preview-dart-2';
  static const String omitImplicitChecks = '--omit-implicit-checks';

  static const String platformBinaries = '--platform-binaries=.+';

  static const String minify = '--minify';
  static const String noFrequencyBasedMinification =
      '--no-frequency-based-minification';
  static const String noSourceMaps = '--no-source-maps';
  static const String preserveUris = '--preserve-uris';
  static const String showPackageWarnings = '--show-package-warnings';
  static const String suppressHints = '--suppress-hints';
  static const String suppressWarnings = '--suppress-warnings';
  static const String terse = '--terse';
  static const String testMode = '--test-mode';
  static const String trustPrimitives = '--trust-primitives';
  static const String trustTypeAnnotations = '--trust-type-annotations';
  static const String trustJSInteropTypeAnnotations =
      '--experimental-trust-js-interop-type-annotations';
  static const String useContentSecurityPolicy = '--csp';
  static const String useMultiSourceInfo = '--use-multi-source-info';
  static const String useNewSourceInfo = '--use-new-source-info';
  static const String verbose = '--verbose';
  static const String version = '--version';

  /// Flag for a combination of flags for 'production' mode.
  static const String benchmarkingProduction = '--benchmarking-production';

  static const String conditionalDirectives = '--conditional-directives';

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

  // Deprecated. This flag is no longer in use for dart2js, but we are keeping
  // it around for a while longer until all other tools deprecate the same flag.
  //
  // It was used to start `async` functions synchronously, but now dart2js
  // switched on this behavior by default.
  // TODO(sigmund): delete once this is on by default on all of our tools.
  static const String syncAsync = '--sync-async';

  // Starts `async` functions asynchronously.
  //
  // This is the old Dart 1.0 behavior. Only used during the migration.
  static const String noSyncAsync = '--no-sync-async';

  // Initializing-formal access is enabled by default and cannot be disabled.
  // For backward compatibility the option is still accepted, but it is ignored.
  static const String initializingFormalAccess = '--initializing-formal-access';

  // Experimental flags.
  static const String resolveOnly = '--resolve-only';
}

class Option {
  static const String showPackageWarnings =
      '${Flags.showPackageWarnings}|${Flags.showPackageWarnings}=.*';

  // Experimental options.
  static const String resolutionInput = '--resolution-input=.+';
  static const String bazelPaths = '--bazel-paths=.+';
}
