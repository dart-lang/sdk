// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:path/path.dart' as pathos;
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/error/listener.dart' show RecordingErrorListener;
export 'package:analyzer/src/generated/timestamped_data.dart'
    show TimestampedData;

/// Used by [AnalysisOptions] to allow function bodies to be analyzed in some
/// sources but not others.
typedef AnalyzeFunctionBodiesPredicate = bool Function(Source source);

/// A context in which a single analysis can be performed and incrementally
/// maintained. The context includes such information as the version of the SDK
/// being analyzed against, and how to resolve 'package:' URI's. (Both of which
/// are known indirectly through the [SourceFactory].)
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
  set analysisOptions(AnalysisOptions options);

  /// Return the set of declared variables used when computing constant values.
  DeclaredVariables get declaredVariables;

  /// Return the source factory used to create the sources that can be analyzed
  /// in this context.
  SourceFactory get sourceFactory;

  /// Set the source factory used to create the sources that can be analyzed in
  /// this context to the given source [factory]. Clients can safely assume that
  /// all analysis results have been invalidated.
  set sourceFactory(SourceFactory factory);

  /// Return a type provider for this context or throw [AnalysisException] if
  /// either `dart:core` or `dart:async` cannot be resolved.
  @Deprecated('Use LibraryElement.typeProvider')
  TypeProvider get typeProvider;

  /// Return a type system for this context.
  @Deprecated('Use LibraryElement.typeSystem')
  TypeSystem get typeSystem;
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

  /// The file name used for analysis options files.
  static const String ANALYSIS_OPTIONS_YAML_FILE = 'analysis_options.yaml';

  /// The file name used for pubspec files.
  static const String PUBSPEC_YAML_FILE = 'pubspec.yaml';

  /// The file name used for Android manifest files.
  static const String ANDROID_MANIFEST_FILE = 'AndroidManifest.xml';

  /// The unique instance of this class.
  static final AnalysisEngine instance = AnalysisEngine._();

  /// The instrumentation service that is to be used by this analysis engine.
  InstrumentationService _instrumentationService =
      InstrumentationService.NULL_SERVICE;

  AnalysisEngine._();

  /// Return the instrumentation service that is to be used by this analysis
  /// engine.
  InstrumentationService get instrumentationService => _instrumentationService;

  /// Set the instrumentation service that is to be used by this analysis engine
  /// to the given [service].
  set instrumentationService(InstrumentationService service) {
    if (service == null) {
      _instrumentationService = InstrumentationService.NULL_SERVICE;
    } else {
      _instrumentationService = service;
    }
  }

  /// Clear any caches holding on to analysis results so that a full re-analysis
  /// will be performed the next time an analysis context is created.
  void clearCaches() {
    // See https://github.com/dart-lang/sdk/issues/30314.
    StringToken.canonicalizer.clear();
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
    return basename == ANALYSIS_OPTIONS_YAML_FILE;
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
  @override
  final LineInfo lineInfo;

  /// Initialize an newly created error info with the given [errors] and
  /// [lineInfo].
  AnalysisErrorInfoImpl(this.errors, this.lineInfo);
}

/// A set of analysis options used to control the behavior of an analysis
/// context.
abstract class AnalysisOptions {
  /// Function that returns `true` if analysis is to parse and analyze function
  /// bodies for a given source.
  @deprecated
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
  @deprecated
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
  @deprecated
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
  @deprecated
  bool get generateImplicitErrors;

  /// Return `true` if errors, warnings and hints should be generated for sources
  /// in the SDK. The default value is `false`.
  @deprecated
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
  @deprecated
  Map<String, List<String>> get patchPaths;

  /// Return `true` if analysis is to parse comments.
  @deprecated
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
  @deprecated
  bool get trackCacheDependencies;

