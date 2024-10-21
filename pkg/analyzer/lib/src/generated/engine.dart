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
import 'package:analyzer/src/generated/utilities_general.dart' show toBool;
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

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

/// A builder for [AnalysisOptionsImpl].
///
/// To be used when an [AnalysisOptionsImpl] needs to be constructed, but with
/// individually set options, rather than being built from YAML.
final class AnalysisOptionsBuilder {
  File? file;

  ExperimentStatus contextFeatures = ExperimentStatus();

  FeatureSet nonPackageFeatureSet = ExperimentStatus();

  List<String> enabledLegacyPluginNames = const [];

  List<ErrorProcessor> errorProcessors = [];

  List<String> excludePatterns = [];

  bool lint = false;

  List<LintRule> lintRules = [];

  bool propagateLinterExceptions = false;

  bool strictCasts = false;

  bool strictInference = false;

  bool strictRawTypes = false;

  bool chromeOsManifestChecks = false;

  CodeStyleOptions codeStyleOptions = CodeStyleOptionsImpl(useFormatter: false);

  FormatterOptions formatterOptions = FormatterOptions();

  Set<String> unignorableNames = {};

  AnalysisOptionsImpl build() {
    return AnalysisOptionsImpl._(
      file: file,
      contextFeatures: contextFeatures,
      nonPackageFeatureSet: nonPackageFeatureSet,
      enabledLegacyPluginNames: enabledLegacyPluginNames,
      errorProcessors: errorProcessors,
      excludePatterns: excludePatterns,
      lint: lint,
      lintRules: lintRules,
      propagateLinterExceptions: propagateLinterExceptions,
      strictCasts: strictCasts,
      strictInference: strictInference,
      strictRawTypes: strictRawTypes,
      chromeOsManifestChecks: chromeOsManifestChecks,
      codeStyleOptions: codeStyleOptions,
      formatterOptions: formatterOptions,
      unignorableNames: unignorableNames,
    );
  }

  void _applyCodeStyleOptions(YamlNode? codeStyle) {
    var useFormatter = false;
    if (codeStyle is YamlMap) {
      var formatNode = codeStyle.valueAt(AnalyzerOptions.format);
      if (formatNode != null) {
        var formatValue = toBool(formatNode);
        if (formatValue is bool) {
          useFormatter = formatValue;
        }
      }
    }
    codeStyleOptions = CodeStyleOptionsImpl(useFormatter: useFormatter);
  }

  void _applyExcludes(YamlNode? excludes) {
    if (excludes is YamlList) {
      // TODO(srawlins): Report non-String items.
      excludePatterns.addAll(excludes.whereType<String>());
    }
    // TODO(srawlins): Report non-List with
    // AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT.
  }

  void _applyFormatterOptions(YamlNode? formatter) {
    int? pageWidth;
    if (formatter is YamlMap) {
      var formatNode = formatter.valueAt(AnalyzerOptions.pageWidth);
      var formatValue = formatNode?.value;
      if (formatValue is int && formatValue > 0) {
        pageWidth = formatValue;
      }
    }
    formatterOptions = FormatterOptions(pageWidth: pageWidth);
  }

  void _applyLanguageOptions(YamlNode? configs) {
    if (configs is! YamlMap) {
      return;
    }

    configs.nodes.forEach((key, value) {
      if (key is! YamlScalar || value is! YamlScalar) {
        return;
      }
      var feature = key.value?.toString();
      var boolValue = value.boolValue;
      if (boolValue == null) {
        return;
      }

      switch (feature) {
        case AnalyzerOptions.strictCasts:
          strictCasts = boolValue;
        case AnalyzerOptions.strictInference:
          strictInference = boolValue;
        case AnalyzerOptions.strictRawTypes:
          strictRawTypes = boolValue;
      }
    });
  }

  void _applyLegacyPlugins(YamlNode? plugins) {
    var pluginName = plugins.stringValue;
    if (pluginName != null) {
      enabledLegacyPluginNames = [pluginName];
    } else if (plugins is YamlList) {
      for (var element in plugins.nodes) {
        var pluginName = element.stringValue;
        if (pluginName != null) {
          // Only the first legacy plugin is supported.
          enabledLegacyPluginNames = [pluginName];
          return;
        }
      }
    } else if (plugins is YamlMap) {
      for (var key in plugins.nodes.keys.cast<YamlNode?>()) {
        var pluginName = key.stringValue;
        if (pluginName != null) {
          // Only the first legacy plugin is supported.
          enabledLegacyPluginNames = [pluginName];
          return;
        }
      }
    }
  }

  void _applyOptionalChecks(YamlNode? config) {
    switch (config) {
      case YamlMap():
        for (var MapEntry(:key, :value) in config.nodes.entries) {
          if (key is YamlScalar && value is YamlScalar) {
            if (value.boolValue case var boolValue?) {
              switch ('${key.value}') {
                case AnalyzerOptions.chromeOsManifestChecks:
                  chromeOsManifestChecks = boolValue;
                case AnalyzerOptions.propagateLinterExceptions:
                  propagateLinterExceptions = boolValue;
              }
            }
          }
        }
      case YamlScalar():
        switch ('${config.value}') {
          case AnalyzerOptions.chromeOsManifestChecks:
            chromeOsManifestChecks = true;
          case AnalyzerOptions.propagateLinterExceptions:
            propagateLinterExceptions = true;
        }
    }
  }

