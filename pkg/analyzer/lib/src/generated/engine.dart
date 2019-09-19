// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:front_end/src/fasta/scanner/token.dart';
import 'package:path/path.dart' as pathos;
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/error/listener.dart' show RecordingErrorListener;
export 'package:analyzer/src/generated/timestamped_data.dart'
    show TimestampedData;

/// Used by [AnalysisOptions] to allow function bodies to be analyzed in some
/// sources but not others.
typedef bool AnalyzeFunctionBodiesPredicate(Source source);

/// A context in which a single analysis can be performed and incrementally
/// maintained. The context includes such information as the version of the SDK
/// being analyzed against as well as the package-root used to resolve 'package:'
/// URI's. (Both of which are known indirectly through the [SourceFactory].)
///
/// An analysis context also represents the state of the analysis, which includes
/// knowing which sources have been included in the analysis (either directly or
/// indirectly) and the results of the analysis. Sources must be added and
/// removed from the context using the method [applyChanges], which is also used
/// to notify the context when sources have been modified and, consequently,
/// previously known results might have been invalidated.
///
/// There are two ways to access the results of the analysis. The most common is
/// to use one of the 'get' methods to access the results. The 'get' methods have
/// the advantage that they will always return quickly, but have the disadvantage
/// that if the results are not currently available they will return either
/// nothing or in some cases an incomplete result. The second way to access
/// results is by using one of the 'compute' methods. The 'compute' methods will
/// always attempt to compute the requested results but might block the caller
/// for a significant period of time.
///
/// When results have been invalidated, have never been computed (as is the case
/// for newly added sources), or have been removed from the cache, they are
/// <b>not</b> automatically recreated. They will only be recreated if one of the
/// 'compute' methods is invoked.
///
/// However, this is not always acceptable. Some clients need to keep the
/// analysis results up-to-date. For such clients there is a mechanism that
/// allows them to incrementally perform needed analysis and get notified of the
/// consequent changes to the analysis results. This mechanism is realized by the
/// method [performAnalysisTask].
///
/// Analysis engine allows for having more than one context. This can be used,
/// for example, to perform one analysis based on the state of files on disk and
/// a separate analysis based on the state of those files in open editors. It can
/// also be used to perform an analysis based on a proposed future state, such as
/// the state after a refactoring.
abstract class AnalysisContext {
  /// Return the set of analysis options controlling the behavior of this
  /// context. Clients should not modify the returned set of options.
  AnalysisOptions get analysisOptions;

  /// Set the set of analysis options controlling the behavior of this context to
  /// the given [options]. Clients can safely assume that all necessary analysis
  /// results have been invalidated.
  void set analysisOptions(AnalysisOptions options);

  /// Return the set of declared variables used when computing constant values.
  DeclaredVariables get declaredVariables;

  /// Return the source factory used to create the sources that can be analyzed
  /// in this context.
  SourceFactory get sourceFactory;

  /// Set the source factory used to create the sources that can be analyzed in
  /// this context to the given source [factory]. Clients can safely assume that
  /// all analysis results have been invalidated.
  void set sourceFactory(SourceFactory factory);

  /// Return a type provider for this context or throw [AnalysisException] if
  /// either `dart:core` or `dart:async` cannot be resolved.
  TypeProvider get typeProvider;

  /// Return a type system for this context.
  TypeSystem get typeSystem;

  /// Apply the changes specified by the given [changeSet] to this context. Any
  /// analysis results that have been invalidated by these changes will be
  /// removed.
  /// TODO(scheglov) This method is referenced by the internal indexer tool.
  void applyChanges(ChangeSet changeSet);
}

/// The entry point for the functionality provided by the analysis engine. There
/// is a single instance of this class.
class AnalysisEngine {
  /// The suffix used for Dart source files.
  static const String SUFFIX_DART = "dart";

  /// The short suffix used for HTML files.
  static const String SUFFIX_HTM = "htm";

  /// The long suffix used for HTML files.
  static const String SUFFIX_HTML = "html";

  /// The deprecated file name used for analysis options files.
  static const String ANALYSIS_OPTIONS_FILE = '.analysis_options';

  /// The file name used for analysis options files.
  static const String ANALYSIS_OPTIONS_YAML_FILE = 'analysis_options.yaml';

  /// The file name used for pubspec files.
  static const String PUBSPEC_YAML_FILE = 'pubspec.yaml';