  /// Return `true` if analyzer should use the Dart 2.0 Front End parser.
  bool get useFastaParser;

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name);

  /// Reset the state of this set of analysis options to its original state.
  @deprecated
  void resetToDefaults();

  /// Set the values of the cross-context options to match those in the given set
  /// of [options].
  @deprecated
  void setCrossContextOptionsFrom(AnalysisOptions options);

  /// Determine whether two signatures returned by [signature] are equal.
  static bool signaturesEqual(Uint32List a, Uint32List b) {
    assert(a.length == AnalysisOptionsImpl.signatureLength);
    assert(b.length == AnalysisOptionsImpl.signatureLength);
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
  /// The length of the list returned by `signature` getters.
  static const int signatureLength = 4;

  /// DEPRECATED: The maximum number of sources for which data should be kept in
  /// the cache.
  ///
  /// This constant no longer has any effect.
  @deprecated
  static const int DEFAULT_CACHE_SIZE = 64;

  /// A predicate indicating whether analysis is to parse and analyze function
  /// bodies.
  @deprecated
  AnalyzeFunctionBodiesPredicate _analyzeFunctionBodiesPredicate =
      _analyzeAllFunctionBodies;

  /// The cached [unlinkedSignature].
  Uint32List _unlinkedSignature;

  /// The cached [signature].
  Uint32List _signature;

  /// The cached [signatureForElements].
  Uint32List _signatureForElements;

  @override
  VersionConstraint sdkVersionConstraint;

  @override
  @deprecated
  int cacheSize = 64;

  @override
  bool dart2jsHint = false;

  ExperimentStatus _contextFeatures = ExperimentStatus();

  /// The set of features to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this feature set is *not* used, even if the
  /// package does not specify the language version. Instead [contextFeatures]
  /// is used.
  FeatureSet nonPackageFeatureSet = ExperimentStatus();

  @override
  List<String> enabledPluginNames = const <String>[];

  @deprecated
  @override
  bool enableLazyAssignmentOperators = false;

  @override
  bool enableTiming = false;

  /// A list of error processors that are to be used when reporting errors in
  /// some analysis context.
  List<ErrorProcessor> _errorProcessors;

  /// A list of exclude patterns used to exclude some sources from analysis.
  List<String> _excludePatterns;

  @deprecated
  @override
  bool generateImplicitErrors = true;

  @deprecated
  @override
  bool generateSdkErrors = false;

  @override
  bool hint = true;

  @override
  bool lint = false;

  /// The lint rules that are to be run in an analysis context if [lint] returns
  /// `true`.
  List<Linter> _lintRules;

  @deprecated
  @override
  Map<String, List<String>> patchPaths = {};

  @deprecated
  @override
  bool preserveComments = true;

  @deprecated
  @override
  bool trackCacheDependencies = true;

  @override
  bool useFastaParser = true;

  @deprecated
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
    // ignore: deprecated_member_use_from_same_package
    analyzeFunctionBodiesPredicate = options.analyzeFunctionBodiesPredicate;
    dart2jsHint = options.dart2jsHint;
    contextFeatures = options.contextFeatures;
    enabledPluginNames = options.enabledPluginNames;
    // ignore: deprecated_member_use_from_same_package
    enableLazyAssignmentOperators = options.enableLazyAssignmentOperators;
    enableTiming = options.enableTiming;
    errorProcessors = options.errorProcessors;
    excludePatterns = options.excludePatterns;
    // ignore: deprecated_member_use_from_same_package
    generateImplicitErrors = options.generateImplicitErrors;
    // ignore: deprecated_member_use_from_same_package
    generateSdkErrors = options.generateSdkErrors;
    hint = options.hint;
    lint = options.lint;
    lintRules = options.lintRules;
    // ignore: deprecated_member_use_from_same_package
    preserveComments = options.preserveComments;
    useFastaParser = options.useFastaParser;
    if (options is AnalysisOptionsImpl) {
      implicitCasts = options.implicitCasts;
      implicitDynamic = options.implicitDynamic;
      strictInference = options.strictInference;
      strictRawTypes = options.strictRawTypes;
    }
    // ignore: deprecated_member_use_from_same_package
    trackCacheDependencies = options.trackCacheDependencies;
    // ignore: deprecated_member_use_from_same_package
    disableCacheFlushing = options.disableCacheFlushing;
    // ignore: deprecated_member_use_from_same_package
    patchPaths = options.patchPaths;
    sdkVersionConstraint = options.sdkVersionConstraint;
  }

  @deprecated
  bool get analyzeFunctionBodies {
    if (identical(analyzeFunctionBodiesPredicate, _analyzeAllFunctionBodies)) {
      return true;
    } else if (identical(
        analyzeFunctionBodiesPredicate, _analyzeNoFunctionBodies)) {
      return false;
    } else {
      throw StateError('analyzeFunctionBodiesPredicate in use');
    }
  }

  @deprecated
  set analyzeFunctionBodies(bool value) {
    if (value) {
      analyzeFunctionBodiesPredicate = _analyzeAllFunctionBodies;
    } else {
      analyzeFunctionBodiesPredicate = _analyzeNoFunctionBodies;
    }
  }

  @deprecated
  @override
  AnalyzeFunctionBodiesPredicate get analyzeFunctionBodiesPredicate =>
      _analyzeFunctionBodiesPredicate;

  @deprecated
  set analyzeFunctionBodiesPredicate(AnalyzeFunctionBodiesPredicate value) {
    if (value == null) {
      throw ArgumentError.notNull('analyzeFunctionBodiesPredicate');
    }
    _analyzeFunctionBodiesPredicate = value;
  }

  @override
  FeatureSet get contextFeatures => _contextFeatures;

  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet;
    nonPackageFeatureSet = featureSet;
  }

  @deprecated
  @override
  bool get enableAssertInitializer => true;

  @deprecated
  set enableAssertInitializer(bool enable) {}

  @override
  @deprecated
  bool get enableAssertMessage => true;

  @deprecated
  set enableAssertMessage(bool enable) {}

  @deprecated
  @override
  bool get enableAsync => true;

  @deprecated
  set enableAsync(bool enable) {}

  /// A flag indicating whether interface libraries are to be supported (DEP 40).
  @override
  bool get enableConditionalDirectives => true;

  @deprecated
  set enableConditionalDirectives(_) {}

  @deprecated
  set enabledExperiments(List<String> enabledExperiments) {
    _contextFeatures = ExperimentStatus.fromStrings(enabledExperiments);
  }

  @override
  @deprecated
  bool get enableGenericMethods => true;

  @deprecated
  set enableGenericMethods(bool enable) {}

  @deprecated
  @override
  bool get enableInitializingFormalAccess => true;

  @deprecated
  set enableInitializingFormalAccess(bool enable) {}

  @override
  @deprecated
  bool get enableSuperMixins => false;

  @deprecated
  set enableSuperMixins(bool enable) {
    // Ignored.
  }

  @deprecated
  @override
  bool get enableUriInPartOf => true;

  @deprecated
  set enableUriInPartOf(bool enable) {}

  @override
  List<ErrorProcessor> get errorProcessors =>
      _errorProcessors ??= const <ErrorProcessor>[];

  /// Set the list of error [processors] that are to be used when reporting
  /// errors in some analysis context.
  set errorProcessors(List<ErrorProcessor> processors) {
    _errorProcessors = processors;
  }

  @override
  List<String> get excludePatterns => _excludePatterns ??= const <String>[];

  /// Set the exclude patterns used to exclude some sources from analysis to
  /// those in the given list of [patterns].
  set excludePatterns(List<String> patterns) {
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
  set lintRules(List<Linter> rules) {
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
      ApiSignature buffer = ApiSignature();

      // Append environment.
      if (sdkVersionConstraint != null) {
        buffer.addString(sdkVersionConstraint.toString());
      }

      // Append boolean flags.
      // ignore: deprecated_member_use_from_same_package
      buffer.addBool(enableLazyAssignmentOperators);
      buffer.addBool(implicitCasts);
      buffer.addBool(implicitDynamic);
      buffer.addBool(strictInference);
      buffer.addBool(strictRawTypes);
      buffer.addBool(useFastaParser);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
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
      _signature = Uint8List.fromList(bytes).buffer.asUint32List();
    }
    return _signature;
  }

  Uint32List get signatureForElements {
    if (_signatureForElements == null) {
      ApiSignature buffer = ApiSignature();

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      List<int> bytes = buffer.toByteList();
      _signatureForElements = Uint8List.fromList(bytes).buffer.asUint32List();
    }
    return _signatureForElements;
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
      ApiSignature buffer = ApiSignature();

      // Append boolean flags.
      // ignore: deprecated_member_use_from_same_package
      buffer.addBool(enableLazyAssignmentOperators);
      buffer.addBool(useFastaParser);

      // Append the current language version.
      buffer.addInt(ExperimentStatus.currentVersion.major);
      buffer.addInt(ExperimentStatus.currentVersion.minor);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      List<int> bytes = buffer.toByteList();
      _unlinkedSignature = Uint8List.fromList(bytes).buffer.asUint32List();
    }
    return _unlinkedSignature;
  }

  @override
  bool isLintEnabled(String name) {
    return lintRules.any((rule) => rule.name == name);
  }

  @deprecated
  @override
  void resetToDefaults() {
    contextFeatures = ExperimentStatus();
    dart2jsHint = false;
    disableCacheFlushing = false;
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
    trackCacheDependencies = true;
    useFastaParser = true;
  }

  @deprecated
  @override
  void setCrossContextOptionsFrom(AnalysisOptions options) {
    enableLazyAssignmentOperators = options.enableLazyAssignmentOperators;
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
  @deprecated
  static bool _analyzeAllFunctionBodies(Source _) => true;

  /// Predicate used for [analyzeFunctionBodiesPredicate] when
  /// [analyzeFunctionBodies] is set to `false`.
  @deprecated
  static bool _analyzeNoFunctionBodies(Source _) => false;
}

