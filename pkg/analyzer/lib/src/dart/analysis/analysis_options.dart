// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/code_style_options.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/utilities_general.dart' show toBool;
import 'package:analyzer/src/lint/config.dart';
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

  PluginsOptions pluginsOptions = PluginsOptions(
    configurations: const [],
    dependencyOverrides: null,
  );

  String? pluginDependencyOverrides;

  AnalysisOptionsImpl build() {
    return AnalysisOptionsImpl._(
      file: file,
      contextFeatures: contextFeatures,
      nonPackageFeatureSet: nonPackageFeatureSet,
      enabledLegacyPluginNames: enabledLegacyPluginNames,
      pluginsOptions: pluginsOptions,
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

    var configurations = <PluginConfiguration>[];
    Map<String, PluginSource>? dependencyOverrides;

    plugins.nodes.forEach((nameNode, pluginNode) {
      if (nameNode is! YamlScalar) {
        return;
      }

      var pluginName = nameNode.toString();
      if (pluginName == 'dependency_overrides') {
        // This is a magic key; not the name of a plugin.
        if (pluginNode is! YamlMap) return;
        pluginNode.nodes.forEach((nameNode, dependencyOverride) {
          if (nameNode is! YamlScalar) {
            return;
          }
          var source = _getSource(dependencyOverride, resourceProvider);
          if (source == null) return;
          (dependencyOverrides ??= {})[nameNode.toString()] = source;
        });

        return;
      }

      var source = _getSource(pluginNode, resourceProvider);
      if (source == null) return;

      if (pluginNode is! YamlMap) {
        configurations.add(
          PluginConfiguration(name: pluginName, source: source),
        );
        return;
      }

      var diagnostics = pluginNode.valueAt(AnalysisOptionsFile.diagnostics);
      var diagnosticConfigurations = diagnostics == null
          ? const <String, RuleConfig>{}
          : parseDiagnosticsSection(diagnostics);

      configurations.add(
        PluginConfiguration(
          name: pluginName,
          source: source,
          diagnosticConfigs: diagnosticConfigurations,
          // TODO(srawlins): Implement `enabled: false`.
        ),
      );
    });

    pluginsOptions = PluginsOptions(
      configurations: configurations,
      dependencyOverrides: dependencyOverrides,
    );
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

  PluginSource? _getSource(
    YamlNode pluginNode,
    ResourceProvider? resourceProvider,
  ) {
    // If it just maps to a String, then that is the version constraint.
    if (pluginNode case YamlScalar(:String value)) {
      return VersionedPluginSource(constraint: value);
    }

    if (pluginNode is! YamlMap) {
      return null;
    }

    // Grab either the source value from 'version', 'git', or 'path'. In the
    // erroneous case that multiple are specified, just take the first. A
    // warning should be reported by `OptionsFileValidator`.
    // TODO(srawlins): In adition to 'version' and 'path', try 'git'.

    var versionSource = pluginNode.valueAt(AnalysisOptionsFile.version);
    if (versionSource case YamlScalar(:String value)) {
      // TODO(srawlins): Handle the 'hosted' key.
      return VersionedPluginSource(constraint: value);
    }
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
      return PathPluginSource(path: pathValue);
    }
    return null;
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

  /// The options used to specify plugins.
  final PluginsOptions pluginsOptions;

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
    required this.pluginsOptions,
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

  @override
  List<PluginConfiguration> get pluginConfigurations =>
      pluginsOptions.configurations;

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
        switch (pluginConfiguration.source) {
          case GitPluginSource source:
            buffer.addString(source._url);
            if (source._path case var path?) {
              buffer.addString(path);
            }
            if (source._ref case var ref?) {
              buffer.addString(ref);
            }
          case PathPluginSource source:
            buffer.addString(source._path);
          case VersionedPluginSource source:
            buffer.addString(source._constraint);
        }
        buffer.addInt(pluginConfiguration.diagnosticConfigs.length);
        for (var diagnosticConfig
            in pluginConfiguration.diagnosticConfigs.values) {
          buffer.addString(diagnosticConfig.group ?? '');
          buffer.addString(diagnosticConfig.name);
          buffer.addInt(diagnosticConfig.severity.index);
        }
        if (pluginsOptions.dependencyOverrides case var dependencyOverrides?) {
          for (var pluginDependencyOverrideEntry
              in dependencyOverrides.entries.sortedBy((entry) => entry.key)) {
            buffer.addString(pluginDependencyOverrideEntry.key);
            switch (pluginDependencyOverrideEntry.value) {
              case GitPluginSource source:
                buffer.addString(source._url);
                if (source._path case var path?) {
                  buffer.addString(path);
                }
                if (source._ref case var ref?) {
                  buffer.addString(ref);
                }
              case PathPluginSource source:
                buffer.addString(source._path);
              case VersionedPluginSource source:
                buffer.addString(source._constraint);
            }
          }
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

@AnalyzerPublicApi(
  message: 'exported by lib/dart/analysis/analysis_options.dart',
)
final class GitPluginSource implements PluginSource {
  final String _url;

  final String? _path;

  final String? _ref;

  GitPluginSource({required String url, String? path, String? ref})
    : _url = url,
      _path = path,
      _ref = ref;

  @override
  String toYaml({required String name}) {
    var buffer = StringBuffer()
      ..writeln('  $name:')
      ..writeln('    git:')
      ..writeln('      url: $_url');
    if (_ref != null) {
      buffer.writeln('      ref: $_ref');
    }
    if (_path != null) {
      buffer.writeln('      path: $_path');
    }
    return buffer.toString();
  }
}

@AnalyzerPublicApi(
  message: 'exported by lib/dart/analysis/analysis_options.dart',
)
final class PathPluginSource implements PluginSource {
  final String _path;

  PathPluginSource({required String path}) : _path = path;

  @override
  String toYaml({required String name}) =>
      '''
  $name:
    path: $_path
''';
}

/// The configuration of a Dart Analysis Server plugin, as specified by
/// analysis options.
@AnalyzerPublicApi(
  message: 'exported by lib/dart/analysis/analysis_options.dart',
)
final class PluginConfiguration {
  /// The name of the plugin being configured.
  final String name;

  /// The source of the plugin being configured.
  final PluginSource source;

  /// The list of specified [DiagnosticConfig]s.
  // ignore: analyzer_public_api_bad_type
  final Map<String, DiagnosticConfig> diagnosticConfigs;

  /// Whether the plugin is enabled.
  final bool isEnabled;

  // ignore: analyzer_public_api_bad_type
  PluginConfiguration({
    required this.name,
    required this.source,
    this.diagnosticConfigs = const {},
    this.isEnabled = true,
  });

  String sourceYaml() => source.toYaml(name: name);
}

/// The analysis options for plugins, as specified in the top-level `plugins`
/// section.
final class PluginsOptions {
  /// The list of each listed plugin's configuration.
  final List<PluginConfiguration> configurations;

  /// The dependency overrides, if specified.
  final Map<String, PluginSource>? dependencyOverrides;

  PluginsOptions({
    required this.configurations,
    required this.dependencyOverrides,
  });
}

/// A description of the source of a plugin.
///
/// We support all of the source formats documented at
/// https://dart.dev/tools/pub/dependencies.
@AnalyzerPublicApi(
  message: 'exported by lib/dart/analysis/analysis_options.dart',
)
sealed class PluginSource {
  /// Returns the YAML-formatted source, using [name] as a key, for writing into
  /// a pubspec 'dependencies' section.
  String toYaml({required String name});
}

/// A plugin source using a version constraint, hosted either at pub.dev or
/// another host.
// TODO(srawlins): Support a different 'hosted' URL.
@AnalyzerPublicApi(
  message: 'exported by lib/dart/analysis/analysis_options.dart',
)
final class VersionedPluginSource implements PluginSource {
  /// The specified version constraint.
  final String _constraint;

  VersionedPluginSource({required String constraint})
    : _constraint = constraint;

  @override
  String toYaml({required String name}) => '  $name: $_constraint\n';
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