  /// The file name used for Android manifest files.
  static const String ANDROID_MANIFEST_FILE = 'AndroidManifest.xml';

  /// The unique instance of this class.
  static final AnalysisEngine instance = new AnalysisEngine._();

  /// The logger that should receive information about errors within the analysis
  /// engine.
  Logger _logger = Logger.NULL;

  /// The instrumentation service that is to be used by this analysis engine.
  InstrumentationService _instrumentationService =
      InstrumentationService.NULL_SERVICE;

  /// The partition manager being used to manage the shared partitions.
  final PartitionManager partitionManager = new PartitionManager();

  AnalysisEngine._();

  /// Return the instrumentation service that is to be used by this analysis
  /// engine.
  InstrumentationService get instrumentationService => _instrumentationService;

  /// Set the instrumentation service that is to be used by this analysis engine
  /// to the given [service].
  void set instrumentationService(InstrumentationService service) {
    if (service == null) {
      _instrumentationService = InstrumentationService.NULL_SERVICE;
    } else {
      _instrumentationService = service;
    }
  }

  /// Return the logger that should receive information about errors within the
  /// analysis engine.
  Logger get logger => _logger;

  /// Set the logger that should receive information about errors within the
  /// analysis engine to the given [logger].
  void set logger(Logger logger) {
    this._logger = logger ?? Logger.NULL;
  }

  /// Clear any caches holding on to analysis results so that a full re-analysis
  /// will be performed the next time an analysis context is created.
  void clearCaches() {
    partitionManager.clearCache();
    // See https://github.com/dart-lang/sdk/issues/30314.
    StringToken.canonicalizer.clear();
  }

  /// Create and return a new context in which analysis can be performed.
  AnalysisContext createAnalysisContext() {
    return new AnalysisContextImpl();
  }

  /// A utility method that clients can use to process all of the required
  /// plugins. This method can only be used by clients that do not need to
  /// process any other plugins.
  @deprecated
  void processRequiredPlugins() {}

  /// Return `true` if the given [fileName] is an analysis options file.
  static bool isAnalysisOptionsFileName(String fileName,
      [pathos.Context context]) {
    if (fileName == null) {
      return false;
    }
    String basename = (context ?? pathos.posix).basename(fileName);
    return basename == ANALYSIS_OPTIONS_FILE ||
        basename == ANALYSIS_OPTIONS_YAML_FILE;
  }

  /// Return `true` if the given [fileName] is assumed to contain Dart source
  /// code.
  static bool isDartFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    String extension = FileNameUtilities.getExtension(fileName).toLowerCase();
    return extension == SUFFIX_DART;
  }

  /// Return `true` if the given [fileName] is AndroidManifest.xml
  static bool isManifestFileName(String fileName) {
    if (fileName == null) {
      return false;
    }
    return fileName.endsWith(AnalysisEngine.ANDROID_MANIFEST_FILE);
  }
}

/// The analysis errors and line information for the errors.
abstract class AnalysisErrorInfo {
  /// Return the errors that as a result of the analysis, or `null` if there were
  /// no errors.
  List<AnalysisError> get errors;

  /// Return the line information associated with the errors, or `null` if there
  /// were no errors.
  LineInfo get lineInfo;
}

/// The analysis errors and line info associated with a source.
class AnalysisErrorInfoImpl implements AnalysisErrorInfo {
  /// The analysis errors associated with a source, or `null` if there are no
  /// errors.
  @override
  final List<AnalysisError> errors;

  /// The line information associated with the errors, or `null` if there are no
  /// errors.
  final LineInfo lineInfo;

  /// Initialize an newly created error info with the given [errors] and
  /// [lineInfo].
  AnalysisErrorInfoImpl(this.errors, this.lineInfo);
}

/// A set of analysis options used to control the behavior of an analysis
/// context.
abstract class AnalysisOptions {
  /// The length of the list returned by [signature].
  static const int signatureLength = 4;

  /// Function that returns `true` if analysis is to parse and analyze function
  /// bodies for a given source.
  AnalyzeFunctionBodiesPredicate get analyzeFunctionBodiesPredicate;

  /// Return the maximum number of sources for which AST structures should be
  /// kept in the cache.
  ///
  /// DEPRECATED: This setting no longer has any effect.
  @deprecated
  int get cacheSize;

  /// A flag indicating whether to run checks on AndroidManifest.xml file to
  /// see if it is complaint with Chrome OS.
  bool get chromeOsManifestChecks;

