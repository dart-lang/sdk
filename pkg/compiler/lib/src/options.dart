// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.src.options;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import 'commandline_options.dart' show Flags;
import 'util/util.dart';

enum NullSafetyMode {
  unsound,
  sound,
}

enum FeatureStatus {
  shipped,
  shipping,
  canary,
}

/// A [FeatureOption] is both a set of flags and an option. By default, creating
/// a [FeatureOption] will create two flags, `--$flag` and `--no-$flag`. The
/// default behavior for a [FeatureOption] in the [FeatureOptions.canary] set is
/// to be disabled by default unless explicity enabled or `--canary` is passed.
/// When the [FeatureOption] is moved to [FeatureOptions.shipping], the behavior
/// flips, and by default it is enabled unless explicitly disabled or
/// `--no-shipping` is passed. The [FeatureOption.isNegativeFlag] bool flips
/// things around so while in canary the [FeatureOption] is enabled unless
/// explicitly disabled, and while in [FeatureOptions.shipping] it is disabled
/// unless explicitly enabled.
///
/// Finally, mature features can be moved to [FeatureOptions.shipped], at which
/// point we ignore the flag, but throw if the value of the flag is
/// unexpected(i.e. if a positive flag is disabled, or a negative flag is
/// enabled).
class FeatureOption {
  final String flag;
  final bool isNegativeFlag;
  bool? _state;
  bool get isEnabled => _state!;
  bool get isDisabled => !isEnabled;
  void set state(bool value) {
    assert(_state == null);
    _state = value;
  }

  void set override(bool value) {
    assert(_state != null);
    _state = value;
  }

  FeatureOption(this.flag, {this.isNegativeFlag = false});
}

/// A class to simplify management of features which will end up being enabled
/// by default. New features should be added as properties, and then to the
/// [canary] list. Features in [canary] default to disabled unless they are
/// explicitly enabled or unless `--canary` is passed on the commandline. When
/// a feature is ready to ship, it should be moved to the [shipping] list,
/// whereupon it will immediately default to enabled but can still be disabled.
/// Once a feature is shipped, it can be deleted from this class entirely.
class FeatureOptions {
  /// Whether to restrict the generated JavaScript to features that work on the
  /// oldest supported versions of JavaScript. This currently means IE11. If
  /// `true`, the generated code runs on the legacy JavaScript platform. If
  /// `false`, the code will fail on the legacy JavaScript platform.
  FeatureOption legacyJavaScript =
      FeatureOption('legacy-javascript', isNegativeFlag: true);

  /// Whether to use optimized holders.
  FeatureOption newHolders = FeatureOption('new-holders');

  /// Whether to generate code compliant with Content Security Policy.
  FeatureOption useContentSecurityPolicy = FeatureOption('csp');

  /// Whether to emit JavaScript encoded as UTF-8.
  FeatureOption writeUtf8 = FeatureOption('utf8');

  /// Experimental instrumentation to add tree shaking information to
  /// dump-info's output.
  FeatureOption newDumpInfo = FeatureOption('new-dump-info');

  /// Whether to implement some simple async functions using Futures directly
  /// to reduce generated code size.
  FeatureOption simpleAsyncToFuture = FeatureOption('simple-async-to-future');

  /// Whether or not the CFE should evaluate constants.
  FeatureOption cfeConstants = FeatureOption('cfe-constants');

  /// Whether or not to intern composite values during deserialization
  /// (e.g. DartType).
  FeatureOption internValues = FeatureOption('intern-composite-values');

  /// Whether to use deferred serialization strategy. This changes serialized
  /// data structure to allow map value deserialization to be deferred.
  FeatureOption deferredSerialization = FeatureOption('deferred-serialization');

  /// [FeatureOption]s which are shipped and cannot be toggled.
  late final List<FeatureOption> shipped = [newHolders, legacyJavaScript];

  /// [FeatureOption]s which default to enabled.
  late final List<FeatureOption> shipping = [
    useContentSecurityPolicy,
    deferredSerialization,
    internValues,
  ];

  /// [FeatureOption]s which default to disabled.
  late final List<FeatureOption> canary = [
    writeUtf8,
    newDumpInfo,
    simpleAsyncToFuture,
    cfeConstants,
  ];

  /// Forces canary feature on. This must run after [Option].parse.
  void forceCanary() {
    for (var feature in canary) {
      feature.override = feature.isNegativeFlag ? false : true;
    }
  }

