// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'package:collection/collection.dart';
// ignore: implementation_imports
import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import 'commandline_options.dart' show Flags;
import 'util/util.dart';

enum FeatureStatus { shipped, shipping, canary }

enum CompilerPhase {
  cfe,
  closedWorld,
  globalInference,
  codegen,
  emitJs,
  dumpInfo,
}

enum CompilerStage {
  all(
    'all',
    phases: {
      CompilerPhase.cfe,
      CompilerPhase.closedWorld,
      CompilerPhase.globalInference,
      CompilerPhase.codegen,
      CompilerPhase.emitJs,
    },
    canCompileFromEntryUri: true,
  ),
  dumpInfoAll(
    'dump-info-all',
    phases: {
      CompilerPhase.cfe,
      CompilerPhase.closedWorld,
      CompilerPhase.globalInference,
      CompilerPhase.codegen,
      CompilerPhase.emitJs,
      CompilerPhase.dumpInfo,
    },
    canCompileFromEntryUri: true,
  ),
  cfe('cfe', phases: {CompilerPhase.cfe}, canCompileFromEntryUri: true),
  deferredLoadIds(
    'deferred-load-ids',
    dataOutputName: 'deferred_load_ids.data',
    phases: {CompilerPhase.closedWorld},
  ),
  closedWorld(
    'closed-world',
    dataOutputName: 'world.data',
    phases: {CompilerPhase.closedWorld},
  ),
  globalInference(
    'global-inference',
    dataOutputName: 'global.data',
    phases: {CompilerPhase.globalInference},
  ),
  codegenAndJsEmitter(
    'codegen-emit-js',
    phases: {CompilerPhase.codegen, CompilerPhase.emitJs},
  ),
  codegenSharded(
    'codegen',
    dataOutputName: 'codegen',
    phases: {CompilerPhase.codegen},
  ),
  jsEmitter('emit-js', phases: {CompilerPhase.emitJs}),
  dumpInfo(
    'dump-info',
    dataOutputName: 'dump.data',
    phases: {CompilerPhase.dumpInfo},
  );

  const CompilerStage(
    this._stageFlag, {
    this.dataOutputName,
    required this.phases,
    this.canCompileFromEntryUri = false,
  });

  final Set<CompilerPhase> phases;
  final String _stageFlag;
  final String? dataOutputName;
  final bool canCompileFromEntryUri;

  bool get emitsJs => phases.contains(CompilerPhase.emitJs);
  bool get shouldOnlyComputeDill => this == CompilerStage.cfe;
  bool get canEmitDill =>
      this == CompilerStage.cfe || this == CompilerStage.closedWorld;
  bool get shouldReadPlatformBinaries => phases.contains(CompilerPhase.cfe);
  bool get emitsDumpInfo => phases.contains(CompilerPhase.dumpInfo);
  bool get emitsDeferredLoadIds => this == CompilerStage.deferredLoadIds;

  /// Global kernel transformations should be run in phase 0b, i.e. after
  /// concatenating dills, but before serializing the output of phase 0.
  // TODO(fishythefish): Add AST metadata to ensure transformations aren't rerun
  // unnecessarily.
  bool get shouldRunGlobalTransforms => phases.contains(CompilerPhase.cfe);

  bool get shouldReadClosedWorld => index > CompilerStage.closedWorld.index;
  bool get shouldReadGlobalInference =>
      index > CompilerStage.globalInference.index;
  bool get shouldReadCodegenShards =>
      index > CompilerStage.codegenSharded.index;
  bool get shouldReadDumpInfoData => this == CompilerStage.dumpInfo;
  bool get shouldWriteDumpInfoData =>
      this == CompilerStage.jsEmitter ||
      this == CompilerStage.codegenAndJsEmitter;
  bool get shouldWriteClosedWorld => this == CompilerStage.closedWorld;
  bool get shouldWriteGlobalInference => this == CompilerStage.globalInference;
  bool get shouldWriteCodegen => this == CompilerStage.codegenSharded;

  // Only use deferred reads for the linker and dump info phase as most deferred
  // entities will not be needed. In other phases we use most of this data so
  // it's not worth deferring.
  bool get shouldUseDeferredSourceReads =>
      this == CompilerStage.jsEmitter || this == CompilerStage.dumpInfo;