  /// The set of features that are globally enabled for this context.
  FeatureSet get contextFeatures;

  /// Return `true` if analysis is to generate dart2js related hint results.
  bool get dart2jsHint;

  /// Return `true` if cache flushing should be disabled.  Setting this option to
  /// `true` can improve analysis speed at the expense of memory usage.  It may
  /// also be useful for working around bugs.
  ///
  /// This option should not be used when the analyzer is part of a long running
  /// process (such as the analysis server) because it has the potential to
  /// prevent memory from being reclaimed.
  bool get disableCacheFlushing;

  /// Return `true` if the parser is to parse asserts in the initializer list of
  /// a constructor.
  @deprecated
  bool get enableAssertInitializer;

  /// Return `true` to enable custom assert messages (DEP 37).
  @deprecated
  bool get enableAssertMessage;

  /// Return `true` to if analysis is to enable async support.
  @deprecated
  bool get enableAsync;

  /// Return `true` to enable interface libraries (DEP 40).
  @deprecated
  bool get enableConditionalDirectives;

  /// Return a list containing the names of the experiments that are enabled in
  /// the context associated with these options.
  ///
  /// The process around these experiments is described in this
  /// [doc](https://github.com/dart-lang/sdk/blob/master/docs/process/experimental-flags.md).
  List<String> get enabledExperiments;

  /// Return a list of the names of the packages for which, if they define a
  /// plugin, the plugin should be enabled.
  List<String> get enabledPluginNames;

  /// Return `true` to enable generic methods (DEP 22).
  @deprecated
  bool get enableGenericMethods => null;

  /// Return `true` if access to field formal parameters should be allowed in a
  /// constructor's initializer list.
  @deprecated
  bool get enableInitializingFormalAccess;

  /// Return `true` to enable the lazy compound assignment operators '&&=' and
  /// '||='.
  bool get enableLazyAssignmentOperators;

  /// Return `true` if mixins are allowed to inherit from types other than
  /// Object, and are allowed to reference `super`.
  @deprecated
  bool get enableSuperMixins;

  /// Return `true` if timing data should be gathered during execution.
  bool get enableTiming;

  /// Return `true` to enable the use of URIs in part-of directives.
  @deprecated
  bool get enableUriInPartOf;

  /// Return a list of error processors that are to be used when reporting
  /// errors in some analysis context.
  List<ErrorProcessor> get errorProcessors;

  /// Return a list of exclude patterns used to exclude some sources from
  /// analysis.
  List<String> get excludePatterns;

  /// Return `true` if errors, warnings and hints should be generated for sources
  /// that are implicitly being analyzed. The default value is `true`.
  bool get generateImplicitErrors;

  /// Return `true` if errors, warnings and hints should be generated for sources
  /// in the SDK. The default value is `false`.
  bool get generateSdkErrors;

  /// Return `true` if analysis is to generate hint results (e.g. type inference
  /// based information and pub best practices).
  bool get hint;

  /// Return `true` if analysis is to generate lint warnings.
  bool get lint;

  /// Return a list of the lint rules that are to be run in an analysis context
  /// if [lint] returns `true`.
  List<Linter> get lintRules;

  /// A mapping from Dart SDK library name (e.g. "dart:core") to a list of paths
  /// to patch files that should be applied to the library.
  Map<String, List<String>> get patchPaths;

  /// Return `true` if analysis is to parse comments.
  bool get preserveComments;

  /// Return `true` if analyzer should enable the use of Dart 2.0 features.
  ///
  /// This getter is deprecated, and is hard-coded to always return true.
  @Deprecated(
      'This getter is deprecated and is hard-coded to always return true.')
  bool get previewDart2;

  /// The version range for the SDK specified in `pubspec.yaml`, or `null` if
  /// there is no `pubspec.yaml` or if it does not contain an SDK range.
  VersionConstraint get sdkVersionConstraint;

  /// Return the opaque signature of the options.
  ///
  /// The length of the list is guaranteed to equal [signatureLength].
  Uint32List get signature;

  /// Return `true` if strong mode analysis should be used.
  ///
  /// This getter is deprecated, and is hard-coded to always return true.
  @Deprecated(
      'This getter is deprecated and is hard-coded to always return true.')
  bool get strongMode;

  /// Return `true` if dependencies between computed results should be tracked
  /// by analysis cache.  This option should only be set to `false` if analysis
  /// is performed in such a way that none of the inputs is ever changed
  /// during the life time of the context.
  bool get trackCacheDependencies;