  void _applyUnignorables(YamlNode? cannotIgnore) {
    if (cannotIgnore is! YamlList) {
      return;
    }
    var stringValues = cannotIgnore.whereType<String>().toSet();
    for (var severity in AnalyzerOptions.severities) {
      if (stringValues.contains(severity)) {
        // [severity] is a marker denoting all error codes with severity
        // equal to [severity].
        stringValues.remove(severity);
        // Replace name like 'error' with error codes with this named
        // severity.
        for (var e in errorCodeValues) {
          // If the severity of [error] is also changed in this options file
          // to be [severity], we add [error] to the un-ignorable list.
          var processors =
              errorProcessors.where((processor) => processor.code == e.name);
          if (processors.isNotEmpty &&
              processors.first.severity?.displayName == severity) {
            unignorableNames.add(e.name);
            continue;
          }
          // Otherwise, add [error] if its default severity is [severity].
          if (e.errorSeverity.displayName == severity) {
            unignorableNames.add(e.name);
          }
        }
      }
    }
    unignorableNames.addAll(stringValues.map((name) => name.toUpperCase()));
  }
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
  List<String> enabledLegacyPluginNames;

  /// Return `true` if timing data should be gathered during execution.
  bool enableTiming = false;

  @override
  final List<ErrorProcessor> errorProcessors;

  @override
  final List<String> excludePatterns;

  /// The associated `analysis_options.yaml` file (or `null` if there is none).
  final File? file;

  @override
  bool lint = false;

  @override
  bool warning = true;

  @override
  List<LintRule> lintRules = [];

  /// Indicates whether linter exceptions should be propagated to the caller (by
  /// re-throwing them).
  bool propagateLinterExceptions;

  @override
  final bool strictCasts;

  @override
  final bool strictInference;

  @override
  final bool strictRawTypes;

  @override
  final bool chromeOsManifestChecks;

  @override
  final CodeStyleOptions codeStyleOptions;

  @override
  final FormatterOptions formatterOptions;

  /// The set of "un-ignorable" error names, as parsed from an analysis options
  /// file.
  // TODO(srawlins): Rename to `unignorableCodes`. 'Names' is ambiguous.
  final Set<String> unignorableNames;

  /// Returns a newly instantiated [AnalysisOptionsImpl].
  ///
  /// Optionally pass [file] as the file where the YAML can be found.
  factory AnalysisOptionsImpl({File? file}) {
    var builder = AnalysisOptionsBuilder()..file = file;
    return builder.build();
  }

  /// Returns a newly instantiated [AnalysisOptionsImpl], as parsed from
  /// [optionsMap].
  ///
  /// Optionally pass [file] as the file where the YAML can be found.
  factory AnalysisOptionsImpl.fromYaml(
      {required YamlMap optionsMap, File? file}) {
    var builder = AnalysisOptionsBuilder()..file = file;

    var analyzer = optionsMap.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      // Process filters.
      var filters = analyzer.valueAt(AnalyzerOptions.errors);
      builder.errorProcessors = ErrorConfig(filters).processors;

      // Process enabled experiments.
      var experimentNames = analyzer.valueAt(AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        var enabledExperiments = <String>[];
        for (var element in experimentNames.nodes) {
          var experimentName = element.stringValue;
          if (experimentName != null) {
            enabledExperiments.add(experimentName);
          }
        }
        builder.contextFeatures = FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: ExperimentStatus.currentVersion,
          flags: enabledExperiments,
        ) as ExperimentStatus;
        builder.nonPackageFeatureSet = builder.contextFeatures;
      }

      // Process optional checks options.
      var optionalChecks = analyzer.valueAt(AnalyzerOptions.optionalChecks);
      builder._applyOptionalChecks(optionalChecks);

      // Process language options.
      var language = analyzer.valueAt(AnalyzerOptions.language);
      builder._applyLanguageOptions(language);

      // Process excludes.
      var excludes = analyzer.valueAt(AnalyzerOptions.exclude);
      builder._applyExcludes(excludes);

      var cannotIgnore = analyzer.valueAt(AnalyzerOptions.cannotIgnore);
      builder._applyUnignorables(cannotIgnore);

      // Process legacy plugins.
      var legacyPlugins = analyzer.valueAt(AnalyzerOptions.plugins);
      builder._applyLegacyPlugins(legacyPlugins);
    }

    // Process the 'formatter' option.
    var formatter = optionsMap.valueAt(AnalyzerOptions.formatter);
    builder._applyFormatterOptions(formatter);

    var lintConfig = parseLintConfig(optionsMap);
    if (lintConfig != null) {
      var enabledRules = Registry.ruleRegistry.enabled(lintConfig);
      if (enabledRules.isNotEmpty) {
        builder.lint = true;
        builder.lintRules = enabledRules.toList();
      }
    }

    // Process the 'code-style' option.
    var codeStyle = optionsMap.valueAt(AnalyzerOptions.codeStyle);
    builder._applyCodeStyleOptions(codeStyle);

    return builder.build();
  }

  AnalysisOptionsImpl._({
    required this.file,
    required ExperimentStatus contextFeatures,
    required this.nonPackageFeatureSet,
    required this.excludePatterns,
    required this.enabledLegacyPluginNames,
    required this.errorProcessors,
    required this.lint,
    required this.lintRules,
    required this.propagateLinterExceptions,
    required this.strictCasts,
    required this.strictInference,
    required this.strictRawTypes,
    required this.chromeOsManifestChecks,
    required this.codeStyleOptions,
    required this.formatterOptions,
    required this.unignorableNames,
  }) : _contextFeatures = contextFeatures {
    (codeStyleOptions as CodeStyleOptionsImpl).options = this;
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

  /// The opaque signature of the options that affect unlinked data.
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

extension on YamlNode? {
  bool? get boolValue {
    var self = this;
    if (self is YamlScalar) {
      var value = self.value;
      if (value is bool) {
        return value;
      }
    }
    return null;
  }

  String? get stringValue {
    var self = this;
    if (self is YamlScalar) {
      var value = self.value;
      if (value is String) {
        return value;
      }
    }
    return null;
  }
}