  /// Returns a list of enabled features as a comma separated string.
  String flavorString() {
    bool _shouldPrint(FeatureOption feature) {
      return feature.isNegativeFlag ? feature.isDisabled : feature.isEnabled;
    }

    String _toString(FeatureOption feature) {
      return feature.isNegativeFlag ? 'no-${feature.flag}' : feature.flag;
    }

    Iterable<String> _listToString(List<FeatureOption> options) {
      return options.where(_shouldPrint).map(_toString);
    }

    return _listToString(shipping).followedBy(_listToString(canary)).join(', ');
  }

  /// Parses a [List<String>] and enables / disables features as necessary.
  void parse(List<String> options) {
    _verifyShippedFeatures(options, shipped);
    _extractFeatures(options, shipping, FeatureStatus.shipping);
    _extractFeatures(options, canary, FeatureStatus.canary);
  }
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
class CompilerOptions implements DiagnosticOptions {
  /// The entry point of the application that is being compiled.
  Uri? entryUri;

  /// The input dill to compile.
  Uri? inputDillUri;

  /// Returns the compilation target specified by these options.
  Uri? get compilationTarget => inputDillUri ?? entryUri;

  bool get fromDill {
    if (sources != null) return false;
    var targetPath = compilationTarget!.path;
    return targetPath.endsWith('.dill');
  }

  /// Location of the package configuration file.
  Uri? packageConfig;

  /// List of kernel files to load.
  ///
  /// When compiling modularly, this contains kernel files that are needed
  /// to compile a single module.
  ///
  /// When linking, this contains all kernel files that form part of the final
  /// program.
  ///
  /// At this time, this list points to full kernel files. In the future, we may
  /// use a list of outline files for modular compiles, and only use full kernel
  /// files for linking.
  List<Uri>? dillDependencies;

  /// A list of sources to compile, only used for modular analysis.
  List<Uri>? sources;

  Uri? writeModularAnalysisUri;

  /// Helper to determine if compiler is being run just for modular analysis.
  bool get modularMode => writeModularAnalysisUri != null && !cfeOnly;

  List<Uri>? modularAnalysisInputs;

  bool get hasModularAnalysisInputs => modularAnalysisInputs != null;

  /// Uses a memory mapped view of files for I/O.
  bool memoryMappedFiles = false;

  /// Location from which serialized inference data is read.
  ///
  /// If this is set, the [entryUri] is expected to be a .dill file and the
  /// frontend work is skipped.
  Uri? readDataUri;

  /// Location to which inference data is serialized.
  ///
  /// If this is set, the compilation stops after type inference.
  Uri? writeDataUri;

  /// Serialize data without the closed world.
  /// TODO(joshualitt) make this the default right after landing in Google3 and
  /// clean up.
  bool noClosedWorldInData = false;

  /// Location from which the serialized closed world is read.
  ///
  /// If this is set, the [entryUri] is expected to be a .dill file and the
  /// frontend work is skipped.
  Uri? readClosedWorldUri;

  /// Location to which inference data is serialized.
  ///
  /// If this is set, the compilation stops after computing the closed world.
  Uri? writeClosedWorldUri;

  /// Location from which codegen data is read.
  ///
  /// If this is set, the compilation starts at codegen enqueueing.
  Uri? readCodegenUri;

  /// Location to which codegen data is serialized.
  ///
  /// If this is set, the compilation stops after code generation.
  Uri? writeCodegenUri;

  /// Whether to run only the CFE and emit the generated kernel file in
  /// [outputUri].
  bool cfeOnly = false;

  /// Flag only meant for dart2js developers to iterate on global inference
  /// changes.
  ///
  /// When working on large apps this flag allows to load serialized data for
  /// the app (via --read-data), reuse its closed world, and rerun the global
  /// inference phase (even though the serialized data already contains a global
  /// inference result).
  bool debugGlobalInference = false;

  /// Resolved constant "environment" values passed to the compiler via the `-D`
  /// flags.
  Map<String, String> environment = const <String, String>{};

  /// Flags enabling language experiments.
  Map<fe.ExperimentalFlag, bool> explicitExperimentalFlags = {};

  /// `true` if variance is enabled.
  bool get enableVariance =>
      fe.isExperimentEnabled(fe.ExperimentalFlag.variance,
          explicitExperimentalFlags: explicitExperimentalFlags);

  /// A possibly null state object for kernel compilation.
  fe.InitializedCompilerState? kernelInitializedCompilerState;

  /// Whether we allow mocking compilation of libraries such as dart:io and
  /// dart:html for unit testing purposes.
  bool allowMockCompilation = false;

  /// Sets a combination of flags for benchmarking 'production' mode.
  bool benchmarkingProduction = false;

  /// Sets a combination of flags for benchmarking 'experiment' mode.
  bool benchmarkingExperiment = false;

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
  Uri? deferredMapUri;