  /// Return `true` if analyzer should use the Dart 2.0 Front End parser.
  bool get useFastaParser;

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name);

  /// Reset the state of this set of analysis options to its original state.
  void resetToDefaults();

  /// Set the values of the cross-context options to match those in the given set
  /// of [options].
  @deprecated
  void setCrossContextOptionsFrom(AnalysisOptions options);

  /// Determine whether two signatures returned by [signature] are equal.
  static bool signaturesEqual(Uint32List a, Uint32List b) {
    assert(a.length == signatureLength);
    assert(b.length == signatureLength);
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// A set of analysis options used to control the behavior of an analysis
/// context.
class AnalysisOptionsImpl implements AnalysisOptions {
  /// DEPRECATED: The maximum number of sources for which data should be kept in
  /// the cache.
  ///
  /// This constant no longer has any effect.
  @deprecated
  static const int DEFAULT_CACHE_SIZE = 64;

  /// The length of the list returned by [unlinkedSignature].
  static const int unlinkedSignatureLength = 4;

  /// A predicate indicating whether analysis is to parse and analyze function
  /// bodies.
  AnalyzeFunctionBodiesPredicate _analyzeFunctionBodiesPredicate =
      _analyzeAllFunctionBodies;

  /// The cached [unlinkedSignature].
  Uint32List _unlinkedSignature;

  /// The cached [signature].
  Uint32List _signature;

  @override
  VersionConstraint sdkVersionConstraint;

  @override
  @deprecated
  int cacheSize = 64;

  @override
  bool dart2jsHint = false;

  List<String> _enabledExperiments = const <String>[];

  ExperimentStatus _contextFeatures = ExperimentStatus();

  @override
  List<String> enabledPluginNames = const <String>[];

  @override
  bool enableLazyAssignmentOperators = false;

  @override
  bool enableTiming = false;

  /// A list of error processors that are to be used when reporting errors in
  /// some analysis context.
  List<ErrorProcessor> _errorProcessors;

  /// A list of exclude patterns used to exclude some sources from analysis.
  List<String> _excludePatterns;

  @override
  bool generateImplicitErrors = true;

  @override
  bool generateSdkErrors = false;

  @override
  bool hint = true;

  @override
  bool lint = false;

  /// The lint rules that are to be run in an analysis context if [lint] returns
  /// `true`.
  List<Linter> _lintRules;

  Map<String, List<String>> patchPaths = {};

  @override
  bool preserveComments = true;

  /// A flag indicating whether strong-mode inference hints should be
  /// used.  This flag is not exposed in the interface, and should be
  /// replaced by something more general.
  // TODO(leafp): replace this with something more general
  bool strongModeHints = false;

  @override
  bool trackCacheDependencies = true;

  @override
  bool useFastaParser = true;

  @override
  bool disableCacheFlushing = false;

  /// A flag indicating whether implicit casts are allowed in [strongMode]
  /// (they are always allowed in Dart 1.0 mode).
  ///
  /// This option is experimental and subject to change.
  bool implicitCasts = true;

  /// A flag indicating whether implicit dynamic type is allowed, on by default.
  ///
  /// This flag can be used without necessarily enabling [strongMode], but it is
  /// designed with strong mode's type inference in mind. Without type inference,
  /// it will raise many errors. Also it does not provide type safety without
  /// strong mode.
  ///
  /// This option is experimental and subject to change.
  bool implicitDynamic = true;

  /// A flag indicating whether inference failures are allowed, off by default.
  ///
  /// This option is experimental and subject to change.
  bool strictInference = false;

  /// Whether raw types (types without explicit type arguments, such as `List`)
  /// should be reported as potential problems.
  ///
  /// Raw types are a common source of `dynamic` being introduced implicitly.
  /// This often leads to cast failures later on in the program.
  bool strictRawTypes = false;

  @override
  bool chromeOsManifestChecks = false;

  /// Initialize a newly created set of analysis options to have their default
  /// values.
  AnalysisOptionsImpl();

  /// Initialize a newly created set of analysis options to have the same values
  /// as those in the given set of analysis [options].
  AnalysisOptionsImpl.from(AnalysisOptions options) {
    analyzeFunctionBodiesPredicate = options.analyzeFunctionBodiesPredicate;
    dart2jsHint = options.dart2jsHint;
    enabledExperiments = options.enabledExperiments;
    enabledPluginNames = options.enabledPluginNames;
    enableLazyAssignmentOperators = options.enableLazyAssignmentOperators;
    enableTiming = options.enableTiming;
    errorProcessors = options.errorProcessors;
    excludePatterns = options.excludePatterns;
    generateImplicitErrors = options.generateImplicitErrors;
    generateSdkErrors = options.generateSdkErrors;
    hint = options.hint;
    lint = options.lint;
    lintRules = options.lintRules;
    preserveComments = options.preserveComments;
    useFastaParser = options.useFastaParser;
    if (options is AnalysisOptionsImpl) {
      strongModeHints = options.strongModeHints;
      implicitCasts = options.implicitCasts;
      implicitDynamic = options.implicitDynamic;
      strictInference = options.strictInference;
      strictRawTypes = options.strictRawTypes;
    }
    trackCacheDependencies = options.trackCacheDependencies;
    disableCacheFlushing = options.disableCacheFlushing;
    patchPaths = options.patchPaths;
    sdkVersionConstraint = options.sdkVersionConstraint;
  }

  bool get analyzeFunctionBodies {
    if (identical(analyzeFunctionBodiesPredicate, _analyzeAllFunctionBodies)) {
      return true;
    } else if (identical(
        analyzeFunctionBodiesPredicate, _analyzeNoFunctionBodies)) {
      return false;
    } else {
      throw new StateError('analyzeFunctionBodiesPredicate in use');
    }
  }

  set analyzeFunctionBodies(bool value) {
    if (value) {
      analyzeFunctionBodiesPredicate = _analyzeAllFunctionBodies;
    } else {
      analyzeFunctionBodiesPredicate = _analyzeNoFunctionBodies;
    }
  }

  @override
  AnalyzeFunctionBodiesPredicate get analyzeFunctionBodiesPredicate =>
      _analyzeFunctionBodiesPredicate;

  set analyzeFunctionBodiesPredicate(AnalyzeFunctionBodiesPredicate value) {
    if (value == null) {
      throw new ArgumentError.notNull('analyzeFunctionBodiesPredicate');
    }
    _analyzeFunctionBodiesPredicate = value;
  }

  @override
  FeatureSet get contextFeatures => _contextFeatures;

  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet;
    _enabledExperiments = _contextFeatures.toStringList();
  }

  @deprecated
  @override
  bool get enableAssertInitializer => true;

  @deprecated
  void set enableAssertInitializer(bool enable) {}

  @override
  @deprecated
  bool get enableAssertMessage => true;

  @deprecated
  void set enableAssertMessage(bool enable) {}

  @deprecated
  @override
  bool get enableAsync => true;

  @deprecated
  void set enableAsync(bool enable) {}

  /// A flag indicating whether interface libraries are to be supported (DEP 40).
  bool get enableConditionalDirectives => true;

  @deprecated
  void set enableConditionalDirectives(_) {}

  @override
  List<String> get enabledExperiments => _enabledExperiments;

  set enabledExperiments(List<String> enabledExperiments) {
    _enabledExperiments = enabledExperiments;
    _contextFeatures = ExperimentStatus.fromStrings(enabledExperiments);
  }

  @override
  @deprecated
  bool get enableGenericMethods => true;

  @deprecated
  void set enableGenericMethods(bool enable) {}

  @deprecated
  @override
  bool get enableInitializingFormalAccess => true;

  @deprecated
  void set enableInitializingFormalAccess(bool enable) {}

  @override
  @deprecated
  bool get enableSuperMixins => false;

  @deprecated
  void set enableSuperMixins(bool enable) {
    // Ignored.
  }

  @deprecated
  @override
  bool get enableUriInPartOf => true;

  @deprecated
  void set enableUriInPartOf(bool enable) {}

  @override
  List<ErrorProcessor> get errorProcessors =>
      _errorProcessors ??= const <ErrorProcessor>[];

  /// Set the list of error [processors] that are to be used when reporting
  /// errors in some analysis context.
  void set errorProcessors(List<ErrorProcessor> processors) {
    _errorProcessors = processors;
  }

  @override
  List<String> get excludePatterns => _excludePatterns ??= const <String>[];

  /// Set the exclude patterns used to exclude some sources from analysis to
  /// those in the given list of [patterns].
  void set excludePatterns(List<String> patterns) {
    _excludePatterns = patterns;
  }

  /// The set of enabled experiments.
  ExperimentStatus get experimentStatus => _contextFeatures;

  /// Return `true` to enable mixin declarations.
  /// https://github.com/dart-lang/language/issues/12
  @deprecated
  bool get isMixinSupportEnabled => true;

  @deprecated
  set isMixinSupportEnabled(bool value) {}

  @override
  List<Linter> get lintRules => _lintRules ??= const <Linter>[];

  /// Set the lint rules that are to be run in an analysis context if [lint]
  /// returns `true`.
  void set lintRules(List<Linter> rules) {
    _lintRules = rules;
  }

  @deprecated
  @override
  bool get previewDart2 => true;

  @deprecated
  set previewDart2(bool value) {}

  @override
  Uint32List get signature {
    if (_signature == null) {
      ApiSignature buffer = new ApiSignature();

      // Append environment.
      if (sdkVersionConstraint != null) {
        buffer.addString(sdkVersionConstraint.toString());
      }

      // Append boolean flags.
      buffer.addBool(enableLazyAssignmentOperators);
      buffer.addBool(implicitCasts);
      buffer.addBool(implicitDynamic);
      buffer.addBool(strictInference);
      buffer.addBool(strictRawTypes);
      buffer.addBool(strongModeHints);
      buffer.addBool(useFastaParser);

      // Append enabled experiments.
      buffer.addInt(enabledExperiments.length);
      for (String experimentName in enabledExperiments) {
        buffer.addString(experimentName);
      }

      // Append error processors.
      buffer.addInt(errorProcessors.length);
      for (ErrorProcessor processor in errorProcessors) {
        buffer.addString(processor.description);
      }

      // Append lints.
      buffer.addString(linterVersion ?? '');
      buffer.addInt(lintRules.length);
      for (Linter lintRule in lintRules) {
        buffer.addString(lintRule.lintCode.uniqueName);
      }

      // Append plugin names.
      buffer.addInt(enabledPluginNames.length);
      for (String enabledPluginName in enabledPluginNames) {
        buffer.addString(enabledPluginName);
      }

      // Hash and convert to Uint32List.
      List<int> bytes = buffer.toByteList();
      _signature = new Uint8List.fromList(bytes).buffer.asUint32List();
    }
    return _signature;
  }

  @override
  bool get strongMode => true;

  @Deprecated(
      "The strongMode field is deprecated, and shouldn't be assigned to")
  set strongMode(bool value) {}

  /// Return the opaque signature of the options that affect unlinked data.
  ///
  /// The length of the list is guaranteed to equal [unlinkedSignatureLength].
  Uint32List get unlinkedSignature {
    if (_unlinkedSignature == null) {
      ApiSignature buffer = new ApiSignature();

      // Append boolean flags.
      buffer.addBool(enableLazyAssignmentOperators);
      buffer.addBool(useFastaParser);

      // Append enabled experiments.
      buffer.addInt(enabledExperiments.length);
      for (String experimentName in enabledExperiments) {
        buffer.addString(experimentName);
      }

      // Hash and convert to Uint32List.
      List<int> bytes = buffer.toByteList();
      _unlinkedSignature = new Uint8List.fromList(bytes).buffer.asUint32List();
    }
    return _unlinkedSignature;
  }

  @override
  bool isLintEnabled(String name) {
    return lintRules.any((rule) => rule.name == name);
  }

  @override
  void resetToDefaults() {
    dart2jsHint = false;
    disableCacheFlushing = false;
    enabledExperiments = const <String>[];
    enabledPluginNames = const <String>[];
    enableLazyAssignmentOperators = false;
    enableTiming = false;
    _errorProcessors = null;
    _excludePatterns = null;
    generateImplicitErrors = true;
    generateSdkErrors = false;
    hint = true;
    implicitCasts = true;
    implicitDynamic = true;
    strictInference = false;
    strictRawTypes = false;
    lint = false;
    _lintRules = null;
    patchPaths = {};
    preserveComments = true;
    strongModeHints = false;
    trackCacheDependencies = true;
    useFastaParser = true;
  }

  @deprecated
  @override
  void setCrossContextOptionsFrom(AnalysisOptions options) {
    enableLazyAssignmentOperators = options.enableLazyAssignmentOperators;
    if (options is AnalysisOptionsImpl) {
      strongModeHints = options.strongModeHints;
    }
  }

  /// Return whether the given lists of lints are equal.
  static bool compareLints(List<Linter> a, List<Linter> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].lintCode != b[i].lintCode) {
        return false;
      }
    }
    return true;
  }

  /// Predicate used for [analyzeFunctionBodiesPredicate] when
  /// [analyzeFunctionBodies] is set to `true`.
  static bool _analyzeAllFunctionBodies(Source _) => true;

  /// Predicate used for [analyzeFunctionBodiesPredicate] when
  /// [analyzeFunctionBodies] is set to `false`.
  static bool _analyzeNoFunctionBodies(Source _) => false;
}