/// Container with global [AnalysisContext] performance statistics.
class PerformanceStatistics {
  /// The [PerformanceTag] for `package:analyzer`.
  static PerformanceTag analyzer = PerformanceTag('analyzer');

  /// The [PerformanceTag] for time spent in reading files.
  static PerformanceTag io = analyzer.createChild('io');

  /// The [PerformanceTag] for general phases of analysis.
  static PerformanceTag analysis = analyzer.createChild('analysis');

  /// The [PerformanceTag] for time spent in scanning.
  static PerformanceTag scan = analyzer.createChild('scan');

  /// The [PerformanceTag] for time spent in parsing.
  static PerformanceTag parse = analyzer.createChild('parse');

  /// The [PerformanceTag] for time spent in resolving.
  static PerformanceTag resolve = PerformanceTag('resolve');

  /// The [PerformanceTag] for time spent in error verifier.
  static PerformanceTag errors = analysis.createChild('errors');

  /// The [PerformanceTag] for time spent in hints generator.
  static PerformanceTag hints = analysis.createChild('hints');

  /// The [PerformanceTag] for time spent in linting.
  static PerformanceTag lints = analysis.createChild('lints');

  /// The [PerformanceTag] for time spent computing cycles.
  static PerformanceTag cycles = PerformanceTag('cycles');

  /// The [PerformanceTag] for time spent in summaries support.
  static PerformanceTag summary = analyzer.createChild('summary');
}