  /// Location where to generate an internal format representing the deferred
  /// graph.
  Uri? deferredGraphUri;

  /// The maximum number of deferred fragments to generate. If the number of
  /// fragments exceeds this amount, then they may be merged.
  /// Note: Currently, we only merge fragments in a single dependency chain. We
  /// will not merge fragments with unrelated dependencies and thus we may
  /// generate more fragments than the 'mergeFragmentsThreshold' under some
  /// situations.
  int? mergeFragmentsThreshold = null; // default value, no max.
  int? _mergeFragmentsThreshold;

  /// Whether to disable inlining during the backend optimizations.
  // TODO(sigmund): negate, so all flags are positive
  bool disableInlining = false;

  /// Disable deferred loading, instead generate everything in one output unit.
  /// Note: the resulting program still correctly checks that loadLibrary &
  /// checkLibrary calls are correct.
  bool disableProgramSplit = false;

  // Whether or not to stop compilation after splitting the
  bool stopAfterProgramSplit = false;

  /// Reads a program split json file and applies the parsed constraints to
  /// deferred loading.
  Uri? readProgramSplit;

  /// Diagnostic option: If `true`, warnings cause the compilation to fail.
  @override
  bool fatalWarnings = false;

  /// Diagnostic option: Emit terse diagnostics without howToFix.
  @override
  bool terseDiagnostics = false;

  /// Diagnostic option: If `true`, warnings are not reported.
  @override
  bool suppressWarnings = false;

  /// Diagnostic option: If `true`, hints are not reported.
  @override
  bool suppressHints = false;

  /// Diagnostic option: List of packages for which warnings and hints are
  /// reported. If `null`, no package warnings or hints are reported. If
  /// empty, all warnings and hints are reported.
  List<String>? shownPackageWarnings;

  /// Whether to disable global type inference.
  bool disableTypeInference = false;

  /// Whether to use the trivial abstract value domain.
  bool useTrivialAbstractValueDomain = false;

  /// Whether to use the wrapped abstract value domain (experimental).
  bool experimentalWrapped = false;

  /// Whether to use the powersets abstract value domain (experimental).
  bool experimentalPowersets = false;

  /// Whether to disable optimization for need runtime type information.
  bool disableRtiOptimization = false;

  /// Whether to emit a summary of the information used by the compiler during
  /// optimization. This includes resolution details, dependencies between
  /// elements, results of type inference, and data about generated code.
  bool dumpInfo = false;

  /// Whether to use the new dump-info binary format. This will be the default
  /// after a transitional period.
  bool useDumpInfoBinaryFormat = false;

  /// If set, SSA intermediate form is dumped for methods with names matching
  /// this RegExp pattern.
  String? dumpSsaPattern = null;

  /// Whether to generate a `.resources.json` file detailing the use of resource
  /// identifiers.
  bool writeResources = false;

  /// Whether we allow passing an extra argument to `assert`, containing a
  /// reason for why an assertion fails. (experimental)
  ///
  /// This is only included so that tests can pass the --assert-message flag
  /// without causing dart2js to crash. The flag has no effect.
  bool enableAssertMessage = true;

  /// Whether to enable minification
  // TODO(sigmund): rename to minify
  bool enableMinification = false;

  /// Flag to turn off minification even if enabled elsewhere, e.g. via
  /// -O2. Both [enableMinification] and [_disableMinification] can be true, in
  /// which case [_disableMinification] wins.
  bool _disableMinification = false;

  /// Whether to omit names of late variables from error messages.
  bool omitLateNames = false;

  /// Flag to turn off `omitLateNames` even if enabled elsewhere, e.g. via
  /// `-O2`. Both [omitLateNames] and [_noOmitLateNames] can be true, in which
  /// case [_noOmitLateNames] wins.
  bool _noOmitLateNames = false;

  /// Whether to model which native classes are live based on annotations on the
  /// core libraries. If false, all native classes will be included by default.
  bool enableNativeLiveTypeAnalysis = true;

  /// Whether to generate code containing user's `assert` statements.
  bool enableUserAssertions = false;

  /// Whether to generate code asserting that non-nullable parameters in opt-in
  /// code are not null. In mixed mode code (some opting into non-nullable, some
  /// not), null-safety is unsound, allowing `null` values to be assigned to
  /// variables with non-nullable types. This assertion lets the opt-in code
  /// operate with a stronger guarantee.
  bool enableNullAssertions = false;