/// An indication of which sources have been added, changed, removed, or deleted.
/// In the case of a changed source, there are multiple ways of indicating the
/// nature of the change.
///
/// No source should be added to the change set more than once, either with the
/// same or a different kind of change. It does not make sense, for example, for
/// a source to be both added and removed, and it is redundant for a source to be
/// marked as changed in its entirety and changed in some specific range.
class ChangeSet {
  /// A list containing the sources that have been added.
  final List<Source> addedSources = new List<Source>();

  /// A list containing the sources that have been changed.
  final List<Source> changedSources = new List<Source>();

  /// A table mapping the sources whose content has been changed to the current
  /// content of those sources.
  Map<Source, String> _changedContent = new HashMap<Source, String>();

  /// A table mapping the sources whose content has been changed within a single
  /// range to the current content of those sources and information about the
  /// affected range.
  final HashMap<Source, ChangeSet_ContentChange> changedRanges =
      new HashMap<Source, ChangeSet_ContentChange>();

  /// A list containing the sources that have been removed.
  final List<Source> removedSources = new List<Source>();

  /// A list containing the source containers specifying additional sources that
  /// have been removed.
  final List<SourceContainer> removedContainers = new List<SourceContainer>();

  /// Return a table mapping the sources whose content has been changed to the
  /// current content of those sources.
  Map<Source, String> get changedContents => _changedContent;

