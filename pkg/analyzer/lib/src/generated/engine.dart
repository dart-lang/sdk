// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/dart/analysis/analysis_options.dart';
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
/// removed from the context, which is also used to notify the context when
/// sources have been modified and, consequently, previously known results might
/// have been invalidated.
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
/// consequent changes to the analysis results.
///
/// Analysis engine allows for having more than one context. This can be used,
/// for example, to perform one analysis based on the state of files on disk and
/// a separate analysis based on the state of those files in open editors. It can
/// also be used to perform an analysis based on a proposed future state, such as
/// the state after a refactoring.
abstract class AnalysisContext {
  /// Return the set of analysis options controlling the behavior of this
  /// context. Clients should not modify the returned set of options.
  @Deprecated("Use 'getAnalysisOptionsForFile(file)' instead")
  AnalysisOptions get analysisOptions;

  /// Return the set of declared variables used when computing constant values.
  DeclaredVariables get declaredVariables;

  /// Return the source factory used to create the sources that can be analyzed
  /// in this context.
  SourceFactory get sourceFactory;

  /// Get the [AnalysisOptions] instance for the given [file].
  ///
  /// NOTE: this API is experimental and subject to change in a future
  /// release (see https://github.com/dart-lang/sdk/issues/53876 for context).
  @experimental
  AnalysisOptions getAnalysisOptionsForFile(File file);
}

/// The entry point for the functionality provided by the analysis engine. There
/// is a single instance of this class.
class AnalysisEngine {
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
  set instrumentationService(InstrumentationService? service) {
    if (service == null) {
      _instrumentationService = InstrumentationService.NULL_SERVICE;
    } else {
      _instrumentationService = service;
    }
  }