  /// Whether to generate code asserting that non-nullable return values of
  /// `@Native` methods or `JS()` invocations are checked for being non-null.
  /// Emits checks only in sound null-safety.
  bool nativeNullAssertions = false;
  bool _noNativeNullAssertions = false;

  /// Whether to generate a source-map file together with the output program.
  bool generateSourceMap = true;

  /// URI of the main output of the compiler.
  Uri? outputUri;

  /// Location of the libraries specification file.
  Uri? librariesSpecificationUri;

  /// Location of the kernel platform `.dill` files.
  Uri? platformBinaries;

  /// Whether to print legacy types as T* rather than T.
  bool printLegacyStars = false;

  /// URI where the compiler should generate the output source map file.
  Uri? sourceMapUri;

  /// The compiler is run from the build bot.
  bool testMode = false;

  /// Whether to use the development type inferrer.
  bool experimentalInferrer = false;

  /// Whether to trust primitive types during inference and optimizations.
  bool trustPrimitives = false;

  /// Whether to omit implicit strong mode checks.
  bool omitImplicitChecks = false;

  /// Whether to omit as casts by default.
  bool omitAsCasts = false;

  /// Whether to omit class type arguments only needed for `toString` on
  /// `Object.runtimeType`.
  bool laxRuntimeTypeToString = false;

  /// What should the compiler do with parameter type assertions.
  ///
  /// This is an internal configuration option derived from other flags.
  late CheckPolicy defaultParameterCheckPolicy;

  /// What should the compiler do with implicit downcasts.
  ///
  /// This is an internal configuration option derived from other flags.
  late CheckPolicy defaultImplicitDowncastCheckPolicy;

  /// What the compiler should do with a boolean value in a condition context
  /// when the language specification says it is a runtime error for it to be
  /// null.
  ///
  /// This is an internal configuration option derived from other flags.
  late CheckPolicy defaultConditionCheckPolicy;

  /// What should the compiler do with explicit casts.
  ///
  /// This is an internal configuration option derived from other flags.
  late CheckPolicy defaultExplicitCastCheckPolicy;

  /// What should the compiler do with List index bounds checks.
  ///
  /// This is an internal configuration option derived from other flags.
  late CheckPolicy defaultIndexBoundsCheckPolicy;

  /// When obfuscating for minification, whether to use the frequency of a name
  /// as an heuristic to pick shorter names.
  bool useFrequencyNamer = true;

  /// Whether to generate source-information from both the old and the new
  /// source-information engines. (experimental)
  bool useMultiSourceInfo = false;

  /// Whether to use the new source-information implementation for source-maps.
  /// (experimental)
  bool useNewSourceInfo = false;

  /// Whether or not use simple load ids.
  bool useSimpleLoadIds = false;

  /// Enable verbose printing during compilation. Includes a time-breakdown
  /// between phases at the end.
  bool verbose = false;

  /// On top of --verbose, enable more verbose printing, like progress messages
  /// during each phase of compilation.
  bool showInternalProgress = false;

  /// Enable printing of metrics at end of compilation.
  // TODO(sra): Add command-line filtering of metrics.
  bool reportPrimaryMetrics = false;

  /// Enable printing of more metrics at end of compilation.
  // TODO(sra): Add command-line filtering of metrics.
  bool reportSecondaryMetrics = false;

  /// Track allocations in the JS output.
  ///
  /// This is an experimental feature.
  bool experimentalTrackAllocations = false;

  /// Experimental part file function generation.
  bool experimentStartupFunctions = false;

  /// Experimental reliance on JavaScript ToBoolean conversions.
  bool experimentToBoolean = false;

  // Experiment to make methods that are inferred as unreachable throw an
  // exception rather than generate suspect code.
  bool experimentUnreachableMethodsThrow = false;

  /// Experimental instrumentation to investigate code bloat.
  ///
  /// If [true], the compiler will emit code that logs whenever a method is
  /// called.
  bool experimentCallInstrumentation = false;

  /// Whether the compiler should emit code with unsound or sound semantics.
  /// Since Dart 3.0 this is no longer inferred from sources, but defaults to
  /// sound semantics.
  ///
  /// This option should rarely need to be accessed directly. Consider using
  /// [useLegacySubtyping] instead.
  NullSafetyMode nullSafetyMode = NullSafetyMode.sound;
  bool _soundNullSafety = false;
  bool _noSoundNullSafety = false;

  /// Whether to use legacy subtype semantics rather than null-safe semantics.
  /// This is `true` if unsound null-safety semantics are being used, since
  /// dart2js does not emit warnings for unsound null-safety.
  bool get useLegacySubtyping {
    return nullSafetyMode == NullSafetyMode.unsound;
  }