  /// Return `true` if this change set does not contain any changes.
  bool get isEmpty =>
      addedSources.isEmpty &&
      changedSources.isEmpty &&
      _changedContent.isEmpty &&
      changedRanges.isEmpty &&
      removedSources.isEmpty &&
      removedContainers.isEmpty;

  /// Record that the specified [source] has been added and that its content is
  /// the default contents of the source.
  void addedSource(Source source) {
    addedSources.add(source);
  }

  /// Record that the specified [source] has been changed and that its content is
  /// the given [contents].
  void changedContent(Source source, String contents) {
    _changedContent[source] = contents;
  }

  /// Record that the specified [source] has been changed and that its content is
  /// the given [contents]. The [offset] is the offset into the current contents.
  /// The [oldLength] is the number of characters in the original contents that
  /// were replaced. The [newLength] is the number of characters in the
  /// replacement text.
  void changedRange(Source source, String contents, int offset, int oldLength,
      int newLength) {
    changedRanges[source] =
        new ChangeSet_ContentChange(contents, offset, oldLength, newLength);
  }

  /// Record that the specified [source] has been changed. If the content of the
  /// source was previously overridden, this has no effect (the content remains
  /// overridden). To cancel (or change) the override, use [changedContent]
  /// instead.
  void changedSource(Source source) {
    changedSources.add(source);
  }