  /// Clear any caches holding on to analysis results so that a full re-analysis
  /// will be performed the next time an analysis context is created.
  void clearCaches() {
    // Ensure the string canonicalization cache size is reasonable.
    pruneStringCanonicalizationCache();
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
class AnalysisOptionsImpl implements AnalysisOptions {
  /// The cached [unlinkedSignature].
  Uint32List? _unlinkedSignature;

  /// The cached [signature].
  Uint32List? _signature;

  /// The cached [signatureForElements].
  Uint32List? _signatureForElements;

  @override
  @Deprecated('Use `PubWorkspacePackage.sdkVersionConstraint` instead')
  VersionConstraint? sdkVersionConstraint;

  /// The constraint on the language version for every Dart file.
  /// Violations will be reported as analysis errors.
  final VersionConstraint? sourceLanguageConstraint =
      VersionConstraint.parse('>= 2.12.0');

  ExperimentStatus _contextFeatures = ExperimentStatus();

  /// The language version to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this language version is *not* used,
  /// even if the package does not specify the language version.
  Version nonPackageLanguageVersion = ExperimentStatus.currentVersion;

  /// The set of features to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this feature set is *not* used, even if the
  /// package does not specify the language version. Instead [contextFeatures]
  /// is used.
  FeatureSet nonPackageFeatureSet = ExperimentStatus();

  @override
  List<String> enabledLegacyPluginNames = const <String>[];

  /// Return `true` if timing data should be gathered during execution.
  bool enableTiming = false;

  @override
  List<ErrorProcessor> errorProcessors = [];

  @override
  List<String> excludePatterns = [];

  /// The associated `analysis_options.yaml` file (or `null` if there is none).
  File? file;

  @override
  bool lint = false;

  @override
  bool warning = true;

  @override
  List<LintRule> lintRules = [];

  /// Indicates whether linter exceptions should be propagated to the caller (by
  /// re-throwing them).
  bool propagateLinterExceptions = false;

  /// Whether implicit casts should be reported as potential problems.
  bool strictCasts = false;

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

  @override
  late CodeStyleOptions codeStyleOptions;

  @override
  FormatterOptions formatterOptions = FormatterOptions();

  /// The set of "un-ignorable" error names, as parsed from an analysis options
  /// file.
  Set<String> unignorableNames = {};

  /// Initialize a newly created set of analysis options to have their default
  /// values.
  AnalysisOptionsImpl({this.file}) {
    codeStyleOptions = CodeStyleOptionsImpl(this, useFormatter: false);
  }

  /// Initialize a newly created set of analysis options to have the same values
  /// as those in the given set of analysis [options].
  AnalysisOptionsImpl.from(AnalysisOptions options) {
    codeStyleOptions = options.codeStyleOptions;
    formatterOptions = options.formatterOptions;
    contextFeatures = options.contextFeatures;
    enabledLegacyPluginNames = options.enabledLegacyPluginNames;
    errorProcessors = options.errorProcessors;
    excludePatterns = options.excludePatterns;
    lint = options.lint;
    warning = options.warning;
    lintRules = options.lintRules;
    if (options is AnalysisOptionsImpl) {
      file = options.file;
      enableTiming = options.enableTiming;
      propagateLinterExceptions = options.propagateLinterExceptions;
      strictInference = options.strictInference;
      strictRawTypes = options.strictRawTypes;
    }
    // ignore: deprecated_member_use_from_same_package
    sdkVersionConstraint = options.sdkVersionConstraint;
  }

  @override
  FeatureSet get contextFeatures => _contextFeatures;

  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet as ExperimentStatus;
    nonPackageFeatureSet = featureSet;
  }

  @override
  @Deprecated("Use 'enabledLegacyPluginNames' instead")
  List<String> get enabledPluginNames => enabledLegacyPluginNames;

  /// The set of enabled experiments.
  ExperimentStatus get experimentStatus => _contextFeatures;

  @override
  bool get hint => warning;

  /// The implementation-specific setter for [hint].
  @Deprecated("Use 'warning=' instead")
  set hint(bool value) => warning = value;

  Uint32List get signature {
    if (_signature == null) {
      ApiSignature buffer = ApiSignature();

      // Append environment.
      // TODO(pq): remove
      // ignore: deprecated_member_use_from_same_package
      if (sdkVersionConstraint != null) {
        // ignore: deprecated_member_use_from_same_package
        buffer.addString(sdkVersionConstraint.toString());
      }

      // Append boolean flags.
      buffer.addBool(propagateLinterExceptions);
      buffer.addBool(strictCasts);
      buffer.addBool(strictInference);
      buffer.addBool(strictRawTypes);

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
      buffer.addInt(lintRules.length);
      for (var lintRule in lintRules) {
        buffer.addString(lintRule.name);
      }

      // Append legacy plugin names.
      buffer.addInt(enabledLegacyPluginNames.length);
      for (var enabledLegacyPluginName in enabledLegacyPluginNames) {
        buffer.addString(enabledLegacyPluginName);
      }

      // Hash and convert to Uint32List.
      _signature = buffer.toUint32List();
    }
    return _signature!;
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
      _signatureForElements = buffer.toUint32List();
    }
    return _signatureForElements!;
  }

  /// Return the opaque signature of the options that affect unlinked data.
  ///
  /// The length of the list is guaranteed to equal [unlinkedSignatureLength].
  Uint32List get unlinkedSignature {
    if (_unlinkedSignature == null) {
      ApiSignature buffer = ApiSignature();

      // Append the current language version.
      buffer.addInt(ExperimentStatus.currentVersion.major);
      buffer.addInt(ExperimentStatus.currentVersion.minor);

      // Append features.
      buffer.addInt(ExperimentStatus.knownFeatures.length);
      for (var feature in ExperimentStatus.knownFeatures.values) {
        buffer.addBool(contextFeatures.isEnabled(feature));
      }

      // Hash and convert to Uint32List.
      return buffer.toUint32List();
    }
    return _unlinkedSignature!;
  }

  @override
  bool isLintEnabled(String name) {
    return lintRules.any((rule) => rule.name == name);
  }
}