  /// If specified, a bundle of optimizations to enable (or disable).
  int? optimizationLevel = null;

  /// The shard to serialize when using [writeCodegenUri].
  int? codegenShard;

  /// The number of shards to serialize when using [writeCodegenUri] or to
  /// deserialize when using [readCodegenUri].
  int? codegenShards;

  /// Arguments passed to the front end about how it is invoked.
  ///
  /// This is used to selectively emit certain messages depending on how the
  /// CFE is invoked. For instance to emit a message about the null safety
  /// compilation mode when compiling an executable.
  ///
  /// See `InvocationMode` in
  /// `pkg/front_end/lib/src/api_prototype/compiler_options.dart` for all
  /// possible options.
  Set<fe.InvocationMode> cfeInvocationModes = {};

  /// Verbosity level used for filtering messages during compilation.
  fe.Verbosity verbosity = fe.Verbosity.all;

  // Whether or not to dump a list of unused libraries.
  bool dumpUnusedLibraries = false;

  late FeatureOptions features;

  // -------------------------------------------------
  // Options for deprecated features
  // -------------------------------------------------

  /// Create an options object by parsing flags from [options].
  static CompilerOptions parse(List<String> options,
      {FeatureOptions? featureOptions,
      Uri? librariesSpecificationUri,
      Uri? platformBinaries,
      void Function(String)? onError,
      void Function(String)? onWarning}) {
    if (featureOptions == null) featureOptions = FeatureOptions();
    featureOptions.parse(options);
    Map<fe.ExperimentalFlag, bool> explicitExperimentalFlags =
        _extractExperiments(options, onError: onError, onWarning: onWarning);

    // The null safety experiment can result in requiring different experiments
    // for compiling user code vs. the sdk. To simplify things, we prebuild the
    // sdk with the correct flags.
    platformBinaries ??= fe.computePlatformBinariesLocation();
    return CompilerOptions()
      ..entryUri = _extractUriOption(options, '${Flags.entryUri}=')
      ..inputDillUri = _extractUriOption(options, '${Flags.inputDill}=')
      ..librariesSpecificationUri = librariesSpecificationUri
      ..allowMockCompilation = _hasOption(options, Flags.allowMockCompilation)
      ..benchmarkingProduction =
          _hasOption(options, Flags.benchmarkingProduction)
      ..benchmarkingExperiment =
          _hasOption(options, Flags.benchmarkingExperiment)
      ..buildId =
          _extractStringOption(options, '--build-id=', _UNDETERMINED_BUILD_ID)!
      ..compileForServer = _hasOption(options, Flags.serverMode)
      ..deferredMapUri = _extractUriOption(options, '--deferred-map=')
      ..deferredGraphUri =
          _extractUriOption(options, '${Flags.dumpDeferredGraph}=')
      ..fatalWarnings = _hasOption(options, Flags.fatalWarnings)
      ..terseDiagnostics = _hasOption(options, Flags.terse)
      ..suppressWarnings = _hasOption(options, Flags.suppressWarnings)
      ..suppressHints = _hasOption(options, Flags.suppressHints)
      ..shownPackageWarnings =
          _extractOptionalCsvOption(options, Flags.showPackageWarnings)
      ..explicitExperimentalFlags = explicitExperimentalFlags
      ..disableInlining = _hasOption(options, Flags.disableInlining)
      ..disableProgramSplit = _hasOption(options, Flags.disableProgramSplit)
      ..stopAfterProgramSplit = _hasOption(options, Flags.stopAfterProgramSplit)
      ..disableTypeInference = _hasOption(options, Flags.disableTypeInference)
      ..useTrivialAbstractValueDomain =
          _hasOption(options, Flags.useTrivialAbstractValueDomain)
      ..experimentalWrapped = _hasOption(options, Flags.experimentalWrapped)
      ..experimentalPowersets = _hasOption(options, Flags.experimentalPowersets)
      ..disableRtiOptimization =
          _hasOption(options, Flags.disableRtiOptimization)
      ..dumpInfo = _hasOption(options, Flags.dumpInfo)
      ..useDumpInfoBinaryFormat =
          _hasOption(options, "${Flags.dumpInfo}=binary")
      ..dumpSsaPattern =
          _extractStringOption(options, '${Flags.dumpSsa}=', null)
      ..writeResources = _hasOption(options, Flags.writeResources)
      ..enableMinification = _hasOption(options, Flags.minify)
      .._disableMinification = _hasOption(options, Flags.noMinify)
      ..omitLateNames = _hasOption(options, Flags.omitLateNames)
      .._noOmitLateNames = _hasOption(options, Flags.noOmitLateNames)
      ..enableNativeLiveTypeAnalysis =
          !_hasOption(options, Flags.disableNativeLiveTypeAnalysis)
      ..enableUserAssertions = _hasOption(options, Flags.enableCheckedMode) ||
          _hasOption(options, Flags.enableAsserts)
      ..enableNullAssertions = _hasOption(options, Flags.enableCheckedMode) ||
          _hasOption(options, Flags.enableNullAssertions)
      ..nativeNullAssertions = _hasOption(options, Flags.nativeNullAssertions)
      .._noNativeNullAssertions =
          _hasOption(options, Flags.noNativeNullAssertions)
      ..experimentalTrackAllocations =
          _hasOption(options, Flags.experimentalTrackAllocations)
      ..experimentStartupFunctions =
          _hasOption(options, Flags.experimentStartupFunctions)
      ..experimentToBoolean = _hasOption(options, Flags.experimentToBoolean)
      ..experimentUnreachableMethodsThrow =
          _hasOption(options, Flags.experimentUnreachableMethodsThrow)
      ..experimentCallInstrumentation =
          _hasOption(options, Flags.experimentCallInstrumentation)
      ..generateSourceMap = !_hasOption(options, Flags.noSourceMaps)
      ..outputUri = _extractUriOption(options, '--out=')
      ..platformBinaries = platformBinaries
      ..printLegacyStars = _hasOption(options, Flags.printLegacyStars)
      ..sourceMapUri = _extractUriOption(options, '--source-map=')
      ..omitImplicitChecks = _hasOption(options, Flags.omitImplicitChecks)
      ..omitAsCasts = _hasOption(options, Flags.omitAsCasts)
      ..laxRuntimeTypeToString =
          _hasOption(options, Flags.laxRuntimeTypeToString)
      ..testMode = _hasOption(options, Flags.testMode)
      ..experimentalInferrer = _hasOption(options, Flags.experimentalInferrer)
      ..trustPrimitives = _hasOption(options, Flags.trustPrimitives)
      ..useFrequencyNamer =
          !_hasOption(options, Flags.noFrequencyBasedMinification)
      ..useMultiSourceInfo = _hasOption(options, Flags.useMultiSourceInfo)
      ..useNewSourceInfo = _hasOption(options, Flags.useNewSourceInfo)
      ..useSimpleLoadIds = _hasOption(options, Flags.useSimpleLoadIds)
      ..verbose = _hasOption(options, Flags.verbose)
      ..reportPrimaryMetrics = _hasOption(options, Flags.reportMetrics)
      ..reportSecondaryMetrics = _hasOption(options, Flags.reportAllMetrics)
      ..showInternalProgress = _hasOption(options, Flags.progress)
      ..dillDependencies =
          _extractUriListOption(options, '${Flags.dillDependencies}')
      ..sources = _extractUriListOption(options, '${Flags.sources}')
      ..readProgramSplit =
          _extractUriOption(options, '${Flags.readProgramSplit}=')
      ..writeModularAnalysisUri =
          _extractUriOption(options, '${Flags.writeModularAnalysis}=')
      ..modularAnalysisInputs =
          _extractUriListOption(options, '${Flags.readModularAnalysis}')
      ..readDataUri = _extractUriOption(options, '${Flags.readData}=')
      ..writeDataUri = _extractUriOption(options, '${Flags.writeData}=')
      ..memoryMappedFiles = _hasOption(options, Flags.memoryMappedFiles)
      ..noClosedWorldInData = _hasOption(options, Flags.noClosedWorldInData)
      ..readClosedWorldUri =
          _extractUriOption(options, '${Flags.readClosedWorld}=')
      ..writeClosedWorldUri =
          _extractUriOption(options, '${Flags.writeClosedWorld}=')
      ..readCodegenUri = _extractUriOption(options, '${Flags.readCodegen}=')
      ..writeCodegenUri = _extractUriOption(options, '${Flags.writeCodegen}=')
      ..codegenShard = _extractIntOption(options, '${Flags.codegenShard}=')
      ..codegenShards = _extractIntOption(options, '${Flags.codegenShards}=')
      ..cfeOnly = _hasOption(options, Flags.cfeOnly)
      ..debugGlobalInference = _hasOption(options, Flags.debugGlobalInference)
      .._soundNullSafety = _hasOption(options, Flags.soundNullSafety)
      .._noSoundNullSafety = _hasOption(options, Flags.noSoundNullSafety)
      .._mergeFragmentsThreshold =
          _extractIntOption(options, '${Flags.mergeFragmentsThreshold}=')
      ..dumpUnusedLibraries = _hasOption(options, Flags.dumpUnusedLibraries)
      ..cfeInvocationModes = fe.InvocationMode.parseArguments(
          _extractStringOption(options, '${Flags.cfeInvocationModes}=', '')!,
          onError: onError)
      ..verbosity = fe.Verbosity.parseArgument(
          _extractStringOption(
              options, '${Flags.verbosity}=', fe.Verbosity.defaultValue)!,
          onError: onError)
      ..features = featureOptions;
  }