  /// Record that the specified source [container] has been removed.
  void removedContainer(SourceContainer container) {
    if (container != null) {
      removedContainers.add(container);
    }
  }

  /// Record that the specified [source] has been removed.
  void removedSource(Source source) {
    if (source != null) {
      removedSources.add(source);
    }
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    bool needsSeparator =
        _appendSources(buffer, addedSources, false, "addedSources");
    needsSeparator = _appendSources(
        buffer, changedSources, needsSeparator, "changedSources");
    needsSeparator = _appendSources2(
        buffer, _changedContent, needsSeparator, "changedContent");
    needsSeparator =
        _appendSources2(buffer, changedRanges, needsSeparator, "changedRanges");
    needsSeparator = _appendSources(
        buffer, removedSources, needsSeparator, "removedSources");
    int count = removedContainers.length;
    if (count > 0) {
      if (removedSources.isEmpty) {
        if (needsSeparator) {
          buffer.write("; ");
        }
        buffer.write("removed: from ");
        buffer.write(count);
        buffer.write(" containers");
      } else {
        buffer.write(", and more from ");
        buffer.write(count);
        buffer.write(" containers");
      }
    }
    return buffer.toString();
  }

  /// Append the given [sources] to the given [buffer], prefixed with the given
  /// [label] and a separator if [needsSeparator] is `true`. Return `true` if
  /// future lists of sources will need a separator.
  bool _appendSources(StringBuffer buffer, List<Source> sources,
      bool needsSeparator, String label) {
    if (sources.isEmpty) {
      return needsSeparator;
    }
    if (needsSeparator) {
      buffer.write("; ");
    }
    buffer.write(label);
    String prefix = " ";
    for (Source source in sources) {
      buffer.write(prefix);
      buffer.write(source.fullName);
      prefix = ", ";
    }
    return true;
  }

