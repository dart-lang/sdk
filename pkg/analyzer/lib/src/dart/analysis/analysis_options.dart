// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/utilities_general.dart' show toBool;
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

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

  List<AbstractAnalysisRule> lintRules = [];

  bool propagateLinterExceptions = false;

  bool strictCasts = false;

  bool strictInference = false;

  bool strictRawTypes = false;

  bool chromeOsManifestChecks = false;

  CodeStyleOptions codeStyleOptions = CodeStyleOptionsImpl(useFormatter: false);

  FormatterOptions formatterOptions = FormatterOptions();

  Set<String> unignorableDiagnosticCodeNames = {};

  List<PluginConfiguration> pluginConfigurations = [];

  AnalysisOptionsImpl build() {
    return AnalysisOptionsImpl._(
      file: file,
      contextFeatures: contextFeatures,
      nonPackageFeatureSet: nonPackageFeatureSet,
      enabledLegacyPluginNames: enabledLegacyPluginNames,
      pluginConfigurations: pluginConfigurations,
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
      unignorableDiagnosticCodeNames: unignorableDiagnosticCodeNames,
    );
  }

  void _applyCodeStyleOptions(YamlNode? codeStyle) {
    var useFormatter = false;
    if (codeStyle is YamlMap) {
      var formatNode = codeStyle.valueAt(AnalysisOptionsFile.format);
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
    TrailingCommas? trailingCommas;
    if (formatter is YamlMap) {
      var pageWidthNode = formatter.valueAt(AnalysisOptionsFile.pageWidth);
      var pageWidthValue = pageWidthNode?.value;
      if (pageWidthValue is int && pageWidthValue > 0) {
        pageWidth = pageWidthValue;
      }

      var trailingCommasNode = formatter.valueAt(
        AnalysisOptionsFile.trailingCommas,
      );
      var trailingCommasValue = trailingCommasNode?.value;
      trailingCommas = TrailingCommas.values.firstWhereOrNull(
        (item) => item.name == trailingCommasValue,
      );
    }
    formatterOptions = FormatterOptions(
      pageWidth: pageWidth,
      trailingCommas: trailingCommas,
    );
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
        case AnalysisOptionsFile.strictCasts:
          strictCasts = boolValue;
        case AnalysisOptionsFile.strictInference:
          strictInference = boolValue;
        case AnalysisOptionsFile.strictRawTypes:
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
                case AnalysisOptionsFile.chromeOsManifestChecks:
                  chromeOsManifestChecks = boolValue;
                case AnalysisOptionsFile.propagateLinterExceptions:
                  propagateLinterExceptions = boolValue;
              }
            }
          }
        }
      case YamlScalar():
        switch ('${config.value}') {
          case AnalysisOptionsFile.chromeOsManifestChecks:
            chromeOsManifestChecks = true;
          case AnalysisOptionsFile.propagateLinterExceptions:
            propagateLinterExceptions = true;
        }
    }
  }

  void _applyPluginsOptions(
    YamlNode? plugins,
    ResourceProvider? resourceProvider,
  ) {
    if (plugins is! YamlMap) {
      return;
    }

    plugins.nodes.forEach((nameNode, pluginNode) {
      if (nameNode is! YamlScalar) {
        return;
      }
      var pluginName = nameNode.toString();

      // If the plugin name just maps to a String, then that is the version
      // constraint; use it and move on.
      if (pluginNode case YamlScalar(:String value)) {
        pluginConfigurations.add(
          PluginConfiguration(
            name: pluginName,
            source: VersionedPluginSource(constraint: value),
          ),
        );
        return;
      }

      if (pluginNode is! YamlMap) {
        return;
      }

      // Grab either the source value from 'version', 'git', or 'path'. In the
      // erroneous case that multiple are specified, just take the first. A
      // warning should be reported by `OptionsFileValidator`.
      // TODO(srawlins): In adition to 'version' and 'path', try 'git'.

      PluginSource? source;
      var versionSource = pluginNode.valueAt(AnalysisOptionsFile.version);
      if (versionSource case YamlScalar(:String value)) {
        // TODO(srawlins): Handle the 'hosted' key.
        source = VersionedPluginSource(constraint: value);
      } else {
        var pathSource = pluginNode.valueAt(AnalysisOptionsFile.path);
        if (pathSource case YamlScalar(value: String pathValue)) {
          var file = this.file;
          assert(
            file != null,
            "AnalysisOptionsImpl must be initialized with a non-null 'file' if "
            'plugins are specified with path constraints.',
          );
          if (file != null &&
              resourceProvider != null &&
              resourceProvider.pathContext.isRelative(pathValue)) {
            // We need to store the absolute path, before this value is used in
            // a synthetic pub package.
            pathValue = resourceProvider.pathContext.join(
              file.parent.path,
              pathValue,
            );
            pathValue = resourceProvider.pathContext.normalize(pathValue);
          }
          source = PathPluginSource(path: pathValue);
        }
      }

      if (source == null) {
        // Either the source data is malformed, or neither 'version' nor 'git'
        // was provided. A warning should be reported by OptionsFileValidator.
        return;
      }

      var diagnostics = pluginNode.valueAt(AnalysisOptionsFile.diagnostics);
      var diagnosticConfigurations =
          diagnostics == null
              ? const <String, RuleConfig>{}
              : parseDiagnosticsSection(diagnostics);

      pluginConfigurations.add(
        PluginConfiguration(
          name: pluginName,
          source: source,
          diagnosticConfigs: diagnosticConfigurations,
          // TODO(srawlins): Implement `enabled: false`.
        ),
      );
    });
  }

  void _applyUnignorables(YamlNode? cannotIgnore) {
    if (cannotIgnore is! YamlList) {
      return;
    }
    var stringValues = cannotIgnore.whereType<String>().toSet();
    for (var severity in AnalysisOptionsFile.severities) {
      if (stringValues.contains(severity)) {
        // [severity] is a marker denoting all diagnostic codes with severity
        // equal to [severity].
        stringValues.remove(severity);
        // Replace name like 'error' with diagnostic codes with this named
        // severity.
        for (var d in diagnosticCodeValues) {
          // If the severity of [error] is also changed in this options file
          // to be [severity], we add [error] to the un-ignorable list.
          var processors = errorProcessors.where(
            (processor) => processor.code == d.name,
          );
          if (processors.isNotEmpty &&
              processors.first.severity?.displayName == severity) {
            unignorableDiagnosticCodeNames.add(d.name);
            continue;
          }
          // Otherwise, add [error] if its default severity is [severity].
          if (d.severity.displayName == severity) {
            unignorableDiagnosticCodeNames.add(d.name);
          }
        }
      }
    }
    unignorableDiagnosticCodeNames.addAll(
      stringValues.map((name) => name.toUpperCase()),
    );
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

  /// The constraint on the language version for every Dart file.
  /// Violations will be reported as analysis errors.
  final VersionConstraint? sourceLanguageConstraint = VersionConstraint.parse(
    '>= 2.12.0',
  );

  ExperimentStatus _contextFeatures;

  /// The set of features to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this feature set is *not* used, even if the
  /// package does not specify the language version. Instead [contextFeatures]
  /// is used.
  FeatureSet nonPackageFeatureSet = ExperimentStatus();

  @override
  final List<String> enabledLegacyPluginNames;

  @override
  final List<PluginConfiguration> pluginConfigurations;

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
  List<AbstractAnalysisRule> lintRules = [];

  /// Whether linter exceptions should be propagated to the caller (by
  /// rethrowing them).
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

  /// The set of "un-ignorable" diagnostic names, as parsed from an analysis
  /// options file.
  final Set<String> unignorableDiagnosticCodeNames;

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
  factory AnalysisOptionsImpl.fromYaml({
    required YamlMap optionsMap,
    File? file,
    ResourceProvider? resourceProvider,
  }) {
    var builder = AnalysisOptionsBuilder()..file = file;

    var analyzer = optionsMap.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzer is YamlMap) {
      // Process filters.
      var filters = analyzer.valueAt(AnalysisOptionsFile.errors);
      builder.errorProcessors = ErrorConfig(filters).processors;

      // Process enabled experiments.
      var experimentNames = analyzer.valueAt(
        AnalysisOptionsFile.enableExperiment,
      );
      if (experimentNames is YamlList) {
        var enabledExperiments = <String>[];
        for (var element in experimentNames.nodes) {
          var experimentName = element.stringValue;
          if (experimentName != null) {
            enabledExperiments.add(experimentName);
          }
        }
        builder.contextFeatures =
            FeatureSet.fromEnableFlags2(
                  sdkLanguageVersion: ExperimentStatus.currentVersion,
                  flags: enabledExperiments,
                )
                as ExperimentStatus;
        builder.nonPackageFeatureSet = builder.contextFeatures;
      }

      // Process optional checks options.
      var optionalChecks = analyzer.valueAt(AnalysisOptionsFile.optionalChecks);
      builder._applyOptionalChecks(optionalChecks);

      // Process language options.
      var language = analyzer.valueAt(AnalysisOptionsFile.language);
      builder._applyLanguageOptions(language);

      // Process excludes.
      var excludes = analyzer.valueAt(AnalysisOptionsFile.exclude);
      builder._applyExcludes(excludes);

      var cannotIgnore = analyzer.valueAt(AnalysisOptionsFile.cannotIgnore);
      builder._applyUnignorables(cannotIgnore);

      // Process legacy plugins.
      var legacyPlugins = analyzer.valueAt(AnalysisOptionsFile.plugins);
      builder._applyLegacyPlugins(legacyPlugins);
    }

    // Process the 'formatter' option.
    var formatter = optionsMap.valueAt(AnalysisOptionsFile.formatter);
    builder._applyFormatterOptions(formatter);

    // Process the 'plugins' option.
    var plugins = optionsMap.valueAt(AnalysisOptionsFile.plugins);
    builder._applyPluginsOptions(plugins, resourceProvider);

    var ruleConfigs = parseLinterSection(optionsMap);
    if (ruleConfigs != null) {
      var enabledRules = Registry.ruleRegistry.enabled(ruleConfigs);
      if (enabledRules.isNotEmpty) {
        builder.lint = true;
        builder.lintRules = enabledRules.toList();
      }
    }

    // Process the 'code-style' option.
    var codeStyle = optionsMap.valueAt(AnalysisOptionsFile.codeStyle);
    builder._applyCodeStyleOptions(codeStyle);

    return builder.build();
  }

  AnalysisOptionsImpl._({
    required this.file,
    required ExperimentStatus contextFeatures,
    required this.nonPackageFeatureSet,
    required this.excludePatterns,
    required this.enabledLegacyPluginNames,
    required this.pluginConfigurations,
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
    required this.unignorableDiagnosticCodeNames,
  }) : _contextFeatures = contextFeatures {
    (codeStyleOptions as CodeStyleOptionsImpl).options = this;
  }

  @override
  FeatureSet get contextFeatures => _contextFeatures;

  set contextFeatures(FeatureSet featureSet) {
    _contextFeatures = featureSet as ExperimentStatus;
    nonPackageFeatureSet = featureSet;
  }

  /// The language version to use for libraries that are not in a package.
  ///
  /// If a library is in a package, this language version is *not* used,
  /// even if the package does not specify the language version.
  Version get nonPackageLanguageVersion => ExperimentStatus.currentVersion;

  Uint32List get signature {
    if (_signature == null) {
      ApiSignature buffer = ApiSignature();

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
      for (ErrorProcessor processor in errorProcessors.sortedBy(
        (processor) => processor.description,
      )) {
        buffer.addString(processor.description);
      }

      // Append lints.
      buffer.addInt(lintRules.length);
      for (var lintRule in lintRules.sortedBy((lintRule) => lintRule.name)) {
        buffer.addString(lintRule.name);
      }

      // Append legacy plugin names.
      buffer.addInt(enabledLegacyPluginNames.length);
      for (var enabledLegacyPluginName in enabledLegacyPluginNames.sorted()) {
        buffer.addString(enabledLegacyPluginName);
      }

      // Append plugin configurations.
      buffer.addInt(pluginConfigurations.length);
      for (var pluginConfiguration in pluginConfigurations.sortedBy(
        (pluginConfiguration) => pluginConfiguration.name,
      )) {
        buffer.addString(pluginConfiguration.name);
        buffer.addBool(pluginConfiguration.isEnabled);
        buffer.addInt(pluginConfiguration.diagnosticConfigs.length);
        for (var diagnosticConfig
            in pluginConfiguration.diagnosticConfigs.values) {
          buffer.addString(diagnosticConfig.group ?? '');
          buffer.addString(diagnosticConfig.name);
          buffer.addBool(diagnosticConfig.isEnabled);
        }
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