  String get toFlag => _stageFlag;

  static String get validFlagValuesString {
    return CompilerStage.values.map((p) => '`${p._stageFlag}`').join(', ');
  }

  static CompilerStage _fromFlagString(String stageFlag) {
    for (final stage in CompilerStage.values) {
      if (stageFlag == stage._stageFlag) {
        return stage;
      }
    }
    throw ArgumentError(
      'Invalid stage: $stageFlag. '
      'Supported values are: $validFlagValuesString',
    );
  }

  /// Can be used from outside the compiler to determine which stage will run
  /// based on provided flag.
  ///
  /// Used for internal build systems.
  static CompilerStage fromFlag(String? stageFlag) {
    return stageFlag == null ? CompilerStage.all : _fromFlagString(stageFlag);
  }

  static CompilerStage fromOptions(CompilerOptions options) {
    final stageFlag = options._stageFlag;
    if (stageFlag == null) {
      return options._dumpInfoFormatOption != null
          ? CompilerStage.dumpInfoAll
          : CompilerStage.all;
    }
    return _fromFlagString(stageFlag);
  }
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
  set state(bool value) {
    assert(_state == null);
    _state = value;
  }

  set override(bool value) {
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
  FeatureOption legacyJavaScript = FeatureOption(
    'legacy-javascript',
    isNegativeFlag: true,
  );

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

  /// [FeatureOption]s which are shipped and cannot be toggled.
  late final List<FeatureOption> shipped = [newHolders, legacyJavaScript];

  /// [FeatureOption]s which default to enabled.
  late final List<FeatureOption> shipping = [
    useContentSecurityPolicy,
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
    bool shouldPrint(FeatureOption feature) {
      return feature.isNegativeFlag ? feature.isDisabled : feature.isEnabled;
    }

    String toString(FeatureOption feature) {
      return feature.isNegativeFlag ? 'no-${feature.flag}' : feature.flag;
    }

    Iterable<String> listToString(List<FeatureOption> options) {
      return options.where(shouldPrint).map(toString);
    }

    return listToString(shipping).followedBy(listToString(canary)).join(', ');
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

enum DumpInfoFormat { binary, json }

/// Object for passing options to the compiler. Superclasses are used to select
/// subsets of these options, enabling each part of the compiler to depend on
/// as few as possible.
class CompilerOptions implements DiagnosticOptions {
  /// The entry point of the application that is being compiled.
  Uri? entryUri;

  /// The input dill to compile.
  Uri? _inputDillUri;

  Uri get _defaultInputDillUri =>
      _outputDir.resolve('${_outputPrefix}out.dill');

  Uri get inputDillUri {
    return _inputDillUri != null
        ? fe.nativeToUri(_inputDillUri.toString())
        : _defaultInputDillUri;
  }

  /// Returns the compilation target specified by these options.
  Uri get compilationTarget =>
      _inputDillUri ??
      (stage.canCompileFromEntryUri ? entryUri : null) ??
      _defaultInputDillUri;

  bool get shouldLoadFromDill =>
      entryUri == null || compilationTarget.path.endsWith('.dill');

  /// Location of the package configuration file.
  Uri? packageConfig;

  /// List of kernel files to load.
  ///
  /// This contains all kernel files that form part of the final program. The
  /// dills passed here should contain full kernel ASTs, not just outlines.
  List<Uri>? dillDependencies;

  /// Uses a memory mapped view of files for I/O.
  bool memoryMappedFiles = false;

  /// Location from which serialized inference data is read/written.
  Uri? _globalInferenceUri;

  /// Location from which the serialized closed world is read/written.
  Uri? _closedWorldUri;

  /// Location from which codegen data is read/written.
  Uri? _codegenUri;

  // TODO(natebiggs): Delete this once Flutter is using the stage flag.
  /// Whether to run only the CFE and emit the generated kernel file in
  /// [outputUri]. Equivalent to `--stage=cfe`.
  bool _cfeOnly = false;

  /// Which stage of the compiler to run. Maps to a stage from [CompilerStage].
  String? _stageFlag;

  /// Flag only meant for dart2js developers to iterate on global inference
  /// changes.
  ///
  /// When working on large apps this flag allows to load serialized data for
  /// the app (via --read-data), reuse its closed world, and rerun the global
  /// inference stage (even though the serialized data already contains a global
  /// inference result).
  bool debugGlobalInference = false;

  /// Resolved constant "environment" values passed to the compiler via the `-D`
  /// flags.
  Map<String, String> environment = const <String, String>{};

  /// Flags enabling language experiments.
  Map<fe.ExperimentalFlag, bool> explicitExperimentalFlags = {};

  /// `true` if variance is enabled.
  bool get enableVariance => fe.isExperimentEnabled(
    fe.ExperimentalFlag.variance,
    explicitExperimentalFlags: explicitExperimentalFlags,
  );

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
  String buildId = _undeterminedBuildID;

  /// Whether there is a build-id available so we can use it on error messages
  /// and in the emitted output of the compiler.
  bool get hasBuildId => buildId != _undeterminedBuildID;

  /// Whether to compile for the server category. This is used to compile to JS
  /// that is intended to be run on server-side VMs like nodejs.
  bool compileForServer = false;

  /// Location where to generate a map containing details of how deferred
  /// libraries are subdivided.
  Uri? deferredMapUri;

  /// Location to generate a map containing mapping from user-defined deferred
  /// import to Dart2js runtime load ID name.
  Uri? _deferredLoadIdMapUri;

  /// Location where to generate an internal format representing the deferred
  /// graph.
  Uri? deferredGraphUri;

  /// The maximum number of deferred fragments to generate. If the number of
  /// fragments exceeds this amount, then they may be merged.
  /// Note: Currently, we only merge fragments in a single dependency chain. We
  /// will not merge fragments with unrelated dependencies and thus we may
  /// generate more fragments than the 'mergeFragmentsThreshold' under some
  /// situations.
  int? mergeFragmentsThreshold; // default value, no max.
  int? _mergeFragmentsThreshold;

  /// Whether to disable inlining during the backend optimizations.
  // TODO(sigmund): negate, so all flags are positive
  bool disableInlining = false;

  /// Disable deferred loading, instead generate everything in one output unit.
  /// Note: the resulting program still correctly checks that loadLibrary &
  /// checkLibrary calls are correct.
  bool disableProgramSplit = false;

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

  /// Whether to disable optimization for need runtime type information.
  bool disableRtiOptimization = false;

  /// Uri to read/write dump info requisite data after emitting JS. This
  /// contains data captured from the JS printer and processed for the dump info
  /// task.
  /// The file emitted to the URI can then be read in using to run dump info as
  /// a standalone task (without re-emitting JS).
  Uri? _dumpInfoDataUri;

  /// Which format the user has chosen to emit dump info in if any.
  DumpInfoFormat? _dumpInfoFormatOption;
  DumpInfoFormat get dumpInfoFormat =>
      _dumpInfoFormatOption ?? DumpInfoFormat.json;

  /// If set, SSA intermediate form is dumped for methods with names matching
  /// this RegExp pattern.
  String? dumpSsaPattern;

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

  /// Whether to generate code asserting that non-nullable return values of
  /// `@Native` methods or `JS()` invocations are checked for being non-null.
  bool nativeNullAssertions = false;
  bool _noNativeNullAssertions = false;

  /// Whether to generate code asserting that return values of JS-interop APIs
  /// with non-nullable return types are not null.
  bool interopNullAssertions = false;
  bool _noInteropNullAssertions = false;

  /// Whether to generate a source-map file together with the output program.
  bool generateSourceMap = true;

  /// Location of the libraries specification file.
  Uri? librariesSpecificationUri;

  /// Location of the kernel platform `.dill` files.
  Uri? platformBinaries;

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

  /// Omit memory usage in the summary printed to the console at the end of
  /// each compilation.
  bool omitMemorySummary = false;

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

  /// If specified, a bundle of optimizations to enable (or disable).
  int? optimizationLevel;

  /// The shard to serialize when running the codegen phase.
  int? codegenShard;

  /// The number of shards to serialize when running the codegen phase or to
  /// deserialize when running the emit-js phase.
  int? codegenShards;

  /// Arguments passed to the front end about how it is invoked.
  ///
  /// This is used to selectively emit certain messages depending on how the
  /// CFE is invoked.
  ///
  /// See `InvocationMode` in
  /// `pkg/front_end/lib/src/api_prototype/compiler_options.dart` for all
  /// possible options.
  Set<fe.InvocationMode> cfeInvocationModes = {};

  /// Verbosity level used for filtering messages during compilation.
  fe.Verbosity verbosity = fe.Verbosity.all;

  // Whether or not to dump a list of unused libraries.
  bool dumpUnusedLibraries = false;

  // Whether or not to disable byte cache for sources loaded from Kernel dill.
  bool disableDiagnosticByteCache = false;

  // Whether or not to enable deferred loading event log.
  bool enableDeferredLoadingEventLog = false;

  bool enableProtoShaking = false;
  bool enableProtoMixinShaking = false;

  bool get producesModifiedDill =>
      stage == CompilerStage.closedWorld && enableProtoShaking;

  late final CompilerStage stage = _calculateStage();

  CompilerStage _calculateStage() =>
      _cfeOnly ? CompilerStage.cfe : CompilerStage.fromOptions(this);

  Uri? _outputUri;
  Uri? outputUri;

  String get _outputFilename => _outputUri?.pathSegments.last ?? '';

  String? get _outputExtension {
    switch (stage) {
      case CompilerStage.all:
      case CompilerStage.dumpInfoAll:
      case CompilerStage.jsEmitter:
      case CompilerStage.codegenAndJsEmitter:
      case CompilerStage.dumpInfo:
        return '.js';
      case CompilerStage.cfe:
        return '.dill';
      case CompilerStage.closedWorld:
        if (producesModifiedDill) return '.dill';
      case CompilerStage.deferredLoadIds:
      case CompilerStage.globalInference:
      case CompilerStage.codegenSharded:
    }
    return null;
  }

  /// Output prefix specified by the user via the `--out` flag. The prefix is
  /// calculated from the final segment of the user provided URI. If the
  /// extension does not match the expected extension for the current [stage]
  /// then the last segment is treated as a prefix. Only set when `--stage` is
  /// specified.
  late final String _outputPrefix = (() {
    if (_stageFlag == null) return '';
    final extension = _outputExtension;

    return (extension != null && _outputFilename.endsWith(extension))
        ? ''
        : _outputFilename;
  })();

  /// Output directory specified by the user via the `--out` flag. The directory
  /// is calculated by resolving the substring prior to the final URI segment
  /// (i.e. before the final slash) relative to [Uri.base]. Defaults to
  /// [Uri.base] if `--out` is not provided or does not include a directory.
  late final Uri _outputDir = (() => (_outputUri != null)
      ? Uri.base.resolveUri(_outputUri!).resolve('.')
      : Uri.base)();

  /// Computes a resolved output URI based on value provided via the `--out`
  /// flag. Updates [outputUri] based on the result and returns the value.
  Uri? setResolvedOutputUri() {
    final extension = _outputExtension;
    if (extension == null) return null;

    if (_stageFlag == null) {
      return outputUri = _outputDir.resolve(
        _outputFilename.isEmpty ? 'out$extension' : _outputFilename,
      );
    }

    String fullName = _outputFilename;
    if (!fullName.endsWith(extension)) {
      fullName += 'out$extension';
    }
    return outputUri = _outputDir.resolve(fullName);
  }

  /// Sets [outputUri] to the value provided via `--out` without any processing.
  void setDefaultOutputUriForTesting() {
    outputUri = _outputUri;
  }

  Uri? _getSpecifiedDataPath(CompilerStage stage) {
    switch (stage) {
      case CompilerStage.all:
      case CompilerStage.dumpInfoAll:
      case CompilerStage.cfe:
      case CompilerStage.jsEmitter:
      case CompilerStage.codegenAndJsEmitter:
        return null;
      case CompilerStage.deferredLoadIds:
        return _deferredLoadIdMapUri;
      case CompilerStage.closedWorld:
        return _closedWorldUri;
      case CompilerStage.globalInference:
        return _globalInferenceUri;
      case CompilerStage.codegenSharded:
        return _codegenUri;
      case CompilerStage.dumpInfo:
        return _dumpInfoDataUri;
    }
  }

  Uri dataUriForStage(CompilerStage stage) {
    final dataUri = _getSpecifiedDataPath(stage);
    if (dataUri != null) return dataUri;

    if (stage.dataOutputName != null) {
      final filename = '$_outputPrefix${stage.dataOutputName}';
      return _outputDir.resolve(filename);
    }
    throw ArgumentError('No data input generated for stage: $stage');
  }

  late FeatureOptions features;

  // -------------------------------------------------
  // Options for deprecated features
  // -------------------------------------------------

  /// Create an options object by parsing flags from [options].
  static CompilerOptions parse(
    List<String> options, {
    FeatureOptions? featureOptions,
    Uri? librariesSpecificationUri,
    Uri? platformBinaries,
    bool useDefaultOutputUri = false,
    void Function(String)? onError,
    void Function(String)? onWarning,
  }) {
    featureOptions ??= FeatureOptions();
    featureOptions.parse(options);
    Map<fe.ExperimentalFlag, bool> explicitExperimentalFlags =
        _extractExperiments(options, onError: onError, onWarning: onWarning);

    // We may require different experiments for compiling user code vs. the sdk.
    // To simplify things, we prebuild the sdk with the correct flags.
    platformBinaries ??= fe.computePlatformBinariesLocation();
    return CompilerOptions()
      ..entryUri = _extractUriOption(options, '${Flags.entryUri}=')
      .._inputDillUri = _extractUriOption(options, '${Flags.inputDill}=')
      ..librariesSpecificationUri = librariesSpecificationUri
      ..allowMockCompilation = _hasOption(options, Flags.allowMockCompilation)
      ..benchmarkingProduction = _hasOption(
        options,
        Flags.benchmarkingProduction,
      )
      ..benchmarkingExperiment = _hasOption(
        options,
        Flags.benchmarkingExperiment,
      )
      ..buildId = _extractStringOption(
        options,
        '--build-id=',
        _undeterminedBuildID,
      )!
      ..compileForServer = _hasOption(options, Flags.serverMode)
      ..deferredMapUri = _extractUriOption(options, '--deferred-map=')
      .._deferredLoadIdMapUri = _extractUriOption(
        options,
        '${Flags.deferredLoadIdMapUri}=',
      )
      ..deferredGraphUri = _extractUriOption(
        options,
        '${Flags.dumpDeferredGraph}=',
      )
      ..fatalWarnings = _hasOption(options, Flags.fatalWarnings)
      ..terseDiagnostics = _hasOption(options, Flags.terse)
      ..suppressWarnings = _hasOption(options, Flags.suppressWarnings)
      ..suppressHints = _hasOption(options, Flags.suppressHints)
      ..shownPackageWarnings = _extractOptionalCsvOption(
        options,
        Flags.showPackageWarnings,
      )
      ..explicitExperimentalFlags = explicitExperimentalFlags
      ..disableInlining = _hasOption(options, Flags.disableInlining)
      ..disableProgramSplit = _hasOption(options, Flags.disableProgramSplit)
      ..disableTypeInference = _hasOption(options, Flags.disableTypeInference)
      ..useTrivialAbstractValueDomain = _hasOption(
        options,
        Flags.useTrivialAbstractValueDomain,
      )
      ..disableRtiOptimization = _hasOption(
        options,
        Flags.disableRtiOptimization,
      )
      .._dumpInfoDataUri = _extractUriOption(
        options,
        '${Flags.dumpInfoDataUri}=',
      )
      .._dumpInfoFormatOption = _extractEnumOption(
        options,
        Flags.dumpInfo,
        DumpInfoFormat.values,
        emptyValue: DumpInfoFormat.binary,
      )
      ..dumpSsaPattern = _extractStringOption(
        options,
        '${Flags.dumpSsa}=',
        null,
      )
      ..writeResources = _hasOption(options, Flags.writeResources)
      ..enableMinification = _hasOption(options, Flags.minify)
      .._disableMinification = _hasOption(options, Flags.noMinify)
      ..omitLateNames = _hasOption(options, Flags.omitLateNames)
      .._noOmitLateNames = _hasOption(options, Flags.noOmitLateNames)
      ..enableNativeLiveTypeAnalysis = !_hasOption(
        options,
        Flags.disableNativeLiveTypeAnalysis,
      )
      ..enableUserAssertions =
          _hasOption(options, Flags.enableCheckedMode) ||
          _hasOption(options, Flags.enableAsserts)
      ..nativeNullAssertions = _hasOption(options, Flags.nativeNullAssertions)
      .._noNativeNullAssertions = _hasOption(
        options,
        Flags.noNativeNullAssertions,
      )
      ..interopNullAssertions = _hasOption(options, Flags.interopNullAssertions)
      .._noInteropNullAssertions = _hasOption(
        options,
        Flags.noInteropNullAssertions,
      )
      ..experimentalTrackAllocations = _hasOption(
        options,
        Flags.experimentalTrackAllocations,
      )
      ..experimentStartupFunctions = _hasOption(
        options,
        Flags.experimentStartupFunctions,
      )
      ..experimentToBoolean = _hasOption(options, Flags.experimentToBoolean)
      ..experimentUnreachableMethodsThrow = _hasOption(
        options,
        Flags.experimentUnreachableMethodsThrow,
      )
      ..experimentCallInstrumentation = _hasOption(
        options,
        Flags.experimentCallInstrumentation,
      )
      ..generateSourceMap = !_hasOption(options, Flags.noSourceMaps)
      .._outputUri = _extractUriOption(options, '--out=')
      ..platformBinaries = platformBinaries
      ..sourceMapUri = _extractUriOption(options, '--source-map=')
      ..omitImplicitChecks = _hasOption(options, Flags.omitImplicitChecks)
      ..omitAsCasts = _hasOption(options, Flags.omitAsCasts)
      ..laxRuntimeTypeToString = _hasOption(
        options,
        Flags.laxRuntimeTypeToString,
      )
      ..enableProtoShaking =
          _hasOption(options, Flags.enableProtoShaking) ||
          _hasOption(options, Flags.enableProtoMixinShaking)
      ..enableProtoMixinShaking = _hasOption(
        options,
        Flags.enableProtoMixinShaking,
      )
      ..testMode = _hasOption(options, Flags.testMode)
      ..trustPrimitives = _hasOption(options, Flags.trustPrimitives)
      ..useFrequencyNamer = !_hasOption(
        options,
        Flags.noFrequencyBasedMinification,
      )
      ..useMultiSourceInfo = _hasOption(options, Flags.useMultiSourceInfo)
      ..useNewSourceInfo = _hasOption(options, Flags.useNewSourceInfo)
      ..useSimpleLoadIds = _hasOption(options, Flags.useSimpleLoadIds)
      ..verbose = _hasOption(options, Flags.verbose)
      ..omitMemorySummary = _hasOption(options, Flags.omitMemorySummary)
      ..reportPrimaryMetrics = _hasOption(options, Flags.reportMetrics)
      ..reportSecondaryMetrics = _hasOption(options, Flags.reportAllMetrics)
      ..showInternalProgress = _hasOption(options, Flags.progress)
      ..dillDependencies = _extractUriListOption(
        options,
        Flags.dillDependencies,
      )
      ..readProgramSplit = _extractUriOption(
        options,
        '${Flags.readProgramSplit}=',
      )
      .._globalInferenceUri = _extractUriOption(
        options,
        '${Flags.globalInferenceUri}=',
      )
      ..memoryMappedFiles = _hasOption(options, Flags.memoryMappedFiles)
      .._closedWorldUri = _extractUriOption(options, '${Flags.closedWorldUri}=')
      .._codegenUri = _extractUriOption(options, '${Flags.codegenUri}=')
      ..codegenShard = _extractIntOption(options, '${Flags.codegenShard}=')
      ..codegenShards = _extractIntOption(options, '${Flags.codegenShards}=')
      .._cfeOnly = _hasOption(options, Flags.cfeOnly)
      .._stageFlag = _extractStringOption(options, '${Flags.stage}=', null)
      ..debugGlobalInference = _hasOption(options, Flags.debugGlobalInference)
      .._mergeFragmentsThreshold = _extractIntOption(
        options,
        '${Flags.mergeFragmentsThreshold}=',
      )
      ..dumpUnusedLibraries = _hasOption(options, Flags.dumpUnusedLibraries)
      ..cfeInvocationModes = fe.InvocationMode.parseArguments(
        _extractStringOption(options, '${Flags.cfeInvocationModes}=', '')!,
        onError: onError,
      )
      ..verbosity = fe.Verbosity.parseArgument(
        _extractStringOption(
          options,
          '${Flags.verbosity}=',
          fe.Verbosity.defaultValue,
        )!,
        onError: onError,
      )
      ..disableDiagnosticByteCache = _hasOption(
        options,
        Flags.disableDiagnosticByteCache,
      )
      ..enableDeferredLoadingEventLog = _hasOption(
        options,
        Flags.enableDeferredLoadingEventLog,
      )
      ..features = featureOptions;
  }

  String? validateStage() {
    bool expectCodegenIn = false;
    bool expectCodegenOut = false;
    switch (stage) {
      case CompilerStage.all:
      case CompilerStage.dumpInfoAll:
      case CompilerStage.cfe:
      case CompilerStage.deferredLoadIds:
      case CompilerStage.closedWorld:
      case CompilerStage.globalInference:
      case CompilerStage.codegenAndJsEmitter:
      case CompilerStage.dumpInfo:
        break;
      case CompilerStage.codegenSharded:
        expectCodegenOut = true;
        break;
      case CompilerStage.jsEmitter:
        expectCodegenIn = true;
        break;
    }

    if (codegenShard == null && expectCodegenOut) {
      return 'Must specify value for ${Flags.codegenShard} '
          'in stage ${stage.name}.';
    }

    if (codegenShards == null && expectCodegenOut) {
      return 'Must specify value for ${Flags.codegenShards} '
          'in stage ${stage.name}.';
    }
    if (codegenShards == null && expectCodegenIn) {
      return 'Must specify value for ${Flags.codegenShards} '
          'in stage ${stage.name}.';
    }
    return null;
  }

  void validate() {
    if (librariesSpecificationUri == null) {
      throw ArgumentError("[librariesSpecificationUri] is null.");
    }
    if (librariesSpecificationUri!.path.endsWith('/')) {
      throw ArgumentError(
        "[librariesSpecificationUri] should be a file: $librariesSpecificationUri",
      );
    }
    Map<fe.ExperimentalFlag, bool> experimentalFlags = Map.from(
      fe.defaultExperimentalFlags,
    );
    experimentalFlags.addAll(explicitExperimentalFlags);
    if (platformBinaries == null &&
        equalMaps(experimentalFlags, fe.defaultExperimentalFlags)) {
      throw ArgumentError("Missing required ${Flags.platformBinaries}");
    }
    if (nativeNullAssertions && _noNativeNullAssertions) {
      throw ArgumentError(
        "'${Flags.nativeNullAssertions}' is incompatible with "
        "'${Flags.noNativeNullAssertions}'",
      );
    }
    if (interopNullAssertions && _noInteropNullAssertions) {
      throw ArgumentError(
        "'${Flags.interopNullAssertions}' is incompatible with "
        "'${Flags.noInteropNullAssertions}'",
      );
    }
  }

  // This should only be used to derive options to be used during compilation,
  // not for options needed during set up of the compiler.
  void deriveOptions() {
    if (benchmarkingProduction) {
      trustPrimitives = true;
      omitImplicitChecks = true;
      // TODO(53993):
      //   laxRuntimeTypeToString = true;
      //   omitLateNames = true;
    }

    if (benchmarkingExperiment) {
      // Set flags implied by '--benchmarking-x'.
      features.forceCanary();
    }

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

    if (_noNativeNullAssertions) {
      // Never assert if the user tells us not to.
      nativeNullAssertions = false;
    } else if (!nativeNullAssertions &&
        (optimizationLevel != null && optimizationLevel! >= 3)) {
      // If the user didn't tell us to assert and we're in >= -O3, optimize away
      // the check. This should reduce issues in production.
      nativeNullAssertions = false;
    } else {
      nativeNullAssertions = true;
    }

    if (_noInteropNullAssertions) {
      interopNullAssertions = false;
    }

    if (_mergeFragmentsThreshold != null) {
      mergeFragmentsThreshold = _mergeFragmentsThreshold;
    }

    environment['dart.web.assertions_enabled'] = '$enableUserAssertions';
    environment['dart.tool.dart2js'] = '${true}';
    environment['dart.tool.dart2js.minify'] = '$enableMinification';
    environment['dart.tool.dart2js.disable_rti_optimization'] =
        '$disableRtiOptimization';
    // Eventually pragmas and commandline flags should be aligned so that users
    // setting these flag is equivalent to setting the relevant pragmas
    // globally.
    // See: https://github.com/dart-lang/sdk/issues/49475
    // https://github.com/dart-lang/sdk/blob/main/pkg/compiler/doc/pragmas.md
    environment['dart.tool.dart2js.primitives:trust'] = '$trustPrimitives';
    environment['dart.tool.dart2js.types:trust'] = '$omitImplicitChecks';
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
/// This enum is used to configure how the compiler treats type assertions
/// during global type inference and codegen.
enum CheckPolicy {
  trusted(isTrusted: true),
  checked(isEmitted: true);

  /// Whether the type assertion should be trusted.
  final bool isTrusted;

  /// Whether the type assertion should be emitted and checked.
  final bool isEmitted;

  const CheckPolicy({this.isTrusted = false, this.isEmitted = false});

  @override
  String toString() =>
      'CheckPolicy(isTrusted=$isTrusted,'
      'isEmitted=$isEmitted)';
}

String? _extractStringOption(
  List<String> options,
  String prefix,
  String? defaultValue,
) {
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

/// Extracts an enum value for the flag given by [prefix].
///
/// [emptyValue] is used to provide a default value when the flag is given but
/// with no '=' value provided.
T? _extractEnumOption<T extends Enum>(
  List<String> options,
  String prefix,
  List<T> values, {
  T? emptyValue,
}) {
  if (emptyValue != null && _hasOption(options, prefix)) return emptyValue;
  String? option = _extractStringOption(options, '$prefix=', null);
  if (option == null) return null;
  return values.firstWhereOrNull((e) => e.name == option);
}

bool _hasOption(List<String> options, String option) {
  return options.contains(option);
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

Map<fe.ExperimentalFlag, bool> _extractExperiments(
  List<String> options, {
  void Function(String)? onError,
  void Function(String)? onWarning,
}) {
  List<String>? experiments = _extractOptionalCsvOption(
    options,
    Flags.enableLanguageExperiments,
  );
  onError ??= (String error) => throw ArgumentError(error);
  onWarning ??= (String warning) => print(warning);
  return fe.parseExperimentalFlags(
    fe.parseExperimentalArguments(experiments),
    onError: onError,
    onWarning: onWarning,
  );
}

void _extractFeatures(
  List<String> options,
  List<FeatureOption> features,
  FeatureStatus status,
) {
  bool hasCanaryFlag = _hasOption(options, Flags.canary);
  bool hasNoShippingFlag = _hasOption(options, Flags.noShipping);
  for (var feature in features) {
    String featureFlag = feature.flag;
    String enableFeatureFlag = '--$featureFlag';
    String disableFeatureFlag = '--no-$featureFlag';
    bool enableFeature = _hasOption(options, enableFeatureFlag);
    bool disableFeature = _hasOption(options, disableFeatureFlag);
    if (enableFeature && disableFeature) {
      throw ArgumentError(
        "'$enableFeatureFlag' incompatible with "
        "'$disableFeatureFlag'",
      );
    }
    bool globalEnable =
        hasCanaryFlag ||
        (status == FeatureStatus.shipping && !hasNoShippingFlag);
    globalEnable = feature.isNegativeFlag ? !globalEnable : globalEnable;
    feature.state = (enableFeature || globalEnable) && !disableFeature;
  }
}

void _verifyShippedFeatures(
  List<String> options,
  List<FeatureOption> features,
) {
  for (var feature in features) {
    String featureFlag = feature.flag;
    String enableFeatureFlag = '--$featureFlag';
    String disableFeatureFlag = '--no-$featureFlag';
    bool enableFeature = _hasOption(options, enableFeatureFlag);
    bool disableFeature = _hasOption(options, disableFeatureFlag);
    if (enableFeature && disableFeature) {
      throw ArgumentError(
        "'$enableFeatureFlag' incompatible with "
        "'$disableFeatureFlag'",
      );
    }
    if (enableFeature && feature.isNegativeFlag) {
      throw ArgumentError(
        "$enableFeatureFlag has been removed and cannot be enabled.",
      );
    }
    if (disableFeature && !feature.isNegativeFlag) {
      throw ArgumentError(
        "$enableFeatureFlag has already shipped and cannot be disabled.",
      );
    }
    feature.state = !feature.isNegativeFlag;
  }
}

const String _undeterminedBuildID = "build number could not be determined";