  /// Append the given [sources] to the given [builder], prefixed with the given
  /// [label] and a separator if [needsSeparator] is `true`. Return `true` if
  /// future lists of sources will need a separator.
  bool _appendSources2(StringBuffer buffer, Map<Source, dynamic> sources,
      bool needsSeparator, String label) {
    if (sources.isEmpty) {
      return needsSeparator;
    }
    if (needsSeparator) {
      buffer.write("; ");
    }
    buffer.write(label);
    String prefix = " ";
    for (Source source in sources.keys.toSet()) {
      buffer.write(prefix);
      buffer.write(source.fullName);
      prefix = ", ";
    }
    return true;
  }
}

/// A change to the content of a source.
class ChangeSet_ContentChange {
  /// The new contents of the source.
  final String contents;

  /// The offset into the current contents.
  final int offset;

  /// The number of characters in the original contents that were replaced
  final int oldLength;

  /// The number of characters in the replacement text.
  final int newLength;

  /// Initialize a newly created change object to represent a change to the
  /// content of a source. The [contents] is the new contents of the source. The
  /// [offset] is the offset into the current contents. The [oldLength] is the
  /// number of characters in the original contents that were replaced. The
  /// [newLength] is the number of characters in the replacement text.
  ChangeSet_ContentChange(
      this.contents, this.offset, this.oldLength, this.newLength);
}

/// Additional behavior for an analysis context that is required by internal
/// users of the context.
abstract class InternalAnalysisContext implements AnalysisContext {
  /// Sets the [TypeProvider] for this context.
  void set typeProvider(TypeProvider typeProvider);
}

/// An object that can be used to receive information about errors within the
/// analysis engine. Implementations usually write this information to a file,
/// but can also record the information for later use (such as during testing) or
/// even ignore the information.
abstract class Logger {
  /// A logger that ignores all logging.
  static final Logger NULL = new NullLogger();

  /// Log the given message as an error. The [message] is expected to be an
  /// explanation of why the error occurred or what it means. The [exception] is
  /// expected to be the reason for the error. At least one argument must be
  /// provided.
  void logError(String message, [CaughtException exception]);

  /// Log the given informational message. The [message] is expected to be an
  /// explanation of why the error occurred or what it means. The [exception] is
  /// expected to be the reason for the error.
  void logInformation(String message, [CaughtException exception]);
}

/// An implementation of [Logger] that does nothing.
class NullLogger implements Logger {
  @override
  void logError(String message, [CaughtException exception]) {}

  @override
  void logInformation(String message, [CaughtException exception]) {}
}

/// Container with global [AnalysisContext] performance statistics.
class PerformanceStatistics {
  /// The [PerformanceTag] for `package:analyzer`.
  static PerformanceTag analyzer = new PerformanceTag('analyzer');

  /// The [PerformanceTag] for time spent in reading files.
  static PerformanceTag io = analyzer.createChild('io');

  /// The [PerformanceTag] for general phases of analysis.
  static PerformanceTag analysis = analyzer.createChild('analysis');

  /// The [PerformanceTag] for time spent in scanning.
  static PerformanceTag scan = analyzer.createChild('scan');

  /// The [PerformanceTag] for time spent in parsing.
  static PerformanceTag parse = analyzer.createChild('parse');

  /// The [PerformanceTag] for time spent in resolving.
  static PerformanceTag resolve = new PerformanceTag('resolve');

  /// The [PerformanceTag] for time spent in error verifier.
  static PerformanceTag errors = analysis.createChild('errors');

  /// The [PerformanceTag] for time spent in hints generator.
  static PerformanceTag hints = analysis.createChild('hints');

  /// The [PerformanceTag] for time spent in linting.
  static PerformanceTag lints = analysis.createChild('lints');

  /// The [PerformanceTag] for time spent computing cycles.
  static PerformanceTag cycles = new PerformanceTag('cycles');

  /// The [PerformanceTag] for time spent in summaries support.
  static PerformanceTag summary = analyzer.createChild('summary');
}