  void validate() {
    // TODO(sigmund): should entrypoint be here? should we validate it is not
    // null? In unittests we use the same compiler to analyze or build multiple
    // entrypoints.
    if (librariesSpecificationUri == null) {
      throw ArgumentError("[librariesSpecificationUri] is null.");
    }
    if (librariesSpecificationUri!.path.endsWith('/')) {
      throw ArgumentError(
          "[librariesSpecificationUri] should be a file: $librariesSpecificationUri");
    }
    Map<fe.ExperimentalFlag, bool> experimentalFlags =
        Map.from(fe.defaultExperimentalFlags);
    experimentalFlags.addAll(explicitExperimentalFlags);
    if (platformBinaries == null &&
        equalMaps(experimentalFlags, fe.defaultExperimentalFlags)) {
      throw ArgumentError("Missing required ${Flags.platformBinaries}");
    }
    if (_soundNullSafety && _noSoundNullSafety) {
      throw ArgumentError("'${Flags.soundNullSafety}' incompatible with "
          "'${Flags.noSoundNullSafety}'");
    }
    if (nativeNullAssertions && _noNativeNullAssertions) {
      throw ArgumentError("'${Flags.nativeNullAssertions}' incompatible with "
          "'${Flags.noNativeNullAssertions}'");
    }
  }

