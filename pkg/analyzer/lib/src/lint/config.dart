// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// Returns the [RuleConfig]s that are parsed from [value], which can be either
/// a YAML list or a YAML map, mapped from each rule's name.
Map<String, RuleConfig> parseDiagnosticsSection(YamlNode value) {
  // For example:
  //
  // ```yaml
  // - unnecessary_getters
  // - camel_case_types
  // ```
  if (value is YamlList) {
    return {
      for (var ruleNode in value.nodes)
        if (ruleNode case YamlScalar(value: String ruleName))
          ruleName: RuleConfig._(
            name: ruleName,
            severity: ConfiguredSeverity.enable,
          ),
    };
  }

  if (value is! YamlMap) {
    return const {};
  }

  var ruleConfigs = <String, RuleConfig>{};
  value.nodes.forEach((configKey, configValue) {
    if (configKey case YamlScalar(value: String configName)) {
      var ruleConfig = _parseRuleConfig(configKey, configValue);
      if (ruleConfig != null) {
        ruleConfigs[ruleConfig.name] = ruleConfig;
        return;
      }

      if (configValue is! YamlMap) {
        return;
      }

      // Try to interpret the entries as sub-rules (the "group" pattern).
      // Only use the group interpretation if ALL entries parse as sub-rules.
      var groupConfigs = <String, RuleConfig>{};
      var allEntriesAreRules = true;
      for (var MapEntry(:key, :value) in configValue.nodes.entries) {
        var ruleConfig = _parseRuleConfig(key, value, group: configName);
        if (ruleConfig != null) {
          groupConfigs[ruleConfig.name] = ruleConfig;
        } else {
          allEntriesAreRules = false;
          break;
        }
      }

      if (allEntriesAreRules && groupConfigs.isNotEmpty) {
        ruleConfigs.addAll(groupConfigs);
        return;
      }

      // Otherwise, treat the map as rule-specific options.
      ruleConfigs[configName] = _parseRuleOptions(configName, configValue);
    }
  });
  return ruleConfigs;
}

/// Parses [optionsMap] into [RuleConfig]s mapped from their names, returning
/// them, or `null` if [optionsMap] does not have `linter` map.
Map<String, RuleConfig>? parseLinterSection(YamlMap optionsMap) {
  var options = optionsMap.valueAt('linter');
  // Quick check of basic contract.
  if (options is YamlMap) {
    var rulesNode = options.valueAt(AnalysisOptionsFile.rules);
    return {
      if (rulesNode != null)
        for (var entry in parseDiagnosticsSection(rulesNode).entries)
          entry.key.toLowerCase(): entry.value,
    };
  }

  return null;
}

RuleConfig? _parseRuleConfig(
  dynamic configKey,
  YamlNode configNode, {
  String? group,
}) {
  // For example: `{unnecessary_getters: false}`.
  if (configKey case YamlScalar(value: String ruleName)) {
    if (configNode case YamlScalar(value: bool isEnabled)) {
      var severity = isEnabled
          ? ConfiguredSeverity.enable
          : ConfiguredSeverity.disable;
      return RuleConfig._(name: ruleName, group: group, severity: severity);
    } else if (configNode case YamlScalar(value: String severityString)) {
      var severity =
          ConfiguredSeverity.values.asNameMap()[severityString] ??
          ConfiguredSeverity.enable;
      return RuleConfig._(name: ruleName, group: group, severity: severity);
    }
  }

  return null;
}

/// Parses [configMap] as rule-specific options for a rule named [ruleName].
RuleConfig _parseRuleOptions(String ruleName, YamlMap configMap) {
  var options = <String, Object>{};
  for (var MapEntry(:key, :value) in configMap.nodes.entries) {
    if (key case YamlScalar(value: String optionName)) {
      if (value case YamlScalar(value: Object optionValue)) {
        options[optionName] = optionValue;
      }
    }
  }
  return RuleConfig._(
    name: ruleName,
    options: options,
    severity: ConfiguredSeverity.enable,
  );
}

/// An alias for a [RuleConfig], but which is configured under a 'diagnostics'
/// key in an analysis options file.
///
/// In an analyzer plugin, diagnostics are enabled and disabled via their name.
/// (For the built-in lint diagnostics, which are configured in an analysis
/// options file's top-level 'linter' key, diagnostics are enabled and disabled
/// via the name of the lint rule that reports the diagnostic.)
typedef DiagnosticConfig = RuleConfig;

/// The possible values for an analysis rule's configured severity.
enum ConfiguredSeverity {
  /// A severity indicating the rule is simply disabled.
  disable,

  /// A severity indicating the rule is enabled with its default severity.
  enable,

  /// A severity indicating the rule is enabled with the 'info' severity.
  info,

  /// A severity indicating the rule is enabled with the 'warning' severity.
  warning,

  /// A severity indicating the rule is enabled with the 'error' severity.
  error,
}

/// The configuration of a single analysis rule within an analysis options file.
class RuleConfig {
  /// The name of the group under which this configuration is found.
  final String? group;

  /// The name of the rule.
  final String name;

  /// Rule-specific configuration options parsed from a YAML map value.
  final Map<String, Object> options;

  /// The rule's severity in this configuration.
  final ConfiguredSeverity severity;

  RuleConfig._({
    required this.name,
    this.group,
    this.options = const {},
    required this.severity,
  });

  /// Whether this rule is enabled or disabled in this configuration.
  bool get isEnabled => severity != ConfiguredSeverity.disable;

  /// Returns whether [ruleName] is disabled in this configuration.
  bool disables(String ruleName) => ruleName == name && !isEnabled;

  /// Returns whether [ruleName] is enabled in this configuration.
  bool enables(String ruleName) => ruleName == name && isEnabled;
}
