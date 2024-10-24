// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// Parses [optionsMap] into a list of [RuleConfig]s, returning them, or `null`
/// if [optionsMap] does not have `linter` map.
List<RuleConfig>? parseLintRuleConfigs(YamlMap optionsMap) {
  var options = optionsMap.valueAt('linter');
  // Quick check of basic contract.
  if (options is YamlMap) {
    var ruleConfigs = <RuleConfig>[];
    var rulesNode = options.valueAt(AnalyzerOptions.rules);
    if (rulesNode != null) {
      ruleConfigs.addAll(_ruleConfigs(rulesNode));
    }

    return ruleConfigs;
  }

  return null;
}

RuleConfig? _parseRuleConfig(dynamic configKey, YamlNode configNode,
    {String? group}) {
  // For example: `{unnecessary_getters: false}`.
  if (configKey case YamlScalar(value: String ruleName)) {
    if (configNode case YamlScalar(value: bool isEnabled)) {
      return RuleConfig._(name: ruleName, isEnabled: isEnabled, group: group);
    }
  }

  return null;
}

/// Returns the [RuleConfig]s that are parsed from [value], which can be either
/// a YAML list or a YAML map.
List<RuleConfig> _ruleConfigs(YamlNode value) {
  // For example:
  //
  // ```yaml
  // - unnecessary_getters
  // - camel_case_types
  // ```
  if (value is YamlList) {
    var ruleConfigs = <RuleConfig>[];
    for (var ruleNode in value.nodes) {
      if (ruleNode case YamlScalar(value: String ruleName)) {
        ruleConfigs.add(RuleConfig._(name: ruleName, isEnabled: true));
      }
    }
    return ruleConfigs;
  }

  if (value is! YamlMap) {
    return const [];
  }

  var ruleConfigs = <RuleConfig>[];
  value.nodes.forEach((configKey, configValue) {
    if (configKey case YamlScalar(value: String configName)) {
      var ruleConfig = _parseRuleConfig(configKey, configValue);
      if (ruleConfig != null) {
        ruleConfigs.add(ruleConfig);
        return;
      }

      if (configValue is! YamlMap) {
        return;
      }
      // For example:
      //
      // ```yaml
      // style_guide: {unnecessary_getters: false, camel_case_types: true}
      // ```
      configValue.nodes.forEach((ruleName, ruleValue) {
        var ruleConfig =
            _parseRuleConfig(ruleName, ruleValue, group: configName);
        if (ruleConfig != null) {
          ruleConfigs.add(ruleConfig);
          return;
        }
      });
    }
  });
  return ruleConfigs;
}

/// The configuration of a single lint rule within an analysis options file.
class RuleConfig {
  /// Whether this rule is enabled or disabled in this configuration.
  final bool isEnabled;

  /// The name of the group under which this configuration is found.
  final String? group;

  /// The name of the rule.
  final String name;

  RuleConfig._({required this.name, required this.isEnabled, this.group});

  /// Returns whether [ruleName] is disabled in this configuration.
  bool disables(String ruleName) => ruleName == name && !isEnabled;

  /// Returns whether [ruleName] is enabled in this configuration.
  bool enables(String ruleName) => ruleName == name && isEnabled;
}