  void deriveOptions() {
    if (benchmarkingProduction) {
      trustPrimitives = true;
      omitImplicitChecks = true;
    }

    if (benchmarkingExperiment) {
      // Set flags implied by '--benchmarking-x'.
      // TODO(sra): Use this for some null safety variant.
      features.forceCanary();
    }

    if (_soundNullSafety) nullSafetyMode = NullSafetyMode.sound;
    if (_noSoundNullSafety) nullSafetyMode = NullSafetyMode.unsound;

    if (optimizationLevel != null) {
      if (optimizationLevel == 0) {
        disableInlining = true;
        disableTypeInference = true;
        disableRtiOptimization = true;
      }
      if (optimizationLevel! >= 2) {
        enableMinification = true;
        laxRuntimeTypeToString = true;
        omitLateNames = true;
      }
      if (optimizationLevel! >= 3) {
        omitImplicitChecks = true;
      }
      if (optimizationLevel == 4) {
        trustPrimitives = true;
      }
    }

    // Strong mode always trusts type annotations (inferred or explicit), so
    // assignments checks should be trusted.
    if (omitImplicitChecks) {
      defaultParameterCheckPolicy = CheckPolicy.trusted;
      defaultImplicitDowncastCheckPolicy = CheckPolicy.trusted;
      defaultConditionCheckPolicy = CheckPolicy.trusted;
    } else {
      defaultParameterCheckPolicy = CheckPolicy.checked;
      defaultImplicitDowncastCheckPolicy = CheckPolicy.checked;
      defaultConditionCheckPolicy = CheckPolicy.checked;
    }
    if (omitAsCasts) {
      defaultExplicitCastCheckPolicy = CheckPolicy.trusted;
    } else {
      defaultExplicitCastCheckPolicy = CheckPolicy.checked;
    }
    if (trustPrimitives) {
      defaultIndexBoundsCheckPolicy = CheckPolicy.trusted;
    } else {
      defaultIndexBoundsCheckPolicy = CheckPolicy.checked;
    }

    if (_disableMinification) {
      enableMinification = false;
    }

    if (_noOmitLateNames) {
      omitLateNames = false;
    }

    if (_noNativeNullAssertions || nullSafetyMode != NullSafetyMode.sound) {
      nativeNullAssertions = false;
    }

    if (_mergeFragmentsThreshold != null) {
      mergeFragmentsThreshold = _mergeFragmentsThreshold;
    }

    environment['dart.web.assertions_enabled'] = '$enableUserAssertions';
  }

  /// Returns `true` if warnings and hints are shown for all packages.
  @override
  bool get showAllPackageWarnings {
    return shownPackageWarnings != null && shownPackageWarnings!.isEmpty;
  }

  /// Returns `true` if warnings and hints are hidden for all packages.
  @override
  bool get hidePackageWarnings => shownPackageWarnings == null;

  /// Returns `true` if warnings should be should for [uri].
  @override
  bool showPackageWarningsFor(Uri uri) {
    if (showAllPackageWarnings) {
      return true;
    }
    if (shownPackageWarnings != null) {
      return uri.isScheme('package') &&
          shownPackageWarnings!.contains(uri.pathSegments.first);
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

  const CheckPolicy({this.isTrusted = false, this.isEmitted = false});

  static const trusted = CheckPolicy(isTrusted: true);
  static const checked = CheckPolicy(isEmitted: true);

  @override
  String toString() => 'CheckPolicy(isTrusted=$isTrusted,'
      'isEmitted=$isEmitted)';
}

String? _extractStringOption(
    List<String> options, String prefix, String? defaultValue) {
  for (String option in options) {
    if (option.startsWith(prefix)) {
      return option.substring(prefix.length);
    }
  }
  return defaultValue;
}

Uri? _extractUriOption(List<String> options, String prefix) {
  String? option = _extractStringOption(options, prefix, null);
  return (option == null) ? null : Uri.parse(option);
}

int? _extractIntOption(List<String> options, String prefix) {
  String? option = _extractStringOption(options, prefix, null);
  return (option == null) ? null : int.parse(option);
}

bool _hasOption(List<String> options, String option) {
  return options.indexOf(option) >= 0;
}

/// Extract list of comma separated values provided for [flag]. Returns an
/// empty list if [option] contain [flag] without arguments. Returns `null` if
/// [option] doesn't contain [flag] with or without arguments.
List<String>? _extractOptionalCsvOption(List<String> options, String flag) {
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

/// Extract list of comma separated Uris provided for [flag]. Returns an
/// empty list if [option] contain [flag] without arguments. Returns `null` if
/// [option] doesn't contain [flag] with or without arguments.
List<Uri>? _extractUriListOption(List<String> options, String flag) {
  List<String>? stringUris = _extractOptionalCsvOption(options, flag);
  if (stringUris == null) return null;
  return stringUris.map(Uri.parse).toList();
}

Map<fe.ExperimentalFlag, bool> _extractExperiments(List<String> options,
    {void Function(String)? onError, void Function(String)? onWarning}) {
  List<String>? experiments =
      _extractOptionalCsvOption(options, Flags.enableLanguageExperiments);
  onError ??= (String error) => throw ArgumentError(error);
  onWarning ??= (String warning) => print(warning);
  return fe.parseExperimentalFlags(fe.parseExperimentalArguments(experiments),
      onError: onError, onWarning: onWarning);
}

void _extractFeatures(
    List<String> options, List<FeatureOption> features, FeatureStatus status) {
  bool hasCanaryFlag = _hasOption(options, Flags.canary);
  bool hasNoShippingFlag = _hasOption(options, Flags.noShipping);
  for (var feature in features) {
    String featureFlag = feature.flag;
    String enableFeatureFlag = '--${featureFlag}';
    String disableFeatureFlag = '--no-$featureFlag';
    bool enableFeature = _hasOption(options, enableFeatureFlag);
    bool disableFeature = _hasOption(options, disableFeatureFlag);
    if (enableFeature && disableFeature) {
      throw ArgumentError("'$enableFeatureFlag' incompatible with "
          "'$disableFeatureFlag'");
    }
    bool globalEnable = hasCanaryFlag ||
        (status == FeatureStatus.shipping && !hasNoShippingFlag);
    globalEnable = feature.isNegativeFlag ? !globalEnable : globalEnable;
    feature.state = (enableFeature || globalEnable) && !disableFeature;
  }
}

void _verifyShippedFeatures(
    List<String> options, List<FeatureOption> features) {
  for (var feature in features) {
    String featureFlag = feature.flag;
    String enableFeatureFlag = '--$featureFlag';
    String disableFeatureFlag = '--no-$featureFlag';
    bool enableFeature = _hasOption(options, enableFeatureFlag);
    bool disableFeature = _hasOption(options, disableFeatureFlag);
    if (enableFeature && disableFeature) {
      throw ArgumentError("'$enableFeatureFlag' incompatible with "
          "'$disableFeatureFlag'");
    }
    if (enableFeature && feature.isNegativeFlag) {
      throw ArgumentError(
          "$enableFeatureFlag has been removed and cannot be enabled.");
    }
    if (disableFeature && !feature.isNegativeFlag) {
      throw ArgumentError(
          "$enableFeatureFlag has already shipped and cannot be disabled.");
    }
    feature.state = !feature.isNegativeFlag;
  }
}

const String _UNDETERMINED_BUILD_ID = "build number could not be determined";
